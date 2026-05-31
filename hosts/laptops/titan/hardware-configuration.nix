{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/313f69ef-cb31-4bd9-8d77-d1ab21ce8e25";
    fsType = "btrfs";
    options = [ "compress=zstd" "subvol=/root" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/313f69ef-cb31-4bd9-8d77-d1ab21ce8e25";
    fsType = "btrfs";
    options = [ "compress=zstd" "subvol=/home" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/12CE-A600";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/32602a39-df97-40fc-b2af-e49849e8af97"; }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
