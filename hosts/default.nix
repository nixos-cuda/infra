{
  imports = [
    ./deploy-rs.nix

    # Generic provisioning of flake.nixosConfigurations
    ./nixos-configs.nix
    {
      # "Resources", more or less. Names `flake.hosts` and `definitions`
      # are kept for compatibility. By lifting the `flake.hosts` prefix up here,
      # we make the file is usable as plain data and as a NixOS module. We also lose
      # the dependency on the fixpoint.
      flake.hosts = import ./definitions.nix;

      # In case you wish inspect `options,` or for error messages
      _file = "hosts/definitions.nix";
    }
  ];
}
