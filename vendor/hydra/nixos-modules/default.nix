# The `services.hydra` and `services.hydra-builder` modules, taken from
# `nixpkgs-hydra` (unstable) because 26.05 predates Hydra's Rust rewrite.
# See ../README.md.
#
# Imported by the Hydra server (hosts/hydra) and by every build agent
# (modules/common/hydra-builder.nix); both need the overlay, since
# `services.hydra` and `services.hydra-builder` default to the packages it
# provides.
{ inputs, ... }:
let
  hydraModules = "${inputs.nixpkgs-hydra}/nixos/modules/services/continuous-integration/hydra";
in
{
  disabledModules = [ "services/continuous-integration/hydra/default.nix" ];

  imports = [
    "${hydraModules}/builder.nix"
    "${hydraModules}/default.nix"
  ];

  nixpkgs.overlays = [ (import ../overlay.nix inputs) ];
}
