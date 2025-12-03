{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  users.users =
    let
      authorizedKeys = [
        # @GaetanLepage
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJSonNBBb1DlhaO4EfMh3TbIIsV25phZQ9vp/qKOw9E"
      ];
    in
    {
      root.openssh.authorizedKeys.keys = authorizedKeys;

      nix.openssh.authorizedKeys.keys = [
        # Hydra's SSH key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDi1X4YCtWEto02ovI/fsond7hMKPZ0cFYMLkGn9rGtu"

        # @SomeoneSerge
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQBX9vypn+dy8nqtV5cchWes2xB5MqsBVMrtJ6hjX1D"
      ]
      ++ authorizedKeys;
    };
}
