{
  _brevBuilder = {
    enable = true;

    disks = {
      os = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0c7d8079ca2a5c7b2";
      nixStore = "/dev/nvme1n1";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
