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

WITH target_receipts AS (
    SELECT DISTINCT
        block_date AS call_date,
        receipt_id,
        receipt_predecessor_account_id AS submitting_account
    FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions`
    WHERE block_date BETWEEN DATE '2026-10-15'
                         AND DATE '2026-10-21'
        AND receipt_receiver_account_id = 'intents.near'
        AND action_kind = 'FUNCTION_CALL'
        AND JSON_VALUE(args, '$.method_name') = 'execute_intents'
),
outcomes AS (
    SELECT
        receipt_id,
        status,
        gas_burnt,
        tokens_burnt
    FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes`
    WHERE block_date BETWEEN DATE '2026-10-15'
                         AND DATE '2026-10-22'
)
SELECT
    a.call_date,
    CASE
        WHEN a.submitting_account = 'escrow.ai.near'
            THEN 'escrow.ai.near'
        ELSE 'All other accounts'
    END AS account_group,
    o.status,
    COUNT(*) AS receipt_count,
    COUNTIF(o.receipt_id IS NULL) AS unmatched_receipts,
    COUNTIF(o.gas_burnt IS NULL) AS missing_gas_values,
    COUNTIF(o.tokens_burnt IS NULL) AS missing_token_values,
    COUNTIF(o.gas_burnt < 0) AS negative_gas_values,
    COUNTIF(o.tokens_burnt < 0) AS negative_token_values,
    SUM(o.gas_burnt) / 1e12 AS total_gas_burnt_tgas,
    SUM(o.tokens_burnt) / 1e24 AS total_tokens_burnt_near,
    AVG(o.gas_burnt) / 1e12 AS avg_gas_burnt_tgas,
    AVG(o.tokens_burnt) / 1e24 AS avg_tokens_burnt_near
FROM target_receipts AS a
LEFT JOIN outcomes AS o
    ON a.receipt_id = o.receipt_id
GROUP BY a.call_date, account_group, o.status
ORDER BY a.call_date, account_group, o.status;