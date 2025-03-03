{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom;
  zsh-custom-path = let
    patch-script = ''
      function git_prompt_info() { git_super_status }
    '';
    zsh-git-prompt-patch = pkgs.writeTextFile rec {
      name = "git-prompt-patch";
      text = patch-script;
      destination = "/custom/${config.home.username}.zsh";
      executable = true;
    };
  in zsh-git-prompt-patch + "/custom";
in {
  options = {
    custom = {
      # TODO: Clean-up
      onNixOS = mkOption {
        type = types.bool;
        default = true;
        description = "whether on NixOS or not";
      };
      wifiInterface = mkOption {
        type = types.str;
        example = "wlan0";
        description = "for polybar";
      };

      hostname = mkOption {
        type = types.str;
        example = "some-host";
        description = "System hostname, used for backups";
      };
    };
  };

  config = {
    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    nix = {
      package = pkgs.nixStable;
      settings = {
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
      };
      extraOptions = builtins.readFile ../nix.conf;
    };

    nixpkgs.config = {
      allowUnfree = true;
      allowUnfreePredicate = (pkg: true);
    };

    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    home.homeDirectory = "/home/${config.home.username}";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "20.09";

    # Config options:
    # https://rycee.gitlab.io/home-manager/options.html
    fonts.fontconfig.enable = true;
    home.packages = [
      pkgs.locale
      pkgs.glibcLocales

      # Writing(?)
      pkgs.ispell
      (pkgs.hunspellWithDicts (with pkgs.hunspellDicts; [ sv_SE en_US ]))
      (pkgs.texlive.combine {
        inherit (pkgs.texlive) scheme-medium collection-langeuropean;
      })

      # Compression
      pkgs.zstd
      pkgs.zip
      pkgs.unzip

      # Pandoc
      pkgs.pandoc

      # Tools
      # pkgs.cachix
      pkgs.csvtool
      pkgs.dive
      pkgs.graphviz
      pkgs.gopass
      # pkgs.haskellPackages.steeloverseer # BROKEN
      pkgs.moreutils
      pkgs.nix-tree
      pkgs.ncdu
      pkgs.pciutils
      pkgs.python3
      pkgs.ripgrep
      pkgs.tree
      pkgs.units
      pkgs.up
      pkgs.usbutils

      # Fonts
      pkgs.carlito
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-emoji
      pkgs.roboto
      pkgs.symbola
    ] ++ (if cfg.onNixOS then [ pkgs.xclip ] else [ ]);

    home.sessionVariables = {
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      LOCALE_ARCHIVE_2_31 = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      TERMINFO_DIRS = "${pkgs.rxvt-unicode-unwrapped.terminfo}/share/terminfo:/lib/terminfo";
      SHELL = "${pkgs.zsh}/bin/zsh";
    };

    home.language.base = "en_US.UTF-8";
    home.language.time = "sv_SE.UTF-8";

    programs.autojump.enable = true;
    programs.htop.enable = true;
    # programs.noti = {
    #   enable = true;
    #   settings = { telegram = import ./semi-secret/telegram.nix; };
    # };
    programs.ssh = {
      enable = true;
      compression = true;
      controlMaster = "auto";
      controlPersist = "60m";
    };

    programs.zsh = {
      enable = true;
      enableVteIntegration = true;
      oh-my-zsh = {
        enable = true;
        theme = "candy";
        plugins = [ "autojump" ];
        custom = zsh-custom-path;
      };
      initExtra = ''
        unset SSH_AGENT_PID
        if [ "''${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
            export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        fi

        GIT_PROMPT_EXECUTABLE="haskell"
        source ${pkgs.zsh-git-prompt}/share/zsh-git-prompt/zshrc.sh
      '';
      shellAliases = {
        e = "emacsclient -c . &";
        ec = "emacsclient -c";
      };
    };
  };
}
