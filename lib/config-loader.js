#!/usr/bin/env node

/**
 * Configuration loader for claude-code-providers-hub
 * Reads YAML config and outputs bash/PowerShell variable declarations
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

// Shipped YAML template — single source of truth, lives next to this file.
// User config (~/.claude-providers-hub/providers.yaml) is seeded from it on
// first run; editing the shipped file updates both seed and version checks.
const SHIPPED_YAML = path.join(__dirname, 'providers.yaml');

const CONFIG_DIR = path.join(os.homedir(), '.claude-providers-hub');
const PROVIDERS_YAML = path.join(CONFIG_DIR, 'providers.yaml');
const STATE_JSON = path.join(CONFIG_DIR, 'state.json');

/**
 * Read the shipped providers.yaml content (the canonical defaults).
 * Throws clearly if the file is missing — the package is incomplete without it.
 */
function getShippedYaml() {
  if (!fs.existsSync(SHIPPED_YAML)) {
    throw new Error(`Shipped config not found: ${SHIPPED_YAML}`);
  }
  return fs.readFileSync(SHIPPED_YAML, 'utf8').trim();
}

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
    fs.writeFileSync(PROVIDERS_YAML, getShippedYaml());
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
 * Expand home directory in path (Unix, for bash wrappers)
 */
function expandHomePath(filePath) {
  if (filePath && filePath.startsWith('~')) {
    return filePath.replace('~', os.homedir());
  }
  return filePath;
}

/**
 * Rewrite a path for a PowerShell wrapper: ~ -> $env:USERPROFILE, / -> \
 */
function expandHomePathPS(filePath) {
  if (!filePath) return filePath;
  const p = filePath.replace(/\//g, '\\');
  if (p === '~') return '$env:USERPROFILE';
  if (p.startsWith('~\\')) return '$env:USERPROFILE' + p.slice(1);
  return p;
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
 * List models as TSV: provider<TAB>model_id<TAB>wrapper_name<TAB>alias<TAB>config_dir<TAB>base_url
 * Bash/PowerShell-friendly (no jq needed). config_dir is expanded per-platform.
 * base_url is empty for passthrough providers (e.g. official claude) — those have
 * no managed wrapper/config and must be EXCLUDED from wrapper-file/config-dir
 * operations (uninstall/cleanup) to avoid touching the user's real binary, though
 * their alias IS still managed.
 * Optional provider filter limits to one provider.
 */
function listModels(providerFilter) {
  const config = loadConfig();
  const lines = [];
  for (const [provKey, prov] of Object.entries(config.providers || {})) {
    if (providerFilter && provKey !== providerFilter) continue;
    const baseUrl = prov.base_url || '';
    for (const [modelKey, model] of Object.entries(prov.models || {})) {
      const wrapper = model.wrapper_name || `claude-${provKey}`;
      const alias = model.alias || '';
      const cfg = expandHomePath(model.config_dir || prov.config_dir || '~/.claude-default');
      lines.push([provKey, modelKey, wrapper, alias, cfg, baseUrl].join('\t'));
    }
  }
  console.log(lines.join('\n'));
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
 * Get the wrapper filename for a provider/model (model.wrapper_name fallback)
 */
function getWrapperName(providerName, modelName) {
  const model = getModel(providerName, modelName);
  return model?.wrapper_name || `claude-${providerName}`;
}

/**
 * Get the shell alias for a provider/model (model.alias fallback to empty)
 */
function getAlias(providerName, modelName) {
  const model = getModel(providerName, modelName);
  return model?.alias || '';
}

/**
 * Get the expanded config directory for a provider/model
 */
function getConfigDir(providerName, modelName) {
  const provider = getProvider(providerName);
  const model = provider?.models?.[modelName];
  return expandHomePath(model?.config_dir || provider?.config_dir || '~/.claude-default');
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
  const shippedYaml = parseSimpleYaml(getShippedYaml());
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
  fs.writeFileSync(PROVIDERS_YAML, getShippedYaml());
}

/**
 * Get custom env vars for a provider/model stored in state.json
 */
function getCustomEnv(providerName, modelName) {
  const state = loadState();
  return state.custom_env?.[providerName]?.[modelName] || {};
}

/**
 * Set a custom env var for a provider/model in state.json
 */
function setCustomEnv(providerName, modelName, key, value) {
  const state = loadState();
  if (!state.custom_env) state.custom_env = {};
  if (!state.custom_env[providerName]) state.custom_env[providerName] = {};
  if (!state.custom_env[providerName][modelName]) state.custom_env[providerName][modelName] = {};
  state.custom_env[providerName][modelName][key] = value;
  saveState(state);
}

/**
 * Remove a custom env var for a provider/model from state.json
 */
function removeCustomEnv(providerName, modelName, key) {
  const state = loadState();
  if (!state.custom_env?.[providerName]?.[modelName]) return;
  delete state.custom_env[providerName][modelName][key];
  saveState(state);
}

/**
 * Get merged env vars: YAML model.env overridden by custom_env from state.json
 */
function getMergedEnv(providerName, modelName) {
  const model = getModel(providerName, modelName);
  const yamlEnv = model?.env || {};
  const customEnv = getCustomEnv(providerName, modelName);
  return { ...yamlEnv, ...customEnv };
}

/**
 * Build the settings.json document ({"env": {...}}) for a provider/model.
 * Uses JSON.stringify so values are properly escaped and consistently
 * typed (e.g. CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC is always a string).
 * Shared by the bash and PowerShell wrapper generators.
 */
function buildSettingsJson(baseUrl, apiKey, mergedEnv) {
  const env = {};
  if (baseUrl) env['ANTHROPIC_BASE_URL'] = baseUrl;
  env['ANTHROPIC_AUTH_TOKEN'] = apiKey;
  Object.entries(mergedEnv).forEach(([k, v]) => { env[k] = v; });
  return JSON.stringify({ env }, null, 2);
}

/**
 * Resolve display description for a provider/model
 */
function getModelDescription(providerName, modelName) {
  const provider = getProvider(providerName);
  const model = provider?.models?.[modelName];
  return model?.description || `${provider?.name || providerName} - ${modelName}`;
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
  const description = model.description || `${provider.name} - ${modelName}`;

  // Merge YAML env with custom env from state.json (custom overrides YAML)
  const merged = getMergedEnv(providerName, modelName);

  // Build export lines for additional env vars
  let envVars = '';
  Object.entries(merged).forEach(([key, value]) => {
    envVars += `export ${key}="${value}"\n`;
  });

  // settings.json content — built once, properly escaped/typed JSON
  const settingsJson = buildSettingsJson(baseUrl, apiKey, merged);

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
${settingsJson}
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
 * Get wrapper script content for PowerShell (mirrors getBashWrapperContent)
 */
function getPowerShellWrapperContent(providerName, modelName, apiKey) {
  const provider = getProvider(providerName);
  const model = provider?.models?.[modelName];

  if (!provider || !model) {
    console.error(`# Error: Provider ${providerName} or model ${modelName} not found`);
    process.exit(1);
  }

  const baseUrl = provider.base_url || '';
  const configDir = expandHomePathPS(model.config_dir || provider.config_dir || '~\\.claude-default');
  const description = model.description || `${provider.name} - ${modelName}`;

  // Merge YAML env with custom env from state.json (custom overrides YAML)
  const merged = getMergedEnv(providerName, modelName);

  // $env:<KEY> = "<value>" lines for the additional env vars
  let envVars = '';
  Object.entries(merged).forEach(([key, value]) => {
    envVars += `$env:${key} = "${value}"\n`;
  });

  // settings.json content — single-quoted here-string (no variable expansion)
  const settingsJson = buildSettingsJson(baseUrl, apiKey, merged);

  return `# ${description}
# Generated by claude-code-providers-hub

# Set environment variables
${baseUrl ? `$env:ANTHROPIC_BASE_URL = "${baseUrl}"\n` : ''}$env:ANTHROPIC_AUTH_TOKEN = "${apiKey}"
${envVars}
# Use custom config directory to avoid conflicts
$env:CLAUDE_HOME = "${configDir}"

# Create config directory if it doesn't exist
if (-not (Test-Path $env:CLAUDE_HOME)) {
    New-Item -ItemType Directory -Path $env:CLAUDE_HOME -Force | Out-Null
}

# Create/update settings file
$settingsJson = @'
${settingsJson}
'@
Set-Content -Path (Join-Path $env:CLAUDE_HOME "settings.json") -Value $settingsJson

# Launch Claude Code
Write-Host "🚀 Starting Claude Code with ${description}..."
Write-Host "📁 Config directory: $env:CLAUDE_HOME"
Write-Host ""

# Check if claude exists
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: 'claude' command not found!"
    Write-Host "Please ensure Claude Code is installed and in your PATH"
    exit 1
}

# Run the actual claude command
& claude $args
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
    case 'list-models':
      listModels(args[1]);
      break;
    case 'save-key':
      updateApiKey(args[1], args[2]);
      console.log(`Saved API key for ${args[1]}`);
      break;
    case 'wrapper-bash':
      console.log(getBashWrapperContent(args[1], args[2], args[3]));
      break;
    case 'wrapper-powershell':
      console.log(getPowerShellWrapperContent(args[1], args[2], args[3]));
      break;
    case 'get-default-model':
      getDefaultModelId(args[1]);
      break;
    case 'get-wrapper-name':
      console.log(getWrapperName(args[1], args[2]));
      break;
    case 'get-alias':
      console.log(getAlias(args[1], args[2]));
      break;
    case 'get-config-dir':
      console.log(getConfigDir(args[1], args[2]));
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
    case 'get-custom-env':
      if (!args[1] || !args[2]) {
        console.error('Usage: get-custom-env <provider> <model>');
        process.exit(1);
      }
      console.log(JSON.stringify(getCustomEnv(args[1], args[2]), null, 2));
      break;
    case 'set-custom-env':
      if (!args[1] || !args[2] || !args[3] || args[4] === undefined) {
        console.error('Usage: set-custom-env <provider> <model> <key> <value>');
        process.exit(1);
      }
      setCustomEnv(args[1], args[2], args[3], args[4]);
      console.log(`Saved ${args[3]}=${args[4]} for ${args[1]}/${args[2]}`);
      break;
    case 'remove-custom-env':
      if (!args[1] || !args[2] || !args[3]) {
        console.error('Usage: remove-custom-env <provider> <model> <key>');
        process.exit(1);
      }
      removeCustomEnv(args[1], args[2], args[3]);
      console.log(`Removed ${args[3]} for ${args[1]}/${args[2]}`);
      break;
    default:
      console.error(`
Usage: node config-loader.js <command> [args]

Commands:
  export-bash <provider> <model> [api-key]    Export bash variables
  export-powershell <provider> <model> [key]  Export PowerShell variables
  wrapper-bash <provider> <model> [api-key]   Generate bash wrapper content
  wrapper-powershell <provider> <model> [key] Generate PowerShell wrapper content
  get-default-model <provider>                Get the first model ID for a provider
  get-wrapper-name <provider> <model>         Get the wrapper filename
  get-alias <provider> <model>                Get the shell alias
  get-config-dir <provider> <model>           Get the expanded config directory
  list                                        List all providers
  list-models [provider]                      List models as TSV (provider/model/wrapper/alias/config_dir/base_url)
  save-key <provider> <api-key>               Save API key to state
  record-wrapper <provider> <model> <path> [config-dir] [alias]
                                              Record an installed wrapper
  remove-wrapper <provider> <model>           Remove a wrapper record
  list-wrappers                               List all recorded wrappers
  find-orphans                                Find wrappers no longer in config
  clear-wrappers                              Clear all wrapper records
  check-config-version                        Check if providers.yaml needs update
  update-config                               Update providers.yaml from defaults
  get-custom-env <provider> <model>           Get custom env vars (state.json)
  set-custom-env <provider> <model> <key> <value>
                                              Save a custom env var to state.json
  remove-custom-env <provider> <model> <key> Remove a custom env var from state.json
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
  expandHomePathPS,
  exportBashVars,
  exportPowerShellVars,
  listProviders,
  listModels,
  updateApiKey,
  getBashWrapperContent,
  getPowerShellWrapperContent,
  buildSettingsJson,
  getDefaultModelId,
  getWrapperName,
  getAlias,
  getConfigDir,
  recordInstalledWrapper,
  removeInstalledWrapper,
  getInstalledWrappers,
  getOrphanedWrappers,
  clearInstalledWrappers,
  checkConfigVersion,
  updateConfig,
  getCustomEnv,
  setCustomEnv,
  removeCustomEnv,
  getMergedEnv,
  getShippedYaml
};
