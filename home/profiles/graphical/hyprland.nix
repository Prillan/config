{ config, lib, pkgs, catppuccin-palette-src, ... }:
with builtins;
with lib;
let
  cfg = config.profiles.graphical.hyprland;

  palette = fromJSON (readFile "${catppuccin-palette-src}/palette.json");
  c = palette.${config.catppuccin.flavor}.colors;

  # Palette .hex values carry a leading "#", hence the substring.
  raw  = entry: substring 1 6 entry.hex;            # "1e66f5"
  rgba = entry: alpha: "rgba(${raw entry}${alpha})"; # "rgba(1e66f5ff)"

  lockCommand = "${pkgs.hyprlock}/bin/hyprlock";
  grimblast   = "${pkgs.grimblast}/bin/grimblast";

  # One list covers every location: a rule whose output isn't plugged in
  # simply doesn't apply.
  #
  # Desk layout: Asus (1080p) on the left, Samsung (1440p) to its right,
  # bottom edges aligned (the Asus is 360px shorter, hence y=360). The laptop
  # panel lands to the right of the Samsung.
  # Modes are spelled out rather than using highrr/highres: on this pair those
  # keywords resolve inconsistently (highrr picks the Samsung's 1024x768@75.03
  # over 2560x1440@74.998, since it optimises refresh alone).
  #
  # The Samsung is held at 60Hz, not its 75Hz max: UHD 620 cannot drive
  # 2560x1440@75 alongside the Asus at 1920x1080 at all — the second modeset
  # fails its atomic commit and the Asus silently drops to 1680x1050. At the
  # Samsung's 59.951 the Asus gets its full 1920x1080@143.61. Use hypr-solo if
  # you want a single monitor at its own maximum.
  monitorAsus    = "desc:ASUSTek COMPUTER INC VG259 L6LMQS191984, 1920x1080@143.61, 0x360, 1";
  monitorSamsung = "desc:Samsung Electric Company LS27A600U H4ZRC01423, 2560x1440@59.951, 1920x0, 1";
  monitorLaptop  = "eDP-1, preferred, auto-right, 1";

  hyprctlBin = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";

  # `hypr-solo <name-or-description-substring>` blanks every other output;
  # `hypr-solo all` (or any `hyprctl reload`) restores the configured layout.
  hyprSolo = pkgs.writeShellApplication {
    name = "hypr-solo";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      target="''${1:-all}"

      # Always start from the configured layout, so an output that a previous
      # run switched off is back before we decide what to disable.
      ${hyprctlBin} reload >/dev/null
      if [ "$target" = all ]; then
        exit 0
      fi
      sleep 1

      monitors=$(${hyprctlBin} monitors all -j)
      keep=$(jq -r --arg t "$target" '
        [ .[] | select(((.name + " " + .description) | ascii_downcase)
                       | contains($t | ascii_downcase)) ]
        | .[0].name // empty' <<< "$monitors")

      if [ -z "$keep" ]; then
        echo "hypr-solo: no monitor matching '$target'" >&2
        jq -r '.[] | "  \(.name): \(.description)"' <<< "$monitors" >&2
        exit 1
      fi

      for name in $(jq -r '.[].name' <<< "$monitors"); do
        if [ "$name" != "$keep" ]; then
          ${hyprctlBin} keyword monitor "$name, disable" >/dev/null
        fi
      done
    '';
  };

  # Wofi front-end for the above, bound to $mod SHIFT, M.
  hyprSoloPick = pkgs.writeShellApplication {
    name = "hypr-solo-pick";
    runtimeInputs = [ pkgs.jq pkgs.wofi hyprSolo ];
    text = ''
      choice=$( { echo "All monitors";
                  ${hyprctlBin} monitors all -j \
                    | jq -r '.[] | "\(.name): \(.description)"'; } \
                | wofi --dmenu --prompt "Use only" ) || exit 0

      case "$choice" in
        "")             exit 0 ;;
        "All monitors") hypr-solo all ;;
        *)              hypr-solo "''${choice%%:*}" ;;
      esac
    '';
  };

  # Clamshell handling.
  #
  #  * Level-triggered, never edge-triggered. Opening the lid is what wakes the
  #    machine, so the `switch:off` event fires while Hyprland is still frozen
  #    and is simply lost. Read the real lid position instead, and run this from
  #    after_sleep_cmd too so resume always re-converges.
  #  * Only ever disable eDP-1 while some other output is live. Blanking the
  #    sole output leaves Hyprland with zero monitors: it survives (the last
  #    disconnect drops it into an "unsafe state" behind a headless fallback
  #    output) but a headless output is not a screen, so nothing renders, no
  #    modeset happens, and there is no VT to escape to -- the machine looks
  #    dead and only the power button gets you out.
  #
  # That second test is really "am I docked?", which is the only case worth
  # acting on: logind already suspends on an undocked lid close
  # (HandleLidSwitch) and ignores a docked one (HandleLidSwitchDocked=ignore),
  # so there is nothing for us to do when no external output is attached.
  # Hyprland itself has no lid/clamshell setting -- switch binds are the only
  # hook, and hyprlang binds cannot express the conditional.
  hyprLid = pkgs.writeShellApplication {
    name = "hypr-lid";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      # "state:      open" / "state:      closed"
      lidstate=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | head -1)
      others=$(${hyprctlBin} monitors -j | jq '[ .[] | select(.name != "eDP-1") ] | length')

      if [ "''${others:-0}" -gt 0 ]; then
        case "$lidstate" in
          *closed*) ${hyprctlBin} keyword monitor "eDP-1, disable" ; exit 0 ;;
        esac
      fi

      ${hyprctlBin} keyword monitor "${monitorLaptop}"
    '';
  };

in
{
  options.profiles.graphical.hyprland = {
    enable = mkEnableOption "Hyprland graphical profile";
  };

  config = mkIf cfg.enable {
    profiles.graphical.common.enable = true;

    catppuccin.enable = true;
    catppuccin.flavor = "latte";
    catppuccin.accent = "blue";
    catppuccin.cache.enable = true;

    home.packages = [
      pkgs.grimblast
      pkgs.wofi
      pkgs.brightnessctl
      hyprSolo
      hyprLid
      hyprSoloPick
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
        # Specific rules win over the wildcard, so the fallback goes last.
        monitor = [
          monitorAsus
          monitorSamsung
          monitorLaptop
          ", preferred, auto, 1"
        ];
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
            "$mod SHIFT, M, exec, ${hyprSoloPick}/bin/hypr-solo-pick"
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
          ", switch:on:Lid Switch,  exec, ${hyprLid}/bin/hypr-lid"
          ", switch:off:Lid Switch, exec, ${hyprLid}/bin/hypr-lid"
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
          lock_cmd = "pidof hyprlock || ${lockCommand}";
          # Guarded like lock_cmd: unguarded, a lid-close right after an idle
          # lock spawns a second hyprlock that is refused the session lock
          # ("Seems we got yeeten. Is another lockscreen running?") and dies.
          before_sleep_cmd = "pidof hyprlock || ${lockCommand}";
          # hypr-lid here is the safety net for the lost lid-open edge: resume
          # re-derives eDP-1's state from the actual lid position, so the
          # session can never come back with no outputs at all.
          after_sleep_cmd = "hyprctl dispatch dpms on; ${hyprLid}/bin/hypr-lid";
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

    # hypridle runs KillMode=control-group and spawns hyprlock as its own
    # child, so every restart of hypridle — any `home-manager switch`, for one
    # — kills a lock screen that happens to be up. Hyprland then sees its
    # ext-session-lock client die and, per protocol, keeps the session locked
    # forever behind the "lockscreen crashed, switch to a TTY" screen, with
    # nothing left that can authenticate. Kill only hypridle itself.
    systemd.user.services.hypridle.Service.KillMode = "process";

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
  };
}
