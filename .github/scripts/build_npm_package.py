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
    path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
    )


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

    package_meta = dict(config["package"])
    package_dir = output_dir / package_meta["name"]
    bin_dir = package_dir / "bin"
    scripts_dir = package_dir / "scripts"
    package_dir.mkdir(parents=True, exist_ok=True)
    bin_dir.mkdir(parents=True, exist_ok=True)
    scripts_dir.mkdir(parents=True, exist_ok=True)

    targets = [dict(entry) for entry in config["targets"]]

    repository = {
        "type": "git",
        "url": f"https://github.com/{config['repository']}",
    }
    repository_directory = package_meta.get("repository_directory")
    if repository_directory:
        repository["directory"] = repository_directory

    package_json = {
        "name": package_meta["name"],
        "version": args.version,
        "description": package_meta["description"],
        "license": "UNLICENSED",
        "repository": repository,
        "homepage": "https://fileuni.com",
        "bugs": {
            "url": "https://github.com/FileUni/FileUni-WorkSpace/issues",
        },
        "files": [
            "bin",
            "scripts",
            "README.md",
            "LICENSE",
        ],
        "bin": {package_meta["bin_name"]: "bin/launcher.js"},
        "scripts": {
            "postinstall": "node ./scripts/postinstall.cjs",
        },
        "dependencies": {
            "adm-zip": "^0.5.16",
        },
        "engines": {
            "node": ">=18.0.0",
        },
        "publishConfig": {
            "access": "public",
        },
    }

    runtime_manifest = {
        "repository": config["repository"],
        "release_tag": args.release_tag,
        "version": args.version,
        "package": package_meta,
        "targets": targets,
    }

    write_json(package_dir / "package.json", package_json)
    write_json(scripts_dir / "fileuni-manifest.json", runtime_manifest)
    shutil.copy2(license_path, package_dir / "LICENSE")
    shutil.copy2(readme_path, package_dir / "README.md")
    copy_template(
        templates_dir / "bin-fileuni.js", bin_dir / "launcher.js", executable=True
    )
    copy_template(
        templates_dir / "fileuni-common.cjs", scripts_dir / "fileuni-common.cjs"
    )
    copy_template(
        templates_dir / "postinstall.cjs",
        scripts_dir / "postinstall.cjs",
        executable=True,
    )
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build a FileUni npm package")
    parser.add_argument("--config", required=True)
    parser.add_argument("--templates", required=True)
    parser.add_argument("--readme", required=True)
    parser.add_argument("--license", required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--release-tag", required=True)
    parser.add_argument("--output", required=True)
    raise SystemExit(build_package(parser.parse_args()))
