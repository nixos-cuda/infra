{ config, ... }:
{
  services = {
    grafana = {
      enable = true;

      settings = {
        server.http_port = 3001;
      };
    };

    caddy = {
      enable = true;

      virtualHosts."grafana.nixos-cuda.org".extraConfig = ''
        reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
      '';
    };
  };
}
