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