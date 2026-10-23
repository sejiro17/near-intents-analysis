# Data Checks

## 22 October 2026 - Latest Transaction Date 

I connected BigQuery to VS Code and checked the latest transaction date in bigquery-public-data.crypto_near_mainnet_us.transactions.
I limited the query to a recent date window to reduce the amount of data scanned. The latest date returned was 22 October 2026, confirming that the table contains transactions dated today.
This check doesn’t confirm that the data is complete or that it covers all NEAR Intents activity. I still need to investigate those before finalising the research question.

## 22 October 2026 — Execution Outcomes and Action Matching

I inspected five execution outcomes for intents.near dated 21 October 2026. Four had SUCCESS_VALUE status and one had FAILURE status. The failed outcome also contained logs, so logs alone cannot confirm successful execution.

I then joined receipt_actions to execution_outcomes using receipt_id, filtering for execute_intents function calls. All five sampled actions matched outcomes with SUCCESS_VALUE status.

These checks show that I can link sampled actions to their receipt execution results. They do not establish the overall success rate, confirm downstream swap completion, or validate matching across the full dataset.

## 22 October 2026 — Full-Day Action Matching

For 21 October 2026, I counted 67,266 execute_intents actions on intents.near across 67,266 distinct receipts. Each receipt matched exactly one execution outcome within the selected day.

Of these calls, 50,387 had SUCCESS_VALUE status (74.91%) and 16,879 had FAILURE status (25.09%). The status counts reconcile to the original action count.

These figures describe receipt execution for one day, not unique users or completed swaps. Failure reasons, retries and trends across other dates still need investigation.

## 23 October 2026 — Tracing a Failed Call

I inspected five failed execute_intents receipts and traced one to its originating transaction using receipt_origin_transaction.

- Receipt: `7tMjQpwapXuyLRHcS3Homck64cZJGFZymF9tea3KPqei`
- Transaction: `DERcYoirdpnH8ujTtEg6MQt3D1ufEnXTaDa6qiQqgZdF`
- Receipt error: `Smart contract panicked: insufficient balance or overflow`
- Action index: 0
- Source: https://nearblocks.io/txns/DERcYoirdpnH8ujTtEg6MQt3D1ufEnXTaDa6qiQqgZdF/execution

The failed receipt contains a transfer event in its logs. I therefore cannot treat that event alone as evidence of a completed transfer.

This is one inspected example. It does not establish which condition triggered the error or explain the other failed calls.

## 23 October 2026 — Failure Concentration by Submitting Account

I grouped execute_intents calls on 21 October 2026 by receipt_predecessor_account_id. The results contain 17 submitting accounts and reconcile to 67,266 calls, 50,387 successful executions and 16,879 failures.

escrow.ai.near submitted 15,781 calls, all of which failed. It accounted for 93.49% of the day's failures. Across the other submitting accounts combined, 1,098 of 51,485 calls failed (2.13%).

The overall failure rate of 25.09% was therefore heavily concentrated in one submitting account. I have kept all accounts in the analysis. These accounts are not necessarily individual users, and I have not established whether the failures were retries or shared the same cause.

Query: `sql/08_failures_by_account.sql`
Results: `results/08_failures_by_account_2026-10-21.csv`

## 23 October 2026 — Seven-Day Failure Concentration

I analysed execute_intents calls dated 15–21 October 2026, allowing execution outcomes through 22 October. Each day's action count matched its distinct receipt count, and every receipt matched exactly one outcome.

The daily results reconcile to 402,695 calls: 279,856 successful receipt executions and 122,839 failures. There were no other or missing statuses.

escrow.ai.near submitted 116,775 calls, all of which failed, with zero successes on every day examined. It contributed 95.06% of the week's failures.

The overall failure rate was 30.50%. Across all other submitting accounts combined, 6,064 of 285,920 calls failed (2.12%). I retained all accounts in the analysis.

This establishes persistent failure concentration during the selected week. It does not establish a common error cause, identify retries, or measure unique users or completed swaps.

Queries: `sql/09_daily_execution_checks.sql` and `sql/10_daily_failure_concentration.sql`
Results: the corresponding CSVs in `results/`.

## 23 October 2026 — Inspecting Signed Intents

I decoded the arguments of five successful execute_intents calls from 21 October 2026. All five decoded successfully, containing 11 signed items across 9 distinct signer identifiers. All sampled signed items used nep413.

One signer, blockzen-1-main.near, appeared in three calls. The sample included token_diff, transfer, storage_deposit and ft_withdraw intents. One call contained only ft_withdraw.

Calls, signed items and signer identifiers therefore measure different things. I have not verified signer roles, and distinct signers should not be interpreted as distinct people. This exploratory sample does not establish the distribution across all successful calls.

Query: `sql/11_inspect_successful_intents.sql`
Sample: `results/11_successful_intents_sample_2026-10-21.csv`
Decoder: `analysis/02_inspect_signed_intents.py`

## 23 October 2026 — Signer Extraction Coverage

I checked signer extraction across all 50,387 successful execute_intents calls dated 21 October, allowing execution outcomes through 22 October.

All calls decoded and contained nonempty signed arrays, totalling 85,897 signed items. The initial nep413-only extractor recovered 83,236 signer occurrences. The remaining 2,661 items used erc191, raw_ed25519, webauthn, tip191, sep53 and ton_connect.

After inspecting an example of each additional format and extending the extraction rules, all 85,897 signed items yielded a nonempty signer_id. Every successful call had all signers extracted.

This confirms extraction coverage for this day's successful calls. It does not measure distinct signers, verify their roles, or establish coverage on other dates. Signer identifiers should not be interpreted as distinct people.

Queries: `sql/12_signer_extraction_coverage.sql`, `sql/13_inspect_signing_standards.sql` and `sql/14_full_signer_extraction_coverage.sql`.
Results: the corresponding CSV exports in `results/`.

## 23 October 2026 — Signer Activity on 21 October

I counted 26,589 distinct signer identifiers in successful execute_intents calls. Their signed-item counts sum to 85,897, matching the extraction coverage result.

Of these signers, 25,442 (95.69%) appeared in exactly one successful call during the day, while 1,147 appeared in multiple calls.

Ranked by signed-item count, the top five signers contributed 39.58% of signed items and the top ten contributed 54.04%.

solver-priv-liq.near contributed 11,180 signed items across 7,123 distinct successful calls. Multiple signed items can therefore belong to the same signer within a call.

These figures describe signer activity for one day, not unique people or retention. Signer roles remain unverified, and calls involving multiple signers must not be counted multiple times as separate calls.

Query: `sql/15_signer_activity.sql`
Results: `results/15_signer_activity_2026-10-21.csv`

## 23 October 2026 — Daily Signer Participation

I analysed successful execute_intents calls dated 15–21 October, including execution outcomes recorded through 22 October.

The results reconcile to 279,856 successful calls and contain 502,916 signed items. Every day had zero decoding failures, zero missing or empty signed arrays, and zero signed items without an extracted signer.

There were 147,573 distinct signer identifiers across the week, calculated by summing each day's first-observed signers. Daily active signers ranged from 17,963 to 26,589.

From 16–21 October, identifiers previously observed on an earlier day within the week represented 1.33%–2.61% of daily active signers. On 21 October, 606 of 26,589 active signers had appeared earlier in the selected week.

First observed means first seen within this window, not first-ever use. Previously observed shares describe daily composition, not cohort retention. Signer identifiers are not necessarily distinct people, and their roles remain unverified.

Query: `sql/16_daily_signer_activity.sql`
Results: `results/16_daily_signer_activity_2026-10-15_to_2026-10-21.csv`

## 23 October 2026 — Receipt Execution Costs

I measured gas_burnt and tokens_burnt for execute_intents receipts dated 15–21 October, including execution outcomes recorded through 22 October.

The results reconcile to 402,695 receipts, with zero unmatched receipts, missing cost values or negative cost values.

Recorded tokens_burnt totalled approximately 292.1178 NEAR: 248.8194 NEAR for 279,856 successful receipts and 43.2985 NEAR for 122,839 failed receipts.

Failed receipts represented 30.50% of receipts and 14.82% of recorded cost. Average recorded cost was approximately 0.00088910 NEAR per successful receipt and 0.00035248 NEAR per failed receipt.

escrow.ai.near accounted for approximately 40.8096 NEAR, or 94.25% of failed-receipt costs.

Token amounts were converted from yoctoNEAR by dividing by 10^24, and gas units to Tgas by dividing by 10^12. The source fields use floating-point storage, so amounts are approximate.

These figures cover the target receipts only, excluding other upstream and downstream execution outcomes. They do not establish NEAR Intents revenue or net token supply reduction.

Query: `sql/17_daily_execution_costs.sql`
Results: `results/17_daily_execution_costs_2026-10-15_to_2026-10-21.csv`

## 23 October 2026 — Signer Active Days

I grouped signer identifiers by the number of days they appeared in successful execute_intents calls during 15–21 October.

The distribution reconciles to 147,573 distinct signers and 150,251 signer-days, matching the earlier daily participation results.

Of these identifiers, 146,301 (99.14%) appeared on one day, while 1,272 appeared on multiple days. There were 131 identifiers active on all seven days.

This measures repeat participation within the selected window, not user retention. Signer identifiers are not necessarily distinct people, and identifiers first observed later in the week had fewer opportunities to return.

Query: `sql/18_signer_active_days.sql`
Results: `results/18_signer_active_days_2026-10-15_to_2026-10-21.csv`

## 23 October 2026 — Signer Cohort Return

I followed the 22,520 signer identifiers active in successful execute_intents calls on 15 October through 21 October.

The starting-day count reconciles to the earlier daily signer analysis. The cohort denominator remains fixed at 22,520, and all exported daily percentages reconcile to their counts.

On 16 October, 312 cohort signers were active (1.39%). On 21 October, 287 were active (1.27%). Across the six subsequent days, daily cohort activity ranged from 259 to 312 signers (1.15%–1.39%).

These are separate daily activity counts, not cumulative returns or uninterrupted participation. A signer could skip a day and return later.

This is an activity cohort, not a cohort of newly acquired users. It measures repeat activity by signer identifier over a short window; signer roles and ownership remain unverified.

Query: `sql/19_signer_cohort_return.sql`
Results: `results/19_signer_cohort_return_2026-10-15_to_2026-10-21.csv`

## 23 October 2026 — Intent Type Activity

I extracted intent arrays from 502,916 signed items in successful execute_intents calls dated 15–21 October.

There were zero invalid messages and zero missing intent arrays. Eight signed items contained empty intent arrays and therefore contributed no individual intents to the breakdown. Their purpose has not been investigated.

The nonempty arrays contained 834,900 intents across 10 types, with no missing or empty intent types.

Transfers accounted for 372,932 intents (44.67%), token_diff for 293,410 (35.14%), and ft_withdraw for 130,383 (15.62%). These three types accounted for 95.43% of individual intents.

A call can contain multiple signed items and intent types. Counts of calls containing each type overlap and must not be summed as distinct calls. Intent types alone do not establish completed swaps or successful downstream actions.

Query: `sql/20_intent_type_activity.sql`
Results: `results/20_intent_type_activity_2026-10-15_to_2026-10-21.csv`

## 23 October 2026 — Assets Referenced in Token Diffs

I inspected asset keys in 293,410 token_diff intents from successful execute_intents calls dated 15–21 October.

All inspected intents contained nonempty diff objects, with zero missing or invalid objects. The export contains 1,626 distinct asset identifiers and 584,173 asset appearances.

The five most frequently referenced identifiers accounted for 54.45% of asset appearances. The leading identifier was nep141:eth-0xdac17f958d2ee523a2206206994597c13d831ec7.omft.near, appearing in 102,976 intents across 50,673 successful calls.

Asset appearances measure frequency, not token quantities, trading volume or completed swaps. Asset-level call counts overlap. Token identities and metadata have not yet been independently verified.

The asset_key column preserves BigQuery's JSON key representation, which quotes identifiers containing punctuation.

Query: `sql/21_token_diff_assets.sql`
Results: `results/21_token_diff_assets_2026-10-15_to_2026-10-21.csv`

## 23 October 2026 — Metadata for the Five Leading Assets

I requested ft_metadata from the five contracts most frequently referenced in token_diff intents, using read-only NEAR mainnet RPC calls.

All five requests succeeded. The contracts reported USDT (6 decimals), USDC (6), ETH (18), USDT (6) and SOL (9), respectively, in descending order of asset appearances.

The saved responses include contract identifiers, retrieval timestamps, block heights and block hashes. Responses were retrieved on 23 October at blocks 221299760–221299786.

These are contract-reported metadata snapshots at the returned blocks, not historical metadata verified for 15–21 October. They do not independently establish asset backing. The two contracts reporting USDT remain separate asset identifiers.

Script: `analysis/06_fetch_token_metadata.py`
Results: `results/22_top_asset_metadata.json`

## 23 October 2026 — Token-Diff Amount Checks for Five Leading Assets

I examined positive and negative amounts for the five most frequently referenced assets in successful execute_intents calls dated 15–21 October, including execution outcomes recorded through 22 October.

The asset appearance counts and distinct call counts matched query 21. All selected amounts parsed as integers within BIGNUMERIC range, with zero invalid or out-of-range amounts. Checks across 293,410 token_diff intents found no missing, invalid or empty diff objects.

For each asset, positive, negative and zero entry counts reconciled to its appearance count. Net amounts reconciled to positive totals minus negative magnitudes. All five assets had negative net amounts, with negative magnitudes slightly exceeding positive totals.

Amounts remain in raw token units, and each contract is analysed separately. These totals describe signed token changes. They do not establish completed swaps, trading volume, protocol revenue or the cause of the net differences.

Query: `sql/23_top_asset_token_flows.sql`
Results: `results/23_top_asset_token_flows_2026-10-15_to_2026-10-21.csv`