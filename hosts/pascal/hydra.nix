# TODO: move to hydra
{ config, ... }:
{
  sops.secrets.cpu-builder-ssh-key.sopsFile = ./secrets.yaml;
  nix = {
    distributedBuilds = true;

    buildMachines = [
      {
        hostName = "144.76.101.55";
        sshUser = "nix";
        sshKey = "/etc/ssh/ssh_host_ed25519_key";
        # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUF1WXZqQWhacXpSZ3J1ekxXV2RPbFJaTU1ZMXF3R3ZXTWZmQ3h4THpIYU8gcm9vdEBhZGEK";
        systems = [ "x86_64-linux" ];
        maxJobs = 10;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        mandatoryFeatures = [
          "cuda"
        ];
      }

      # TODO remove
      {
        hostName = "localhost";
        systems = [ "x86_64-linux" ];
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
          "cuda-pascal" # TODO
        ];
        mandatoryFeatures = [
          "cuda"
        ];
      }

      # CPU builder
      {
        hostName = "91.224.148.57";
        sshUser = "nix";
        sshKey = config.sops.secrets.cpu-builder-ssh-key.path;
        # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
        publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUJyc3o4UkttbkNCdWEzQ3djMnRYOEYvYXVBbWNTcjlRcWVMSnRkL0ZLTHMgcm9vdEBuaXhvcwo=";
        systems = [ "x86_64-linux" ];
        maxJobs = 8;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
      }
    ];
  };

  services =
    let
      hydraURL = "hydra-cuda.glepage.com";
    in
    {
      hydra = {
        enable = true;

        inherit hydraURL;
        notificationSender = "hydra@glepage.com";
        useSubstitutes = true;
      };

      caddy = {
        enable = true;

        virtualHosts.${hydraURL}.extraConfig = ''
          reverse_proxy localhost:${toString config.services.hydra.port}
        '';
      };
    };
  networking.firewall.allowedTCPPorts = [
    443
  ];
}
