{
  description = "A very basic flake";

  nixConfig = {
    extra-substituters = "https://rprecenth.cachix.org";
    extra-trusted-public-keys = "rprecenth.cachix.org-1:ZQOug0Ec0sckEbnimeHUUekj3NeMg+kz5vb3vqy5ajE=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-review.url = "github:Mic92/nixpkgs-review";
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, unstable, flake-utils, emacs-overlay, home-manager, nixpkgs-review }: {
    overlays = {
      default = final: prev:
        let pkgs = unstable.legacyPackages.${prev.system};
        in {
          inherit (pkgs) josm nix-zsh-completions;
        };
    };
    lib = {
      homeConfiguration = { configuration, username ? "rasmus", system ? "x86_64-linux", extraModules ? [ ] }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            ./nixpkgs/home.nix
            configuration
            {
              home.packages = [ nixpkgs-review.packages.${system}.default ];
              nixpkgs.overlays = [
                emacs-overlay.overlay
                self.overlays.default
              ];
            }
            {
              home = {
                username = username;
                homeDirectory = "/home/${username}";
              };
              nix.registry =
                let
                  reg = { id, input, type, owner, repo }: {
                    from = {
                      inherit id;
                      type = "indirect";
                    };
                    to = {
                      inherit (input) rev narHash lastModified;
                      inherit type owner repo;
                    };
                  };
                in
                {
                  nixpkgs = reg {
                    id = "nixpkgs";
                    input = self.inputs.nixpkgs;
                    type = "github";
                    owner = "NixOS";
                    repo = "nixpkgs";
                  };
                  unstable = reg {
                    id = "unstable";
                    input = self.inputs.unstable;
                    type = "github";
                    owner = "NixOS";
                    repo = "nixpkgs";
                  };
                  config = {
                    from = {
                      id = "config";
                      type = "indirect";
                    };
                    to = {
                      type = "github";
                      owner = "Prillan";
                      repo = "config";
                    };
                  };
                };
            }
          ] ++ extraModules;
        };
    };

    nixosModules.rsync-backup = import ./nixos/modules/backup.nix;

    homeConfigurations = {
      "rasmus@kalmiya" = (self.lib.homeConfiguration {
        configuration = { ... }: {
          custom.hostname = "kalmiya";
          custom.wifiInterface = "wlp2s0";
          profiles.fluff.enable = true;
          profiles.graphical.wayland.enable = true;
          profiles.mapping.enable = true;
          borg.enable = true;
        };
      });
    };


    templates.shell = {
      path = ./templates/shell;
      description = "A quick ad-hoc-ish shell";
    };
  } // flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: {
    apps = {
      # First run "wal ...", then "nix run .#copy-theme".
      copy-theme = {
        type = "app";
        program =
          let
            prog = nixpkgs.legacyPackages.${system}.writeShellApplication {
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

                cp colors{.json,.hs,.Xresources,-kitty.conf,-sway,-waybar.css} \
                   colors-wal-dmenu.h \
                   "$TARGET"

                popd

                pushd "$TARGET"

                sed -i 's/"wallpaper": ".*"/"wallpaper": "None"/' colors.json
                sed -i 's/wallpaper=".*"/wallpaper="None"/' colors.hs
                sed -i '/set .wallpaper/d' colors-sway

                popd
              '';
            };
          in
          "${prog}/bin/copy-theme";
      };
    };

    checks = {
      # x11 = (self.lib.homeConfiguration {
      #   inherit system;
      #   configuration = {
      #     profiles.graphical.x11.enable = true;
      #     custom.hostname = "check";
      #     custom.wifiInterface = "wl-test";
      #   };
      # }).activationPackage;

      wayland = (self.lib.homeConfiguration {
        inherit system;
        configuration = {
          profiles.graphical.wayland.enable = true;
          custom.hostname = "check";
          custom.wifiInterface = "wl-test";
        };
      }).activationPackage;
    };
  }
  );
}
