{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.custom;
  colors = rec {
    background = "#222";
    foreground = "#eee";
    highlight = accent;
    linecolor = "#fba922";
    bordercolor = "#333";
    accent = "#e60053";
    icon = "#666";
  };
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
  options.custom = {
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
    defaultMonitor = mkOption {
      type = types.str;
      default = "eDP-1";
      example = "HDMI-1";
      description = ''
        Used to decide where to put polybar.
      '';
    };
  };

  imports = [ ./ctf.nix ./dev.nix ./media.nix ];

  config = {
    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

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
    # fonts.fontconfig.enable = true;
    home.packages = [
      pkgs.locale
      pkgs.glibcLocales

      # Window manager, etc.
      pkgs.pnmixer
      pkgs.xmonad-log # Required by xmonad/polybar

      # "Apps"
      pkgs.discord
      pkgs.evince
      pkgs.tdesktop
      pkgs.thunderbird

      # Writing(?)
      pkgs.ispell

      # Compression
      pkgs.zstd

      # Pandoc
      pkgs.pandoc
      pkgs.wkhtmltopdf

      # Tools
      pkgs.dmenu
      pkgs.graphviz
      pkgs.gopass
      pkgs.haskellPackages.steeloverseer
      pkgs.moreutils
      pkgs.ncdu
      pkgs.nixfmt
      pkgs.python3
      pkgs.ripgrep
      pkgs.tree
      pkgs.up

      # Fonts
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk
      pkgs.noto-fonts-emoji
    ];

    home.sessionVariables = {
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      LOCALE_ARCHIVE_2_31 = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      TERMINFO_DIRS = "$HOME/.nix-profile/share/terminfo:/lib/terminfo";
      SHELL = "${pkgs.zsh}/bin/zsh";
    };

    home.language.base = "en_US.UTF-8";
    home.language.time = "sv_SE.UTF-8";

    programs.gpg = {
      enable = true;
      settings = { default-key = "6A3950D91C1FA0F728D115E73E4C7B34D80F07F7"; };
    };
    programs.autojump.enable = true;
    programs.feh.enable = true;
    programs.htop.enable = true;
    # programs.noti = {
    #   enable = true;
    #   settings = { telegram = import ./semi-secret/telegram.nix; };
    # };
    programs.ssh = {
      enable = true;
      compression = true;
      controlMaster = "yes";
      controlPersist = "30m";
    };
    programs.urxvt = {
      enable = true;
      scroll.bar.enable = false;
      fonts = [ "xft:DejaVu Sans Mono:size=10" ];
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
        e = "emacsclient -c";
        # Watch dir for changes to org files and compile to pdf.
        # TODO: Backup files before starting.
        wpdf =
          "sos . -p '([^#]*).org' -c 'pandoc -f org -t pdf --pdf-engine wkhtmltopdf -i \\0 -o \\1.pdf'";
      };
    };

    services.network-manager-applet.enable = true;
    services.polybar = {
      enable = true;
      config = {
        "colors" = colors;
        "bar/top" = {
          monitor = "\${env:MONITOR:${cfg.defaultMonitor}}";
          width = "100%";
          radius = 0;
          background = colors.background;
          foreground = colors.foreground;
          modules-center = "date";
          modules-left = "xmonad";
          modules-right = "cpu temperature memory network battery xkeyboard";
          # font-0 = "DejaVu Sans Mono:pixelsize=10;1";
          font-0 = "Noto Sans:style=Regular:pixelsize=10;1";
          font-1 = "Noto Sans CJK SC:style=Regular:pixelsize=10;1";
          font-2 = "Noto Emoji:style=Regular:pixelsize=10;1";

          tray-position = "right";
        };
        "module/network" = {
          type = "internal/network";
          interface = cfg.wifiInterface;
          accumulate-stats = "true";
          format-prefix = " | ";
          format-connected = "<label-connected>";
          format-connected-prefix = " | ";
          format-connected-prefix-foreground = colors.icon;
          label-connected = "%downspeed%↓%upspeed%↑";
        };
        "module/xkeyboard" = {
          type = "internal/xkeyboard";
          blacklist-0 = "num lock";
          format-prefix = " | ";
          format-prefix-foreground = colors.icon;
          label-layout = "%layout%";
          label-indicator-padding = "2";
          label-indicator-background = colors.accent;
        };
        "module/battery" = {
          type = "internal/battery";
          # TODO: Fix
          format-prefix = " | ";
          format-prefix-foreground = colors.icon;
        };
        "module/cpu" = {
          type = "internal/cpu";
          label = "%percentage%%";
          format-prefix = " ";
          format-prefix-foreground = colors.icon;
        };
        "module/date" = {
          type = "internal/date";
          internal = 5;
          date = "%Y-%m-%d";
          time = "%H:%M:%S";
          label = "%date% %{F${colors.highlight}}-%{F-} %time%";
        };
        "module/memory" = {
          type = "internal/memory";
          label = "%gb_free% (%percentage_used%%)";
          format-prefix = " | ";
          format-prefix-foreground = colors.icon;
        };
        "module/temperature" = {
          type = "internal/temperature";
          format-prefix = " ";
          format-warn-prefix = " ";
          label-foreground = colors.icon;
          label-warn-foreground = colors.accent;
          units = "true";
          warn-temperature = "75";
        };
        "module/xmonad" = {
          type = "custom/script";
          exec = "${pkgs.xmonad-log}/bin/xmonad-log";
          tail = "true";
        };
      };
      script = "polybar top &";
    };

    xresources.properties = {
      "xterm*faceName" = "DejaVu Sans Mono:size=11";
      "xterm*font" = "7x13";
      "xterm*foreground" = "rgb:aa/aa/aa";
      "xterm*background" = "rgb:05/05/05";
      "URxvt*depth" = 32;
      "URxvt*foreground" = "rgb:aa/aa/aa";
      "URxvt*background" = "rgb:05/05/05/6464";
      "*color0" = "#2E3436";
      "*color8" = "#555753";
      "*color1" = "#a40000";
      "*color9" = "#EF2929";
      "*color2" = "#4E9A06";
      "*color10" = "#8AE234";
      "*color3" = "#C4A000";
      "*color11" = "#FCE94F";
      "*color4" = "#3465A4";
      "*color12" = "#729FCF";
      "*color5" = "#75507B";
      "*color13" = "#AD7FA8";
      "*color6" = "#ce5c00";
      "*color14" = "#fcaf3e";
      "*color7" = "#babdb9";
      "*color15" = "#EEEEEC";

    };
    xsession = {
      enable = true;
      initExtra = ''
        xsetroot -solid black
        # gnome-screensaver &
        pnmixer &
        export GTK_IM_MODULE=fctix
        export XMODIFIERS=@im=fctix
        export QT_IM_MODULE=fctix

        if [ "''${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
            export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        fi

        # ibus-daemon -dx
      '';
      profileExtra = ''
        export PATH="$HOME/.local/bin:$PATH"

      '' + (if !cfg.onNixOS then (''
        if [ -e /home/${config.home.username}/.nix-profile/etc/profile.d/nix.sh ]; then
           . /home/${config.home.username}/.nix-profile/etc/profile.d/nix.sh;
        fi
        # if test -f $XDG_RUNTIME_DIR/gpg-agent-info && kill -0 $(head -n 1 $XDG_RUNTIME_DIR/gpg-agent-info | cut -d: -f2) 2>/dev/null ; then
        #     eval $(< $XDG_RUNTIME_DIR/gpg-agent-info)
        # else
        #     eval $(gpg-agent --daemon --enable-ssh-support --write-env-file $XDG_RUNTIME_DIR/gpg-agent-info)
        # fi
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        export GPG_AGENT_INFO
      '') else
        "");
    };
    xsession.windowManager.xmonad = {
      enable = true;
      config = let
        template = builtins.readFile ./xmonad.hs;
        replaced = builtins.replaceStrings [
          "$$FOREGROUND$$"
          "$$BACKGROUND$$"
          "$$ACCENT$$"
          "$$LINE$$"
          "$$BORDER$$"
          "$$HIGHLIGHT$$"
          "$$ICON$$"
        ] [
          colors.foreground
          colors.background
          colors.accent
          colors.linecolor
          colors.bordercolor
          colors.highlight
          colors.icon
        ] template;
      in builtins.toFile "xmonad.hs" replaced;
      enableContribAndExtras = true;
      extraPackages = haskellPackages: [ haskellPackages.dbus ];
    };
  };
}
