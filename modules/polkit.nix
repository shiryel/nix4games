{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.polkit.enable {
  security.polkit.enable = true;

  # NOTE: Polkit agents require setuid, therefore the service MUST be
  # "PrivateUsers=false" (which is automatically enabled in most sandbox options)
  systemd.user.services = {
    polkit-kde-authentication-agent-1 = {
      description = "polkit-kde-authentication-agent-1";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;

        # FIX: qrc:/qml/QuickAuthDialog.qml: module "kvantum" is not installed
        UnsetEnvironment = [ "QT_QPA_PLATFORMTHEME" "QT_STYLE_OVERRIDE" "QT_PLUGIN_PATH" "QML2_IMPORT_PATH" ];

        DeviceAllow = [ "" ];
        RestrictFileSystems = "@basic-api @application @common-block";
      };
    };
  };
}
