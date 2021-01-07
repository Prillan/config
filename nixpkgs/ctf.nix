{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    gdb
    ltrace
    unixtools.xxd
  ];
}
