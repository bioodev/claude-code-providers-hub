# Claude Code Providers Hub

> [English version](README.md)

Usa modelos de GLM (Z.AI), MiniMax y DeepSeek con [Claude Code](https://www.anthropic.com/claude-code) — sin tocar tu configuración de Anthropic existente.

Cada proveedor corre en un entorno completamente aislado: directorio de configuración propio, historial de chat separado y clave API independiente.

## Proveedores disponibles

| Comando | Proveedor | Modelo | Ideal para |
|---------|-----------|--------|------------|
| `ccg` | Z.AI | GLM-5.1 | Mejor calidad GLM, tareas complejas |
| `ccf` | Z.AI | GLM-4.5-Air | Respuestas rápidas, menor costo |
| `ccm` | MiniMax | MiniMax-M2 | Tareas con MiniMax |
| `ccd` | DeepSeek | deepseek-chat | Tareas enfocadas en código |
| `cc` | Anthropic | Claude | Tu configuración original (sin cambios) |

## Requisitos

- [Node.js](https://nodejs.org/) v14+
- [Claude Code](https://www.anthropic.com/claude-code) instalado y funcionando
- Una clave API de al menos un proveedor:

| Proveedor | Obtener clave |
|-----------|--------------|
| Z.AI (GLM) | [z.ai/manage-apikey/apikey-list](https://z.ai/manage-apikey/apikey-list) |
| MiniMax | [api.minimax.io](https://api.minimax.io) |
| DeepSeek | [api.deepseek.com](https://api.deepseek.com) |

## Instalación

```bash
npx github:bioodev/claude-code-providers-hub
```

El instalador detectará tu sistema operativo, preguntará qué proveedores quieres configurar y solicitará tus claves API.

Después de la instalación, recarga tu shell:

```bash
# macOS / Linux
source ~/.zshrc   # o ~/.bashrc

# Windows PowerShell
. $PROFILE
```

### Alternativa: ejecutar el script directamente

<details>
<summary>macOS / Linux</summary>

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/bioodev/claude-code-providers-hub/main/install.sh)
source ~/.zshrc
```

</details>

<details>
<summary>Windows (PowerShell)</summary>

```powershell
iwr -useb https://raw.githubusercontent.com/bioodev/claude-code-providers-hub/main/install.ps1 | iex
. $PROFILE
```

Si obtienes un error de política de ejecución:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

</details>

## Uso

```bash
ccg                        # Claude Code con GLM-5.1
ccf                        # Claude Code con GLM-4.5-Air
ccm                        # Claude Code con MiniMax-M2
ccd                        # Claude Code con DeepSeek-chat
cc                         # Claude Code con Anthropic (por defecto)
```

Todos los argumentos estándar de Claude Code funcionan normalmente:

```bash
ccg "refactoriza esta función"
ccg --help
```

## Cómo funciona

Cada comando es un pequeño script wrapper que configura variables de entorno antes de lanzar Claude Code:

| Variable | Propósito |
|----------|-----------|
| `ANTHROPIC_BASE_URL` | Apunta al endpoint API del proveedor |
| `ANTHROPIC_AUTH_TOKEN` | Tu clave API del proveedor |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Mapeo del modelo tier Sonnet |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Mapeo del modelo tier Opus |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Mapeo del modelo tier Haiku (rápido) |
| `CLAUDE_HOME` | Directorio de configuración aislado para este proveedor |

Los directorios de configuración se mantienen separados para que los historiales y ajustes nunca se mezclen:

| Comando | Directorio de configuración |
|---------|-----------------------------|
| `ccg` | `~/.claude-glm/` |
| `ccf` | `~/.claude-glm-fast/` |
| `ccm` | `~/.claude-minimax/` |
| `ccd` | `~/.claude-deepseek/` |
| `cc` | `~/.claude/` (tu configuración original, nunca modificada) |

En Windows, reemplaza `~/` por `%USERPROFILE%\`.

## Actualizar tu clave API

Vuelve a ejecutar el instalador y elige "Update API key only":

```bash
npx github:bioodev/claude-code-providers-hub
```

## Agregar o actualizar modelos

Edita `~/.claude-providers-hub/providers.yaml` para agregar nuevos modelos o cambiar el modelo por defecto de un proveedor, luego reinstala:

```bash
npx github:bioodev/claude-code-providers-hub
```

Consulta [CLAUDE.md](CLAUDE.md) para el esquema completo de proveedores y modelos.

## Solución de problemas

**`ccg: command not found` (o `ccf`, `ccm`, `ccd`)**
La configuración del shell no se recargó después de la instalación. Ejecuta `source ~/.zshrc` (macOS/Linux) o `. $PROFILE` (Windows), o abre una nueva terminal.

**`claude: command not found`**
Claude Code no está instalado o no está en tu PATH. Instálalo desde [anthropic.com/claude-code](https://www.anthropic.com/claude-code) y verifica con `which claude`.

**Errores de autenticación de API**
Verifica que tu clave API sea válida y tenga créditos disponibles. Vuelve a ejecutar el instalador para actualizar la clave.

**Windows: "running scripts is disabled"**
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Contribuir

Los reportes de bugs y pull requests son bienvenidos.

- Reportar problemas: [GitHub Issues](https://github.com/bioodev/claude-code-providers-hub/issues)
- Haz un fork, mejora el proyecto y abre un pull request

## Licencia

MIT — ver [LICENSE](LICENSE).

## Agradecimientos

Este proyecto comenzó como un fork de [claude-glm-wrapper](https://github.com/JoeInnsp23/claude-glm-wrapper) y desde entonces creció hasta convertirse en una herramienta multi-proveedor independiente.

Gracias a [Z.AI](https://z.ai), [MiniMax](https://api.minimax.io), [DeepSeek](https://api.deepseek.com) y [Anthropic](https://anthropic.com) por sus APIs.
