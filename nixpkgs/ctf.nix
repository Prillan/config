{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    gdb
    ltrace
  ];
}
