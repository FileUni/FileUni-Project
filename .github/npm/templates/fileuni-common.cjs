const fs = require('node:fs');
const fsp = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const AdmZip = require('adm-zip');

const manifest = require('./fileuni-manifest.json');
const packageRoot = path.resolve(__dirname, '..');
const binDir = path.join(packageRoot, 'bin');
const binaryBasePath = path.join(binDir, 'fileuni-bin');
const metadataPath = path.join(binDir, 'fileuni-target.json');

function normalizeLibc(input) {
  if (!input) {
    return null;
  }

  const value = String(input).trim().toLowerCase();
  if (value === 'gnu' || value === 'glibc') {
    return 'gnu';
  }
  if (value === 'musl') {
    return 'musl';
  }
  return null;
}

function detectLibc() {
  const envLibc = normalizeLibc(process.env.FILEUNI_NPM_LIBC || process.env.npm_config_fileuni_libc);
  if (envLibc) {
    return envLibc;
  }

  if (process.platform !== 'linux') {
    return null;
  }

  const report = process.report;
  if (report && typeof report.getReport === 'function') {
    const glibcVersion = report.getReport()?.header?.glibcVersionRuntime;
    if (glibcVersion) {
      return 'gnu';
    }
  }

  return 'musl';
}

function supportedTargets() {
  return manifest.targets.map((entry) => entry.target).sort();
}

function selectTarget() {
  const explicitTarget = process.env.FILEUNI_NPM_TARGET || process.env.npm_config_fileuni_target;
  if (explicitTarget) {
    const match = manifest.targets.find((entry) => entry.target === explicitTarget);
    if (!match) {
      throw new Error(`Unsupported FILEUNI_NPM_TARGET: ${explicitTarget}. Supported targets: ${supportedTargets().join(', ')}`);
    }
    return match;
  }

  const libc = detectLibc();
  const candidates = manifest.targets.filter((entry) => entry.os === process.platform && entry.arch === process.arch);
  if (candidates.length === 0) {
    throw new Error(`Unsupported platform: ${process.platform}/${process.arch}. Supported targets: ${supportedTargets().join(', ')}`);
  }

  if (process.platform !== 'linux') {
    return candidates[0];
  }

  const preferredLibc = libc || 'gnu';
  const exact = candidates.find((entry) => entry.libc === preferredLibc);
  if (exact) {
    return exact;
  }

  const fallbackGnu = candidates.find((entry) => entry.libc === 'gnu');
  if (fallbackGnu) {
    return fallbackGnu;
  }

  return candidates[0];
}

function binaryPathFor(entry) {
  return entry.binary_name.endsWith('.exe') ? `${binaryBasePath}.exe` : binaryBasePath;
}

async function readInstalledMetadata() {
  try {
    const raw = await fsp.readFile(metadataPath, 'utf-8');
    return JSON.parse(raw);
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return null;
    }
    throw error;
  }
}

async function writeInstalledMetadata(entry) {
  await fsp.writeFile(
    metadataPath,
    `${JSON.stringify({ target: entry.target, asset_name: entry.asset_name, release_tag: manifest.release_tag }, null, 2)}\n`,
    'utf-8',
  );
}

function releaseBaseUrl() {
  const customBaseUrl = process.env.FILEUNI_NPM_BASE_URL;
  if (customBaseUrl) {
    return customBaseUrl.replace(/\/$/, '');
  }
  return `https://github.com/${manifest.repository}`;
}

function releaseAssetUrl(entry) {
  return `${releaseBaseUrl()}/releases/download/${manifest.release_tag}/${entry.asset_name}`;
}

async function downloadAsset(entry, zipPath) {
  const response = await fetch(releaseAssetUrl(entry));
  if (!response.ok) {
    throw new Error(`Failed to download ${entry.asset_name}: HTTP ${response.status} ${response.statusText}`);
  }

  const buffer = Buffer.from(await response.arrayBuffer());
  await fsp.writeFile(zipPath, buffer);
}

async function installTarget(entry) {
  await fsp.mkdir(binDir, { recursive: true });
  const tmpDir = await fsp.mkdtemp(path.join(os.tmpdir(), 'fileuni-npm-'));
  const zipPath = path.join(tmpDir, 'fileuni.zip');

  try {
    await downloadAsset(entry, zipPath);

    const extractDir = path.join(tmpDir, 'extract');
    await fsp.mkdir(extractDir, { recursive: true });
    const archive = new AdmZip(zipPath);
    archive.extractAllTo(extractDir, true);

    const targetBinary = binaryPathFor(entry);
    const extractedBinary = path.join(extractDir, entry.binary_name);
    if (!fs.existsSync(extractedBinary)) {
      throw new Error(`Downloaded archive does not contain ${entry.binary_name}`);
    }

    await fsp.copyFile(extractedBinary, targetBinary);
    if (!entry.binary_name.endsWith('.exe')) {
      await fsp.chmod(targetBinary, 0o755);
    }
    await writeInstalledMetadata(entry);
    return targetBinary;
  } finally {
    await fsp.rm(tmpDir, { recursive: true, force: true });
  }
}

async function ensureInstalled() {
  const entry = selectTarget();
  const targetBinary = binaryPathFor(entry);
  const metadata = await readInstalledMetadata();

  if (metadata && metadata.target === entry.target && fs.existsSync(targetBinary)) {
    return targetBinary;
  }

  return installTarget(entry);
}

module.exports = {
  ensureInstalled,
  selectTarget,
  supportedTargets,
};
