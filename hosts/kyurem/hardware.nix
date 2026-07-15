# nixos-generate-config usually creates this file. Disko provides the
# fileSystems entries, so this file keeps the kernel modules and firmware.
# Check the generated file during installation and bring over any extra entries.
{ config, lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.enableRedistributableFirmware = true;

  # The framework-13-amd-ai-300-series hardware profile covers amdgpu,
  # the Strix Point kernel floor, MediaTek Wi-Fi details, and fwupd.
  nixpkgs.hostPlatform = "x86_64-linux";
}
