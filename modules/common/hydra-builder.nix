# Hydra build agent.
#
# Since the Rust rewrite, builders are no longer `nix.buildMachines` entries
# driven over SSH by the queue runner: each agent runs `hydra-builder`, dials
# the queue runner's gRPC endpoint itself and builds through its own
# nix-daemon. The queue-runner side of this lives in
# `hosts/hydra/hydra/builders.nix`.
{
  config,
  hosts,
  lib,
  ...
}:
let
  cfg = config._hydraBuilder;

  inherit (config.networking) hostName;
  inherit (lib) types;

  # What every agent advertises, as `nix.buildMachines` used to declare it.
  defaultFeatures = [
    "benchmark"
    "big-parallel"
    "kvm"
    "nixos-test"
  ];
in
{
  imports = [ ../../vendor/hydra/nixos-modules ];

  options._hydraBuilder = {
    enable = lib.mkEnableOption "the Hydra build agent on this builder";

    extraSupportedFeatures = lib.mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "cuda" ];
      description = ''
        Features this agent advertises on top of {var}`defaultFeatures`.

        `services.hydra-builder.settings.supportedFeatures` would default to
        whatever Nix is configured with; we stay explicit instead, so that what
        an agent offers does not change behind our back.
      '';
    };

    mandatoryFeatures = lib.mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "cuda" ];
      description = ''
        Features a step has to request to be scheduled on this agent. Keeps
        GPU builders from being used up by ordinary jobs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # The same static token the queue runner accepts; see
    # hosts/hydra/hydra/builders.nix.
    sops.secrets.queue-runner-token = {
      sopsFile = ../../secrets-queue-runner.yaml;
      owner = "hydra-builder";
    };

    services.hydra-builder = {
      enable = true;

      # Terminated by Caddy on the Hydra host, which proxies to the queue
      # runner's gRPC listener on localhost.
      queueRunnerAddr = "https://queue-runner.nixos-cuda.org";
      authorizationFile = config.sops.secrets.queue-runner-token.path;

      settings = {
        inherit (cfg) mandatoryFeatures;
        inherit (hosts.${hostName}) speedFactor;

        maxJobs = hosts.${hostName}.max-jobs;
        supportedFeatures = defaultFeatures ++ cfg.extraSupportedFeatures;
      };
    };
  };
}
