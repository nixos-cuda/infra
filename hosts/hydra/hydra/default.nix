# TODO: move to hydra
{
  config,
  pkgs,
  ...
}:
let
  baseDomain = "nixos-cuda.org";
in
{
  imports = [
    ./builders.nix
  ];

  # Public key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDi1X4YCtWEto02ovI/fsond7hMKPZ0cFYMLkGn9rGtu
  # Used to authenticate to both the CPU builder
  sops.secrets.ssh-private-key.owner = config.users.users.hydra-queue-runner.name;

  services =
    let
      hydraURL = "hydra.${baseDomain}";
    in
    {
      hydra = {
        enable = true;

        # Make the drv available to the remote pre-build-hook by copying the .drv to the remote builders
        # https://github.com/NixOS/nix/issues/9272
        # Fix submitted upstream: https://github.com/NixOS/hydra/pull/1565
        package = pkgs.hydra.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./0001-hydra-queue-runner-make-drv-available-to-remote-pre-build-hook.patch
          ];
        });

        inherit hydraURL;
        notificationSender = "hydra@${baseDomain}";
        useSubstitutes = true;

        extraConfig = ''
          max_output_size = 12884901888 # 8 << 30 = 12GiB

          # Used by the cuda-packages exhaustive jobset
          allow_import_from_derivation = true

          evaluator_workers = 12
          evaluator_max_memory_size = 4096
        '';
      };
      postgresqlBackup.enable = true;

      caddy = {
        enable = true;

        virtualHosts.${hydraURL}.extraConfig = ''
          reverse_proxy localhost:${toString config.services.hydra.port}
        '';
      };
    };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
