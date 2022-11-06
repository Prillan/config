{
  description = "A very basic flake";

  nixConfig = {
    extra-substituters = "https://rprecenth.cachix.org";
    extra-trusted-public-keys = "rprecenth.cachix.org-1:ZQOug0Ec0sckEbnimeHUUekj3NeMg+kz5vb3vqy5ajE=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-review.url = "github:Mic92/nixpkgs-review";
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixpkgs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, emacs-overlay, home-manager, nixpkgs-review }: {
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
        };
    };

    apps.x86_64-linux = {
      # First run "wal ...", then "nix run .#copy-theme".
      copy-theme = {
        type = "app";
        program = let prog = nixpkgs.legacyPackages.x86_64-linux.writeShellApplication {
          name = "copy-theme";
          text = ''
            mkdir -p wal
            if [[ -v 1 ]]; then
              pushd "$1"
              TARGET="$(pwd)"
              popd
            else
              TARGET=$(pwd)/wal
            fi
            pushd ~/.cache/wal

            cp colors{.json,.hs,.Xresources} \
               colors-wal-dmenu.h \
               "$TARGET"

            popd

            pushd "$TARGET"

            sed -i 's/"wallpaper": ".*"/"wallpaper": "None"/' colors.json
            sed -i 's/wallpaper=".*"/wallpaper="None"/' colors.hs

            popd
          '';
        };
        in "${prog}/bin/copy-theme";
      };
    };

    homeConfigurations = {
      "rasmus@kalmiya" =  (self.lib.homeConfiguration {
        configuration = { ... }: {
          custom.hostname = "kalmiya";
          custom.wifiInterface = "wlp2s0";
          profiles.fluff.enable = true;
          profiles.graphical.enable = true;
          profiles.mapping.enable = true;
          borg.enable = true;
        };
      });
    };

    nixosModules.rsync-backup = import ./nixos/modules/backup.nix;
  };
}
