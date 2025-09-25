{
  imports = [
    ./disko.nix
    ./hardware.nix
    ./hydra.nix
  ];

  # GTX 1080
  hardware.nvidia.open = false;
  nix.settings.system-features = [ "cuda-pascal" ];
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-pascal" ];

  networking.hostName = "pascal";
  system.stateVersion = "25.05";
}
