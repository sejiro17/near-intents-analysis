import csv
import json
from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.ticker import StrMethodFormatter

project_dir = Path(__file__).resolve().parents[1]
results_dir = project_dir / "results"

with (
    results_dir / "21_token_diff_assets_2026-10-15_to_2026-10-21.csv"
).open(newline="") as file:
    rows = list(csv.DictReader(file))

metadata_records = json.loads(
    (results_dir / "22_top_asset_metadata.json").read_text(
        encoding="utf-8"
    )
)

metadata_by_asset = {
    record["asset_id"]: record
    for record in metadata_records
    if "error" not in record
}

rows.sort(
    key=lambda row: int(row["intent_appearances"]),
    reverse=True,
)

total_appearances = sum(
    int(row["intent_appearances"]) for row in rows
)

labels = []
counts = []

for row in rows[:5]:
    asset_id = row["asset_key"]
    if asset_id.startswith('"'):
        asset_id = json.loads(asset_id)

    record = metadata_by_asset.get(asset_id)
    if record is None:
        raise ValueError(f"Metadata missing: {asset_id}")

    count = int(row["intent_appearances"])
    if count != record["intent_appearances"]:
        raise ValueError(f"Appearance counts differ: {asset_id}")

    symbol = record["metadata"]["symbol"]
    contract = record["contract_account_id"]

    if contract.startswith("eth-"):
        context = "eth-prefixed contract"
    elif contract.startswith("tron-"):
        context = "tron-prefixed contract"
    else:
        context = contract

    labels.append(f"{symbol}\n{context}")
    counts.append(count)

if total_appearances != 584173:
    raise ValueError("Asset appearance total does not reconcile.")

positions = list(range(len(counts)))
shares = [
    100 * count / total_appearances for count in counts
]

fig, ax = plt.subplots(figsize=(11, 6.5))

ax.barh(positions, counts, color="#247B73")
ax.set_yticks(positions)
ax.set_yticklabels(labels)
ax.invert_yaxis()

for position, count, share in zip(positions, counts, shares):
    ax.text(
        count + max(counts) * 0.02,
        position,
        f"{count:,} ({share:.2f}%)",
        va="center",
        fontsize=10,
    )

ax.set_title(
    "NEAR Intents: five most referenced token-diff assets",
    loc="left",
    fontsize=15,
    pad=20,
)
ax.set_xlabel("Asset appearances in individual token_diff intents")
ax.xaxis.set_major_formatter(StrMethodFormatter("{x:,.0f}"))
ax.set_xlim(0, max(counts) * 1.40)
ax.set_axisbelow(True)
ax.grid(axis="x", alpha=0.2)
ax.spines[["top", "right", "left"]].set_visible(False)
ax.tick_params(axis="y", length=0)

fig.text(
    0.08,
    0.025,
    "15–21 October 2026 | Successful execute_intents calls\n"
    "Shares use all 584,173 asset appearances. "
    "Names use contract-reported metadata retrieved on 23 October.\n"
    "Separate contracts remain separate assets. "
    "Frequency does not measure trading volume or completed swaps.\n"
    "Sources: NEAR public data on BigQuery and NEAR mainnet RPC.",
    fontsize=9,
    color="#555555",
)

fig.tight_layout(rect=[0, 0.17, 1, 1])

output_path = (
    project_dir / "charts" / "05_top_token_diff_assets.png"
)
output_path.parent.mkdir(parents=True, exist_ok=True)
fig.savefig(output_path, dpi=200, bbox_inches="tight")
plt.close(fig)

print(f"Chart saved: {output_path}")