# fileuni

FileUni CLI distributed through npm as a single package.
The package downloads the matching prebuilt binary from GitHub Releases during `postinstall`.

## Install

```bash
npm install fileuni
```

## Run

```bash
npx fileuni --help
```

## Platform Override

The installer auto-detects the current platform.
You can override the target manually when you need a specific Linux runtime variant.

Examples:

```bash
FILEUNI_NPM_LIBC=musl npm install fileuni
FILEUNI_NPM_TARGET=x86_64-unknown-linux-musl npm install fileuni
```

## Optional Controls

```bash
FILEUNI_NPM_SKIP_DOWNLOAD=1 npm install fileuni
FILEUNI_NPM_BASE_URL=https://github.com/FileUni/FileUni-Project npm install fileuni
```

## License

MIT
