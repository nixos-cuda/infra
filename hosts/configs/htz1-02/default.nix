{
  imports = [
    ./disko.nix
    ./hardware.nix
  ];

  networking.hostId = "e1ce6466";

  _hydraBuilder.enable = true;

  system.stateVersion = "25.05";
}
