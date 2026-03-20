# fileuni-gui

FileUni GUI distributed through npm as a single desktop package.
The package downloads the matching prebuilt desktop bundle from GitHub Releases during `postinstall`.

## Install

```bash
npm install fileuni-gui
```

## Run

```bash
npx fileuni-gui
```

## Supported Platforms

- Windows x64
- Linux x64 (glibc)
- Linux arm64 (glibc)
- macOS Intel
- macOS Apple Silicon

## Platform Override

The installer auto-detects the current platform.
You can override the target manually when needed.

Examples:

```bash
FILEUNI_GUI_NPM_TARGET=x86_64-unknown-linux-gnu npm install fileuni-gui
FILEUNI_GUI_NPM_TARGET=aarch64-apple-darwin npm install fileuni-gui
```

## Optional Controls

```bash
FILEUNI_GUI_NPM_SKIP_DOWNLOAD=1 npm install fileuni-gui
FILEUNI_GUI_NPM_BASE_URL=https://github.com/FileUni/FileUni-Project npm install fileuni-gui
```

## License

This project is licensed under the FileUni Community Source License v1.0.

For the full license text, please see:
https://github.com/FileUni/FileUni-Project/blob/main/LICENSE
