{ inputs, lib, ... }:
{
  imports = [
    ./deploy-rs.nix
  ];

  flake =
    let
      hostnames = [
        "ada"
        "atlas"
        "hydra"
        "oxide-1"
        "pascal"
      ];
      mkHost =
        hostname:
        inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit inputs hostnames;
          };
          modules = [
            ../modules/common
            ./${hostname}
            { networking.hostName = hostname; }
          ];
        };
    in
    {
      nixosConfigurations = lib.genAttrs hostnames mkHost;
    };
}
