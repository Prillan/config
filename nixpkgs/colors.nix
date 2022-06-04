{ config, lib, ... }:
with builtins;

let cfg = config.colors;
    load = f: fromJSON (readFile f);
    wal = load "${cfg.wal-dir}/colors.json";
in {
  options = {
    colors = {
      wal-dir = lib.mkOption {
        description = "Path to directory containing wal-generated files";
        type = lib.types.path;
        default = ../wal;
      };

      wal = lib.mkOption {
        description = "raw wal attrSet";
        type = lib.types.anything;
        default = wal;
      };

      background = lib.mkOption {
        type = lib.types.str;
        default = wal.special.background;
      };
      foreground = lib.mkOption {
        type = lib.types.str;
        default = wal.special.foreground;
      };
      cursor = lib.mkOption {
        type = lib.types.str;
        default = wal.special.cursor;
      };
      accent = lib.mkOption {
        type = lib.types.str;
        default = wal.colors.color1;
      };
      accent-dark = lib.mkOption {
        type = lib.types.str;
        default = wal.colors.color8;
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = wal.colors.color2;
      };
      icon-dark = lib.mkOption {
        type = lib.types.str;
        default = wal.colors.color9;
      };
    };
  };
}
