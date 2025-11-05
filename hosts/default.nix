{ inputs, lib, ... }:
{
  imports = [
    ./deploy-rs.nix
  ];

  flake =
    let
      hosts = {
        ada = {
          cores = 20;
          max-jobs = 2;
          speedFactor = 4;
        };
        atlas = {
          cores = 96;
          max-jobs = 10;
          speedFactor = 10;
        };
        pascal = {
          cores = 8;
          max-jobs = 1;
          speedFactor = 2;
        };
        oxide-1 = {
          cores = 32;
          max-jobs = 4;
          speedFactor = 4;
        };
        hydra = {
          cores = 16;
        };
      };

      mkNixosConfig =
        hostname: hostCfg:
        inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs hosts;
          };
          modules = [
            ../modules/common
            ./${hostname}
            {
              networking.hostName = hostname;

              nix.settings = rec {
                max-jobs = hostCfg.nix-settings.max-jobs;

                cores = hostCfg.cores / max-jobs;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = lib.mapAttrs hosts mkNixosConfig;
      inherit hosts;
    };
}
