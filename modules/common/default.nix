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
    ./monitoring.nix
    ./nix.nix
    ./ssh.nix
    ./users.nix
    ./network.nix
    ./nvidia.nix
    ./copy-fail.nix
  ];

  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  networking.firewall.enable = true;
  networking.useNetworkd = true;

  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 10;
      };

      efi.canTouchEfiVariables = lib.mkDefault true;
    };

    # It is highly recommended to set this option to `false`, the new default from 26.11 on, to
    # reduce the risk of data loss.
    zfs.forceImportRoot = false;
  };

  environment.systemPackages = with pkgs; [
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
