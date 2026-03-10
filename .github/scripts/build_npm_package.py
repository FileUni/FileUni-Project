#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import stat
from pathlib import Path


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


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


def asset_name_for_target(target: str, binary_name: str) -> str:
    if "linux-android" in target:
        return f"{cli_base(target, 'android')}.zip"
    if "freebsd" in target:
        return f"{cli_base(target, 'freebsd')}.zip"
    if target.endswith("windows-msvc"):
        return f"{cli_base(target, 'default')}.exe.zip"
    return f"{cli_base(target, 'default')}.zip"


def copy_template(src: Path, dst: Path, executable: bool = False) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)
    if executable:
        dst.chmod(dst.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def build_package(args: argparse.Namespace) -> int:
    config = load_json(Path(args.config))
    output_dir = Path(args.output).resolve()
    templates_dir = Path(args.templates).resolve()
    license_path = Path(args.license).resolve()
    readme_path = Path(args.readme).resolve()

    package_meta = config["package"]
    package_dir = output_dir / package_meta["name"]
    bin_dir = package_dir / "bin"
    scripts_dir = package_dir / "scripts"
    package_dir.mkdir(parents=True, exist_ok=True)
    bin_dir.mkdir(parents=True, exist_ok=True)
    scripts_dir.mkdir(parents=True, exist_ok=True)

    targets = []
    for entry in config["targets"]:
        generated = dict(entry)
        generated["asset_name"] = asset_name_for_target(entry["target"], entry["binary_name"])
        targets.append(generated)

    package_json = {
        "name": package_meta["name"],
        "version": args.version,
        "description": package_meta["description"],
        "license": "UNLICENSED",
        "repository": {
            "type": "git",
            "url": "https://github.com/fileuni/FileUni-Project.git",
            "directory": package_meta["repository_directory"],
        },
        "homepage": "https://fileuni.com",
        "bugs": {
            "url": "https://github.com/fileuni/FileUni-WorkSpace/issues",
        },
        "files": [
            "bin",
            "scripts",
            "README.md",
            "LICENSE",
        ],
        "bin": {
            "fileuni": "./bin/fileuni.js"
        },
        "scripts": {
            "postinstall": "node ./scripts/postinstall.cjs"
        },
        "dependencies": {
            "adm-zip": "^0.5.16"
        },
        "engines": {
            "node": ">=18.0.0"
        },
        "publishConfig": {
            "access": "public"
        }
    }

    runtime_manifest = {
        "repository": config["repository"],
        "release_tag": args.release_tag,
        "version": args.version,
        "targets": targets,
    }

    write_json(package_dir / "package.json", package_json)
    write_json(scripts_dir / "fileuni-manifest.json", runtime_manifest)
    shutil.copy2(license_path, package_dir / "LICENSE")
    shutil.copy2(readme_path, package_dir / "README.md")
    copy_template(templates_dir / "bin-fileuni.js", bin_dir / "fileuni.js", executable=True)
    copy_template(templates_dir / "fileuni-common.cjs", scripts_dir / "fileuni-common.cjs")
    copy_template(templates_dir / "postinstall.cjs", scripts_dir / "postinstall.cjs", executable=True)
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build the single fileuni npm package")
    parser.add_argument("--config", required=True)
    parser.add_argument("--templates", required=True)
    parser.add_argument("--readme", required=True)
    parser.add_argument("--license", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-tag", required=True)
    parser.add_argument("--output", required=True)
    raise SystemExit(build_package(parser.parse_args()))
