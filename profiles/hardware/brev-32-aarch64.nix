{ lib, ... }:
{
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
      ];
      kernelModules = [
        "dm-snapshot"
      ];
    };
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = "aarch64-linux";

  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/nvme1n1";
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
        device = "/dev/nvme0n1";
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
}
