{
  imports = [
    ./deploy-rs.nix

    # Hosts specifications
    ./definitions.nix

    # Generic provisioning of flake.nixosConfigurations
    ./nixos-configs.nix
  ];
}
