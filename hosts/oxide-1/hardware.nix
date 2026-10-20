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
        "virtio_pci"
        "virtio_blk"
      ];
      kernelModules = [ ];
    };
    kernelParams = [
      "console=ttyS0,115200n8"
      # Oxide vmm clocksource workaround — see omicron#8001
      "tsc=reliable"
    ];
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
