{
  _brevBuilder = {
    enable = true;

    disks = {
      os = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol006f09e6e9c078709";
      nixStore = "/dev/nvme0n1";
    };
  };

  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "25.05";
}
