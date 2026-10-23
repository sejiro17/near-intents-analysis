import base64
import csv
import json
from pathlib import Path

project_dir = Path(__file__).resolve().parents[1]
csv_path = (
    project_dir
    / "results"
    / "11_successful_intents_sample_2026-10-21.csv"
)

with csv_path.open(newline="") as file:
    rows = list(csv.DictReader(file))

for row_number, row in enumerate(rows, start=1):
    print(f"\n--- Sample call {row_number} ---")
    print("Receipt:", row["receipt_id"])
    print("Submitting account:", row["submitting_account"])

    try:
        wrapper = json.loads(row["args"])
        decoded = base64.b64decode(
            wrapper["args_base64"], validate=True
        ).decode("utf-8")
        call_args = json.loads(decoded)
    except (KeyError, ValueError, UnicodeDecodeError) as error:
        print("Could not decode arguments:", error)
        continue

    signed_items = call_args.get("signed")
    if not isinstance(signed_items, list):
        print("No signed array found. Keys:", list(call_args))
        continue

    print("Signed items:", len(signed_items))

    for item_number, item in enumerate(signed_items, start=1):
        print(f"\n  Signed item {item_number}")
        print("  Standard:", item.get("standard"))

        payload = item.get("payload")
        if not isinstance(payload, dict):
            print("  Payload needs separate inspection.")
            continue

        message = payload.get("message")
        if not isinstance(message, str):
            print("  No text message found. Payload keys:", list(payload))
            continue

        try:
            message_data = json.loads(message)
        except ValueError:
            print("  Message is not JSON; needs separate inspection.")
            continue

        if not isinstance(message_data, dict):
            print("  Message is not a JSON object.")
            continue

        print("  Signer:", message_data.get("signer_id"))
        print(
            "  Intent types:",
            [
                intent.get("intent")
                for intent in message_data.get("intents", [])
                if isinstance(intent, dict)
            ],
        )