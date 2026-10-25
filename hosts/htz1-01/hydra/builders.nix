# Queue-runner side of the build agents.
#
# Since the Rust rewrite the queue runner no longer drives `nix.buildMachines`
# over SSH: agents run `hydra-builder` (see `modules/hydra-builder.nix`), dial
# the gRPC endpoint below and authenticate with a bearer token.
{
  config,
  ...
}:
let
  queueRunnerURL = "queue-runner.nixos-cuda.org";
in
{
  # A single static token, shared by every agent. The same file is read by the
  # agents themselves, hence the shared secrets file rather than a per-host one.
  sops.secrets.queue-runner-token = {
    sopsFile = ../../../secrets-queue-runner.yaml;
    owner = config.users.users.hydra-queue-runner.name;
  };

  services = {
    hydra.queueRunner.settings.tokenPaths = [ config.sops.secrets.queue-runner-token.path ];

    # The gRPC listener itself stays on localhost; Caddy terminates TLS for it,
    # which is also what the agents' `https://` endpoint expects.
    caddy.virtualHosts.${queueRunnerURL}.extraConfig =
      let
        inherit (config.services.hydra.queueRunner) grpc;
      in
      ''
        reverse_proxy h2c://${grpc.address}:${toString grpc.port} {
          # Agents keep one long-lived HTTP/2 channel open and stream build
          # logs over it, so nothing here may buffer or time out.
          flush_interval -1
        }
      '';
  };
}
