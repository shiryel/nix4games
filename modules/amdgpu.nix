# Custom AMDGPU kernel module with cap_sys_nice check removed

{ config, lib, pkgs, ... }:

let
  kernel = config.boot.kernelPackages.kernel;

  amdgpu_module = pkgs.stdenv.mkDerivation {
    pname = "amdgpu-kernel-module";
    inherit (kernel) src version postPatch nativeBuildInputs modDirVersion;

    modulePath = "drivers/gpu/drm/amd/amdgpu";

    buildPhase = ''
      BUILT_KERNEL=${kernel.dev}/lib/modules/$modDirVersion/build

      cp $BUILT_KERNEL/Module.symvers ./
      cp $BUILT_KERNEL/.config        ./
      cp ${kernel.dev}/vmlinux        ./

      make "-j$NIX_BUILD_CORES" modules_prepare
      make "-j$NIX_BUILD_CORES" M=$modulePath modules
    '';

    installPhase = ''
      make \
        INSTALL_MOD_PATH="$out" \
        XZ="xz -T$NIX_BUILD_CORES" \
        M="$modulePath" \
        INSTALL_MOD_STRIP=1 \
        modules_install
    '';

    NIX_CFLAGS_COMPILE = [ "-O3" "-march=native" "-mtune=native" ];

    patches = kernel.patches ++
      (if config.nix4games.amdgpu.fullrgb then [
        # https://gitlab.freedesktop.org/drm/amd/-/issues/476
        # https://github.com/swaywm/sway/issues/3173
        # https://web.archive.org/web/20210525124315/https://www.brad-x.com/2017/08/07/quick-tip-setting-the-color-space-value-in-wayland/
        # TEST on tty with:
        # proptest -M amdgpu -D /dev/dri/card1 94 connector 40 0
        # proptest -M amdgpu -D /dev/dri/card1 94 connector 40 1
        # proptest -M amdgpu -D /dev/dri/card1 94 connector 40 2
        ../patches/amdgpu_full_rgb.patch
      ] else [ ]) ++
      (if config.nix4games.amdgpu.no_cap_sys_nice then [
        # https://wiki.nixos.org/wiki/VR#Patching_AMDGPU_to_allow_high_priority_queues
        # PATCH FROM:
        # https://github.com/Frogging-Family/community-patches/blob/a6a468420c0df18d51342ac6864ecd3f99f7011e/linux61-tkg/cap_sys_nice_begone.mypatch
        ../patches/amdgpu_cap_sys_nice_begone.patch
      ] else [ ]);

    meta = {
      description = "AMD GPU kernel module";
      license = lib.licenses.gpl3;
    };
  };
in
lib.mkIf config.nix4games.amdgpu.enable {
  boot.kernelParams = lib.mkIf config.nix4games.amdgpu.fullrgb [
    # enables full rgb from patch
    "amdgpu.pixel_encoding=rgb"
  ];

  boot.extraModulePackages = [ amdgpu_module ];
}
