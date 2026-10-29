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

  ########
  # BREV #
  ########
  brv1-01 = {
    ip = "54.235.229.247";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  brv1-02 = {
    ip = "3.88.168.65";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  brv1-03 = {
    ip = "98.84.33.137";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  brv1-04 = {
    ip = "44.192.102.46";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  brv1-05 = {
    ip = "3.81.157.120";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  brv1-06 = {
    ip = "54.210.202.168";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  brv1-07 = {
    ip = "184.72.199.142";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
  brv1-08 = {
    ip = "3.89.64.43";
    cores = 32;
    max-jobs = 2;
    speedFactor = 4;
  };
}
