# Tinta Final: Último Pulso

Experiencia multijugador de supervivencia por rondas construida con **Luau + Rojo + GitHub Actions**.

## Identificadores de Roblox

- Universe ID: `8973271699`
- Starting Place ID: `73618099851560`
- Jugadores previstos por servidor: `100`

> El límite de 100 jugadores debe configurarse en Roblox Creator Dashboard, dentro de la configuración del Place. `Players.MaxPlayers` no puede modificarse desde un script.

## Sistemas incluidos

- Lobby generado por código.
- Sala AFK con recompensa limitada.
- Sala de descanso para guardias.
- Votación entre tres pruebas.
- Cinco minijuegos originales:
  - Pulso y Silencio.
  - Memoria de Tinta.
  - Cuadrícula Inestable.
  - Cacería de Sombras.
  - Última Plataforma.
- Partidas de hasta cinco etapas.
- Director procedural que adapta la tensión de las pruebas.
- Eliminaciones no gráficas.
- Guardias temporales con validación del servidor.
- Won virtuales, gemas, niveles y victorias.
- Tienda de mejoras.
- Giros con probabilidades visibles.
- Pase de batalla de 50 niveles.
- Compra del pase con Won y soporte preparado para Game Pass de Robux.
- Persistencia con DataStore y guardado automático.
- HUD responsive para PC y dispositivos móviles.
- Compilación automática a `.rbxlx`.
- Publicación manual segura mediante Roblox Open Cloud.

## Estructura

```text
src/
├── client/
│   └── Main.client.lua
├── server/
│   ├── Main.server.lua
│   └── Services/
│       ├── AudioService.lua
│       ├── EconomyService.lua
│       ├── GameService.lua
│       ├── MapService.lua
│       └── ProfileService.lua
└── shared/
    ├── GameConfig.lua
    └── MinigameDefinitions.lua
```

## Compilar desde GitHub

Cada cambio enviado a `main` ejecuta el workflow **Build Roblox Place**. El resultado se guarda como artifact:

```text
TintaFinal-Roblox-Place/TintaFinal.rbxlx
```

También puede compilarse localmente:

```bash
rojo build default.project.json --output build/TintaFinal.rbxlx
```

## Publicar sin Roblox Studio

1. En Roblox Creator Dashboard, crear una Open Cloud API Key.
2. Darle acceso `universe-places` con operación `Write` para el universo `8973271699`.
3. En GitHub abrir:
   - `Settings`
   - `Secrets and variables`
   - `Actions`
   - `New repository secret`
4. Crear el secreto:

```text
ROBLOX_API_KEY
```

5. Abrir `Actions > Publish Roblox > Run workflow`.
6. Escribir el Place ID `73618099851560` para confirmar.

La clave nunca debe colocarse dentro de un archivo del repositorio.

## Configuración pendiente en Creator Dashboard

Antes de una publicación pública:

- Establecer máximo de jugadores en `100`.
- Habilitar acceso público cuando las pruebas estén terminadas.
- Configurar la etiqueta de madurez correspondiente.
- Habilitar DataStore/API Services si Roblox lo requiere para las pruebas.
- Crear el Game Pass del pase premium y colocar su ID en `GameConfig.lua`.
- Elegir audios autorizados y colocar sus Asset IDs en `GameConfig.lua`.

## Propiedad intelectual

Tinta Final usa una identidad, nombres, mapas, interfaz y mecánicas propias. No deben incorporarse logos, música, personajes, uniformes, diálogos, mapas ni recursos copiados de series, películas o experiencias de terceros.

## Seguridad

Todas las compras, recompensas, votos, eliminaciones y roles se validan desde el servidor. No se deben aceptar cantidades de moneda, premios o resultados enviados por el cliente.
