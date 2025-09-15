{ config, lib, pkgs, ... }:

with lib;

let
  # themes: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/themes
  # icons/cursors: https://github.com/NixOS/nixpkgs/tree/master/pkgs/data/icons

  # DRACULA THEMES: Dracula | Dracula-Solid | Dracula-purple | Dracula-purple-solid
  # OTHER THEMES: Adwaita:dark | Mint-Y-Dark
  main_theme_gtk = "Dracula";
  main_theme_qt = "Dracula-Solid";
  main_theme_package = pkgs.dracula-theme;

  cursor_theme = "Nordzy-cursors";
  cursor_theme_package = pkgs.nordzy-cursor-theme;
  cursor_size = 24;

  icon_theme = "Tela-purple"; # WhiteSur-dark
  icon_theme_package = pkgs.tela-icon-theme;

  gtk2_gtkfilechooser = pkgs.writeText "gtk2-gtkfilechooser" (lib.generators.toINI { } {
    "Filechooser Settings".StartupMode = "cwd";
  });

  gtk2_gtkrc = pkgs.writeText "gtk2-gtkrc" ''
    gtk-theme-name="${main_theme_gtk}"
    gtk-icon-theme-name="${icon_theme}"
    gtk-cursor-theme-name="${cursor_theme}"
    gtk-enable-animations=1
    gtk-primary-button-warps-slider=0
    gtk-toolbar-style=3
    gtk-menu-images=1
    gtk-button-images=1
  '';

  # https://docs.gtk.org/gtk3/class.Settings.html
  # https://docs.gtk.org/gtk4/class.Settings.html
  gtk3-4_settings = pkgs.writeText "gtk3-4-settings" ''
    [Settings]
    gtk-theme-name=${main_theme_gtk}
    gtk-icon-theme-name=${icon_theme}
    gtk-cursor-theme-name=${cursor_theme}
    gtk-application-prefer-dark-theme=true
    gtk-decoration-layout=icon:minimize,maximize,close
    gtk-enable-animations=true
    gtk-recent-files-enabled=1
    gtk-recent-files-max-age=3 # in days
  '';

  #gtk4_css = pkgs.writeText "gtk4-css" ''
  #  /**
  #   * GTK 4 reads the theme configured by gtk-theme-name, but ignores it.
  #   * It does however respect user CSS, so import the theme from here.
  #  **/
  #  @import url("file://${pkgs.dracula-theme}/share/themes/Dracula/gtk-4.0/gtk.css");
  #'';

  kvantum_config = pkgs.writeText "kvantum_config" ''
    [General]
    theme=${main_theme_qt}
  '';
in
mkIf config.nix4games.dark-theme.enable {
  gtk.iconCache.enable = true;

  systemd.user.tmpfiles.users."${config.nix4games.mainUser}".rules = [
    "L+ %h/.config/gtk-2.0/gtkfilechooser.ini 777 - - - ${gtk2_gtkfilechooser}"
    "L+ %h/.config/gtk-2.0/gtkrc 777 - - - ${gtk2_gtkrc}"
    "L+ %h/.config/gtk-3.0/settings.ini 777 - - - ${gtk3-4_settings}"
    "L+ %h/.config/gtk-4.0/settings.ini 777 - - - ${gtk3-4_settings}"

    # https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications#Overview

    # to find compatible themes: nix-locate -r 'kvconfig'
    "L+ %h/.config/Kvantum/kvantum.kvconfig 777 - - - ${kvantum_config}"
    "L+ %h/.config/Kvantum/${main_theme_qt} 777 - - - ${main_theme_package}/share/Kvantum/${main_theme_qt}"
  ];

  environment.systemPackages = [
    main_theme_package
    icon_theme_package
    cursor_theme_package
    pkgs.libsForQt5.qtstyleplugin-kvantum
    pkgs.qt6Packages.qtstyleplugin-kvantum
    pkgs.libsForQt5.qt5ct
    pkgs.kdePackages.qt6ct

    #xsettingsd # Some GTK applications running via XWayland, and some Java applications, need an XSettings daemon running in order to pick up the themes and font settings.
  ];

  qt = {
    enable = true;
    style = "kvantum";
    platformTheme = "qt5ct";
  };

  environment.variables = {
    GTK_THEME = main_theme_gtk;
    XCURSOR_SIZE = cursor_size;
    # See https://wiki.hyprland.org/Configuring/Environment-variables/
    XCURSOR_THEME = cursor_theme;
    #ADW_DISABLE_PORTAL = 1; # recommended when not using xdg-desktop-portal-gnome, see: https://gitlab.gnome.org/GNOME/libadwaita/-/commit/e715fae6a509db006a805af816f9d163f81011ef
    #XCURSOR_PATH = "$XCURSOR_PATH\${XCURSOR_PATH:+:}${cursor_theme_package}/share/icons";
  };

  #########
  # Fonts #
  #########
  # Compare on: https://www.programmingfonts.org/
  # Best fonts:
  # - https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/Cousine
  # - https://input.djr.com/
  # - https://www.jetbrains.com/lp/mono/
  # - https://rubjo.github.io/victor-mono/
  # - https://github.com/ryanoasis/nerd-fonts/tree/master/patched-fonts/CascadiaCode

  # Font/DPI configuration optimized for HiDPI displays
  #hardware.video.hidpi.enable = true;

  i18n.defaultLocale = "en_US.UTF-8";
  # real tty font
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # NOTE: on Wayland each WM/DE has it's own way to configure xkb
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
    options = "nodeadkeys";
  };

  # Enables font stem darkening
  # https://freetype.org/freetype2/docs/hinting/text-rendering-general.html#experimental-stem-darkening-for-the-auto-hinter
  environment.sessionVariables.FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";

  fonts = {
    fontconfig = {
      enable = true;
      # not very useful in high DPI displays
      # maybe set to style = full and antialias = false? see: https://datagubbe.se/fontfest/
      hinting = {
        enable = true;
        # https://freetype.org/freetype2/docs/hinting/text-rendering-general.html
        style = "slight";
        autohint = false;
      };
    };

    fontDir.enable = true;

    enableGhostscriptFonts = true;

    enableDefaultPackages = true;
    packages = with pkgs; [
      # To list all fonts use:
      #   builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts)
      nerd-fonts.cousine
      nerd-fonts.symbols-only # SymbolsOnly is used to mix fonts like on the waybar

      carlito
      dejavu_fonts
      fira
      fira-code
      fira-mono
      inconsolata
      inter
      libertine
      noto-fonts
      noto-fonts-emoji
      noto-fonts-extra
      roboto
      roboto-mono
      roboto-slab
      source-code-pro
      source-sans-pro
      source-serif-pro
      twitter-color-emoji
      corefonts
    ];

    # cd /nix/var/nix/profiles/system/sw/share/X11/fonts
    # fc-query DejaVuSans.ttf | grep '^\s\+family:' | cut -d'"' -f2 
    # OR
    # fc-list | grep Cousine
    fontconfig.defaultFonts = {
      sansSerif = [ "Source Sans Pro" ];
      serif = [ "Source Serif Pro" ];
      monospace = [ "Cousine Nerd Font" ]; # icons "without mono"
      emoji = [ "Twitter Color Emoji" ];
    };
  };

  programs.dconf = {
    enable = true;
    profiles = {
      user.databases = [
        {
          settings."org/gnome/desktop/interface" = {
            gtk-theme = main_theme_gtk;
            icon-theme = icon_theme;
            color-scheme = "prefer-dark";
            cursor-theme = cursor_theme;
            cursor-size = lib.gvariant.mkInt32 cursor_size;
            gtk-im-module = "gtk-im-context-simple";
            font-antialiasing = "rgba";
            font-hinting = "full";
            #document-font-name = main_font;
            #font-name = main_font;
            #monospace-font-name = mono_font;
          };
        }
      ];
    };
  };
}
