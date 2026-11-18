{
  lib,
  isLinux,
  ...
}:
{
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = lib.optionals isLinux [ "systemd" ];

    openFirewall = lib.mkIf isLinux true;
  };
}
