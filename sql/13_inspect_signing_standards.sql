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
        a.receipt_id,
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
),
decoded_calls AS (
    SELECT
        receipt_id,
        SAFE.PARSE_JSON(
            SAFE_CONVERT_BYTES_TO_STRING(
                SAFE.FROM_BASE64(
                    JSON_VALUE(args, '$.args_base64')
                )
            )
        ) AS decoded_args
    FROM successful_calls
),
signed_items AS (
    SELECT
        receipt_id,
        item,
        JSON_VALUE(item, '$.standard') AS signing_standard
    FROM decoded_calls
    CROSS JOIN UNNEST(
        JSON_QUERY_ARRAY(decoded_args, '$.signed')
    ) AS item
)
SELECT
    signing_standard,
    COUNT(*) AS signed_item_count,
    COUNT(DISTINCT receipt_id) AS receipt_count,
    ARRAY_AGG(
        STRUCT(
            receipt_id AS receipt_id,
            TO_JSON_STRING(item) AS signed_item_json
        )
        ORDER BY receipt_id
        LIMIT 1
    )[OFFSET(0)] AS example
FROM signed_items
WHERE signing_standard IS NULL
    OR signing_standard != 'nep413'
GROUP BY signing_standard
ORDER BY signed_item_count DESC;