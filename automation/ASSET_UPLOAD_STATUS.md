# Carga de imágenes de Tinta Final

- Estado: ERROR
- Commit: 7cc1022a16085dfd6ea4fe544b0fdb0bceff5e23
- Fecha UTC: 2026-08-06 23:09:13

```text
Propietario resuelto: demianvelo (8433192682)
Renderizando assets/branding/main.svg -> build/branding/MainMenu.png
Subiendo MainMenu a Roblox...
Traceback (most recent call last):
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/upload_brand_assets.py", line 188, in <module>
    main()
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/upload_brand_assets.py", line 166, in main
    asset_ids[key] = create_asset(api_key, creator_id, key, png_path)
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/upload_brand_assets.py", line 90, in create_asset
    raise RuntimeError(
RuntimeError: Roblox rechazó MainMenu: HTTP 403 - {
  "code": "PERMISSION_DENIED",
  "message": "User not authenticated"
}

```
