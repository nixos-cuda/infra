{ lib, config, ... }:
{
  options.nixos-cuda = lib.mkOption {
    type = lib.types.submodule { imports = [ ../../users.nix ]; };
  };
  config = {
    security.sudo = {
      enable = true;
      execWheelOnly = true;
    };
    services.openssh.authorizedKeysInHomedir = false;
    services.userborn.enable = true;
    sops.secrets = lib.mapAttrs' (
      _: x:
      lib.nameValuePair "user-${x.name}-password" (
        lib.mkIf (x.hosts == [ ] || lib.elem config.networking.hostName x.hosts) {
          sopsFile = ../../user-passwords.yaml;
          key = x.name;
          neededForUsers = true;
        }
      )
    ) config.nixos-cuda.users;

    users = {
      mutableUsers = false;

      users = {
        nix = {
          isNormalUser = true;
          group = "nix";
        };
      }
      // lib.mapAttrs (
        _: x:
        lib.mkIf (x.hosts == [ ] || lib.elem config.networking.hostName x.hosts) {
          isNormalUser = true;
          openssh.authorizedKeys.keys = x.authorizedKeys;
          inherit (x) uid;
          group = "users";
          extraGroups = [ "wheel" ];
          hashedPasswordFile = config.sops.secrets."user-${x.name}-password".path;
        }
      ) config.nixos-cuda.users;
      groups.nix = { };
      groups.users = { };
    };
  };
}
