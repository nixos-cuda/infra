{ inputs, ... }:
{
  imports = [
    ../../common
    ./disko.nix
    ./hardware.nix
    (inputs."uvms" + "/profiles/vsock-connect.nix")
    (inputs."microvm.nix" + "/nixos-modules/host")
  ];

  microvm.vms.pascal-builder.specialArgs = {
    inherit inputs;
  };
  microvm.vms.pascal-builder.config = {
    imports = [ ../pascal-builder ];
  };
  microvm.vms.pascal-builder.pkgs = null;

  networking.nat.internalInterfaces = [ "vt-*" ];
  networking.nat.externalInterface = "enp0s31f6";

  # GTX 1080
  hardware.nvidia.open = false;

  networking = {
    hostName = "pascal";
    hostId = "c0a6b9c4";
  };
  system.stateVersion = "25.05";
}
