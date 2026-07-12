{ ... }:

{
  # Firmware updates for the Framework.
  services.fwupd.enable = true;

  # Enroll fingerprints with `fprintd-enroll` after installation.
  # SDDM stays password-based so the greeter and KWallet unlock smoothly.
  # Fingerprints work for sudo and the Plasma lock screen.
  services.fprintd.enable = true;
  security.pam.services.sddm.fprintAuth = false;

  # Closing the lid suspends; battery-powered sleep hibernates after 2 hours.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
  };
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "2h";
  };

  # Power Profiles shows up in Plasma's battery widget. The hardware profile
  # takes care of amd-pstate.
  services.power-profiles-daemon.enable = true;

  # Bluetooth.
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # boltd handles Thunderbolt and USB4 device authorization, including TB4
  # docks and eGPUs.
  services.hardware.bolt.enable = true;

  # Host udev rules let the Solaar Flatpak see Logitech receivers.
  hardware.logitech.wireless.enable = true;
}
