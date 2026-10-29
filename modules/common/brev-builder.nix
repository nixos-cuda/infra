{
  lib,
  config,
  ...
}:
let
  cfg = config._brevBuilder;
in
{
  options._brevBuilder = {
    enable = lib.mkEnableOption "TODO";
  };

  config = lib.mkIf cfg.enable {

  };
}
