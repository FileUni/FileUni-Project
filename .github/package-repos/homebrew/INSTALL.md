# Install FileUni With Homebrew

## Requirements

- Homebrew installed
- Supported packages:
  - `fileuni` CLI: macOS Apple Silicon, macOS Intel, Linux x86_64 with GNU libc, Linux arm64 with GNU libc
  - `fileuni-gui` GUI: macOS Apple Silicon, macOS Intel

## Add Tap

```bash
brew tap FileUni/fileuni
```

## Install FileUni CLI

```bash
brew install fileuni
```

## Install FileUni GUI

```bash
brew install --cask fileuni-gui
```

## Run

```bash
fileuni --help
open -a "FileUni UI"
```

## Update

```bash
brew update
brew upgrade fileuni
brew upgrade --cask fileuni-gui
```

## Remove

```bash
brew uninstall fileuni
brew uninstall --cask fileuni-gui
```

## Troubleshooting

If Homebrew still sees older metadata:

```bash
brew update-reset
brew update
```

If you need to inspect the installed package definitions:

```bash
brew info fileuni
brew cat fileuni
brew info --cask fileuni-gui
```
