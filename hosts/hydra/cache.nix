{ config, ... }:
{
  sops.secrets.harmonia-private-key = { };

  services =
    let
      port = "5000";
    in
    {
      harmonia = {
        enable = true;

        signKeyPaths = [
          # Public key: cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=
          config.sops.secrets.harmonia-private-key.path
        ];

        settings = {
          bind = "localhost:${port}";

          # Pick a lower priority (higher number) than cache.nixos.org
          # https://cache.nixos.org/nix-cache-info
          priority = 50;
        };
      };

      caddy.virtualHosts."cache.nixos-cuda.org".extraConfig = ''
        reverse_proxy localhost:${port}
      '';
    };
}
