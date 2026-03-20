{
  pkgs ? import <nixpkgs> { },
}:
{
  fileuni = pkgs.callPackage ./pkgs/fileuni-bin.nix { };
  fileuni-gui = pkgs.callPackage ./pkgs/fileuni-gui-bin.nix { };
}
