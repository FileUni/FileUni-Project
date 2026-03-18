# FileUni Release Flow (Project Side)

## Workflow Files

- Upstream trigger in WorkSpace: `.github/workflows/trigger-project-release.yml`
- Downstream build/publish workflow in Project: `FileUni-release.yml`
- Required secret in Project: `FILEUNI_WORKSPACE_PAT`
- npm target manifest: `.github/npm/binary-targets.json`
- npm package builder: `.github/scripts/build_npm_package.py`
- npm package templates: `.github/npm/templates/`

## Trigger Sources

`FileUni-release.yml` is always a `workflow_dispatch` workflow, but it can be reached from three different sources:

| Source | How it is triggered | Key inputs passed to Project | Default release name |
|--------|---------------------|------------------------------|----------------------|
| App tag release | WorkSpace pushes `fileuni-v*` and dispatches Project | `workspace_ref=<tag>`, `trigger_mode=tag`, `prerelease=false` | `FileUni-v...` |
| Nightly release | WorkSpace schedule runs daily at 03:45 Asia/Shanghai (`45 19 * * *` UTC) | `workspace_ref=main`, `trigger_mode=nightly`, `prerelease=true` | `nightly_YYYYMMDD_HHMMSS` |
| Direct manual dispatch | User runs `FileUni-release.yml` manually in Project | `trigger_mode=manual` by default | `release_name` if provided, otherwise `manually_YYYYMMDD_HHMMSS` |

## Release Name Resolution

The final GitHub release `tag_name` and display `name` are resolved in this order:

1. `release_name` input, if it is non-empty
2. `trigger_mode=tag` → `FileUni-v...`
3. `trigger_mode=nightly` → `nightly_YYYYMMDD_HHMMSS`
4. `trigger_mode=manual` → `manually_YYYYMMDD_HHMMSS`

Timestamps are generated in the `Asia/Shanghai` timezone.

## Manual Inputs

Important `workflow_dispatch` inputs:

- `workspace_ref` — source ref in `FileUni-WorkSpace`
- `release_name` — optional manual override for the release name
- `trigger_mode` — `manual`, `tag`, or `nightly`
- `build_mode` — `full` or `minimal`
- `build_target` — `cli`, `gui`, or `cli+gui`
- `prerelease` — whether the GitHub release is marked as pre-release
- `enable_upx` — whether UPX-compressed copies are produced where supported

## Stages

1. resolve-matrix — Resolve source ref, release metadata, and build matrix
2. build-frontends — Build CLI and GUI frontend assets from WorkSpace
3. build-cli — Build CLI artifacts across cargo-dist, cross, Android, BSD, and package formats
4. build-gui — Build GUI artifacts across desktop Tauri, Android, and iOS paths
5. publish — Collect standardized `FileUni-*` artifacts, generate release notes, and publish the GitHub Release
6. update-package-indexes — Update Homebrew tap, Scoop bucket, and Nix package sources in WorkSpace after a tag release
7. publish-npm — Build and publish the single `fileuni` npm package after the GitHub Release is available

## Artifact Naming

- Final release assets are standardized as `FileUni-*`
- Architecture, OS, and libc naming are centralized in `.github/scripts/arch-helpers.sh`
- The publish step removes non-standard filenames before uploading release assets
- The npm package downloads those same standardized GitHub Release assets during `postinstall`

## Build Coverage

The exact matrix is resolved from `.github/build_matrix.jsonc`, but the workflow currently supports:

- CLI native and cross builds
- CLI Android builds
- CLI FreeBSD builds
- Linux package builds via nFPM
- npm single-package distribution for Linux `gnu` / `musl`, Windows, macOS, Android, and FreeBSD
- Homebrew tap updates for macOS and Linux CLI assets
- Scoop bucket updates for Windows CLI assets
- Nix package repo updates for Linux and macOS CLI assets
- GUI desktop Tauri builds
- GUI Android APK builds
- GUI iOS IPA packaging

## npm Publish Rules

- npm publish is enabled only when `build_mode=full`
- Homebrew, Scoop, and Nix index updates run only for `trigger_mode=tag` releases
- npm publish requires CLI builds to be enabled
- npm publish runs after the GitHub Release has been published, because the npm package downloads release assets by `release_tag`
- npm publish uses npm Trusted Publisher with GitHub Actions OIDC
- no `NPM_TOKEN` secret is required for npm publishing
- the npm package settings must trust `FileUni/FileUni-Project` and the `FileUni-release.yml` workflow
- only one npm package is published: `fileuni`
- prerelease versions are published with a non-`latest` npm dist-tag derived from the semver prerelease label, while stable versions use `latest`
- the package auto-detects the current platform during `postinstall`
- Linux defaults to `gnu` when detection is ambiguous, and users can override with `FILEUNI_NPM_LIBC` or `FILEUNI_NPM_TARGET`

## npm Package Layout

- Package name: `fileuni`
- Binary target metadata is defined in `.github/npm/binary-targets.json`
- The generated package contains only JavaScript launcher/install files and downloads the real CLI binary from GitHub Releases on demand
- This design is fully independent from `packages/`, so `packages/` can be removed later without affecting release publishing

## Notes

- The upstream dispatch workflow uses `ref: main` for the workflow file version, while `workspace_ref` controls which WorkSpace source ref is checked out and built.
- CLI remains friendly to cross-compilation, while GUI release jobs include platform-specific packaging steps.

## Package Manager Repos

- Homebrew tap repo: `FileUni/homebrew-fileuni`
- Scoop bucket repo: `FileUni/scoop-fileuni`
- Nix package repo: `FileUni/nixpkgs-fileuni`
- Repository contents are generated in CI from `.github/package-repos/` templates and `.github/scripts/update_package_indexes.py`
- `FileUni-release.yml` clones those standalone repos, regenerates their contents in a temporary workspace, and pushes updates directly
- `Crontab_Subtree.yml` does not manage package manager repositories
