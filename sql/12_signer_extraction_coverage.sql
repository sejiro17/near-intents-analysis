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
signed_arrays AS (
    SELECT
        receipt_id,
        decoded_args,
        JSON_QUERY_ARRAY(decoded_args, '$.signed') AS signed_items
    FROM decoded_calls
),
call_checks AS (
    SELECT
        receipt_id,
        decoded_args,
        signed_items,
        (
            SELECT COUNT(*)
            FROM UNNEST(signed_items) AS item
            WHERE JSON_VALUE(item, '$.standard') = 'nep413'
        ) AS nep413_items,
        (
            SELECT COUNT(*)
            FROM UNNEST(signed_items) AS item
            WHERE JSON_VALUE(item, '$.standard') = 'nep413'
                AND NULLIF(
                    JSON_VALUE(
                        JSON_VALUE(item, '$.payload.message'),
                        '$.signer_id'
                    ),
                    ''
                ) IS NOT NULL
        ) AS items_with_extracted_signer
    FROM signed_arrays
)
SELECT
    COUNT(*) AS successful_calls,
    COUNTIF(decoded_args IS NULL) AS undecodable_calls,
    COUNTIF(signed_items IS NULL) AS calls_without_signed_array,
    COUNTIF(ARRAY_LENGTH(signed_items) = 0) AS calls_with_empty_signed_array,
    SUM(COALESCE(ARRAY_LENGTH(signed_items), 0)) AS signed_items,
    SUM(nep413_items) AS nep413_items,
    SUM(
        COALESCE(ARRAY_LENGTH(signed_items), 0) - nep413_items
    ) AS other_or_missing_standard_items,
    SUM(items_with_extracted_signer) AS items_with_extracted_signer,
    COUNTIF(
        ARRAY_LENGTH(signed_items) > 0
        AND items_with_extracted_signer = ARRAY_LENGTH(signed_items)
    ) AS calls_with_all_signers_extracted
FROM call_checks;