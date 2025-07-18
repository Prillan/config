{ config, lib, pkgs, ... }:

with builtins;
with lib;

let cfg = config.profiles.mapping;
in
{
  options.profiles.mapping = {
    enable = mkEnableOption "mapping (OSM) applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      josm
    ];
  };
}
