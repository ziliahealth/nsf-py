{ pkgs ? null
, workspaceDir ? null
}:

rec {
  # This constitutes our default nixpkgs.
  nixpkgsSrc = builtins.fetchTarball rec {
       # nixpkgs 24.11 - 2025-02-04
      rev = "030ba1976b7c0e1a67d9716b17308ccdab5b381e";
      sha256 = "14rpk53mia7j0hr4yaf5m3b2d4lzjx8qi2rszxjhqq00pxzzr64w";
      url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    };
  nixpkgs = nixpkgsSrc;

  importPkgs = { nixpkgs ? null } @ args:
      let
        nixpkgs =
          if args ? "nixpkgs" && null != args.nixpkgs
            then args.nixpkgs
            # This constitutes our default nixpkgs.
            else nixpkgsSrc;
      in
    assert null != nixpkgs;
    import nixpkgs {};

  ensurePkgs = { pkgs ? null, nixpkgs ? null }:
    if null != pkgs
      then pkgs
    else
      importPkgs { inherit nixpkgs; };
}
