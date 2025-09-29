{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  # GTX 1080
  hardware.nvidia.open = false;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-pascal" ];

  networking.hostName = "pascal";
  system.stateVersion = "25.05";
}
