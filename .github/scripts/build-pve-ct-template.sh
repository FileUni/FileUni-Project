#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <version> <binary-path> <output-dir>" >&2
  exit 1
fi

version="$1"
binary_path="$2"
output_dir="$3"

if [ ! -f "${binary_path}" ]; then
  echo "Binary not found: ${binary_path}" >&2
  exit 1
fi

rootfs_dir="$(mktemp -d)"
trap 'sudo rm -rf "${rootfs_dir}"' EXIT

sudo debootstrap \
  --variant=minbase \
  --include=ca-certificates,curl,iproute2,netbase,procps,systemd-sysv,tzdata \
  bookworm \
  "${rootfs_dir}" \
  http://deb.debian.org/debian

sudo install -d -m0755 \
  "${rootfs_dir}/usr/local/bin" \
  "${rootfs_dir}/etc/fileuni" \
  "${rootfs_dir}/var/lib/fileuni" \
  "${rootfs_dir}/etc/systemd/system"

sudo install -m0755 "${binary_path}" "${rootfs_dir}/usr/local/bin/fileuni"

sudo tee "${rootfs_dir}/etc/systemd/system/fileuni.service" >/dev/null <<'EOF'
[Unit]
Description=FileUni CLI Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/fileuni
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

sudo chroot "${rootfs_dir}" /bin/bash -lc "systemctl enable fileuni.service >/dev/null 2>&1 || true"
sudo tee "${rootfs_dir}/etc/motd" >/dev/null <<EOF
FileUni PVE CT Template
Version: ${version}
Binary: /usr/local/bin/fileuni
Config dir: /etc/fileuni
Data dir: /var/lib/fileuni
EOF

mkdir -p "${output_dir}"
output_file="${output_dir}/FileUni-cli-x86_64-linux-pve-ct-by-debian.tar.zst"
sudo tar \
  --zstd \
  --numeric-owner \
  --acls \
  --xattrs \
  -C "${rootfs_dir}" \
  -cpf "${output_file}" \
  .
sudo chown "$(id -u):$(id -g)" "${output_file}"
