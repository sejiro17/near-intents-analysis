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
    a.receipt_id,
    a.receipt_predecessor_account_id AS submitting_account,
    a.args
FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions` AS a
WHERE a.block_date = DATE '2026-10-21'
    AND a.receipt_receiver_account_id = 'intents.near'
    AND a.action_kind = 'FUNCTION_CALL'
    AND JSON_VALUE(a.args, '$.method_name') = 'execute_intents'
    AND EXISTS (
        SELECT 1
        FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes` AS o
        WHERE o.block_date BETWEEN DATE '2026-10-21'
                                   AND DATE '2026-10-22'
            AND o.receipt_id = a.receipt_id
            AND o.status = 'SUCCESS_VALUE'
    )
LIMIT 5;