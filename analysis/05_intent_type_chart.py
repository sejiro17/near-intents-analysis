import csv
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter

project_dir = Path(__file__).resolve().parents[1]
csv_path = (
    project_dir
    / "results"
    / "20_intent_type_activity_2026-10-15_to_2026-10-21.csv"
)

with csv_path.open(newline="") as file:
    rows = list(csv.DictReader(file))

if not rows:
    raise ValueError("The CSV contains no results.")

for row in rows:
    if int(row["signed_items_checked"]) != 502916:
        raise ValueError("Signed-item coverage does not reconcile.")

    if int(row["invalid_messages"]) != 0:
        raise ValueError("Invalid messages need investigation.")

    if int(row["items_without_intents_array"]) != 0:
        raise ValueError("Missing intent arrays need investigation.")

    if int(row["items_with_empty_intents_array"]) != 8:
        raise ValueError("The empty-array count has changed.")

    if not row["intent_type"].strip():
        raise ValueError("An intent type is missing.")

rows.sort(key=lambda row: int(row["intent_count"]), reverse=True)

labels = [row["intent_type"] for row in rows]
counts = [int(row["intent_count"]) for row in rows]
total = sum(counts)

if total != 834900:
    raise ValueError(f"Unexpected total intent count: {total:,}")

shares = [100 * count / total for count in counts]
positions = list(range(len(rows)))

fig, ax = plt.subplots(figsize=(12, 7.5))

colors = [
    "#247B73" if index < 3 else "#879DA8"
    for index in positions
]

ax.barh(positions, counts, color=colors)
ax.set_yticks(positions)
ax.set_yticklabels(labels)
ax.invert_yaxis()

label_padding = max(counts) * 0.015

for position, count, share in zip(positions, counts, shares):
    ax.text(
        count + label_padding,
        position,
        f"{count:,} ({share:.2f}%)",
        va="center",
        fontsize=10,
    )

ax.set_title(
    "NEAR Intents: intent types in successful calls",
    loc="left",
    fontsize=16,
    pad=20,
)
ax.set_xlabel("Individual intents")
ax.xaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
ax.set_xlim(0, max(counts) * 1.40)
ax.set_axisbelow(True)
ax.grid(axis="x", alpha=0.2)
ax.spines[["top", "right", "left"]].set_visible(False)
ax.tick_params(axis="y", length=0)

fig.text(
    0.08,
    0.025,
    "15–21 October 2026 | 834,900 intents | "
    "Source: NEAR public data on BigQuery\n"
    "502,916 signed items checked; eight contained empty intent arrays.\n"
    "Counts represent individual intents, not distinct calls, "
    "people or completed swaps.",
    fontsize=9,
    color="#555555",
)

fig.tight_layout(rect=[0, 0.13, 1, 1])

output_path = project_dir / "charts" / "04_intent_type_activity.png"
output_path.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(output_path, dpi=200, bbox_inches="tight")
plt.close(fig)

print(f"Chart saved: {output_path}")