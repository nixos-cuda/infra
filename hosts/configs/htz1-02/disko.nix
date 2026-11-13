{
  disko.devices = {
    disk = {
      ssd-root-1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KIOXIA_KCD8XRUG1T92_55U0A0X5TM7J";
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
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
      ssd-root-2 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KIOXIA_KCD8XRUG1T92_55T0A0DQTM7J";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
            swap = {
              size = "64G";
              content.type = "swap";
            };
          };
        };
      };
    };

    zpool.zroot = {
      type = "zpool";
      options = {
        ashift = "12";
      };
      # stripe
      mode = "";
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
  };
}
