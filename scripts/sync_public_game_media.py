#!/usr/bin/env python3
"""Replace stale public experience media with Tinta Final branding.

Safety rules:
- Upload/confirm the new Tinta Final thumbnail first.
- Only then delete the explicitly-known stale river image/thumbnail.
- Never bulk-delete unknown creator media.
- Permission blocks are persisted as diagnostics instead of being confused with code failures.
"""

from __future__ import annotations

import json
import os
import time
from pathlib import Path

import cairosvg
import requests

UNIVERSE_ID = 8973271699
LANGUAGE = "en-us"
API = "https://apis.roblox.com"
PUBLIC_MEDIA_URL = f"https://games.roblox.com/v2/games/{UNIVERSE_ID}/media"
UPLOAD_URL = (
    f"{API}/legacy-game-internationalization/v1/game-thumbnails/games/"
    f"{UNIVERSE_ID}/language-codes/{LANGUAGE}/image"
)
DELETE_URL = (
    f"{API}/legacy-game-internationalization/v1/game-thumbnails/games/"
    f"{UNIVERSE_ID}/language-codes/{LANGUAGE}/images/{{image_id}}"
)
ORDER_URL = (
    f"{API}/legacy-game-internationalization/v1/game-thumbnails/games/"
    f"{UNIVERSE_ID}/language-codes/{LANGUAGE}/images/order"
)
PERSONALIZATION_ROOT = f"{API}/thumbnail-personalization-api/v1/universes/{UNIVERSE_ID}"

SOURCE = Path("assets/branding/main.svg")
BUILD = Path("build/public-media/TintaFinal-Public.png")
STATUS = Path("automation/PUBLIC_MEDIA_STATUS.md")
RESULT = Path("automation/public-media-sync.json")

STALE_RIVER_IMAGE_ID = 80353689172158
STALE_RIVER_HOMEPAGE_THUMBNAIL_ID = "d47b764f-e739-444f-9e33-acf2bcd7d367"
REQUIRED_LEGACY_SCOPE = "legacy-universe:manage"


class PermissionBlocked(RuntimeError):
    pass


def key() -> str:
    value = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not value:
        raise PermissionBlocked("Falta ROBLOX_API_KEY en GitHub Actions.")
    return value


def api_headers() -> dict[str, str]:
    return {"x-api-key": key(), "Accept": "application/json"}


def public_media() -> dict:
    response = requests.get(
        PUBLIC_MEDIA_URL,
        params={"fetchAllExperienceRelatedMedia": "true"},
        headers={"Accept": "application/json"},
        timeout=60,
    )
    if not response.ok:
        raise RuntimeError(f"No se pudo consultar media pública: HTTP {response.status_code} - {response.text[:1200]}")
    return response.json()


def image_ids(payload: dict) -> set[int]:
    output: set[int] = set()
    for item in payload.get("data") or []:
        if str(item.get("assetType")) == "Image":
            value = int(item.get("imageId") or 0)
            if value > 0:
                output.add(value)
    return output


def render() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    BUILD.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(url=str(SOURCE), write_to=str(BUILD), output_width=1280, output_height=720)
    if not BUILD.is_file() or BUILD.stat().st_size <= 0:
        raise RuntimeError("No se pudo renderizar la portada Tinta Final")


def legacy_permission_error(action: str, response: requests.Response) -> PermissionBlocked:
    return PermissionBlocked(
        f"Roblox rechazó {action}: HTTP {response.status_code} - {response.text[:900]}. "
        f"Los endpoints legacy de miniatura pública requieren el scope {REQUIRED_LEGACY_SCOPE} en la API Key."
    )


def upload_thumbnail() -> dict:
    attempts = []
    for field_name in ("file", "imageFile", "image"):
        with BUILD.open("rb") as handle:
            response = requests.post(
                UPLOAD_URL,
                headers=api_headers(),
                files={field_name: (BUILD.name, handle, "image/png")},
                timeout=120,
            )
        attempts.append({"field": field_name, "statusCode": response.status_code, "body": response.text[:1600]})
        if response.ok:
            try:
                payload = response.json()
            except ValueError:
                payload = {"raw": response.text[:3000]}
            return {"success": True, "field": field_name, "response": payload, "attempts": attempts}
        if response.status_code in (401, 403):
            raise legacy_permission_error("la carga de la portada pública", response)
        if response.status_code not in (400, 404, 415, 422):
            break
    raise RuntimeError("No se pudo subir la portada pública: " + json.dumps(attempts, ensure_ascii=False))


def wait_for_new_image(before: set[int]) -> tuple[int, dict]:
    last = {}
    for _ in range(30):
        time.sleep(2)
        last = public_media()
        candidates = image_ids(last) - before
        if candidates:
            return sorted(candidates)[-1], last
    raise TimeoutError(f"Roblox aceptó la carga pero no apareció una nueva imageId: {last}")


def order_new_first(new_image_id: int) -> dict:
    attempts = []
    for payload in ({"imageIds": [new_image_id]}, {"orderedImageIds": [new_image_id]}):
        response = requests.post(
            ORDER_URL,
            headers={**api_headers(), "Content-Type": "application/json"},
            json=payload,
            timeout=60,
        )
        attempts.append({"payload": payload, "statusCode": response.status_code, "body": response.text[:1000]})
        if response.ok:
            return {"success": True, "attempts": attempts}
        if response.status_code in (401, 403):
            raise legacy_permission_error("el orden de miniaturas públicas", response)
    return {"success": False, "attempts": attempts}


def delete_stale_public_image() -> dict:
    response = requests.delete(DELETE_URL.format(image_id=STALE_RIVER_IMAGE_ID), headers=api_headers(), timeout=60)
    if response.status_code in (200, 204, 400, 404):
        return {"statusCode": response.status_code, "body": response.text[:1000]}
    if response.status_code in (401, 403):
        raise legacy_permission_error("la eliminación de la portada vieja", response)
    raise RuntimeError(f"No se pudo eliminar la imagen vieja del río: HTTP {response.status_code} - {response.text[:1200]}")


def delete_stale_personalized_thumbnail() -> dict:
    response = requests.delete(
        f"{PERSONALIZATION_ROOT}/thumbnails",
        headers=api_headers(),
        params=[("homepageThumbnailIds", STALE_RIVER_HOMEPAGE_THUMBNAIL_ID)],
        timeout=60,
    )
    response_text = response.text.lower()
    if response.status_code in (200, 204, 400, 404) or (
        response.status_code == 403 and "invalid thumbnail id" in response_text
    ):
        return {"statusCode": response.status_code, "body": response.text[:1000]}
    if response.status_code in (401, 403):
        raise PermissionBlocked(
            f"Roblox rechazó retirar el thumbnail personalizado: HTTP {response.status_code}. "
            "Verificá universe.thumbnail:write para este Universe."
        )
    raise RuntimeError(
        f"No se pudo retirar el thumbnail personalizado viejo: HTTP {response.status_code} - {response.text[:1200]}"
    )


def write_status(state: str, detail: str, new_image_id: int = 0) -> None:
    STATUS.parent.mkdir(parents=True, exist_ok=True)
    STATUS.write_text(
        "# Portada pública de Tinta Final\n\n"
        f"- Estado: {state}\n"
        f"- Universe ID: {UNIVERSE_ID}\n"
        f"- Nueva imageId: {new_image_id if new_image_id > 0 else 'NO_GENERADA'}\n"
        f"- River imageId objetivo: {STALE_RIVER_IMAGE_ID}\n"
        f"- Scope legacy requerido: {REQUIRED_LEGACY_SCOPE}\n"
        f"- Detalle: {detail}\n",
        encoding="utf-8",
    )


def write_result(payload: dict) -> None:
    RESULT.parent.mkdir(parents=True, exist_ok=True)
    RESULT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def main() -> None:
    before_payload = public_media()
    before_ids = image_ids(before_payload)

    if STALE_RIVER_IMAGE_ID not in before_ids and before_ids:
        current_id = sorted(before_ids)[0]
        write_result({"mode": "REUTILIZADO", "before": before_payload, "after": before_payload, "newImageId": current_id})
        write_status("CORRECTO", "La imagen vieja ya no está activa; se reutiliza la portada pública actual.", current_id)
        return

    render()
    upload_result = upload_thumbnail()
    new_image_id, after_upload = wait_for_new_image(before_ids)
    order_result = order_new_first(new_image_id)
    stale_public_result = delete_stale_public_image() if STALE_RIVER_IMAGE_ID in before_ids else {"skipped": True}
    stale_personalized_result = delete_stale_personalized_thumbnail()

    time.sleep(2)
    final_media = public_media()
    final_ids = image_ids(final_media)
    if new_image_id not in final_ids:
        raise RuntimeError(f"La portada nueva {new_image_id} no figura en la media final: {final_media}")
    if STALE_RIVER_IMAGE_ID in final_ids:
        raise RuntimeError("La imagen vieja del río continúa en la media pública después del reemplazo.")

    result = {
        "mode": "REEMPLAZADO",
        "before": before_payload,
        "upload": upload_result,
        "afterUpload": after_upload,
        "newImageId": new_image_id,
        "order": order_result,
        "deleteStalePublic": stale_public_result,
        "deleteStalePersonalized": stale_personalized_result,
        "final": final_media,
    }
    write_result(result)
    write_status("CORRECTO", "Portada Tinta Final confirmada y escena del río retirada.", new_image_id)
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except PermissionBlocked as exc:
        write_result({"mode": "BLOQUEADO_POR_PERMISO", "requiredScope": REQUIRED_LEGACY_SCOPE, "error": str(exc)})
        write_status("BLOQUEADO", str(exc))
        print(str(exc))
        raise SystemExit(2)
    except Exception as exc:
        write_result({"mode": "ERROR", "error": str(exc)})
        write_status("ERROR", str(exc))
        raise
