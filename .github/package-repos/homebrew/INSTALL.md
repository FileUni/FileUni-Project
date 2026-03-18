# Install FileUni With Homebrew

## Requirements

- Homebrew installed
- Supported platform:
 - macOS Apple Silicon
 - macOS Intel
 - Linux x86_64 with GNU libc
 - Linux arm64 with GNU libc

## Add Tap

```bash
brew tap FileUni/fileuni
```

## Install FileUni

```bash
brew install fileuni
```

## Run

```bash
fileuni --help
```

## Update

```bash
brew update
brew upgrade fileuni
```

## Remove

```bash
brew uninstall fileuni
```

## Troubleshooting

If Homebrew still sees an older formula version:

```bash
brew update-reset
brew update
```

If you need to inspect the installed formula:

```bash
brew info fileuni
brew cat fileuni
```
