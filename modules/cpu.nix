{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.cpu.enable {
  environment.systemPackages = with pkgs; [
    # (0xF: all 4 CPUs, 0xFF: all 8 CPUs, and so on ...)
    # schedtool -
    # schedtool -a 0,1 -n -10 -e
    # schedtool -a 0xFF -n -10 -e (each F is 4 CPUs)
    schedtool
  ];

  # CPU security
  hardware.cpu.amd.updateMicrocode = true;

  powerManagement.cpuFreqGovernor = "performance";

  ##########
  # LIMITS #
  ##########
  # -- DOCS -- 
  # man limits.conf
  # https://wiki.archlinux.org/title/Limits.conf
  #
  # -- TEST --
  # Check system limits: 
  #   ulimit -aS # soft
  #   ulimit -aH # hard
  # Check the maximum of file descriptors
  #   ulimit -Hn
  #   cat /proc/sys/fs/file-max (for system wide)
  #   cat /proc/sys/fs/nr_open (for system wide)
  # Check number of process per user:
  #   ps h -LA -o user | sort | uniq -c | sort -n
  #
  # -- NOTE -- 
  # These limits do not apply to systemd services, use systemd.extraConfig instead

  security.pam.loginLimits = [
    # MAXIMUM NICE - Global hint for setting priority

    # maximum nice priority allowed to raise to [-20,19] (negative values boost process priority)
    #
    # The 'nice' value should do the same as 'rtprio' but for standard CFQ scheduling
    # It sets the initial process spawned when PAM is setting these limits to that nice vaule, 
    # a normal user can then go to that nice level or higher without needing root to set them [1]
    #
    # The current Linux scheduler gives a program at -1 twice as much CPU power as 
    # a 0, and a program at -2 twice as much as a -1, and so forth. This means that 99.9999046% 
    # (1-(100/(2^20*100)))*100 of your CPU time will go to the program that's at -20, but some small fraction
    # does go to the program at 0. The program at 0 will feel like it's running on a 200kHz processor![2][3]
    { domain = "root"; type = "-"; item = "nice"; value = "-20"; }
    # Do not set -20, as the root needs it to be able to fix an unresponsive system[1]
    #{ domain = "@users"; type = "-"; item = "nice"; value = "-7"; } # 99.60%
    { domain = "*"; type = "hard"; item = "nice"; value = "-8"; } # 99.60% | same as steamos

    # DEFAULT PRIORITY - Task priority for SCHED_OTHER, SCHED_BATCH and SCHED_IDLE

    # the priority to run user process with [-20,19] (negative values boost process priority)
    { domain = "@users"; type = "-"; item = "priority"; value = "0"; }

    # MAXIMUM REAL-TIME PRIORITY - Task priority for SCHED_FIFO and SCHED_RR

    # Check max with: schedtool -r
    # Check current with: ulimit -a[S|H]
    { domain = "@users"; type = "-"; item = "rtprio"; value = "50"; } # basically 100%, but depends on other RR tasks priority

    # FILE DESCRIPTORS
    # Number of file descriptors any process owned by the specified domain  can have open at any one time.
    # Certain games needs this value as hight as 8192, or in case of lutris with esync, >=524288 [4][5],
    # but setting this value too high or to unlimited may break some tools like fakeroot [6]
    { domain = "*"; type = "hard"; item = "nofile"; value = "1048576"; } # recommended by esync [5]
    { domain = "*"; type = "soft"; item = "nofile"; value = "8192"; } # default 1024
    { domain = "@audio"; type = "soft"; item = "nofile"; value = "65536"; }

    # MEMORY

    # Memory locked memory is never swappable and remains resident. This value is strictly 
    # controlled because it can be abused by people to starve a system of memory and cause swapping [1]
    #{ domain = "@audio"; type = "-"; item = "memlock"; value = "524288"; } # default 8192
  ];
  # NOTE FOR GAMING:
  # SCHED_ISO was designed to give users a SCHED_RR-similar class. 
  # To quote Con Kolivas: "This is a non-expiring scheduler policy designed to guarantee 
  # a timeslice within a reasonable latency while preventing starvation. Good for gaming, 
  # video at the limits of hardware, video capture etc."
  #
  # SCHED_ISO is now somewhat deprecated; SCHED_RR is now possible for normal users,
  # albeit to a limited amount only. See newer kernels. (from `man schedtool`)
  #
  # [1] - https://serverfault.com/questions/487602/linux-etc-security-limits-conf-explanation
  # [2] - https://wiki.archlinux.org/title/Limits.conf#nice
  # [3] - https://unix.stackexchange.com/questions/334170/is-changing-the-priority-of-a-games-process-to-realtime-bad-for-the-cpu
  # [4] - https://github.com/lutris/docs/blob/master/HowToEsync.md
  # [5] - https://github.com/zfigura/wine/blob/esync/README.esync
  # [6] - https://wiki.archlinux.org/title/Limits.conf#nofile

  ############
  # GAMEMODE #
  ############

  # You can simulate gamemode with cpu scaling_governor[1], renice[2], softrealtime[3] and GPU configs[4]
  # [1] - powerManagement.cpuFreqGovernor = "performance";
  #       cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
  # [2] - nice -n -1 %command%
  # [3] - only available on kernels with the muqss scheduler (SCHED_ISO) like zen and xenmod
  # [4] - echo high > /sys/class/drm/card0/device/power_dpm_force_performance_level
  #programs.gamemode = {
  #  enable = true;
  #  settings = {
  #    general = {
  #      renice = 10; # sets renice to -10
  #      softrealtime = "auto"; # needs SCHED_ISO ("auto" will set with >= 4 cpus)
  #      inhibit_screensaver = 0;
  #    };
  #  };
  #};

  #systemd.user.services.gamemoded.serviceConfig = {
  #  # needs SUIDSGID and Devices to work
  #  NoNewPrivileges = true;
  #  ProtectSystem = "full"; # makes /boot, /etc, and /usr directories read-only
  #  ProtectHome = true; # hides /home, /root and /run/user
  #  PrivateNetwork = true;
  #  ProtectControlGroups = true; # makes /sys/fs/cgroup/ read-only
  #  #CapabilityBoundingSet = "CAP_SYS_NICE";
  #};
}
