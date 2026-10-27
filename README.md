# NEAR Intents Activity Analysis

I analysed seven days of NEAR Intents activity to understand execution failures, repeat signer participation and recorded execution costs.

The main finding was that one submitting account accounted for **95.06% of failures**—important context behind the overall failure rate of **30.50%**.

The analysis covers `execute_intents` calls to `intents.near` dated **15–21 October 2026**, including execution outcomes recorded through 22 October.

## What I Investigated

- How often the selected receipts executed successfully or failed.
- Whether failures were concentrated in particular submitting accounts.
- How signer identifiers participated across the week.
- Which intent types and assets appeared in successful calls.
- How recorded execution costs differed between successful and failed receipts.

## Key Findings

### One submitting account accounted for most failures

The selected week contained **402,695 calls**: 279,856 successful receipt executions and 122,839 failures.

`escrow.ai.near` submitted 116,775 calls, all of which failed. It contributed **95.06% of the week's failures**. Across all other submitting accounts combined, the failure rate was **2.12%**.

One inspected failure reported “insufficient balance or overflow.” That example does not establish a common cause across the remaining failures or show whether they were retries.

![Daily execution outcomes](charts/01_daily_execution_outcomes.png)

### Most signer identifiers appeared on one day

Successful calls contained **502,916 signed items** across **147,573 distinct signer identifiers**.

Of those identifiers, 146,301 (**99.14%**) appeared on only one day. The remaining 1,272 appeared on multiple days, including 131 active on all seven days.

Among the fixed cohort of 22,520 signers active on 15 October, daily participation on subsequent days ranged from **1.15% to 1.39%** of the starting cohort.

These are account-identifier observations within a short window, not verified user-retention or churn rates. Signer ownership and roles remain unverified.

![Daily signer participation](charts/02_daily_signer_participation.png)

### Failed receipts represented a smaller share of cost than of calls

Recorded execution costs for the selected receipts totalled approximately **292.12 NEAR**.

| Outcome | Receipts | Recorded cost (NEAR) |
|---|---:|---:|
| Successful | 279,856 | 248.8194 |
| Failed | 122,839 | 43.2985 |
| Total | 402,695 | 292.1178 |

Failed receipts represented **30.50% of calls** and **14.82% of recorded execution costs**.

Amounts are approximate and rounded independently. They cover the selected receipts, not every upstream and downstream execution step. They do not measure protocol revenue or permanent token supply reduction.

![Daily receipt execution costs](charts/03_daily_execution_costs.png)

### Successful calls contained several kinds of intent

The signed items contained **834,900 individual intents across ten types**.

Transfers accounted for **44.67%**, `token_diff` for **35.14%**, and `ft_withdraw` for **15.62%**.

A call can contain multiple signed items and intent types. These counts therefore describe individual intents, not distinct calls or completed swaps.

![Intent type activity](charts/04_intent_type_activity.png)

### Asset references were concentrated

Across **293,410 `token_diff` intents**, 1,626 distinct asset identifiers accounted for 584,173 asset appearances.

The five most frequently referenced assets contributed **54.45% of appearances**. Their contracts reported the symbols USDT, USDC, ETH, USDT and SOL. The two USDT contracts remain separate assets.

Metadata was retrieved on 23 October 2026, with block references preserved in [the metadata snapshot](results/22_top_asset_metadata.json).

Reference frequency is not trading volume. Token amounts for these five assets were also normalised using the recorded decimals and exact decimal arithmetic; historical decimals were not independently verified.

![Most referenced token-diff assets](charts/05_top_token_diff_assets.png)

## Data and Validation

**Source:** `bigquery-public-data.crypto_near_mainnet_us`

The analysis selects `FUNCTION_CALL` actions targeting `intents.near` with the method name `execute_intents`, then links them to execution outcomes by receipt identifier.

For the selected week:

- Each selected call corresponded to a distinct receipt.
- Every selected receipt matched exactly one execution outcome.
- Success and failure counts reconciled to the call totals.
- Successful-call arguments were decoded from Base64 and parsed as JSON.
- Signer extraction covered all signed items across the seven observed signing formats.
- Cost checks found no missing or negative gas or token-cost values.

Recorded token costs are converted from yoctoNEAR to NEAR by dividing by `10^24`. Source cost fields use floating-point storage, so reported amounts are approximate.

Detailed methods, coverage checks and investigation notes are recorded in [notes/data_checks.md](notes/data_checks.md).

## Interpretation Boundaries

- Seven days cannot establish sustained adoption.
- Successful receipt execution does not establish a completed swap or successful downstream execution.
- Submitting accounts, signer identifiers, signed items and individual intents measure different things.
- Signer identifiers are not verified people, and their roles remain unverified.
- First observed means first seen within this window, not first-ever use.
- Failure causes and retries have not been established across the dataset.
- Asset appearances are not trading volume, and recorded execution costs do not establish investment value accruing to NEAR holders.

## Reproduce the Charts

The charts use saved CSV exports, so reproducing them does not require another BigQuery scan.

With Python 3 installed, run from the repository root:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt

python analysis/01_daily_execution_chart.py
python analysis/03_daily_signer_chart.py
python analysis/04_daily_execution_cost_chart.py
python analysis/05_intent_type_chart.py
python analysis/07_top_asset_chart.py
```

Generated images are saved in `charts/`.

The repository also includes scripts for inspecting signed intents, fetching asset metadata and normalising token amounts. Fetching fresh metadata requires network access and may produce a different snapshot.

SQL queries are stored in `sql/`. Running them requires BigQuery access and may incur query charges.

## Repository Structure

| Directory | Contents |
|---|---|
| `sql/` | Data checks and analytical queries. |
| `results/` | Exported query results, metadata and derived results. |
| `analysis/` | Python scripts for inspection, metadata retrieval, normalisation and charts. |
| `charts/` | Generated visualisations. |
| `notes/` | Research findings, validation checks and interpretation boundaries. |

**Built with:** SQL, Google BigQuery, Python and Matplotlib.