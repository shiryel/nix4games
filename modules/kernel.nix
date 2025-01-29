{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.kernel.enable {
  # Good alternatives:
  # - linuxPackages_zen
  # - linuxPackages_xanmod_latest
  # - linuxPackages_hardened
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = [
    config.boot.kernelPackages.turbostat

    # see: https://wiki.archlinux.org/title/Realtime_kernel_patchset#Latency_testing_utilities
    # sudo cyclictest --smp -p98 -m
    # sudo hwlatdetect --duration=120 --threshold=15
    pkgs.rt-tests
  ];

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

    # Maximum number of active memory map areas
    # kernel default: (USHRT_MAX - MAPCOUNT_ELF_CORE_MARGIN)
    "vm.max_map_count" = 2147483642;

    ##########
    # Custom #
    ##########

    # High Precision Event Timer (similar to rtc.c driver)
    # mainly used for audio, interrupts can be calculated like: 1000/64 = 15.625ms per CPU
    # see:
    # - https://linuxmusicians.com/viewtopic.php?t=25625
    # - https://github.com/torvalds/linux/blob/e0daef7de1acecdb64c1fa31abc06529abb98710/Documentation/admin-guide/rtc.rst#old-pcat-compatible-driver--devrtc
    # notes:
    # - may reduce audio crackling
    "dev.hpet.max-user-freq" = 2048; # default: 64 hz

    # Max file-handles allocations
    # configure with a rate of 256 for every 4M of RAM (e.g. for 32GB: 32768/4*256 = 2097152)
    # NOTE: it's user limited by pam.loginLimits nofile!
    "fs.file-max" = 2097152; # default: 9223372036854775807

    # https://wiki.archlinux.org/title/Sysctl#Virtual_memory
    # Percentage of total available memory that contains free pages and reclaimable pages at
    # which the background kernel flusher threads will start writing out dirty data
    # A sane value is ~1GB for a fast NVMe, e.g.: 3% of 16 GB = ~491 MB
    "vm.dirty_ratio" = 6; # default: 20

    # Percentage of total available memory that contains free pages and reclaimable pages at
    # which the background kernel flusher threads will start writing out dirty data.
    # A sane value is ~500MB
    "vm.dirty_background_ratio" = 3; # default: 10

    # https://wiki.archlinux.org/title/Sysctl#VFS_cache
    # The value controls the tendency of the kernel to reclaim the memory which is used for
    # caching of directory and inode objects (VFS cache). Lowering it from the default value
    # of 100 makes the kernel less inclined to reclaim VFS cache (do not set it to 0, this
    # may produce out-of-memory conditions)
    "vm.vfs_cache_pressure" = 50; # default: 100

    ############################################################
    # Tweaking kernel parameters for response time consistency #
    ############################################################
    # https://wiki.archlinux.org/title/Gaming#Tweaking_kernel_parameters_for_response_time_consistency

    # Proactive compaction for (Transparent) Hugepage allocation reduces the average but not
    # necessarily the maximum allocation stalls. Disable proactive compaction because it
    # introduces jitter according to kernel documentation
    "vm.compaction_proactiveness" = 0; # default: 20

    # Reduce the watermark boost factor to defragment only one pageblock (2MB on 64-bit x86) in
    # case of memory fragmentation. After a memory fragmentation event this helps to better keep
    # the application data in the last level processor cache.
    "vm.watermark_boost_factor" = 1; # default: 15000

    # If you have enough free RAM increase the number of minimum free Kilobytes to avoid stalls on
    # memory allocations. Do not set this below 512 KB or above 5% of your systems memory. Reserving 1GB:
    "vm.min_free_kbytes" = 524288; # default: 67584

    # If you have enough free RAM increase the watermark scale factor to further reduce the
    # likelihood of allocation stalls. Setting watermark distances to 2.5% of RAM:
    "vm.watermark_scale_factor" = 250; # default: 10

    # Rough relative IO cost of swapping and filesystem paging
    # - may reduces audio crackling
    "vm.swappiness" = 10; # default: 60

    # Disable zone reclaim (locking and moving memory pages that introduces latency spikes)
    "vm.zone_reclaim_mode" = 0; # default: 0

    # Reduce the maximum page lock acquisition latency while retaining adequate throughput
    "vm.page_lock_unfairness" = 1; # default: 5

    ########################
    # Persistent Hugepages #
    ########################
    # https://gist.github.com/sjenning/b6bed5bf029c9fd6f078f76b37f0a73f
    #
    # "vm.nr_hugepages" = 125; # 2M per page = 250MB reserved
    # "vm.nr_overcommit_hugepages" = 875; # 250MB + 1750MB = 2GB max
  };

  # There certain uncertainty about THP, as it can improve performance but also degrade it depending on the situation
  # https://www.reddit.com/r/linux_gaming/comments/uhfjyt/underrated_advice_for_improving_gaming/
  # Check with:
  #   cat /proc/meminfo | grep HugePages
  # (AnonHugePages are the THP)
  #environment.etc."tmpfiles.d/thp.conf".text = ''
  #  w /sys/kernel/mm/transparent_hugepage/enabled - - - - never
  #'';

  boot = {
    kernelParams = [
      "threadirqs"
    ];
    postBootCommands = ''
      echo 2048 > /sys/class/rtc/rtc0/max_user_freq
    '';
    #setpci -v -d *:* latency_timer=b0
  };

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
