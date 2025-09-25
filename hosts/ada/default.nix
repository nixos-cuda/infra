{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  # RTX 6000 ada
  hardware.nvidia.open = true;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-ada" ];

  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };

    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "ada";
  system.stateVersion = "25.05";
}
