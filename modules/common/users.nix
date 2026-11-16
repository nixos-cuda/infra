{ lib, config, ... }:
{
  options.nixos-cuda = lib.mkOption {
    type = lib.types.submodule { imports = [ ../../users.nix ]; };
  };
  config = {
    security.sudo = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };
    services.openssh.authorizedKeysInHomedir = false;
    services.userborn.enable = true;

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
        }
      ) config.nixos-cuda.users;
      groups.nix = { };
      groups.users = { };
    };
  };
}
