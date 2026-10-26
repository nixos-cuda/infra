{
  config,
  lib,
  inputs,
  ...
}:
let
  domain = "gradient.nixos-cuda.org";
  port = 3010;
  serverConfig = config.containers.gradient.config.services;
  workerId = "6169559d-12b1-4aa2-9cb0-345c65ce129e";
  containerSecrets = [
    "gradient-jwt"
    "gradient-crypt"
    "gradient-worker-token"
    "gradient-admin-password"
    "gradient-infra-ssh-key"
    "gradient-cache-main-signing-key"
  ];
  secretMount = name: {
    "/run/secrets/${name}".hostPath = config.sops.secrets.${name}.path;
  };
in
{
  imports = [ inputs.gradient.nixosModules.default ];

  sops = {
    secrets = lib.genAttrs containerSecrets (_: { });
    templates.gradient-worker-peers = {
      content = "*:${config.sops.placeholder.gradient-worker-token}\n";
      owner = "gradient-worker";
    };
  };

  # TODO: currently separate container for testing, later in a microvm
  containers.gradient = {
    autoStart = true;
    bindMounts = lib.mergeAttrsList (map secretMount containerSecrets);

    config =
      { pkgs, ... }:
      {
        imports = [ inputs.gradient.nixosModules.default ];

        services = {
          caddy.enable = lib.mkForce false;
          postgresql = {
            package = pkgs.postgresql_18;
            settings.port = 5433;
          };

          gradient = {
            inherit domain port;

            enable = true;
            postgres.enable = true;
            reverseProxy.caddy.enable = true;
            database.url = "postgresql://gradient@localhost/gradient?host=/run/postgresql&port=5433";
            secrets = {
              jwtFile = "/run/secrets/gradient-jwt";
              cryptFile = "/run/secrets/gradient-crypt";
            };

            state = {
              users.admin = {
                email = "admin@nixos-cuda.org";
                password_file = "/run/secrets/gradient-admin-password";
                superuser = true;
              };

              caches.main = {
                created_by = "admin";
                signing_key_file = "/run/secrets/gradient-cache-main-signing-key";
                projects = [ "infra" ];
                upstream_caches = [
                  {
                    type = "external";
                    display_name = "cache.nixos.org";
                    url = "https://cache.nixos.org";
                    public_key = "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=";
                  }
                  {
                    type = "external";
                    display_name = "cache.nixos-cuda.org";
                    url = "https://cache.nixos-cuda.org";
                    public_key = "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=";
                  }
                ];
              };

              projects.infra = {
                display_name = "Infra";
                created_by = "admin";
                private_key_file = "/run/secrets/gradient-infra-ssh-key";
                teams = [ { team = "core"; } ];
              };

              tasks.master = {
                display_name = "Master";
                project = "infra";
                created_by = "admin";
                repository = "https://github.com/nixos-cuda/infra.git";
                wildcard = "nixosConfigurations.*.config.system.build.toplevel";
                triggers = [
                  {
                    type = "polling";
                    config = {
                      interval_secs = 300;
                      branch = "master";
                    };
                  }
                ];
              };

              teams.core = {
                display_name = "Core";
                new_projects.workers = true;
              };

              workers.${config.networking.hostName} = {
                display_name = config.networking.hostName;
                worker_id = workerId;
                token_file = "/run/secrets/gradient-worker-token";
                team = "core";
              };
            };
          };
        };

        system.stateVersion = "26.05";
      };
  };

  services.caddy.virtualHosts.${domain}.extraConfig =
    serverConfig.caddy.virtualHosts.${domain}.extraConfig;

  services.gradient.worker = {
    enable = true;
    id = workerId;
    serverUrl = "ws://127.0.0.1:${toString port}/proto";
    peersFile = config.sops.templates.gradient-worker-peers.path;

    # Ram / CPU copied from Hydra config
    eval = {
      maxConcurrent = 1;
      maxRss = 4 * 1024 * 1024 * 1024;
      forkWorkers = 12;
      maxMemory = 48 * 1024;
    };
  };
}
