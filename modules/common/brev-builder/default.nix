{
  lib,
  config,
  ...
}:
let
  cfg = config._brevBuilder;
in
{
  imports = [
    ./hardware.nix
    ./disko.nix
  ];

  options._brevBuilder = {
    enable = lib.mkEnableOption "the Brev (AWS EC2) Hydra builder profile";
  };

  config = lib.mkIf cfg.enable {
    _hydraBuilder.enable = true;
  };
}
