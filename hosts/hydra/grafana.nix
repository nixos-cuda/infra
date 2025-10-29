{ config, ... }:
let
  domain = "grafana.nixos-cuda.org";
in
{
  services = {
    grafana = {
      enable = true;

      settings = {
        # Allow public access
        "auth.anonymous".enabled = true;

        server = {
          http_port = 3001;

          root_url = "https://${domain}";
        };
      };
      provision = {
        enable = true;
        datasources.settings.datasources = [
          {
            name = "prometheus";
            type = "prometheus";
            url = "http://localhost:${toString config.services.prometheus.exporters.node.port}";
          }
        ];
        dashboards = {
        };
      };
    };
    # Collect system metrics using prometheus and node exporter
    prometheus = {
      enable = true;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
        };
      };
      scrapeConfigs = [
        {
          job_name = "node_exporter";
          scrape_interval = "10s";
          static_configs = [
            {
              targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
            }
          ];
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
}
