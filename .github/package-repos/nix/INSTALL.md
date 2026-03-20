# Install FileUni With Nix

## Supported Packages

- `fileuni` CLI:
  - `x86_64-linux`
  - `aarch64-linux`
  - `x86_64-darwin`
  - `aarch64-darwin`
- `fileuni-gui` GUI:
  - `x86_64-linux`
  - `aarch64-linux`

These targets cover:

- NixOS
- Linux with Nix
- WSL with Nix
- macOS with Nix for CLI

## Install With Flakes

```bash
nix profile install github:FileUni/nixpkgs-fileuni#fileuni
nix profile install github:FileUni/nixpkgs-fileuni#fileuni-gui
```

## Run Without Installing

```bash
nix run github:FileUni/nixpkgs-fileuni#fileuni -- --help
nix run github:FileUni/nixpkgs-fileuni#fileuni-gui
```

## Use In `flake.nix`

```nix
{
  inputs.fileuni.url = "github:FileUni/nixpkgs-fileuni";

  outputs = { self, nixpkgs, fileuni }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = fileuni.packages.${system}.fileuni;
      packages.${system}.gui = fileuni.packages.${system}.fileuni-gui;
    };
}
```

## Install Without Flakes

```bash
nix-env -f https://github.com/FileUni/nixpkgs-fileuni/archive/refs/heads/main.tar.gz -iA fileuni
nix-env -f https://github.com/FileUni/nixpkgs-fileuni/archive/refs/heads/main.tar.gz -iA fileuni-gui
```

## Verify

```bash
fileuni --help
fileuni-gui
```

## Troubleshooting

If your environment has stale inputs:

```bash
nix flake update github:FileUni/nixpkgs-fileuni
```

If you want to inspect the resolved packages:

```bash
nix flake show github:FileUni/nixpkgs-fileuni
```

If you see a lock-file write error while using `github:FileUni/nixpkgs-fileuni`,
you are likely pinned to an older commit. Refresh to the latest commit or run once with:

```bash
nix run --refresh github:FileUni/nixpkgs-fileuni#fileuni -- --help
nix run --refresh github:FileUni/nixpkgs-fileuni#fileuni-gui
nix run github:FileUni/nixpkgs-fileuni/main#fileuni -- --help
nix run github:FileUni/nixpkgs-fileuni/main#fileuni-gui
```

Either command will bypass the stale cached revision and pick up the committed `flake.lock`.
