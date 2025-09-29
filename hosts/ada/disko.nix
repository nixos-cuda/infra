{
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-MTFDKCC1T9TGP-1BK1DABYY_0725109F32C5";
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
            swap = {
              size = "64G";
              content.type = "swap";
            };
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
        device = "/dev/disk/by-id/nvme-MTFDKCC1T9TGP-1BK1DABYY_0725109F32F1";
        content = {
          type = "gpt";
          partitions.nix = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "znix";
            };
          };
        };
      };
    };

    zpool.znix = {
      type = "zpool";
      options = {
        ashift = "9";
      };
      datasets.nix = {
        type = "zfs_fs";
        mountpoint = "/nix";
      };
    };
  };
}
