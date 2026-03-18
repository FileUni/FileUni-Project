# Install FileUni With Scoop

## Requirements

- Windows
- Scoop installed
- Supported architecture:
 - x64
 - x86

## Add Bucket

```powershell
scoop bucket add fileuni https://github.com/FileUni/scoop-fileuni
```

## Install FileUni

```powershell
scoop install fileuni/fileuni
```

## Run

```powershell
fileuni --help
```

## Update

```powershell
scoop update
scoop update fileuni
```

## Remove

```powershell
scoop uninstall fileuni
```

## Troubleshooting

If the bucket metadata is stale:

```powershell
scoop update
scoop cache rm fileuni
```

If you want to inspect the active manifest:

```powershell
scoop info fileuni
cat "$HOME\\scoop\\buckets\\fileuni\\bucket\\fileuni.json"
```
