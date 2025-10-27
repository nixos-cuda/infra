{ lib, ... }:
{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  networking.hostId = "e1ce6466";

  # Disable GC
  nix.gc.automatic = lib.mkForce false;

  # Legacy BIOS
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  system.stateVersion = "25.05";
}
