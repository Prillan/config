{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dev;
    emacsPiper = pkgs.callPackage (import ./pkgs/piper.nix) {};
in {
  options.dev = {
    dotEmacs = mkOption {
      description = "submodule example";
      type = types.submodule {
        options = {
          extraLines = mkOption {
            description = "extra lines to put in .emacs";
            type = types.lines;
            default = "";
          };
        };
      };
      default = { };
    };
  };

  config = {
    programs.jq.enable = true;

    home.packages = [
      ## Scala
      pkgs.lombok
      pkgs.metals
      pkgs.sbt

      pkgs.binutils
      pkgs.git-crypt
      pkgs.kafkacat
      pkgs.ncdu
    ];

    home.file.".emacs".text = let
      base = builtins.readFile ./../dotfiles/emacs;
      extra = cfg.dotEmacs.extraLines;
    in ''
      (setq -piper-load-path "${emacsPiper}")
      ${base}
      ;; Lines from dev.dotEmacs.extraLines
      ${extra}
    '';

    programs.emacs = {
      enable = true;
      extraPackages = epkgs: [
        # Auto-complete
        epkgs.company-lsp
        epkgs.flycheck

        # Searching
        epkgs.ag
        epkgs.helm-ag

        # Latex
        # epkgs.auctex 404???

        # Modes
        epkgs.company-terraform
        epkgs.dockerfile-mode
        epkgs.haskell-mode
        epkgs.groovy-mode
        epkgs.lsp-mode
        epkgs.lsp-ui
        epkgs.lsp-haskell
        epkgs.lsp-metals
        epkgs.lsp-java
        epkgs.nix-mode
        epkgs.markdown-mode
        epkgs.typescript-mode
        epkgs.yaml-mode
        epkgs.yasnippet
        epkgs.yasnippet-snippets
        epkgs.scala-mode
        epkgs.terraform-mode

        # Navigation
        epkgs.dumb-jump
        epkgs.multiple-cursors

        # Git
        epkgs.magit
        epkgs.magit-todos
        epkgs.forge

        # Projects
        epkgs.projectile
        epkgs.projectile-ripgrep

        # Themes
        epkgs.doom-themes

        # Other
        epkgs.rainbow-delimiters
        epkgs.helm
        epkgs.edit-server
        epkgs.dap-mode
        epkgs.browse-at-remote
        epkgs.general
        epkgs.no-littering
        epkgs.string-inflection
        epkgs.ripgrep
        epkgs.use-package
      ];
    };

    programs.git = {
      enable = true;
      ignores = import ./gitignores.nix;
      # Email, name and key needs to be defined elsewhere.
    };

    services.emacs = {
      enable = true;
      socketActivation.enable = true;
    };
    systemd.user.services.emacs.Service.Environment = "XMODIFIERS=";
  };
}
