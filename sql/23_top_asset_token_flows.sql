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

-- Positive and negative token_diff amounts for the five most
-- frequently referenced assets identified in query 21.
-- Amounts remain in raw token units.

WITH target_assets AS (
    SELECT asset_id
    FROM UNNEST([
        'nep141:eth-0xdac17f958d2ee523a2206206994597c13d831ec7.omft.near',
        'nep141:eth-0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48.omft.near',
        'nep141:eth.omft.near',
        'nep141:tron-d28a265909efecdcee7c5028585214ea0b96f015.omft.near',
        'nep141:sol.omft.near'
    ]) AS asset_id
),
successful_calls AS (
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
coverage AS (
    SELECT
        COUNT(*) AS token_diff_intents_checked,
        COUNTIF(
            diff IS NULL
            OR JSON_TYPE(diff) != 'object'
        ) AS missing_or_invalid_diff_objects,
        COUNTIF(
            JSON_TYPE(diff) = 'object'
            AND ARRAY_LENGTH(JSON_KEYS(diff, 1)) = 0
        ) AS empty_diff_objects
    FROM token_diffs
),
asset_values AS (
    SELECT
        d.receipt_id,
        t.asset_id,
        JSON_VALUE(d.diff[t.asset_id]) AS amount_text
    FROM token_diffs AS d
    CROSS JOIN target_assets AS t
    WHERE JSON_TYPE(d.diff) = 'object'
        AND d.diff[t.asset_id] IS NOT NULL
),
parsed_amounts AS (
    SELECT
        receipt_id,
        asset_id,
        amount_text,
        CASE
            WHEN REGEXP_CONTAINS(amount_text, r'^-?[0-9]+$')
                THEN SAFE_CAST(amount_text AS BIGNUMERIC)
        END AS raw_amount
    FROM asset_values
),
asset_totals AS (
    SELECT
        asset_id,
        COUNT(*) AS intent_appearances,
        COUNT(DISTINCT receipt_id)
            AS successful_calls_containing_asset,
        COUNTIF(raw_amount IS NULL)
            AS invalid_or_out_of_range_amounts,
        COUNTIF(raw_amount > 0) AS positive_entries,
        COUNTIF(raw_amount < 0) AS negative_entries,
        COUNTIF(raw_amount = 0) AS zero_entries,

        -- Suppress totals if any amount could not be parsed.
        IF(
            COUNTIF(raw_amount IS NULL) = 0,
            SUM(IF(raw_amount > 0, raw_amount, 0)),
            NULL
        ) AS positive_raw_amount,

        IF(
            COUNTIF(raw_amount IS NULL) = 0,
            SUM(IF(raw_amount < 0, -raw_amount, 0)),
            NULL
        ) AS negative_raw_amount_magnitude,

        IF(
            COUNTIF(raw_amount IS NULL) = 0,
            SUM(raw_amount),
            NULL
        ) AS net_raw_amount
    FROM parsed_amounts
    GROUP BY asset_id
)
SELECT
    t.asset_id,
    COALESCE(a.intent_appearances, 0) AS intent_appearances,
    COALESCE(a.successful_calls_containing_asset, 0)
        AS successful_calls_containing_asset,
    COALESCE(a.invalid_or_out_of_range_amounts, 0)
        AS invalid_or_out_of_range_amounts,
    COALESCE(a.positive_entries, 0) AS positive_entries,
    COALESCE(a.negative_entries, 0) AS negative_entries,
    COALESCE(a.zero_entries, 0) AS zero_entries,
    a.positive_raw_amount,
    a.negative_raw_amount_magnitude,
    a.net_raw_amount,
    c.token_diff_intents_checked,
    c.missing_or_invalid_diff_objects,
    c.empty_diff_objects
FROM target_assets AS t
LEFT JOIN asset_totals AS a
    ON t.asset_id = a.asset_id
CROSS JOIN coverage AS c
ORDER BY intent_appearances DESC, t.asset_id;