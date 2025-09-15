# !!! Requires configuration on KeePassXC !!!
# see: https://gist.github.com/GrabbenD/6658c36a1c7fc7ee30ee2498647ca4c6#keepassxc-integration
#
# -- TEST --
#
# `python3Packages.keyring` to test the secrets service
#
# -- DOCS --
#
# https://wiki.archlinux.org/title/KeePass#Secret_Service

{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.keepassxc-keyring.enable {
  # Use keepassxc for the secrets service
  # https://gist.github.com/GrabbenD/6658c36a1c7fc7ee30ee2498647ca4c6
  environment.systemPackages = with pkgs; [
    (stdenv.mkDerivation {
      pname = "keepassxc-dbus";
      version = "custom";
      dontUnpack = true;
      installPhase = ''
        mkdir -p $out/share/dbus-1/services

        cat > $out/share/dbus-1/services/org.freedesktop.secrets.service << EOF
          [D-BUS Service]
          Name=org.freedesktop.secrets
          Exec=${lib.getExe keepassxc}
        EOF

        chmod 333 $out/share/dbus-1/services/org.freedesktop.secrets.service
      '';
    })
  ];

  services.gnome.gnome-keyring.enable = false;

  xdg.portal.config = {
    common = lib.mkForce {
      "org.freedesktop.impl.portal.Secret" = "keepassxc";
    };
  };
}
