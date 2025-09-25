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
        # TODO: insert hydra's key
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFjThKUxa07cl3mwZH2tIxpCbedtoHpPr+CmsUYKVw3p root@pascal"
      ]
      ++ authorizedKeys;
    };
}
