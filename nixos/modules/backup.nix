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
        name = mkOption {
          type = types.str;
          default = "rsync-backup";
          example = "backup-user";
        };
        extraGroups = mkOption {
          type = with types; listOf str;
          default = [ ];
          example = [ "nextcloud" ];
        };
      };
      onFailure = mkOption {
        type = with types; nullOr lines;
        default = null;
        description = ''
          Script run when a backup fails. The failed unit name is available as $MONITOR_UNIT.
        '';
      };
      scripts = mkOption {
        description = "backup scripts";
        type = with types; lazyAttrsOf (submodule {
          options = {
            enable = mkEnableOption "script";
            preScript = mkOption {
              type = lines;
              default = "";
              description = "Script to run before rsync.";
            };
            source = {
              dir = mkOption {
                type = with types; nullOr str;
                default = null;
              };
              runtimeDirectory = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Use a systemd RuntimeDirectory as rsync source. Mutually exclusive with dir.";
              };
              filters = mkOption {
                type = lines;
                default = "";
                example = ''
                  - /foo
                  + /some/
                  + /some/path/
                '';
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
    users.users.${cfg.user.name} = {
      group = cfg.user.name;
      isSystemUser = true;
      extraGroups = cfg.user.extraGroups;
    };
    users.groups.${cfg.user.name} = { };

    programs.ssh.knownHosts = mkMerge (
      mapAttrsToList
        (k: { target, ... }: mkIf (target.hostKeys != "" && target.host != "") {
          "rsync-backup-${k}" = {
            hostNames = [ target.host ];
            publicKeyFile = pkgs.writeText "host-key" target.hostKeys;
          };
        })
        cfg.scripts);

    systemd.timers = mapAttrs'
      (k: _:
        {
          name = unit-name k;
          value = {
            wantedBy = [ "timers.target" ];
            after = [ "multi-user.target" ];

            timerConfig = {
              OnCalendar = "Sun 02:00:00";
            };
          };
        })
      cfg.scripts;

    systemd.services = mkMerge [
      (mapAttrs'
        (k: v:
          {
            name = unit-name k;
            value = {
              path = [ pkgs.openssh pkgs.rsync ];
              script =
                let
                  ssh =
                    if v.target.sshKeyFile != null
                    then "ssh -i '${v.target.sshKeyFile}'"
                    else "ssh";
                  sourceArg =
                    if v.source.runtimeDirectory != null
                    then ''"$RUNTIME_DIRECTORY/"''
                    else lib.escapeShellArg (assert v.source.dir != null; v.source.dir);
                  targetStr =
                    if v.target.host == "" then v.target.dir
                    else
                      if v.target.user == "" then "${v.target.host}:${v.target.dir}"
                      else "${v.target.user}@${v.target.host}:${v.target.dir}";
                  targetArg = lib.escapeShellArg targetStr;
                  filterFile = pkgs.writeText "${unit-name k}-filters" v.source.filters;
                  filterOpt =
                    if v.source.filters != ""
                    then "--filter='merge ${filterFile}'"
                    else "";
                in
                ''
                  set -ex
                  ${v.preScript}
                  echo "$(date): ${sourceArg} -> ${targetArg}"
                  rsync -e "${ssh}" -vrzt ${filterOpt} ${sourceArg} ${targetArg}
                '';
              serviceConfig = {
                Type = "exec";
                User = cfg.user.name;
              } // optionalAttrs (v.source.runtimeDirectory != null) {
                RuntimeDirectory = v.source.runtimeDirectory;
              };
              unitConfig = optionalAttrs (cfg.onFailure != null) {
                OnFailure = "rsync-backup-notify@%n.service";
              };
            };
          })
        cfg.scripts)

      (optionalAttrs (cfg.onFailure != null) {
        "rsync-backup-notify@" = {
          description = "Notify on rsync-backup failure for %i";
          script = cfg.onFailure;
          serviceConfig = {
            Type = "oneshot";
            User = cfg.user.name;
          };
        };
      })
    ];
  };
}
