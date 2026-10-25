{
  #############
  # Hetzner 1 #
  #############
  # hydra
  htz1-01 = {
    ip = "37.27.129.22";
    ip6Prefix = "2a01:4f9:3071:1108";
    hwaddr = "04:42:1a:23:df:46";
    cores = 16;
    max-jobs = "auto";
  };
  # AMD EPYC 9454P
  htz1-02 = {
    ip = "95.216.20.88";
    cores = 96;
    max-jobs = 10;
    speedFactor = 10;
  };
  # Ada GPU builder
  htz1-03 = {
    ip = "144.76.101.55";
    cores = 20;
    max-jobs = 6;
    speedFactor = 4;
  };
  # Pascal GPU builder
  htz1-04 = {
    ip = "95.216.72.164";
    cores = 8;
    max-jobs = 1;
    speedFactor = 2;
  };

  #########
  # Oxide #
  #########
  oxi1-01 = {
    ip = "45.154.216.84";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  oxi1-02 = {
    ip = "45.154.216.166";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
}
