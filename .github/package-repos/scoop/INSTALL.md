# Install FileUni With Scoop

## Requirements

- Windows
- Scoop installed
- Supported packages:
  - `fileuni` CLI: x64, x86
  - `fileuni-gui` GUI: x64

## Add Bucket

```powershell
scoop bucket add fileuni https://github.com/FileUni/scoop-fileuni
```

## Install FileUni CLI

```powershell
scoop install fileuni/fileuni
```

## Install FileUni GUI

```powershell
scoop install fileuni/fileuni-gui
```

## Run

```powershell
fileuni --help
fileuni-gui
```

## Update

```powershell
scoop update
scoop update fileuni
scoop update fileuni-gui
```

## Remove

```powershell
scoop uninstall fileuni
scoop uninstall fileuni-gui
```

## Troubleshooting

If the bucket metadata is stale:

```powershell
scoop update
scoop cache rm fileuni
scoop cache rm fileuni-gui
```

If you want to inspect the active manifests:

```powershell
scoop info fileuni
scoop info fileuni-gui
cat "$HOME\scoop\buckets\fileuni\bucket\fileuni.json"
cat "$HOME\scoop\buckets\fileuni\bucket\fileuni-gui.json"
```
