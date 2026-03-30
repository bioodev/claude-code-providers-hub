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

# Function to load provider variables from YAML config
load_provider_vars() {
    local provider="$1"
    local model="$2"
    local api_key="$3"

    # Try to use YAML config if available
    if [ -f "$CONFIG_LOADER" ]; then
        local output
        output=$(node "$CONFIG_LOADER" export-bash "$provider" "$model" "$api_key" 2>&1)
        if [ $? -eq 0 ]; then
            eval "$output"
            return 0
        fi
    fi

    # Fallback to hardcoded values
    case "$provider" in
        glm)
            case "$model" in
                glm-51)
                    BASE_URL="https://api.z.ai/api/anthropic"
                    MODEL_NAME="glm-5.1"
                    CONFIG_DIR="$HOME/.claude-glm"
                    ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.1"
                    ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.1"
                    ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
                    ;;
                glm-fast)
                    BASE_URL="https://api.z.ai/api/anthropic"
                    MODEL_NAME="glm-4.5-air"
                    CONFIG_DIR="$HOME/.claude-glm-fast"
                    ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.5-air"
                    ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.5-air"
                    ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
                    ;;
            esac
            ;;
        deepseek)
            BASE_URL="https://api.deepseek.com/anthropic"
            MODEL_NAME="deepseek-chat"
            CONFIG_DIR="$HOME/.claude-deepseek"
            ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-chat"
            ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-chat"
            ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-chat"
            API_TIMEOUT_MS="600000"
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
            ;;
        minimax)
            BASE_URL="https://api.minimax.io/anthropic"
            MODEL_NAME="MiniMax-M2"
            CONFIG_DIR="$HOME/.claude-minimax"
            ANTHROPIC_DEFAULT_SONNET_MODEL="MiniMax-M2"
            ANTHROPIC_DEFAULT_OPUS_MODEL="MiniMax-M2"
            ANTHROPIC_DEFAULT_HAIKU_MODEL="MiniMax-M2"
            API_TIMEOUT_MS="3000000"
            CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
            ;;
    esac

    # Set API key variable
    API_KEY="$api_key"
}

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

# Create the standard GLM wrapper (uses GLM-5.1 from YAML config)
create_claude_glm_wrapper() {
    local wrapper_path="$USER_BIN_DIR/claude-glm"

    # Try to use YAML config if available
    if [ -f "$CONFIG_LOADER" ]; then
        local model_id
        model_id=$(node "$CONFIG_LOADER" get-default-model "glm" 2>/dev/null)
        if [ -n "$model_id" ]; then
            node "$CONFIG_LOADER" wrapper-bash "glm" "$model_id" "$ZAI_API_KEY" > "$wrapper_path" 2>/dev/null
            if [ $? -eq 0 ]; then
                chmod +x "$wrapper_path"
                echo "✅ Installed claude-glm at $wrapper_path (from YAML config)"
                [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "glm" "$model_id" "$wrapper_path" "$HOME/.claude-glm" "ccg" 2>/dev/null
                return 0
            fi
        fi
    fi

    # Fallback to hardcoded template
    cat > "$wrapper_path" << EOF
#!/bin/bash
# Claude-GLM - Claude Code with Z.AI GLM-5.1 (Standard Model)

# Set Z.AI environment variables
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.1"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.1"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"

# Use custom config directory to avoid conflicts
export CLAUDE_HOME="\$HOME/.claude-glm"

# Create config directory if it doesn't exist
mkdir -p "\$CLAUDE_HOME"

# Create/update settings file with GLM configuration
cat > "\$CLAUDE_HOME/settings.json" << SETTINGS
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "$ZAI_API_KEY",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5.1",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5.1",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air"
  }
}
SETTINGS

# Launch Claude Code with custom config
echo "🚀 Starting Claude Code with GLM-5.1 (Standard Model)..."
echo "📁 Config directory: \$CLAUDE_HOME"
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "\$@"
EOF

    chmod +x "$wrapper_path"
    echo "✅ Installed claude-glm at $wrapper_path"
    [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "glm" "glm-51" "$wrapper_path" "$HOME/.claude-glm" "ccg" 2>/dev/null
}

# Create the fast GLM-4.5-Air wrapper
create_claude_glm_fast_wrapper() {
    local wrapper_path="$USER_BIN_DIR/claude-glm-fast"

    # Try to use YAML config if available
    if [ -f "$CONFIG_LOADER" ]; then
        node "$CONFIG_LOADER" wrapper-bash "glm" "glm-fast" "$ZAI_API_KEY" > "$wrapper_path" 2>/dev/null
        if [ $? -eq 0 ]; then
            chmod +x "$wrapper_path"
            echo "✅ Installed claude-glm-fast at $wrapper_path (from YAML config)"
            [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "glm" "glm-fast" "$wrapper_path" "$HOME/.claude-glm-fast" "ccf" 2>/dev/null
            return 0
        fi
    fi

    # Fallback to hardcoded template
    cat > "$wrapper_path" << EOF
#!/bin/bash
# Claude-GLM-Fast - Claude Code with Z.AI GLM-4.5-Air (Fast Model)

# Set Z.AI environment variables
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY"
export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-4.5-air"
export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.5-air"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"

# Use custom config directory to avoid conflicts
export CLAUDE_HOME="\$HOME/.claude-glm-fast"

# Create config directory if it doesn't exist
mkdir -p "\$CLAUDE_HOME"

# Create/update settings file with GLM-Air configuration
cat > "\$CLAUDE_HOME/settings.json" << SETTINGS
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.z.ai/api/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "$ZAI_API_KEY",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air"
  }
}
SETTINGS

# Launch Claude Code with custom config
echo "⚡ Starting Claude Code with GLM-4.5-Air (Fast Model)..."
echo "📁 Config directory: \$CLAUDE_HOME"
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "\$@"
EOF

    chmod +x "$wrapper_path"
    echo "✅ Installed claude-glm-fast at $wrapper_path"
    [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "glm" "glm-fast" "$wrapper_path" "$HOME/.claude-glm-fast" "ccf" 2>/dev/null
}

# Create the MiniMax wrapper
create_claude_minimax_wrapper() {
    local wrapper_path="$USER_BIN_DIR/ccm"

    # Try to use YAML config if available
    if [ -f "$CONFIG_LOADER" ]; then
        node "$CONFIG_LOADER" wrapper-bash "minimax" "default" "$MINIMAX_API_KEY" > "$wrapper_path" 2>/dev/null
        if [ $? -eq 0 ]; then
            chmod +x "$wrapper_path"
            echo "✅ Installed ccm at $wrapper_path (from YAML config)"
            [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "minimax" "default" "$wrapper_path" "$HOME/.claude-minimax" "ccm" 2>/dev/null
            return 0
        fi
    fi

    # Fallback to hardcoded template
    cat > "$wrapper_path" << EOF
#!/bin/bash
# CCM - Claude Code with MiniMax provider

# Set MiniMax environment variables
export ANTHROPIC_BASE_URL="https://api.minimax.io/anthropic"
export ANTHROPIC_AUTH_TOKEN="$MINIMAX_API_KEY"
export ANTHROPIC_DEFAULT_SONNET_MODEL="MiniMax-M2"
export ANTHROPIC_DEFAULT_OPUS_MODEL="MiniMax-M2"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="MiniMax-M2"
export API_TIMEOUT_MS="3000000"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"

# Use custom config directory to avoid conflicts
export CLAUDE_HOME="\$HOME/.claude-minimax"

# Create config directory if it doesn't exist
mkdir -p "\$CLAUDE_HOME"

# Create/update settings file with MiniMax configuration
cat > "\$CLAUDE_HOME/settings.json" << SETTINGS
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.minimax.io/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "$MINIMAX_API_KEY",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1,
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "MiniMax-M2",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "MiniMax-M2",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "MiniMax-M2"
  }
}
SETTINGS

# Launch Claude Code with custom config
echo "🚀 Starting Claude Code with MiniMax (M2 Model)..."
echo "📁 Config directory: \$CLAUDE_HOME"
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "\$@"
EOF

    chmod +x "$wrapper_path"
    echo "✅ Installed ccm at $wrapper_path"
    [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "minimax" "default" "$wrapper_path" "$HOME/.claude-minimax" "ccm" 2>/dev/null
}

# Create the DeepSeek wrapper
create_claude_deepseek_wrapper() {
    local wrapper_path="$USER_BIN_DIR/ccd"

    # Try to use YAML config if available
    if [ -f "$CONFIG_LOADER" ]; then
        node "$CONFIG_LOADER" wrapper-bash "deepseek" "default" "$DEEPSEEK_API_KEY" > "$wrapper_path" 2>/dev/null
        if [ $? -eq 0 ]; then
            chmod +x "$wrapper_path"
            echo "✅ Installed ccd at $wrapper_path (from YAML config)"
            [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "deepseek" "default" "$wrapper_path" "$HOME/.claude-deepseek" "ccd" 2>/dev/null
            return 0
        fi
    fi

    # Fallback to hardcoded template
    cat > "$wrapper_path" << EOF
#!/bin/bash
# CCD - Claude Code with DeepSeek provider

# Set DeepSeek environment variables
export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
export ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY"
export API_TIMEOUT_MS="600000"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"

# Use custom config directory to avoid conflicts
export CLAUDE_HOME="\$HOME/.claude-deepseek"

# Create config directory if it doesn't exist
mkdir -p "\$CLAUDE_HOME"

# Create/update settings file with DeepSeek configuration
cat > "\$CLAUDE_HOME/settings.json" << SETTINGS
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://api.deepseek.com/anthropic",
    "ANTHROPIC_AUTH_TOKEN": "$DEEPSEEK_API_KEY",
    "API_TIMEOUT_MS": "600000",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "deepseek-chat",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "deepseek-chat",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "deepseek-chat",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  }
}
SETTINGS

# Launch Claude Code with custom config
echo "🚀 Starting Claude Code with DeepSeek (deepseek-chat)..."
echo "📁 Config directory: \$CLAUDE_HOME"
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "\$@"
EOF

    chmod +x "$wrapper_path"
    echo "✅ Installed ccd at $wrapper_path"
    [ -f "$CONFIG_LOADER" ] && node "$CONFIG_LOADER" record-wrapper "deepseek" "default" "$wrapper_path" "$HOME/.claude-deepseek" "ccd" 2>/dev/null
}

# Clean up wrappers for providers not selected in this installation
cleanup_unselected_wrappers() {
    local selected_providers="$1"  # Space-separated list: "glm", "minimax", "deepseek"

    # Define all possible wrappers and their config directories
    local glm_wrappers="claude-glm claude-glm-fast"
    local glm_configs="$HOME/.claude-glm $HOME/.claude-glm-fast"
    local glm_aliases="ccg ccf"

    local minimax_wrappers="ccm"
    local minimax_configs="$HOME/.claude-minimax"
    local minimax_aliases="ccm"

    local deepseek_wrappers="ccd"
    local deepseek_configs="$HOME/.claude-deepseek"
    local deepseek_aliases="ccd"

    # Check which wrappers exist
    local existing_wrappers=""
    local existing_configs=""
    local existing_aliases_info=""

    # Check GLM wrappers
    if [[ ! " $selected_providers " =~ " glm " ]]; then
        for wrapper in $glm_wrappers; do
            if [ -f "$USER_BIN_DIR/$wrapper" ]; then
                existing_wrappers="$existing_wrappers $wrapper"
            fi
        done
        for config in $glm_configs; do
            if [ -d "$config" ]; then
                existing_configs="$existing_configs $config"
            fi
        done
    fi

    # Check MiniMax wrappers
    if [[ ! " $selected_providers " =~ " minimax " ]]; then
        for wrapper in $minimax_wrappers; do
            if [ -f "$USER_BIN_DIR/$wrapper" ]; then
                existing_wrappers="$existing_wrappers $wrapper"
            fi
        done
        for config in $minimax_configs; do
            if [ -d "$config" ]; then
                existing_configs="$existing_configs $config"
            fi
        done
    fi

    # Check DeepSeek wrappers
    if [[ ! " $selected_providers " =~ " deepseek " ]]; then
        for wrapper in $deepseek_wrappers; do
            if [ -f "$USER_BIN_DIR/$wrapper" ]; then
                existing_wrappers="$existing_wrappers $wrapper"
            fi
        done
        for config in $deepseek_configs; do
            if [ -d "$config" ]; then
                existing_configs="$existing_configs $config"
            fi
        done
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

        # Remove GLM
        if [[ ! " $selected_providers " =~ " glm " ]]; then
            for wrapper in $glm_wrappers; do
                if [ -f "$USER_BIN_DIR/$wrapper" ]; then
                    rm -f "$USER_BIN_DIR/$wrapper"
                    echo "   ✅ Removed: $wrapper"
                fi
            done
            for config in $glm_configs; do
                if [ -d "$config" ]; then
                    rm -rf "$config"
                    echo "   ✅ Removed: $config"
                fi
            done
            # Remove aliases from shell config
            remove_aliases_from_shell "$glm_aliases"
        fi

        # Remove MiniMax
        if [[ ! " $selected_providers " =~ " minimax " ]]; then
            for wrapper in $minimax_wrappers; do
                if [ -f "$USER_BIN_DIR/$wrapper" ]; then
                    rm -f "$USER_BIN_DIR/$wrapper"
                    echo "   ✅ Removed: $wrapper"
                fi
            done
            for config in $minimax_configs; do
                if [ -d "$config" ]; then
                    rm -rf "$config"
                    echo "   ✅ Removed: $config"
                fi
            done
            # Remove aliases from shell config
            remove_aliases_from_shell "$minimax_aliases"
        fi

        # Remove DeepSeek
        if [[ ! " $selected_providers " =~ " deepseek " ]]; then
            for wrapper in $deepseek_wrappers; do
                if [ -f "$USER_BIN_DIR/$wrapper" ]; then
                    rm -f "$USER_BIN_DIR/$wrapper"
                    echo "   ✅ Removed: $wrapper"
                fi
            done
            for config in $deepseek_configs; do
                if [ -d "$config" ]; then
                    rm -rf "$config"
                    echo "   ✅ Removed: $config"
                fi
            done
            # Remove aliases from shell config
            remove_aliases_from_shell "$deepseek_aliases"
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
    echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => '  - ' + i.alias + ' (' + i.provider + '/' + i.model_id + ')').join('\n')" 2>/dev/null
    echo ""

    read -p "Remove orphaned installations? (y/N): " orphan_choice
    if [ "$orphan_choice" = "y" ] || [ "$orphan_choice" = "Y" ]; then
        # Remove wrapper files
        echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.wrapper_path).join('\n')" 2>/dev/null | while read wpath; do
            [ -n "$wpath" ] && [ -f "$wpath" ] && rm -f "$wpath" && echo "  Removed wrapper: $wpath"
        done

        # Remove config directories
        echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.config_dir).join('\n')" 2>/dev/null | while read cpath; do
            [ -n "$cpath" ] && [ -d "$cpath" ] && rm -rf "$cpath" && echo "  Removed config: $cpath"
        done

        # Remove aliases
        local orphan_aliases
        orphan_aliases=$(echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.alias).filter(Boolean).join(' ')" 2>/dev/null)
        if [ -n "$orphan_aliases" ]; then
            remove_aliases_from_shell $orphan_aliases
        fi

        # Remove from state
        echo "$orphans" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).map(i => i.provider + ' ' + i.model_id).join('\n')" 2>/dev/null | while read provider model; do
            [ -n "$provider" ] && [ -n "$model" ] && node "$CONFIG_LOADER" remove-wrapper "$provider" "$model" 2>/dev/null
        done

        echo ""
        echo "✅ Orphaned installations cleaned up."
    fi
}

# Create shell aliases
create_shell_aliases() {
    local rc_file=$(detect_shell_rc)
    
    if [ -z "$rc_file" ] || [ ! -f "$rc_file" ]; then
        echo "⚠️  Could not detect shell rc file, skipping aliases"
        return
    fi
    
    # Remove old aliases if they exist
    if grep -q "# Claude Code Model Switcher Aliases" "$rc_file" 2>/dev/null; then
        # Use temp file for compatibility
        grep -v "# Claude Code Model Switcher Aliases" "$rc_file" | \
        grep -v "alias cc=" | \
        grep -v "alias ccg=" | \
        grep -v "alias ccf=" | \
        grep -v "alias ccm=" | \
        grep -v "alias ccd=" > "$rc_file.tmp"
        mv "$rc_file.tmp" "$rc_file"
    fi
    
    # Add aliases based on shell type
    if [[ "$rc_file" == *".cshrc" ]]; then
        cat >> "$rc_file" << 'EOF'

# Claude Code Model Switcher Aliases
alias cc 'claude'
alias ccg 'claude-glm'
alias ccf 'claude-glm-fast'
alias ccm 'ccm'
alias ccd 'ccd'
EOF
    else
        cat >> "$rc_file" << 'EOF'

# Claude Code Model Switcher Aliases
alias cc='claude'
alias ccg='claude-glm'
alias ccf='claude-glm-fast'
alias ccm='ccm'
alias ccd='ccd'
EOF
    fi
    
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
        needs_update=$(echo "$config_status" | node -p "JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).needsUpdate" 2>/dev/null)
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

                # Regenerate wrappers with new models
                if [ -n "$ZAI_API_KEY" ]; then
                    create_claude_glm_wrapper
                    create_claude_glm_fast_wrapper
                    echo "✅ GLM models updated to GLM-5.1!"
                fi
                if [ -n "$MINIMAX_API_KEY" ]; then
                    create_claude_minimax_wrapper
                    echo "✅ MiniMax wrapper updated!"
                fi
                if [ -n "$DEEPSEEK_API_KEY" ]; then
                    create_claude_deepseek_wrapper
                    echo "✅ DeepSeek wrapper updated!"
                fi

                echo ""
                echo "🎉 Models updated! Your API keys were preserved."
                exit 0
                ;;
            2)
                echo "Choose provider to update:"
                echo "1) Z.AI GLM (GLM-5.1, GLM-4.5-Air)"
                echo "2) MiniMax (MiniMax-M2)"
                echo "3) DeepSeek (deepseek-chat)"
                read -p "Provider (1-3): " provider_choice

                if [ "$provider_choice" = "1" ]; then
                    read -p "Enter your Z.AI API key: " input_key
                    if [ -n "$input_key" ]; then
                        ZAI_API_KEY="$input_key"
                        create_claude_glm_wrapper
                        create_claude_glm_fast_wrapper
                        echo "✅ GLM API key updated!"
                    fi
                elif [ "$provider_choice" = "2" ]; then
                    read -p "Enter your MiniMax API key: " input_key
                    if [ -n "$input_key" ]; then
                        MINIMAX_API_KEY="$input_key"
                        create_claude_minimax_wrapper
                        echo "✅ MiniMax API key updated!"
                    fi
                elif [ "$provider_choice" = "3" ]; then
                    read -p "Enter your DeepSeek API key: " input_key
                    if [ -n "$input_key" ]; then
                        DEEPSEEK_API_KEY="$input_key"
                        create_claude_deepseek_wrapper
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
    echo "1) Z.AI GLM only (GLM-5.1, GLM-4.5-Air)"
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
        create_claude_glm_wrapper
        create_claude_glm_fast_wrapper
    fi
    
    if [ "$provider_choice" = "2" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        create_claude_minimax_wrapper
    fi
    
    if [ "$provider_choice" = "3" ] || [ "$provider_choice" = "4" ] || [ "$provider_choice" = "5" ]; then
        create_claude_deepseek_wrapper
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
        echo "📁 GLM Config directories: ~/.claude-glm, ~/.claude-glm-fast"
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

    # Remove wrapper scripts
    local wrapper_files=("claude-glm" "claude-glm-fast" "ccm" "ccd")
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
    local config_dirs=("$HOME/.claude-glm" "$HOME/.claude-glm-fast" "$HOME/.claude-minimax" "$HOME/.claude-deepseek")
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
    local all_aliases="cc ccg ccf ccm ccd"
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