{
  _brevBuilder = {
    enable = true;

    disks = {
      os = "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol0144e67ae9364b3b0";
      nixStore = "/dev/nvme1n1";
    };
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "25.05";
}
