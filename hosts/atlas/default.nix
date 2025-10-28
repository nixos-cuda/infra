{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  networking.hostId = "e1ce6466";

  system.stateVersion = "25.05";
}
