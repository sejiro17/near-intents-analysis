import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import PercentFormatter, StrMethodFormatter

project_dir = Path(__file__).resolve().parents[1]
csv_path = (
    project_dir
    / "results"
    / "16_daily_signer_activity_2026-10-15_to_2026-10-21.csv"
)

with csv_path.open(newline="") as file:
    rows = sorted(csv.DictReader(file), key=lambda row: row["block_date"])

dates = [row["block_date"] for row in rows]
labels = [f"{date[-2:]} Oct" for date in dates]
positions = list(range(len(rows)))

active = [int(row["active_signers"]) for row in rows]
first_observed = [
    int(row["first_observed_signers"]) for row in rows
]
previously_observed = [
    int(row["previously_observed_signers"]) for row in rows
]

for row in rows:
    assert int(row["active_signers"]) == (
        int(row["first_observed_signers"])
        + int(row["previously_observed_signers"])
    ), f"Participation counts do not reconcile: {row['block_date']}"

    for column in (
        "undecodable_calls",
        "calls_without_nonempty_signed_array",
        "items_without_extracted_signer",
    ):
        assert int(row[column]) == 0, (
            f"Extraction coverage issue: {row['block_date']} / {column}"
        )

previous_share = [
    100 * previous / total
    for previous, total in zip(previously_observed, active)
]

fig, (ax_counts, ax_share) = plt.subplots(
    2,
    1,
    figsize=(11, 8),
    sharex=True,
    gridspec_kw={"height_ratios": [2, 1]},
)

fig.suptitle(
    "NEAR Intents: daily signer participation",
    x=0.10,
    ha="left",
    fontsize=17,
)

ax_counts.bar(
    positions,
    first_observed,
    label="First observed within selected week",
    color="#247B73",
)
ax_counts.bar(
    positions,
    previously_observed,
    bottom=first_observed,
    label="Observed on an earlier day within week",
    color="#E6AB45",
)

for position, total in zip(positions, active):
    ax_counts.annotate(
        f"{total:,}",
        (position, total),
        xytext=(0, 5),
        textcoords="offset points",
        ha="center",
        fontsize=9,
    )

ax_counts.set_ylabel("Distinct active signer identifiers")
ax_counts.yaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
ax_counts.set_ylim(0, max(active) * 1.22)
ax_counts.legend(frameon=False, loc="upper left", fontsize=9)

# The first day has no earlier observation days in this window.
ax_share.plot(
    positions[1:],
    previous_share[1:],
    marker="o",
    linewidth=2,
    color="#A66B12",
)

for position, share in zip(positions[1:], previous_share[1:]):
    ax_share.annotate(
        f"{share:.2f}%",
        (position, share),
        xytext=(0, 8),
        textcoords="offset points",
        ha="center",
        fontsize=9,
    )

ax_share.text(
    0,
    0.25,
    "Window starts",
    ha="center",
    fontsize=9,
    color="#666666",
)
ax_share.set_ylabel("Previously observed share")
ax_share.yaxis.set_major_formatter(PercentFormatter(xmax=100))
ax_share.set_ylim(0, max(previous_share[1:]) + 0.9)
ax_share.set_xticks(positions)
ax_share.set_xticklabels(labels)

for ax in (ax_counts, ax_share):
    ax.set_axisbelow(True)
    ax.grid(axis="y", alpha=0.2)
    ax.spines[["top", "right"]].set_visible(False)

fig.text(
    0.10,
    0.025,
    "15–21 October 2026 | Successful execute_intents calls | "
    "Source: NEAR public data on BigQuery\n"
    "First observed refers to this window, not first-ever use. "
    "Signer identifiers are not necessarily people.\n"
    "Previously observed share describes daily composition, "
    "not cohort retention.",
    fontsize=9,
    color="#555555",
)

fig.tight_layout(rect=[0, 0.11, 1, 0.95])

output_path = project_dir / "charts" / "02_daily_signer_participation.png"
output_path.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(output_path, dpi=200, bbox_inches="tight")
plt.close(fig)

print(f"Chart saved: {output_path}")