{ inputs, lib, ... }:
{

  flake =
    let
      mkHost =
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs.inputs = inputs;
          modules = [
            ../common
            ./${hostname}
          ];
        };
    in
    {
      nixosConfigurations = lib.genAttrs [ "ada" "pascal" ] mkHost;
    };
}
