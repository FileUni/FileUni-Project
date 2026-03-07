# FileUni Release Flow (Community Side)

## Workflow

- File: `release.yml`
- Trigger: `workflow_dispatch` (manual or API-dispatch from WorkSpace)
- Required secret: `FILEUNI_WORKSPACE_PAT`

## Stages

1. **build-frontends** — Checkout WorkSpace, build CLI frontend with Bun
2. **build-cli** — Matrix build across 6 targets via `cargo-dist`
3. **publish** — Collect artifacts, publish GitHub Release

## Targets

| Runner | Target |
|--------|--------|
| ubuntu-latest | `x86_64-unknown-linux-gnu` |
| ubuntu-latest | `x86_64-unknown-linux-musl` |
| ubuntu-latest | `aarch64-unknown-linux-gnu` |
| windows-latest | `x86_64-pc-windows-msvc` |
| macos-15 | `x86_64-apple-darwin` |
| macos-15 | `aarch64-apple-darwin` |

## Notes

- GUI/Tauri release pipeline is not yet implemented.
- CLI has zero C dependencies — no cross-compilation toolchain needed except `gcc-aarch64-linux-gnu` for ARM Linux linker.
