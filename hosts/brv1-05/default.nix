{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  _hydraBuilder.enable = true;

  # networking.hostId = "";

  system.stateVersion = "25.05";
}
