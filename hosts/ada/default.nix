{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/nvidia.nix
  ];

  _module.args.pkgsCuda = import pkgs.path {
    system = "x86_64-linux";
    config =
      { pkgs, ... }:
      {
        cudaSupport = true;
        cudaCapabilities = [
          "8.9"
        ];
        allowUnfreePredicate = pkgs._cuda.lib.allowUnfreeCudaPredicate;
      };
  };

  # RTX 6000 ada
  hardware.nvidia.open = true;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-ada" ];

  networking.hostId = "7b3b5a4c";

  system.stateVersion = "25.05";
}
