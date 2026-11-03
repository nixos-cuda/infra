{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  # GTX 1080
  _nvidia = {
    enable = true;
    cudaCapabilities = [ "6.1" ];
    openSourceKernelModules = false;
    requiredMountsOnFeatures = [ "cuda-pascal" ];
  };

  _hydraBuilder = {
    enable = true;
    extraSupportedFeatures = [ "cuda-pascal" ];
    # mandatoryFeatures = [ "cuda-pascal" ];
  };

  # Legacy BIOS
  boot.loader.systemd-boot.enable = false;

  networking.hostId = "c0a6b9c4";

  system.stateVersion = "25.05";
}
