{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nix.settings.extra-substituters = [
    "https://cache.flox.dev"
    "https://nix-community.cachix.org"
  ];
  nix.settings.extra-trusted-public-keys = [
    "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  programs.nix-required-mounts = {
    enable = true;
    presets.nvidia-gpu.enable = true;
  };
}
