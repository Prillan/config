{ config, lib, pkgs, ... }:
with builtins;
with lib;
let cfg = config.profiles.graphical.x11;
in
{
  options.profiles.graphical.x11 = {
    enable = mkEnableOption "X11 (Xmonad) graphical profile";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.scrot
      pkgs.xclip
      pkgs.xmonad-log # Required by xmonad/polybar
      pkgs.swaylock-effects
    ];

    programs.emacs.package = pkgs.emacs-unstable;
    programs.urxvt = let
      inherit (builtins) concatStringsSep;
      fonts = [ "xft:DejaVu Sans Mono:size=10" "xft:Symbola" ];
      large = [ "xft:DejaVu Sans Mono:size=16" "xft:Symbola" ];
      xlarge = [ "xft:DejaVu Sans Mono:size=24" "xft:Symbola" ];
      set-font = f:
        let fstring = concatStringsSep "," f;
        in "command:\\033]710;${fstring}\\007";
    in {
      enable = true;
      scroll.bar.enable = false;
      fonts = fonts;
      keybindings = {
        "C-plus" = set-font large;
        "C-0" = set-font fonts;
        "C-0x30" = set-font fonts;
      };
    };

    services.network-manager-applet.enable = true;
    services.polybar = {
      enable = true;
      settings = {
        "colors" = config.colors.wal.colors;
        "bar/top" = {
          monitor = "";
          width = "100%";
          radius = 0;
          background = config.colors.background;
          foreground = config.colors.foreground;
          modules = {
            center = "date";
            left = "xmonad";
            right = "cpu temperature memory network battery xkeyboard";
          };
          font = [
            "Noto Sans:style=Regular:pixelsize=10;1"
            "Noto Sans CJK SC:style=Regular:pixelsize=10;1"
            "Noto Emoji:style=Regular:pixelsize=10:scale=12;1"
          ];

          tray.position = "right";
        };
        "module/network" = {
          type = "internal/network";
          interface = config.custom.wifiInterface;
          accumulate-stats = "true";
          format = {
            prefix = " | ";
            connected = "<label-connected>";
            connected-prefix = " | ";
            connected-prefix-foreground = config.colors.icon;
          };
          label.connected = "%downspeed%↓%upspeed%↑";
        };
        "module/xkeyboard" = {
          type = "internal/xkeyboard";
          blacklist."0" = "num lock";
          format = {
            prefix = " | ";
            prefix-foreground = config.colors.icon;
          };
          label = {
            layout = "%layout%";
            indicator = {
              padding = "2";
              background = config.colors.accent;
            };
          };
        };
        "module/battery" = {
          type = "internal/battery";
          full-at = 98;
          format = {
            charging-prefix = " | ";
            charging-prefix-foreground = config.colors.icon;
            discharging-prefix = " | ";
            discharging-prefix-foreground = config.colors.icon;

            full = "<label-full>";
            charging = "<animation-charging> <label-charging>";
            discharging = "<ramp-capacity> <label-discharging>";
          };
          label.full = "%percentage_raw%%";
          ramp = {
            capacity = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
            capacity-0-foreground = config.colors.accent;
            capacity-1-foreground = config.colors.accent;
            capacity-2-foreground = config.colors.accent;
          };
          animation.charging = [ "▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" ];
        };
        "module/cpu" = {
          type = "internal/cpu";
          label = "%percentage%%";
          format = {
            prefix = " ";
            prefix-foreground = config.colors.icon;
          };
        };
        "module/date" = {
          type = "internal/date";
          internal = 5;
          date = "%Y-%m-%d";
          time = "%H:%M:%S";
          label = "%date% %{F${config.colors.icon}}-%{F-} %time%";
        };
        "module/memory" = {
          type = "internal/memory";
          label = "%gb_free% (%percentage_used%%)";
          format = {
            prefix = " | ";
            prefix-foreground = config.colors.icon;
          };
        };
        "module/temperature" = {
          type = "internal/temperature";
          format = {
            prefix = " ";
            warn.prefix = " ";
          };
          label = {
            foreground = config.colors.icon;
            warn.foreground = config.colors.accent;
          };
          units = "true";
          warn.temperature = "75";
        };
        "module/xmonad" = {
          type = "custom/script";
          exec = "${pkgs.xmonad-log}/bin/xmonad-log";
          tail = "true";
        };
      };
      script = "polybar top &";
    };

    xresources = {
      extraConfig = builtins.readFile "${config.colors.wal-dir}/colors.Xresources";
      properties = {
        "xterm*faceName" = "DejaVu Sans Mono:size=11";
        "xterm*font" = "7x13";
      };
    };
    xsession = {
      enable = true;
      initExtra = ''
        xsetroot -solid black
        pnmixer &
        export GTK_IM_MODULE=fctix
        export XMODIFIERS=@im=fctix
        export QT_IM_MODULE=fctix

        if [ "''${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
            export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';
      profileExtra = ''
        export PATH="$HOME/.local/bin:$PATH"

      '' + (if !config.custom.onNixOS then (''
        if [ -e ${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh ]; then
           . ${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh;
        fi
        export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
        export GPG_AGENT_INFO
      '') else
        "");
    };
    xsession.windowManager.xmonad = {
      enable = true;
      config = ../../../dotfiles/xmonad.hs;
      enableContribAndExtras = true;
      extraPackages = haskellPackages: [ haskellPackages.dbus ];
      libFiles = {
        "Colors.hs" = "${config.colors.wal-dir}/colors.hs";
      };
    };
  };
}
