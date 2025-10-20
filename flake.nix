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

              portablegl-demos = pkgs.callPackage (
                {
                  stdenv,
                  portablegl,
                  SDL2,
                  llvmPackages_20,
                  assimp,
                  premake4
                }:
                stdenv.mkDerivation {
                  pname = "portablegl-demos";
                  version = pkgs.portablegl.version;
                  src = ./.;
                  buildInputs = [
                    stdenv
                    portablegl
                    SDL2
                    llvmPackages_20.openmp
                    assimp
                    premake4
                  ];
                  premakeFlags = [ "--prefix=$(out)/" ];
                  makeFlags = ["config=release"];
                  preConfigure = ''
                    cd demos
                    mkdir -p $out/bin
                  '';
                  INCLUDES = "-I${pkgs.portablegl}/include/";
                  installPhase = ''
                    runHook preInstall
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
          portablegl-demos = pkgs.portablegl-demos;
        };

        devShells.default =
          with pkgs;
          mkShell {
            inputsFrom = [ portablegl portablegl-demos ];
          };
      }
    );
}
