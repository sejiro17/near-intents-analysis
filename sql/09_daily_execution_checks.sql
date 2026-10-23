WITH actions AS (
    SELECT
        block_date,
        receipt_id,
        COUNT(*) AS action_count
    FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions`
    WHERE block_date BETWEEN DATE '2026-10-15' AND DATE '2026-10-21'
        AND receipt_receiver_account_id = 'intents.near'
        AND action_kind = 'FUNCTION_CALL'
        AND JSON_VALUE(args, '$.method_name') = 'execute_intents'
    GROUP BY block_date, receipt_id
),
outcomes AS (
    SELECT
        receipt_id,
        COUNT(*) AS outcome_count
    FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes`
    WHERE block_date BETWEEN DATE '2026-10-15' AND DATE '2026-10-22'
    GROUP BY receipt_id
)
SELECT
    a.block_date,
    SUM(a.action_count) AS action_count,
    COUNT(*) AS receipt_count,
    COUNTIF(o.outcome_count IS NULL) AS unmatched_receipts,
    COUNTIF(o.outcome_count > 1) AS receipts_with_multiple_outcomes
FROM actions AS a
LEFT JOIN outcomes AS o
    ON a.receipt_id = o.receipt_id
GROUP BY a.block_date
ORDER BY a.block_date;