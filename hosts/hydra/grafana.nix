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
    };

    caddy = {
      enable = true;

      virtualHosts.${domain}.extraConfig = ''
        reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
      '';
    };
  };
}
