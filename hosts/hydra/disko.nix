{
  disko.devices =
    let
      mkZfsDisk = diskId: {
        type = "disk";
        device = "/dev/disk/by-id/${diskId}";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "znix";
              };
            };
          };
        };
      };
    in
    {
      disk = {
        ssd-root = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NF0WB16135";
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02"; # for grub MBR
                attributes = [ 0 ]; # partition attribute
              };
              ESP = {
                type = "EF00";
                size = "1G";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              swap = {
                size = "128G";
                content.type = "swap";
              };
              root = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "zroot";
                };
              };
            };
          };
        };

        hdd1 = mkZfsDisk "ata-ST22000NM002E-3HL113_ZX244XWH";
        hdd2 = mkZfsDisk "ata-ST22000NM002E-3HL113_ZX23Y0KS";
        hdd3 = mkZfsDisk "ata-ST22000NM002E-3HL113_ZX24G8CF";
        hdd4 = mkZfsDisk "ata-ST22000NM002E-3HL113_ZX24KEXX";
        zfs-cache-ssd = mkZfsDisk "nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NF0WB15992";
      };

      zpool = {
        zroot = {
          type = "zpool";
          options = {
            ashift = "12";
          };
          rootFsOptions = {
            acltype = "posixacl";
            compression = "lz4";
            mountpoint = "none";
            xattr = "sa";
            "com.sun:auto-snapshot" = "false";
          };
          datasets.root = {
            type = "zfs_fs";
            mountpoint = "/";
          };
        };

        znix = {
          type = "zpool";

          options = {
            ashift = "12";
          };
          rootFsOptions = {
            compression = "zstd";
          };

          mode.topology = {
            type = "topology";
            vdev = [
              {
                mode = "raidz";
                members = [
                  "hdd1"
                  "hdd2"
                  "hdd3"
                  "hdd4"
                ];
              }
            ];
            cache = [ "zfs-cache-ssd" ];
          };

          datasets.nix = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
        };
      };
    };
}
