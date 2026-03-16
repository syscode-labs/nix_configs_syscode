# Hardware configuration for spark (Framework laptop)
# Framework laptops typically use:
# - Intel/AMD CPU
# - NVMe storage
# - Intel/AMD integrated graphics

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Framework laptop typical modules
  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ]; # Or "kvm-amd" for AMD version
  boot.extraModulePackages = [ ];

  # Filesystems - UPDATE THESE with actual UUIDs
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/PLACEHOLDER";
    fsType = "vfat";
  };

  # Swap
  # swapDevices = [ { device = "/dev/disk/by-uuid/PLACEHOLDER"; } ];

  # Framework laptop specific
  # For Intel version:
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # For AMD version, use instead:
  # hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Framework display and graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Thunderbolt support
  services.hardware.bolt.enable = true;
}
