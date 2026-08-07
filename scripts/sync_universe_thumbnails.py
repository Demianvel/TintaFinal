#!/usr/bin/env python3
"""Upload Tinta Final artwork as real Roblox universe thumbnails and keep the sync idempotent.

Also records the public media inventory so stale legacy thumbnails can be identified
and removed deliberately instead of deleting unknown media blindly.
"""

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
PUBLIC_MEDIA_URL = f"https://games.roblox.com/v2/games/{UNIVERSE_ID}/media"
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

# Estas cinco miniaturas fueron creadas únicamente por el primer intento de nuestro
# workflow. Se eliminan de forma explícita para no tocar ninguna miniatura ajena.
KNOWN_FIRST_RUN_DUPLICATES = {
    "ba795341-cce3-45c2-b4a1-9c7b9145b6b9",
    "9790e7dc-edd6-4709-8c48-8d198b8d27d5",
    "b6d3e7f5-99b3-44ff-815a-8ac8563d2f1b",
    "4841b13d-ffc3-4d1d-baf8-ab29fb146125",
    "3075c1f1-79a3-442f-a24c-8a3bc0d37c83",
}


def api_key() -> str:
    value = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not value:
        raise RuntimeError("Falta ROBLOX_API_KEY.")
    return value


def headers() -> dict[str, str]:
    return {"x-api-key": api_key(), "Accept": "application/json"}


def load_cached_payload() -> dict:
    if not RESULT_FILE.is_file():
        return {}
    try:
        payload = json.loads(RESULT_FILE.read_text(encoding="utf-8"))
        return payload if isinstance(payload, dict) else {}
    except (OSError, json.JSONDecodeError, AttributeError):
        return {}


def cached_approved_count(payload: dict | None = None) -> int:
    payload = payload or load_cached_payload()
    try:
        status_map = payload.get("status", {}).get("uploadThumbnailStatusDict", {})
    except AttributeError:
        return 0

    approved_ids: set[str] = set()
    for item in status_map.values():
        if not isinstance(item, dict):
            continue
        thumbnail_id = str(item.get("homepageThumbnailId") or "").strip()
        asset_id = int(item.get("assetId") or 0)
        moderation = str(item.get("moderationStatus") or "")
        if thumbnail_id and asset_id > 0 and moderation.lower() == "approved":
            approved_ids.add(thumbnail_id)
    return len(approved_ids)


def get_personalized_inventory() -> dict:
    response = requests.get(f"{API_ROOT}/thumbnails", headers=headers(), timeout=60)
    if not response.ok:
        raise RuntimeError(
            f"No se pudo leer el inventario de miniaturas personalizadas: "
            f"HTTP {response.status_code} - {response.text[:1800]}"
        )
    try:
        return response.json()
    except ValueError:
        return {"raw": response.text[:5000]}


def get_public_media() -> dict:
    # Endpoint público usado por la ficha de la experiencia. Incluye media legacy que
    # puede seguir apareciendo aunque las Home thumbnails personalizadas estén bien.
    response = requests.get(
        PUBLIC_MEDIA_URL,
        params={"fetchAllExperienceRelatedMedia": "true"},
        headers={"Accept": "application/json"},
        timeout=60,
    )
    if not response.ok:
        return {
            "error": f"HTTP {response.status_code}",
            "body": response.text[:3000],
        }
    try:
        return response.json()
    except ValueError:
        return {"raw": response.text[:5000]}


def save_inventory(payload: dict) -> dict:
    payload["personalizedInventory"] = get_personalized_inventory()
    payload["publicMedia"] = get_public_media()
    RESULT_FILE.parent.mkdir(parents=True, exist_ok=True)
    RESULT_FILE.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return payload


def cleanup_known_duplicates() -> int:
    deleted = 0
    for thumbnail_id in sorted(KNOWN_FIRST_RUN_DUPLICATES):
        response = requests.delete(
            f"{API_ROOT}/thumbnails",
            headers=headers(),
            params=[("homepageThumbnailIds", thumbnail_id)],
            timeout=60,
        )
        response_text = response.text.lower()
        if response.status_code in (200, 204):
            deleted += 1
            print(f"Duplicado eliminado: {thumbnail_id}")
            continue
        if response.status_code in (400, 404) or (
            response.status_code == 403 and "invalid thumbnail id" in response_text
        ):
            print(f"Duplicado ya ausente: {thumbnail_id}")
            continue
        raise RuntimeError(
            f"No se pudo eliminar miniatura duplicada {thumbnail_id}: "
            f"HTTP {response.status_code} - {response.text[:1200]}"
        )
    return deleted


def public_media_count(payload: dict) -> int:
    public = payload.get("publicMedia") or {}
    data = public.get("data") if isinstance(public, dict) else None
    return len(data) if isinstance(data, list) else 0


def write_status(active_count: int, deleted_count: int, mode: str, payload: dict | None = None) -> None:
    payload = payload or {}
    STATUS_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATUS_FILE.write_text(
        "# Miniaturas del universo Tinta Final\n\n"
        "- Estado: CORRECTO\n"
        f"- Universe ID: {UNIVERSE_ID}\n"
        f"- Miniaturas activas/reutilizadas: {active_count}\n"
        f"- Media pública detectada: {public_media_count(payload)}\n"
        f"- Duplicados eliminados en esta ejecución: {deleted_count}\n"
        f"- Modo: {mode}\n",
        encoding="utf-8",
    )


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
            if (
                item.get("homepageThumbnailId")
                and int(item.get("assetId") or 0) > 0
                and str(item.get("moderationStatus") or "").lower() == "approved"
            ):
                completed += 1
        print(f"Miniaturas aprobadas: {completed}/{len(operation_ids)}")
        if completed == len(operation_ids):
            return last
        time.sleep(5)
    raise TimeoutError(f"Roblox no terminó de procesar las miniaturas: {last}")


def main() -> None:
    deleted = cleanup_known_duplicates()
    cached_payload = load_cached_payload()
    cached_count = cached_approved_count(cached_payload)

    if cached_count == len(THUMBNAILS):
        payload = save_inventory(cached_payload)
        write_status(cached_count, deleted, "REUTILIZADO_AUDITADO", payload)
        print(f"Set aprobado existente reutilizado: {cached_count} miniaturas.")
        print(json.dumps({
            "personalizedInventory": payload.get("personalizedInventory"),
            "publicMedia": payload.get("publicMedia"),
        }, indent=2, ensure_ascii=False))
        return

    rendered = render_all()
    upload_payload = upload(rendered)
    status_payload = poll(upload_payload)

    result = {
        "universeId": UNIVERSE_ID,
        "upload": upload_payload,
        "status": status_payload,
    }
    result = save_inventory(result)

    status_map = status_payload.get("uploadThumbnailStatusDict") or {}
    active_count = sum(
        1
        for item in status_map.values()
        if isinstance(item, dict)
        and item.get("homepageThumbnailId")
        and int(item.get("assetId") or 0) > 0
        and str(item.get("moderationStatus") or "").lower() == "approved"
    )
    if active_count != len(THUMBNAILS):
        raise RuntimeError(f"Se esperaban {len(THUMBNAILS)} miniaturas aprobadas y hay {active_count}.")
    write_status(active_count, deleted, "NUEVO_SET_APROBADO_AUDITADO", result)
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
