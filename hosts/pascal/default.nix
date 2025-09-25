{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  # GTX 1080
  hardware.nvidia.open = false;
  nix.settings.system-features = [ "cuda-pascal" ];

  networking.hostName = "pascal";
  system.stateVersion = "25.05";
}
