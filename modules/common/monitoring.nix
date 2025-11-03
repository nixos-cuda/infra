{ config, ... }:
{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  networking.firewall.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
  ];
}
