{ pkgs, inputs, ... }:

{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  services.desktopManager.plasma6.enable = true;

  # Plasma Login Manager handles the display-manager role on Plasma 6.6+.
  # Fingerprint PAM details may need tuning. The SDDM setup is:
  #   services.displayManager.sddm = { enable = true; wayland.enable = true; };
  services.displayManager = {
    plasma-login-manager.enable = true;
  };

  security.pam.services.login.fprintAuth = false;

  # PipeWire with PulseAudio and JACK compatibility.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Steam
  # The native package integrates with drivers, 32-bit libraries, and
  # Gamescope. ProtonPlus can manage Proton-GE at ~/.local/share/Steam.
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
  };

  # GameMode lets games request performance tuning while they run. Add
  # `gamemoderun %command%` to a Steam game's launch options.
  programs.gamemode.enable = true;

  fonts.packages = with pkgs; [
    inter
    jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    source-code-pro
    # Nerd Fonts.
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.caskaydia-mono
    nerd-fonts._0xproto
    nerd-fonts.blex-mono
    nerd-fonts.sauce-code-pro
    nerd-fonts.comic-shanns-mono
    nerd-fonts.droid-sans-mono
    nerd-fonts.go-mono
    nerd-fonts.ubuntu
  ];

  programs.kdeconnect.enable = true;

  # KDE Partition Manager needs a root helper via polkit, so it can't run as
  # a Flatpak. This option installs it natively with the kpmcore helper wired up.
  programs.partition-manager.enable = true;

  # AppImages expect FHS paths. binfmt wires appimage-run in as their kernel
  # interpreter, so AppImages managed by GearLever launch directly.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # These Plasma apps come from Flatpak, keeping the application menu tidy.
  # Konsole stays native.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    gwenview
    okular
    kate
  ];

  # Declarative Flatpaks (nix-flatpak)
  # Rebuilds sync the installed set with this list.
  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    uninstallUnmanaged = true;
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
    packages = [
      # Terminals and system utilities.
      "com.freerdp.FreeRDP"
      "app.drey.Warp"
      "au.stevetech.yafi"
      "com.github.tchx84.Flatseal"
      # EasyEffects is configured through Home Manager with Framework 13
      # speaker presets.
      "com.system76.Popsicle"
      "io.github.flattool.Warehouse"
      "io.github.getnf.embellish"
      "io.github.kolunmi.Bazaar"
      "io.missioncenter.MissionCenter"
      "it.mijorus.gearlever"
      "org.fedoraproject.MediaWriter"
      "org.gnome.Firmware"
      "org.kde.isoimagewriter"

      # Browsers and communication. Firefox comes from Home Manager for
      # 1Password integration.
      "com.google.Chrome"
      "org.chromium.Chromium"
      "dev.vencord.Vesktop"
      "org.kde.neochat"
      "org.kde.tokodon"

      # Container and virtual-machine frontends; the engine is in containers.nix.
      "com.ranfdev.DistroShelf"
      "io.github.DenysMb.Kontainer"
      "org.gnome.Boxes"

      # Media.
      "com.spotify.Client"
      "org.kde.elisa"
      "org.kde.haruna"
      "org.videolan.VLC"
      "org.kde.kasts"
      "org.kde.alligator"
      "org.pipewire.Helvum"
      "io.github.dimtpap.coppwr"

      # Creative and 3D tools.
      "com.orcaslicer.OrcaSlicer"
      "org.blender.Blender"
      "org.freecad.FreeCAD"
      "org.gimp.GIMP"
      "org.kde.kdenlive"
      "org.gnome.gitlab.YaLTeR.VideoTrimmer"
      "io.gitlab.adhami3310.Impression"

      # Gaming; Steam is configured above.
      "com.usebottles.bottles"
      "com.vysp3r.ProtonPlus"
      "io.github.radiolamp.mangojuice"
      "org.prismlauncher.PrismLauncher"
      "org.vinegarhq.Sober"
      "com.unity.UnityHub"
      "org.godotengine.Godot"

      # KDE applications. Loosely mirrored after Fedora.
      "org.kde.okular"
      "org.kde.kate"
      "org.kde.kcalc"
      "org.kde.kcharselect"
      "org.kde.kwalletmanager5"
      "org.kde.filelight"
      "org.kde.kfind"
      "org.kde.kolourpaint"
      "org.kde.kamoso"
      "org.kde.kleopatra"
      "org.kde.kontact"
      "org.kde.merkuro"
      "org.kde.krdc"
      "org.kde.marknote"
      "org.kde.skanpage"
      "org.kde.kmahjongg"
      "org.kde.kmines"
      "org.kde.kpat"

      # Productivity and utilities.
      "org.libreoffice.LibreOffice"
      "io.github.alainm23.planify"
      "me.iepure.devtoolbox"
      "net.werwolv.ImHex"
      "com.reqable.Reqable"
      "com.jeffser.Alpaca"
      "com.rcloneui.RcloneUI"
      "com.rustdesk.RustDesk"
      "org.deskflow.deskflow"
      "org.fkoehler.KTailctl"
      "io.github.nozwock.Packet"
      "io.github.pwr_solaar.solaar"
      "org.gnome.DejaDup"
      "org.qbittorrent.qBittorrent"
    ];
  };
}
