{ config, lib, ... }:
with builtins;
with lib;

let cfg = config.colors;
in {
  options.colors = {
    background = mkOption {
      type = types.str;
      default = "#222";
    };
    foreground = mkOption {
      type = types.str;
      default = "#eee";
    };
    highlight = mkOption {
      type = types.str;
      default = cfg.accent;
    };
    linecolor = mkOption {
      type = types.str;
      default = "#fba922";
    };
    bordercolor = mkOption {
      type = types.str;
      default = "#333";
    };
    accent = mkOption {
      type = types.str;
      default = "#e60053";
    };
    icon = mkOption {
      type = types.str;
      default = "#666";
    };
  };
}
