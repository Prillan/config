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
      # gnucash
      discord
      libreoffice
      telegram-desktop
      thunderbird
      zoom-us
    ];
  };
}
