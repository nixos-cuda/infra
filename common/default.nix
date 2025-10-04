{ pkgs, inputs, ... }:
{
  imports = [
    ./nix.nix
    ./nvidia.nix
    ./ssh.nix
    ./users.nix
  ];

  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  networking.firewall.enable = true;

  environment.systemPackages = with pkgs; [
    btop
    htop
  ];
  programs.neovim = {
    enable = true;
    vimAlias = true;
  };
}
