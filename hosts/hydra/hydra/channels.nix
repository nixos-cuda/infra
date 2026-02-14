{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # GitHub App's private key, used to update branches in nixpkgs repo
  sops.secrets.channel-updater-github-app-key.owner = config.users.users.hydra-queue-runner.name;

  services.hydra = {
    extraConfig =
      let
        hydraChannelUpdateScript =
          pkgs.lib.getExe
            inputs.self.packages.${config.nixpkgs.system}.hydra-channel-update-script;

        commandPrefix = lib.concatStringsSep " " [
          hydraChannelUpdateScript

          "https://${config.services.hydra.hydraURL}"

          # channel-updater GitHub app client ID
          "Iv23liZJuJFjr3N1KsP0"

          # Path to the channel-updater Github app key file
          config.sops.secrets.channel-updater-github-app-key.path

          # nixpkgs fork
          "nixos-cuda/nixpkgs"
        ];
      in
      ''
        <runcommand>
          job = nixos-cuda:channel-unstable:_tested
          command = ${commandPrefix} nixos-unstable-cuda
        </runcommand>
        <runcommand>
          job = nixos-cuda:channel-25.11:_tested
          command = ${commandPrefix} nixos-25.11-cuda
        </runcommand>
      '';
  };
}
