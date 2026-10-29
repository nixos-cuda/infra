{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  _hydraBuilder.enable = true;

  # networking.hostId = "ec22951c";

  system.stateVersion = "25.05";
}
