const fs = require('node:fs');
const fsp = require('node:fs/promises');
const os = require('node:os');
const path = require('node:path');
const { spawn } = require('node:child_process');
const AdmZip = require('adm-zip');

const manifest = require('./fileuni-manifest.json');
const packageRoot = path.resolve(__dirname, '..');
const binDir = path.join(packageRoot, 'bin');
const metadataPath = path.join(binDir, 'installed-target.json');

function logPrefix() {
  return `[${manifest.package.name}]`;
}

function packageDisplayName() {
  return manifest.package.display_name || manifest.package.name;
}

function envName(suffix) {
  return `${manifest.package.env_prefix}_${suffix}`;
}

function npmConfigName(suffix) {
  return `npm_config_${manifest.package.npm_config_prefix}_${suffix.toLowerCase()}`;
}

function envValue(suffix) {
  return process.env[envName(suffix)] || process.env[npmConfigName(suffix)] || null;
}

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
  const envLibc = normalizeLibc(envValue('LIBC'));
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
  const explicitTarget = envValue('TARGET');
  if (explicitTarget) {
    const match = manifest.targets.find((entry) => entry.target === explicitTarget);
    if (!match) {
      throw new Error(`Unsupported ${envName('TARGET')}: ${explicitTarget}. Supported targets: ${supportedTargets().join(', ')}`);
    }
    return match;
  }

  const libc = detectLibc();
  const candidates = manifest.targets.filter((entry) => entry.os === process.platform && entry.arch === process.arch);
  if (candidates.length === 0) {
    throw new Error(`Unsupported platform for ${packageDisplayName()}: ${process.platform}/${process.arch}. Supported targets: ${supportedTargets().join(', ')}`);
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

function targetInstallPath(entry) {
  return path.join(binDir, entry.installed_rel_path);
}

function targetExists(targetPath) {
  return fs.existsSync(targetPath);
}

async function readInstalledMetadata() {
  try {
    const raw = await fsp.readFile(metadataPath, { encoding: 'utf-8' });
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
  const customBaseUrl = envValue('BASE_URL');
  if (customBaseUrl) {
    return customBaseUrl.replace(/\/$/, '');
  }
  return `https://github.com/${manifest.repository}`;
}

function releaseAssetUrl(entry) {
  return `${releaseBaseUrl()}/releases/download/${manifest.release_tag}/${entry.asset_name}`;
}

async function downloadAsset(entry, downloadPath) {
  const response = await fetch(releaseAssetUrl(entry));
  if (!response.ok) {
    throw new Error(`Failed to download ${entry.asset_name}: HTTP ${response.status} ${response.statusText}`);
  }

  const buffer = Buffer.from(await response.arrayBuffer());
  await fsp.writeFile(downloadPath, buffer);
}

async function copyExtractedTarget(extractDir, entry, targetPath) {
  const extractedPath = path.join(extractDir, entry.installed_rel_path);
  if (!targetExists(extractedPath)) {
    throw new Error(`Downloaded archive does not contain ${entry.installed_rel_path}`);
  }

  await fsp.rm(targetPath, { recursive: true, force: true });
  await fsp.mkdir(path.dirname(targetPath), { recursive: true });

  const stat = await fsp.stat(extractedPath);
  if (stat.isDirectory()) {
    await fsp.cp(extractedPath, targetPath, { recursive: true, force: true });
    return;
  }

  await fsp.copyFile(extractedPath, targetPath);
}

async function installFromZip(entry, downloadPath, targetPath) {
  const tmpDir = await fsp.mkdtemp(path.join(os.tmpdir(), `${manifest.package.name}-`));

  try {
    const extractDir = path.join(tmpDir, 'extract');
    await fsp.mkdir(extractDir, { recursive: true });
    const archive = new AdmZip(downloadPath);
    archive.extractAllTo(extractDir, true);
    await copyExtractedTarget(extractDir, entry, targetPath);
  } finally {
    await fsp.rm(tmpDir, { recursive: true, force: true });
  }
}

async function installFromFile(entry, downloadPath, targetPath) {
  await fsp.rm(targetPath, { recursive: true, force: true });
  await fsp.mkdir(path.dirname(targetPath), { recursive: true });
  await fsp.copyFile(downloadPath, targetPath);
}

async function installTarget(entry) {
  await fsp.mkdir(binDir, { recursive: true });
  const tmpDir = await fsp.mkdtemp(path.join(os.tmpdir(), `${manifest.package.name}-download-`));
  const targetPath = targetInstallPath(entry);
  const downloadPath = path.join(tmpDir, entry.asset_name);

  try {
    await downloadAsset(entry, downloadPath);

    if (entry.asset_format === 'zip') {
      await installFromZip(entry, downloadPath, targetPath);
    } else if (entry.asset_format === 'file') {
      await installFromFile(entry, downloadPath, targetPath);
    } else {
      throw new Error(`Unsupported asset format: ${entry.asset_format}`);
    }

    if (entry.launch_strategy === 'exec' && targetExists(targetPath)) {
      const targetStat = await fsp.stat(targetPath);
      if (targetStat.isFile()) {
        await fsp.chmod(targetPath, 0o755);
      }
    }

    await writeInstalledMetadata(entry);
    return { entry, targetPath };
  } finally {
    await fsp.rm(tmpDir, { recursive: true, force: true });
  }
}

async function ensureInstalled() {
  const entry = selectTarget();
  const targetPath = targetInstallPath(entry);
  const metadata = await readInstalledMetadata();

  if (metadata && metadata.target === entry.target && targetExists(targetPath)) {
    return { entry, targetPath };
  }

  return installTarget(entry);
}

function waitForChild(child) {
  return new Promise((resolve, reject) => {
    child.on('error', reject);
    child.on('exit', (code, signal) => {
      if (signal) {
        process.kill(process.pid, signal);
        return;
      }
      resolve(code ?? 0);
    });
  });
}

async function launchInstalled(args = []) {
  const { entry, targetPath } = await ensureInstalled();

  if (entry.launch_strategy === 'open') {
    if (process.platform !== 'darwin') {
      throw new Error(`launch_strategy=open is only supported on macOS for ${packageDisplayName()}`);
    }

    const openArgs = ['-n', targetPath];
    if (args.length > 0) {
      openArgs.push('--args', ...args);
    }

    const child = spawn('open', openArgs, { stdio: 'inherit' });
    return waitForChild(child);
  }

  if (entry.launch_strategy === 'exec') {
    const child = spawn(targetPath, args, { stdio: 'inherit' });
    return waitForChild(child);
  }

  throw new Error(`Unsupported launch strategy: ${entry.launch_strategy}`);
}

module.exports = {
  ensureInstalled,
  envName,
  launchInstalled,
  logPrefix,
  packageDisplayName,
  selectTarget,
  supportedTargets,
};
