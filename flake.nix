{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/release-25.05";
    };
    utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          localSystem = system;
          overlays = [
            (final: prev: {

              portablegl = pkgs.callPackage (
                {
                  stdenv,
                  python314,
                }:
                stdenv.mkDerivation {
                  pname = "portablegl";
                  version = "0.99.0";
                  src = ./.;

                  # Versions can be checked with
                  # `nix eval --json ".#riscv-bluespec-classic.nativeBuildInputs" | nix-shell -p jq --run jq`
                  nativeBuildInputs = [
                    python314
                  ];

                  buildPhase = ''
                      pushd src
                      python3 generate_gl_h.py
                      popd
                  '';

                  installPhase = ''
                    runHook preInstall

                    mkdir -p "$out/include"
                    cp ./src/portablegl.h "$out/include/portablegl.h"

                    runHook postInstall
                  '';

                }
              ) { };

            })
          ];
        };
      in
      {
        packages = {
          default = inputs.self.packages."${system}".portablegl;
          portablegl = pkgs.portablegl;
        };

        devShells.default =
          with pkgs;
          mkShell {
            inputsFrom = [ portablegl ];
          };
      }
    );
}
