{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config._brevBuilder;
  inherit (pkgs.stdenv.hostPlatform) isx86_64;
in
{
  config = lib.mkIf cfg.enable {
    # Equivalent to importing `(modulesPath + "/installer/scan/not-detected.nix")`.
    # `imports` cannot be conditional, and this module is imported by every host.
    hardware.enableRedistributableFirmware = lib.mkDefault true;

    boot = {
      initrd = {
        availableKernelModules = [
          "nvme"
        ];
        kernelModules = [
          "dm-snapshot"
        ];
      };
      kernelModules = lib.optionals isx86_64 [
        "kvm-intel"
      ];
      extraModulePackages = [ ];
    };

    hardware.cpu.intel.updateMicrocode = lib.mkIf isx86_64 config.hardware.enableRedistributableFirmware;
  };
}
