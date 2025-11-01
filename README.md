# Claude AI Providers Installer

Use [Z.AI's GLM models](https://z.ai), [MiniMax models](https://api.minimax.io), and [DeepSeek models](https://api.deepseek.com) with [Claude Code](https://www.anthropic.com/claude-code) — **without losing your existing Claude setup!**

Switch freely between GLM-4.6, GLM-4.5, GLM-4.5-Air, MiniMax-M2, DeepSeek-chat, and original Anthropic Claude models using simple commands.

## Why This Installer?

**💰 Cost-effective**: Z.AI's GLM, MiniMax, and DeepSeek offer competitive pricing (often with free tiers)
**🔄 Risk-free**: Your existing Claude Code setup remains completely untouched
**⚡ Multiple options**: Choose between GLM models, MiniMax-M2, DeepSeek-chat, or regular Claude
**🎯 Perfect for**: Development, testing, or when you want to conserve your Claude API credits
**🏢 Multiple providers**: Support for Z.AI, MiniMax, and DeepSeek APIs
**⏱️ Optimized timeouts**: DeepSeek configured with 10-minute timeout to prevent client timeouts

## Quick Start

### Universal Installation (All Platforms)

**One command works everywhere - Windows, macOS, and Linux:**

```bash
npx claude-ai-providers-installer
# or
npx claude-glm-installer
```

Then activate (platform-specific):
```bash
# macOS / Linux:
source ~/.zshrc  # or ~/.bashrc

# Windows PowerShell:
. $PROFILE
```

### Start Using Multi-Provider Models

**All Platforms:**
```bash
ccg              # Claude Code with GLM-4.6 (latest)
ccg45            # Claude Code with GLM-4.5
ccf              # Claude Code with GLM-4.5-Air (faster)
ccm              # Claude Code with MiniMax-M2 (full config)
ccd              # Claude Code with DeepSeek (deepseek-chat)
cc               # Regular Claude Code
```

That's it! 🎉

---

### Alternative: Platform-Specific Installers

<details>
<summary>Click to expand platform-specific installation methods</summary>

#### macOS / Linux

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/JoeInnsp23/claude-glm-wrapper/powershell/install.sh)
source ~/.zshrc  # or ~/.bashrc
```

#### Windows (PowerShell)

```powershell
iwr -useb https://raw.githubusercontent.com/JoeInnsp23/claude-glm-wrapper/powershell/install.ps1 | iex
. $PROFILE
```

</details>

## Features

- 🚀 **Easy switching** between GLM, MiniMax, DeepSeek, and Claude models
- ⚡ **Multiple models**: GLM-4.6 (latest), GLM-4.5, GLM-4.5-Air (fast), MiniMax-M2, and DeepSeek-chat
- 🏢 **Multiple providers**: Support for Z.AI, MiniMax, and DeepSeek APIs
- 🔒 **No sudo/admin required**: Installs to user's home directory
- 🖥️ **Cross-platform**: Works on Windows, macOS, and Linux
- 📁 **Isolated configs**: Each model uses its own config directory — no conflicts!
- 🔧 **Shell aliases**: Quick access with simple commands

## Prerequisites

1. **Node.js** (v14+): For npx installation - [nodejs.org](https://nodejs.org/)
2. **Claude Code**: Install from [anthropic.com/claude-code](https://www.anthropic.com/claude-code)
3. **API Keys** (choose one or more):
   - **Z.AI API Key**: Get your free key from [z.ai/manage-apikey/apikey-list](https://z.ai/manage-apikey/apikey-list)
   - **MiniMax API Key**: Get your key from [api.minimax.io](https://api.minimax.io)
   - **DeepSeek API Key**: Get your key from [api.deepseek.com](https://api.deepseek.com)

*Note: If you don't have Node.js, you can use the platform-specific installers (see Quick Start above)*

## Installation

### Method 1: npx (Recommended - All Platforms)

**One command for Windows, macOS, and Linux:**

```bash
npx claude-ai-providers-installer
```

The installer will:
- Auto-detect your operating system
- Check if Claude Code is installed
- Let you choose which provider(s) to install (GLM, MiniMax, or both)
- Ask for your API key(s)
- Create platform-appropriate wrapper scripts
- Add convenient aliases to your shell/profile

After installation, **activate the changes**:

```bash
# macOS / Linux:
source ~/.zshrc  # or ~/.bashrc

# Windows PowerShell:
. $PROFILE
```

### Method 2: Platform-Specific Installers

<details>
<summary>macOS / Linux</summary>

**One-Line Install:**
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/JoeInnsp23/claude-glm-wrapper/powershell/install.sh)
source ~/.zshrc  # or ~/.bashrc
```

**Clone and Install:**
```bash
git clone https://github.com/JoeInnsp23/claude-glm-wrapper.git
cd claude-glm-wrapper
bash install.sh
source ~/.zshrc
```

</details>

<details>
<summary>Windows (PowerShell)</summary>

**One-Line Install:**
```powershell
iwr -useb https://raw.githubusercontent.com/JoeInnsp23/claude-glm-wrapper/powershell/install.ps1 | iex
. $PROFILE
```

**Clone and Install:**
```powershell
git clone https://github.com/JoeInnsp23/claude-glm-wrapper.git
cd claude-glm-wrapper
.\install.ps1
. $PROFILE
```

**Note:** If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

</details>

## Usage

### Available Commands & Aliases

The installer creates these commands and aliases:

| Alias | Full Command | What It Does | When to Use |
|-------|--------------|--------------|-------------|
| `cc` | `claude` | Regular Claude Code | Default - your normal Claude setup |
| `ccg` | `claude-glm` | GLM-4.6 (latest) | Best quality GLM model |
| `ccg45` | `claude-glm-4.5` | GLM-4.5 | Previous version of GLM |
| `ccf` | `claude-glm-fast` | GLM-4.5-Air (fast) | Quicker responses, lower cost |
| `ccm` | `ccm` | MiniMax-M2 | MiniMax with full configuration |

**💡 Tip**: Use the short aliases! They're faster to type and easier to remember.

### How It Works

Each command starts a **separate Claude Code session** with different configurations:
- `ccg`, `ccg45`, and `ccf` use Z.AI's API with your Z.AI key
- `ccm` uses MiniMax's API with your MiniMax key (includes timeout and traffic settings)
- `cc` uses Anthropic's API with your Anthropic key (default Claude setup)
- Your configurations **never conflict** — they're stored in separate directories

### Basic Examples

**Start a coding session with the latest GLM:**
```bash
ccg
# Opens Claude Code using GLM-4.6
```

**Use GLM-4.5:**
```bash
ccg45
# Opens Claude Code using GLM-4.5
```

**Need faster responses? Use the fast model:**
```bash
ccf
# Opens Claude Code using GLM-4.5-Air
```

**Use regular Claude:**
```bash
cc
# Opens Claude Code with Anthropic models (your default setup)
```

**Pass arguments like normal:**
```bash
ccg --help
ccg "refactor this function"
ccf "quick question about Python"
```

## Common Workflows

### Workflow 1: Testing with GLM, Production with Claude
```bash
# Develop and test with cost-effective GLM-4.6
ccg
# ... work on your code ...
# exit

# Switch to Claude for final review
cc
# ... final review with Claude ...
```

### Workflow 2: Quick Questions with Fast Model
```bash
# Quick syntax questions
ccf "how do I use async/await in Python?"

# Complex refactoring with latest GLM
ccg
# ... longer coding session ...
```

### Workflow 3: Using MiniMax Provider
```bash
# Use MiniMax-M2 with full configuration
ccm
# ... coding session with MiniMax ...
```

### Workflow 4: Multiple Projects
```bash
# Project 1: Use GLM to save costs
cd ~/project1
ccg

# Project 2: Use MiniMax for different tasks
cd ~/project2
ccm

# Project 3: Use Claude for critical work
cd ~/project3
cc
```

**Each session is independent** — your chat history stays separate!

## Configuration Details

### Where Things Are Stored

Each wrapper uses its own configuration directory to prevent conflicts:

**macOS / Linux:**
| Command | Config Directory | Purpose |
|---------|-----------------|---------|
| `claude-glm` | `~/.claude-glm/` | GLM-4.6 settings and history |
| `claude-glm-4.5` | `~/.claude-glm-45/` | GLM-4.5 settings and history |
| `claude-glm-fast` | `~/.claude-glm-fast/` | GLM-4.5-Air settings and history |
| `ccm` | `~/.claude-minimax/` | MiniMax-M2 settings and history |
| `claude` | `~/.claude/` (default) | Your original Claude setup |

**Windows:**
| Command | Config Directory | Purpose |
|---------|-----------------|---------|
| `claude-glm` | `%USERPROFILE%\.claude-glm\` | GLM-4.6 settings and history |
| `claude-glm-4.5` | `%USERPROFILE%\.claude-glm-45\` | GLM-4.5 settings and history |
| `claude-glm-fast` | `%USERPROFILE%\.claude-glm-fast\` | GLM-4.5-Air settings and history |
| `ccm` | `%USERPROFILE%\.claude-minimax\` | MiniMax-M2 settings and history |
| `claude` | `%USERPROFILE%\.claude\` (default) | Your original Claude setup |

**This means:**
- ✅ Your original Claude settings are **never touched**
- ✅ Chat histories stay separate for each model
- ✅ API keys are isolated — no mixing!

### Wrapper Scripts Location

**macOS / Linux:** `~/.local/bin/`
- `claude-glm` (GLM-4.6)
- `claude-glm-4.5` (GLM-4.5)
- `claude-glm-fast` (GLM-4.5-Air)
- `ccm` (MiniMax-M2)

**Windows:** `%USERPROFILE%\.local\bin\`
- `claude-glm.ps1` (GLM-4.6)
- `claude-glm-4.5.ps1` (GLM-4.5)
- `claude-glm-fast.ps1` (GLM-4.5-Air)
- `ccm.ps1` (MiniMax-M2)

These are just tiny wrapper scripts (bash or PowerShell) that set the right environment variables before launching Claude Code.

## Updating Your API Key

### macOS / Linux

**Option 1: Use the Installer**
```bash
cd claude-glm-wrapper && bash install.sh
# Choose option "1) Update API key only"
```

**Option 2: Edit Manually**
```bash
nano ~/.local/bin/claude-glm
nano ~/.local/bin/claude-glm-4.5
nano ~/.local/bin/claude-glm-fast
# Find and replace ANTHROPIC_AUTH_TOKEN value
```

### Windows (PowerShell)

**Option 1: Use the Installer**
```powershell
cd claude-glm-wrapper
.\install.ps1
# Choose option "1) Update API key only"
```

**Option 2: Edit Manually**
```powershell
notepad "$env:USERPROFILE\.local\bin\claude-glm.ps1"
notepad "$env:USERPROFILE\.local\bin\claude-glm-4.5.ps1"
notepad "$env:USERPROFILE\.local\bin\claude-glm-fast.ps1"
# Find and replace $ZaiApiKey value
```

## How It Works (Technical Details)

The wrapper scripts work by setting environment variables before launching Claude Code:

| Environment Variable | What It Does |
|---------------------|--------------|
| `ANTHROPIC_BASE_URL` | Points to Z.AI's API endpoint |
| `ANTHROPIC_AUTH_TOKEN` | Your Z.AI API key |
| `ANTHROPIC_MODEL` | Which model to use (glm-4.5 or glm-4.5-air) |
| `CLAUDE_HOME` | Where to store config files |

Claude Code reads these variables and uses them instead of the defaults. Simple! 🎯

## Troubleshooting

### ❌ "claude command not found"

**Problem**: Claude Code isn't installed or not in your PATH.

**Solutions**:
1. Install Claude Code from [anthropic.com/claude-code](https://www.anthropic.com/claude-code)
2. Or add Claude to your PATH if it's installed elsewhere

**Test it**: Run `which claude` — it should show a path.

### ❌ "ccg: command not found" (or ccg45, ccf, cc)

**Problem**: You didn't source your shell config after installation.

**Solution**: Run the source command the installer showed you:
```bash
source ~/.zshrc  # or ~/.bashrc
```

**Still not working?** Try opening a new terminal window.

### ❌ API Authentication Errors

**Problem**: Z.AI API key issues.

**Solutions**:
1. **Check your key**: Visit [z.ai/manage-apikey/apikey-list](https://z.ai/manage-apikey/apikey-list)
2. **Verify credits**: Make sure your Z.AI account has available credits
3. **Update the key**: Run `bash install.sh` and choose "Update API key only"

### ❌ Wrong Model Being Used

**Problem**: Using `ccg` but it's using the wrong API.

**Solution**: Each command is independent. Make sure you:
- Exit any running Claude Code session
- Start fresh with the command you want (`ccg`, `ccg45`, `ccf`, or `cc`)

### 🪟 Windows-Specific Issues

**❌ "cannot be loaded because running scripts is disabled"**

**Problem**: PowerShell execution policy prevents running scripts.

**Solution**:
```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

**❌ "ccg: The term 'ccg' is not recognized"**

**Problem**: PowerShell profile wasn't reloaded after installation.

**Solutions**:
1. Reload profile: `. $PROFILE`
2. Or restart PowerShell
3. Or run the full command: `claude-glm`

**❌ PATH not updated**

**Problem**: The `~/.local/bin` or `$env:USERPROFILE\.local\bin` directory isn't in your PATH.

**Solution**: The installer adds it automatically, but you may need to restart PowerShell for it to take effect.

### 💡 General Tips

- **Open new terminal**: After installation, aliases work in new terminals automatically
- **Check the greeting**: Each command prints what model it's using when it starts
- **Test with**: `ccg --version` to verify the command works

## Uninstallation

### macOS / Linux

**Remove wrapper scripts:**
```bash
rm ~/.local/bin/claude-glm
rm ~/.local/bin/claude-glm-4.5
rm ~/.local/bin/claude-glm-fast
```

**Remove config directories** (optional - deletes chat history):
```bash
rm -rf ~/.claude-glm
rm -rf ~/.claude-glm-45
rm -rf ~/.claude-glm-fast
```

**Remove aliases** from `~/.zshrc` or `~/.bashrc`:
```bash
# Delete these lines:
# Claude Code Model Switcher Aliases
alias cc='claude'
alias ccg='claude-glm'
alias ccg45='claude-glm-4.5'
alias ccf='claude-glm-fast'
```

Then run: `source ~/.zshrc`

### Windows (PowerShell)

**Remove wrapper scripts:**
```powershell
Remove-Item "$env:USERPROFILE\.local\bin\claude-glm.ps1"
Remove-Item "$env:USERPROFILE\.local\bin\claude-glm-4.5.ps1"
Remove-Item "$env:USERPROFILE\.local\bin\claude-glm-fast.ps1"
```

**Remove config directories** (optional - deletes chat history):
```powershell
Remove-Item -Recurse "$env:USERPROFILE\.claude-glm"
Remove-Item -Recurse "$env:USERPROFILE\.claude-glm-45"
Remove-Item -Recurse "$env:USERPROFILE\.claude-glm-fast"
```

**Remove aliases** from PowerShell profile:
```powershell
notepad $PROFILE
# Delete these lines:
# Claude Code Model Switcher Aliases
Set-Alias cc claude
Set-Alias ccg claude-glm
Set-Alias ccg45 claude-glm-4.5
Set-Alias ccf claude-glm-fast
```

Then reload: `. $PROFILE`

## FAQ

### Q: Will this affect my existing Claude Code setup?
**A**: No! Your regular Claude Code setup is completely untouched. The wrappers use separate config directories.

### Q: Can I use both GLM, MiniMax, and Claude in the same project?
**A**: Yes! Just use `ccg` for GLM sessions, `ccm` for MiniMax sessions, and `cc` for Claude sessions. Each maintains its own chat history.

### Q: Which model should I use?
**A**:
- Use **`ccg` (GLM-4.6)** for: Latest GLM model, complex coding, refactoring, detailed explanations
- Use **`ccg45` (GLM-4.5)** for: Previous version of GLM, if you need consistency with older projects
- Use **`ccf` (GLM-4.5-Air)** for: Quick questions, simple tasks, faster responses, lower cost
- Use **`ccm` (MiniMax-M2)** for: MiniMax provider with full configuration (timeout and traffic settings)
- Use **`cc` (Claude)** for: Your regular Anthropic Claude setup

### Q: Is this secure?
**A**: Yes! Your API keys are stored locally on your machine in wrapper scripts (bash or PowerShell, depending on your OS). Keep your scripts directory secure with appropriate permissions.

### Q: Does this work on Windows?
**A**: Yes! Use the PowerShell installer (install.ps1). Windows, macOS, and Linux are all fully supported.

### Q: Can I use a different Z.AI model?
**A**: Yes! Edit the wrapper scripts in `~/.local/bin/` and change the `ANTHROPIC_MODEL` variable to any model Z.AI supports.

### Q: What happens if I run out of credits on one provider?
**A**: Commands using that provider will fail with an API error. Just switch to another provider using `cc` (Claude), `ccg` (GLM), or `ccm` (MiniMax) until you add more credits to the affected provider.

## Contributing

Found a bug? Have an idea? Contributions are welcome!

- 🐛 **Report issues**: [GitHub Issues](https://github.com/JoeInnsp23/claude-glm-wrapper/issues)
- 🔧 **Submit PRs**: Fork, improve, and open a pull request
- 💡 **Share feedback**: Tell us how you're using this tool!

## License

MIT License - see [LICENSE](LICENSE) file for details.

**TL;DR**: Free to use, modify, and distribute. No warranty provided.

## Acknowledgments

- 🙏 [Z.AI](https://z.ai) for providing GLM model API access
- 🙏 [Anthropic](https://anthropic.com) for Claude Code
- 🙏 You, for using this tool!

---

**⭐ Found this useful?** Give it a star on GitHub and share it with others!
