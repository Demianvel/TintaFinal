#!/usr/bin/env python3
"""Create/resolve Tinta Final Game Passes and sync IDs into Lua config."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

import requests

UNIVERSE_ID = 8973271699
API_ROOT = f"https://apis.roblox.com/game-passes/v1/universes/{UNIVERSE_ID}/game-passes"
CONFIG_FILE = Path("src/shared/GamePassConfig.lua")
RESULT_FILE = Path("automation/game-passes.json")
STATUS_FILE = Path("automation/GAME_PASSES_STATUS.md")

PASSES = {
    "BattlePassPremium": {
        "name": "Tinta Final - Battle Pass Premium",
        "description": "Pista premium de la temporada competitiva de Tinta Final.",
        "price": 199,
    },
    "VIP": {
        "name": "Tinta Final - VIP",
        "description": "Beneficios VIP permanentes dentro de Tinta Final.",
        "price": 299,
    },
    "DoubleXP": {
        "name": "Tinta Final - 2X XP",
        "description": "Duplica permanentemente el XP ganado jugando.",
        "price": 149,
    },
    "SpinBooster": {
        "name": "Tinta Final - Lucky Spin Booster",
        "description": "Mejora permanente de suerte para la ruleta de Tinta Final.",
        "price": 99,
    },
    "Founder": {
        "name": "Tinta Final - Founder Pack",
        "description": "Paquete Founder con cosméticos exclusivos y bonus inicial.",
        "price": 499,
    },
}


def api_key() -> str:
    value = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not value:
        raise RuntimeError("Falta ROBLOX_API_KEY.")
    return value


def headers() -> dict[str, str]:
    return {"x-api-key": api_key(), "Accept": "application/json"}


def list_passes() -> list[dict]:
    result: list[dict] = []
    token = ""
    for _ in range(20):
        params: dict[str, object] = {"pageSize": 100}
        if token:
            params["pageToken"] = token
        response = requests.get(f"{API_ROOT}/creator", headers=headers(), params=params, timeout=60)
        if not response.ok:
            raise RuntimeError(f"No se pudieron listar Game Passes: HTTP {response.status_code} - {response.text[:1500]}")
        payload = response.json()
        result.extend(payload.get("gamePasses", []))
        token = str(payload.get("nextPageToken") or "")
        if not token:
            break
    return result


def create_pass(spec: dict) -> dict:
    multipart = {
        "name": (None, str(spec["name"])),
        "description": (None, str(spec["description"])),
        "isForSale": (None, "true"),
        "price": (None, str(int(spec["price"]))),
        "isRegionalPricingEnabled": (None, "false"),
    }
    response = requests.post(API_ROOT, headers=headers(), files=multipart, timeout=90)
    if not response.ok:
        raise RuntimeError(f"No se pudo crear {spec['name']}: HTTP {response.status_code} - {response.text[:1800]}")
    payload = response.json()
    game_pass_id = int(payload.get("gamePassId") or payload.get("id") or 0)
    if game_pass_id <= 0:
        raise RuntimeError(f"Roblox creó el pase sin gamePassId válido: {payload}")
    return payload


def update_config(ids: dict[str, int]) -> None:
    content = CONFIG_FILE.read_text(encoding="utf-8")
    for key, game_pass_id in ids.items():
        pattern = rf"({re.escape(key)}\s*=\s*\{{\s*GamePassId\s*=\s*)\d+"
        content, count = re.subn(pattern, rf"\g<1>{game_pass_id}", content, count=1)
        if count != 1:
            raise RuntimeError(f"No se encontró GamePassId de {key} en {CONFIG_FILE}")
    CONFIG_FILE.write_text(content, encoding="utf-8")


def main() -> None:
    existing = list_passes()
    by_name = {str(item.get("name")): item for item in existing}
    resolved: dict[str, int] = {}
    details: dict[str, dict] = {}

    for key, spec in PASSES.items():
        item = by_name.get(spec["name"])
        if item is None:
            print(f"Creando {spec['name']} ({spec['price']} Robux)...")
            item = create_pass(spec)
        else:
            print(f"Reutilizando {spec['name']} -> {item.get('gamePassId') or item.get('id')}")
        game_pass_id = int(item.get("gamePassId") or item.get("id") or 0)
        if game_pass_id <= 0:
            raise RuntimeError(f"GamePassId inválido para {key}: {item}")
        resolved[key] = game_pass_id
        details[key] = {
            "gamePassId": game_pass_id,
            "name": spec["name"],
            "priceRobux": spec["price"],
        }

    update_config(resolved)
    RESULT_FILE.parent.mkdir(parents=True, exist_ok=True)
    RESULT_FILE.write_text(
        json.dumps({"universeId": UNIVERSE_ID, "passes": details}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    STATUS_FILE.write_text(
        "# Game Passes de Tinta Final\n\n"
        "- Estado: CORRECTO\n"
        f"- Universe ID: {UNIVERSE_ID}\n"
        f"- Game Passes conectados: {len(resolved)}\n",
        encoding="utf-8",
    )
    print(json.dumps(details, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
