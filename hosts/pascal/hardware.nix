{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
      ];
      kernelModules = [
        "vfio"
        "vfio_pci"
      ];
    };
    kernelModules = [
      "kvm-intel"
    ];
    extraModulePackages = [ ];
    blacklistedKernelModules = [ "nouveau" ];
    kernelParams = [
      "intel_iommu=on"
      "snd_hda_core.gpu_bind=0"
      "vfio-pci.ids=${
        lib.concatStringsSep "," [
          "10de:1b80"
          "10de:10f0"
        ]
      }"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
