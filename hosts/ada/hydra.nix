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
      # - localhost: for most cuda GPU tests
      # - CPU builder: for building regular derivations (which do not require a GPU)
      # - pascal: for cuda-pascal GPU tests (older GPU)
      [
        # localhost
        {
          hostName = "localhost";
          inherit system supportedFeatures;
          mandatoryFeatures = [ "cuda" ];
          maxJobs = 4;
        }

        # CPU builder
        # https://github.com/liberodark/nix-community-builder
        # build02.ynh.ovh
        {
          hostName = "91.224.148.57";
          sshUser = "nix";
          inherit sshKey supportedFeatures system;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUJyc3o4UkttbkNCdWEzQ3djMnRYOEYvYXVBbWNTcjlRcWVMSnRkL0ZLTHMgcm9vdEBuaXhvcwo=";
          maxJobs = 1;
        }

        # Pascal
        {
          hostName = "pascal.${baseDomain}";
          sshUser = "nix";
          inherit sshKey supportedFeatures system;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUZqVGhLVXhhMDdjbDNtd1pIMnRJeHBDYmVkdG9IcFByK0Ntc1VZS1Z3M3Agcm9vdEBwYXNjYWwK";
          maxJobs = 10;
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
