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

WITH actions AS (
    SELECT
        block_date,
        receipt_id,
        receipt_predecessor_account_id AS submitting_account
    FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions`
    WHERE block_date BETWEEN DATE '2026-10-15' AND DATE '2026-10-21'
        AND receipt_receiver_account_id = 'intents.near'
        AND action_kind = 'FUNCTION_CALL'
        AND JSON_VALUE(args, '$.method_name') = 'execute_intents'
),
outcomes AS (
    SELECT
        receipt_id,
        status
    FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes`
    WHERE block_date BETWEEN DATE '2026-10-15' AND DATE '2026-10-22'
)
SELECT
    a.block_date,
    CASE
        WHEN a.submitting_account = 'escrow.ai.near'
            THEN 'escrow.ai.near'
        ELSE 'All other accounts'
    END AS account_group,
    COUNT(*) AS total_calls,
    COUNTIF(o.status = 'SUCCESS_VALUE') AS successful_calls,
    COUNTIF(o.status = 'FAILURE') AS failed_calls,
    COUNTIF(
        o.status IS NULL
        OR o.status NOT IN ('SUCCESS_VALUE', 'FAILURE')
    ) AS other_or_missing_status,
    ROUND(
        100.0 * SAFE_DIVIDE(
            COUNTIF(o.status = 'FAILURE'),
            COUNT(*)
        ),
        2
    ) AS failure_rate_pct
FROM actions AS a
LEFT JOIN outcomes AS o
    ON a.receipt_id = o.receipt_id
GROUP BY a.block_date, account_group
ORDER BY a.block_date, account_group;