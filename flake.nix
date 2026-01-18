{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            mkdir -p "$(pwd)/_libs"
            export R_LIBS_USER="$(pwd)/_libs"
          '';
          packages = with pkgs; [
            bashInteractive
            autoconf
            go-task
            pandoc
            air
            llvmPackages.openmp
            (rWrapper.override {
              packages = with rPackages; [
                Rcpp
                covr
                devtools
                knitr
                languageserver
                rhub
                rmarkdown
                spelling
                testthat
                sf
              ];
            })
          ];
        };
      }
    );
}
