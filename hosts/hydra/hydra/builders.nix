{ config, ... }:
{
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

        baseDomain = "nixos-cuda.org";
      in
      [
        ########### CPU builders
        # atlas
        {
          hostName = "atlas.${baseDomain}";
          sshUser = "nix";
          inherit sshKey supportedFeatures system;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUhwbG9zNlh0STY1VmVqbEMvdVNwbUF6bjJ4MEloZFIzYTl4d3ZFbWJsN0Igcm9vdEBhdGxhcwo=";
          maxJobs = 10;
        }
        # oxide-1
        {
          hostName = "45.154.216.118";
          sshUser = "nix";
          inherit sshKey supportedFeatures system;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpPSWlZVThYWnU5NlJoWUZyUnoweVlOUEVnSDUxTTRjRHgrSW1YTHpSeDcgcm9vdEBveGlkZS0xCg==";
          maxJobs = 3;
        }

        ########### GPU builders
        # Ada
        {
          hostName = "ada.${baseDomain}";
          sshUser = "nix";
          inherit sshKey supportedFeatures system;
          # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
          publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUp1RjdhSkZydXJUUHBMNjIxZU5mWlkxR2J0cHZhTkxIVlZKcTdKdDZ0YzYgcm9vdEBhZGEK";
          mandatoryFeatures = [ "cuda" ];
          maxJobs = 2;
        }

        # pascal
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

}
