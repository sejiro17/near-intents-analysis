# Data Checks

## 22 October 2026 - Latest Transaction Date 

I connected BigQuery to VS Code and checked the latest transaction date in bigquery-public-data.crypto_near_mainnet_us.transactions.
I limited the query to a recent date window to reduce the amount of data scanned. The latest date returned was 22 October 2026, confirming that the table contains transactions dated today.
This check doesn’t confirm that the data is complete or that it covers all NEAR Intents activity. I still need to investigate those before finalising the research question.

## 22 October 2026 — Execution Outcomes and Action Matching

I inspected five execution outcomes for intents.near dated 21 October 2026. Four had SUCCESS_VALUE status and one had FAILURE status. The failed outcome also contained logs, so logs alone cannot confirm successful execution.

I then joined receipt_actions to execution_outcomes using receipt_id, filtering for execute_intents function calls. All five sampled actions matched outcomes with SUCCESS_VALUE status.

These checks show that I can link sampled actions to their receipt execution results. They do not establish the overall success rate, confirm downstream swap completion, or validate matching across the full dataset.