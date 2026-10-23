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
        a.block_date,
        a.receipt_id,
        a.args
    FROM `bigquery-public-data.crypto_near_mainnet_us.receipt_actions` AS a
    WHERE a.block_date BETWEEN DATE '2026-10-15'
                               AND DATE '2026-10-21'
        AND a.receipt_receiver_account_id = 'intents.near'
        AND a.action_kind = 'FUNCTION_CALL'
        AND JSON_VALUE(a.args, '$.method_name') = 'execute_intents'
        AND EXISTS (
            SELECT 1
            FROM `bigquery-public-data.crypto_near_mainnet_us.execution_outcomes` AS o
            WHERE o.block_date BETWEEN DATE '2026-10-15'
                                       AND DATE '2026-10-22'
                AND o.receipt_id = a.receipt_id
                AND o.status = 'SUCCESS_VALUE'
        )
),
decoded_calls AS (
    SELECT
        block_date,
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
signed_messages AS (
    SELECT
        block_date,
        receipt_id,
        item_offset,
        SAFE.PARSE_JSON(
            CASE
                WHEN JSON_VALUE(item, '$.standard') = 'nep413'
                    THEN JSON_VALUE(item, '$.payload.message')
                WHEN JSON_VALUE(item, '$.standard') IN (
                    'erc191',
                    'raw_ed25519',
                    'webauthn',
                    'tip191',
                    'sep53'
                )
                    THEN JSON_VALUE(item, '$.payload')
                WHEN JSON_VALUE(item, '$.standard') = 'ton_connect'
                    THEN JSON_VALUE(item, '$.payload.text')
            END
        ) AS message_json
    FROM decoded_calls
    CROSS JOIN UNNEST(
        JSON_QUERY_ARRAY(decoded_args, '$.signed')
    ) AS item WITH OFFSET AS item_offset
),
message_arrays AS (
    SELECT
        *,
        JSON_QUERY_ARRAY(message_json, '$.intents') AS intents
    FROM signed_messages
),
coverage AS (
    SELECT
        COUNT(*) AS signed_items_checked,
        COUNTIF(
            message_json IS NULL
            OR JSON_TYPE(message_json) != 'object'
        ) AS invalid_messages,
        COUNTIF(intents IS NULL) AS items_without_intents_array,
        COUNTIF(
            ARRAY_LENGTH(intents) = 0
        ) AS items_with_empty_intents_array
    FROM message_arrays
),
expanded_intents AS (
    SELECT
        block_date,
        receipt_id,
        item_offset,
        NULLIF(
            TRIM(JSON_VALUE(intent, '$.intent')),
            ''
        ) AS intent_type
    FROM message_arrays
    CROSS JOIN UNNEST(intents) AS intent
),
intent_counts AS (
    SELECT
        intent_type,
        COUNT(*) AS intent_count,
        COUNT(DISTINCT receipt_id) AS successful_calls_containing_type
    FROM expanded_intents
    GROUP BY intent_type
)
SELECT
    i.intent_type,
    i.intent_count,
    i.successful_calls_containing_type,
    ROUND(
        100.0 * SAFE_DIVIDE(
            i.intent_count,
            SUM(i.intent_count) OVER ()
        ),
        2
    ) AS intent_share_pct,
    c.signed_items_checked,
    c.invalid_messages,
    c.items_without_intents_array,
    c.items_with_empty_intents_array
FROM intent_counts AS i
CROSS JOIN coverage AS c
ORDER BY i.intent_count DESC, i.intent_type;
