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
    args
FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions`
WHERE block_date = DATE '2026-10-21'
    AND receipt_receiver_account_id = 'intents.near'
    AND action_kind = 'FUNCTION_CALL'
LIMIT 5;