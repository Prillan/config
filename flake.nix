{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nixpkgs-old.url = "github:NixOS/nixpkgs/38fce8ec004b3e61c241e3b64c683f719644f350";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-review.url = "github:Mic92/nixpkgs-review";
    nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-old, home-manager, nixpkgs-review }: {
    lib = {
      homeConfiguration = { configuration, username ? "rasmus" , system ? "x86_64-linux", extraModules ? [] }:
        home-manager.lib.homeManagerConfiguration {
          inherit system username configuration;
          extraModules = [
            ./nixpkgs/home.nix
            { home.packages = [ nixpkgs-review.defaultPackage.${system} ]; }
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