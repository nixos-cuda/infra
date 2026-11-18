{
  lib,
  pkgs,
  inputs,
  isLinux,
  isDarwin,
  ...
}:
{
  imports = [
    ./hydra-builder.nix
    ./monitoring.nix
    ./nix.nix
    ./ssh.nix
    ./users.nix
  ]
  ++ lib.optionals isLinux [
    inputs.disko.nixosModules.disko
    inputs.sops-nix.nixosModules.sops
    ./copy-fail.nix
    ./network.nix
    ./nvidia.nix
    {
      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      networking.firewall.enable = true;
      networking.useNetworkd = true;

      boot = lib.optionalAttrs isLinux {
        loader = {
          systemd-boot = {
            enable = lib.mkDefault true;
            configurationLimit = 10;
          };
          # Some systems are not able to use systemd-boot.
          grub.configurationLimit = 10;

          efi.canTouchEfiVariables = lib.mkDefault true;
        };

        # It is highly recommended to set this option to `false`, the new default from 26.11 on, to
        # reduce the risk of data loss.
        zfs.forceImportRoot = false;
      };

      programs.neovim = {
        enable = true;
        vimAlias = true;
      };
    }
  ]
  ++ lib.optionals isDarwin [
    inputs.sops-nix.darwinModules.sops
  ];

  time.timeZone = "Europe/Paris";

  environment.systemPackages = with pkgs; [
    htop
    nix-output-monitor
  ];

  programs.tmux.enable = true;
}
