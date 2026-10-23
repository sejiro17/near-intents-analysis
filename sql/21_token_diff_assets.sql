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
        receipt_id,
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
    ) AS item
),
token_diffs AS (
    SELECT
        receipt_id,
        JSON_QUERY(intent, '$.diff') AS diff
    FROM signed_messages
    CROSS JOIN UNNEST(
        JSON_QUERY_ARRAY(message_json, '$.intents')
    ) AS intent
    WHERE JSON_VALUE(intent, '$.intent') = 'token_diff'
),
diff_checks AS (
    SELECT
        *,
        JSON_KEYS(diff, 1) AS asset_keys
    FROM token_diffs
),
coverage AS (
    SELECT
        COUNT(*) AS token_diff_intents_checked,
        COUNTIF(
            diff IS NULL
            OR JSON_TYPE(diff) != 'object'
        ) AS missing_or_invalid_diff_objects,
        COUNTIF(
            JSON_TYPE(diff) = 'object'
            AND ARRAY_LENGTH(asset_keys) = 0
        ) AS empty_diff_objects
    FROM diff_checks
),
asset_counts AS (
    SELECT
        asset_key,
        COUNT(*) AS intent_appearances,
        COUNT(DISTINCT receipt_id) AS successful_calls_containing_asset
    FROM diff_checks
    CROSS JOIN UNNEST(asset_keys) AS asset_key
    WHERE JSON_TYPE(diff) = 'object'
    GROUP BY asset_key
)
SELECT
    a.asset_key,
    a.intent_appearances,
    a.successful_calls_containing_asset,
    c.token_diff_intents_checked,
    c.missing_or_invalid_diff_objects,
    c.empty_diff_objects
FROM asset_counts AS a
CROSS JOIN coverage AS c
ORDER BY a.intent_appearances DESC, a.asset_key;