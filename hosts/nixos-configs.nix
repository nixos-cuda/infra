{
  lib,
  inputs,
  config,
  ...
}:
{
  flake =
    let
      inherit (config.flake) hosts;
      mkNixosConfig =
        hostname: hostCfg:
        (inputs.nixpkgs.lib.nixosSystem {
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
                max-jobs = hostCfg.max-jobs;

                cores = if max-jobs == "auto" then 0 else hostCfg.cores / max-jobs;
              };
            }
          ];
        });
    in
    {
      nixosConfigurations = lib.mapAttrs mkNixosConfig hosts;
    };
}
