let
  byOxide = "(provided by [Oxide computers](https://oxide.computer))";
  byNvidia = "(provided by [NVIDIA](https://www.nvidia.com))";
in
{
  #############
  # Hetzner 1 #
  #############
  # hydra
  htz1-01 = {
    purpose = "Hydra + binary cache + Grafana";
    ip = "37.27.129.22";
    ip6Prefix = "2a01:4f9:3071:1108";
    hwaddr = "04:42:1a:23:df:46";
    cores = 16;
    max-jobs = "auto";
    profiles = [
      ./configs/htz1-01
    ];
  };
  # AMD EPYC 9454P
  htz1-02 = {
    purpose = "CPU builder (AMD EPYC 9454P)";
    ip = "95.216.20.88";
    cores = 96;
    max-jobs = 10;
    speedFactor = 10;
    profiles = [
      ./configs/htz1-02
    ];
  };
  # Ada GPU builder
  htz1-03 = {
    purpose = "GPU builder";
    ip = "144.76.101.55";
    cores = 20;
    max-jobs = 6;
    speedFactor = 4;
    gpu = {
      name = "RTX 4000 ada (SFF)";
      arch = "Ada Lovelace";
    };
    profiles = [
      ./configs/htz1-03
    ];
  };
  # Pascal GPU builder
  htz1-04 = {
    purpose = "GPU builder";
    ip = "95.216.72.164";
    cores = 8;
    max-jobs = 1;
    speedFactor = 2;
    gpu = {
      name = "GeForce GTX 1080";
      arch = "Pascal";
    };
    profiles = [
      ./configs/htz1-04
    ];
  };

  #########
  # Oxide #
  #########
  oxi1-01 = {
    purpose = "CPU builder ${byOxide}";
    ip = "45.154.216.84";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/oxide-32.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  oxi1-02 = {
    purpose = "CPU builder ${byOxide}";
    ip = "45.154.216.166";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/oxide-32.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };

  #######
  # TTN #
  #######
  ttn1-01 = {
    purpose = "CPU builder";
    ip = null; # public IP not known yet
    cores = 16;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      {
        nixpkgs.system = "aarch64-darwin";
        system.stateVersion = 7;
      }
      ../profiles/hydra-builder.nix
    ];
  };

  ########
  # BREV #
  ########
  brv1-01 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "54.235.229.247";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-x86.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  brv1-02 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "3.88.168.65";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-x86.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  brv1-03 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "98.84.33.137";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-x86.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  brv1-04 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "44.192.102.46";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-x86.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  brv1-05 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "3.81.157.120";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-aarch64.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  brv1-06 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "54.210.202.168";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-aarch64.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  brv1-07 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "184.72.199.142";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-aarch64.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
  brv1-08 = {
    purpose = "CPU builder ${byNvidia}";
    ip = "3.89.64.43";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
    profiles = [
      ../profiles/hardware/brev-32-aarch64.nix
      ../profiles/hydra-builder.nix
      { system.stateVersion = "25.05"; }
    ];
  };
}
