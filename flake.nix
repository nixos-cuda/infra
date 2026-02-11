{
  description = "NixOS configuration for nix-community CUDA infrastructure";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11-small";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs.url = "github:serokell/deploy-rs";

    dnscontrol-nix = {
      url = "git+https://codeberg.org/hu5ky/dnscontrol-nix.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./dns.nix
        ./hosts
        inputs.devshell.flakeModule
        inputs.git-hooks-nix.flakeModule
      ];

      perSystem =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        {
          pre-commit.settings.hooks = {
            actionlint.enable = true;
            nixfmt.enable = true;
          };
          devshells.default.packages = [
            pkgs.sops
          ];
          packages = lib.packagesFromDirectoryRecursive {
            inherit (pkgs) callPackage;
            directory = ./packages;
          };
          checks = lib.mapAttrs' (name: lib.nameValuePair "package-${name}") config.packages;
        };
    };
}
