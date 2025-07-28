{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dev.langs;
  mkEnableOptionDefaultTrue = name:
    mkOption {
      default = true;
      example = true;
      description = "Whether to enable ${name}.";
      type = lib.types.bool;
    };
in {
  options.dev.langs = {
    python.enabled = mkEnableOptionDefaultTrue "python";
    haskell.enabled = mkEnableOptionDefaultTrue "haskell";
    rust.enabled = mkEnableOptionDefaultTrue "rust";
    nix.enabled = mkEnableOptionDefaultTrue "nix";
    scala.enabled = mkEnableOptionDefaultTrue "scala";
    koka.enabled = mkEnableOptionDefaultTrue "koka";
    java.enabled = mkEnableOptionDefaultTrue "java";
    purescript.enabled = mkEnableOptionDefaultTrue "purescript";
  };

  config = mkMerge [
    # Python
    (mkIf cfg.python.enabled
      {
        home.packages = [
          pkgs.pyright
        ];
        programs.emacs.extraPackages = epkgs: [
          epkgs.lsp-pyright
        ];
      })
    # Haskell
    (mkIf cfg.haskell.enabled
      {
        home.packages = [
          pkgs.cabal-install
          pkgs.haskell-language-server
        ];
        programs.emacs.extraPackages = epkgs: [
          epkgs.haskell-mode
          epkgs.lsp-haskell
        ];
      })
    # Rust
    (mkIf cfg.rust.enabled
      {
        home.packages = [
          pkgs.rust-analyzer
        ];
        programs.emacs.extraPackages = epkgs: [
          epkgs.rust-mode
        ];
      })
    # Nix
    (mkIf cfg.nix.enabled
      {
        home.packages = [
          pkgs.nixfmt-rfc-style
          pkgs.nixpkgs-fmt
          pkgs.nixpkgs-review
        ];
        programs.emacs.extraPackages = epkgs: [
          epkgs.nix-mode
        ];
      })
    # Scala
    (mkIf cfg.scala.enabled
      {
        home.packages = [
          pkgs.metals
        ];
        programs.emacs.extraPackages = epkgs: [
          epkgs.scala-mode
          epkgs.lsp-metals
        ];
        programs.sbt.enable = true;
      })
    # Koka
    (mkIf cfg.koka.enabled (
      let kokaMode = "${pkgs.koka.src}/support/emacs/";
      in
        {
          home.packages = [
            pkgs.koka
          ];
          dev.dotEmacs.extraLines = ''
            (setq -koka-load-path "${kokaMode}")
          '';
        }))
    # Java
    (mkIf cfg.java.enabled
      {
        home.packages = [
          pkgs.lombok
        ];
        programs.emacs.extraPackages = epkgs: [
          epkgs.lsp-java
        ];
        dev.dotEmacs.extraLines = ''
          (setq lsp-java-vmargs
            '("-noverify" "-Xmx1G" "-XX:+UseG1GC" "-XX:+UseStringDeduplication" "-javaagent:${pkgs.lombok}/share/java/lombok.jar"))
        '';
      })
    # Purescript
    (mkIf cfg.purescript.enabled
      {
        home.packages = [
          pkgs.purescript
          pkgs.nodePackages.purescript-language-server
        ];
        dev.dotEmacs.extraLines = ''
          ;; FROM https://github.com/purescript-emacs/purescript-mode?tab=readme-ov-file#basic-configuration
          (use-package purescript-mode
            :defer t
            :config
            (defun myhook-purescript-mode ()
              (turn-on-purescript-indentation)
              (add-hook 'before-save-hook #'purescript-sort-imports nil t))
            (add-hook 'purescript-mode-hook #'myhook-purescript-mode)
            :hook (purescript-mode . lsp))
        '';
      })
    # # Rust
    # (mkIf cfg.rust.enabled
    #   {
    #     home.packages = [
    #
    #     ];
    #     programs.emacs.extraPackages = epkgs: [
    #
    #     ];
    #   })
    # TODO
    ({
      programs.emacs = {
        extraPackages = epkgs: [
          # Modes
          epkgs.company-terraform
          epkgs.dockerfile-mode
          epkgs.groovy-mode
          epkgs.hledger-mode
          epkgs.jq-mode
          epkgs.json-mode
          epkgs.lsp-mode
          epkgs.lsp-ui
          epkgs.markdown-mode
          epkgs.purescript-mode
          epkgs.terraform-mode
          epkgs.typescript-mode
          epkgs.yaml-mode
        ];
      };
    })
  ];
}
