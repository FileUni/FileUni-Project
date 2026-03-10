#!/usr/bin/env node

const { spawn } = require('node:child_process');
const { ensureInstalled } = require('../scripts/fileuni-common.cjs');

(async () => {
  const binaryPath = await ensureInstalled();
  const child = spawn(binaryPath, process.argv.slice(2), { stdio: 'inherit' });

  child.on('exit', (code, signal) => {
    if (signal) {
      process.kill(process.pid, signal);
      return;
    }
    process.exit(code ?? 0);
  });
})();
