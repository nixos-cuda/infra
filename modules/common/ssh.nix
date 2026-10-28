{
  lib,
  pkgs,
  config,
  ...
}:
let
  # Handle both ssh:// and ssh-ng:// remote commands, block anything else
  wrapper-dispatch-ssh-nix =
    let
      wrapCmd =
        cmd: args:
        "exec env NIX_SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt ${lib.getExe' pkgs.nix cmd} ${args}";
    in
    pkgs.writeShellScriptBin "wrapper-dispatch-ssh-nix" ''
      case $SSH_ORIGINAL_COMMAND in
        "nix-daemon --stdio")
          ${wrapCmd "nix-daemon" "--stdio"}
          ;;
        "nix-store --serve --write")
          ${wrapCmd "nix-store" "--serve --write"}
          ;;
        *)
          echo "Access only allowed for using the nix remote builder" 1>&2
          exit 1
      esac
    '';

  # For `nix` user, prevent any usage of any key, except through the wrapper
  ssh-restrict = "restrict,pty,command=\"${lib.getExe wrapper-dispatch-ssh-nix}\"";
in
{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  users.users =
    let
      hydra = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDi1X4YCtWEto02ovI/fsond7hMKPZ0cFYMLkGn9rGtu"
      ];
    in
    {
      nix.openssh.authorizedKeys.keys = map (key: "${ssh-restrict} ${key}") (
        hydra
        ++ (lib.concatMap (
          x: lib.optionals (x.hosts == [ ] || lib.elem config.networking.hostName x.hosts) x.authorizedKeys
        ) (lib.attrValues config.nixos-cuda.users))
      );
    };
}
