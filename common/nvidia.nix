{ pkgs, ... }:
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  nix.settings.system-features = [
    "cuda"
  ];
}
