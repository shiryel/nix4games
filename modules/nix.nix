{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.nix.enable {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
    '';
    gc = {
      automatic = true;
      persistent = true;
      dates = "weekly";
      options = "--delete-old --delete-older-than 7d";
    };
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  documentation = {
    man = {
      enable = true;
      generateCaches = false; # generate the index (needed by tools like apropos)
    };
    dev.enable = true;
    nixos.enable = true;
  };

  environment.systemPackages = with pkgs; [
    man-pages # linux
    man-pages-posix # POSIX
    stdmanpages # GCC C++
    clang-manpages # Clang
  ];
}
