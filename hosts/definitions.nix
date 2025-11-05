{
  flake.hosts = {

    hydra = {
      cores = 16;
      max-jobs = "auto";
    };

    # CPU builders
    oxide-1 = {
      cores = 32;
      max-jobs = 4;
      speedFactor = 4;
    };
    ada = {
      cores = 20;
      max-jobs = 2;
      speedFactor = 4;
    };

    # GPU builders
    atlas = {
      cores = 96;
      max-jobs = 10;
      speedFactor = 10;
    };
    pascal = {
      cores = 8;
      max-jobs = 1;
      speedFactor = 2;
    };
  };
}
