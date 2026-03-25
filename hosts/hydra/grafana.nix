{
  lib,
  config,
  hosts,
  ...
}:
let
  domain = "grafana.nixos-cuda.org";
  dbName = "grafana";
  userName = "grafana";
in
{
  systemd.services.grafana.serviceConfig.LoadCredential = [
    "admin_pw:${config.sops.secrets."grafana/admin_pw".path}"
  ];
  sops.secrets."grafana/admin_pw" = {
    owner = "grafana";
    group = "grafana";
    sopsFile = ./secrets-grafana.yaml;
  };

  services = {
    grafana = {
      enable = true;

      settings = {
        # Allow public access
        "auth.anonymous" = {
          enabled = true;
          org_name = "NixOS CUDA";
        };

        security = {
          admin_user = "clanker";
          admin_password = "__file\${/run/credentials/grafana/admin_pw}";
        };

        server = {
          http_port = 3001;

          root_url = "https://${domain}/";
          inherit domain;
          enforce_domain = true;
          enable_gzip = true;
        };

        database = {
          type = "postgres";
          name = dbName;
          host = "/run/postgresql";
          user = userName;
        };
      };
      provision.datasources.settings.datasources = [
        {
          name = "prometheus";
          type = "prometheus";
          url = "http://localhost:${toString config.services.prometheus.port}";
          isDefault = true;
        }
      ];
    };

    # Collect system metrics using prometheus and node exporter
    prometheus = {
      enable = true;

      scrapeConfigs = [
        # Harmonia cache monitoring
        # Not available in the latest release: https://github.com/nix-community/harmonia/issues/631
        {
          job_name = "harmonia";
          static_configs = [
            {
              targets = [ config.services.harmonia.settings.bind ];
            }
          ];
        }
        # Prometheus node exporters
        {
          job_name = "node_exporter";
          scrape_interval = "10s";
          static_configs = [
            {
              targets =
                let
                  mkTarget =
                    hostName: _:
                    let
                      inherit (config.services.prometheus.exporters.node) port;
                    in
                    "${hostName}.nixos-cuda.org:${toString port}";
                in
                lib.mapAttrsToList mkTarget hosts;
            }
          ];
          relabel_configs = [
            # `ada.nixos-cuda.org:9100` -> `ada`
            {
              source_labels = [ "__address__" ];
              target_label = "instance";
              regex = "^([^.]+)\\..*(?::\\d+)?$";
              replacement = "$1";
              action = "replace";
            }
          ];
        }
        {
          job_name = "hydra";
          metrics_path = "/prometheus";
          scheme = "https";
          static_configs = [ { targets = [ "hydra.nixos-cuda.org:443" ]; } ];
        }
        {
          job_name = "hydra_queue_runner";
          metrics_path = "/metrics";
          scheme = "http";
          static_configs = [ { targets = [ "hydra.nixos-cuda.org:9198" ]; } ];
        }
        {
          job_name = "hydra-webserver";
          metrics_path = "/metrics";
          scheme = "https";
          static_configs = [ { targets = [ "hydra.nixos-cuda.org:443" ]; } ];
        }
      ];
    };

    postgresql = {
      ensureDatabases = [ dbName ];
      ensureUsers = [
        {
          name = userName;
          ensureDBOwnership = true;
        }
      ];
    };

    caddy = {
      enable = true;

      virtualHosts.${domain}.extraConfig = ''
        reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
      '';
    };
  };

  # TODO remove
  networking.firewall.allowedTCPPorts = [ config.services.prometheus.port ];
}
