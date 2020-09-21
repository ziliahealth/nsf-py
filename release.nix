{ pkgs ? null } @ args:

let
  pkgs = (import ./.nix/release.nix {}).ensurePkgs args;
in

with pkgs;

let
  nix-lib = pkgs.callPackage ./nix-lib {};
in

{
  inherit nix-lib;
}
