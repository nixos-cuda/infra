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
        helpers = pkgs.lib.getExe inputs.self.packages.${config.nixpkgs.system}.helpers;

        commandPrefix = lib.concatStringsSep " " [
          helpers

          # channel-updater GitHub app client ID
          "--client-id"
          "Iv23liZJuJFjr3N1KsP0"

          # Path to the channel-updater Github app key file
          "--private-key"
          config.sops.secrets.channel-updater-github-app-key.path

          "update-channel"
          "--hydra-url"
          "https://${config.services.hydra.hydraURL}"

          # nixpkgs fork
          "--repo-full-name"
          "nixos-cuda/nixpkgs"
        ];
      in
      ''
        <runcommand>
          job = nixos-cuda:channel-unstable:_tested
          command = ${commandPrefix} --upstream-branch nixos-unstable-small --branch nixos-unstable-cuda
        </runcommand>
        <runcommand>
          job = nixos-cuda:channel-25.11:_tested
          command = ${commandPrefix} --upstream-branch nixos-25.11-small --branch nixos-25.11-cuda
        </runcommand>
      '';
  };
}
