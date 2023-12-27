{
  inputs.crane.url = "github:ipetkov/crane";
  inputs.fenix.url = "github:nix-community/fenix";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.std.url = "github:divnix/std";

  outputs = {
    crane,
    fenix,
    flake-utils,
    nixpkgs,
    self,
    std,
    ...
  } @ inputs: let
    systems = ["x86_64-linux"];
    inputs' =
      inputs
      // (flake-utils.lib.eachSystem systems (system: let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (pkgs.lib) cleanSourceWith;

        toolchain = with fenix.packages.${system};
          combine [
            default.cargo
            default.rustc
          ];

        craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;

        src = cleanSourceWith {
          src = ./.;
          filter = _: _: true;
        };

        commonArgs = with nixpkgs; {
          inherit src;

          strictDeps = true;
          cargoVendorDir = craneLib.vendorMultipleCargoDeps {
            inherit (craneLib.findCargoFiles src) cargoConfigs;
            cargoLockList = [
              ./Cargo.lock

              "${fenix.packages.${system}.complete.rust-src}/lib/rustlib/src/rust/Cargo.lock"
            ];
          };
        };

        cargoArtifacts = craneLib.buildDepsOnly (commonArgs
          // {
          });

        my-crate = craneLib.buildPackage (commonArgs
          // {
            inherit cargoArtifacts;
            cargoExtraArgs = "--bin withdrawal-finalizer";
          });
      in {inherit my-crate;}));
  in
    std.growOn {
      inherit systems;
      inputs = inputs';
      cellsFrom = ./nix;
      cellBlocks = with std.blockTypes; [
        #(containers "oci-images" {ci.publish = true;})
        (installables "packages" {ci.build = true;})
        #(runnables "operables")
      ];
    } {
      packages = std.harvest self ["local" "packages"];
    };
}
