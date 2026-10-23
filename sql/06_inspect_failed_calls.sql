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

SELECT
    o.receipt_id,
    o.status,
    o.logs
FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes` AS o
WHERE o.block_date = DATE '2026-10-21'
    AND o.status = 'FAILURE'
    AND EXISTS (
        SELECT 1
        FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions` AS a
        WHERE a.block_date = DATE '2026-10-21'
            AND a.receipt_id = o.receipt_id
            AND a.receipt_receiver_account_id = 'intents.near'
            AND a.action_kind = 'FUNCTION_CALL'
            AND JSON_VALUE(a.args, '$.method_name') = 'execute_intents'
    )
LIMIT 5;