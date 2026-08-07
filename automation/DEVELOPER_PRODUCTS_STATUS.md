# Developer Products de Tinta Final

- Estado: ERROR
- Universe ID: 8973271699

```text
Creando Tinta Final - 25K Tinta Money (25 Robux)...
Traceback (most recent call last):
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/sync_developer_products.py", line 147, in <module>
    main()
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/sync_developer_products.py", line 120, in main
    item = create_product(spec)
           ^^^^^^^^^^^^^^^^^^^^
  File "/home/runner/work/TintaFinal/TintaFinal/scripts/sync_developer_products.py", line 93, in create_product
    raise RuntimeError(f"No se pudo crear {spec['name']}: HTTP {response.status_code} - {response.text[:1500]}")
RuntimeError: No se pudo crear Tinta Final - 25K Tinta Money: HTTP 415 - 

```
