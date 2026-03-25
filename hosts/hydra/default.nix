{ lib, pkgs, ... }:
{
  imports = [
    ./cache.nix
    ./disko.nix
    ./github-runner.nix
    ./grafana.nix
    ./hardware.nix
    ./hydra
    ./hydra-github-app.nix
    ./sync-nixpkgs-branches.nix
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

  environment.systemPackages = [
    pkgs.btop
  ];

  system.stateVersion = "25.05";
}
