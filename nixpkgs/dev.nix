{ config, pkgs, ... }: {
  programs.jq.enable = true;

  home.file.".emacs".source = ./../dotfiles/emacs;
  programs.emacs = {
    enable = true;
    extraPackages = epkgs: [
      # Searching
      epkgs.ag
      epkgs.helm-ag

      # Latex
      # epkgs.auctex 404???

      # Modes
      epkgs.dockerfile-mode
      epkgs.haskell-mode
      epkgs.lsp-mode
      epkgs.lsp-ui
      epkgs.nix-mode
      epkgs.typescript-mode
      epkgs.yaml-mode
      epkgs.yasnippet
      epkgs.yasnippet-snippets

      # Navigation
      epkgs.dumb-jump
      epkgs.multiple-cursors

      # Git
      epkgs.magit
      epkgs.magit-todos

      # Projects
      epkgs.projectile
      epkgs.projectile-ripgrep

      # Other
      epkgs.general
      epkgs.no-littering
      epkgs.string-inflection
      epkgs.ripgrep
      epkgs.use-package
    ];
  };

  programs.git = {
    enable = true;
    userEmail = "rasmus@precenth.eu";
    userName = "Rasmus Précenth";
    ignores = import ./gitignores.nix;
    signing = {
      key = "6A3950D91C1FA0F728D115E73E4C7B34D80F07F7";
      signByDefault = true;
    };
  };

  services.emacs = {
    enable = true;
    socketActivation.enable = true;
  };
  systemd.user.services.emacs.Service.Environment = "XMODIFIERS=";
}
