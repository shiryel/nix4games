# Relevant links:
# - https://nixos.wiki/wiki/PipeWire
# - https://wiki.linuxaudio.org/wiki/system_configuration
# - https://codeberg.org/rtcqs/rtcqs
# - https://systemd.io/MY_SERVICE_CANT_GET_REATLIME/
# - https://askubuntu.com/questions/656771/process-niceness-vs-priority

{ config, lib, pkgs, ... }:

let
  quantum = 1024; # another good option: 512
  rate = 96000; # default: 48000, another good option: 192000
  qr = quantum / rate;
in
lib.mkIf config.nix4games.audio.enable {
  # Use `pw-profiler` to profile audio and `pw-top`
  # to see the outputs and quantum/rate
  # quantum/rate*1000 = ms delay
  # eg: 3600/48000*1000 = 75ms
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = false;
    pulse.enable = true; # required by pavucontrol
    jack.enable = true;
    wireplumber.enable = true;

    extraConfig = {
      pipewire."92-low-latency".context = {
        properties.default.clock = {
          rate = rate;
          quantum = quantum;
          min-quantum = 32;
          max-quantum = 4096;
        };
        stream.properties = {
          node.latency = qr;
          resample.quality = 1;
        };
        modules = [
          {
            name = "libpipewire-module-rt";
            args = {
              nice.level = -15;
              rt.prio = 85; # FIXME: pw is not respecting this?
              rlimits.enabled = true;
              rtportal.enabled = false;
              rtkit.enabled = false;
            };
            flags = [ "ifexists" "nofail" ];
          }
          {
            name = "libpipewire-module-protocol-pulse";
            args = {
              server.address = [ "unix:native" ];
              pulse.min = {
                req = qr;
                quantum = qr;
                frag = qr;
              };
            };
          }
          #{ "name" = "libpipewire-module-portal"; }
          #{ "name" = "libpipewire-module-spa-node-factory"; }
          #{ "name" = "libpipewire-module-link-factory"; }
        ];
      };
      #jack."92-low-latency" = {
      #  "jack.properties" = {
      #    "rt.prio" = 80;
      #    #"node.latency" = "512/192000";
      #    "node.latency" = "1024/96000";
      #    "jack.show-monitor" = true;
      #    "jack.merge-monitor" = true;
      #    "jack.show-midi" = true;
      #    "jack.fix-midi-events" = true;
      #  };
      #};
    };

    # low latency rules for alsa
    #wireplumber.extraConfig = {
    #  # https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/alsa.html
    #  "92-alsa-low-latency" = {
    #    monitor.alsa.rules = [
    #      {
    #        matches = [{ node.name = "~alsa_output.*"; }];
    #        actions = {
    #          update-props = {
    #            #audio.format = "S32LE";
    #            audio.rate = rate * 2;
    #            api.alsa.period-size = 2;
    #          };
    #        };
    #      }
    #    ];
    #  };
    #};
  };
  hardware.pulseaudio.enable = false;

  # RT Config
  # FIXES: https://github.com/heftig/rtkit/issues/25

  # NOTE: Currently its broken and needs a workaround, see:
  # - https://github.com/heftig/rtkit/issues/32
  # - https://github.com/heftig/rtkit/pull/35
  security.rtkit.enable = false; # it also enables polkit

  security.pam.loginLimits = [
    { domain = "@pipewire"; type = "-"; item = "rtprio"; value = "95"; } # recommended: 95, min: 11, max: 99
    { domain = "@pipewire"; type = "-"; item = "nice"; value = "-19"; } # recommended: -19, min: -20, max: -1
    { domain = "@pipewire"; type = "-"; item = "memlock"; value = "4194304"; } # recommended: 4194304, can be unlimited
  ];

  users.users."${config.nix4games.mainUser}".extraGroups = [ "pipewire" ];
}
