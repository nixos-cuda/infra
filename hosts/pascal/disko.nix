{
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_1707191CB464";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
              attributes = [ 0 ]; # partition attribute
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
        device = "/dev/disk/by-id/ata-Micron_1100_MTFDDAK512TBN_1707191CB452";
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
      rootFsOptions = {
        acltype = "posixacl";
        xattr = "sa";
      };
      datasets.nix = {
        type = "zfs_fs";
        mountpoint = "/nix";
      };
    };
  };
}
