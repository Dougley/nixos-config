{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
    # nix-community cache for ready-made lanzaboote, nh, and friends.
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://cache.numtide.com" # Ready-made llm-agents.nix harnesses.
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # nh handles rebuilds with diffs and cleans up old generations.
  # Its cleanup timer keeps the requested generations around.
  programs.nh = {
    enable = true;
    flake = "/home/remco/nixos-config";
    clean = {
      enable = true;
      extraArgs = "--keep 5 --keep-since 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Lets FHS binaries run, including pnpm postinstall tools, VS Code
  # extension servers, and JetBrains downloads. Add libraries as needed:
  # run the binary, note the missing library, then find its package
  # with `nix run github:nix-community/nix-index-database -- lib/<name>`.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      openssl
      curl
      icu
    ];
  };

  # nix-index-database supplies the command-not-found handler for Zsh.
  programs.command-not-found.enable = false;

  # Prefer compressed RAM swap and leave the disk swapfile for hibernation.
  zramSwap = {
    enable = true;
    memoryPercent = 25;
    priority = 100;
  };

  # Weekly TRIM reaches the SSD through LUKS discard support in disko.
  services.fstrim.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "nl_NL.UTF-8";
    LC_MONETARY = "nl_NL.UTF-8";
    LC_MEASUREMENT = "nl_NL.UTF-8";
    LC_PAPER = "nl_NL.UTF-8";
  };

  # US English layout with the euro sign on 5. This also covers the console
  # and the LUKS passphrase prompt.
  services.xserver.xkb = {
    layout = "us";
    variant = "euro";
  };
  console.useXkbConfig = true;

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    ripgrep
    fd
    jq
    sbctl # Secure Boot key management.
    sops # Edit secrets/secrets.yaml; recipients are in .sops.yaml.
    age
  ];

  # NetworkManager and Tailscale add the firewall rules they need.
  networking.firewall.enable = true;
}
