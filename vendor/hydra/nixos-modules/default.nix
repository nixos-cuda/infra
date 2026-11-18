# The `services.hydra` and `services.hydra-builder` modules, taken from
# `nixpkgs-hydra` (unstable) because 26.05 predates Hydra's Rust rewrite.
# See ../README.md.
#
# Imported by the Hydra server (hosts/htz1-01) and by every build agent
# (modules/common/hydra-builder.nix); both need the overlay, since
# `services.hydra` and `services.hydra-builder` default to the packages it
# provides.
{
  inputs,
  pkgs,
  lib,
  isLinux,
  isDarwin,
  ...
}:
let
  hydraNixOSModules = "${inputs.nixpkgs-hydra}/nixos/modules/services/continuous-integration/hydra";
  hydraDarwinModules = "${inputs.hydra}/darwin-modules";
in
{
  disabledModules = [ "services/continuous-integration/hydra/default.nix" ];

  imports =
    lib.optionals isLinux [
      "${hydraNixOSModules}/builder.nix"
      "${hydraNixOSModules}/default.nix"
    ]
    ++ lib.optionals isDarwin [
      "${hydraDarwinModules}/builder-module.nix"
    ];

  nixpkgs.overlays = [ (import ../overlay.nix inputs) ];

  services = lib.optionalAttrs isDarwin {
    hydra-queue-builder-dev.package = pkgs.hydra-builder;
  };
}
