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
      configs = lib.concatMapAttrs (
        name: type:
        if type == "directory" then
          {
            ${name} = ./configs/${name};
          }
        else if type == "regular" then
          {
            ${lib.removeSuffix ".nix" name} = ./configs/${name};
          }
        else
          lib.warn "Ignoring non-regular file hosts/config/${name}" { }
      ) (builtins.readDir ./configs);
      mkNixosConfig =
        hostname: hostCfg:
        (inputs.nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs hosts;
          };
          modules = [
            ../modules/common
            configs.${hostname}
            {
              networking.hostName = hostname;

              nix.settings = rec {
                max-jobs = hostCfg.max-jobs;

                cores = if max-jobs == "auto" then 0 else hostCfg.cores / max-jobs;
              };
            }
          ]
          ++ hostCfg.profiles or [ ];
        });
    in
    {
      nixosConfigurations = lib.mapAttrs mkNixosConfig hosts;
    };
}
