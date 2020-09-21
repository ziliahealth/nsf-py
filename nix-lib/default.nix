{ lib } @ args:

let
  callPackage = lib.callPackageWith args;
in

{
  nsfpy = {
    shell = callPackage ./shell.nix {};
  };
}
