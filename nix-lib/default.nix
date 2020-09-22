{ lib } @ args:

let
  callPackage = lib.callPackageWith args;
in

{
  nsfPy = {
    shell = callPackage ./shell.nix {};
  };
}
