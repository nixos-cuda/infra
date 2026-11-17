{ config, ... }:
{
  sops.secrets.harmonia-private-key = { };

  services = {
    harmonia.cache = {
      enable = true;

      signKeyPaths = [
        # Public key: cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=
        config.sops.secrets.harmonia-private-key.path
      ];

      settings = {
        # Don't put the socket in /run/harmonia: it is harmonia.service's RuntimeDirectory, which
        # systemd wipes whenever the service stops. harmonia.socket would then keep listening on a
        # deleted path and caddy would return 502s.
        bind = "unix:/run/harmonia-cache/socket";

        # Pick a lower priority (higher number) than cache.nixos.org
        # https://cache.nixos.org/nix-cache-info
        priority = 50;

        # Whether to enable transparent compression with zstd.
        # TODO: remove when using harmonia>=3.3.0 which made it true by default
        enable_compression = true;
      };
    };

    caddy.virtualHosts."cache.nixos-cuda.org".extraConfig = ''
      reverse_proxy unix//run/harmonia-cache/socket
    '';
  };
}
