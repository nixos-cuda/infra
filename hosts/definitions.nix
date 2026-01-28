{
  flake.hosts = {

    hydra = {
      ip = "37.27.129.22";
      cores = 16;
      max-jobs = "auto";
    };

    # CPU builders
    oxide-1 = {
      ip = "45.154.216.118";
      cores = 32;
      max-jobs = 4;
      speedFactor = 4;
    };
    atlas = {
      ip = "95.216.20.88";
      cores = 96;
      max-jobs = 10;
      speedFactor = 10;
    };

    # GPU builders
    ada = {
      ip = "144.76.101.55";
      cores = 20;
      max-jobs = 6;
      speedFactor = 4;
    };
    pascal = {
      ip = "95.216.72.164";
      cores = 8;
      max-jobs = 1;
      speedFactor = 2;
    };
  };
}
