{ pkgs, ... }:
{
  home.username = "rasmus";
  custom = {
    onNixOS = true;
    defaultMonitor = "eDP-1";
    wifiInterface = "wlan0";
  };

  programs.git = {
    userEmail = "rasmus@precenth.eu";
    userName = "Rasmus Précenth";
    # signing = {
    #   key = "";
    #   signByDefault = true;
    # };
  };
}
