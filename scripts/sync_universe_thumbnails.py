#!/usr/bin/env python3
"""Upload Tinta Final artwork as real Roblox universe thumbnails and verify completion."""

from __future__ import annotations

import json
import os
import time
from contextlib import ExitStack
from pathlib import Path

import cairosvg
import requests

UNIVERSE_ID = 8973271699
API_ROOT = f"https://apis.roblox.com/thumbnail-personalization-api/v1/universes/{UNIVERSE_ID}"
OUTPUT_DIR = Path("build/universe-thumbnails")
RESULT_FILE = Path("automation/universe-thumbnails.json")
STATUS_FILE = Path("automation/UNIVERSE_THUMBNAILS_STATUS.md")

THUMBNAILS = {
    "TintaFinal-Main.png": Path("assets/branding/main.svg"),
    "TintaFinal-Lobby.png": Path("assets/branding/lobby.svg"),
    "TintaFinal-Round1.png": Path("assets/branding/round1.svg"),
    "TintaFinal-Round2.png": Path("assets/branding/round2.svg"),
    "TintaFinal-Shop.png": Path("assets/branding/shop.svg"),
}


def api_key() -> str:
    value = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not value:
        raise RuntimeError("Falta ROBLOX_API_KEY.")
    return value


def headers() -> dict[str, str]:
    return {"x-api-key": api_key(), "Accept": "application/json"}


def render_all() -> dict[str, Path]:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    rendered: dict[str, Path] = {}
    for filename, source in THUMBNAILS.items():
        if not source.is_file():
            raise FileNotFoundError(source)
        output = OUTPUT_DIR / filename
        cairosvg.svg2png(
            url=str(source),
            write_to=str(output),
            output_width=1280,
            output_height=720,
        )
        if output.stat().st_size <= 0:
            raise RuntimeError(f"No se pudo renderizar {source}")
        rendered[filename] = output
    return rendered


def upload(rendered: dict[str, Path]) -> dict:
    with ExitStack() as stack:
        files = []
        for filename, path in rendered.items():
            handle = stack.enter_context(path.open("rb"))
            files.append(("files", (filename, handle, "image/png")))
        response = requests.post(
            f"{API_ROOT}/thumbnails/uploads",
            headers=headers(),
            files=files,
            timeout=180,
        )
    if not response.ok:
        raise RuntimeError(f"Carga de miniaturas falló: HTTP {response.status_code} - {response.text[:2000]}")
    payload = response.json()
    operations = payload.get("fileToOperationIdDict") or {}
    if not operations:
        raise RuntimeError(f"Roblox no devolvió operation IDs: {payload}")
    return payload


def poll(upload_payload: dict) -> dict:
    operation_map = upload_payload.get("fileToOperationIdDict") or {}
    operation_ids = [str(value) for value in operation_map.values() if value]
    if not operation_ids:
        raise RuntimeError("No hay operation IDs para verificar.")

    last: dict = {}
    for _ in range(60):
        params = [("operationIds", operation_id) for operation_id in operation_ids]
        response = requests.get(
            f"{API_ROOT}/thumbnails/uploads/status",
            headers=headers(),
            params=params,
            timeout=60,
        )
        if not response.ok:
            raise RuntimeError(f"Consulta de miniaturas falló: HTTP {response.status_code} - {response.text[:2000]}")
        last = response.json()
        status_map = last.get("uploadThumbnailStatusDict") or {}
        completed = 0
        for operation_id in operation_ids:
            item = status_map.get(operation_id) or {}
            if item.get("homepageThumbnailId") and int(item.get("assetId") or 0) > 0:
                completed += 1
        print(f"Miniaturas verificadas: {completed}/{len(operation_ids)}")
        if completed == len(operation_ids):
            return last
        time.sleep(5)
    raise TimeoutError(f"Roblox no terminó de procesar las miniaturas: {last}")


def main() -> None:
    rendered = render_all()
    upload_payload = upload(rendered)
    status_payload = poll(upload_payload)

    RESULT_FILE.parent.mkdir(parents=True, exist_ok=True)
    result = {
        "universeId": UNIVERSE_ID,
        "upload": upload_payload,
        "status": status_payload,
    }
    RESULT_FILE.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    status_map = status_payload.get("uploadThumbnailStatusDict") or {}
    STATUS_FILE.write_text(
        "# Miniaturas del universo Tinta Final\n\n"
        "- Estado: CORRECTO\n"
        f"- Universe ID: {UNIVERSE_ID}\n"
        f"- Miniaturas procesadas: {len(status_map)}\n",
        encoding="utf-8",
    )
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        STATUS_FILE.parent.mkdir(parents=True, exist_ok=True)
        STATUS_FILE.write_text(
            "# Miniaturas del universo Tinta Final\n\n"
            "- Estado: ERROR\n"
            f"- Universe ID: {UNIVERSE_ID}\n"
            f"- Error: {exc}\n",
            encoding="utf-8",
        )
        raise
