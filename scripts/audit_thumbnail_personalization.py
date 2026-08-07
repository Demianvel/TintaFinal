#!/usr/bin/env python3
from __future__ import annotations

import json
import os
from pathlib import Path

import requests

UNIVERSE_ID = 8973271699
URL = f"https://apis.roblox.com/thumbnail-personalization-api/v1/universes/{UNIVERSE_ID}/personalization"
OUT = Path("automation/thumbnail-personalization.json")

key = os.environ.get("ROBLOX_API_KEY", "").strip()
if not key:
    raise RuntimeError("Falta ROBLOX_API_KEY")

response = requests.get(URL, headers={"x-api-key": key, "Accept": "application/json"}, timeout=60)
payload = {
    "statusCode": response.status_code,
    "ok": response.ok,
}
try:
    payload["response"] = response.json()
except ValueError:
    payload["responseText"] = response.text[:5000]

OUT.parent.mkdir(parents=True, exist_ok=True)
OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

if not response.ok:
    raise SystemExit(f"HTTP {response.status_code}: {response.text[:1500]}")

print(json.dumps(payload, indent=2, ensure_ascii=False))
