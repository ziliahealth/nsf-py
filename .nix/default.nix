{ pkgs ? null
, workspaceDir ? null
}:

rec {
  # This constitutes our default nixpkgs.
  nixpkgsSrc = builtins.fetchTarball {
      # Latest `release-19.09`.
      url = "https://github.com/jraygauthier/nixpkgs/archive/289466dd6a11c65a7de4a954d6ebf66c1ad07652.tar.gz";
      sha256 = "0r5ja052s86fr54fm1zlhld3fwawz2w1d1gd6vbvpjrpjfyajibn";
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
