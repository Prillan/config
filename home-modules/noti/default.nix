{ lib, config, pkgs, ... }:
# A different version of programs.noti
let cfg = config.custom-programs.noti;
    inherit (lib) mkOption mkEnableOption types;
in
{
  # TODO: override programs.noti directly instead
  options.custom-programs.noti = {
    enable = mkEnableOption "noti";
    telegram = {
      enable = mkEnableOption "noti telegram integration";
      chatId = mkOption {
        type = types.str;
      };
      tokenFile = mkOption {
        type = types.pathWith { absolute = false; };
      };
    };

    envPaths = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = [
          (
            pkgs.writeShellScriptBin "noti" (
              let buildVar = key: value: ''export ${key}="$(cat ${value})"'';
                  vars = lib.strings.concatMapAttrsStringSep "\n" buildVar cfg.envPaths;
              in ''
                 ${vars}
                 exec ${pkgs.noti}/bin/noti "$@"
              ''
            )
          )
        ];
      }
      (lib.mkIf cfg.telegram.enable {
        xdg.configFile."noti/noti.yaml".text = lib.generators.toYAML { } {
          telegram.chatId = cfg.telegram.chatId;
        };

        custom-programs.noti.envPaths.NOTI_TELEGRAM_TOKEN = cfg.telegram.tokenFile;
      })
    ]
  );
}
