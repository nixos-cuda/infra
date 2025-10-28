{ config, ... }:
{
  services = {
    grafana = {
      enable = true;
    };

    caddy = {
      enable = true;

      virtualHosts."grafana.nixos-cuda.org".extraConfig = ''
        reverse_proxy localhost:${toString config.services.grafana.settings.server.http_port}
      '';
    };
  };
}
