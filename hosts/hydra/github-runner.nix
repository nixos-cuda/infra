# FIXME: Get rid of GitHub(-runner)

{ config, pkgs, ... }:
{
  sops.secrets.gh-runner-token = { };

  services.github-runners.main = {
    enable = true;
    url = "https://github.com/nixos-cuda";
    tokenFile = config.sops.secrets.gh-runner-token.path;
    replace = true;
    user = "nix";
    package = pkgs.github-runner.overrideAttrs (_: {
        # Remediate https://github.com/NixOS/nixpkgs/pull/506237#discussion_r3052699154
        __noChroot = false;
    });
  };
}
