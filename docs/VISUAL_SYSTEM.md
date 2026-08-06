# Sistema visual de Tinta Final

La interfaz del proyecto sigue el mapa visual aprobado: negro profundo, cian, magenta, naranja y amarillo, con salpicaduras de tinta y contraste alto.

## Ubicación de cada imagen

| Archivo | Uso recomendado |
|---|---|
| `01_pantalla_principal_1280x720.png` | Portada, menú inicial y miniatura horizontal |
| `02_pantalla_carga_1280x720.png` | Pantalla de carga |
| `03_lobby_1280x720.png` | Referencia visual del lobby |
| `04_ronda_1_1280x720.png` | Presentación de la primera ronda |
| `05_ronda_2_1280x720.png` | Presentación de la segunda ronda |
| `06_tienda_recompensas_1280x720.png` | Tienda, pase y recompensas |
| `icono_tinta_final_1024x1024.png` | Ícono cuadrado de la experiencia |
| `00_mapa_visual_completo.png` | Documento maestro de diseño |

## Código implementado

- `src/shared/VisualConfig.lua`: paleta y Asset IDs.
- `src/client/VisualTheme.client.lua`: pantalla de carga animada y tema visual del HUD actual.

La pantalla de carga funciona aun sin imágenes externas: genera un fondo neón, logotipo, manchas animadas y barra de progreso. Cuando el campo `Loading` de `VisualConfig.Assets` tenga un Asset ID válido, usa la imagen oficial como fondo.

## Subir imágenes a Roblox desde el celular

1. Entrar en Creator Dashboard.
2. Abrir **Creaciones → Development Items → Decals**.
3. Cargar cada PNG por separado.
4. Esperar la moderación.
5. Copiar el Asset ID de cada imagen.
6. Colocar los números dentro de `VisualConfig.lua`.

También se puede automatizar más adelante con Open Cloud Assets API. La API key debe tener el sistema **Assets** con permisos **Read** y **Write** y nunca debe publicarse en el repositorio.

## Correspondencia de Asset IDs

```lua
Assets = {
    MainMenu = 0,
    Loading = 0,
    Lobby = 0,
    Round1 = 0,
    Round2 = 0,
    Shop = 0,
    Icon = 0,
}
```

Reemplazar cada `0` por el número de la imagen correspondiente.
