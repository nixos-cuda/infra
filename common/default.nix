{ pkgs, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./nix.nix
    ./ssh.nix
    ./users.nix
  ];

  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  networking.firewall.enable = true;

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  environment.systemPackages = with pkgs; [
    btop
    htop
    nvtopPackages.nvidia
  ];
  programs.neovim = {
    enable = true;
    vimAlias = true;
  };
}
