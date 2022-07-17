{ config, lib, pkgs, sbt-pkgs, ... }:
with lib;
let
  cfg = config.dev;
  emacsPiper = pkgs.callPackage (import ./pkgs/piper.nix) { };
  kokaMode = "${pkgs.koka.src}/support/emacs/";

  # TODO: Fix
  # nix-haskell-hls = import (fetchTarball https://github.com/shajra/nix-haskell-hls/archive/refs/heads/main.tar.gz) {};
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
      ## Haskell
      # TODO: Fix
      # nix-haskell-hls.hls-wrapper-nix

      # Nix
      pkgs.nixfmt
      pkgs.nixpkgs-fmt

      ## Rust
      pkgs.rust-analyzer

      ## Scala
      pkgs.lombok
      pkgs.metals

      pkgs.binutils
      pkgs.git-crypt
      pkgs.kafkacat
      pkgs.ncdu
      pkgs.redis
    ];

    home.file.".emacs".text = let
      base = builtins.readFile ./../dotfiles/emacs.el;
      extra = cfg.dotEmacs.extraLines;
      # TODO: Re-add
      # (setq lsp-haskell-server-path "${nix-haskell-hls.hls-wrapper-nix}/bin/hls-wrapper-nix")
    in ''
      (setq -piper-load-path "${emacsPiper}")
      (setq -koka-load-path "${kokaMode}")
      (setq lsp-java-vmargs
        '("-noverify" "-Xmx1G" "-XX:+UseG1GC" "-XX:+UseStringDeduplication" "-javaagent:${pkgs.lombok}/share/java/lombok.jar"))

      ${base}
      ;; Lines from dev.dotEmacs.extraLines
      ${extra}
    '';

    programs.emacs = {
      enable = true;
      package = mkIf (!config.profiles.graphical.enable) pkgs.emacs-nox;
      extraPackages = epkgs: [
        # Auto-complete
        #        epkgs.company-lsp
        epkgs.flycheck

        # Searching
        epkgs.ag
        epkgs.helm-ag

        # Latex
        epkgs.auctex

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
        epkgs.rustic
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
        epkgs.po-mode
      ];
    };

    programs.git = {
      enable = true;
      ignores = import ./gitignores.nix;
      userEmail = "rasmus@precenth.eu";
      userName = "Rasmus Précenth";
      signing = {
        key = "6A3950D91C1FA0F728D115E73E4C7B34D80F07F7";
        signByDefault = true;
      };
    };

    programs.sbt = {
      enable = true;
      package = sbt-pkgs.sbt;
      # % sbt
      # Unrecognized VM option 'CMSClassUnloadingEnabled'
      # Error: Could not create the Java Virtual Machine.
      # Error: A fatal exception has occurred. Program will exit.
    };

    services.emacs.enable = true;
    services.emacs.socketActivation.enable = true;
    systemd.user.services.emacs.Service.Environment = "XMODIFIERS=";
    systemd.user.services.emacs.Service.Type = lib.mkForce "simple";
  };
}
