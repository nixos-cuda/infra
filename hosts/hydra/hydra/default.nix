# TODO: move to hydra
{ config, ... }:
let
  baseDomain = "nixos-cuda.org";
in
{
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

        inherit hydraURL;
        notificationSender = "hydra@${baseDomain}";
        useSubstitutes = true;

        extraConfig = ''
          max_output_size = 4294967296 # 4 << 30 = 4GiB

          # Used by the cuda-packages exhaustive jobset
          allow_import_from_derivation = true
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
