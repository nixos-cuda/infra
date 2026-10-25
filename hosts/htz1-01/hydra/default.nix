# TODO: move to hydra
{
  config,
  ...
}:
let
  baseDomain = "nixos-cuda.org";
  cfg = config.services.hydra;
  anubisCfg = config.services.anubis.instances."hydra-server";
in
{
  imports = [
    # Hydra's Rust rewrite, vendored from NixOS/nixpkgs#563797 until it lands
    # in our nixpkgs channel.
    ../../../vendor/hydra/nixos-modules

    ./builders.nix
    ./channels.nix
  ];

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

        queueRunner.settings = {
          # CUDA-enabled builds are getting painfully large...
          maxOutputSize = 17179869184; # 16 << 30 = 16GiB

          # The default ("Static") ignores what an agent reports as its job
          # limit, which is how `nix.buildMachines` used to schedule; keep
          # honouring the per-agent `maxJobs` from modules/hydra-builder.nix.
          machineFreeFn = "DynamicWithMaxJobLimit";

          # An agent that reconnects briefly stops advertising its system, and
          # with the 120s default we would abort perfectly buildable steps as
          # unsupported. Only `ada` can take `cuda` steps, so a short restart
          # there would otherwise throw away the whole CUDA queue.
          # Cf. https://github.com/NixOS/hydra/issues/1805.
          maxUnsupportedTimeInS = 86400;
        };

        extraConfig = ''
          # Used by the cuda-packages exhaustive jobset
          allow_import_from_derivation = true

          # Defaults to bzip2.
          # Note that CNO Hydra sets `compress_build_logs = false`
          # and `upload_logs_to_binary_cache = true` instead.
          compress_build_logs_compression = zstd

          evaluator_workers = 12
          evaluator_max_memory_size = 4096

          # Makes the build page tail live logs from `hydra-ws` instead of
          # waiting for the finished log file. Routed below.
          ws_endpoint = wss://${hydraURL}/ws
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
          # Live build logs from `hydra-ws`. A named matcher, so that Caddy
          # keeps this ahead of the @whitelist branch below instead of
          # reordering it by path specificity; the matcher-less `handle` at
          # the end still sorts last.
          @ws path /ws
          handle @ws {
            reverse_proxy ${cfg.ws.bind.address}:${toString cfg.ws.bind.port}
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
            ) ||  header({'Accept': 'application/json', 'User-Agent': 'YorikSar-test-repo-webhook-testing'})
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
