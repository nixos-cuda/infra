{
  lib,
  inputs,
  self,
  ...
}:
let
  inherit (inputs) deploy-rs;
in
{
  flake = {
    deploy.nodes = lib.mapAttrs (hostname: configuration: {
      hostname = "${hostname}.nixos-cuda.org";
      profiles.system = {
        sshUser = "root";
        user = "root";
        path =
          let
            inherit (configuration.pkgs.stdenv.hostPlatform) system;
          in
          deploy-rs.lib.${system}.activate.nixos configuration;
      };
    }) self.nixosConfigurations;
  };

  perSystem =
    {
      system,
      inputs',
      ...
    }:
    {
      checks = deploy-rs.lib.${system}.deployChecks self.deploy;

      devshells.default.packages = [
        inputs'.deploy-rs.packages.default
      ];
    };
}
