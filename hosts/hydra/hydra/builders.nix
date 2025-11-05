{ lib, config, ... }:
{
  nix = {
    distributedBuilds = true;

    buildMachines =
      let
        mkBuilder =
          name: cfg:
          {
            hostName = "${name}.nixos-cuda.org";
            sshKey = config.sops.secrets.ssh-private-key.path;
            sshUser = "nix";
            system = "x86_64-linux";
            supportedFeatures = [
              "benchmark"
              "big-parallel"
              "kvm"
              "nixos-test"
            ];
          }
          // cfg;

        builders = {
          ########### CPU builders
          atlas = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUhwbG9zNlh0STY1VmVqbEMvdVNwbUF6bjJ4MEloZFIzYTl4d3ZFbWJsN0Igcm9vdEBhdGxhcwo=";
            maxJobs = 10;
            speedFactor = 2;
          };
          oxide-1 = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpPSWlZVThYWnU5NlJoWUZyUnoweVlOUEVnSDUxTTRjRHgrSW1YTHpSeDcgcm9vdEBveGlkZS0xCg==";
            maxJobs = 3;
          };

          ########### GPU builders
          ada = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUp1RjdhSkZydXJUUHBMNjIxZU5mWlkxR2J0cHZhTkxIVlZKcTdKdDZ0YzYgcm9vdEBhZGEK";
            mandatoryFeatures = [ "cuda" ];
            maxJobs = 2;
          };
          pascal = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSURJU0FZMCt3OUFxdW5ZT1pWLy9lT0MwUjVFeEZnZEIzcGpTeHFMYVFsdlAgcm9vdEBwYXNjYWwK";
            maxJobs = 2;
            mandatoryFeatures = [ "cuda-pascal" ];
          };
        };
      in
      lib.mapAttrsToList mkBuilder builders;
  };
}
