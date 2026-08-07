# Developer Products de Tinta Final

- Estado: ERROR
- Universe ID: 8973271699

```text
Traceback (most recent call last):
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/sync_developer_products.py", line 146, in <module>
    main()
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/sync_developer_products.py", line 110, in main
    existing = list_products()
               ^^^^^^^^^^^^^^^
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/sync_developer_products.py", line 73, in list_products
    raise RuntimeError(f"No se pudieron listar developer products: HTTP {response.status_code} - {response.text[:1200]}")
RuntimeError: No se pudieron listar developer products: HTTP 403 - {"errors":[{"code":0,"message":"Scope not authorized."}]}


```
