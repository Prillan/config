{ config, lib, pkgs, ... }:
with builtins;
with lib;

{
  config = mkIf config.profiles.graphical.enable {
    programs.mpv.enable = true;
    home.packages = with pkgs; [
      spotify
    ];
  };
}
