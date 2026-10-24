{
  lib,
  inputs,
  self,
  config,
  ...
}:
let
  deploy-rs-pkgs = inputs.nixpkgs.lib.genAttrs config.systems (
    system:
    (import inputs.nixpkgs {
      inherit system;
      overlays = [
        inputs.deploy-rs.overlays.default
        (final: prev: {
          deploy-rs = prev.deploy-rs // {
            inherit (inputs.nixpkgs.legacyPackages.${system}) deploy-rs;
          };
        })
      ];
    })
  );
  deploy-rs = {
    packages = builtins.mapAttrs (_: pkgs: { inherit (pkgs.deploy-rs) deploy-rs; }) deploy-rs-pkgs;
    lib = builtins.mapAttrs (_: pkgs: pkgs.deploy-rs.lib) deploy-rs-pkgs;
  };
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
        deploy-rs.packages.${system}.deploy-rs
      ];
    };
}
