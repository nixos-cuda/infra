{
  imports = [
    ./cache.nix
    ./hardware.nix
    ./hydra.nix
    ./disko.nix
  ];

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
