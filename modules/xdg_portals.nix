# Run screenshare wayland and improves containerized apps
#
# -- TEST --
#
# `busctl --user` or `qdbusviewer` to see portal services
# `ashpd-demo` to manually test the portal services
# `python3Packages.keyring` to test the secrets service
#
# Test DBUS calls with:
#   nix shell nixpkgs#glib
#   gdbus call --session --dest="org.freedesktop.portal.Desktop" --object-path=/org/freedesktop/portal/desktop --method=org.freedesktop.portal.OpenURI.OpenURI '' 'https://example.com' '{}'
#
# To list all interfaces available on DBUS use:
# (for session)
#   dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames
# (for system)
#   dbus-send --system --dest=org.freedesktop.DBus --type=method_call --print-reply /org/freedesktop/DBus org.freedesktop.DBus.ListNames
#
# To list the methods available on the DBUS interface use:
#   dbus-send --session --type=method_call --print-reply --dest=org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Introspectable.Introspect
#
# Check which DE xdg is using with:
#   XDG_UTILS_DEBUG_LEVEL=5 xdg-open "https://example.com"
#
# -- DOCS --
# 
# For configuring Dbus portals:
# https://flatpak.github.io/xdg-desktop-portal/docs/api-reference.html

{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.xdg-portals.enable {
  xdg.portal = {
    enable = true;

    # https://wiki.archlinux.org/title/XDG_Desktop_Portal#List_of_backends_and_interfaces
    # NOTES:
    # - xdg-desktop-portal just handles request, it needs extraPortals implementing the backend (e.g.: 
    # xdg-desktop-portal-gtk for sandbox apps and common services like "Open With...") 
    # - some apps include their own services, see: `ls /run/current-system/sw/share/dbus-1/services/`
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk # may need GTK_USE_PORTAL=1 on a app, because setting it gtksystem wide is unstable
      xdg-desktop-portal-gnome
    ];

    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1050913
    config = {
      # cat /etc/xdg/xdg-desktop-portal/portals.conf
      common = lib.mkForce {
        default = [ "gtk" ];
      };

      # https://github.com/emersion/xdg-desktop-portal-wlr/blob/master/contrib/wlroots-portals.conf
      sway = {
        default = [ "wlr" "gtk" ];

        #"org.freedesktop.impl.portal.ScreenCast" = "hyprland";
        #"org.freedesktop.impl.portal.Screenshot" = "hyprland";

        # ignore inhibit because gtk portal always returns as success,
        # despite the wlr portal not having an implementation,
        # stopping firefox from using wayland idle-inhibit
        # https://github.com/labwc/labwc/pull/2205
        # https://github.com/emersion/xdg-desktop-portal-wlr/pull/315
        "org.freedesktop.impl.portal.Inhibit" = "none";
      };

      niri = {
        default = [ "gnome" "gtk" ];

        "org.freedesktop.impl.portal.Access" = "gtk";
        "org.freedesktop.impl.portal.Notification" = "gtk";

        # disabling some useless portals...
        "org.freedesktop.portal.RemoteDesktop" = "none";
        "org.freedesktop.portal.Wallpaper" = "none";
      };
    };

    # Force apps running on FHS or flatpack to use xdg-open by using desktop portals
    # see: https://github.com/NixOS/nixpkgs/issues/160923
    # To check if systemd + desktop portals is working use:
    #   systemd-run --user -t gio mime x-scheme-handler/https
    xdgOpenUsePortal = true;
  };
}

