{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  networking.hostId = "e1ce6466";

  nix.settings = {
    cores = 24;
  };

  system.stateVersion = "25.05";
}
