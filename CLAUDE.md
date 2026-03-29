# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Claude Code Providers Hub** (v3.0.0) is a cross-platform installer that enables Claude Code to work with multiple AI providers without affecting the user's existing Anthropic Claude setup. This is an **installer project**, not a traditional application - the main artifacts are bash and PowerShell wrapper scripts that set environment variables before launching the actual Claude Code binary.

### Supported Providers

| Provider | Models | Wrapper command | Alias |
|----------|--------|-----------------|-------|
| Anthropic Claude | claude-sonnet-4 | `claude` | `cc` |
| Z.AI GLM | GLM-5.1, GLM-4.5-Air | `claude-glm`, `claude-glm-fast` | `ccg`, `ccf` |
| MiniMax | MiniMax-M2 | `ccm` | `ccm` |
| DeepSeek | deepseek-chat | `ccd` | `ccd` |

## Key Architecture

### Platform-Specific Installer Pattern
The project uses a **dual-platform installer architecture**:
- `bin/cli.js` - CLI entry point: platform detection, routing, help/version/list commands (~188 lines)
- `install.sh` - Bash installer for Unix/Linux/macOS (~1,323 lines)
- `install.ps1` - PowerShell installer for Windows (~1,251 lines)
- `install` - Universal bootstrap script (OS detection, delegates to install.sh/install.ps1; excluded from npm via `.npmignore`)

Both installers perform identical logical operations with platform-specific syntax. They are the primary code and should be modified together when changing installation behavior.

### Reinstallation / Update Flow
When existing wrappers are detected, the installer offers 4 options:
1. **Update models only** - Extracts API keys from existing wrappers, regenerates wrappers with current model definitions from YAML config (preserves API keys)
2. **Update API key only** - Lets user change the API key for a specific provider
3. **Reinstall everything** - Full reinstall from scratch
4. **Cancel**

### Configuration System
- `lib/config-loader.js` (~519 lines) - YAML-based configuration engine that:
  - Parses provider configurations from `~/.claude-providers-hub/providers.yaml`
  - Generates bash/PowerShell wrapper scripts dynamically
  - Manages API keys in `~/.claude-providers-hub/state.json`
  - Provides a fallback embedded YAML config (`DEFAULT_YAML` constant) if files don't exist
  - Includes a simple YAML parser (no external dependencies)
  - CLI commands: `list`, `get-default-model`, `wrapper-bash`, `export-bash`, `export-powershell`, `save-key`
- `lib/providers.yaml` - Source YAML template (copied to `~/.claude-providers-hub/providers.yaml` on first install)

### Installation Method Enforcement
- `bin/preinstall.js` - Blocks all installation methods except `npx`
- This package is designed to be run with `npx github:bioodev/claude-code-providers-hub`, never installed locally
- The preinstall script detects npx via environment variables and process arguments

### Wrapper Script Pattern
Wrapper scripts (installed to `~/.local/bin/` on Unix, `%USERPROFILE%\.local\bin\` on Windows):
1. Set `ANTHROPIC_BASE_URL` to point to the provider's API endpoint
2. Set `ANTHROPIC_AUTH_TOKEN` with the provider's API key
3. Set model-specific environment variables (`ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`)
4. Set `CLAUDE_HOME` to a provider-specific config directory (e.g., `~/.claude-glm/`)
5. Create a `settings.json` in the config directory with the env vars
6. Launch the `claude` binary with all arguments forwarded

This ensures complete isolation - each provider has its own config directory and chat history.

## Common Commands

### Testing the installer
```bash
# Test the installer (runs interactively)
npx github:bioodev/claude-code-providers-hub

# Show available providers
npx github:bioodev/claude-code-providers-hub --list

# Show help
npx github:bioodev/claude-code-providers-hub --help
```

### Testing configuration loader
```bash
# List all providers
node lib/config-loader.js list

# Get the default (first) model ID for a provider
node lib/config-loader.js get-default-model glm

# Export bash variables for a provider/model
node lib/config-loader.js export-bash glm glm-51 your-api-key

# Generate wrapper script content
node lib/config-loader.js wrapper-bash glm glm-51 your-api-key
```

### Development workflow
1. Edit installer scripts (`install.sh` or `install.ps1`)
2. Test with `bash install.sh` (Unix) or `.\install.ps1` (Windows)
3. When modifying platform-agnostic logic, update both installers
4. The preinstall script will NOT block running installers directly from source

## File Structure

```
bin/
├── cli.js           # CLI entry point - detects platform, routes to installer
└── preinstall.js    # Installation method validator (npx-only enforcement)

lib/
├── config-loader.js # YAML config parser, wrapper generator, state management
└── providers.yaml   # Source provider/model definitions (template for user config)

install               # Universal bootstrap script (OS detection, not in npm package)
install.sh            # Unix/Linux/macOS installer (bash)
install.ps1           # Windows installer (PowerShell)
package.json          # npm package definition
CHANGELOG.md          # Version history
README.md             # English documentation
README.es.md          # Spanish documentation
```

## Configuration State

User state is maintained in `~/.claude-providers-hub/`:
- `providers.yaml` - Provider/model definitions (editable by users for customization)
- `state.json` - API keys and installation metadata

## Important Constraints

- **No traditional tests** - This is an installer that creates system-level changes (scripts, PATH, aliases)
- **Cross-platform changes** - When modifying installer logic, update both `install.sh` and `install.ps1`
- **npx-only design** - The package intentionally blocks `npm install` to ensure users always get the latest version
- **Wrapper scripts are the output** - The main "product" is the generated wrapper scripts, not a running service
- **No external dependencies** - config-loader.js includes its own simple YAML parser; the project has zero npm dependencies

## Adding or Updating Models

### Updating the primary model for an existing provider (e.g. GLM-5.1 → GLM-5.2)

1. Edit `lib/providers.yaml` — rename the model key (e.g. `glm-51` → `glm-52`) and update its `name` and `env.ANTHROPIC_DEFAULT_*_MODEL` values
2. Edit `lib/config-loader.js` — apply the same change to the `DEFAULT_YAML` constant
3. Update `bin/cli.js` — update `showProviders()` to reflect the new model name (this function has hardcoded strings)
4. Update the fallback hardcoded template in `install.sh` (the `cat > "$wrapper_path" << EOF` block in `create_claude_glm_wrapper`) and `install.ps1` (`New-ClaudeGlmWrapper`) to keep them in sync
5. Update the "Update models" section in both installers to show the correct model name in user messages

### Adding a new AI provider

1. Add provider definition to `lib/providers.yaml` and the `DEFAULT_YAML` in `lib/config-loader.js`
2. Follow the existing structure: `name`, `description`, `base_url`, `config_dir`, `models`
3. Update both `install.sh` and `install.ps1` to include the new provider in interactive menus
4. Add a `create_claude_<provider>_wrapper` function to `install.sh` using the dynamic lookup pattern:
   ```bash
   model_id=$(node "$CONFIG_LOADER" get-default-model "<provider>" 2>/dev/null)
   node "$CONFIG_LOADER" wrapper-bash "<provider>" "$model_id" "$API_KEY" > "$wrapper_path"
   ```
5. Add the equivalent `New-Claude<Provider>Wrapper` function to `install.ps1`
6. Update `bin/cli.js` `showProviders()` to include the new provider

## Known Issues

- `bin/cli.js` `showProviders()` contains stale hardcoded model names (e.g., shows "GLM-4.7" instead of current "GLM-5.1") — should read from config-loader dynamically or be updated alongside model changes

## Error Reporting

Both installers include comprehensive error reporting that:
- Automatically generates GitHub issue URLs with pre-filled error details
- Sanitizes sensitive information (API keys, paths) before reporting
- Provides test mode via `CLAUDE_GLM_TEST_ERROR=1` environment variable
