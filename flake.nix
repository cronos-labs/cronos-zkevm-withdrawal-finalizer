{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = {
    flake-utils,
    nixpkgs,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};

      src = pkgs.lib.cleanSourceWith {
        src = ./.;
        filter = _: _: true;
      };
    in {
      packages.withdrawal-finalizer = pkgs.rustPlatform.buildRustPackage {
        pname = "withdrawal-finalizer";
        version = "1.0.0";
        inherit src;
        cargoLock = {
          lockFile = ./Cargo.lock;
          allowBuiltinFetchGit = true;
        };
        doCheck = false;
      };
    });
}