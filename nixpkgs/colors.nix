{ lib, ... }:
with builtins;

let wal = fromJSON (readFile ./../wal/colors.json);
in {
  options = {
    colors = lib.mkOption {
      type = lib.types.anything;
      default = {
        inherit wal;
        inherit (wal.special) background foreground cursor;
        accent = wal.colors.color1;
        accent-dark = wal.colors.color8;
        icon = wal.colors.color2;
        icon-dark = wal.colors.color9;
      };
    };
  };
}
