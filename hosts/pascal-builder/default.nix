{ inputs, ... }:
let
  mac = "02:00:00:00:00:01";
in
{
  imports = [
    ../../common
    ../../modules/nvidia.nix
    (inputs."uvms" + "/profiles/vsock-connect-guest.nix")
    # (inputs."microvm.nix" + "/nixos-modules/microvm")
  ];
  microvm.hypervisor = "cloud-hypervisor";
  microvm.registerClosure = false;
  microvm.writableStoreOverlay = "/nix/.rw-store";
  microvm.vcpu = 8;
  microvm.hotplugMem = 1024 * 42;
  microvm.hotpluggedMem = 1024 * 2;
  microvm.volumes = [
    {
      mountPoint = "/nix"; # Persist both .rw-store/ and var/nix/db/

      # TODO: switch to zvol configuration
      # autoCreate = false;
      # image = "/dev/zvol/znix/builder_store";

      # TODO: remove when switching to zvol
      image = "tmp_store.img"; # TODO: replace with zvol
      size = 64 * 1024; # TODO: replace with zvol
      fsType = "xfs"; # TODO: replace with zvol
    }

    # Persist /etc/ssh/ssh_host*_key
    {
      mountPoint = "/etc";
      image = "etc.img";
      size = 32;
    }
  ];
  microvm.shares = [
    # Need to come up with some fscache solution (like styx) to use erofs without paying the build time price
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
  microvm.devices =
    let
      mkPci = id: {
        bus = "pci";
        path = "0000:${id}";
      };
    in
    [
      (mkPci "01:00.0")
      (mkPci "01:00.1")
    ];
  boot.supportedFilesystems.xfs = true;
  programs.nix-required-mounts.allowedPatterns.nvidia-gpu.onFeatures = [ "cuda-pascal" ];

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILQBX9vypn+dy8nqtV5cchWes2xB5MqsBVMrtJ6hjX1D else@x390"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDISAY0+w9AqunYOZV//eOC0R5ExFgdB3pjSxqLaQlvP root@pascal"
  ];

  # GTX 1080
  hardware.nvidia.open = false;
}
