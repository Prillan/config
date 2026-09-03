{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.profiles.dev.langs;
in
{
  options.profiles.dev.langs = {
    python.enabled = mkEnableOption "python";
    haskell.enabled = mkEnableOption "haskell";
    rust.enabled = mkEnableOption "rust";
    nix.enabled = mkEnableOption "nix";
    scala.enabled = mkEnableOption "scala";
    koka.enabled = mkEnableOption "koka";
    java.enabled = mkEnableOption "java";
    purescript.enabled = mkEnableOption "purescript";
    erlang.enabled = mkEnableOption "erlang";
    erlang.beamPackages = mkOption {
      default = pkgs.beam28Packages;
      type = types.lazyAttrsOf types.package;
    };
    elixir.enabled = mkEnableOption "elixir";
    elixir.beamPackages = mkOption {
      default = cfg.erlang.beamPackages;
      type = types.lazyAttrsOf types.package;
    };
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
          pkgs.nixfmt
          pkgs.nixpkgs-fmt
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
          (use-package koka-mode
              :load-path (-koka-load-path)
              :mode "\\.kk\\'")
        '';
      }
    ))
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
          # pkgs.nodePackages.purescript-language-server
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
            ;; :hook (purescript-mode . lsp)
            )
        '';
      })
    # Erlang
    (mkIf cfg.erlang.enabled (
      let beamPackages = cfg.erlang.beamPackages;
      in
      {
        home.packages = [
          pkgs.erlang-language-platform
          beamPackages.erlang
          beamPackages.rebar3
        ];
        programs.emacs.extraPackages = epkgs: [
          epkgs.erlang
        ];
        dev.dotEmacs.extraLines = ''
          (add-hook 'erlang-mode-hook #'lsp)
        '';
      }
    ))
    # Elixir
    (mkIf cfg.elixir.enabled (
      let beamPackages = cfg.elixir.beamPackages;
      in
      {
        home.packages = [
          beamPackages.elixir_1_20
          beamPackages.expert
        ];
        dev.dotEmacs.extraLines = ''
          (require 'elixir-ts-mode)
          (add-hook 'elixir-ts-mode-hook #'lsp-deferred)
          (with-eval-after-load 'lsp-mode
            (add-to-list 'lsp-disabled-clients 'elixir-ls)
            (lsp-register-client
             (make-lsp-client
              :new-connection (lsp-stdio-connection
                               '("${beamPackages.expert}/bin/expert" "--stdio"))
              :activation-fn (lsp-activate-on "elixir")
              :server-id 'expert-elixir)))
        '';
      }
    ))
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
