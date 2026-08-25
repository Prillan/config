{ config, lib, pkgs, catppuccin-palette-src, ... }:
with builtins;
with lib;
let
  cfg = config.profiles.graphical.hyprland;

  palette = fromJSON (readFile "${catppuccin-palette-src}/palette.json");
  c = palette.${config.catppuccin.flavor}.colors;

  # Helpers to produce Hyprland color strings (rgba(RRGGBBAA)) and plain hex (#RRGGBB).
  # palette entries have a .hex field with the "#" prefix.
  raw  = entry: substring 1 6 entry.hex;            # "1e66f5"
  rgba = entry: alpha: "rgba(${raw entry}${alpha})"; # "rgba(1e66f5ff)"

  lockCommand = "${pkgs.hyprlock}/bin/hyprlock";
  grimblast   = "${pkgs.grimblast}/bin/grimblast";

in
{
  options.profiles.graphical.hyprland = {
    enable = mkEnableOption "Hyprland graphical profile";
  };

  config = mkIf cfg.enable {
    profiles.graphical.common.enable = true;

    catppuccin.enable = true;
    catppuccin.flavor = "latte";
    catppuccin.accent    = "blue";

    home.packages = [
      pkgs.grimblast
      pkgs.wofi
      pkgs.brightnessctl
    ];

    catppuccin.cursors.enable  = true;
    home.pointerCursor = {
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
    gtk.cursorTheme.size = config.home.pointerCursor.size;
    catppuccin.gtk.icon.enable = true; # Papirus icons with catppuccin folder colours

    # Style GTK3 classic menus (Emacs menu bar, mostly) with the Catppuccin
    # palette. Scoped to menubar/menu/menuitem so it doesn't touch modern
    # GTK apps that use headerbars instead.
    home.file.".config/gtk-3.0/gtk.css".text = ''
      menubar, menu, menuitem {
        font-family: "DejaVu Sans", sans-serif;
        font-size: 10pt;
      }

      menubar {
        background-color: ${c.base.hex};
        color: ${c.text.hex};
        border-bottom: 1px solid ${c.surface0.hex};
      }

      menubar > menuitem {
        background-color: ${c.base.hex};
        color: ${c.text.hex};
        padding: 4px 8px;
      }

      menubar > menuitem:hover,
      menubar > menuitem:active {
        background-color: ${c.surface0.hex};
        color: ${c.text.hex};
      }

      menu {
        background-color: ${c.mantle.hex};
        color: ${c.text.hex};
        border: 1px solid ${c.surface0.hex};
        padding: 4px 0;
      }

      menu > menuitem {
        color: ${c.text.hex};
        padding: 4px 12px;
      }

      menu > menuitem:hover,
      menu > menuitem:active {
        background-color: ${c.blue.hex};
        color: ${c.base.hex};
      }

      menu > separator {
        background-color: ${c.surface1.hex};
        min-height: 1px;
        margin: 4px 0;
      }
    '';

    programs.emacs.package = pkgs.emacs-git-pgtk;
    dev.dotEmacs.extraLines = ''
      (setq catppuccin-flavor '${config.catppuccin.flavor})
      (load-theme 'catppuccin t)

      ;; catppuccin's default magit-diff faces put green/red text on a
      ;; surface1 background — low contrast, especially on latte. Tint the
      ;; background instead and let the foreground fall back to normal text.
      (with-eval-after-load 'magit
        (let* ((green (catppuccin-color 'green))
               (red   (catppuccin-color 'red))
               (text  (catppuccin-color 'text)))
          (custom-set-faces
           `(magit-diff-added             ((t (:background ,(catppuccin-recolor green 75) :foreground ,text :extend t))))
           `(magit-diff-added-highlight   ((t (:background ,(catppuccin-recolor green 60) :foreground ,text :extend t))))
           `(magit-diff-removed           ((t (:background ,(catppuccin-recolor red   75) :foreground ,text :extend t))))
           `(magit-diff-removed-highlight ((t (:background ,(catppuccin-recolor red   60) :foreground ,text :extend t)))))))
    '';

    services.mako.enable = true;
    catppuccin.mako.enable = true;

    programs.kitty = {
      enable = true;
      settings = {
        enable_audio_bell       = false;
        touch_scroll_multiplier = 5;
      };
    };

    catppuccin.kitty.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = true;
      xwayland.enable = true;
      configType = "hyprlang";

      settings = {
        monitor  = ",preferred,auto,1";
        "$mod"   = "SUPER";

        env = [
          "XCURSOR_SIZE,${toString config.home.pointerCursor.size}"
          "XCURSOR_THEME,${config.home.pointerCursor.name}"
          "SDL_VIDEODRIVER,wayland"
          "QT_QPA_PLATFORM,wayland"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          "_JAVA_AWT_WM_NONREPARENTING,1"
        ];

        general = {
          gaps_in       = 5;
          gaps_out      = 10;
          border_size   = 2;
          # Active border: blue → lavender gradient; inactive: surface1
          "col.active_border"   = "${rgba c.blue "ff"} ${rgba c.lavender "ff"} 45deg";
          "col.inactive_border" = rgba c.surface1 "ff";
          layout        = "dwindle";
          allow_tearing = false;
        };

        decoration = {
          rounding         = 8;
          active_opacity   = 1.0;
          inactive_opacity = 0.95;
          blur = {
            enabled  = true;
            size     = 5;
            passes   = 2;
            vibrancy = 0.17;
          };
          shadow = {
            enabled      = true;
            range        = 8;
            render_power = 3;
            color        = "rgba(00000033)";
          };
        };

        animations = {
          enabled = true;
          bezier  = "easeOut, 0.16, 1, 0.3, 1";
          animation = [
            "windows, 1, 5, easeOut, slide"
            "windowsOut, 1, 5, easeOut, slide"
            "border, 1, 10, default"
            "fade, 1, 5, default"
            "workspaces, 1, 5, easeOut, slide"
          ];
        };

        input = {
          kb_layout    = "se";
          follow_mouse = 1;
          sensitivity  = 0;
          touchpad = {
            natural_scroll = false;
            tap-to-click   = true;
            drag_lock      = true;
          };
        };

        gestures.workspace_swipe_touch = true;

        dwindle = {
          preserve_split = true;
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo   = true;
          background_color        = "rgb(${raw c.base})";
        };

        bind =
          [
            "$mod, Return, exec, kitty"
            "$mod, P, exec, ${pkgs.wofi}/bin/wofi --show drun"
            "$mod SHIFT, Q, killactive"
            "$mod SHIFT, E, exit"
            "$mod, F, fullscreen"
            "$mod, Space, togglefloating"
            # Focus
            "$mod, left,  movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up,    movefocus, u"
            "$mod, down,  movefocus, d"
            # Move windows
            "$mod SHIFT, left,  movewindow, l"
            "$mod SHIFT, right, movewindow, r"
            "$mod SHIFT, up,    movewindow, u"
            "$mod SHIFT, down,  movewindow, d"
            # § — move current workspace to next monitor
            "$mod, code:49, movecurrentworkspacetomonitor, +1"
            "$mod SHIFT, Escape, exec, ${lockCommand}"
            # Screenshots
            "$mod, Print, exec, ${grimblast} --notify save active"
            "$mod SHIFT, Print, exec, ${grimblast} --notify save area"
            "$mod MOD1, Print, exec, ${grimblast} --notify save output"
          ]
          ++ map (n: "$mod, ${toString n}, workspace, ${toString n}") (lib.range 1 9)
          ++ map (n: "$mod SHIFT, ${toString n}, movetoworkspace, ${toString n}") (lib.range 1 9)
          ++ [ "$mod, 0, workspace, 10" "$mod SHIFT, 0, movetoworkspace, 10" ];

        binde = [
          "$mod CTRL, left,  resizeactive, -20 0"
          "$mod CTRL, right, resizeactive, 20 0"
          "$mod CTRL, up,    resizeactive, 0 -20"
          "$mod CTRL, down,  resizeactive, 0 20"
        ];

        bindm = [
          "$mod, mouse:272, movewindow"
          "$mod, mouse:273, resizewindow"
        ];

        bindl = [
          ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
          ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%+"
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ", XF86AudioMicMute,     exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ", switch:on:Lid Switch, exec, ${lockCommand}"
        ];
      };

    };

    # catppuccin/nix handles the full hyprlock theme (colors + default layout).
    programs.hyprlock.enable    = true;
    catppuccin.hyprlock.enable  = true;

    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd         = "pidof hyprlock || ${lockCommand}";
          before_sleep_cmd = lockCommand;
          after_sleep_cmd  = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout    = 300;
            on-timeout = "pidof hyprlock || ${lockCommand}";
          }
          {
            timeout    = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on";
          }
        ];
      };
    };

    catppuccin.waybar.enable = true;

    # Chevron modules (custom/arrow1..10, battery#leftarrow,
    # battery#arrow) are still defined in hyprland-config but removed
    # from modules-left/right. To restore the powerline look,
    # re-insert them between adjacent modules.
    programs.waybar = {
      enable = true;
      style = readFile ../../../waybar/hyprland-style-base.css;
      settings = {
        mainBar = fromJSON (readFile ../../../waybar/hyprland-config);
      };
      systemd.enable = true;
    };

    services.kanshi = {
      enable = true;
      settings = [
        {
          profile.name    = "undocked";
          profile.outputs = [{ criteria = "eDP-1"; }];
        }
        {
          profile.name    = "home-docked";
          profile.outputs = [
            {
              criteria = "Samsung Electric Company LS27A600U H4ZRC01423";
              position = "1920,0";
              mode     = "2560x1440";
              status   = "enable";
            }
            {
              criteria = "ASUSTek COMPUTER INC VG259 L6LMQS191984";
              position = "0,0";
              mode     = "1920x1080";
              status   = "enable";
            }
            { criteria = "eDP-1"; }
          ];
        }
      ];
    };
  };
}
