{ config, ... }:
{
  sops.secrets.harmonia-private-key = { };

  # The socket file lives in harmonia.service's RuntimeDirectory, which systemd deletes whenever
  # the service stops. harmonia.socket then keeps "listening" on a path that no longer exists and
  # caddy returns 502s. Keep the directory around so the socket survives service restarts.
  systemd.services.harmonia.serviceConfig.RuntimeDirectoryPreserve = "yes";

  services = {
    harmonia.cache = {
      enable = true;

      signKeyPaths = [
        # Public key: cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=
        config.sops.secrets.harmonia-private-key.path
      ];

      settings = {
        bind = "unix:/run/harmonia/socket";

        # Pick a lower priority (higher number) than cache.nixos.org
        # https://cache.nixos.org/nix-cache-info
        priority = 50;

        # Whether to enable transparent compression with zstd.
        # TODO: remove when using harmonia>=3.3.0 which made it true by default
        enable_compression = true;
      };
    };

    caddy.virtualHosts."cache.nixos-cuda.org".extraConfig = ''
      reverse_proxy unix//run/harmonia/socket
    '';
  };
}
