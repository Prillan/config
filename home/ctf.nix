{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bind
    gdb
    file
    ltrace
    unixtools.xxd
  ];
}
