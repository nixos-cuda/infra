{
  imports = [
    ./disko.nix
    ./hardware.nix
    ../../modules/nvidia.nix
  ];

  # GTX 1080
  hardware.nvidia.open = false;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-pascal" ];

  networking.hostId = "c0a6b9c4";

  system.stateVersion = "25.05";
}
