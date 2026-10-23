import csv
import json
from decimal import Decimal, localcontext
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FLOW_PATH = (
    ROOT / "results"
    / "23_top_asset_token_flows_2026-10-15_to_2026-10-21.csv"
)
METADATA_PATH = ROOT / "results" / "22_top_asset_metadata.json"
OUTPUT_PATH = (
    ROOT / "results"
    / "24_top_asset_normalised_amounts_2026-10-15_to_2026-10-21.csv"
)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def main():
    with METADATA_PATH.open(encoding="utf-8") as source:
        metadata_records = json.load(source)

    metadata_by_asset = {}
    for record in metadata_records:
        asset_id = record["asset_id"]
        require(
            asset_id not in metadata_by_asset,
            f"Duplicate metadata: {asset_id}",
        )
        require(
            not record.get("error"),
            f"Metadata lookup failed: {asset_id}",
        )
        metadata_by_asset[asset_id] = record

    with FLOW_PATH.open(newline="", encoding="utf-8") as source:
        flows = list(csv.DictReader(source))

    asset_ids = [row["asset_id"] for row in flows]
    require(len(flows) == 5, "Expected five asset rows.")
    require(len(set(asset_ids)) == 5, "Duplicate flow asset.")
    require(
        set(asset_ids) == set(metadata_by_asset),
        "Flow and metadata asset sets do not match.",
    )

    output_rows = []

    with localcontext() as context:
        context.prec = 100

        for row in flows:
            asset_id = row["asset_id"]
            record = metadata_by_asset[asset_id]
            metadata = record["metadata"]
            decimals = metadata["decimals"]

            require(
                type(decimals) is int and 0 <= decimals <= 255,
                f"Invalid decimals: {asset_id}",
            )

            for field in (
                "invalid_or_out_of_range_amounts",
                "missing_or_invalid_diff_objects",
                "empty_diff_objects",
            ):
                require(
                    int(row[field]) == 0,
                    f"{field} is nonzero: {asset_id}",
                )

            appearances = int(row["intent_appearances"])
            entry_count = sum(
                int(row[field])
                for field in (
                    "positive_entries",
                    "negative_entries",
                    "zero_entries",
                )
            )

            require(
                appearances == entry_count,
                f"Entry counts do not reconcile: {asset_id}",
            )
            require(
                appearances == int(record["intent_appearances"]),
                f"Metadata appearance count differs: {asset_id}",
            )

            raw_values = {
                field: Decimal(row[field])
                for field in (
                    "positive_raw_amount",
                    "negative_raw_amount_magnitude",
                    "net_raw_amount",
                )
            }

            for field, value in raw_values.items():
                require(
                    value.is_finite()
                    and value == value.to_integral_value(),
                    f"Invalid raw integer in {field}: {asset_id}",
                )

            positive = raw_values["positive_raw_amount"]
            negative = raw_values["negative_raw_amount_magnitude"]
            net = raw_values["net_raw_amount"]

            require(
                positive >= 0 and negative >= 0,
                f"Negative magnitude total: {asset_id}",
            )
            require(
                positive - negative == net,
                f"Raw amounts do not reconcile: {asset_id}",
            )

            scale = Decimal(10) ** decimals

            output_rows.append({
                "asset_id": asset_id,
                "contract_account_id": record["contract_account_id"],
                "symbol": metadata["symbol"],
                "decimals": decimals,
                "intent_appearances": appearances,
                "successful_calls_containing_asset":
                    row["successful_calls_containing_asset"],
                "positive_token_amount": format(positive / scale, "f"),
                "negative_token_amount_magnitude":
                    format(negative / scale, "f"),
                "net_token_amount": format(net / scale, "f"),
                "metadata_retrieved_at_utc":
                    record["retrieved_at_utc"],
                "metadata_block_height": record["block_height"],
                "metadata_block_hash": record["block_hash"],
            })

    with OUTPUT_PATH.open(
        "w", newline="", encoding="utf-8"
    ) as destination:
        writer = csv.DictWriter(
            destination,
            fieldnames=list(output_rows[0]),
        )
        writer.writeheader()
        writer.writerows(output_rows)

    print("All five assets passed validation.")
    print(f"Results saved: {OUTPUT_PATH}")
    print(
        "Units use the 23 October metadata snapshot; "
        "historical decimals have not been independently verified."
    )


if __name__ == "__main__":
    main()
    