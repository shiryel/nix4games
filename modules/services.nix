{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.services.enable {
  # lets android devices connect
  services.udev.packages = [ pkgs.android-udev-rules ];
  users.groups.adbusers = { }; # To enable device as a user device if found (add an "android" SYMLINK)

  # Trimming enables the SSD to more efficiently handle garbage collection,
  # which would otherwise slow future write operations to the involved blocks.
  services.fstrim.enable = true;

  ############
  # SECURITY #
  ############

  # sets a gnome-keyring on dbus and portals, the security.wrapper is not a setuid, so its not a security risk
  services.gnome.gnome-keyring.enable = true;

  security.sudo.execWheelOnly = false; # btrbk needs this false to work

  services.dbus = {
    apparmor = "enabled";
    implementation = "broker"; # dbus-broker is the default on Arch & Fedora
  };

  # xdg's autostart is unecessary
  xdg.autostart.enable = lib.mkForce false;

  # antivirus clamav and keep the signatures' database updated
  # see: https://github.com/anoadragon453/dotfiles/blob/de37bcd64f702b16115fb405f559e979a1e0260e/modules/base/antivirus.nix#L69
  #services = {
  #  clamav.daemon.enable = true;
  #  clamav.updater.enable = true;
  #};

  #######
  # SSH #
  #######
  # NOTE: We use GNUPG agent instead of SSH agent

  # SSH AGENT
  programs.ssh = {
    startAgent = true;
    knownHosts = {
      "github.com".hostNames = [ "github.com" ];
      "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

      "gitlab.com".hostNames = [ "gitlab.com" ];
      "gitlab.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";

      "git.sr.ht".hostNames = [ "git.sr.ht" ];
      "git.sr.ht".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZvRd4EtM7R+IHVMWmDkVU3VLQTSwQDSAvW0t2Tkj60";

      "codeberg.org".hostNames = [ "codeberg.org" ];
      "codeberg.org".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVIC02vnjFyL+I4RHfvIGNtOgJMe769VTF1VR4EB3ZB";
    };
  };

  # SSH DAEMON (to do connections)
  services.openssh = {
    enable = true;
    allowSFTP = false;
    openFirewall = lib.mkForce false;
    startWhenNeeded = true;
    hostKeys = [ ]; # do not generate any host keys
    settings = {
      PermitRootLogin = lib.mkForce "no";
      PasswordAuthentication = lib.mkForce false;
      X11Forwarding = false;
      AllowAgentForwarding = "no";
      AllowStreamLocalForwarding = "no";
      AuthenticationMethods = "publickey";
    };
  };

  ###############
  # GNUPG AGENT #
  ###############

  # Generate GPG Keys With Curve Ed25519: https://www.digitalneanderthal.com/post/gpg/
  # See:
  # - https://www.latacora.com/blog/2019/07/16/the-pgp-problem/
  # - https://words.filippo.io/giving-up-on-long-term-pgp/
  # - https://soatok.blog/2024/11/15/what-to-use-instead-of-pgp/
  programs.gnupg.agent = {
    enable = false;
    # cache SSH keys added by the ssh-add
    enableSSHSupport = true;
    # set up a Unix domain socket forwarding from a remote system
    # enables to use gpg on the remote system without exposing the private keys to the remote system
    enableExtraSocket = false;
    # allows web browsers to access the gpg-agent daemon
    enableBrowserSocket = false;
    # NOTE: "gnome3" flavor only works with Xorg
    # To reload config: gpg-connect-agent reloadagent /bye
    pinentryPackage = pkgs.pinentry-gnome3; # use "pkgs.pinentry-curses" for console only
  };

  environment.systemPackages = [ pkgs.gnupg ];
}
