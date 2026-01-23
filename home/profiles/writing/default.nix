{ lib, config, pkgs, ... }:
with builtins;
with lib;
let cfg = config.profiles.writing;
in
{
  options.profiles.writing = {
    enable = mkEnableOption "writing with LaTeX etc.";
  };

  config = mkIf cfg.enable {
    home.packages = [
      (pkgs.texlive.combine {
        inherit (pkgs.texlive) scheme-medium collection-langeuropean;
      })
    ];
    programs.emacs.extraPackages = epkgs: [
      # Latex
      epkgs.auctex
    ];
  };
}
