# Claude Code Providers Hub

> [English version](README.md)

Usa modelos de GLM (Z.AI), MiniMax y DeepSeek con [Claude Code](https://www.anthropic.com/claude-code) — sin tocar tu configuración de Anthropic existente.

Cada proveedor corre en un entorno completamente aislado: directorio de configuración propio, historial de chat separado y clave API independiente.

## Proveedores disponibles

| Comando | Proveedor | Modelos (Opus/Sonnet/Haiku) | Ideal para |
|---------|-----------|----------------------------|------------|
| `ccg` | Z.AI | GLM MAX: glm-5.1 / glm-5-turbo / glm-4.7 | Máxima potencia, tareas complejas (3× cuota en hora pico) |
| `ccgs` | Z.AI | GLM Standard: glm-5-turbo / glm-4.7 / glm-4.6 | Balance potencia/costo (mixto) |
| `ccf` | Z.AI | GLM Fast: glm-4.7 / glm-4.6 / glm-4.5-air | Máximo ahorro, solo 4.x (siempre 1× cuota) |
| `ccm` | MiniMax | MiniMax-M2 | Tareas con MiniMax |
| `ccd` | DeepSeek | deepseek-chat | Tareas enfocadas en código |
| `cc` | Anthropic | Claude | Tu configuración original (sin cambios) |

> **Nota de cuota:** Los modelos 5.x de Z.AI usan multiplicador 3× en hora pico (2× en valle). Los modelos 4.x siempre cuestan 1×.

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
ccg                        # Claude Code con GLM MAX (glm-5.1/glm-5-turbo/glm-4.7)
ccgs                       # Claude Code con GLM Standard (glm-5-turbo/glm-4.7/glm-4.6)
ccf                        # Claude Code con GLM Fast (glm-4.7/glm-4.6/glm-4.5-air)
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
| `ccgs` | `~/.claude-glm-standard/` |
| `ccf` | `~/.claude-glm-fast/` |
| `ccm` | `~/.claude-minimax/` |
| `ccd` | `~/.claude-deepseek/` |
| `cc` | `~/.claude/` (tu configuración original, nunca modificada) |

> **Nota:** Cada directorio contiene un `settings.json` que se regenera automáticamente cada vez que ejecutas el wrapper — siempre refleja la configuración actual.

En Windows, reemplaza `~/` por `%USERPROFILE%\`.

## Configuración avanzada

El instalador incluye un paso opcional de **opciones avanzadas** después de recopilar las claves API. Puedes activar/desactivar la telemetría, deshabilitar actualizaciones automáticas y configurar límites por proveedor. Para acceder en una instalación existente:

```bash
npx github:bioodev/claude-code-providers-hub
# Elige: "Update models only" → responde y cuando pregunte por opciones avanzadas
```

### Variables de entorno disponibles

Claude Code admite más de 60 variables de entorno. Las más útiles se muestran a continuación — todas pueden configurarse mediante el menú del instalador o agregarse manualmente (ver más abajo).

#### Autenticación y API

| Variable | Descripción |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Clave API principal para autenticación con Anthropic |
| `ANTHROPIC_BASE_URL` | Endpoint API personalizado (proxies o proveedores alternativos) |

#### Selección de modelos

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `ANTHROPIC_MODEL` | Modelo principal (override) | `claude-sonnet-4` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Mapeo del modelo tier Opus | `claude-opus-4` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Mapeo del modelo tier Sonnet | `claude-sonnet-4` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Modelo Haiku (tareas en segundo plano) | `claude-haiku-4` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Modelo para subagentes (hereda del principal si no se define) | |

#### Rendimiento y límites

| Variable | Descripción | Por defecto |
|----------|-------------|-------------|
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Tokens máximos por respuesta (máx. 64k) | 32768 |
| `CLAUDE_CODE_EFFORT_LEVEL` | Nivel de razonamiento: `low` / `medium` / `high` / `max` / `auto` | `auto` |
| `API_TIMEOUT_MS` | Timeout de solicitudes HTTP en milisegundos | varía |
| `BASH_DEFAULT_TIMEOUT_MS` | Timeout para comandos Bash | — |
| `MAX_THINKING_TOKENS` | Límite de tokens para razonamiento interno | — |

#### Telemetría y privacidad

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `DISABLE_TELEMETRY` | `1` | Desactiva métricas de uso (Statsig) |
| `DISABLE_ERROR_REPORTING` | `1` | Desactiva reportes de errores (Sentry) |
| `DISABLE_FEEDBACK_COMMAND` | `1` | Bloquea el comando `/feedback` |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` | Bloquea todo tráfico no esencial |
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `0` | Desactiva métricas OpenTelemetry |
| `OTEL_METRICS_EXPORTER` | `none` | Desactiva exportación de métricas OTEL |
| `OTEL_TRACES_EXPORTER` | `none` | Desactiva exportación de trazas OTEL |

#### Comportamiento

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `CLAUDE_CODE_DISABLE_AUTO_UPDATES` | `1` | Desactiva actualizaciones automáticas de Claude Code |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | `1` | Desactiva headers beta (soluciona errores en Bedrock/Vertex) |

#### Integración

| Variable | Descripción |
|----------|-------------|
| `HTTP_PROXY` / `HTTPS_PROXY` | Proxies de red para conexiones externas |
| `MCP_TIMEOUT` | Timeout para conexiones a servidores MCP |
| `CLAUDE_CODE_IDE_HOST_OVERRIDE` | Host IDE personalizado |

### Agregar cualquier variable manualmente

Añade cualquier variable en la configuración de tu proveedor en `~/.claude-providers-hub/providers.yaml`:

```yaml
providers:
  glm:
    models:
      glm-51:
        env:
          CLAUDE_CODE_MAX_OUTPUT_TOKENS: "32000"
          BASH_DEFAULT_TIMEOUT_MS: "30000"
          DISABLE_TELEMETRY: "1"
```

Luego regenera el wrapper:

```bash
npx github:bioodev/claude-code-providers-hub
# Elige: "Update models only"
```

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

## Desinstalar

Elimina todos los wrappers, alias y opcionalmente los directorios de configuración:

```bash
npx github:bioodev/claude-code-providers-hub uninstall
```

El desinstalador:
1. Elimina todos los wrapper scripts de `~/.local/bin`
2. Pregunta antes de eliminar los directorios de config de cada proveedor (contiene historial de chat)
3. Elimina los aliases del shell de `.bashrc`/`.zshrc`/PowerShell profile
4. Elimina la entrada PATH si `~/.local/bin` queda vacío
5. Pregunta antes de eliminar `~/.claude-providers-hub/` (providers.yaml, state.json)

## Reinstalación y limpieza

Al reinstalar, el instalador detecta automáticamente:
- **Instalaciones huérfanas** — wrappers/configs de providers o modelos que ya no existen en la configuración actual (ej: versiones anteriores de modelos), y ofrece eliminarlos. Nota: solo se detectan wrappers registrados en `state.json`; los instalados antes de v3.0.0 pueden requerir eliminación manual desde `~/.local/bin/`.
- **Configuración desactualizada** — si tu `providers.yaml` tiene una versión vieja, ofrece actualizarla desde los defaults (con backup `.bak`)

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
