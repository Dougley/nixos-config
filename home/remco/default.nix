{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    inputs.plasma-manager.homeModules.plasma-manager
    ./easyeffects
    ./plasma.nix
  ];

  home.username = "remco";
  home.homeDirectory = "/home/remco";

  # `, foo` runs any nixpkgs binary without adding it to the profile.
  # It also provides the command-not-found handler.
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  # Zsh and Antidote
  programs.zsh = {
    enable = true;
    enableCompletion = true; # Runs compinit.
    defaultKeymap = "emacs";

    history = {
      size = 10000;
      save = 10000;
      share = true; # Shares and appends history between sessions.
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      saveNoDups = true;
      findNoDups = true;
    };

    # Antidote loads autosuggestions and syntax highlighting below.
    antidote = {
      enable = true;
      useFriendlyNames = true;
      plugins = [
        # Oh My Zsh libraries.
        "ohmyzsh/ohmyzsh path:lib"
        # Oh My Zsh core plugins.
        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/docker"
        "ohmyzsh/ohmyzsh path:plugins/docker-compose"
        "ohmyzsh/ohmyzsh path:plugins/kubectl"
        "ohmyzsh/ohmyzsh path:plugins/sudo"
        "ohmyzsh/ohmyzsh path:plugins/colored-man-pages"
        # nix-index supplies the command-not-found hook.
        # Oh My Zsh infrastructure plugins.
        "ohmyzsh/ohmyzsh path:plugins/helm"
        "ohmyzsh/ohmyzsh path:plugins/terraform"
        "ohmyzsh/ohmyzsh path:plugins/systemd"
        # The 1Password agent owns SSH_AUTH_SOCK.
        # Oh My Zsh productivity plugins.
        # programs.direnv installs its Zsh hook.
        "ohmyzsh/ohmyzsh path:plugins/extract"
        "ohmyzsh/ohmyzsh path:plugins/copyfile"
        "ohmyzsh/ohmyzsh path:plugins/copypath"
        # Essentials.
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
        "zsh-users/zsh-history-substring-search"
        "zsh-users/zsh-completions"
        # belak utilities.
        "belak/zsh-utils path:completion"
        "belak/zsh-utils path:editor"
        "belak/zsh-utils path:history"
      ];
    };

    shellAliases = {
      rebuild = "nh os switch"; # Uses programs.nh.flake and elevates as needed.
      update = "nix flake update --flake ~/nixos-config";
      agents-up = "nix flake update llm-agents --flake ~/nixos-config && nh os switch";

      # eza.
      ls = "eza --icons";
      ll = "eza -lah --icons --git";
      la = "eza -a --icons";
      lt = "eza --tree --level=2 --icons";
      l = "eza -lah --icons --git";

      # bat.
      cat = "bat --style=auto";

      # Navigation; zoxide provides cd below.
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
    };

    # .zshenv runs before .zshrc, so the completion directory exists before
    # Antidote loads the Oh My Zsh completion plugins.
    envExtra = ''
      export ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
      [[ -d "$ZSH_CACHE_DIR/completions" ]] || mkdir -p "$ZSH_CACHE_DIR/completions"
      fpath=($ZSH_CACHE_DIR/completions $fpath)
    '';

    initContent = ''
      # General options; the history block handles history settings.
      setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS CORRECT
      setopt COMPLETE_IN_WORD ALWAYS_TO_END HIST_REDUCE_BLANKS

      # Completion styling.
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' menu select
      zstyle ':completion:*:descriptions' format '%F{green}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

      # History substring search on the arrow keys.
      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      palette = "normal";

      # A dollar sign followed by a letter stays literal in Nix strings.
      # Only ${...} forms interpolate.
      format = ''
        [╭╴](fg:arrow)$username$os$git_branch(at $directory)$cmd_duration(via $python$conda$nodejs$c$rust$java)
        [╰─](fg:arrow)$character'';

      palettes.normal = {
        arrow = "#333533";
        os = "#16f4d0";
        os_admin = "#e4ff1a";
        directory = "#9ffff5";
        time = "#bdfffd";
        node = "#a5e6ba";
        git = "#f17f29";
        git_status = "#DFEBED";
        python = "#edf67d";
        conda = "#70e000";
        java = "#F86279";
        rust = "#ffdac6";
        clang = "#caf0f8";
        duration = "#ce4257";
        text_color = "#EDF2F4";
        text_light = "#26272A";
      };

      username = {
        style_user = "bold os";
        style_root = "bold os_admin";
        format = "[  $user](fg:$style) ";
        disabled = false;
        show_always = true;
      };

      # Set to false to show the NixOS glyph.
      os = {
        format = "on [($name)]($style) ";
        style = "bold blue";
        disabled = true;
        symbols = {
          Alpine = " ";
          Arch = " ";
          Debian = " ";
          EndeavourOS = " ";
          Fedora = " ";
          Linux = " ";
          Macos = " ";
          Manjaro = " ";
          Mint = " ";
          NixOS = " ";
          openSUSE = " ";
          Pop = " ";
          SUSE = " ";
          Ubuntu = " ";
          Windows = " ";
        };
      };

      character = {
        success_symbol = "[󰍟](fg:arrow)";
        error_symbol = "[󰍟](fg:red)";
      };

      directory = {
        format = " ";
        truncation_length = 2;
        style = "fg:directory";
        read_only_style = "fg:directory";
        before_repo_root_style = "fg:directory";
        truncation_symbol = "…/";
        truncate_to_repo = true;
        read_only = "  ";
      };

      time = {
        disabled = true;
        format = "at [󱑈 $time]($style)";
        time_format = "%H:%M";
        style = "bold fg:time";
      };

      cmd_duration = {
        format = "took [ $duration]($style) ";
        style = "bold fg:duration";
        min_time = 500;
      };

      git_branch = {
        format = "via  ";
        style = "bold fg:git";
        symbol = " ";
      };

      git_status = {
        format = "";
        style = "fg:text_color bg:git";
        disabled = true;
      };

      docker_context = {
        disabled = true;
        symbol = " ";
      };

      package.disabled = true;
      fill.symbol = " ";

      # The backslash keeps ${raw} literal for Starship.
      nodejs = {
        format = "";
        style = "bg:node fg:text_light";
        symbol = " ";
        version_format = "\${raw}";
        disabled = false;
      };

      # Indented strings preserve the literal backslashes in this format.
      # ''${ } produces a literal ${ }.
      python = {
        disabled = false;
        format = "";
        symbol = " ";
        version_format = "\${raw}";
        style = "bg:python fg:text_light";
      };

      conda = {
        format = "";
        style = "bg:conda fg:text_light";
        ignore_base = false;
        disabled = false;
        symbol = " ";
      };

      java = {
        format = "";
        style = "bg:java fg:text_light";
        version_format = "\${raw}";
        symbol = " ";
        disabled = true;
      };

      c = {
        format = "";
        style = "bg:clang fg:text_light";
        symbol = " ";
        version_format = "\${raw}";
        disabled = true;
      };

      rust = {
        format = "";
        style = "bg:rust fg:text_light";
        symbol = " ";
        version_format = "\${raw}";
        disabled = true;
      };
    };
  };
  # Ctrl+R opens Atuin's fuzzy history. The arrow keys stay with
  # history-substring-search.
  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
  };

  # The 1Password agent handles SSH identities. Declaring IdentityAgent helps
  # GUI-launched apps such as VS Code's Git integration find it. OpenSSH keeps
  # its built-in defaults alongside this configuration.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      IdentityAgent = ''"~/.1password/agent.sock"'';
    };
  };

  programs.zoxide = {
    enable = true;
    options = [ "--cmd cd" ]; # Provides cd and cdi.
  };

  programs.bat.enable = true;

  # fzf: Ctrl+T files and Alt+C directories
  programs.fzf = {
    enable = true;
    historyWidget.command = ""; # Atuin handles Ctrl+R.
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    fileWidget.command = "fd --type f --hidden --follow --exclude .git";
    changeDirWidget = {
      command = "fd --type d --hidden --follow --exclude .git";
      options = [
        "--preview 'eza --tree --level=2 --icons --color=always {}'"
      ];
    };
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
      "--preview-window 'right:60%:wrap'"
      "--bind 'ctrl-/:toggle-preview'"
      "--bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'"
    ];
    colors = {
      fg = "#d0d0d0";
      bg = "#121212";
      hl = "#5f87af";
      "fg+" = "#d0d0d0";
      "bg+" = "#262626";
      "hl+" = "#5fd7ff";
      info = "#afaf87";
      prompt = "#d7005f";
      pointer = "#af5fff";
      marker = "#87ff00";
      spinner = "#af5fff";
      header = "#87afaf";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Editor and browser
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    # FHS-linked extension binaries can use: package = pkgs.vscode.fhs;
  };

  # The native package enables 1Password browser-to-desktop integration.
  # Store the profile in the XDG config directory.
  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
  };

  # Topgrade: updates the remaining user-managed tools
  # System packages update through `update && rebuild`, and Flatpaks update
  # weekly. Topgrade handles Antidote plugins, the tldr cache, firmware, and
  # similar tools. Check `topgrade --dry-run` after installation and add any
  # declaratively managed tools to the disable list.
  programs.topgrade = {
    enable = true;
    settings = {
      misc = {
        cleanup = true;
        disable = [ ];
      };
    };
  };

  # Git and GPG
  programs.git = {
    enable = true;
    settings = {
      user.name = "Remco";
      user.email = "hey@dougley.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      # 1Password SSH signing settings:
      # gpg.format = "ssh";
      # user.signingKey = "CHANGEME";
      # commit.gpgsign = true;
    };
  };
  programs.gh.enable = true;

  programs.gpg.enable = true;
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-qt;
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
    PNPM_HOME = "$HOME/.local/share/pnpm";
  };
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm/bin"
  ];

  home.packages = with pkgs; [
    # CLI; base.nix supplies ripgrep, fd, jq, and htop
    eza
    ugrep
    dysk
    tealdeer
    trash-cli
    yq
    wl-clipboard # Supplies wl-copy for the fzf binding.

    # Development; devshells pin Node versions
    nodejs_latest
    pnpm
    cmake
    kubectl
    kubernetes-helm

    # Python. The bare interpreter covers ad-hoc scripting; projects go
    # through uv, which owns the venv/lockfile lifecycle:
    #   uv init && uv add <pkg>   # per-project venv + pyproject + uv.lock
    #   uv run <script.py>        # runs inside the project venv
    #   uvx <tool>                # one-off tools, replaces pipx
    #   uv python install 3.12    # extra interpreter versions; the
    #                             # standalone builds run thanks to nix-ld
    # Avoid `pip install` outside a venv; on NixOS it fails by design.
    python3
    uv

    # AI tooling
    # Numtide/llm-agents.nix provides cached, daily-refreshed harnesses.
    # Refresh them with `agents-up`.
    inputs.llm-agents.packages.${stdenv.hostPlatform.system}.claude-code
    inputs.llm-agents.packages.${stdenv.hostPlatform.system}.codex
    inputs.llm-agents.packages.${stdenv.hostPlatform.system}.opencode
    lmstudio
    ramalama

    # Hardware and miscellaneous
    framework-tool
    jetbrains-toolbox
    mangohud
  ];

  # Packages to install separately: bbrew, llmfit, merve, nbytes, and the
  # Bluefin and Framework wallpaper packs. Check `nix search` or `,` first.

  home.stateVersion = "25.11";
}
