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
    receipt_kind,
    originated_from_transaction_hash
FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_origin_transaction`
WHERE block_date = DATE '2026-10-21'
    AND receipt_id = '7tMjQpwapXuyLRHcS3Homck64cZJGFZymF9tea3KPqei';