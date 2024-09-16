{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.kernel.enable {
  # Good alternatives:
  # - linuxPackages_zen
  # - linuxPackages_xanmod_latest
  # - linuxPackages_hardened
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    # Disable mitigation of: "one user process from a guest system may block other 
    # cores from accessing memory and cause performance degradation across the whole system"
    # as some games makes heavy use of this feature, and this penalises them (or crash)
    # NOTE: when finding a split_lock the following log will be created: "took a split_lock trap at address:"
    # https://lwn.net/Articles/790464/
    # https://www.phoronix.com/news/Linux-Splitlock-Hurts-Gaming
    # https://github.com/ValveSoftware/steam-for-linux/issues/8003
    "kernel.split_lock_mitigate" = 0;
    # Used to reboot the machine in the case that the kernel reaches a halting state.
    # Normal users don't need this feature and can disable it, as it can generate a high number of
    # interrupts, slowing down the system
    # https://wiki.archlinux.org/title/Improving_performance#Watchdogs
    # https://unix.stackexchange.com/questions/353895/should-i-disable-nmi-watchdog-permanently-or-not
    "kernel.nmi_watchdog" = 0;
    "kernel.soft_watchdog" = 0;
    "kernel.watchdog" = 0;

    ################################
    # Default configs from SteamOS # 
    ################################
    # check with:
    # https://steamdeck-packages.steamos.cloud/archlinux-mirror/jupiter-main/os/x86_64/steamos-customizations-jupiter-20240906.1-1-any.pkg.tar.zst

    # This is required due to some games being unable to reuse their TCP ports
    # if they're killed and restarted quickly - the default timeout is too large.
    "net.ipv4.tcp_fin_timeout" = 5;

    # "Larger slice values will reduce transfer overheads, while smaller values allow for more fine-grained consumption."
    # https://www.kernel.org/doc/html/latest/scheduler/sched-bwc.html
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;

    # same as FILE DESCRIPTORS configured on pam.loginLimits
    # for now prefer value recommended by esync
    # "vm.max_map_count" = 2147483642; 
  };

  # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/monitoring_and_managing_system_status_and_performance/configuring-huge-pages_monitoring-and-managing-system-status-and-performance
  #boot.kernelParams = [
  #  "hugepages=1000" # 1000 x 2mb = 2GB
  #];

  # see: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/hardened.nix
  boot.blacklistedKernelModules = [
    # Obscure network protocols
    "ax25"
    "netrom"
    "rose"

    # Old or rare or insufficiently audited filesystems
    "adfs"
    "affs"
    "bfs"
    "befs"
    "cramfs"
    "efs"
    "erofs"
    "exofs"
    "freevxfs"
    "f2fs"
    "hfs"
    "hpfs"
    "jfs"
    "minix"
    "nilfs2"
    "ntfs"
    "omfs"
    "qnx4"
    "qnx6"
    "sysv"
    "ufs"
  ];

  security = {
    # required by podman to run containers in rootless mode when using linuxPackages_hardened
    #unprivilegedUsernsClone = true;

    # prevent replacing the running kernel image
    protectKernelImage = true;

    # packages and services can dynamically load kernel modules
    lockKernelModules = false;

    # Kernel Audit
    # * DOCS: 
    #   - https://wiki.archlinux.org/title/Audit_framework
    #   - auditctl -h
    #audit = {
    #  enable = false;
    #  rules = [
    #    "-w /home/shiryel/keep/games -p rwxa"
    #  ];
    #};
  };

  #######
  # TPM #
  #######
  #
  # Trusted Platform Module (TPM) is an international standard for a secure cryptoprocessor, 
  # which is a dedicated microprocessor designed to secure hardware by integrating 
  # cryptographic keys into devices. 
  # - https://security.stackexchange.com/questions/187820/do-a-tpms-benefits-outweigh-the-risks
  #   Another criticism is that it may be used to prove to remote websites that you are running the software they want you to run, or that you are using a device which is not fully under your control. The TPM can prove to the remote server that your system's firmware has not been tampered with, and if your system's firmware is designed to restrict your rights, then the TPM is proving that your rights are sufficiently curtailed and that you are allowed to watch that latest DRM-ridden video you wanted to see. Thankfully, TPMs are not currently being used to do this, but the technology is there.
  #   TPMs make me nervous because a hardware failure could render me unable to access my own keys and data. That seems more likely than a black hat hacker pulling off a root kit on my OS." - https://youtu.be/RW2zHvVO09g
  #
  # More discussions at: https://news.ycombinator.com/item?id=38149441
  security.tpm2 = {
    enable = false;
    # userspace resource manager daemon
    abrmd.enable = false;
  };
}
