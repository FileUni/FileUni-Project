#!/usr/bin/env node

const { ensureInstalled, envName, logPrefix } = require('./fileuni-common.cjs');

(async () => {
  if (process.env[envName('SKIP_DOWNLOAD')] === '1') {
    console.log(`${logPrefix()} Skipping asset download because ${envName('SKIP_DOWNLOAD')}=1`);
    return;
  }

  const { targetPath } = await ensureInstalled();
  console.log(`${logPrefix()} Installed asset: ${targetPath}`);
})().catch((error) => {
  console.error(`${logPrefix()} ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
