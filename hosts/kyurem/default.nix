{
  inputs,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.lanzaboote.nixosModules.lanzaboote
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    # This module is the 13-inch AI 300 profile:
    # framework/13-inch/amd-ai-300-series.
    inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series

    ./hardware.nix
    ./disko.nix

    ../../modules/base.nix
    ../../modules/desktop.nix
    ../../modules/laptop.nix
    ../../modules/containers.nix
  ];

  networking.hostName = "kyurem";

  # Boot: Lanzaboote (Secure Boot) and systemd initrd
  # Lanzaboote manages the bootloader, so systemd-boot is disabled.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
    bootCounting.initialTries = 3;
  };

  # systemd in the initrd enables TPM2 LUKS unlock.
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."cryptroot".crypttabExtraOpts = [ "tpm2-device=auto" ];
  security.tpm2.enable = true;

  # Latest Linux kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Plymouth and quiet boot
  # The bgrt theme shows the firmware logo and a spinner. A Plasma-themed
  # splash can use:
  #   boot.plymouth.theme = "breeze";
  #   boot.plymouth.themePackages = [ pkgs.kdePackages.breeze-plymouth ];
  boot.plymouth.enable = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "rd.systemd.show_status=auto"
    "rd.udev.log_level=3"
    "resume_offset=533760"
  ];

  # Hibernation (Btrfs swapfile)
  # resume_offset=533760 in boot.kernelParams matches this swapfile. After
  # reinstalling, recalculate it with
  #   sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
  # and update the parameter if needed.
  boot.resumeDevice = "/dev/mapper/cryptroot";

  # Users
  users.users.remco = {
    isNormalUser = true;
    description = "Remco"; # Display name in Plasma and SDDM.
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.zsh;
    # Set a password on first boot with `passwd`. A declarative password can
    # use hashedPassword; the SOPS example below shows the setup.
    initialPassword = "changeme";
  };
  programs.zsh.enable = true;

  # Home Manager module
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.remco = import ../../home/remco;
  };

  # Secrets (sops-nix)
  # secrets/secrets.yaml is encrypted for the editing age key
  # (~/.config/sops/age/keys.txt) and this host's SSH key. sops-nix uses
  # the host key at activation through age.sshKeyPaths. Edit it with
  # `sops secrets/secrets.yaml`. Add another host's age-converted SSH key
  # to .sops.yaml, then run `sops updatekeys secrets/secrets.yaml`.
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  # A small secret at /run/secrets/placeholder confirms the setup is working.
  sops.secrets.placeholder = { };
  # A declarative login password can use this in place of initialPassword:
  #   users.users.remco.hashedPasswordFile = config.sops.secrets."remco-password".path;
  #   sops.secrets."remco-password".neededForUsers = true;
  # Add the mkpasswd hash with: sops set secrets/secrets.yaml \
  #   '["remco-password"]' '"<hash>"'

  # Scrub (Btrfs)
  # Monthly scrubs verify data checksums. / covers every subvolume on this
  # filesystem, including /home.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Snapshots (Snapper)
  services.snapper.configs = {
    root = {
      SUBVOLUME = "/";
      ALLOW_USERS = [ "remco" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 12;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 2;
      TIMELINE_LIMIT_YEARLY = 0;
    };
    home = {
      SUBVOLUME = "/home";
      ALLOW_USERS = [ "remco" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 12;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 2;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  # 1Password
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "remco" ];
  };
  # 1Password checks browser binaries before connecting its extension to the
  # desktop app. This list includes Firefox and the nixpkgs wrapper path.
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      firefox
      .firefox-wrapped
    '';
    mode = "0755";
  };

  # Tailscale
  services.tailscale.enable = true;

  # Keep this value from the original installation.
  system.stateVersion = "25.11";
}
