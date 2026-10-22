SELECT
    COUNT(*) AS action_count,
    COUNT(DISTINCT receipt_id) AS receipt_count
FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions`
WHERE block_date = DATE '2026-10-21'
    AND receipt_receiver_account_id = 'intents.near'
    AND action_kind = 'FUNCTION_CALL'
    AND JSON_VALUE(args, '$.method_name') = 'execute_intents';

WITH actions AS (
    SELECT DISTINCT receipt_id
    FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions`
    WHERE block_date = DATE '2026-10-21'
        AND receipt_receiver_account_id = 'intents.near'
        AND action_kind = 'FUNCTION_CALL'
        AND JSON_VALUE(args, '$.method_name') = 'execute_intents'
),
matches AS (
    SELECT
        a.receipt_id,
        COUNT(o.receipt_id) AS outcome_count
    FROM actions AS a
    LEFT JOIN `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes` AS o
        ON a.receipt_id = o.receipt_id
        AND o.block_date = DATE '2026-10-21'
    GROUP BY a.receipt_id
)
SELECT
    outcome_count,
    COUNT(*) AS receipt_count
FROM matches
GROUP BY outcome_count
ORDER BY outcome_count;