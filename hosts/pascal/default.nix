{ pkgs, ... }:
{
  imports = [
    ./disko.nix
    ./hardware.nix
    ../../modules/nvidia.nix
  ];

  # GTX 1080
  hardware.nvidia.open = false;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-pascal" ];

  _module.args.pkgsCuda = import pkgs.path {
    system = "x86_64-linux";
    config =
      { pkgs, ... }:
      {
        cudaSupport = true;
        cudaCapabilities = [
          "6.0"
        ];
        allowUnfreePredicate = pkgs._cuda.lib.allowUnfreeCudaPredicate;
      };
  };

  # Legacy BIOS
  boot.loader.systemd-boot.enable = false;

  networking.hostId = "c0a6b9c4";

  system.stateVersion = "25.05";
}
