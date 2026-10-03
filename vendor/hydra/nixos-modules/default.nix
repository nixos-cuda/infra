# NixOS modules from https://github.com/NixOS/nixpkgs/pull/563797, vendored
# until the PR lands in our nixpkgs channel. See ../README.md.
#
# Imported by the Hydra server (hosts/hydra) and by every build agent
# (modules/hydra-builder.nix); both need the overlay, since `services.hydra`
# and `services.hydra-builder` default to the packages it provides.
{
  disabledModules = [ "services/continuous-integration/hydra/default.nix" ];

  imports = [
    ./hydra/builder.nix
    ./hydra/default.nix
  ];

  nixpkgs.overlays = [ (import ../overlay.nix) ];
}
