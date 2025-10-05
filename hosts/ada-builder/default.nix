{ inputs, ... }:
let
  mac = "02:00:00:00:00:01";
in
{
  imports = [
    ../../common
    ../../modules/nvidia.nix
    (inputs."microvm.nix" + "/nixos-modules/microvm")
  ];
  microvm.hypervisor = "cloud-hypervisor";
  microvm.vcpu = 18;
  microvm.hotplugMem = 1024 * 42;
  microvm.hotpluggedMem = 1024 * 2;
  microvm.registerClosure = false;
  microvm.writableStoreOverlay = "/nix/.rw-store";
  microvm.volumes = [
    {
      mountPoint = "/nix"; # Persist both .rw-store/ and var/nix/db/

      # TODO: cf. the zvol comment in pascal-builder
      image = "tmp_store.img"; # TODO: replace with zvol
      size = "64g"; # TODO: replace with zvol
      fsType = "xfs"; # TODO: replace with zvol
    }
  ];
  microvm.shares = [
    # Cf. the fscache/erofs comment in pascal-builder
    {
      mountPoint = "/nix/.ro-store";
      source = "/nix/store";
      proto = "virtiofs";
      readOnly = true;
      tag = "ro-store";
    }
  ];
  microvm.interfaces = [
    {
      type = "tap";
      id = "vt-bldr";
      inherit mac;
    }
  ];
  boot.supportedFilesystems.xfs = true;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-pascal" ];
}
