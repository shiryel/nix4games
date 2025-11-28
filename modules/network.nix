# Enables dnscrypt-proxy for security, to cache requests and to find the best DNS server to connect
#
# -- TEST --
# To see the logs:
#   sudo cat /var/log/dnscrypt-proxy/dnscrypt-proxy.log
#
# To test if its working as expected:
#   dig +short txt qnamemintest.internet.nl
#   https://www.cloudflare.com/ssl/encrypted-sni/
#
# -- NOTES --
# ESNI support is only from the browser
#   https://github.com/DNSCrypt/dnscrypt-proxy/issues/941
#
# You can configure dnscrypt to block ads
#
# -- DOCS --
# - https://nixos.wiki/wiki/Encrypted_DNS
# - https://wiki.archlinux.org/title/Systemd-networkd

{ config, lib, ... }:

lib.mkIf config.nix4games.network.enable {
  # does not have access to the network as specified bellow
  # by systemd.services
  services.nscd.enableNsncd = true;

  # started from sway, so we can have the tray-icon
  programs.nm-applet.enable = lib.mkDefault false;

  networking = {
    networkmanager = {
      enable = true;
      ethernet.macAddress = "random";
      wifi.scanRandMacAddress = true;
    };
    # explicity disable dhcpcd 
    useDHCP = false;
    dhcpcd.enable = false;
    ################################################
    # defaults for DNSCrypt (both DHCP and Networkd)
    nameservers = [ "127.0.0.1" "::1" ];
    # If using dhcpcd:
    dhcpcd.extraConfig = "nohook resolv.conf";
    # If using NetworkManager:
    networkmanager.dns = "none";
    ################################################
  };

  # Do not wait for a network connection to start the system
  # (adds +6 seconds to the `systemd-analyze critical-chain`)
  systemd.services.NetworkManager-wait-online.enable = false;

  users.extraGroups.networkmanager.members = [ config.nix4games.mainUser ];

  # FIXES: failed to sufficiently increase receive buffer size (from dnscrypt-proxy.service)
  # https://github.com/quic-go/quic-go/wiki/UDP-Receive-Buffer-Size
  boot.kernel.sysctl."net.core.rmem_max" = 7500000; # default 212992
  boot.kernel.sysctl."net.core.wmem_max" = 7500000; # default 212992

  services = {
    resolved.enable = false;

    dnscrypt-proxy = {
      enable = true;
      # Use defaults from: https://github.com/DNSCrypt/dnscrypt-proxy/blob/master/dnscrypt-proxy/example-dnscrypt-proxy.toml
      upstreamDefaults = true;
      settings = {
        log_file = "/var/log/dnscrypt-proxy/dnscrypt-proxy.log";
        log_file_latest = true;

        ipv6_servers = true;
        dnscrypt_servers = true;
        doh_servers = true;

        require_dnssec = true;
        require_nolog = true;
        require_nofilter = true;

        # Load-balancing: top 6, update ping over time
        lb_strategy = "p6";
        lb_estimator = true;

        # Enable support for HTTP/3 (DoH3, HTTP over QUIC)
        # Note that, like DNSCrypt but unlike other HTTP versions, this uses
        # UDP and (usually) port 443 instead of TCP.
        http3 = true;

        # DNSCrypt: Create a new, unique key for every single DNS query
        # This may improve privacy but can also have a significant impact on CPU usage
        # Only enable if you don't have a lot of network load
        dnscrypt_ephemeral_keys = true;

        # Cache
        # https://00f.net/2019/11/03/stop-using-low-dns-ttls/
        cache = true;
        cache_size = 8192;
        #cache_min_ttl = 86400; # 1 day
        cache_min_ttl = 7200; # 2 hours
        cache_max_ttl = 86400; # 1 day
        cache_neg_min_ttl = 60; # 1 min
        cache_neg_max_ttl = 600; # 10 min

        # - To a faster startup when configuring this file
        # - You can choose a specific set of servers from https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v3/public-resolvers.md
        # server_names = [ "nextdns" "nextdns-ipv6" "cloudflare" "cloudflare-ipv6" ];

        ###############
        # ODoH Config #
        ###############
        # (WIP)
        #
        # CAUTION: 
        # - ODoH relays cannot be used with DNSCrypt servers, 
        # - DNSCrypt relays cannot be used to connect to ODoH servers.
        # - ODoH relays can only connect to servers supporting the ODoH protocol, not regular DoH servers.
        # In other words, only combine ODoH relays with ODoH servers.
        #
        # odoh_servers = true;
        #
        # sources.odoh-servers =
        #   {
        #     urls = [
        #       "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-servers.md"
        #       "https://download.dnscrypt.info/resolvers-list/v3/odoh-servers.md"
        #       "https://ipv6.download.dnscrypt.info/resolvers-list/v3/odoh-servers.md"
        #     ];
        #     cache_file = "odoh-servers.md";
        #     minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        #     refresh_delay = 24;
        #   };
        # sources.odoh-relays = {
        #   urls = [
        #     "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/odoh-relays.md"
        #     "https://download.dnscrypt.info/resolvers-list/v3/odoh-relays.md"
        #     "https://ipv6.download.dnscrypt.info/resolvers-list/v3/odoh-relays.md"
        #   ];
        #   cache_file = "odoh-relays.md";
        #   minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        #   refresh_delay = 24;
        # };
      };
    };
  };
}
