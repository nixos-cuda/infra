# All users that are expected to have sudo access must provide hashed
# passwords to be put in user-passwords.yaml. Please generate hash with
# mkpasswd and send it to one of the operators.
# If password is not set, put '!' (with quotes for YAML) instead of the
# hash so that password is disabled for that user.
let
  users = {
    connor = {
      uid = 1001;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXpenPZWADrxK4+6nFmPspmYPPniI3m+3PxAfjbslg+"
      ];
    };
    gaetan = {
      uid = 1002;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEJSonNBBb1DlhaO4EfMh3TbIIsV25phZQ9vp/qKOw9E"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOupOoulINUeCUKLfBllcS1Rulc1LzYnIOITXqEyYaao"
      ];
    };
    serge = {
      uid = 1003;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQBX9vypn+dy8nqtV5cchWes2xB5MqsBVMrtJ6hjX1D"
      ];
    };
    yuriy = {
      uid = 1004;
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINeK+D62nHcQfidm6bKP86RyWUda7pf14H1hABAQPnss"
      ];
    };
  };

  userSchema =
    { name, lib, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "User name as appears on all machines";
        };
        uid = lib.mkOption {
          type = lib.types.int;
          description = "User UID on machines, must not be changed or reused";
        };
        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "List of authorized SSH keys";
        };
        hosts = lib.mkOption {
          type = lib.types.listOf (lib.types.enum (lib.attrNames (import hosts/definitions.nix)));
          default = [ ];
          description = "List of hosts to access, empty to access all hosts";
        };
      };
    };
in
{ lib, ... }:
{
  options.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule userSchema);
  };
  config = { inherit users; };
}
