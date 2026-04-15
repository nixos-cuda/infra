{
  inputs,
  config,
  ...
}:
let
  hydraURL = "hydra.nixos-cuda.org";
  githubAppPath = "/github-app";
in
{
  imports = [ inputs.hydra-github-app.nixosModules.default ];

  sops.secrets = {
    hydra-github-app-webhook-secret = { };
    hydra-github-app-private-key = { };
    hydra-github-app-hydra-password = { };
  };

  # Caddy will evaluate handle_path before reverse_proxy, see docs at
  # https://caddyserver.com/docs/caddyfile/directives#directive-order
  services.caddy.virtualHosts.${hydraURL}.extraConfig = ''
    handle_path ${githubAppPath} {
      reverse_proxy ${config.services.hydra-github-app.settings.listen}
    }
  '';
  services.hydra-github-app = {
    enable = true;
    settings = {
      listen = "127.0.0.1:3947";
      user_agent = "nixos-cuda-ci";
      github_app = {
        webhook_secret_file = config.sops.secrets.hydra-github-app-webhook-secret.path;
        app_private_key_file = config.sops.secrets.hydra-github-app-private-key.path;
        app_id = 3166838;
        client_id = "Iv23liR8I9R73IRTYbMw";
      };
      hydra = {
        url = "https://${hydraURL}";
        user = "github_app";
        password_file = config.sops.secrets.hydra-github-app-hydra-password.path;
        project = "github-ci";
      };
      repositories = {
        "nixos-cuda/infra" = {
          check_run_name = "Hydra eval";
          check_per_job = true;
          hydra_jobset_template = {
            description = "triggered by PR {pr_url}";
            flake = "{pr head}";
          };
        };
        "nixos-cuda/nixpkgs" = {
          check_run_name = "CUDA CI check";
          hydra_jobset_template = {
            description = "triggered by PR {pr_url}";
            nixexprinput = "jobsets";
            nixexprpath = "jobsets/nixpkgs-pr.nix";
            inputs = {
              jobsets = {
                type = "git";
                value = "https://github.com/nixos-cuda/hydra-jobsets";
              };
              nixpkgsMerge = {
                type = "pr merge";
              };
              nixpkgs = {
                type = "pr base";
              };
              targetBranch = {
                type = "pr target branch";
              };
            };
          };
        };
      };
    };
  };
}
