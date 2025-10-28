{ lib, ... }:
{
  imports = [
    ./cache.nix
    ./disko.nix
    ./hardware.nix
    ./hydra.nix
  ];

  networking.hostId = "e1ce6466";

  # Disable GC
  nix.gc.automatic = lib.mkForce false;

  sops.defaultSopsFile = ./secrets.yaml;

  # Legacy BIOS
  boot.loader = {
    systemd-boot.enable = false;
    efi.canTouchEfiVariables = false;

    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  system.stateVersion = "25.05";
}
