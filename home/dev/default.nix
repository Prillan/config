{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dev;
  emacsPiper = pkgs.callPackage (import ../../pkgs/piper.nix) { };
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
      pkgs.binutils
      pkgs.git-crypt
      pkgs.hyperfine
      pkgs.kcat
      pkgs.ncdu
      pkgs.redis
    ];

    home.file.".emacs".text = let
      base = builtins.readFile ../../dotfiles/emacs.el;
      extra = cfg.dotEmacs.extraLines;
    in ''
      (setq -piper-load-path "${emacsPiper}")

      ${base}
      ;; Begin lines from dev.dotEmacs.extraLines ;;
      ${extra}
      ;; End lines from dev.dotEmacs.extraLines   ;;

      ;; Supposedly has to be at the end of the file
      (use-package envrc
        :hook (after-init . envrc-global-mode))
    '';

    programs.emacs = {
      enable = true;
      package = mkDefault pkgs.emacs-unstable-nox;
      extraPackages = epkgs: [
        # Auto-complete
        epkgs.flycheck

        # Searching
        epkgs.ag
        epkgs.helm-ag

        # Latex
        epkgs.auctex

        # Navigation
        epkgs.dumb-jump
        epkgs.multiple-cursors

        # Git
        epkgs.magit
        epkgs.magit-todos
        epkgs.forge

        # Projects
        epkgs.envrc
        epkgs.projectile
        epkgs.projectile-ripgrep

        # Themes
        epkgs.doom-themes

        # Other
        epkgs.browse-at-remote
        epkgs.dap-mode
        epkgs.edit-server
        epkgs.general
        epkgs.helm
        epkgs.no-littering
        epkgs.po-mode
        epkgs.rainbow-delimiters
        epkgs.restclient
        epkgs.ripgrep
        epkgs.string-inflection
        epkgs.use-package
      ];
    };

    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
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

    services.emacs.enable = true;
    services.emacs.socketActivation.enable = true;
    systemd.user.services.emacs.Service.Environment = "XMODIFIERS=";
    systemd.user.services.emacs.Service.Type = lib.mkForce "simple";
  };
}
