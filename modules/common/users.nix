{
  lib,
  config,
  pkgs,
  isLinux,
  isDarwin,
  ...
}:
let
  userNames = lib.filter (
    name:
    let
      x = config.nixos-cuda.users.${name};
    in
    (x.hosts == [ ] || lib.elem config.networking.hostName x.hosts)
  ) (lib.attrNames config.nixos-cuda.users);
in
{
  options.nixos-cuda = lib.mkOption {
    type = lib.types.submodule { imports = [ ../../users.nix ]; };
  };
  config = lib.mkMerge [
    (lib.optionalAttrs isLinux {
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
        };
        groups.nix = { };
        groups.users = { };
      };
    })
    (lib.optionalAttrs isDarwin {
      users = {
        users.nix = { };
        knownUsers = userNames;
        groups.nix-wheel = {
          gid = 555;
          members = userNames;
        };
        knownGroups = [ "nix-wheel" ];
      };

      security.sudo.extraConfig = ''
        %nix-wheel ALL = NOPASSWD: ALL
      '';
    })
    {
      users = {
        users = lib.genAttrs userNames (
          name:
          let
            user = config.nixos-cuda.users.${name};
          in
          {
            openssh.authorizedKeys.keys = user.authorizedKeys;
            inherit (user) uid;
          }
          // lib.optionalAttrs isLinux {
            isNormalUser = true;
            group = "users";
            extraGroups = [ "wheel" ];
          }
          // lib.optionalAttrs isDarwin {
            createHome = true; # default in NixOS, but not in nix-darwin
            home = "/Users/${name}";
            shell = pkgs.zsh;
          }
        );
      };
    }
  ];
}
