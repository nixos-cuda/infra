{
  lib,
  config,
  ...
}:
let
  cfg = config._brevBuilder;
in
{
  options._brevBuilder.disks = {
    os = lib.mkOption {
      type = lib.types.str;
      example = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0123456789abcdef0";
      description = ''
        Device holding the ESP (`/boot`) and the root filesystem (`/`).
      '';
    };
    nixStore = lib.mkOption {
      type = lib.types.str;
      example = "/dev/nvme1n1";
      description = ''
        Device entirely dedicated to `/nix`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    disko.devices = {
      disk = {
        ssd = {
          type = "disk";
          device = cfg.disks.os;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                type = "EF00";
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              # No swap
              root = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };
          };
        };

        nix = {
          type = "disk";
          device = cfg.disks.nixStore;
          content = {
            type = "gpt";
            partitions.nix = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
              };
            };
          };
        };
      };
    };
  };
}
