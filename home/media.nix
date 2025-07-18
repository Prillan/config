{ config, lib, pkgs, ... }:
with builtins;
with lib;

{
  config = mkIf config.profiles.graphical.common.enable {
    programs.mpv.enable = true;
    home.packages = with pkgs; [
      spotify
    ];
  };
}
