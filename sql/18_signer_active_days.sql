/* @datacloud.settings
{
  "version": 1,
  "service": "BIG_QUERY",
  "connectionInfo": {
    "billingProjectId": "INHERIT"
  },
  "dialect": "GOOGLE_SQL"
}
*/

WITH successful_calls AS (
    SELECT
        a.block_date,
        a.receipt_id,
        a.args
    FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions` AS a
    WHERE a.block_date BETWEEN DATE '2026-10-15'
                               AND DATE '2026-10-21'
        AND a.receipt_receiver_account_id = 'intents.near'
        AND a.action_kind = 'FUNCTION_CALL'
        AND JSON_VALUE(a.args, '$.method_name') = 'execute_intents'
        AND EXISTS (
            SELECT 1
            FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes` AS o
            WHERE o.block_date BETWEEN DATE '2026-10-15'
                                       AND DATE '2026-10-22'
                AND o.receipt_id = a.receipt_id
                AND o.status = 'SUCCESS_VALUE'
        )
),
decoded_calls AS (
    SELECT
        block_date,
        receipt_id,
        SAFE.PARSE_JSON(
            SAFE_CONVERT_BYTES_TO_STRING(
                SAFE.FROM_BASE64(
                    JSON_VALUE(args, '$.args_base64')
                )
            )
        ) AS decoded_args
    FROM successful_calls
),
extracted_signers AS (
    SELECT
        block_date,
        NULLIF(
            CASE
                WHEN JSON_VALUE(item, '$.standard') = 'nep413'
                THEN JSON_VALUE(
                    JSON_VALUE(item, '$.payload.message'),
                    '$.signer_id'
                )
                WHEN JSON_VALUE(item, '$.standard') IN (
                    'erc191',
                    'raw_ed25519',
                    'webauthn',
                    'tip191',
                    'sep53'
                )
                THEN JSON_VALUE(
                    JSON_VALUE(item, '$.payload'),
                    '$.signer_id'
                )
                WHEN JSON_VALUE(item, '$.standard') = 'ton_connect'
                THEN JSON_VALUE(
                    JSON_VALUE(item, '$.payload.text'),
                    '$.signer_id'
                )
            END,
            ''
        ) AS signer_id
    FROM decoded_calls
    CROSS JOIN UNNEST(
        JSON_QUERY_ARRAY(decoded_args, '$.signed')
    ) AS item
),
signer_days AS (
    SELECT DISTINCT
        block_date,
        signer_id
    FROM extracted_signers
    WHERE signer_id IS NOT NULL
),
signer_activity AS (
    SELECT
        signer_id,
        COUNT(*) AS active_days
    FROM signer_days
    GROUP BY signer_id
),
distribution AS (
    SELECT
        active_days,
        COUNT(*) AS signer_count
    FROM signer_activity
    GROUP BY active_days
)
SELECT
    active_days,
    signer_count,
    ROUND(
        100.0 * SAFE_DIVIDE(
            signer_count,
            SUM(signer_count) OVER ()
        ),
        2
    ) AS signer_share_pct
FROM distribution
ORDER BY active_days;