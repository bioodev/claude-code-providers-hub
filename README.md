# Claude Code Providers Hub

> [Versión en español](README.es.md)

Use GLM (Z.AI), MiniMax, and DeepSeek models with [Claude Code](https://www.anthropic.com/claude-code) — without touching your existing Anthropic setup.

Each provider runs in a fully isolated environment: separate config directory, separate chat history, separate API key.

## Available Providers

| Command | Provider | Model | Best for |
|---------|----------|-------|----------|
| `ccg` | Z.AI | GLM-5.1 | Best quality GLM, complex tasks |
| `ccf` | Z.AI | GLM-4.5-Air | Faster responses, lower cost |
| `ccm` | MiniMax | MiniMax-M2 | MiniMax tasks |
| `ccd` | DeepSeek | deepseek-chat | Coding-focused tasks |
| `cc` | Anthropic | Claude | Your original setup (unchanged) |

## Requirements

- [Node.js](https://nodejs.org/) v14+
- [Claude Code](https://www.anthropic.com/claude-code) installed and working
- An API key from at least one provider:

| Provider | Get API Key |
|----------|-------------|
| Z.AI (GLM) | [z.ai/manage-apikey/apikey-list](https://z.ai/manage-apikey/apikey-list) |
| MiniMax | [api.minimax.io](https://api.minimax.io) |
| DeepSeek | [api.deepseek.com](https://api.deepseek.com) |

## Installation

```bash
npx github:bioodev/claude-code-providers-hub
```

The installer will detect your OS, ask which providers you want to set up, and prompt for your API keys.

After installation, reload your shell:

```bash
# macOS / Linux
source ~/.zshrc   # or ~/.bashrc

# Windows PowerShell
. $PROFILE
```

### Alternative: run the script directly

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

If you get an execution policy error first:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

</details>

## Usage

```bash
ccg                        # Open Claude Code with GLM-5.1
ccf                        # Open Claude Code with GLM-4.5-Air
ccm                        # Open Claude Code with MiniMax-M2
ccd                        # Open Claude Code with DeepSeek-chat
cc                         # Open Claude Code with Anthropic (default)
```

All standard Claude Code arguments work as usual:

```bash
ccg "refactor this function"
ccg --help
```

## How It Works

Each command is a small wrapper script that sets environment variables before launching Claude Code:

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_BASE_URL` | Points to the provider's API endpoint |
| `ANTHROPIC_AUTH_TOKEN` | Your provider API key |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Default Sonnet-tier model mapping |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Default Opus-tier model mapping |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Default Haiku-tier (fast) model mapping |
| `CLAUDE_HOME` | Isolated config directory for this provider |

Config directories are kept separate so chat histories and settings never mix:

| Command | Config Directory |
|---------|-----------------|
| `ccg` | `~/.claude-glm/` |
| `ccf` | `~/.claude-glm-fast/` |
| `ccm` | `~/.claude-minimax/` |
| `ccd` | `~/.claude-deepseek/` |
| `cc` | `~/.claude/` (your original, never modified) |

On Windows, replace `~/` with `%USERPROFILE%\`.

## Advanced Configuration

The installer includes an optional **Advanced Options** step after API key collection. You can toggle telemetry, disable auto-updates, and set limits per provider. To access it on an existing install, run:

```bash
npx github:bioodev/claude-code-providers-hub
# Choose: "Update models only" → answer y when asked about advanced options
```

### Available Environment Variables

Claude Code supports 60+ environment variables. The following are the most useful ones — all can be configured through the installer menu or added manually (see below).

#### Authentication & API

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | Main API key for Anthropic authentication |
| `ANTHROPIC_BASE_URL` | Custom API endpoint (proxies or alternative providers) |

#### Model Selection

| Variable | Description | Example |
|----------|-------------|---------|
| `ANTHROPIC_MODEL` | Primary model override | `claude-sonnet-4` |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Opus-tier model mapping | `claude-opus-4` |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Sonnet-tier model mapping | `claude-sonnet-4` |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Haiku-tier model (background tasks) | `claude-haiku-4` |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Model used for subagents (inherits main if unset) | |

#### Performance & Limits

| Variable | Description | Default |
|----------|-------------|---------|
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max tokens per response (max 64k) | 32768 |
| `CLAUDE_CODE_EFFORT_LEVEL` | Reasoning level: `low` / `medium` / `high` / `max` / `auto` | `auto` |
| `API_TIMEOUT_MS` | HTTP request timeout in milliseconds | varies |
| `BASH_DEFAULT_TIMEOUT_MS` | Timeout for Bash tool commands | — |
| `MAX_THINKING_TOKENS` | Token budget for internal reasoning | — |

#### Telemetry & Privacy

| Variable | Value | Description |
|----------|-------|-------------|
| `DISABLE_TELEMETRY` | `1` | Disable Statsig usage metrics |
| `DISABLE_ERROR_REPORTING` | `1` | Disable Sentry error reports |
| `DISABLE_FEEDBACK_COMMAND` | `1` | Block the `/feedback` command |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` | Block all non-essential network traffic |
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `0` | Disable OpenTelemetry metrics |
| `OTEL_METRICS_EXPORTER` | `none` | Disable OTEL metrics export |
| `OTEL_TRACES_EXPORTER` | `none` | Disable OTEL trace export |

#### Behavior

| Variable | Value | Description |
|----------|-------|-------------|
| `CLAUDE_CODE_DISABLE_AUTO_UPDATES` | `1` | Disable automatic Claude Code updates |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | `1` | Disable beta headers (fixes issues on Bedrock/Vertex) |

#### Integration

| Variable | Description |
|----------|-------------|
| `HTTP_PROXY` / `HTTPS_PROXY` | Network proxies for external connections |
| `MCP_TIMEOUT` | Timeout for MCP server connections |
| `CLAUDE_CODE_IDE_HOST_OVERRIDE` | Custom IDE host address |

### Adding Any Variable Manually

Add any variable to your provider's config in `~/.claude-providers-hub/providers.yaml`:

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

Then regenerate the wrapper:

```bash
npx github:bioodev/claude-code-providers-hub
# Choose: "Update models only"
```

## Uninstall

Remove all installed wrappers, aliases, and optionally config directories:

```bash
npx github:bioodev/claude-code-providers-hub uninstall
```

The uninstaller will:
1. Remove all wrapper scripts from `~/.local/bin`
2. Ask before removing provider config directories (contains chat history)
3. Remove shell aliases from your `.bashrc`/`.zshrc`/PowerShell profile
4. Remove the PATH entry if `~/.local/bin` is empty
5. Ask before removing `~/.claude-providers-hub/` (providers.yaml, state.json)

## Reinstalling and Cleanup

When you re-run the installer over an existing installation, it automatically:

1. **Detects orphaned installations** — wrappers and config directories from providers or models that no longer exist in the current config (e.g., from previous model versions), and offers to remove them
2. **Checks config version** — if your `providers.yaml` is outdated (new providers/models shipped), offers to update it from defaults (API keys in `state.json` are preserved, a `.bak` backup is created)

## Updating Your API Key

Re-run the installer and choose "Update API key only":

```bash
npx github:bioodev/claude-code-providers-hub
```

## Adding or Updating Models

Edit `~/.claude-providers-hub/providers.yaml` to add new models or change the default for a provider, then reinstall:

```bash
npx github:bioodev/claude-code-providers-hub
```

See [CLAUDE.md](CLAUDE.md) for the full provider/model schema.

## Troubleshooting

**`ccg: command not found` (or `ccf`, `ccm`, `ccd`)**
The shell config wasn't reloaded after installation. Run `source ~/.zshrc` (macOS/Linux) or `. $PROFILE` (Windows), or open a new terminal.

**`claude: command not found`**
Claude Code is not installed or not in your PATH. Install it from [anthropic.com/claude-code](https://www.anthropic.com/claude-code), then run `which claude` to verify.

**API authentication errors**
Check that your API key is valid and has available credits. Re-run the installer to update the key.

**Windows: "running scripts is disabled"**
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Contributing

Bug reports and pull requests are welcome.

- Report issues: [GitHub Issues](https://github.com/bioodev/claude-code-providers-hub/issues)
- Fork, improve, and open a pull request

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgments

This project started as a fork of [claude-glm-wrapper](https://github.com/JoeInnsp23/claude-glm-wrapper) and has since grown into an independent multi-provider tool.

Thanks to [Z.AI](https://z.ai), [MiniMax](https://api.minimax.io), [DeepSeek](https://api.deepseek.com), and [Anthropic](https://anthropic.com) for their APIs.
