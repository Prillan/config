{ lib, config, ... }:

with builtins;
with lib;
let cfg = config.profiles.dev;
in
{
  imports = [ ./dev/langs ];
  options.profiles.dev = {
    enable = mkEnableOption "mapping (OSM) applications";
  };

  config = mkIf cfg.enable {
    profiles.dev.langs = {
      python.enabled = true;
      haskell.enabled = true;
      rust.enabled = true;
      nix.enabled = true;
      scala.enabled = true;
      koka.enabled = true;
      java.enabled = true;
      purescript.enabled = true;
    };
  };
}
