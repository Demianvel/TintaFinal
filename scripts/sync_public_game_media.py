#!/usr/bin/env python3
"""Synchronize Tinta Final public experience media safely.

The legacy upload endpoint can accept an image before it becomes visible in the
public media list. This script therefore distinguishes Roblox processing from
real errors and never uploads another copy while a previous accepted upload is
still pending.
"""

from __future__ import annotations

import json
import os
import time
from datetime import datetime, timezone
from pathlib import Path

import cairosvg
import requests

UNIVERSE_ID = 8973271699
API = "https://apis.roblox.com"
PUBLIC_MEDIA_URL = f"https://games.roblox.com/v2/games/{UNIVERSE_ID}/media"
SOURCE_LANGUAGE_URL = (
    f"https://gameinternationalization.roblox.com/v1/source-language/games/"
    f"{UNIVERSE_ID}/language-with-locales"
)
LEGACY_ROOT = (
    f"{API}/legacy-game-internationalization/v1/game-thumbnails/games/"
    f"{UNIVERSE_ID}/language-codes"
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


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


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
        raise RuntimeError(
            f"No se pudo consultar media pública: HTTP {response.status_code} - {response.text[:1200]}"
        )
    return response.json()


def image_ids(payload: dict) -> set[int]:
    output: set[int] = set()
    for item in payload.get("data") or []:
        if str(item.get("assetType")) == "Image":
            value = int(item.get("imageId") or 0)
            if value > 0:
                output.add(value)
    return output


def previous_upload_pending() -> bool:
    markers = (
        "pendiente_roblox",
        "carga_aceptada_esperando_roblox",
        "roblox aceptó la carga pero no apareció",
        "roblox acepto la carga pero no aparecio",
    )
    if STATUS.is_file():
        text = STATUS.read_text(encoding="utf-8", errors="ignore").lower()
        if any(marker in text for marker in markers):
            return True

    # Redundant guard: GitHub Actions can update the JSON result independently
    # from the Markdown status. Any accepted mediaAssetId means a new upload must
    # not be attempted again until Roblox exposes it in public media.
    if RESULT.is_file():
        try:
            payload = json.loads(RESULT.read_text(encoding="utf-8"))
        except (ValueError, OSError):
            payload = {}
        mode = str(payload.get("mode") or "").lower()
        upload = payload.get("upload") if isinstance(payload.get("upload"), dict) else {}
        response = upload.get("response") if isinstance(upload.get("response"), dict) else {}
        accepted_asset = str(response.get("mediaAssetId") or "").strip()
        if any(marker in mode for marker in ("pendiente_roblox", "carga_aceptada_esperando_roblox")):
            return True
        if accepted_asset:
            return True
    return False


def _add_language_candidate(output: list[str], value: object) -> None:
    if not isinstance(value, str):
        return
    value = value.strip().lower().replace("_", "-")
    if not value:
        return
    # The legacy endpoint accepts language codes (es/en/pt...), not locale codes
    # such as es-es or es-mx. Keep only the base language discovered from Roblox.
    short = value.split("-", 1)[0]
    if short and short not in output:
        output.append(short)


def _walk_language_payload(value: object, output: list[str]) -> None:
    if isinstance(value, dict):
        for key_name, child in value.items():
            if str(key_name).lower() in {
                "languagecode",
                "language_code",
                "language",
                "locale",
                "localecode",
                "locale_code",
            }:
                _add_language_candidate(output, child)
            _walk_language_payload(child, output)
    elif isinstance(value, list):
        for child in value:
            _walk_language_payload(child, output)


def language_candidates() -> tuple[list[str], dict]:
    candidates: list[str] = []
    diagnostics: dict = {}
    try:
        response = requests.get(SOURCE_LANGUAGE_URL, headers={"Accept": "application/json"}, timeout=60)
        diagnostics = {"statusCode": response.status_code, "body": response.text[:3000]}
        if response.ok:
            try:
                payload = response.json()
            except ValueError:
                payload = {}
            diagnostics["json"] = payload
            _walk_language_payload(payload, candidates)
    except requests.RequestException as exc:
        diagnostics = {"error": str(exc)}

    for fallback in ("es", "en", "pt", "fr", "de"):
        if fallback not in candidates:
            candidates.append(fallback)
    return candidates, diagnostics


def render() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    BUILD.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(SOURCE),
        write_to=str(BUILD),
        output_width=1280,
        output_height=720,
    )
    if not BUILD.is_file() or BUILD.stat().st_size <= 0:
        raise RuntimeError("No se pudo renderizar la portada Tinta Final")


def legacy_permission_error(action: str, response: requests.Response) -> PermissionBlocked:
    return PermissionBlocked(
        f"Roblox rechazó {action}: HTTP {response.status_code} - {response.text[:900]}. "
        f"Revisá el scope {REQUIRED_LEGACY_SCOPE} en la API Key."
    )


def legacy_url(language_code: str, suffix: str) -> str:
    return f"{LEGACY_ROOT}/{language_code}/{suffix.lstrip('/')}"


def upload_thumbnail(candidates: list[str]) -> dict:
    attempts = []
    for language_code in candidates:
        for field_name in ("file", "imageFile", "image"):
            with BUILD.open("rb") as handle:
                response = requests.post(
                    legacy_url(language_code, "image"),
                    headers=api_headers(),
                    files={field_name: (BUILD.name, handle, "image/png")},
                    timeout=120,
                )
            attempt = {
                "languageCode": language_code,
                "field": field_name,
                "statusCode": response.status_code,
                "body": response.text[:1600],
            }
            attempts.append(attempt)
            if response.ok:
                try:
                    payload = response.json()
                except ValueError:
                    payload = {"raw": response.text[:3000]}
                return {
                    "success": True,
                    "languageCode": language_code,
                    "field": field_name,
                    "response": payload,
                    "attempts": attempts,
                }
            if response.status_code in (401, 403):
                raise legacy_permission_error("la carga de la portada pública", response)
            text = response.text.lower()
            if response.status_code == 400 and "invalid language code" in text:
                break
            if response.status_code == 400 and "can't update translations for source language" in text:
                break
            if response.status_code not in (400, 404, 415, 422):
                break
    raise RuntimeError("No se pudo subir la portada pública: " + json.dumps(attempts, ensure_ascii=False))


def wait_for_new_image(before: set[int], checks: int = 30) -> tuple[int, dict] | tuple[None, dict]:
    last = {}
    for _ in range(checks):
        time.sleep(2)
        last = public_media()
        candidates = image_ids(last) - before
        if candidates:
            return sorted(candidates)[-1], last
    return None, last


def request_order(language_code: str, new_image_id: int) -> dict:
    attempts = []
    for payload in ({"imageIds": [new_image_id]}, {"orderedImageIds": [new_image_id]}):
        response = requests.post(
            legacy_url(language_code, "images/order"),
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


def order_with_candidates(candidates: list[str], new_image_id: int) -> tuple[str, dict]:
    all_attempts = []
    for language_code in candidates:
        result = request_order(language_code, new_image_id)
        all_attempts.extend(result.get("attempts") or [])
        if result.get("success"):
            return language_code, {"success": True, "attempts": all_attempts}
    return candidates[0], {"success": False, "attempts": all_attempts}


def delete_public_image(language_code: str, image_id: int) -> dict:
    response = requests.delete(
        legacy_url(language_code, f"images/{int(image_id)}"),
        headers=api_headers(),
        timeout=60,
    )
    if response.status_code in (200, 204, 400, 404):
        return {"imageId": int(image_id), "statusCode": response.status_code, "body": response.text[:1000]}
    if response.status_code in (401, 403):
        raise legacy_permission_error(f"la eliminación de la imagen pública {int(image_id)}", response)
    raise RuntimeError(
        f"No se pudo eliminar la imagen pública {int(image_id)}: HTTP {response.status_code} - {response.text[:1200]}"
    )


def delete_stale_personalized_thumbnail() -> dict:
    response = requests.delete(
        f"{PERSONALIZATION_ROOT}/thumbnails",
        headers=api_headers(),
        params=[("homepageThumbnailIds", STALE_RIVER_HOMEPAGE_THUMBNAIL_ID)],
        timeout=60,
    )
    text = response.text.lower()
    if response.status_code in (200, 204, 400, 404) or (
        response.status_code == 403 and "invalid thumbnail id" in text
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


def write_status(
    state: str,
    detail: str,
    new_image_id: int = 0,
    language_code: str = "NO_DETECTADO",
) -> None:
    STATUS.parent.mkdir(parents=True, exist_ok=True)
    STATUS.write_text(
        "# Portada pública de Tinta Final\n\n"
        f"- Estado: {state}\n"
        f"- Universe ID: {UNIVERSE_ID}\n"
        f"- Idioma usado: {language_code}\n"
        f"- Nueva imageId: {new_image_id if new_image_id > 0 else 'NO_GENERADA'}\n"
        f"- River imageId objetivo: {STALE_RIVER_IMAGE_ID}\n"
        f"- Scope legacy requerido: {REQUIRED_LEGACY_SCOPE}\n"
        f"- Actualizado UTC: {utc_now()}\n"
        f"- Detalle: {detail}\n",
        encoding="utf-8",
    )


def write_result(payload: dict) -> None:
    RESULT.parent.mkdir(parents=True, exist_ok=True)
    RESULT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def finish_existing_new_media(before_payload: dict, new_ids: set[int]) -> None:
    new_image_id = sorted(new_ids)[-1]
    candidates, language_diag = language_candidates()
    language_code, order_result = order_with_candidates(candidates, new_image_id)

    delete_results = []
    for image_id in sorted(image_ids(before_payload)):
        if image_id == new_image_id:
            continue
        delete_results.append(delete_public_image(language_code, image_id))

    stale_personalized_result = delete_stale_personalized_thumbnail()
    time.sleep(2)
    final_media = public_media()
    final_ids = image_ids(final_media)
    if new_image_id not in final_ids:
        raise RuntimeError(f"La portada nueva {new_image_id} no figura en la media final.")
    unexpected = final_ids - {new_image_id}
    if unexpected:
        raise RuntimeError(f"Persisten imágenes públicas duplicadas: {sorted(unexpected)}")
    write_result(
        {
            "mode": "REEMPLAZADO_DESDE_PENDIENTE",
            "languageDiscovery": language_diag,
            "languageCode": language_code,
            "newImageId": new_image_id,
            "order": order_result,
            "deletedPublicImages": delete_results,
            "deleteStalePersonalized": stale_personalized_result,
            "before": before_payload,
            "final": final_media,
        }
    )
    write_status(
        "CORRECTO",
        "La portada nueva quedó como única media pública y la escena vieja del río fue retirada.",
        new_image_id,
        language_code,
    )


def main() -> None:
    before_payload = public_media()
    before_ids = image_ids(before_payload)
    visible_new_ids = before_ids - {STALE_RIVER_IMAGE_ID}

    if visible_new_ids:
        finish_existing_new_media(before_payload, visible_new_ids)
        return

    if STALE_RIVER_IMAGE_ID not in before_ids and before_ids:
        current_id = sorted(before_ids)[0]
        write_result({"mode": "REUTILIZADO", "before": before_payload, "newImageId": current_id})
        write_status("CORRECTO", "La imagen vieja ya no está activa.", current_id)
        return

    if previous_upload_pending():
        candidates, language_diag = language_candidates()
        write_result(
            {
                "mode": "PENDIENTE_ROBLOX",
                "checkedAt": utc_now(),
                "languageDiscovery": language_diag,
                "languageCandidates": candidates,
                "publicMedia": before_payload,
            }
        )
        write_status(
            "PENDIENTE_ROBLOX",
            "Existe una carga ya aceptada por Roblox; se bloqueó cualquier nueva carga y se espera moderación/propagación.",
            0,
            candidates[0] if candidates else "NO_DETECTADO",
        )
        raise SystemExit(3)

    render()
    candidates, language_diag = language_candidates()
    upload_result = upload_thumbnail(candidates)
    language_code = upload_result["languageCode"]

    write_result(
        {
            "mode": "CARGA_ACEPTADA_ESPERANDO_ROBLOX",
            "acceptedAt": utc_now(),
            "languageDiscovery": language_diag,
            "languageCandidates": candidates,
            "languageCode": language_code,
            "upload": upload_result,
            "before": before_payload,
        }
    )
    write_status(
        "PENDIENTE_ROBLOX",
        "Roblox aceptó la portada nueva. Esperando moderación/propagación antes de retirar la imagen vieja.",
        0,
        language_code,
    )

    new_image_id, after_upload = wait_for_new_image(before_ids)
    if new_image_id is None:
        write_result(
            {
                "mode": "PENDIENTE_ROBLOX",
                "acceptedAt": utc_now(),
                "languageDiscovery": language_diag,
                "languageCandidates": candidates,
                "languageCode": language_code,
                "upload": upload_result,
                "before": before_payload,
                "lastPublicMedia": after_upload,
            }
        )
        write_status(
            "PENDIENTE_ROBLOX",
            "Roblox aceptó la carga pero todavía no publicó una nueva imageId. No se volverá a subir otra copia.",
            0,
            language_code,
        )
        raise SystemExit(3)

    finish_existing_new_media(after_upload, image_ids(after_upload) - {STALE_RIVER_IMAGE_ID})


if __name__ == "__main__":
    try:
        main()
    except PermissionBlocked as exc:
        write_result(
            {
                "mode": "BLOQUEADO_POR_PERMISO",
                "requiredScope": REQUIRED_LEGACY_SCOPE,
                "error": str(exc),
            }
        )
        write_status("BLOQUEADO", str(exc))
        print(str(exc))
        raise SystemExit(2)
    except Exception as exc:
        write_result({"mode": "ERROR", "error": str(exc)})
        write_status("ERROR", str(exc))
        raise
