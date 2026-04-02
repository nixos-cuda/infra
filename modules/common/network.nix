{ config, lib, ... }:
let
  # No point in relying on the _module.args.hosts fixpoint,
  # but too early to refactor
  resources = import ../../hosts/definitions.nix;
  host = resources.${hostName};
  inherit (config.networking) hostName;
  inherit (lib) optionals mkIf;
in
{
  networking.useNetworkd = true;
  systemd.network.networks = mkIf (host ? hwaddr) {
    "10-wan" = {
      matchConfig.PermanentMACAddress = host.hwaddr;
      address = [
        "${host.ip}/26"
      ]
      ++ optionals (host ? ip6Prefix) [
        "${host.ip6Prefix}::1/64"
      ];
      routes = [
        { Gateway = "fe80::1"; }
      ];
      DHCP = "yes";
    };
  };
}
