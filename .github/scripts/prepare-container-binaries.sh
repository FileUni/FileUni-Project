#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <artifacts-dir> <output-dir>" >&2
  exit 1
fi

artifacts_dir="$1"
output_dir="$2"

mkdir -p "${output_dir}"

copy_binary() {
  local artifact_name="$1"
  local docker_arch="$2"
  local source_path=""

  source_path="$(find "${artifacts_dir}/${artifact_name}" -type f -name 'fileuni' | head -1 || true)"
  if [ -z "${source_path}" ]; then
    local archive_path=""
    archive_path="$(find "${artifacts_dir}/${artifact_name}" -type f -name '*.tar.xz' | head -1 || true)"
    if [ -n "${archive_path}" ]; then
      local tmp_dir=""
      tmp_dir="$(mktemp -d)"
      tar -xJf "${archive_path}" -C "${tmp_dir}"
      source_path="$(find "${tmp_dir}" -type f -name 'fileuni' | head -1 || true)"
    fi
  fi

  if [ -z "${source_path}" ] || [ ! -f "${source_path}" ]; then
    echo "Missing fileuni binary in artifact ${artifact_name}" >&2
    exit 1
  fi

  install -Dm0755 "${source_path}" "${output_dir}/${docker_arch}/fileuni"
}

copy_binary "cli-x86_64-unknown-linux-musl" "amd64"
copy_binary "cli-aarch64-unknown-linux-musl" "arm64"
copy_binary "cli-armv7-unknown-linux-musleabihf" "armv7"
