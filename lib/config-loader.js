#!/usr/bin/env node

/**
 * Configuration loader for claude-code-providers-hub
 * Reads YAML config and outputs bash/PowerShell variable declarations
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Default embedded YAML config (fallback if file doesn't exist)
const DEFAULT_YAML = `# Provider configurations for claude-code-providers-hub
# This file defines available providers and their models

config_version: "1.1"

providers:
  claude:
    name: "Anthropic Claude"
    description: "Official Anthropic Claude models"
    base_url: null
    config_dir: null
    models:
      default:
        name: "claude-sonnet-4"
        wrapper_name: "claude"
        alias: "cc"
        description: "Default Claude model"
        env:
          ANTHROPIC_DEFAULT_HAIKU_MODEL: "claude-haiku-4"

  glm:
    name: "Z.AI GLM"
    description: "Chinese AI models from Z.AI"
    base_url: "https://api.z.ai/api/anthropic"
    config_dir: "~/.claude-glm"
    models:
      glm-51:
        name: "GLM-5.1"
        wrapper_name: "claude-glm"
        alias: "ccg"
        description: "GLM-5.1 (latest)"
        env:
          ANTHROPIC_DEFAULT_OPUS_MODEL: "glm-5.1"
          ANTHROPIC_DEFAULT_SONNET_MODEL: "glm-5.1"
          ANTHROPIC_DEFAULT_HAIKU_MODEL: "glm-4.5-air"
      glm-fast:
        name: "GLM-4.5-Air"
        wrapper_name: "claude-glm-fast"
        alias: "ccf"
        description: "Fast GLM model"
        config_dir: "~/.claude-glm-fast"
        env:
          ANTHROPIC_DEFAULT_OPUS_MODEL: "glm-4.5-air"
          ANTHROPIC_DEFAULT_SONNET_MODEL: "glm-4.5-air"
          ANTHROPIC_DEFAULT_HAIKU_MODEL: "glm-4.5-air"

  deepseek:
    name: "DeepSeek"
    description: "Coding-optimized AI from DeepSeek"
    base_url: "https://api.deepseek.com/anthropic"
    config_dir: "~/.claude-deepseek"
    models:
      default:
        name: "deepseek-chat"
        wrapper_name: "ccd"
        alias: "ccd"
        description: "DeepSeek chat model"
        env:
          ANTHROPIC_DEFAULT_OPUS_MODEL: "deepseek-chat"
          ANTHROPIC_DEFAULT_SONNET_MODEL: "deepseek-chat"
          ANTHROPIC_DEFAULT_HAIKU_MODEL: "deepseek-chat"
          API_TIMEOUT_MS: "600000"
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"

  minimax:
    name: "MiniMax"
    description: "Advanced AI models from MiniMax"
    base_url: "https://api.minimax.io/anthropic"
    config_dir: "~/.claude-minimax"
    models:
      default:
        name: "MiniMax-M2"
        wrapper_name: "ccm"
        alias: "ccm"
        description: "MiniMax M2 model"
        env:
          ANTHROPIC_DEFAULT_SONNET_MODEL: "MiniMax-M2"
          ANTHROPIC_DEFAULT_OPUS_MODEL: "MiniMax-M2"
          ANTHROPIC_DEFAULT_HAIKU_MODEL: "MiniMax-M2"
          API_TIMEOUT_MS: "3000000"
          CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: "1"

# Default provider selection
default_provider: "claude"

# User's last selected provider/model (managed by installer)
state:
  last_provider: null
  last_model: null
`;

const CONFIG_DIR = path.join(os.homedir(), '.claude-providers-hub');
const PROVIDERS_YAML = path.join(CONFIG_DIR, 'providers.yaml');
const STATE_JSON = path.join(CONFIG_DIR, 'state.json');

/**
 * Simple YAML parser (minimal implementation)
 * Handles basic key-value and nested structures
 */
function parseSimpleYaml(yamlString) {
  const lines = yamlString.split('\n');
  const result = {};
  const stack = [{ obj: result, indent: -1 }];

  for (const line of lines) {
    // Skip comments and empty lines
    if (line.trim().startsWith('#') || !line.trim()) {
      continue;
    }

    const indent = line.search(/\S/);
    if (indent === -1) continue;

    const trimmed = line.trim();
    if (!trimmed) continue;

    // Pop stack to correct level (find parent with less indent)
    while (stack.length > 1 && indent <= stack[stack.length - 1].indent) {
      stack.pop();
    }

    const current = stack[stack.length - 1].obj;
    const colonIndex = trimmed.indexOf(':');

    if (colonIndex === -1) {
      // Line without colon - skip or handle as list item
      continue;
    }

    const key = trimmed.substring(0, colonIndex).trim();
    let value = trimmed.substring(colonIndex + 1).trim();

    // Remove inline comments from value
    const commentIndex = value.indexOf('#');
    if (commentIndex !== -1) {
      value = value.substring(0, commentIndex).trim();
    }

    if (value === '') {
      // Nested object - create empty object and push to stack
      current[key] = {};
      stack.push({ obj: current[key], indent: indent });
    } else if (value.startsWith('"') || value.startsWith("'")) {
      // String value
      current[key] = value.slice(1, -1);
    } else if (!isNaN(value)) {
      // Number
      current[key] = Number(value);
    } else if (value === 'true' || value === 'false') {
      // Boolean
      current[key] = value === 'true';
    } else if (value === 'null' || value === '~') {
      current[key] = null;
    } else {
      // Plain string
      current[key] = value;
    }
  }

  return result;
}

/**
 * Ensure config directory and default files exist
 */
function ensureConfig() {
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }

  if (!fs.existsSync(PROVIDERS_YAML)) {
    fs.writeFileSync(PROVIDERS_YAML, DEFAULT_YAML.trim());
  }

  if (!fs.existsSync(STATE_JSON)) {
    fs.writeFileSync(STATE_JSON, JSON.stringify({
      version: '1.0.0',
      api_keys: {},
      installed_wrappers: []
    }, null, 2));
  }
}

/**
 * Load provider configuration
 */
function loadConfig() {
  ensureConfig();
  const yamlContent = fs.readFileSync(PROVIDERS_YAML, 'utf8');
  return parseSimpleYaml(yamlContent);
}

/**
 * Load state
 */
function loadState() {
  ensureConfig();
  const content = fs.readFileSync(STATE_JSON, 'utf8');
  return JSON.parse(content);
}

/**
 * Save state
 */
function saveState(state) {
  ensureConfig();
  fs.writeFileSync(STATE_JSON, JSON.stringify(state, null, 2));
}

/**
 * Get provider configuration by name
 */
function getProvider(providerName) {
  const config = loadConfig();
  return config.providers?.[providerName];
}

/**
 * Get model configuration
 */
function getModel(providerName, modelName) {
  const provider = getProvider(providerName);
  return provider?.models?.[modelName];
}

/**
 * Expand home directory in path
 */
function expandHomePath(filePath) {
  if (filePath && filePath.startsWith('~')) {
    return filePath.replace('~', os.homedir());
  }
  return filePath;
}

/**
 * Export bash variable declarations for a provider/model
 */
function exportBashVars(providerName, modelName, apiKey) {
  const provider = getProvider(providerName);
  const model = provider?.models?.[modelName];

  if (!provider || !model) {
    console.error(`# Error: Provider ${providerName} or model ${modelName} not found`);
    process.exit(1);
  }

  // Build environment variables
  const vars = {};

  // Provider base config
  if (provider.base_url) {
    vars['BASE_URL'] = provider.base_url;
  }

  // Model config
  if (model.config_dir) {
    vars['CONFIG_DIR'] = expandHomePath(model.config_dir);
  } else if (provider.config_dir) {
    vars['CONFIG_DIR'] = expandHomePath(provider.config_dir);
  }

  if (model.name) {
    vars['MODEL_NAME'] = model.name;
  }

  // Model-specific env vars
  if (model.env) {
    Object.entries(model.env).forEach(([key, value]) => {
      vars[key] = value;
    });
  }

  // API key placeholder
  vars['API_KEY'] = apiKey || '';

  // Output bash export statements
  Object.entries(vars).forEach(([key, value]) => {
    console.log(`export ${key}="${value}"`);
  });
}

/**
 * Export PowerShell variable declarations
 */
function exportPowerShellVars(providerName, modelName, apiKey) {
  const provider = getProvider(providerName);
  const model = provider?.models?.[modelName];

  if (!provider || !model) {
    console.error(`# Error: Provider ${providerName} or model ${modelName} not found`);
    process.exit(1);
  }

  // Build environment variables (PowerShell style)
  const vars = {};

  if (provider.base_url) {
    vars['BaseUrl'] = provider.base_url;
  }

  if (model.config_dir) {
    vars['ConfigDir'] = expandHomePath(model.config_dir);
  } else if (provider.config_dir) {
    vars['ConfigDir'] = expandHomePath(provider.config_dir);
  }

  if (model.name) {
    vars['ModelName'] = model.name;
  }

  if (model.env) {
    Object.entries(model.env).forEach(([key, value]) => {
      vars[key] = value;
    });
  }

  vars['ApiKey'] = apiKey || '';

  // Output PowerShell variable declarations
  Object.entries(vars).forEach(([key, value]) => {
    console.log(`$${key} = "${value}"`);
  });
}

/**
 * List all available providers
 */
function listProviders() {
  const config = loadConfig();
  if (!config.providers) {
    console.error('No providers found in configuration');
    process.exit(1);
  }

  console.log('Available providers:');
  Object.entries(config.providers).forEach(([key, provider]) => {
    console.log(`  ${key}: ${provider.name} - ${provider.description || ''}`);
    if (provider.models) {
      Object.keys(provider.models).forEach(modelKey => {
        console.log(`    - ${modelKey}: ${provider.models[modelKey].name || modelKey}`);
      });
    }
  });
}

/**
 * Get the ID of the first model defined for a provider
 */
function getDefaultModelId(providerName) {
  const provider = getProvider(providerName);
  if (!provider || !provider.models) {
    console.error(`Provider ${providerName} not found`);
    process.exit(1);
  }
  const firstKey = Object.keys(provider.models)[0];
  if (!firstKey) {
    console.error(`No models found for provider ${providerName}`);
    process.exit(1);
  }
  console.log(firstKey);
}

/**
 * Update state with API key
 */
function updateApiKey(providerName, apiKey) {
  const state = loadState();
  if (!state.api_keys) state.api_keys = {};
  state.api_keys[providerName] = apiKey;
  saveState(state);
}

/**
 * Record an installed wrapper in state
 */
function recordInstalledWrapper(providerName, modelName, wrapperPath, configDir, aliasName) {
  const state = loadState();
  if (!state.installed_wrappers) {
    state.installed_wrappers = [];
  }
  // Replace existing entry for same provider+model, or add new
  const idx = state.installed_wrappers.findIndex(
    e => e.provider === providerName && e.model_id === modelName
  );
  const entry = {
    provider: providerName,
    model_id: modelName,
    wrapper_path: wrapperPath,
    config_dir: configDir,
    alias: aliasName || null,
    installed_at: new Date().toISOString(),
    install_version: '3.0.0'
  };
  if (idx >= 0) {
    state.installed_wrappers[idx] = entry;
  } else {
    state.installed_wrappers.push(entry);
  }
  saveState(state);
}

/**
 * Remove a recorded wrapper from state
 */
function removeInstalledWrapper(providerName, modelName) {
  const state = loadState();
  if (!state.installed_wrappers) return;
  state.installed_wrappers = state.installed_wrappers.filter(
    e => !(e.provider === providerName && e.model_id === modelName)
  );
  saveState(state);
}

/**
 * Get all recorded installed wrappers
 */
function getInstalledWrappers() {
  const state = loadState();
  return state.installed_wrappers || [];
}

/**
 * Get orphaned wrappers (installed but no longer in current config)
 */
function getOrphanedWrappers() {
  const config = loadConfig();
  const installed = getInstalledWrappers();
  if (installed.length === 0) return [];

  return installed.filter(entry => {
    const provider = config.providers?.[entry.provider];
    if (!provider) return true;
    if (!provider.models?.[entry.model_id]) return true;
    return false;
  });
}

/**
 * Clear all installed wrapper records
 */
function clearInstalledWrappers() {
  const state = loadState();
  state.installed_wrappers = [];
  saveState(state);
}

/**
 * Check if providers.yaml needs updating
 */
function checkConfigVersion() {
  const shippedYaml = parseSimpleYaml(DEFAULT_YAML);
  const shippedVersion = shippedYaml.config_version || '0';

  if (!fs.existsSync(PROVIDERS_YAML)) {
    return { current: null, shipped: shippedVersion, needsUpdate: false };
  }

  const userYaml = parseSimpleYaml(fs.readFileSync(PROVIDERS_YAML, 'utf8'));
  const currentVersion = userYaml.config_version || '0';

  return {
    current: currentVersion,
    shipped: shippedVersion,
    needsUpdate: currentVersion !== shippedVersion
  };
}

/**
 * Update providers.yaml from shipped defaults (with backup)
 */
function updateConfig() {
  if (fs.existsSync(PROVIDERS_YAML)) {
    fs.writeFileSync(PROVIDERS_YAML + '.bak', fs.readFileSync(PROVIDERS_YAML));
  }
  fs.writeFileSync(PROVIDERS_YAML, DEFAULT_YAML.trim());
}

/**
 * Get wrapper script content for bash
 */
function getBashWrapperContent(providerName, modelName, apiKey) {
  const provider = getProvider(providerName);
  const model = provider?.models?.[modelName];

  if (!provider || !model) {
    console.error(`# Error: Provider ${providerName} or model ${modelName} not found`);
    process.exit(1);
  }

  const baseUrl = provider.base_url || '';
  const configDir = expandHomePath(model.config_dir || provider.config_dir || '~/.claude-default');
  const modelNameValue = model.name || '';
  const description = model.description || `${provider.name} - ${modelName}`;

  // Build env vars
  let envVars = '';
  if (model.env) {
    Object.entries(model.env).forEach(([key, value]) => {
      envVars += `export ${key}="${value}"\n`;
    });
  }

  return `#!/bin/bash
# ${description}
# Generated by claude-code-providers-hub

# Set environment variables
${baseUrl ? `export ANTHROPIC_BASE_URL="${baseUrl}"` : ''}
export ANTHROPIC_AUTH_TOKEN="${apiKey}"
${envVars}
# Use custom config directory to avoid conflicts
export CLAUDE_HOME="${configDir}"

# Create config directory if it doesn't exist
mkdir -p "$CLAUDE_HOME"

# Create/update settings file
cat > "$CLAUDE_HOME/settings.json" << SETTINGS
{
  "env": {
    ${baseUrl ? `"ANTHROPIC_BASE_URL": "${baseUrl}",` : ''}
    "ANTHROPIC_AUTH_TOKEN": "${apiKey}",
${model.env ? Object.entries(model.env).map(([k, v]) => `    "${k}": "${v}"`).join(',\n') : ''}
  }
}
SETTINGS

# Launch Claude Code
echo "🚀 Starting Claude Code with ${description}..."
echo "📁 Config directory: $CLAUDE_HOME"
echo ""

# Check if claude exists
if ! command -v claude &> /dev/null; then
    echo "❌ Error: 'claude' command not found!"
    echo "Please ensure Claude Code is installed and in your PATH"
    exit 1
fi

# Run the actual claude command
claude "$@"
`;
}

/**
 * Main CLI handler
 */
function main() {
  const args = process.argv.slice(2);
  const command = args[0];

  switch (command) {
    case 'export-bash':
      exportBashVars(args[1], args[2], args[3]);
      break;
    case 'export-powershell':
      exportPowerShellVars(args[1], args[2], args[3]);
      break;
    case 'list':
      listProviders();
      break;
    case 'save-key':
      updateApiKey(args[1], args[2]);
      console.log(`Saved API key for ${args[1]}`);
      break;
    case 'wrapper-bash':
      console.log(getBashWrapperContent(args[1], args[2], args[3]));
      break;
    case 'get-default-model':
      getDefaultModelId(args[1]);
      break;
    case 'record-wrapper':
      if (!args[1] || !args[2] || !args[3]) {
        console.error('Usage: record-wrapper <provider> <model> <wrapper-path> [config-dir] [alias]');
        process.exit(1);
      }
      recordInstalledWrapper(args[1], args[2], args[3], args[4] || '', args[5] || '');
      break;
    case 'remove-wrapper':
      if (!args[1] || !args[2]) {
        console.error('Usage: remove-wrapper <provider> <model>');
        process.exit(1);
      }
      removeInstalledWrapper(args[1], args[2]);
      break;
    case 'list-wrappers':
      console.log(JSON.stringify(getInstalledWrappers(), null, 2));
      break;
    case 'find-orphans':
      console.log(JSON.stringify(getOrphanedWrappers(), null, 2));
      break;
    case 'clear-wrappers':
      clearInstalledWrappers();
      console.log('Cleared all installed wrapper records.');
      break;
    case 'check-config-version':
      console.log(JSON.stringify(checkConfigVersion(), null, 2));
      break;
    case 'update-config':
      updateConfig();
      console.log('Updated providers.yaml from shipped defaults (backup saved as .bak).');
      break;
    default:
      console.error(`
Usage: node config-loader.js <command> [args]

Commands:
  export-bash <provider> <model> [api-key]    Export bash variables
  export-powershell <provider> <model> [key]  Export PowerShell variables
  wrapper-bash <provider> <model> [api-key]   Generate bash wrapper content
  get-default-model <provider>                Get the first model ID for a provider
  list                                        List all providers
  save-key <provider> <api-key>               Save API key to state
  record-wrapper <provider> <model> <path> [config-dir] [alias]
                                              Record an installed wrapper
  remove-wrapper <provider> <model>           Remove a wrapper record
  list-wrappers                               List all recorded wrappers
  find-orphans                                Find wrappers no longer in config
  clear-wrappers                              Clear all wrapper records
  check-config-version                        Check if providers.yaml needs update
  update-config                               Update providers.yaml from defaults
      `);
      process.exit(1);
  }
}

if (require.main === module) {
  main();
}

module.exports = {
  loadConfig,
  loadState,
  saveState,
  getProvider,
  getModel,
  expandHomePath,
  exportBashVars,
  exportPowerShellVars,
  listProviders,
  updateApiKey,
  getBashWrapperContent,
  getDefaultModelId,
  recordInstalledWrapper,
  removeInstalledWrapper,
  getInstalledWrappers,
  getOrphanedWrappers,
  clearInstalledWrappers,
  checkConfigVersion,
  updateConfig
};
