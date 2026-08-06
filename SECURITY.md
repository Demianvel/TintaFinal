# Seguridad de Tinta Final

## Dependencias permitidas

Este proyecto solo incorpora código Luau revisable, paquetes con licencia clara y herramientas de compilación conocidas.

No se aceptan:

- ejecutores de Roblox;
- archivos `.exe`, `.apk`, `.bat` o `.zip` descargados desde dominios desconocidos;
- scripts de Auto Win, Noclip, ESP, Kill Aura, Fly, Infinite Jump o bypass de anti-cheat;
- código que use `loadstring`, `game:HttpGet`, `getgenv`, `hookmetamethod` o APIs propias de ejecutores;
- copias de mapas, interfaces, música, personajes o recursos de otras experiencias.

## Secretos

Las claves de Roblox Open Cloud deben guardarse exclusivamente en GitHub Actions Secrets con el nombre `ROBLOX_API_KEY`. Nunca deben escribirse en scripts, commits, archivos de configuración o mensajes públicos.

## Revisión

Todo código externo debe revisarse antes de incorporarse. El workflow `Security Scan` bloquea patrones habituales de scripts de exploit y archivos ejecutables.
