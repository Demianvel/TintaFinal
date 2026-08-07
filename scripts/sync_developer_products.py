#!/usr/bin/env python3
"""Create/resolve Tinta Final developer products and write their IDs into Lua config."""

# Trigger: 2026-08-06 multipart/form-data según OpenAPI oficial de Roblox.
from __future__ import annotations

import json
import os
import re
from pathlib import Path

import requests

UNIVERSE_ID = 8973271699
API_ROOT = f"https://apis.roblox.com/developer-products/v2/universes/{UNIVERSE_ID}/developer-products"
CONFIG_FILE = Path("src/shared/MonetizationConfig.lua")
RESULT_FILE = Path("automation/developer-products.json")
STATUS_FILE = Path("automation/DEVELOPER_PRODUCTS_STATUS.md")

PRODUCTS = {
    "TintaPackSmall": {
        "name": "Tinta Final - 25K Tinta Money",
        "description": "25.000 Tinta Money para la tienda de Tinta Final.",
        "price": 25,
    },
    "TintaPackMedium": {
        "name": "Tinta Final - 100K Tinta Money",
        "description": "100.000 Tinta Money para la tienda de Tinta Final.",
        "price": 75,
    },
    "TintaPackMega": {
        "name": "Tinta Final - 500K Tinta Money",
        "description": "500.000 Tinta Money para la tienda de Tinta Final.",
        "price": 199,
    },
    "Donation10": {
        "name": "Tinta Final - Apoyo 10",
        "description": "Apoyo de 10 Robux al desarrollo de Tinta Final.",
        "price": 10,
    },
    "Donation50": {
        "name": "Tinta Final - Apoyo 50",
        "description": "Apoyo de 50 Robux al desarrollo de Tinta Final.",
        "price": 50,
    },
    "Donation100": {
        "name": "Tinta Final - Apoyo 100",
        "description": "Apoyo de 100 Robux al desarrollo de Tinta Final.",
        "price": 100,
    },
}


def api_key() -> str:
    value = os.environ.get("ROBLOX_API_KEY", "").strip()
    if not value:
        raise RuntimeError("Falta ROBLOX_API_KEY.")
    return value


def headers() -> dict[str, str]:
    return {"x-api-key": api_key(), "Accept": "application/json"}


def list_products() -> list[dict]:
    products: list[dict] = []
    token = ""
    for _ in range(20):
        params = {"pageSize": 100}
        if token:
            params["pageToken"] = token
        response = requests.get(f"{API_ROOT}/creator", headers=headers(), params=params, timeout=60)
        if not response.ok:
            raise RuntimeError(f"No se pudieron listar developer products: HTTP {response.status_code} - {response.text[:1200]}")
        payload = response.json()
        products.extend(payload.get("developerProducts", []))
        token = str(payload.get("nextPageToken") or "")
        if not token:
            break
    return products


def create_product(spec: dict) -> dict:
    # Roblox Developer Products v2 requires multipart/form-data, even when no image is sent.
    multipart = {
        "name": (None, spec["name"]),
        "description": (None, spec["description"]),
        "isForSale": (None, "true"),
        "price": (None, str(int(spec["price"]))),
        "isManagedPricingEnabled": (None, "false"),
    }
    response = requests.post(API_ROOT, headers=headers(), files=multipart, timeout=60)
    if not response.ok:
        raise RuntimeError(f"No se pudo crear {spec['name']}: HTTP {response.status_code} - {response.text[:1500]}")
    payload = response.json()
    if not int(payload.get("productId") or 0):
        raise RuntimeError(f"Roblox creó el producto sin productId válido: {payload}")
    return payload


def update_config(ids: dict[str, int]) -> None:
    content = CONFIG_FILE.read_text(encoding="utf-8")
    for key, product_id in ids.items():
        pattern = rf"({re.escape(key)}\s*=\s*\{{\s*ProductId\s*=\s*)\d+"
        content, count = re.subn(pattern, rf"\g<1>{product_id}", content, count=1)
        if count != 1:
            raise RuntimeError(f"No se encontró ProductId de {key} en {CONFIG_FILE}")
    CONFIG_FILE.write_text(content, encoding="utf-8")


def main() -> None:
    existing = list_products()
    by_name = {str(item.get("name")): item for item in existing}
    resolved: dict[str, int] = {}
    details: dict[str, dict] = {}

    for key, spec in PRODUCTS.items():
        item = by_name.get(spec["name"])
        if item is None:
            print(f"Creando {spec['name']} ({spec['price']} Robux)...")
            item = create_product(spec)
        else:
            print(f"Reutilizando {spec['name']} -> {item.get('productId')}")
        product_id = int(item.get("productId") or 0)
        if product_id <= 0:
            raise RuntimeError(f"ProductId inválido para {key}: {item}")
        resolved[key] = product_id
        details[key] = {
            "productId": product_id,
            "name": spec["name"],
            "priceRobux": spec["price"],
        }

    update_config(resolved)
    RESULT_FILE.parent.mkdir(parents=True, exist_ok=True)
    RESULT_FILE.write_text(json.dumps({"universeId": UNIVERSE_ID, "products": details}, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    STATUS_FILE.write_text(
        "# Developer Products de Tinta Final\n\n"
        "- Estado: CORRECTO\n"
        f"- Universe ID: {UNIVERSE_ID}\n"
        f"- Productos conectados: {len(resolved)}\n",
        encoding="utf-8",
    )
    print(json.dumps(details, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
