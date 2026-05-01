{
  lib,
  inputs,
  config,
  ...
}:
{
  perSystem =
    { inputs', ... }:
    {
      devshells.default.packages = [
        inputs'.dnscontrol-nix.packages.default
      ];
    };

  flake.dns = inputs.dnscontrol-nix.lib.buildConfig {
    settings.sops = {
      file = ./.secrets.yaml;
      extractString = "['dns-creds']";
    };
    domains = {
      nixos-cuda = {
        domain = "nixos-cuda.org";
        registrar = "none";
        dnsProvider = "hetzner_v2";

        records =
          let
            # https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site
            githubPages = {
              a = [
                "185.199.108.153"
                "185.199.109.153"
                "185.199.110.153"
                "185.199.111.153"
              ];
              aaaa = [
                "2606:50c0:8000::153"
                "2606:50c0:8001::153"
                "2606:50c0:8002::153"
                "2606:50c0:8003::153"
              ];
            };
            websiteRecords = builtins.concatMap (
              type:
              map (address: {
                label = "@";
                inherit address type;
              }) githubPages.${type}
            ) (builtins.attrNames githubPages);

            inherit (lib) optionals;
            inherit (config.flake) hosts;
            hosts' = map ({ name, value }: value // { hostName = name; }) (lib.attrsToList hosts);
            hostRecords = builtins.concatMap (
              { hostName, ip, ... }@hostCfg:
              [
                {
                  type = "a";
                  label = hostName;
                  address = ip;
                }
              ]
              ++ optionals (hostCfg ? ip6Prefix) [
                {
                  type = "aaaa";
                  label = hostName;
                  address = "${hostCfg.ip6Prefix}::1";
                }
              ]
            ) hosts';
          in
          websiteRecords
          ++ hostRecords
          ++ [
            {
              type = "cname";
              label = "www";
              target = "@";
            }
            {
              type = "cname";
              label = "cache";
              target = "hydra";
            }
            {
              type = "cname";
              label = "grafana";
              target = "hydra";
            }
          ];
      };
    };
  };
}
