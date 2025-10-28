{ config, ... }:
{
  sops.secrets.gh-runner-token = { };

  services.github-runners.main = {
    enable = true;
    url = "https://github.com/nixos-cuda";
    tokenFile = config.sops.secrets.gh-runner-token.path;
    replace = true;
    user = "nix";
  };
}
