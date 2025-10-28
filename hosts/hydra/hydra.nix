# TODO: move to hydra
{ config, ... }:
let
  baseDomain = "nixos-cuda.org";
in
{
  # Public key: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDi1X4YCtWEto02ovI/fsond7hMKPZ0cFYMLkGn9rGtu
  # Used to authenticate to both the CPU builder
  sops.secrets.ssh-private-key.owner = config.users.users.hydra-queue-runner.name;

  nix = {
    distributedBuilds = true;

    buildMachines =
      let
        sshKey = config.sops.secrets.ssh-private-key.path;
        system = "x86_64-linux";
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      in
      # 3 builders:
      # - CPU builder: for building regular derivations (which do not require a GPU)
      # - ada: for most cuda GPU tests
      # - pascal: for cuda-pascal GPU tests (older GPU)
      [
        # CPU builder
        {
          hostName = "atlas.${baseDomain}";
          sshUser = "nix";
          inherit sshKey supportedFeatures system;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUhwbG9zNlh0STY1VmVqbEMvdVNwbUF6bjJ4MEloZFIzYTl4d3ZFbWJsN0Igcm9vdEBhdGxhcwo=";
          maxJobs = 4;
        }

        # Ada
        {
          hostName = "ada.${baseDomain}";
          sshUser = "nix";
          inherit system supportedFeatures;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUp1RjdhSkZydXJUUHBMNjIxZU5mWlkxR2J0cHZhTkxIVlZKcTdKdDZ0YzYgcm9vdEBhZGEK";
          mandatoryFeatures = [ "cuda" ];
          maxJobs = 2;
        }
        # Pascal
        {
          hostName = "pascal.${baseDomain}";
          sshUser = "nix";
          inherit sshKey supportedFeatures system;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUZqVGhLVXhhMDdjbDNtd1pIMnRJeHBDYmVkdG9IcFByK0Ntc1VZS1Z3M3Agcm9vdEBwYXNjYWwK";
          maxJobs = 2;
          mandatoryFeatures = [ "cuda-pascal" ];
        }
      ];
  };

  services =
    let
      hydraURL = "hydra.${baseDomain}";
    in
    {
      hydra = {
        enable = true;

        inherit hydraURL;
        notificationSender = "hydra@${baseDomain}";
        useSubstitutes = true;

        extraConfig = ''
          max_output_size = 4294967296 # 4 << 30 = 4GiB
        '';
      };
      postgresqlBackup.enable = true;

      caddy = {
        enable = true;

        virtualHosts.${hydraURL}.extraConfig = ''
          reverse_proxy localhost:${toString config.services.hydra.port}
        '';
      };
    };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
