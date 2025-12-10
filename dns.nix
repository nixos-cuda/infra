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
            githubPagesIps = [
              "185.199.108.153"
              "185.199.109.153"
              "185.199.110.153"
              "185.199.111.153"
            ];
            websiteRecords = map (address: {
              type = "a";
              label = "@";
              inherit address;
            }) githubPagesIps;

            hostRecords = lib.mapAttrsToList (hostname: hostCfg: {
              type = "a";
              label = hostname;
              address = hostCfg.ip;
            }) config.flake.hosts;
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
