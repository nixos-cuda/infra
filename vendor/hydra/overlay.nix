# Hydra's Rust rewrite, taken from `nixpkgs-hydra` (unstable) because 26.05
# predates it, plus the patches in ./patches. See ./README.md.
#
# `inherit`ing straight from the other package set keeps each package built
# against the nixpkgs its NixOS module was written for, which is the point of
# using a full nixpkgs as the input.
inputs: final: _prev:
let
  hydraPkgs = inputs.nixpkgs-hydra.legacyPackages.${final.stdenv.hostPlatform.system};

  withPatches =
    package: patches:
    package.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ patches;
    });
in
{
  inherit (hydraPkgs)
    hydra
    hydra-evaluator
    hydra-ws
    ;

  hydra-builder = withPatches hydraPkgs.hydra-builder [
    ./patches/0001-hydra-builder-make-drv-available-to-pre-build-hook.patch
  ];

  hydra-queue-runner = withPatches hydraPkgs.hydra-queue-runner [
    ./patches/0002-queue-runner-skip-unparseable-drvpath.patch
  ];
}
