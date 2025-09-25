{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  # GTX 1080
  hardware.nvidia.open = false;

  networking.hostName = "pascal";
  system.stateVersion = "25.05";
}
