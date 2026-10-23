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