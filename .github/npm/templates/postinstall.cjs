#!/usr/bin/env node

const { ensureInstalled } = require('./fileuni-common.cjs');

(async () => {
  if (process.env.FILEUNI_NPM_SKIP_DOWNLOAD === '1') {
    console.log('[fileuni] Skipping binary download because FILEUNI_NPM_SKIP_DOWNLOAD=1');
    return;
  }

  const binaryPath = await ensureInstalled();
  console.log(`[fileuni] Installed binary: ${binaryPath}`);
})().catch((error) => {
  console.error(`[fileuni] ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
