#!/usr/bin/env node

const { launchInstalled, logPrefix } = require('../scripts/fileuni-common.cjs');

launchInstalled(process.argv.slice(2)).then((code) => {
  process.exit(code ?? 0);
}).catch((error) => {
  console.error(`${logPrefix()} ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
});
