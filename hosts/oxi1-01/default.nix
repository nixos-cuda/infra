{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  _hydraBuilder.enable = true;

  system.stateVersion = "25.05";
}
