{ config, lib, pkgs, ... }:
{
  imports = [
    ./base.nix
    ./backup
    ./colors.nix
    ./ctf.nix
    ./dev
    ./media.nix
    ./profiles
  ];
}
