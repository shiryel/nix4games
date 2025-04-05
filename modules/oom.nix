{ config, lib, ... }:

lib.mkIf config.nix4games.oom.enable (
  #assert lib.warnIf (config.zramSwap.enable == true) "OOM without zramSwap will kill apps too early!" true;
  #assert lib.warnIf (config.swapDevices != [ ]) "OOM with an IO swap will wait for swap to fill up (usually slowly) before triggering!" true;
  {
    services.earlyoom.enable = true;
    systemd.oomd.enable = false;

    systemd.services.earlyoom.serviceConfig = {
      ProtectHome = "tmpfs";
      ProtectSystem = "full";
      PrivateNetwork = true;
      PrivateTmp = true;
      RestrictSUIDSGID = true;
      ProtectControlGroups = true;
      ProtectKernelTunables = true;
    };
  }
)
