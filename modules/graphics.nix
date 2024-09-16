# -- NOTE -- 
# There is 3 implementations for OpenGL/Vulkan graphics:
# Mesa RADV, AMDVLK, AMDVLK-PRO
# Mesa RADV is the most performant and stable in most games
#
# -- NOTE -- 
# On BIOS, enable "Above 4G Decoding" with UEFI only to let linux GPU drivers to have the
# option to choose to use SAM (a.k.a. Resize BAR).
# Note that the option Resize BAR on BIOS apparently(?) forces the use of SAM.
# https://www.reddit.com/r/linux_gaming/comments/v58ts5/quick_heads_up_about_something_i_discovered/
# https://wiki.archlinux.org/title/Improving_performance#Enabling_PCI_Resizable_BAR
#
# -- TEST -- 
# You can disable vsync for openGL using
#   vblank_mode=0
#   mangohud vblank_mode=0 glxgears
#
# You can disable vsync for Mesa Vulkan using
#   MESA_VK_WSI_PRESENT_MODE=mailbox (or immediate)
#   mangohud MESA_VK_WSI_PRESENT_MODE=immediate vkgears
#
# -- DOCS --
# https://docs.mesa3d.org/envvars.html
# https://registry.khronos.org/vulkan/specs/1.3-extensions/man/html/VkPresentModeKHR.html

# Other relevant issues:
# RX 7900XTX - https://gitlab.freedesktop.org/drm/amd/-/issues/2434, https://gitlab.freedesktop.org/mesa/mesa/-/issues/8661

{ config, lib, pkgs, ... }:

lib.mkIf config.nix4games.graphics.enable {
  # Useful for debugging
  environment.systemPackages = with pkgs; [
    glxinfo # glxgears
    vulkan-tools # vulkaninfo
    clinfo

    rocmPackages.rocminfo
    #rocmPackages.rocm-smi # ROCm System Management Interface 
  ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true; # required by steam
      #setLdLibraryPath = true;

      # https://nixos.org/manual/nixos/unstable/#sec-gpu-accel
      # https://wiki.nixos.org/wiki/Accelerated_Video_Playback
      extraPackages = with pkgs; [
        #amdvlk # https://wiki.gentoo.org/wiki/AMDVLK
        #xorg.xf86videoamdgpu

        ### Hardware video acceleration ###
        # https://trac.ffmpeg.org/wiki/HWAccelIntro
        # https://trac.ffmpeg.org/wiki/Hardware/VAAPI
        # initially developed by Intel but can be used in combination with other devices
        #intel-media-driver # iHD driver, for modern GPUs
        #intel-vaapi-driver # i965 driver, for older GPUs

        # https://github.com/i-rinat/libvdpau-va-gl
        # VDPAU driver with VA-API/OpenGL backend.
        libvdpau-va-gl

        ### OpenCL ###
        # https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/amd/default.nix#L39
        rocmPackages.clr
        rocmPackages.clr.icd
      ];
    };
  };


  # Make sure that RADV is the default even if amdvlk is installed
  environment.sessionVariables = { AMD_VULKAN_ICD = "RADV"; };

  # Enable support to AMD GPU on some software
  # e.g.: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/tools/system/btop/default.nix#L12
  nixpkgs.config.rocmSupport = true;

  # https://wiki.archlinux.org/title/AMDGPU#Boot_parameter
  #boot.kernelParams = [ "amdgpu.ppfeaturemask=0xfff7ffff" ];

  # Overclock/Fan Control of CPU/GPU
  #programs.corectrl.enable = true;
  #services.dbus.packages = [ pkgs.corectrl ];
  #users.groups.corectrl = { };
  #users.extraGroups.corectrl.members = [ "shiryel" ];

  # Load the correct driver right away on early KMS
  # NOTE: If you don't use Plymouth, early KMS might actually make the boot sequence worse, 
  # because the flicker might heppen during encryption password entry.
  #boot.initrd.kernelModules = [ "amdgpu" ];

  # Some softwares require these paths for hardware acceleration or for using python GPU libs
  #systemd.tmpfiles.rules = [
  #  "L+ /opt/rocm/hip - - - - ${pkgs.rocmPackages.clr}"
  #  "L+ /opt/amdgpu - - - - ${pkgs.libdrm}"
  #];

  environment.etc = {
    # https://wiki.gentoo.org/wiki/AMDVLK
    "X11/xorg.conf".source = pkgs.writeText "xorg.conf" ''
      Section "Device"
        Identifier "AMDgpu"
        Driver "amdgpu"
        Option  "DRI" "3"
      EndSection
    '';
  };
}
