{ inputs, ... }:
{
  perSystem =
    {
      system,
      inputs',
      ...
    }:
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
        dnsProvider = "hetzner";

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
          in
          websiteRecords
          ++ [
            # servers
            {
              type = "a";
              label = "ada";
              address = "144.76.101.55";
            }
            {
              type = "a";
              label = "atlas";
              address = "95.216.20.88";
            }
            {
              type = "a";
              label = "hydra";
              address = "37.27.129.22";
            }
            {
              type = "a";
              label = "pascal";
              address = "95.216.72.164";
            }
            {
              type = "a";
              label = "oxide-1";
              address = "45.154.216.118";
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
