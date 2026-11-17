{
  _brevBuilder = {
    enable = true;

    disks = {
      os = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0e365e1c412b3e7b2";
      nixStore = "/dev/nvme0n1";
    };
  };

  nixpkgs.system = "aarch64-linux";

  system.stateVersion = "25.05";
}
