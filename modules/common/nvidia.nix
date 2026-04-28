{
  lib,
  pkgs,
  config,
  pkgsCuda,
  ...
}:
let
  cfg = config._nvidia;

  inherit (lib) types;
in
{
  options._nvidia = {
    enable = lib.mkEnableOption "nvidia support for this builder";

    openSourceKernelModules = lib.mkOption {
      type = types.bool;
      description = ''
        Whether to use the open source or proprietary kernel modules
      '';
      example = true;
    };

    cudaCapabilities = lib.mkOption {
      type = with types; listOf str;
    };

    requiredMountsOnFeatures = lib.mkOption {
      type = with types; listOf str;
      default = [ ];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (!cfg.enable) {
      environment.systemPackages = [
        pkgs.btop
      ];
    })

    (lib.mkIf cfg.enable {
      services.xserver.videoDrivers = [ "nvidia" ];
      hardware = {
        graphics.enable = true;
        nvidia.open = cfg.openSourceKernelModules;
      };

      _module.args.pkgsCuda = import pkgs.path {
        inherit (config.nixpkgs.hostPlatform) system;
        config =
          { pkgs, ... }:
          {
            cudaSupport = true;
            inherit (cfg) cudaCapabilities;
            allowUnfreePredicate = pkgs._cuda.lib.allowUnfreeCudaPredicate;
          };
      };

      environment.systemPackages = with pkgsCuda; [
        nvtopPackages.nvidia
        btop
      ];

      programs.nix-required-mounts = {
        enable = true;
        presets.nvidia-gpu.enable = true;
        allowedPatterns.nvidia-gpu.onFeatures = cfg.requiredMountsOnFeatures;
      };

      nixpkgs.config =
        { pkgs, ... }:
        {
          allowUnfreePredicate =
            p:
            builtins.elem (lib.getName p) [
              "nvidia-x11"
              "nvidia-settings"
            ]
            || pkgs._cuda.lib.allowUnfreeCudaPredicate p;
        };
    })
  ];
}
