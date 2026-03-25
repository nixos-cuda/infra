{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  branches = [
    "master"
    "release-25.11"
  ];
  serviceName = "sync-nixpkgs-branches";
  helpers = pkgs.lib.getExe inputs.self.packages.${config.nixpkgs.system}.helpers;
  script = lib.concatStringsSep " " (
    [
      helpers

      # channel-updater GitHub app client ID
      "--client-id"
      "Iv23liZJuJFjr3N1KsP0"

      # Path to the channel-updater Github app key file
      "--private-key"
      "$CREDENTIALS_DIRECTORY/github_app_key"

      "sync-branches"

      # nixpkgs fork
      "--repo-full-name"
      "nixos-cuda/nixpkgs"
    ]
    ++ branches
  );
in
{
  systemd.timers.${serviceName} = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/5"; # every 5 minutes
    timerConfig.Unit = "${serviceName}.service";
  };
  systemd.services.${serviceName} = {
    inherit script;
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      LoadCredential = [
        "github_app_key:${config.sops.secrets.channel-updater-github-app-key.path}"
      ];
    };
  };
}
