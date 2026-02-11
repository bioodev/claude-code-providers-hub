# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Claude Code Providers Hub** is a cross-platform installer that enables Claude Code to work with multiple AI providers (GLM/Z.AI, MiniMax, DeepSeek) without affecting the user's existing Anthropic Claude setup. This is an **installer project**, not a traditional application - the main artifacts are bash and PowerShell wrapper scripts that set environment variables before launching the actual Claude Code binary.

## Key Architecture

### Platform-Specific Installer Pattern
The project uses a **dual-platform installer architecture**:
- `bin/cli.js` - Platform detection and routing, runs the appropriate installer
- `install.sh` - Bash installer for Unix/Linux/macOS (~1,070 lines)
- `install.ps1` - PowerShell installer for Windows (~950 lines)

Both installers perform identical logical operations with platform-specific syntax. They are the primary code and should be modified together when changing installation behavior.

### Configuration System
- `lib/config-loader.js` - YAML-based configuration engine that:
  - Parses provider configurations from `~/.claude-providers-hub/providers.yaml`
  - Generates bash/PowerShell wrapper scripts dynamically
  - Manages API keys in `~/.claude-providers-hub/state.json`
  - Provides a fallback embedded YAML config if files don't exist

### Installation Method Enforcement
- `bin/preinstall.js` - Blocks all installation methods except `npx`
- This package is designed to be run with `npx github:bioodev/claude-code-providers-hub`, never installed locally
- The preinstall script detects npx via environment variables and process arguments

### Wrapper Script Pattern
Wrapper scripts (installed to `~/.local/bin/` on Unix, `%USERPROFILE%\.local\bin\` on Windows):
1. Set `ANTHROPIC_BASE_URL` to point to the provider's API endpoint
2. Set `ANTHROPIC_AUTH_TOKEN` with the provider's API key
3. Set `ANTHROPIC_MODEL` and related model-specific environment variables
4. Set `CLAUDE_HOME` to a provider-specific config directory (e.g., `~/.claude-glm/`)
5. Launch the `claude` binary with all arguments forwarded

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

# Export bash variables for a provider/model
node lib/config-loader.js export-bash glm glm-47 your-api-key

# Generate wrapper script content
node lib/config-loader.js wrapper-bash glm glm-47 your-api-key
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
└── config-loader.js # YAML config parser, wrapper generator, state management

install.sh           # Unix/Linux/macOS installer (bash)
install.ps1          # Windows installer (PowerShell)
package.json         # npm package definition
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

## Adding a New Provider

To add a new AI provider:

1. Add provider definition to the embedded YAML in `lib/config-loader.js` (DEFAULT_YAML constant)
2. Follow the existing structure with: `name`, `description`, `base_url`, `config_dir`, `models`
3. Update both `install.sh` and `install.ps1` to include the new provider in interactive menus
4. Add wrapper script generation logic to both installers

## Error Reporting

Both installers include comprehensive error reporting that:
- Automatically generates GitHub issue URLs with pre-filled error details
- Sanitizes sensitive information (API keys, paths) before reporting
- Provides test mode via `CLAUDE_GLM_TEST_ERROR=1` environment variable
