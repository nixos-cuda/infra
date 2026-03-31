# TODO: move to hydra
{
  config,
  pkgs,
  ...
}:
let
  baseDomain = "nixos-cuda.org";
  cfg = config.services.hydra;
  anubisCfg = config.services.anubis.instances."hydra-server";
in
{
  imports = [
    ./builders.nix
    ./channels.nix
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
          # CUDA-enabled builds are getting painfully large...
          max_output_size = 17179869184 # 16 << 30 = 16GiB

          # Used by the cuda-packages exhaustive jobset
          allow_import_from_derivation = true

          # Defaults to bzip2.
          # Note that CNO Hydra sets `compress_build_logs = false`
          # and `upload_logs_to_binary_cache = true` instead.
          compress_build_logs_compression = zstd

          evaluator_workers = 12
          evaluator_max_memory_size = 4096
        '';
      };
      postgresqlBackup.enable = true;

      caddy = {
        enable = true;

        virtualHosts.${hydraURL}.extraConfig = ''
          rate_limit {
              # Tasks so expensive we won't even do per-host limits
              zone global_queue {
                  match {
                      # Spawns `nix-store --export ... | gzip`
                      # path /job/*/*/*/channel/*
                      path */channel/latest /build/*/*/closure/*
                  }
                  events 2
                  window 1h
              }
          }
          # Based on NixOS/infra s build/hydra-proxy.nix
          @whitelist <<CEL
            path(
                '/build/*/download',
                '/build/*/download-by-type',
                '/job/*/*/*/latest/download',
                '/job/*/*/*/latest/download-by-type'
            ) || remote_ip(
                '127.0.0.0/23',
                '::1'
            )
          CEL
          handle @whitelist {
            reverse_proxy localhost:${toString cfg.port}
          }
          handle {
            reverse_proxy localhost${anubisCfg.settings.BIND}
          }
        '';
      };
      anubis.instances."hydra-server" = {
        settings = {
          TARGET = "http://localhost:${toString cfg.port}";
          BIND = ":13001";
          BIND_NETWORK = "tcp";
        };
      };
    };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
