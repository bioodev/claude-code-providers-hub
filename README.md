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
| `ANTHROPIC_MODEL` | Primary model to use |
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
