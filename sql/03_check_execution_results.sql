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
    block_date,
    receipt_id,
    executor_account_id,
    status,
    gas_burnt,
    tokens_burnt,
    logs
FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes`
WHERE block_date = DATE '2026-10-21'
    AND executor_account_id = 'intents.near'
LIMIT 5;