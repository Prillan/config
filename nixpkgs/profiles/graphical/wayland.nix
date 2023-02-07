{ config, lib, pkgs, ... }:
with builtins;
with lib;
let cfg = config.profiles.graphical.wayland;
    lockCommand = "${pkgs.swaylock-effects}/bin/swaylock -S --clock --effect-pixelate 10 --effect-blur 10x10 -k";
    inherit (pkgs.sway-contrib) grimshot;
in
{
  options.profiles.graphical.wayland = {
    enable = mkEnableOption "wayland (Sway) graphical profile";
  };

  config = mkIf cfg.enable {
    profiles.graphical.common.enable = true;

    home.packages = [
      grimshot
    ];

    programs.emacs.package = pkgs.emacsPgtk;
    programs.mako.enable = true;
    programs.kitty = {
      enable = true;
      extraConfig = readFile "${config.colors.wal-dir}/colors-kitty.conf";
      settings = {
        enable_audio_bell = false;
        touch_scroll_multiplier = 5;
      };
    };
    wayland.windowManager.sway = {
      enable = true;
      config = {
        modifier = "Mod4";
        terminal = "kitty";
        bars = []; # Handled by waybar instead.
        keybindings =
          let modifier = config.wayland.windowManager.sway.config.modifier;
              grimshot-cmd = "${grimshot}/bin/grimshot --notify";
          in lib.mkOptionDefault {
            "${modifier}+p" = "exec ${pkgs.dmenu}/bin/dmenu_path | ${pkgs.dmenu}/bin/dmenu | ${pkgs.findutils}/bin/xargs swaymsg exec --";
            "${modifier}+Shift+l" = "exec ${lockCommand}";

            "${modifier}+Print" = "exec ${grimshot-cmd} save active";
            "${modifier}+Shift+Print" = "exec ${grimshot-cmd} save area";
            "${modifier}+Mod1+Print" = "exec ${grimshot-cmd} save output";
            "${modifier}+Ctrl+Print" = "exec ${grimshot-cmd} save window";
          };
        input = {
          "*" = {
            xkb_layout = "se";
          };
          "type:touchpad" = {
            dwt = "enabled";
            tap = "enabled";
            tap_button_map = "lmr";
          };
        };
      };
      extraConfig = lib.mkMerge [
        (readFile "${config.colors.wal-dir}/colors-sway")
        ''
        bindsym --locked XF86MonBrightnessDown exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-
        bindsym --locked XF86MonBrightnessUp exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+
        ''
      ];
      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        # needs qt5.qtwayland in systemPackages
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
        # Fix for some Java AWT applications (e.g. Android Studio),
        # use this if they aren't displayed properly:
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };
    programs.waybar = {
      enable = true;
      style = readFile ../../../waybar/style.css;
      settings = {
        mainBar = builtins.fromJSON (readFile ../../../waybar/config);
      };
      systemd.enable = true;
    };

    services.swayidle.enable = true;
    services.swayidle.events = [
      { event = "before-sleep"; command = lockCommand; }
      { event = "lock"; command = lockCommand; }
    ];
    services.swayidle.timeouts = [
      { timeout = 600; command = "swaymsg 'output * dpms off'"; resumeCommand = "swaymsg 'output * dpms on'"; }
    ];
    services.kanshi = {
      enable = true;
      profiles = {
        undocked = {
          outputs = [
            {
              criteria = "eDP-1";
            }
          ];
        };
      };
    };
  };
}