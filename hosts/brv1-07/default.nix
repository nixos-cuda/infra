{
  _brevBuilder = {
    enable = true;

    disks = {
      os = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol02281c101b79bb879";
      nixStore = "/dev/nvme0n1";
    };
  };

  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "25.05";
}
