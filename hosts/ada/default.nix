{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  # RTX 6000 ada
  _nvidia = {
    enable = true;
    cudaCapabilities = [ "8.9" ];
    openSourceKernelModules = true;
    requiredMountsOnFeatures = [ "cuda-ada" ];
  };

  networking.hostId = "7b3b5a4c";

  system.stateVersion = "25.05";
}
