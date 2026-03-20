{
  description = "Standalone Nix package source for FileUni CLI and GUI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          fileuni = pkgs.callPackage ./pkgs/fileuni-bin.nix { };
        in
        {
          inherit fileuni;
          default = fileuni;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          fileuni-gui = pkgs.callPackage ./pkgs/fileuni-gui-bin.nix { };
        }
      );

      overlays.default =
        final: prev:
        {
          fileuni = final.callPackage ./pkgs/fileuni-bin.nix { };
        }
        // lib.optionalAttrs final.stdenv.hostPlatform.isLinux {
          fileuni-gui = final.callPackage ./pkgs/fileuni-gui-bin.nix { };
        };
    };
}
