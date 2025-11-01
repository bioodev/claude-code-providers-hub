#!/usr/bin/env node

/**
 * Preinstall script to prevent incorrect installation method
 * This package should ONLY be run with npx, not installed
 */

const fs = require('fs');
const path = require('path');

// Check if being installed via npx (including GitHub npx)
const isNpxInstall = process.env.npm_execpath && (
  process.env.npm_execpath.includes('npx') ||
  process.env.npm_execpath.includes('bin/npx')
);

// Check for temporary installation directory (_npx)
const isTempInstall = (
  process.env.npm_config_cache ||
  process.cwd().includes('_npx') ||
  process.cwd().includes('node_modules')
);

// Check if running from GitHub URL
const isGitHubInstall = process.argv[1] && (
  process.argv[1].includes('github:') ||
  process.argv[1].includes('raw.githubusercontent.com')
);

// Check for npx in process arguments
const hasNpxArg = process.argv.some(arg =>
  arg.includes('npx') || arg.includes('github:')
);

// Allow installation if any npx-related condition is met
const shouldAllowInstall = isNpxInstall || isTempInstall || isGitHubInstall || hasNpxArg;

// Block installation only for traditional npm install methods
if (!shouldAllowInstall) {
  console.error('\n❌ ERROR: Incorrect installation method!\n');
  console.error('This package is meant to be run directly with npx only.\n');
  console.error('✅ Correct usage:');
  console.error('   npx github:bioodev/claude-code-providers-hub');
  console.error('   npx github:bioodev/claude-code-providers-hub install');
  console.error('   npx claude-code-providers-hub\n');
  console.error('❌ Do NOT install this package:');
  console.error('   npm install claude-code-providers-hub');
  console.error('   npm i claude-code-providers-hub');
  console.error('   npm install -g claude-code-providers-hub\n');
  console.error('Always use npx to run the latest version!\n');

  process.exit(1);
}

// Log successful detection for debugging
if (isGitHubInstall) {
  console.log('✅ Detected GitHub npx installation');
} else if (isNpxInstall) {
  console.log('✅ Detected standard npx installation');
} else if (isTempInstall) {
  console.log('✅ Detected temporary installation');
}

// Allow installation to proceed
process.exit(0);
