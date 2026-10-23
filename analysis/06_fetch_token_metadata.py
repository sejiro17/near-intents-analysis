import csv
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path

project_dir = Path(__file__).resolve().parents[1]
source_path = (
    project_dir
    / "results"
    / "21_token_diff_assets_2026-10-15_to_2026-10-21.csv"
)
output_path = (
    project_dir / "results" / "22_top_asset_metadata.json"
)

with source_path.open(newline="") as file:
    rows = list(csv.DictReader(file))

rows.sort(
    key=lambda row: int(row["intent_appearances"]),
    reverse=True,
)

records = []

for row in rows[:5]:
    asset_id = row["asset_key"]

    # JSON_KEYS quotes keys containing punctuation.
    if asset_id.startswith('"'):
        asset_id = json.loads(asset_id)

    if not asset_id.startswith("nep141:"):
        raise ValueError(f"Unexpected asset format: {asset_id}")

    contract = asset_id.removeprefix("nep141:")
    retrieved_at = datetime.now(timezone.utc).isoformat()

    payload = {
        "jsonrpc": "2.0",
        "id": "token-metadata",
        "method": "query",
        "params": {
            "request_type": "call_function",
            "finality": "final",
            "account_id": contract,
            "method_name": "ft_metadata",
            "args_base64": "e30=",
        },
    }

    record = {
        "asset_id": asset_id,
        "contract_account_id": contract,
        "intent_appearances": int(row["intent_appearances"]),
        "retrieved_at_utc": retrieved_at,
        "rpc_endpoint": "https://rpc.mainnet.near.org",
        "requested_finality": "final",
    }

    try:
        response = subprocess.run(
            [
                "curl",
                "--silent",
                "--show-error",
                "--fail",
                "--max-time",
                "30",
                "https://rpc.mainnet.near.org",
                "-H",
                "Content-Type: application/json",
                "--data",
                json.dumps(payload),
            ],
            capture_output=True,
            text=True,
            check=True,
        )

        data = json.loads(response.stdout)

        if "error" in data:
            record["error"] = data["error"]
            print(f"{contract}: RPC error")
        else:
            result = data["result"]
            metadata = json.loads(
                bytes(result["result"]).decode("utf-8")
            )

            record["block_height"] = result["block_height"]
            record["block_hash"] = result["block_hash"]
            record["metadata"] = {
                key: metadata.get(key)
                for key in (
                    "spec",
                    "name",
                    "symbol",
                    "decimals",
                    "reference",
                    "reference_hash",
                )
            }

            print(
                f"{contract}: "
                f"{metadata.get('name')} | "
                f"{metadata.get('symbol')} | "
                f"decimals={metadata.get('decimals')}"
            )

    except (
        subprocess.CalledProcessError,
        ValueError,
        KeyError,
        TypeError,
    ) as error:
        record["error"] = str(error)
        print(f"{contract}: request or decoding failed")

    records.append(record)

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(
    json.dumps(records, indent=2) + "\n",
    encoding="utf-8",
)

print(f"\nMetadata saved: {output_path}")