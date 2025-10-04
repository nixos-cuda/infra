{
  inputs ? import ./lon.nix,
  nixpkgs ? inputs.nixpkgs,
  pkgs ? import nixpkgs { },
  lib ? pkgs.lib,
}:
{
  hosts =
    let
      root = ./hosts;
      nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
    in
    lib.concatMapAttrs (
      name: typ:
      let
        path = root + "/${name}/default.nix";
        name' = if builtins.pathExists path then name else null;
      in
      {
        ${name'} = nixosSystem {
          specialArgs = {
            inherit inputs;
          };
          modules = [
            path
          ];
        };
      }
    ) (builtins.readDir root);
}
