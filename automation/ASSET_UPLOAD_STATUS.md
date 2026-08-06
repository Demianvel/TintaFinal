# Carga de imágenes de Tinta Final

- Estado: ERROR
- Commit: b8c217d668cea5239b58e1b1ac2866b7eb2af659
- Fecha UTC: 2026-08-06 22:47:50

```text
Renderizando assets/branding/main.svg -> build/branding/MainMenu.png
Subiendo MainMenu a Roblox...
Traceback (most recent call last):
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/upload_brand_assets.py", line 149, in <module>
    main()
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/upload_brand_assets.py", line 136, in main
    asset_ids[key] = create_asset(api_key, creator_id, key, png_path)
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/upload_brand_assets.py", line 61, in create_asset
    raise RuntimeError(
RuntimeError: Roblox rechazó MainMenu: HTTP 403 - {
  "code": "PERMISSION_DENIED",
  "message": "User not authenticated"
}

```
