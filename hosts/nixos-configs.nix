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
