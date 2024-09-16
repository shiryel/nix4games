# Run screenshare wayland and improves containerized apps
#
# -- TEST --
# Use qdbusviewer or...
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

lib.mkIf config.nix4games.xdg_portals.enable {
  xdg.portal = {
    enable = true;

    # NOTE: xdg-desktop-portal (for sandbox apps) can't be added directly
    # it relies on other portals (like xdg-desktop-portal-gtk)
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      # may need GTK_USE_PORTAL=1 on a app, because setting it gtksystem wide is unstable
      xdg-desktop-portal-gtk # flatpak xdg-desktop-portal, this provides the "Open With…" window
      xdg-desktop-portal-hyprland
    ];

    config = {
      # https://wiki.archlinux.org/title/XDG_Desktop_Portal#List_of_backends_and_interfaces
      # cat /etc/xdg/xdg-desktop-portal/portals.conf
      sway = {
        default = [
          "wlr"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = "hyprland";
        "org.freedesktop.impl.portal.Screenshot" = "hyprland";
        "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
      };
    };

    # Force apps running on FHS or flatpack to use xdg-open by using desktop portals
    # see: https://github.com/NixOS/nixpkgs/issues/160923
    # To check if systemd + desktop portals is working use:
    #   systemd-run --user -t gio mime x-scheme-handler/https
    xdgOpenUsePortal = true;
  };
}
