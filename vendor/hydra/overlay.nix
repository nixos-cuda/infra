# Package set from https://github.com/NixOS/nixpkgs/pull/563797, vendored until
# the PR lands in our nixpkgs channel. See ./README.md.
final: _prev: {
  hydra = final.callPackage ./pkgs/hydra/package.nix { };
  # `patches/` holds our own fixes; see ./README.md. The patch does not touch
  # Cargo.lock, so the vendored package's `cargoHash` stays valid.
  hydra-builder = (final.callPackage ./pkgs/hydra-builder/package.nix { }).overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/0001-hydra-builder-make-drv-available-to-pre-build-hook.patch
    ];
  });
  hydra-evaluator = final.callPackage ./pkgs/hydra-evaluator/package.nix { };
  hydra-queue-runner =
    (final.callPackage ./pkgs/hydra-queue-runner/package.nix { }).overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          ./patches/0002-queue-runner-skip-unparseable-drvpath.patch
        ];
      });
  hydra-ws = final.callPackage ./pkgs/hydra-ws/package.nix { };
}
