{
  lib,
  config,
  hosts,
  ...
}:
{
  nix = {
    distributedBuilds = true;

    buildMachines =
      let
        defaultFeatures = [
          "benchmark"
          "big-parallel"
          "kvm"
          "nixos-test"
        ];
        mkBuilder =
          name: cfg:
          {
            hostName = "${name}.nixos-cuda.org";
            sshKey = config.sops.secrets.ssh-private-key.path;
            sshUser = "nix";
            system = "x86_64-linux";
            supportedFeatures = defaultFeatures;
            maxJobs = hosts.${name}.max-jobs;
            inherit (hosts.${name}) speedFactor;
          }
          // cfg;

        builders = {
          ########### CPU builders
          atlas = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUhwbG9zNlh0STY1VmVqbEMvdVNwbUF6bjJ4MEloZFIzYTl4d3ZFbWJsN0Igcm9vdEBhdGxhcwo=";
          };
          oxide-1 = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpPSWlZVThYWnU5NlJoWUZyUnoweVlOUEVnSDUxTTRjRHgrSW1YTHpSeDcgcm9vdEBveGlkZS0xCg==";
          };

          ########### GPU builders
          ada = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUp1RjdhSkZydXJUUHBMNjIxZU5mWlkxR2J0cHZhTkxIVlZKcTdKdDZ0YzYgcm9vdEBhZGEK";
            supportedFeatures = defaultFeatures ++ [ "cuda" ];
            # mandatoryFeatures = [ "cuda" ];
          };
          pascal = {
            # base64 -w0 /etc/ssh/ssh_host_ed25519_key.pub
            publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSURJU0FZMCt3OUFxdW5ZT1pWLy9lT0MwUjVFeEZnZEIzcGpTeHFMYVFsdlAgcm9vdEBwYXNjYWwK";
            supportedFeatures = defaultFeatures ++ [ "cuda-pascal" ];
            # mandatoryFeatures = [ "cuda-pascal" ];
          };
        };
      in
      lib.mapAttrsToList mkBuilder builders;
  };
}
