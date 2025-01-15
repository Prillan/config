{ config, lib, pkgs, ... }:
with builtins;
with lib;

let # TODO: Prettify
  borg-host = "ch-s012.rsync.net";
  borg-user = "19194";

  borg-exclude = pkgs.writeText "borg-exclude" ''
    ${config.home.homeDirectory}/.android
    ${config.home.homeDirectory}/Android
    ${config.home.homeDirectory}/Downloads
    ${config.home.homeDirectory}/tmp
    sh:${config.home.homeDirectory}/**/.stack-work
    sh:${config.home.homeDirectory}/**/__pycache__
    ${config.home.homeDirectory}/.idris/
    ${config.home.homeDirectory}/.ghc/
    ${config.home.homeDirectory}/.ghcjs/
    ${config.home.homeDirectory}/.cabal/
    ${config.home.homeDirectory}/.cargo/
    ${config.home.homeDirectory}/.rustup/
    ${config.home.homeDirectory}/.cache/
    ${config.home.homeDirectory}/.config/Slack/Cache/
    ${config.home.homeDirectory}/.stack/
    ${config.home.homeDirectory}/.rubies/
    ${config.home.homeDirectory}/.rvm/
    ${config.home.homeDirectory}/.npm/
    ${config.home.homeDirectory}/.local/share/virtualenvs/
    sh:${config.home.homeDirectory}/**/.venv
    sh:${config.home.homeDirectory}/projects/**/node_modules
    ${config.home.homeDirectory}/media/
    ${config.home.homeDirectory}/.local/share/Steam
    ${config.home.homeDirectory}/.config/Slack/Cache
  '';

  borg-backup-script = pkgs.writeScriptBin "borg_backup" ''
    export BORG_PASSPHRASE="$(gopass --password borg/${config.custom.hostname})"

    REPO='${borg-user}@${borg-host}:~/${config.custom.hostname}/borg'
    ARCHIVE="$(date --iso-8601=minutes | cut -d'+' -f 1)"

    ${pkgs.borgbackup}/bin/borg create \
         --exclude-from ${borg-exclude} \
         --stats \
         --progress \
         "''${REPO}::''${ARCHIVE}" \
         ${config.home.homeDirectory}
  '';
in {
  options.borg.enable = mkEnableOption "borg backup script";
  config = mkIf config.borg.enable {
    home.packages = with pkgs; [ borg-backup-script ];
  };
}
