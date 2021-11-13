{ config, lib, pkgs, ... }:
{
  imports = [
    ./base.nix
    ./backup
    ./colors.nix
    ./ctf.nix
    ./dev.nix
    ./media.nix
    ./profiles
  ];
}
