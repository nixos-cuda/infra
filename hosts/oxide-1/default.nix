{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  nix.settings = {
    max-jobs = 3;
    cores = 12;
  };

  system.stateVersion = "25.05";
}
