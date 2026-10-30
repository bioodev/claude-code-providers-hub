#!/bin/bash
# Claude-GLM Server-Friendly Installer
# Works without sudo, installs to user's home directory
#
# Usage:
#   Test error reporting:
#     CLAUDE_GLM_TEST_ERROR=1 bash <(curl -fsSL https://raw.githubusercontent.com/bioodev/claude-code-providers-hub/main/install.sh)
#     OR: ./install.sh --test-error
#
#   Enable debug mode:
#     CLAUDE_GLM_DEBUG=1 bash <(curl -fsSL https://raw.githubusercontent.com/bioodev/claude-code-providers-hub/main/install.sh)
#     OR: ./install.sh --debug

# Parse command-line arguments
TEST_ERROR=false
DEBUG=false
UNINSTALL=false

for arg in "$@"; do
    case $arg in
        --test-error)
            TEST_ERROR=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        --uninstall)
            UNINSTALL=true
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

# Support environment variables for parameters
if [ "$CLAUDE_GLM_TEST_ERROR" = "1" ] || [ "$CLAUDE_GLM_TEST_ERROR" = "true" ]; then
    TEST_ERROR=true
fi

if [ "$CLAUDE_GLM_DEBUG" = "1" ] || [ "$CLAUDE_GLM_DEBUG" = "true" ]; then
    DEBUG=true
fi

# Configuration
USER_BIN_DIR="$HOME/.local/bin"
PROVIDERS_HUB_DIR="$HOME/.claude-providers-hub"
CONFIG_LOADER="$(dirname "$0")/lib/config-loader.js"

# Legacy config directories (for backward compatibility)
GLM_CONFIG_DIR="$HOME/.claude-glm"
GLM_FAST_CONFIG_DIR="$HOME/.claude-glm-fast"
MINIMAX_CONFIG_DIR="$HOME/.claude-minimax"
DEEPSEEK_CONFIG_DIR="$HOME/.claude-deepseek"
MINIMAX_API_KEY="YOUR_MINIMAX_API_KEY_HERE"
DEEPSEEK_API_KEY="YOUR_DEEPSEEK_API_KEY_HERE"
ZAI_API_KEY="YOUR_ZAI_API_KEY_HERE"

# Ensure config directory exists
mkdir -p "$PROVIDERS_HUB_DIR" 2>/dev/null || true

# Report installation errors to GitHub
report_error() {
    local error_msg="$1"
    local error_line="$2"
    local error_code="$3"

    echo ""
    echo "============================================="
    echo "❌ Installation failed!"
    echo "============================================="
    echo ""

    # Collect system information
    local os_info="$(uname -s) $(uname -r) ($(uname -m))"
    local shell_info="bash $BASH_VERSION"
    local timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')

    # Sanitize error message (remove API keys)
    local sanitized_error=$(echo "$error_msg" | sed \
        -e 's/ANTHROPIC_AUTH_TOKEN="[^"]*"/ANTHROPIC_AUTH_TOKEN="[REDACTED]"/g' \
        -e 's/ZAI_API_KEY="[^"]*"/ZAI_API_KEY="[REDACTED]"/g' \
        -e 's/\$ZAI_API_KEY="[^"]*"/\$ZAI_API_KEY="[REDACTED]"/g')

    # Display error details to user
    echo "Error Details:"
    echo "$sanitized_error"
    if [ -n "$error_line" ]; then
        echo "Location: $error_line"
    fi
    echo ""

    # Ask if user wants to report the error
    echo "Would you like to report this error to GitHub?"
    echo "This will open your browser with a pre-filled issue report."
    read -p "Report error? (y/n): " report_choice
    echo ""

    if [ "$report_choice" != "y" ] && [ "$report_choice" != "Y" ]; then
        echo "Error not reported. You can get help at:"
        echo "  https://github.com/bioodev/claude-code-providers-hub/issues"
        echo ""
        echo "Press Enter to finish..."
        read
        return
    fi

    # Get additional context
    local claude_found="No"
    if command -v claude &> /dev/null; then
        claude_found="Yes ($(which claude))"
    fi

    # Build error report
    local issue_body="## Installation Error (Unix/Linux/macOS)

**OS:** $os_info
**Shell:** $shell_info
**Timestamp:** $timestamp

### Error Details:
\`\`\`
$sanitized_error
\`\`\`
"

    if [ -n "$error_line" ]; then
        issue_body+="
**Error Location:** $error_line
"
    fi

    if [ -n "$error_code" ]; then
        issue_body+="
**Exit Code:** $error_code
"
    fi

    issue_body+="
### System Information:
- Installation Location: $USER_BIN_DIR
- Claude Code Found: $claude_found
- PATH: \`$(echo $PATH | sed 's/:/\n  /g')\`

---
*This error was automatically reported by the installer. Please add any additional context below.*
"

    # URL encode using Python (most compatible)
    local encoded_body=""
    local encoded_title=""

    if command -v python3 &> /dev/null; then
        encoded_body=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$issue_body'''))" 2>/dev/null)
        encoded_title=$(python3 -c "import urllib.parse; print(urllib.parse.quote('Installation Error: Unix/Linux/macOS'))" 2>/dev/null)
    elif command -v python &> /dev/null; then
        encoded_body=$(python -c "import urllib; print urllib.quote('''$issue_body''')" 2>/dev/null)
        encoded_title=$(python -c "import urllib; print urllib.quote('Installation Error: Unix/Linux/macOS')" 2>/dev/null)
    else
        # Fallback: basic URL encoding with sed
        encoded_body=$(echo "$issue_body" | sed 's/ /%20/g; s/\n/%0A/g')
        encoded_title="Installation%20Error%3A%20Unix%2FLinux%2FmacOS"
    fi

    local issue_url="https://github.com/bioodev/claude-code-providers-hub/issues/new?title=${encoded_title}&body=${encoded_body}&labels=bug,unix,installation"

    echo "📋 Error details have been prepared for reporting."
    echo ""

    # Try to open in browser
    local browser_opened=false
    if command -v xdg-open &> /dev/null; then
        if xdg-open "$issue_url" 2>/dev/null; then
            browser_opened=true
            echo "✅ Browser opened with pre-filled error report."
        fi
    elif command -v open &> /dev/null; then
        if open "$issue_url" 2>/dev/null; then
            browser_opened=true
            echo "✅ Browser opened with pre-filled error report."
        fi
    fi

    if [ "$browser_opened" = false ]; then
        echo "⚠️  Could not open browser automatically."
        echo ""
        echo "Please copy and open this URL manually:"
        echo "$issue_url"
    fi

    echo ""

    # Add instructions and wait for user
    if [ "$browser_opened" = true ]; then
        echo "Please review the error report in your browser and submit the issue."
        echo "After submitting (or if you choose not to), return here."
    fi

    echo ""
    echo "Press Enter to continue..."
    read
}

# Find all existing wrapper installations
find_all_installations() {
    local locations=(
        "/usr/local/bin"
        "/usr/bin"
        "$HOME/.local/bin"
        "$HOME/bin"
    )

    local found_files=()

    for location in "${locations[@]}"; do
        if [ -d "$location" ]; then
            # Find all claude-glm* files in this location
            while IFS= read -r file; do
                if [ -f "$file" ]; then
                    found_files+=("$file")
                fi
            done < <(find "$location" -maxdepth 1 -name "claude-glm*" 2>/dev/null)
        fi
    done

    # Return found files (print them)
    printf '%s\n' "${found_files[@]}"
}

# Clean up old wrapper installations
cleanup_old_wrappers() {
    local current_location="$USER_BIN_DIR"
    local all_wrappers=($(find_all_installations))

    if [ ${#all_wrappers[@]} -eq 0 ]; then
        return 0
    fi

    # Separate current location files from old ones
    local old_wrappers=()
    local current_wrappers=()

    for wrapper in "${all_wrappers[@]}"; do
        if [[ "$wrapper" == "$current_location"* ]]; then
            current_wrappers+=("$wrapper")
        else
            old_wrappers+=("$wrapper")
        fi
    done

    # If no old wrappers found, nothing to clean
    if [ ${#old_wrappers[@]} -eq 0 ]; then
        return 0
    fi

    echo ""
    echo "🔍 Found existing wrappers in multiple locations:"
    echo ""

    for wrapper in "${old_wrappers[@]}"; do
        echo "  ❌ $wrapper (old location)"
    done

    if [ ${#current_wrappers[@]} -gt 0 ]; then
        for wrapper in "${current_wrappers[@]}"; do
            echo "  ✅ $wrapper (current location)"
        done
    fi

    echo ""
    read -p "Would you like to clean up old installations? (y/n): " cleanup_choice

    if [[ "$cleanup_choice" == "y" || "$cleanup_choice" == "Y" ]]; then
        echo ""
        echo "Removing old wrappers..."
        for wrapper in "${old_wrappers[@]}"; do
            if rm "$wrapper" 2>/dev/null; then
                echo "  ✅ Removed: $wrapper"
            else
                echo "  ⚠️  Could not remove: $wrapper (permission denied)"
            fi
        done
        echo ""
        echo "✅ Cleanup complete!"
    else
        echo ""
        echo "⚠️  Skipping cleanup. Old wrappers may interfere with the new installation."
        echo "   You may want to manually remove them later."
    fi

    echo ""
}

# Detect shell and rc file
detect_shell_rc() {
    local shell_name=$(basename "$SHELL")
    local rc_file=""
    
    case "$shell_name" in
        bash)
            rc_file="$HOME/.bashrc"
            [ -f "$HOME/.bash_profile" ] && rc_file="$HOME/.bash_profile"
            ;;
        zsh)
            rc_file="$HOME/.zshrc"
            ;;
        ksh)
            rc_file="$HOME/.kshrc"
            [ -f "$HOME/.profile" ] && rc_file="$HOME/.profile"
            ;;
        csh|tcsh)
            rc_file="$HOME/.cshrc"
            ;;
        *)
            rc_file="$HOME/.profile"
            ;;
    esac
    
    echo "$rc_file"
}

# Ensure user bin directory exists and is in PATH
setup_user_bin() {
    # Create user bin directory
    mkdir -p "$USER_BIN_DIR"
    
    local rc_file=$(detect_shell_rc)
    
    # Check if PATH includes user bin
    if [[ ":$PATH:" != *":$USER_BIN_DIR:"* ]]; then
        echo "📝 Adding $USER_BIN_DIR to PATH in $rc_file"
        
        # Add to PATH based on shell type
        if [[ "$rc_file" == *".cshrc" ]]; then
            echo "setenv PATH \$PATH:$USER_BIN_DIR" >> "$rc_file"
        else
            echo "export PATH=\"\$PATH:$USER_BIN_DIR\"" >> "$rc_file"
        fi
        
        echo ""
        echo "⚠️  IMPORTANT: You will need to run this command after installation:"
        echo "   source $rc_file"
        echo ""
    fi
}

# Create a wrapper script for a provider/model.
# Content, filename, alias and config dir are all derived from config-loader.js
# (providers.yaml), so adding a model only requires editing the YAML.
create_wrapper_for() {
    local provider="$1"
    local model_id="$2"
    local api_key="$3"

    if [ ! -f "$CONFIG_LOADER" ]; then
        echo "❌ Error: config-loader.js not found at $CONFIG_LOADER"
        return 1
    fi

    local wrapper_name alias config_dir wrapper_path
    wrapper_name=$(node "$CONFIG_LOADER" get-wrapper-name "$provider" "$model_id" 2>/dev/null)
    alias=$(node "$CONFIG_LOADER" get-alias "$provider" "$model_id" 2>/dev/null)
    config_dir=$(node "$CONFIG_LOADER" get-config-dir "$provider" "$model_id" 2>/dev/null)

    if [ -z "$wrapper_name" ]; then
        echo "❌ Error: could not resolve wrapper name for $provider/$model_id"
        return 1
    fi

    wrapper_path="$USER_BIN_DIR/$wrapper_name"

    if ! node "$CONFIG_LOADER" wrapper-bash "$provider" "$model_id" "$api_key" > "$wrapper_path" 2>/dev/null; then
        echo "❌ Error generating $wrapper_name (provider=$provider model=$model_id)"
        rm -f "$wrapper_path"
        return 1
    fi

    chmod +x "$wrapper_path"
    echo "✅ Installed $wrapper_name at $wrapper_path"
    node "$CONFIG_LOADER" record-wrapper "$provider" "$model_id" "$wrapper_path" "$config_dir" "$alias" 2>/dev/null
}

# Clean up wrappers for providers not selected in this installation
cleanup_unselected_wrappers() {
    local selected_providers="$1"  # Space-separated list: "glm", "minimax", "deepseek"

    # Discover existing wrappers/configs/aliases for providers NOT selected,
    # driven by config (single source of truth). Passthrough providers
    # (base_url empty, e.g. official claude) are skipped — they have no wrapper.
    local existing_wrappers=""
    local existing_configs=""
    local existing_aliases=""

    if [ -f "$CONFIG_LOADER" ]; then
        while IFS=$'\t' read -r provider _model wrapper alias config_dir base_url; do
            [ -n "$base_url" ] || continue                       # skip passthrough
            [[ " $selected_providers " =~ " $provider " ]] && continue
            [ -f "$USER_BIN_DIR/$wrapper" ] && existing_wrappers="$existing_wrappers $wrapper"
            [ -d "$config_dir" ] && existing_configs="$existing_configs $config_dir"
            [ -n "$alias" ] && existing_aliases="$existing_aliases $alias"
        done < <(node "$CONFIG_LOADER" list-models 2>/dev/null)
    fi

    # If nothing to clean, return
    if [ -z "$existing_wrappers" ] && [ -z "$existing_configs" ]; then
        return
    fi

    # Show what will be removed
    echo ""
    echo "🔍 Detected existing wrappers from providers NOT selected in this installation:"
    echo ""

    if [ -n "$existing_wrappers" ]; then
        echo "   Wrapper scripts:"
        for wrapper in $existing_wrappers; do
            echo "     - $wrapper"
        done
    fi

    if [ -n "$existing_configs" ]; then
        echo ""
        echo "   Config directories (includes chat history):"
        for config in $existing_configs; do
            echo "     - $config"
        done
    fi

    echo ""
    read -p "❓ Do you want to remove these unselected provider wrappers? (y/N): " cleanup_choice

    if [ "$cleanup_choice" = "y" ] || [ "$cleanup_choice" = "Y" ]; then
        echo ""
        echo "🧹 Removing unselected provider wrappers..."

        for wrapper in $existing_wrappers; do
            rm -f "$USER_BIN_DIR/$wrapper"
            echo "   ✅ Removed: $wrapper"
        done
        for config in $existing_configs; do
            rm -rf "$config"
            echo "   ✅ Removed: $config"
        done
        # Remove the aliases of unselected providers from shell config
        if [ -n "$existing_aliases" ]; then
            remove_aliases_from_shell "$existing_aliases"
        fi

        echo ""
        echo "✅ Cleanup complete!"
    else
        echo ""
        echo "⚠️  Keeping existing wrappers. They will remain available but may have outdated API keys."
    fi
}

# Helper function to remove specific aliases from shell config
remove_aliases_from_shell() {
    local aliases_to_remove="$1"
    local rc_file=$(detect_shell_rc)

    if [ -z "$rc_file" ] || [ ! -f "$rc_file" ]; then
        return
    fi

    # Create temp file
    local tmp_file="$rc_file.tmp"

    # Copy lines that don't contain the aliases to remove
    > "$tmp_file"
    while IFS= read -r line || [ -n "$line" ]; do
        local should_include=true
        for alias in $aliases_to_remove; do
            if echo "$line" | grep -q "alias $alias="; then
                should_include=false
                break
            fi
        done
        if [ "$should_include" = true ]; then
            echo "$line" >> "$tmp_file"
        fi
    done < "$rc_file"

    mv "$tmp_file" "$rc_file"
}

# Clean up orphaned wrappers from previous installs (providers/models no longer in config)
cleanup_orphaned_wrappers() {
    if [ ! -f "$CONFIG_LOADER" ]; then
        return
    fi

    local orphans
    orphans=$(node "$CONFIG_LOADER" find-orphans 2>/dev/null)

    # Check if orphans is empty array or null
    if [ -z "$orphans" ] || [ "$orphans" = "[]" ] || [ "$orphans" = "null" ]; then
        return
    fi

    echo ""
    echo "Found orphaned installations from previous versions:"
    echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => '  - ' + i.alias + ' (' + i.provider + '/' + i.model_id + ')').join('\n')" 2>/dev/null || true
    echo ""

    read -p "Remove orphaned installations? (y/N): " orphan_choice
    if [ "$orphan_choice" = "y" ] || [ "$orphan_choice" = "Y" ]; then
        # Remove wrapper files
        local wrapper_paths
        wrapper_paths=$(echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.wrapper_path).join('\n')" 2>/dev/null) || true
        while IFS= read -r wpath; do
            if [ -n "$wpath" ] && [ -f "$wpath" ]; then
                rm -f "$wpath" && echo "  Removed wrapper: $wpath"
            fi
        done <<< "$wrapper_paths"

        # Remove config directories
        local config_dirs
        config_dirs=$(echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.config_dir).join('\n')" 2>/dev/null) || true
        while IFS= read -r cpath; do
            if [ -n "$cpath" ] && [ -d "$cpath" ]; then
                rm -rf "$cpath" && echo "  Removed config: $cpath"
            fi
        done <<< "$config_dirs"

        # Remove aliases
        local orphan_aliases
        orphan_aliases=$(echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.alias).filter(Boolean).join(' ')" 2>/dev/null) || true
        if [ -n "$orphan_aliases" ]; then
            remove_aliases_from_shell $orphan_aliases
        fi

        # Remove from state
        local state_entries
        state_entries=$(echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.provider + ' ' + i.model_id).join('\n')" 2>/dev/null) || true
        while IFS= read -r entry; do
            local provider model
            provider=$(echo "$entry" | cut -d' ' -f1)
            model=$(echo "$entry" | cut -d' ' -f2-)
            if [ -n "$provider" ] && [ -n "$model" ]; then
                node "$CONFIG_LOADER" remove-wrapper "$provider" "$model" 2>/dev/null || true
            fi
        done <<< "$state_entries"

        echo ""
        echo "✅ Orphaned installations cleaned up."
    fi
}

# Configure advanced environment variables for a provider (interactive menu)
# Usage: configure_advanced_options <provider> <"model1 model2..."> <display_name>
configure_advanced_options() {
    local provider="$1"
    local model_ids="$2"
    local display_name="$3"
    local first_model
    first_model=$(echo "$model_ids" | awk '{print $1}')

    echo ""
    read -p "Configure advanced options for $display_name? (y/N): " adv_choice
    [ "$adv_choice" != "y" ] && [ "$adv_choice" != "Y" ] && return

    # Read current custom env values from state.json
    local custom_json
    custom_json=$(node "$CONFIG_LOADER" get-custom-env "$provider" "$first_model" 2>/dev/null) || custom_json="{}"

    local telemetry_state auto_update_state max_tokens_val bash_timeout_val
    telemetry_state=$(echo "$custom_json" | node -p "var d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));d.DISABLE_TELEMETRY==='1'?'ON':'OFF'" 2>/dev/null) || telemetry_state="OFF"
    auto_update_state=$(echo "$custom_json" | node -p "var d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));d.CLAUDE_CODE_DISABLE_AUTO_UPDATES==='1'?'ON':'OFF'" 2>/dev/null) || auto_update_state="OFF"
    max_tokens_val=$(echo "$custom_json" | node -p "var d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));d.CLAUDE_CODE_MAX_OUTPUT_TOKENS||'default'" 2>/dev/null) || max_tokens_val="default"
    bash_timeout_val=$(echo "$custom_json" | node -p "var d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));d.BASH_DEFAULT_TIMEOUT_MS||'default'" 2>/dev/null) || bash_timeout_val="default"

    while true; do
        echo ""
        echo "── Advanced Options: $display_name ──────────────────────────"
        echo "1) Disable telemetry/tracking    [$telemetry_state]"
        echo "2) Disable auto-updates          [$auto_update_state]"
        echo "3) Max output tokens             [$max_tokens_val]"
        echo "4) Bash command timeout (ms)     [$bash_timeout_val]"
        echo "5) Done"
        read -p "Choice (1-5): " adv_opt

        case "$adv_opt" in
            1)
                if [ "$telemetry_state" = "OFF" ]; then
                    telemetry_state="ON"
                else
                    telemetry_state="OFF"
                fi
                ;;
            2)
                if [ "$auto_update_state" = "OFF" ]; then
                    auto_update_state="ON"
                else
                    auto_update_state="OFF"
                fi
                ;;
            3)
                read -p "Max output tokens (e.g. 32000, max 64000; Enter=clear): " tok_input
                if [ -n "$tok_input" ]; then
                    max_tokens_val="$tok_input"
                else
                    max_tokens_val="default"
                fi
                ;;
            4)
                read -p "Bash timeout in ms (e.g. 30000; Enter=clear): " timeout_input
                if [ -n "$timeout_input" ]; then
                    bash_timeout_val="$timeout_input"
                else
                    bash_timeout_val="default"
                fi
                ;;
            5)
                break
                ;;
        esac
    done

    # Save settings to all model IDs for this provider
    for model_id in $model_ids; do
        # Telemetry: sets DISABLE_TELEMETRY + DISABLE_ERROR_REPORTING together
        if [ "$telemetry_state" = "ON" ]; then
            node "$CONFIG_LOADER" set-custom-env "$provider" "$model_id" DISABLE_TELEMETRY 1 2>/dev/null || true
            node "$CONFIG_LOADER" set-custom-env "$provider" "$model_id" DISABLE_ERROR_REPORTING 1 2>/dev/null || true
        else
            node "$CONFIG_LOADER" remove-custom-env "$provider" "$model_id" DISABLE_TELEMETRY 2>/dev/null || true
            node "$CONFIG_LOADER" remove-custom-env "$provider" "$model_id" DISABLE_ERROR_REPORTING 2>/dev/null || true
        fi

        # Auto-updates
        if [ "$auto_update_state" = "ON" ]; then
            node "$CONFIG_LOADER" set-custom-env "$provider" "$model_id" CLAUDE_CODE_DISABLE_AUTO_UPDATES 1 2>/dev/null || true
        else
            node "$CONFIG_LOADER" remove-custom-env "$provider" "$model_id" CLAUDE_CODE_DISABLE_AUTO_UPDATES 2>/dev/null || true
        fi

        # Max output tokens
        if [ "$max_tokens_val" != "default" ]; then
            node "$CONFIG_LOADER" set-custom-env "$provider" "$model_id" CLAUDE_CODE_MAX_OUTPUT_TOKENS "$max_tokens_val" 2>/dev/null || true
        else
            node "$CONFIG_LOADER" remove-custom-env "$provider" "$model_id" CLAUDE_CODE_MAX_OUTPUT_TOKENS 2>/dev/null || true
        fi

        # Bash timeout
        if [ "$bash_timeout_val" != "default" ]; then
            node "$CONFIG_LOADER" set-custom-env "$provider" "$model_id" BASH_DEFAULT_TIMEOUT_MS "$bash_timeout_val" 2>/dev/null || true
        else
            node "$CONFIG_LOADER" remove-custom-env "$provider" "$model_id" BASH_DEFAULT_TIMEOUT_MS 2>/dev/null || true
        fi
    done

    echo "✅ Advanced options saved for $display_name."
}

# Create shell aliases
create_shell_aliases() {
    local rc_file=$(detect_shell_rc)

    if [ -z "$rc_file" ] || [ ! -f "$rc_file" ]; then
        echo "⚠️  Could not detect shell rc file, skipping aliases"
        return
    fi

    # Derive alias/wrapper pairs from config (single source of truth)
    local aliases=() wrappers=()
    if [ -f "$CONFIG_LOADER" ]; then
        while IFS=$'\t' read -r _prov _model wrapper alias _cfg _url; do
            [ -n "$alias" ] || continue
            aliases+=("$alias")
            wrappers+=("$wrapper")
        done < <(node "$CONFIG_LOADER" list-models 2>/dev/null)
    fi
    if [ ${#aliases[@]} -eq 0 ]; then
        echo "⚠️  No aliases found in config, skipping"
        return
    fi

    # Remove old aliases if they exist (match both bash "alias x=" and cshrc "alias x ")
    if grep -q "# Claude Code Model Switcher Aliases" "$rc_file" 2>/dev/null; then
        local grep_args=("-v" "-e" "# Claude Code Model Switcher Aliases")
        for a in "${aliases[@]}"; do
            grep_args+=("-e" "alias $a=")
            grep_args+=("-e" "alias $a ")
        done
        grep "${grep_args[@]}" "$rc_file" > "$rc_file.tmp"
        mv "$rc_file.tmp" "$rc_file"
    fi

    # Add aliases based on shell type
    {
        echo ""
        echo "# Claude Code Model Switcher Aliases"
        if [[ "$rc_file" == *".cshrc" ]]; then
            for i in "${!aliases[@]}"; do
                echo "alias ${aliases[$i]} '${wrappers[$i]}'"
            done
        else
            for i in "${!aliases[@]}"; do
                echo "alias ${aliases[$i]}='${wrappers[$i]}'"
            done
        fi
    } >> "$rc_file"

    echo "✅ Added aliases to $rc_file"
}

# Check Claude Code availability
check_claude_installation() {
    echo "🔍 Checking Claude Code installation..."
    
    if command -v claude &> /dev/null; then
        echo "✅ Claude Code found at: $(which claude)"
        return 0
    else
        echo "⚠️  Claude Code not found in PATH"
        echo ""
        echo "Options:"
        echo "1. If Claude Code is installed elsewhere, add it to PATH first"
        echo "2. Install Claude Code from: https://www.anthropic.com/claude-code"
        echo "3. Continue anyway (wrappers will be created but won't work until claude is available)"
        echo ""
        read -p "Continue with installation? (y/n): " continue_choice
        if [[ "$continue_choice" != "y" && "$continue_choice" != "Y" ]]; then
            echo "Installation cancelled."
            exit 1
        fi
        return 1
    fi
}

# Main installation
main() {
    echo "🔧 Multi-Provider Claude Installer"
    echo "========================================"
    echo ""
    echo "This installer:"
    echo "  • Does NOT require sudo/root access"
    echo "  • Installs to: $USER_BIN_DIR"
    echo "  • Works on Unix/Linux servers"
    echo ""
    
    # Check Claude Code
    check_claude_installation
    
    # Setup user bin directory
    setup_user_bin

    # Clean up old installations from different locations
    cleanup_old_wrappers

    # Check if providers.yaml needs updating
    if [ -f "$CONFIG_LOADER" ]; then
        local config_status
        config_status=$(node "$CONFIG_LOADER" check-config-version 2>/dev/null)
        local needs_update
        needs_update=$(echo "$config_status" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).needsUpdate" 2>/dev/null) || true
        if [ "$needs_update" = "true" ]; then
            echo ""
            echo "⚠️  Your providers.yaml is outdated (new providers/models available)."
            echo "1) Update providers.yaml (API keys in state.json are preserved)"
            echo "2) Keep current"
            read -p "Choice (1-2): " yaml_choice
            if [ "$yaml_choice" = "1" ]; then
                node "$CONFIG_LOADER" update-config 2>/dev/null
                echo "✅ providers.yaml updated (backup saved as .bak)"
            fi
        fi
    fi

    # Check if already installed
    if [ -f "$USER_BIN_DIR/claude-glm" ] || [ -f "$USER_BIN_DIR/claude-glm-fast" ] || [ -f "$USER_BIN_DIR/ccm" ] || [ -f "$USER_BIN_DIR/ccd" ]; then
        echo ""
        echo "✅ Existing installation detected!"

        # Check for orphaned installations from previous versions
        cleanup_orphaned_wrappers
        echo "1) Update models only (keep API keys)"
        echo "2) Update API key only"
        echo "3) Reinstall everything"
        echo "4) Cancel"
        read -p "Choice (1-4): " update_choice

        case "$update_choice" in
            1)
                # Update models only - extract existing API keys from wrappers
                echo "🔄 Updating models (preserving API keys)..."

                # Extract API keys from existing wrappers
                if [ -f "$USER_BIN_DIR/claude-glm" ]; then
                    ZAI_API_KEY=$(grep "ANTHROPIC_AUTH_TOKEN=" "$USER_BIN_DIR/claude-glm" | sed 's/export ANTHROPIC_AUTH_TOKEN="//; s/"$//')
                fi
                if [ -f "$USER_BIN_DIR/claude-glm-fast" ]; then
                    ZAI_API_KEY=${ZAI_API_KEY:-$(grep "ANTHROPIC_AUTH_TOKEN=" "$USER_BIN_DIR/claude-glm-fast" | sed 's/export ANTHROPIC_AUTH_TOKEN="//; s/"$//')}
                fi
                if [ -f "$USER_BIN_DIR/ccm" ]; then
                    MINIMAX_API_KEY=$(grep "ANTHROPIC_AUTH_TOKEN=" "$USER_BIN_DIR/ccm" | sed 's/export ANTHROPIC_AUTH_TOKEN="//; s/"$//')
                fi
                if [ -f "$USER_BIN_DIR/ccd" ]; then
                    DEEPSEEK_API_KEY=$(grep "ANTHROPIC_AUTH_TOKEN=" "$USER_BIN_DIR/ccd" | sed 's/export ANTHROPIC_AUTH_TOKEN="//; s/"$//')
                fi

                # Offer advanced options before regenerating wrappers
                if [ -f "$CONFIG_LOADER" ]; then
                    if [ -n "$ZAI_API_KEY" ]; then
                        configure_advanced_options "glm" "glm-51 glm-52 glm-standard glm-fast" "Z.AI GLM"
                    fi
                    if [ -n "$MINIMAX_API_KEY" ]; then
                        configure_advanced_options "minimax" "default" "MiniMax"
                    fi
                    if [ -n "$DEEPSEEK_API_KEY" ]; then
                        configure_advanced_options "deepseek" "default" "DeepSeek"
                    fi
                fi

                # Regenerate wrappers with new models
                if [ -n "$ZAI_API_KEY" ]; then
                    create_wrapper_for "glm" "glm-51" "$ZAI_API_KEY"
                    create_wrapper_for "glm" "glm-52" "$ZAI_API_KEY"
                    create_wrapper_for "glm" "glm-standard" "$ZAI_API_KEY"
                    create_wrapper_for "glm" "glm-fast" "$ZAI_API_KEY"
                    echo "✅ GLM models updated (MAX/MAX-5.2/Standard/Fast)!"
                fi
                if [ -n "$MINIMAX_API_KEY" ]; then
                    create_wrapper_for "minimax" "default" "$MINIMAX_API_KEY"
                    echo "✅ MiniMax wrapper updated!"
                fi
                if [ -n "$DEEPSEEK_API_KEY" ]; then
                    create_wrapper_for "deepseek" "default" "$DEEPSEEK_API_KEY"
                    echo "✅ DeepSeek wrapper updated!"
                fi

                echo ""
                echo "🎉 Models updated! Your API keys were preserved."
                exit 0
                ;;
            2)
                echo "Choose provider to update:"
                echo "1) Z.AI GLM (MAX/Standard/Fast)"
                echo "2) MiniMax (MiniMax-M2)"
                echo "3) DeepSeek (deepseek-chat)"
                read -p "Provider (1-3): " provider_choice

                if [ "$provider_choice" = "1" ]; then
                    read -p "Enter your Z.AI API key: " input_key
                    if [ -n "$input_key" ]; then
                        ZAI_API_KEY="$input_key"
                        create_wrapper_for "glm" "glm-51" "$ZAI_API_KEY"
                        create_wrapper_for "glm" "glm-52" "$ZAI_API_KEY"
                        create_wrapper_for "glm" "glm-standard" "$ZAI_API_KEY"
                        create_wrapper_for "glm" "glm-fast" "$ZAI_API_KEY"
                        echo "✅ GLM API key updated!"
                    fi
                elif [ "$provider_choice" = "2" ]; then
                    read -p "Enter your MiniMax API key: " input_key
                    if [ -n "$input_key" ]; then
                        MINIMAX_API_KEY="$input_key"
                        create_wrapper_for "minimax" "default" "$MINIMAX_API_KEY"
                        echo "✅ MiniMax API key updated!"
                    fi
                elif [ "$provider_choice" = "3" ]; then
                    read -p "Enter your DeepSeek API key: " input_key
                    if [ -n "$input_key" ]; then
                        DEEPSEEK_API_KEY="$input_key"
                        create_wrapper_for "deepseek" "default" "$DEEPSEEK_API_KEY"
                        echo "✅ DeepSeek API key updated!"
                    fi
                fi
                exit 0
                ;;
            3)
                echo "Reinstalling..."
                ;;
            *)
                exit 0
                ;;
        esac
    fi
    
    # Get API keys
    echo ""
    echo "Choose which providers to install:"
    echo "1) Z.AI GLM only (MAX/Standard/Fast)"
    echo "2) MiniMax only (MiniMax-M2)"
    echo "3) DeepSeek only (deepseek-chat)"
    echo "4) All three providers"
    echo "5) Custom combination"
    read -p "Choice (1-5): " provider_choice
    
    if [ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo ""
        echo "Enter your Z.AI API key (from https://z.ai/manage-apikey/apikey-list)"
        read -p "Z.AI API Key: " input_key
        
        if [ -n "$input_key" ]; then
            ZAI_API_KEY="$input_key"
            echo "✅ Z.AI API key received (${#input_key} characters)"
        else
            echo "⚠️  No Z.AI API key provided. Add it manually later."
        fi
    fi
    
    if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo ""
        echo "Enter your MiniMax API key (from https://api.minimax.io)"
        read -p "MiniMax API Key: " input_key
        
        if [ -n "$input_key" ]; then
            MINIMAX_API_KEY="$input_key"
            echo "✅ MiniMax API key received (${#input_key} characters)"
        else
            echo "⚠️  No MiniMax API key provided. Add it manually later."
        fi
    fi
    
    if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo ""
        echo "Enter your DeepSeek API key (from https://api.deepseek.com)"
        read -p "DeepSeek API Key: " input_key
        
        if [ -n "$input_key" ]; then
            DEEPSEEK_API_KEY="$input_key"
            echo "✅ DeepSeek API key received (${#input_key} characters)"
        else
            echo "⚠️  No DeepSeek API key provided. Add it manually later."
        fi
    fi

    # Advanced options per selected provider (optional, interactive)
    if [ -f "$CONFIG_LOADER" ]; then
        if [ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
            if [ -n "$ZAI_API_KEY" ]; then
                configure_advanced_options "glm" "glm-51 glm-52 glm-standard glm-fast" "Z.AI GLM"
            fi
        fi
        if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
            if [ -n "$MINIMAX_API_KEY" ]; then
                configure_advanced_options "minimax" "default" "MiniMax"
            fi
        fi
        if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
            if [ -n "$DEEPSEEK_API_KEY" ]; then
                configure_advanced_options "deepseek" "default" "DeepSeek"
            fi
        fi
    fi

    # Determine which providers are selected and cleanup unselected ones
    local selected_providers=""
    if [ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        selected_providers="$selected_providers glm"
    fi
    if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        selected_providers="$selected_providers minimax"
    fi
    if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        selected_providers="$selected_providers deepseek"
    fi

    # Cleanup unselected providers (skip for option 1 "Update API key only")
    if [ "$provider_choice" != "1" ] && [ "$provider_choice" != "2" ] && [ "$provider_choice" != "3" ]; then
        cleanup_unselected_wrappers "$selected_providers"
    fi

    # Create wrappers
    if [ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        create_wrapper_for "glm" "glm-51" "$ZAI_API_KEY"
        create_wrapper_for "glm" "glm-52" "$ZAI_API_KEY"
        create_wrapper_for "glm" "glm-standard" "$ZAI_API_KEY"
        create_wrapper_for "glm" "glm-fast" "$ZAI_API_KEY"
    fi

    if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        create_wrapper_for "minimax" "default" "$MINIMAX_API_KEY"
    fi

    if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        create_wrapper_for "deepseek" "default" "$DEEPSEEK_API_KEY"
    fi
    
    create_shell_aliases
    
    # Final instructions
    local rc_file=$(detect_shell_rc)
    
    echo ""
    echo "✅ Installation complete!"
    echo ""
    echo "=========================================="
    echo "⚡ IMPORTANT: Run this command now:"
    echo "=========================================="
    echo ""
    echo "   source $rc_file"
    echo ""
    echo "=========================================="
    echo ""
    echo "📝 After sourcing, you can use:"
    echo ""
    echo "Commands:"
    
    if [ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "   claude-glm      - GLM-5.1 (latest)"
        echo "   claude-glm-52   - GLM-5.2 (MAX 5.2)"
        echo "   claude-glm-fast - GLM-4.5-Air (fast)"
    fi
    
    if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "   ccm             - MiniMax-M2 (with full config)"
    fi
    
    if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "   ccd             - DeepSeek (deepseek-chat)"
    fi
    
    echo ""
    echo "Aliases:"
    echo "   cc    - claude (regular Claude)"
    
    if [ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "   ccg   - claude-glm (GLM-5.1)"
        echo "   ccg52 - claude-glm-52 (GLM-5.2)"
        echo "   ccf   - claude-glm-fast"
    fi
    
    if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "   ccm   - MiniMax-M2"
    fi
    
    if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "   ccd   - DeepSeek"
    fi
    
    echo ""
    
    if [ "$ZAI_API_KEY" = "YOUR_ZAI_API_KEY_HERE" ] && ([ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]); then
        echo "⚠️  Don't forget to add your Z.AI API key to:"
        echo "   $USER_BIN_DIR/claude-glm"
        echo "   $USER_BIN_DIR/claude-glm-52"
        echo "   $USER_BIN_DIR/claude-glm-fast"
        echo ""
    fi
    
    if [ "$MINIMAX_API_KEY" = "YOUR_MINIMAX_API_KEY_HERE" ] && ([ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]); then
        echo "⚠️  Don't forget to add your MiniMax API key to:"
        echo "   $USER_BIN_DIR/ccm"
        echo ""
    fi
    
    if [ "$DEEPSEEK_API_KEY" = "YOUR_DEEPSEEK_API_KEY_HERE" ] && ([ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]); then
        echo "⚠️  Don't forget to add your DeepSeek API key to:"
        echo "   $USER_BIN_DIR/ccd"
        echo ""
    fi

    echo "📁 Installation location: $USER_BIN_DIR"
    
    if [ "$provider_choice" = "1" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "📁 GLM Config directories: ~/.claude-glm, ~/.claude-glm-52, ~/.claude-glm-standard, ~/.claude-glm-fast"
    fi
    
    if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "📁 MiniMax Config directory: ~/.claude-minimax"
    fi
    
    if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        echo "📁 DeepSeek Config directory: ~/.claude-deepseek"
    fi
}

# Error handler
handle_error() {
    local exit_code=$?
    local line_number=$1
    local bash_command="$2"

    # Capture the error details
    local error_msg="Command failed with exit code $exit_code"
    if [ -n "$bash_command" ]; then
        error_msg="$error_msg: $bash_command"
    fi

    local error_location="Line $line_number in install.sh"

    report_error "$error_msg" "$error_location" "$exit_code"

    # Give user time to read any final messages before stopping
    echo ""
    echo "Installation terminated due to error."
    echo "Press Enter to finish (window will remain open)..."
    read
    # Return to stop script execution without closing terminal
    return
}

# Test error functionality if requested
if [ "$TEST_ERROR" = true ]; then
    echo "🔍 TEST: Testing error reporting functionality..."
    echo ""

    # Show how script was invoked
    if [ -n "$CLAUDE_GLM_TEST_ERROR" ]; then
        echo "   (Invoked via environment variable)"
    fi
    echo ""

    # Create a test error
    local test_error_message="This is a test error to verify error reporting works correctly"
    local test_error_line="Test mode - no actual error"

    report_error "$test_error_message" "$test_error_line" "0"

    echo "✅ Test complete. If a browser window opened, error reporting is working!"
    echo ""
    echo "To run normal installation, use:"
    echo "   curl -fsSL https://raw.githubusercontent.com/bioodev/claude-code-providers-hub/main/install.sh | bash"
    echo ""
    echo "Press Enter to finish (window will remain open)..."
    read
    # Script ends naturally here - terminal stays open
    exit 0
fi

# Uninstall function
run_uninstall() {
    echo "🗑️  Uninstalling claude-code-providers-hub..."
    echo ""

    local wrappers_json=""
    if [ -f "$CONFIG_LOADER" ]; then
        wrappers_json=$(node "$CONFIG_LOADER" list-wrappers 2>/dev/null)
    fi

    # Derive wrapper files, config dirs and aliases from config (single source of truth).
    # Passthrough providers (empty base_url) are excluded from wrapper/config lists.
    local wrapper_files=()
    local config_dirs=()
    local all_aliases=""
    if [ -f "$CONFIG_LOADER" ]; then
        while IFS=$'\t' read -r _provider _model wrapper alias config_dir base_url; do
            if [ -n "$base_url" ]; then
                wrapper_files+=("$wrapper")
                config_dirs+=("$config_dir")
            fi
            [ -n "$alias" ] && all_aliases="$all_aliases $alias"
        done < <(node "$CONFIG_LOADER" list-models 2>/dev/null)
    fi

    # Remove wrapper scripts
    local removed_count=0
    for w in "${wrapper_files[@]}"; do
        local wpath="$USER_BIN_DIR/$w"
        if [ -f "$wpath" ]; then
            rm -f "$wpath"
            echo "  Removed wrapper: $wpath"
            ((removed_count++))
        fi
    done

    # Remove config directories (with confirmation - they contain chat history)
    echo ""
    read -p "Remove provider config directories (includes chat history)? (y/N): " rm_configs
    if [ "$rm_configs" = "y" ] || [ "$rm_configs" = "Y" ]; then
        for d in "${config_dirs[@]}"; do
            if [ -d "$d" ]; then
                rm -rf "$d"
                echo "  Removed config: $d"
            fi
        done
    else
        echo "  Keeping config directories."
    fi

    # Remove shell aliases
    remove_aliases_from_shell $all_aliases 2>/dev/null
    echo "  Removed shell aliases."

    # Check if ~/.local/bin has other files; if empty, remove PATH entry
    if [ -d "$USER_BIN_DIR" ]; then
        local file_count
        file_count=$(ls -1A "$USER_BIN_DIR" 2>/dev/null | wc -l)
        if [ "$file_count" -eq 0 ]; then
            echo ""
            echo "  $USER_BIN_DIR is now empty."
            read -p "Remove PATH entry from shell profile? (y/N): " rm_path
            if [ "$rm_path" = "y" ] || [ "$rm_path" = "Y" ]; then
                local rc_file=$(detect_shell_rc)
                if [ -n "$rc_file" ] && [ -f "$rc_file" ]; then
                    local tmp_file=$(mktemp)
                    grep -v "export PATH=\"\$PATH:$USER_BIN_DIR\"" "$rc_file" > "$tmp_file"
                    grep -v "setenv PATH \$PATH:$USER_BIN_DIR" "$tmp_file" > "$tmp_file.2"
                    mv "$tmp_file.2" "$rc_file"
                    rm -f "$tmp_file"
                    echo "  Removed PATH entry from $rc_file"
                fi
            fi
        fi
    fi

    # Remove ~/.claude-providers-hub/ (with confirmation)
    echo ""
    if [ -d "$PROVIDERS_HUB_DIR" ]; then
        read -p "Remove $PROVIDERS_HUB_DIR (providers.yaml, state.json)? (y/N): " rm_hub
        if [ "$rm_hub" = "y" ] || [ "$rm_hub" = "Y" ]; then
            rm -rf "$PROVIDERS_HUB_DIR"
            echo "  Removed: $PROVIDERS_HUB_DIR"
        else
            echo "  Keeping: $PROVIDERS_HUB_DIR"
        fi
    fi

    # Clear wrapper records in state
    if [ -f "$CONFIG_LOADER" ]; then
        node "$CONFIG_LOADER" clear-wrappers 2>/dev/null
    fi

    echo ""
    echo "✅ Uninstall complete."
}

# Handle --uninstall flag
if [ "$UNINSTALL" = true ]; then
    run_uninstall
    exit 0
fi

# Set up error handling
set -eE  # Exit on error, inherit ERR trap in functions
trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR

# Only run installation if not in test mode
if [ "$TEST_ERROR" != true ]; then
    # Run installation
    main "$@"
fi