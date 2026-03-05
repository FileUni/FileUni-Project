# FileUni Release Responsibility (Community Side)

This repository (`fileuni/FileUni-Community`) is the **public release repository**.

## Responsibility

- Provide public Issues entry.
- Build release artifacts by pulling source from `fileuni/FileUni-WorkSpace`.
- Publish GitHub Releases and downloadable binaries.

## Build Workflow

Workflow: `.github/workflows/community-build-release.yml`

Trigger:

- `workflow_dispatch` (usually dispatched by `FileUni-WorkSpace` workflow)

Inputs:

- `release_tag` (required)
- `workspace_ref` (optional)
- `build_mode` (optional)
- `prerelease` (optional)
- `trigger_source` (optional)

## Required Secret

- `FILEUNI_WORKSPACE_PAT`
  - Must be able to read private repository `fileuni/FileUni-WorkSpace`

## Optional Variables

- `BUILD_MODE` (fallback build mode)
- `WORKSPACE_DEFAULT_REF` (fallback source branch, default `main`)

## End-to-End Sequence

1. `FileUni-WorkSpace` dispatches this workflow with release metadata.
2. This workflow resolves source ref and build mode.
3. It checks out private `FileUni-WorkSpace` source.
4. It executes `go run script/tools.go release:build-all ...`.
5. It uploads artifacts and publishes release assets in this public repository.
