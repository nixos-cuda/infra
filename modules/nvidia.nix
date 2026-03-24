{
  lib,
  pkgs,
  pkgsCuda,
  ...
}:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgsCuda; [
    nvtopPackages.nvidia
    btop
  ];

  programs.nix-required-mounts = {
    enable = true;
    presets.nvidia-gpu.enable = true;
  };

  nixpkgs.config =
    { pkgs, ... }:
    {
      allowUnfreePredicate =
        p:
        builtins.elem (lib.getName p) [
          "nvidia-x11"
          "nvidia-settings"
        ]
        || pkgs._cuda.lib.allowUnfreeCudaPredicate p;
    };

}
