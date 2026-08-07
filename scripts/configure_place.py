#!/usr/bin/env python3
"""Set the live Tinta Final Roblox place to 20 players per server and verify it."""

# Trigger de configuración: 2026-08-06 scopes Open Cloud habilitados.
from __future__ import annotations

import json
import os
from pathlib import Path

import requests

UNIVERSE_ID = 8973271699
PLACE_ID = 73618099851560
SERVER_SIZE = 20
URL = f"https://apis.roblox.com/cloud/v2/universes/{UNIVERSE_ID}/places/{PLACE_ID}"
STATUS = Path("automation/PLACE_CONFIG_STATUS.md")
RESULT = Path("automation/place-config.json")


def key() -> str:
    value = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not value:
        raise RuntimeError("Falta ROBLOX_API_KEY.")
    return value


def headers() -> dict[str, str]:
    return {"x-api-key": key(), "Accept": "application/json", "Content-Type": "application/json"}


def get_place() -> dict:
    response = requests.get(URL, headers=headers(), timeout=60)
    if not response.ok:
        raise RuntimeError(f"GET Place falló: HTTP {response.status_code} - {response.text[:1500]}")
    return response.json()


def update_server_size() -> dict:
    response = requests.patch(
        URL,
        params={"updateMask": "serverSize"},
        headers=headers(),
        json={"serverSize": SERVER_SIZE},
        timeout=60,
    )
    if not response.ok:
        raise RuntimeError(f"PATCH Place falló: HTTP {response.status_code} - {response.text[:1500]}")
    return response.json()


def write_status(place: dict, state: str = "CORRECTO") -> None:
    STATUS.parent.mkdir(parents=True, exist_ok=True)
    RESULT.write_text(json.dumps(place, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    STATUS.write_text(
        "# Configuración del servidor de Tinta Final\n\n"
        f"- Estado: {state}\n"
        f"- Universe ID: {UNIVERSE_ID}\n"
        f"- Place ID: {PLACE_ID}\n"
        f"- Jugadores máximos por servidor: {place.get('serverSize')}\n",
        encoding="utf-8",
    )


def main() -> None:
    before = get_place()
    print("Configuración actual:", json.dumps(before, ensure_ascii=False))
    if int(before.get("serverSize") or 0) != SERVER_SIZE:
        updated = update_server_size()
        print("Respuesta de actualización:", json.dumps(updated, ensure_ascii=False))
    after = get_place()
    if int(after.get("serverSize") or 0) != SERVER_SIZE:
        raise RuntimeError(f"Roblox no confirmó serverSize={SERVER_SIZE}: {after}")
    write_status(after)
    print(f"Servidor confirmado con {SERVER_SIZE} jugadores máximos.")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        STATUS.parent.mkdir(parents=True, exist_ok=True)
        STATUS.write_text(
            "# Configuración del servidor de Tinta Final\n\n"
            "- Estado: ERROR\n"
            f"- Universe ID: {UNIVERSE_ID}\n"
            f"- Place ID: {PLACE_ID}\n"
            f"- Objetivo: {SERVER_SIZE} jugadores por servidor\n"
            f"- Error: {exc}\n",
            encoding="utf-8",
        )
        raise
