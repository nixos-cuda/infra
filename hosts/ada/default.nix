{ inputs, ... }:
{
  imports = [
    ./cache.nix
    ./hardware.nix
    ./hydra.nix
    ./disko.nix
    ../../modules/nvidia.nix
    ../../common
    (inputs."microvm.nix" + "/nixos-modules/host")
  ];

  microvm.vms.ada-builder.specialArgs = {
    inherit inputs;
  };
  microvm.vms.ada-builder.config = {
    imports = [ ../ada-builder ];
  };
  microvm.vms.ada-builder.pkgs = null;
  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "vt-*" ];
  networking.nat.externalInterface = "enp4s0";

  # RTX 6000 ada
  hardware.nvidia.open = true;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-ada" ];

  sops.defaultSopsFile = ./secrets.yaml;

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    efi.canTouchEfiVariables = true;
  };

  networking = {
    hostName = "ada";
    hostId = "7b3b5a4c";
  };
  system.stateVersion = "25.05";
}
