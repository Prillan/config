{
  description = "A very basic flake";

  nixConfig = {
    extra-substituters = "https://rprecenth.cachix.org";
    extra-trusted-public-keys = "rprecenth.cachix.org-1:ZQOug0Ec0sckEbnimeHUUekj3NeMg+kz5vb3vqy5ajE=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-old.url = "github:NixOS/nixpkgs/38fce8ec004b3e61c241e3b64c683f719644f350";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-review.url = "github:Mic92/nixpkgs-review";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-old, emacs-overlay, home-manager, nixpkgs-review }: {
    lib = {
      homeConfiguration = { configuration, username ? "rasmus" , system ? "x86_64-linux", extraModules ? [] }:
        home-manager.lib.homeManagerConfiguration {
          inherit system username configuration;
          extraModules = [
            ./nixpkgs/home.nix
            {
              home.packages = [ nixpkgs-review.defaultPackage.${system} ];
              nixpkgs.overlays = [ emacs-overlay.overlay ];
            }
          ] ++ extraModules;
          homeDirectory = "/home/${username}";
          extraSpecialArgs = {
            sbt-pkgs = nixpkgs-old.legacyPackages.${system};
          };
        };
    };

    homeConfigurations = {
      "rasmus@kalmiya" =  (self.lib.homeConfiguration {
        configuration = { ... }: {
          custom.hostname = "kalmiya";
          custom.wifiInterface = "wlp2s0";
          profiles.graphical.enable = true;
          profiles.fluff.enable = true;
          borg.enable = true;
        };
      });
    };
  };
}
