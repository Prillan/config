{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dev;
  emacsPiper = pkgs.callPackage (import ./pkgs/piper.nix) { };
  nix-haskell-hls = import (fetchTarball https://github.com/shajra/nix-haskell-hls/archive/refs/heads/main.tar.gz) {};

  oldPkgs = import (fetchTarball {
    url =
      "https://github.com/NixOS/nixpkgs/archive/38fce8ec004b3e61c241e3b64c683f719644f350.tar.gz";
    sha256 = "12azgdf3zihlxqiw33dx0w9afhgzka8pqha4irp7sn0jgka0zyxs";
  }) {};
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
      nix-haskell-hls.hls-wrapper-nix

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
    in ''
      (setq -piper-load-path "${emacsPiper}")
      (setq lsp-java-vmargs
        '("-noverify" "-Xmx1G" "-XX:+UseG1GC" "-XX:+UseStringDeduplication" "-javaagent:${pkgs.lombok}/share/java/lombok.jar"))

      (setq lsp-haskell-server-path "${nix-haskell-hls.hls-wrapper-nix}/bin/hls-wrapper-nix")
      ${base}
      ;; Lines from dev.dotEmacs.extraLines
      ${extra}
    '';

    programs.emacs = {
      enable = true;
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
      ];
    };

    programs.git = {
      enable = true;
      ignores = import ./gitignores.nix;
      # Email, name and key needs to be defined elsewhere.
    };

    programs.sbt = {
      enable = true;
      package = oldPkgs.sbt;
      # % sbt
      # Unrecognized VM option 'CMSClassUnloadingEnabled'
      # Error: Could not create the Java Virtual Machine.
      # Error: A fatal exception has occurred. Program will exit.
    };

    services.emacs = {
      enable = true;
      socketActivation.enable = true;
    };
    systemd.user.services.emacs.Service.Environment = "XMODIFIERS=";
  };
}
