{ config, lib, pkgs, ... }:

with builtins;
with lib;

let cfg = config.profiles.fluff;
in
{
  options.profiles.fluff = {
    enable = mkEnableOption "fluff applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      gnucash
      libreoffice
      zoom-us
    ];
  };
}
