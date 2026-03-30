#!/usr/bin/env node

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');
const fs = require('fs');
const process = require('process');

const platform = os.platform();
const rootDir = path.join(__dirname, '..');

// Package info
const packageInfo = {
  name: 'claude-code-providers-hub',
  version: '3.0.0',
  description: 'Multi-provider installer for Claude Code'
};

// CLI Arguments
const args = process.argv.slice(2);
const command = args[0];

// Help text
function showHelp() {
  console.log(`🔧 ${packageInfo.name} v${packageInfo.version}`);
  console.log('============================================================');
  console.log(`${packageInfo.description}`);
  console.log('');
  console.log('USAGE:');
  console.log('  npx github:bioodev/claude-code-providers-hub [command]');
  console.log('');
  console.log('COMMANDS:');
  console.log('  install     Run the interactive installer (default)');
  console.log('  uninstall   Remove all installed wrappers and configs');
  console.log('  --help      Show this help message');
  console.log('  --version   Show version information');
  console.log('  --list      Show available providers');
  console.log('');
  console.log('EXAMPLES:');
  console.log('  npx github:bioodev/claude-code-providers-hub install');
  console.log('  npx github:bioodev/claude-code-providers-hub --help');
  console.log('  npx github:bioodev/claude-code-providers-hub');
  console.log('');
  console.log('PROVIDERS:');
  console.log('  • GLM (Z.AI) - Chinese AI models');
  console.log('  • MiniMax - Advanced AI models');
  console.log('  • DeepSeek - Coding-optimized AI');
  console.log('  • Anthropic Claude - Original Claude');
}

// Version info
function showVersion() {
  console.log(`${packageInfo.name} v${packageInfo.version}`);
  console.log(`Platform: ${platform}`);
  console.log(`Node.js: ${process.version}`);
}

// List providers
function showProviders() {
  const { loadConfig, expandHomePath } = require('../lib/config-loader');
  const config = loadConfig();
  if (!config.providers) {
    console.log('No providers found in configuration.');
    return;
  }

  console.log('🤖 Available AI Providers:');
  console.log('==========================');
  console.log('');

  let idx = 1;
  Object.entries(config.providers).forEach(([key, provider]) => {
    const models = provider.models || {};
    const modelNames = Object.values(models).map(m => m.name).join(', ');
    const commands = Object.values(models).map(m => m.alias || m.wrapper_name).join(', ');
    const configDir = provider.config_dir ? expandHomePath(provider.config_dir) : '~/.claude/';

    console.log(`${idx}. ${provider.name}`);
    console.log(`   Models: ${modelNames}`);
    console.log(`   Commands: ${commands}`);
    console.log(`   Config: ${configDir}`);
    console.log('');
    idx++;
  });
}

// Run installer with provider selection
function runInstaller() {
  let scriptPath, command, args;

  console.log('🔧 Multi-Provider Claude Installer');
  console.log('===================================\n');
  console.log(`Detected OS: ${platform}\n`);

  if (platform === 'win32') {
    // Windows - run PowerShell installer
    console.log('🪟 Running Windows PowerShell installer...\n');
    scriptPath = path.join(rootDir, 'install.ps1');

    if (!fs.existsSync(scriptPath)) {
      console.error('❌ Error: install.ps1 not found!');
      process.exit(1);
    }

    command = 'powershell.exe';
    args = [
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', scriptPath
    ];

  } else if (platform === 'darwin' || platform === 'linux') {
    // macOS or Linux - run bash installer
    console.log(`🐧 Running Unix/Linux installer...\n`);
    scriptPath = path.join(rootDir, 'install.sh');

    if (!fs.existsSync(scriptPath)) {
      console.error('❌ Error: install.sh not found!');
      process.exit(1);
    }

    command = 'bash';
    args = [scriptPath];

  } else {
    console.error(`❌ Unsupported platform: ${platform}`);
    console.error('This installer supports Windows, macOS, and Linux.');
    process.exit(1);
  }

  // Spawn the installer process
  const installer = spawn(command, args, {
    stdio: 'inherit',
    cwd: rootDir
  });

  installer.on('error', (error) => {
    console.error(`❌ Failed to start installer: ${error.message}`);
    process.exit(1);
  });

  installer.on('close', (code) => {
    if (code !== 0) {
      console.error(`\n❌ Installer exited with code ${code}`);
      process.exit(code);
    }
    console.log('\n✅ Installation completed successfully!');
  });
}

// Run uninstaller
function runUninstaller() {
  let scriptPath, command, args;

  console.log('🗑️  Multi-Provider Claude Uninstaller');
  console.log('======================================\n');

  if (platform === 'win32') {
    scriptPath = path.join(rootDir, 'install.ps1');

    if (!fs.existsSync(scriptPath)) {
      console.error('❌ Error: install.ps1 not found!');
      process.exit(1);
    }

    command = 'powershell.exe';
    args = [
      '-NoProfile',
      '-ExecutionPolicy', 'Bypass',
      '-File', scriptPath,
      '-Uninstall'
    ];

  } else if (platform === 'darwin' || platform === 'linux') {
    scriptPath = path.join(rootDir, 'install.sh');

    if (!fs.existsSync(scriptPath)) {
      console.error('❌ Error: install.sh not found!');
      process.exit(1);
    }

    command = 'bash';
    args = [scriptPath, '--uninstall'];

  } else {
    console.error(`❌ Unsupported platform: ${platform}`);
    process.exit(1);
  }

  const uninstaller = spawn(command, args, {
    stdio: 'inherit',
    cwd: rootDir
  });

  uninstaller.on('error', (error) => {
    console.error(`❌ Failed to start uninstaller: ${error.message}`);
    process.exit(1);
  });

  uninstaller.on('close', (code) => {
    if (code !== 0) {
      console.error(`\n❌ Uninstaller exited with code ${code}`);
      process.exit(code);
    }
    console.log('\n✅ Uninstall completed successfully!');
  });
}

// Main CLI logic
function main() {
  // Handle different commands
  switch (command) {
    case '--help':
    case '-h':
    case 'help':
      showHelp();
      break;

    case '--version':
    case '-v':
    case 'version':
      showVersion();
      break;

    case '--list':
    case 'list':
    case 'providers':
      showProviders();
      break;

    case 'uninstall':
      runUninstaller();
      break;

    case 'install':
    case undefined:
    case null:
      // Default behavior - run installer
      runInstaller();
      break;

    default:
      console.log(`❌ Unknown command: ${command}`);
      console.log('Use --help for available commands.');
      process.exit(1);
  }
}

// Check if this is being run directly
if (require.main === module) {
  main();
}

module.exports = { showHelp, showVersion, showProviders, runInstaller, runUninstaller };
