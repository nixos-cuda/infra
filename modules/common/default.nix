{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    ./nix.nix
    ./ssh.nix
    ./users.nix
  ];

  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  networking.firewall.enable = true;

  boot.loader = {
    systemd-boot = {
      enable = lib.mkDefault true;
      configurationLimit = 10;
    };

    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  environment.systemPackages = with pkgs; [
    btop
    htop
    nix-output-monitor
  ];
  programs = {
    tmux.enable = true;
    neovim = {
      enable = true;
      vimAlias = true;
    };
  };
}
