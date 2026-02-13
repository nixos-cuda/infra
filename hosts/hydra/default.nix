{ lib, ... }:
{
  imports = [
    ./cache.nix
    ./disko.nix
    ./github-runner.nix
    ./grafana.nix
    ./hardware.nix
    ./hydra
  ];

  networking.hostId = "e1ce6466";

  # Disable GC
  nix.gc.automatic = lib.mkForce false;

  sops.defaultSopsFile = ./secrets.yaml;

  # Enable zramSwap to ponder nix-eval-jobs' high RAM usage
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
    algorithm = "zstd";
  };

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
