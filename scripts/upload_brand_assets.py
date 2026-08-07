#!/usr/bin/env python3
"""Render and upload all Tinta Final competitive brand images to Roblox Open Cloud."""

# Trigger: 2026-08-06 permisos de assets, sesiones Luau y miniatura del universo habilitados.
from __future__ import annotations

import json
import os
import re
import time
from pathlib import Path

import cairosvg
import requests

API_ROOT = "https://apis.roblox.com/assets/v1"
USERS_API = "https://users.roblox.com/v1/usernames/users"
OUTPUT_DIR = Path("build/branding")
RESULT_FILE = Path("automation/brand-assets.json")
CONFIG_FILE = Path("src/shared/VisualConfig.lua")

ASSETS = {
    "MainMenu": Path("assets/branding/main.svg"),
    "Loading": Path("assets/branding/loading.svg"),
    "Lobby": Path("assets/branding/lobby.svg"),
    "Round1": Path("assets/branding/round1.svg"),
    "Round2": Path("assets/branding/round2.svg"),
    "Shop": Path("assets/branding/shop.svg"),
}


def require_env(name: str, fallback: str | None = None) -> str:
    value = os.environ.get(name, fallback or "").strip()
    if not value:
        raise SystemExit(f"Falta la variable o secreto {name}.")
    return value


def resolve_creator_id(username: str, explicit_id: str = "") -> int:
    if explicit_id.strip():
        try:
            return int(explicit_id)
        except ValueError as exc:
            raise RuntimeError("ROBLOX_CREATOR_ID debe ser numérico.") from exc

    response = requests.post(
        USERS_API,
        json={"usernames": [username], "excludeBannedUsers": True},
        timeout=30,
    )
    response.raise_for_status()
    users = response.json().get("data", [])
    if not users:
        raise RuntimeError(f"Roblox no encontró el usuario {username!r}.")
    creator_id = users[0].get("id")
    if not isinstance(creator_id, int) or creator_id <= 0:
        raise RuntimeError(f"Respuesta de usuario inesperada: {users[0]!r}")
    print(f"Propietario resuelto: {users[0].get('name')} ({creator_id})")
    return creator_id


def render_svg(source: Path, output: Path) -> None:
    if not source.is_file():
        raise FileNotFoundError(source)
    output.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(source),
        write_to=str(output),
        output_width=1280,
        output_height=720,
    )
    if output.stat().st_size <= 0:
        raise RuntimeError(f"No se pudo renderizar {source}")


def create_asset(api_key: str, creator_id: int, key: str, image_path: Path) -> str:
    request_data = {
        "assetType": "Decal",
        "displayName": f"Tinta Final Competitive - {key}",
        "description": "Arte oficial de Tinta Final Competitive Arena.",
        "creationContext": {"creator": {"userId": creator_id}},
    }

    with image_path.open("rb") as handle:
        response = requests.post(
            f"{API_ROOT}/assets",
            headers={"x-api-key": api_key},
            files={
                "request": (None, json.dumps(request_data), "application/json"),
                "fileContent": (image_path.name, handle, "image/png"),
            },
            timeout=120,
        )
    if not response.ok:
        raise RuntimeError(
            f"Roblox rechazó {key}: HTTP {response.status_code} - {response.text[:1500]}"
        )

    payload = response.json()
    operation_path = str(payload.get("path", ""))
    if not operation_path.startswith("operations/"):
        raise RuntimeError(f"Respuesta inesperada al crear {key}: {payload}")

    operation_id = operation_path.split("/", 1)[1]
    for _ in range(120):
        status = requests.get(
            f"{API_ROOT}/operations/{operation_id}",
            headers={"x-api-key": api_key},
            timeout=60,
        )
        if not status.ok:
            raise RuntimeError(
                f"No se pudo consultar la operación {operation_id}: "
                f"HTTP {status.status_code} - {status.text[:1000]}"
            )
        operation = status.json()
        if operation.get("done"):
            if operation.get("error"):
                raise RuntimeError(f"Roblox rechazó {key}: {operation['error']}")
            asset_id = str(operation.get("response", {}).get("assetId", "")).strip()
            if not asset_id:
                raise RuntimeError(f"La operación terminó sin assetId: {operation}")
            return asset_id
        time.sleep(5)

    raise TimeoutError(f"La carga de {key} excedió el tiempo de espera.")


def update_visual_config(ids: dict[str, str]) -> None:
    content = CONFIG_FILE.read_text(encoding="utf-8")
    replacements = dict(ids)
    replacements["Icon"] = ids["MainMenu"]
    for key, value in replacements.items():
        content, count = re.subn(
            rf"(\s*{re.escape(key)}\s*=\s*)\d+(,)",
            rf"\g<1>{value}\g<2>",
            content,
            count=1,
        )
        if count != 1:
            raise RuntimeError(f"No se encontró {key} en {CONFIG_FILE}")
    CONFIG_FILE.write_text(content, encoding="utf-8")


def main() -> None:
    api_key = require_env("ROBLOX_API_KEY")
    username = require_env("ROBLOX_CREATOR_USERNAME", "demianvelo")
    creator_id = resolve_creator_id(username, os.environ.get("ROBLOX_CREATOR_ID", ""))
    force = os.environ.get("FORCE_UPLOAD", "false").lower() == "true"

    if RESULT_FILE.exists() and not force:
        cached = json.loads(RESULT_FILE.read_text(encoding="utf-8"))
        if all(str(cached.get(key, "")).isdigit() and int(cached[key]) > 0 for key in ASSETS):
            print("Los assets competitivos ya existen; se reutilizan los IDs guardados.")
            update_visual_config({key: str(cached[key]) for key in ASSETS})
            return

    asset_ids: dict[str, str] = {}
    for key, svg_path in ASSETS.items():
        png_path = OUTPUT_DIR / f"{key}.png"
        print(f"Renderizando {svg_path} -> {png_path}")
        render_svg(svg_path, png_path)
        print(f"Subiendo {key} a Roblox...")
        asset_ids[key] = create_asset(api_key, creator_id, key, png_path)
        print(f"{key}: {asset_ids[key]}")

    RESULT_FILE.parent.mkdir(parents=True, exist_ok=True)
    RESULT_FILE.write_text(
        json.dumps(
            {
                **asset_ids,
                "CreatorUsername": username,
                "CreatorId": creator_id,
            },
            indent=2,
            ensure_ascii=False,
        ) + "\n",
        encoding="utf-8",
    )
    update_visual_config(asset_ids)
    print(json.dumps(asset_ids, indent=2))


if __name__ == "__main__":
    main()
