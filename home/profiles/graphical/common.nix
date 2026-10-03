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
    home.packages = [
      pkgs.pnmixer

      # "Apps"
      pkgs.discord
      pkgs.evince
      pkgs.telegram-desktop
      pkgs.thunderbird

      # Fonts
      pkgs.carlito
      pkgs.font-awesome
      pkgs.jetbrains-mono
      pkgs.nerd-fonts.fantasque-sans-mono
      pkgs.noto-fonts
      pkgs.noto-fonts-cjk-sans
      pkgs.noto-fonts-color-emoji
      pkgs.roboto
      pkgs.symbola
      pkgs.terminus_font
      pkgs.terminus_font_ttf
    ];

    programs.feh.enable = true;
  };
}
