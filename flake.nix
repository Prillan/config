{
  description = "A very basic flake";

  nixConfig = {
    extra-substituters = "https://rprecenth.cachix.org";
    extra-trusted-public-keys = "rprecenth.cachix.org-1:ZQOug0Ec0sckEbnimeHUUekj3NeMg+kz5vb3vqy5ajE=";
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs-review.url = "github:Mic92/nixpkgs-review";
    emacs-overlay.url = "github:nix-community/emacs-overlay";

    flake-utils.url = "github:numtide/flake-utils";
    flake-parts.url = "github:hercules-ci/flake-parts";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.darwin.follows = "";
  };

  outputs = inputs@{ self, flake-parts, emacs-overlay, nixpkgs-review, flake-utils, unstable, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({withSystem, config, ...}: {
      systems = [ "x86_64-linux" ];
      imports = [
        inputs.home-manager.flakeModules.home-manager
      ];
      flake = {
        overlays = {
          default = final: prev:
            let pkgs = unstable.legacyPackages.${prev.system};
            in {
              inherit (pkgs) josm nix-zsh-completions;
              nixpkgs-review = nixpkgs-review.packages.${prev.system}.default;
            };
        };

        homeModules = {
          base = {
            imports = [
              inputs.agenix.homeManagerModules.default
              ./home-modules/noti
              ./home
            ];
            nixpkgs.overlays = [
              emacs-overlay.overlay
              self.overlays.default
            ];

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
                    input = inputs.nixpkgs;
                    type = "github";
                    owner = "NixOS";
                    repo = "nixpkgs";
                  };
                  unstable = reg {
                    id = "unstable";
                    input = inputs.unstable;
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
          };

          rasmus-graphical-user = {
            imports = [ self.homeModules.base ];
            profiles.fluff.enable = true;
            profiles.graphical.wayland.enable = true;
            profiles.mapping.enable = true;
            borg.enable = true;
            programs.home-manager.enable = true;
          };
        };

        homeConfigurations = {
          "rasmus@kalmiya" = withSystem "x86_64-linux" (
            {pkgs, ...}:
            inputs.home-manager.lib.homeManagerConfiguration {
              inherit pkgs;

              modules = [
                self.homeModules.rasmus-graphical-user
                {
                  home = {
                    username = "rasmus";
                    homeDirectory = "/home/rasmus";
                  };
                  custom.hostname = "kalmiya";
                  custom.wifiInterface = "wlp2s0";
                  nix.settings.experimental-features = [ "nix-command" "flakes" "ca-derivations" ];
                }
              ];
            }
          );
        };

        nixosModules.rsync-backup = import ./nixos/modules/backup.nix;

        templates.shell = {
          path = ./templates/shell;
          description = "A quick ad-hoc-ish shell";
        };
      };

      perSystem = { pkgs, ...}: {
        apps.copy-theme = {
          type = "app";
          program =
            let
              prog = pkgs.writeShellApplication {
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
    });
}
