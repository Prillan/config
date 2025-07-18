{ config, lib, pkgs, ... }:
with builtins;
with lib;
let cfg = config.profiles.graphical.common;
in
{
  options.profiles.graphical.common = {
    enable = mkEnableOption "common functionality for the graphical profiles";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        dmenu = prev.dmenu.override {
          patches = [
            # NOTE: White space is very important here
            (pkgs.writeText "config.h.wal.patch" ''
              diff --git a/config.def.h b/config.def.h
              index 1edb647..303dd5b 100644
              --- a/config.def.h
              +++ b/config.def.h
              @@ -7,12 +7,9 @@ static const char *fonts[] = {
               	"monospace:size=10"
               };
               static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
              -static const char *colors[SchemeLast][2] = {
              -	/*     fg         bg       */
              -	[SchemeNorm] = { "#bbbbbb", "#222222" },
              -	[SchemeSel] = { "#eeeeee", "#005577" },
              -	[SchemeOut] = { "#000000", "#00ffff" },
              -};
              +
              +#include "${config.colors.wal-dir}/colors-wal-dmenu.h"
              +
               /* -l option; if nonzero, dmenu uses vertical list with given number of lines */
               static unsigned int lines      = 0;
            '')
          ];
        };
      })
    ];

    home.packages = [
      # Window manager, etc.
      pkgs.dmenu
      pkgs.pnmixer

      # "Apps"
      pkgs.discord
      pkgs.evince
      pkgs.tdesktop
      pkgs.thunderbird

      # Fonts
      pkgs.terminus_font
      pkgs.terminus_font_ttf
      pkgs.jetbrains-mono
      pkgs.font-awesome
    ];

    programs.feh.enable = true;
  };
}
