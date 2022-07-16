{ config, pkgs, lib, ... }:

with builtins;
with lib;

let
  cfg = config.rsync-backup;

  unit-name = k: "rsync-backup-${k}";
in
{
  options = {
    rsync-backup = {
      enable = mkEnableOption "rsync backup scripts";
      user = {
        extraGroups = mkOption {
          type = with types; listOf str;
          default = [];
          example = [ "nextcloud" ];
        };
      };
      scripts = mkOption {
        description = "backup scripts";
        type = with types; lazyAttrsOf (submodule {
          options = {
            enable = mkEnableOption "script";
            source = {
              dir = mkOption {
                type = str;
              };
            };
            target = {
              dir = mkOption {
                type = str;
              };
              host = mkOption {
                type = str;
                default = "";
                example = "example.com";
              };
              user = mkOption {
                type = str;
                default = "";
                example = "user";
              };
              sshKeyFile = mkOption {
                type = nullOr str;
                default = null;
                example = "/path/to/secret/id_rsa";
              };
              hostKeys = mkOption {
                type = lines;
                default = "";
                example = ''
                ssh-ed25519 <...>
              '';
              };
            };
          };
        });
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.rsync-backup = {
      group = "rsync-backup";
      isSystemUser = true;
      extraGroups = cfg.user.extraGroups;
    };
    users.groups.backup = { };

    programs.ssh.knownHosts = mkMerge (
      mapAttrsToList (k: { target, ...}: mkIf (target.hostKeys != "" && target.host != "") {
        "rsync-backup-${k}" = {
          hostNames = [ target.host ];
          publicKeyFile = pkgs.writeText "host-key" target.hostKeys;
        };
      }) cfg.scripts);

    systemd.timers = mapAttrs' (k: _:
      {
        name = unit-name k;
        value = {
          wantedBy = [ "timers.target" ];
          after = [ "multi-user.target" ]; # wait until the system hs started

          timerConfig = {
            OnCalendar = "Sun 02:00:00";
          };
        };
      }) cfg.scripts;

    systemd.services = mapAttrs' (k: v:
      {
        name = unit-name k;
        value = {
          path = [ pkgs.openssh pkgs.rsync ];
          script =
            let ssh = if v.target.sshKeyFile != null
                      then "ssh -i '${v.target.sshKeyFile}'"
                      else "ssh";
                source = v.source.dir;
                target =
                  if v.target.host == "" then v.target.dir
                  else
                    if v.target.user == "" then "${v.target.host}:${v.target.dir}"
                    else "${v.target.user}@${v.target.host}:${v.target.dir}";
            in ''
              set -x
              echo "$(date): " '${source} -> ${target}'
              rsync -e "${ssh}" -vrz '${source}' '${target}'
            '';
          serviceConfig = {
            Type = "exec";
            User = "backup";
          };
        };
      }) cfg.scripts;
  };
}
