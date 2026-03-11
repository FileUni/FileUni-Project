#!/usr/bin/env python3
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import shutil
from pathlib import Path


def normalize_arch(arch_raw: str) -> str:
    if arch_raw == "x86_64":
        return "x86_64"
    if arch_raw == "i686":
        return "x86_32"
    if arch_raw in {"aarch64", "arm64"}:
        return "aarch64"
    return arch_raw


def detect_os_default(target: str) -> str:
    if "windows" in target:
        return "windows"
    if "apple-darwin" in target:
        return "macos"
    if "linux-android" in target:
        return "android"
    if "freebsd" in target:
        return "freebsd"
    if "linux" in target:
        return "linux"
    return "unknown"


def detect_libc_default(target: str) -> str:
    if "musl" in target:
        return "musl"
    if "gnu" in target:
        return "gnu"
    if "msvc" in target:
        return "msvc"
    if "darwin" in target:
        return "darwin"
    if "android" in target:
        return "android"
    if "freebsd" in target:
        return "freebsd"
    return "native"


def cli_base(target: str, variant: str) -> str:
    arch = normalize_arch(target.split("-")[0])
    if variant == "default":
        return f"FileUni-cli-{arch}-{detect_os_default(target)}-{detect_libc_default(target)}"
    if variant == "android":
        return f"FileUni-cli-{arch}-android-cli"
    if variant == "freebsd":
        return f"FileUni-cli-{arch}-freebsd-freebsd"
    raise ValueError(f"Unknown CLI variant: {variant}")


def asset_name_for_target(target: str) -> str:
    if "linux-android" in target:
        return f"{cli_base(target, 'android')}.zip"
    if "freebsd" in target:
        return f"{cli_base(target, 'freebsd')}.zip"
    if target.endswith("windows-msvc"):
        return f"{cli_base(target, 'default')}.exe.zip"
    return f"{cli_base(target, 'default')}.zip"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def find_asset(artifact_root: Path, target: str) -> Path:
    target_dir = artifact_root / target
    expected_name = asset_name_for_target(target)
    exact = target_dir / expected_name
    if exact.is_file():
        return exact
    matches = sorted(target_dir.rglob(expected_name))
    if matches:
        return matches[0]
    raise FileNotFoundError(f"Asset not found for {target}: {expected_name}")


def release_url(release_tag: str, asset_name: str) -> str:
    return f"https://github.com/FileUni/FileUni-Project/releases/download/{release_tag}/{asset_name}"


def render_formula(version: str, release_tag: str, checksums: dict[str, str]) -> str:
    urls = {
        target: release_url(release_tag, asset_name_for_target(target))
        for target in checksums
    }
    return f'''class Fileuni < Formula
  desc "FileUni CLI"
  homepage "https://fileuni.com"
  version "{version}"
  license "Proprietary"

  on_macos do
    if Hardware::CPU.arm?
      url "{urls["aarch64-apple-darwin"]}"
      sha256 "{checksums["aarch64-apple-darwin"]}"
    else
      url "{urls["x86_64-apple-darwin"]}"
      sha256 "{checksums["x86_64-apple-darwin"]}"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "{urls["aarch64-unknown-linux-gnu"]}"
      sha256 "{checksums["aarch64-unknown-linux-gnu"]}"
    else
      url "{urls["x86_64-unknown-linux-gnu"]}"
      sha256 "{checksums["x86_64-unknown-linux-gnu"]}"
    end
  end

  def install
    bin.install "fileuni"
  end

  test do
    system bin/"fileuni", "--help"
  end
end
'''


def render_scoop_manifest(
    version: str, release_tag: str, checksums: dict[str, str]
) -> str:
    manifest = {
        "version": version,
        "description": "FileUni CLI",
        "homepage": "https://fileuni.com",
        "license": {
            "identifier": "Proprietary",
            "url": "https://github.com/FileUni/FileUni-Project/blob/main/LICENSE",
        },
        "architecture": {
            "64bit": {
                "url": release_url(
                    release_tag, asset_name_for_target("x86_64-pc-windows-msvc")
                ),
                "hash": checksums["x86_64-pc-windows-msvc"],
            },
            "32bit": {
                "url": release_url(
                    release_tag, asset_name_for_target("i686-pc-windows-msvc")
                ),
                "hash": checksums["i686-pc-windows-msvc"],
            },
        },
        "bin": "fileuni.exe",
        "checkver": {
            "github": "https://github.com/FileUni/FileUni-Project",
        },
        "notes": [
            "This manifest is auto-generated from FileUni release artifacts.",
        ],
    }
    return json.dumps(manifest, indent=2, ensure_ascii=False) + "\n"


def hex_to_sri_sha256(hex_digest: str) -> str:
    return "sha256-" + base64.b64encode(bytes.fromhex(hex_digest)).decode("ascii")


def render_nix_package(
    version: str, release_tag: str, checksums: dict[str, str]
) -> str:
    systems = {
        "x86_64-linux": {
            "url": release_url(
                release_tag, asset_name_for_target("x86_64-unknown-linux-gnu")
            ),
            "hash": hex_to_sri_sha256(checksums["x86_64-unknown-linux-gnu"]),
        },
        "aarch64-linux": {
            "url": release_url(
                release_tag, asset_name_for_target("aarch64-unknown-linux-gnu")
            ),
            "hash": hex_to_sri_sha256(checksums["aarch64-unknown-linux-gnu"]),
        },
        "x86_64-darwin": {
            "url": release_url(
                release_tag, asset_name_for_target("x86_64-apple-darwin")
            ),
            "hash": hex_to_sri_sha256(checksums["x86_64-apple-darwin"]),
        },
        "aarch64-darwin": {
            "url": release_url(
                release_tag, asset_name_for_target("aarch64-apple-darwin")
            ),
            "hash": hex_to_sri_sha256(checksums["aarch64-apple-darwin"]),
        },
    }

    entries = []
    for system, meta in systems.items():
        entries.append(
            f'    "{system}" = {{ url = "{meta["url"]}"; hash = "{meta["hash"]}"; }};'
        )
    sources_block = "\n".join(entries)

    return f'''{{ lib, stdenvNoCC, fetchurl, unzip }}:

let
  pname = "fileuni";
  version = "{version}";
  sources = {{
{sources_block}
  }};
  source = sources.${{stdenvNoCC.hostPlatform.system}}
    or (throw "Unsupported system for FileUni: ${{stdenvNoCC.hostPlatform.system}}");
in
stdenvNoCC.mkDerivation {{
  inherit pname version;

  src = fetchurl {{
    url = source.url;
    hash = source.hash;
  }};

  nativeBuildInputs = [ unzip ];

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    mkdir -p source
    unzip -q "$src" -d source
    runHook postUnpack
  '';

  sourceRoot = "source";

  installPhase = ''
    runHook preInstall
    install -Dm755 "$sourceRoot/fileuni" "$out/bin/fileuni"
    runHook postInstall
  '';

  meta = with lib; {{
    description = "FileUni CLI";
    homepage = "https://fileuni.com";
    mainProgram = "fileuni";
    platforms = builtins.attrNames sources;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  }};
}}
'''


def reset_directory(target_dir: Path) -> None:
    target_dir.mkdir(parents=True, exist_ok=True)
    for child in target_dir.iterdir():
        if child.name == ".git":
            continue
        if child.is_dir():
            shutil.rmtree(child)
        else:
            child.unlink()


def copy_tree_contents(source_dir: Path, target_dir: Path) -> None:
    for path in sorted(source_dir.rglob("*")):
        relative = path.relative_to(source_dir)
        destination = target_dir / relative
        if path.is_dir():
            destination.mkdir(parents=True, exist_ok=True)
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, destination)


def generate_homebrew_repo(
    output_dir: Path,
    template_root: Path,
    version: str,
    release_tag: str,
    checksums: dict[str, str],
) -> None:
    reset_directory(output_dir)
    copy_tree_contents(template_root / "homebrew", output_dir)
    formula_path = output_dir / "Formula" / "fileuni.rb"
    formula_path.parent.mkdir(parents=True, exist_ok=True)
    formula_path.write_text(
        render_formula(version, release_tag, checksums), encoding="utf-8"
    )


def generate_scoop_repo(
    output_dir: Path,
    template_root: Path,
    version: str,
    release_tag: str,
    checksums: dict[str, str],
) -> None:
    reset_directory(output_dir)
    copy_tree_contents(template_root / "scoop", output_dir)
    manifest_path = output_dir / "bucket" / "fileuni.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        render_scoop_manifest(version, release_tag, checksums), encoding="utf-8"
    )


def generate_nix_repo(
    output_dir: Path,
    template_root: Path,
    version: str,
    release_tag: str,
    checksums: dict[str, str],
) -> None:
    reset_directory(output_dir)
    copy_tree_contents(template_root / "nix", output_dir)
    nix_path = output_dir / "pkgs" / "fileuni-bin.nix"
    nix_path.parent.mkdir(parents=True, exist_ok=True)
    nix_path.write_text(
        render_nix_package(version, release_tag, checksums), encoding="utf-8"
    )


def generate_package_repos(args: argparse.Namespace) -> int:
    artifact_root = Path(args.artifact_root).resolve()
    template_root = Path(args.template_root).resolve()

    checksum_targets = [
        "x86_64-apple-darwin",
        "aarch64-apple-darwin",
        "x86_64-unknown-linux-gnu",
        "aarch64-unknown-linux-gnu",
        "x86_64-pc-windows-msvc",
        "i686-pc-windows-msvc",
    ]
    checksums = {
        target: sha256_file(find_asset(artifact_root, target))
        for target in checksum_targets
    }

    generate_homebrew_repo(
        Path(args.homebrew_out).resolve(),
        template_root,
        args.version,
        args.release_tag,
        checksums,
    )
    generate_scoop_repo(
        Path(args.scoop_out).resolve(),
        template_root,
        args.version,
        args.release_tag,
        checksums,
    )
    generate_nix_repo(
        Path(args.nix_out).resolve(),
        template_root,
        args.version,
        args.release_tag,
        checksums,
    )
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate Homebrew, Scoop, and Nix package repositories"
    )
    parser.add_argument("--artifact-root", required=True)
    parser.add_argument("--template-root", required=True)
    parser.add_argument("--homebrew-out", required=True)
    parser.add_argument("--scoop-out", required=True)
    parser.add_argument("--nix-out", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-tag", required=True)
    raise SystemExit(generate_package_repos(parser.parse_args()))
