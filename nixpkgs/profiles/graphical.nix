{ config, lib, pkgs, ... }:
with builtins;
with lib;
let cfg = config.profiles.graphical;
in
{
  options.profiles.graphical = {
    enable = mkEnableOption "graphical (X11) profile";
  };
  imports = [ ./graphical ];
  config = mkIf cfg.enable {
    profiles.graphical.x11.enable = true;
  };
}
