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
signed_arrays AS (
    SELECT
        block_date,
        receipt_id,
        decoded_args,
        JSON_QUERY_ARRAY(decoded_args, '$.signed') AS signed_items
    FROM decoded_calls
),
extracted_items AS (
    SELECT
        a.block_date,
        a.receipt_id,
        item_offset,
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
    FROM signed_arrays AS a
    LEFT JOIN UNNEST(a.signed_items) AS item
        WITH OFFSET AS item_offset ON TRUE
),
daily_coverage AS (
    SELECT
        block_date,
        COUNT(*) AS successful_calls,
        COUNTIF(decoded_args IS NULL) AS undecodable_calls,
        COUNTIF(
            signed_items IS NULL
            OR ARRAY_LENGTH(signed_items) = 0
        ) AS calls_without_nonempty_signed_array,
        SUM(
            COALESCE(ARRAY_LENGTH(signed_items), 0)
        ) AS signed_items
    FROM signed_arrays
    GROUP BY block_date
),
signer_days AS (
    SELECT DISTINCT
        block_date,
        signer_id
    FROM extracted_items
    WHERE signer_id IS NOT NULL
),
first_observed AS (
    SELECT
        signer_id,
        MIN(block_date) AS first_observed_date
    FROM signer_days
    GROUP BY signer_id
),
daily_participation AS (
    SELECT
        s.block_date,
        COUNT(*) AS active_signers,
        COUNTIF(
            s.block_date = f.first_observed_date
        ) AS first_observed_signers,
        COUNTIF(
            s.block_date > f.first_observed_date
        ) AS previously_observed_signers
    FROM signer_days AS s
    JOIN first_observed AS f
        ON s.signer_id = f.signer_id
    GROUP BY s.block_date
),
daily_extraction AS (
    SELECT
        block_date,
        COUNTIF(
            item_offset IS NOT NULL AND signer_id IS NULL
        ) AS items_without_extracted_signer
    FROM extracted_items
    GROUP BY block_date
)
SELECT
    c.block_date,
    c.successful_calls,
    c.undecodable_calls,
    c.calls_without_nonempty_signed_array,
    c.signed_items,
    e.items_without_extracted_signer,
    COALESCE(p.active_signers, 0) AS active_signers,
    COALESCE(p.first_observed_signers, 0) AS first_observed_signers,
    COALESCE(p.previously_observed_signers, 0)
        AS previously_observed_signers
FROM daily_coverage AS c
LEFT JOIN daily_extraction AS e
    ON c.block_date = e.block_date
LEFT JOIN daily_participation AS p
    ON c.block_date = p.block_date
ORDER BY c.block_date;
