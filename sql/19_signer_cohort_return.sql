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
cohort AS (
    SELECT signer_id
    FROM signer_days
    WHERE block_date = DATE '2026-10-15'
),
cohort_size AS (
    SELECT COUNT(*) AS cohort_signers
    FROM cohort
),
observation_dates AS (
    SELECT observation_date
    FROM UNNEST(
        GENERATE_DATE_ARRAY(
            DATE '2026-10-15',
            DATE '2026-10-21'
        )
    ) AS observation_date
),
daily_cohort_activity AS (
    SELECT
        s.block_date,
        COUNT(*) AS active_cohort_signers
    FROM signer_days AS s
    INNER JOIN cohort AS c
        ON s.signer_id = c.signer_id
    GROUP BY s.block_date
)
SELECT
    DATE '2026-10-15' AS cohort_date,
    d.observation_date,
    DATE_DIFF(
        d.observation_date,
        DATE '2026-10-15',
        DAY
    ) AS days_since_cohort,
    c.cohort_signers,
    COALESCE(a.active_cohort_signers, 0) AS active_cohort_signers,
    ROUND(
        100.0 * SAFE_DIVIDE(
            COALESCE(a.active_cohort_signers, 0),
            c.cohort_signers
        ),
        2
    ) AS cohort_active_pct
FROM observation_dates AS d
CROSS JOIN cohort_size AS c
LEFT JOIN daily_cohort_activity AS a
    ON d.observation_date = a.block_date
ORDER BY d.observation_date;