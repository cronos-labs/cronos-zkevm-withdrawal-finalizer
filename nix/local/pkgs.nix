{
  default = import inputs.nixpkgs {
    inherit (inputs.nixpkgs) system;
    overlays = [];
  };
}
