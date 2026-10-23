import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter

project_dir = Path(__file__).resolve().parents[1]
csv_path = (
    project_dir
    / "results"
    / "10_daily_failure_concentration_2026-10-15_to_2026-10-21.csv"
)

with csv_path.open(newline="") as file:
    rows = list(csv.DictReader(file))

dates = sorted({row["block_date"] for row in rows})

successful = []
other_failures = []
escrow_failures = []

for date in dates:
    daily_rows = [row for row in rows if row["block_date"] == date]

    successful.append(
        sum(int(row["successful_calls"]) for row in daily_rows)
    )
    other_failures.append(
        sum(
            int(row["failed_calls"])
            for row in daily_rows
            if row["account_group"] == "All other accounts"
        )
    )
    escrow_failures.append(
        sum(
            int(row["failed_calls"])
            for row in daily_rows
            if row["account_group"] == "escrow.ai.near"
        )
    )

fig, ax = plt.subplots(figsize=(11, 6))

ax.bar(dates, successful, label="Successful receipt executions",
       color="#247B73")
ax.bar(dates, other_failures, bottom=successful,
       label="Failures: all other accounts", color="#E6AB45")

failure_base = [
    success + failed
    for success, failed in zip(successful, other_failures)
]
ax.bar(dates, escrow_failures, bottom=failure_base,
       label="Failures: escrow.ai.near", color="#C75B5B")

ax.set_title(
    "NEAR Intents: daily execution outcomes",
    loc="left",
    fontsize=16,
    pad=18,
)
ax.set_ylabel("execute_intents calls")
ax.set_xticks(range(len(dates)))
ax.set_xticklabels([f"{date[-2:]} Oct" for date in dates])
ax.yaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
ax.set_axisbelow(True)
ax.grid(axis="y", alpha=0.2)
ax.spines[["top", "right"]].set_visible(False)
ax.legend(frameon=False, loc="upper left", bbox_to_anchor=(0, 1.01))

fig.text(
    0.08, 0.04,
    "15–21 October 2026 | Source: NEAR public data on BigQuery\n"
    "Successful receipt execution does not establish a completed swap.",
    fontsize=9,
    color="#555555",
)

fig.tight_layout(rect=[0, 0.11, 1, 1])

output_path = project_dir / "charts" / "01_daily_execution_outcomes.png"
output_path.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(output_path, dpi=200, bbox_inches="tight")
plt.close(fig)

print(f"Chart saved: {output_path}")

