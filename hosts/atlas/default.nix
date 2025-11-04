{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  networking.hostId = "e1ce6466";

  nix.settings = {
    cores = 10;
    max-jobs = 10;
  };

  system.stateVersion = "25.05";
}
