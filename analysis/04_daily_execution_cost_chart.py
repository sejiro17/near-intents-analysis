import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter

project_dir = Path(__file__).resolve().parents[1]
csv_path = (
    project_dir
    / "results"
    / "17_daily_execution_costs_2026-10-15_to_2026-10-21.csv"
)

with csv_path.open(newline="") as file:
    rows = list(csv.DictReader(file))

dates = sorted({row["call_date"] for row in rows})
positions = list(range(len(dates)))

categories = [
    "Successful receipts",
    "Failures: escrow.ai.near",
    "Failures: all other accounts",
]
colors = ["#247B73", "#C75B5B", "#E6AB45"]
costs = {category: [0.0] * len(dates) for category in categories}

for row in rows:
    for column in (
        "unmatched_receipts",
        "missing_gas_values",
        "missing_token_values",
        "negative_gas_values",
        "negative_token_values",
    ):
        if int(row[column]) != 0:
            raise ValueError(f"Data check failed: {column}")

    if row["status"] == "SUCCESS_VALUE":
        category = "Successful receipts"
    elif row["status"] == "FAILURE":
        if row["account_group"] == "escrow.ai.near":
            category = "Failures: escrow.ai.near"
        else:
            category = "Failures: all other accounts"
    else:
        raise ValueError(f"Unexpected status: {row['status']}")

    date_position = dates.index(row["call_date"])
    costs[category][date_position] += float(
        row["total_tokens_burnt_near"]
    )

fig, ax = plt.subplots(figsize=(11, 6.5))
bottom = [0.0] * len(dates)

for category, color in zip(categories, colors):
    values = costs[category]
    ax.bar(
        positions,
        values,
        bottom=bottom,
        label=category,
        color=color,
    )
    bottom = [
        base + value for base, value in zip(bottom, values)
    ]

for position, total in zip(positions, bottom):
    ax.annotate(
        f"{total:.2f}",
        (position, total),
        xytext=(0, 5),
        textcoords="offset points",
        ha="center",
        fontsize=10,
    )

ax.set_title(
    "NEAR Intents: daily receipt execution costs",
    loc="left",
    fontsize=16,
    pad=20,
)
ax.set_ylabel("Recorded tokens_burnt (NEAR)")
ax.set_xticks(positions)
ax.set_xticklabels([f"{date[-2:]} Oct" for date in dates])
ax.yaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
ax.set_ylim(0, max(bottom) * 1.25)
ax.set_axisbelow(True)
ax.grid(axis="y", alpha=0.2)
ax.spines[["top", "right"]].set_visible(False)
ax.legend(frameon=False, loc="upper left", fontsize=9)

fig.text(
    0.09,
    0.025,
    "15–21 October 2026 | Source: NEAR public data on BigQuery\n"
    "Target execute_intents receipts only; excludes other upstream "
    "and downstream outcomes.\n"
    "Approximate amounts. This measures recorded execution costs, "
    "not protocol revenue or net supply reduction.",
    fontsize=9,
    color="#555555",
)

fig.tight_layout(rect=[0, 0.13, 1, 1])

output_path = project_dir / "charts" / "03_daily_execution_costs.png"
output_path.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(output_path, dpi=200, bbox_inches="tight")
plt.close(fig)

print(f"Chart saved: {output_path}")