{
  lib,
  inputs,
  config,
  ...
}:
{
  flake =
    let
      # Aside from the memoization issues with the fixpoint,
      # cf. https://github.com/NixOS/nixpkgs/pull/349163#issuecomment-2421774237
      # for a discussion on why wrapping `eval-config.nix` for extending `_module.args`
      # or any `baseModules` like that is not a good pattern in case of NixOS specifically
      # (nothing to say of other applications of `evalModules`).
      # Instead one may e.g. prepare a module with the "defaults" that can be explicitly put in `imports`.
      inherit (config.flake) hosts;

      modulesPath = "${inputs.nixpkgs}/nixos/modules";
      hostSystems = lib.mapAttrs (
        _: hostCfg:
        (lib.evalModules {
          modules = hostCfg.profiles ++ [
            { _module.check = false; }
            "${modulesPath}/misc/nixpkgs.nix"
          ];
          specialArgs = {
            inherit inputs modulesPath;
          };
        }).config.nixpkgs.localSystem
      ) hosts;

      mkNixosConfig =
        hostname: hostCfg:
        (inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs hosts;
          };
          modules = [
            ../modules/common
            {
              networking.hostName = hostname;

              nix.settings = rec {
                max-jobs = hostCfg.max-jobs;

                cores = if max-jobs == "auto" then 0 else hostCfg.cores / max-jobs;
              };
            }
          ]
          ++ hostCfg.profiles;
        });

      mkDarwinConfig =
        hostname: hostCfg:
        (inputs.nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit inputs hosts;
          };
          modules = [
            ../modules/common
            {
              networking.hostName = hostname;

              nix.settings = rec {
                max-jobs = hostCfg.max-jobs;

                cores = if max-jobs == "auto" then 0 else hostCfg.cores / max-jobs;
              };
            }
          ]
          ++ hostCfg.profiles;
        });

      filterSystemAndMapConfig =
        pred: mkConfig:
        lib.concatMapAttrs (
          hostname: system:
          lib.optionalAttrs (pred system) {
            ${hostname} = mkConfig hostname hosts.${hostname};
          }
        ) hostSystems;
    in
    {
      nixosConfigurations = filterSystemAndMapConfig (system: system.isLinux) mkNixosConfig;
      darwinConfigurations = filterSystemAndMapConfig (system: system.isDarwin) mkDarwinConfig;
    };
}
