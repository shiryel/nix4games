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

    NIX_CFLAGS_COMPILE = [ "-O2" "-march=native" "-mtune=native" ];

    patches = kernel.patches ++ [
      # https://wiki.nixos.org/wiki/VR#Patching_AMDGPU_to_allow_high_priority_queues
      # PATCH FROM: 
      # https://github.com/Frogging-Family/community-patches/blob/a6a468420c0df18d51342ac6864ecd3f99f7011e/linux61-tkg/cap_sys_nice_begone.mypatch
      (pkgs.writeText "cap_sys_nice_begone.patch" ''
        From fe059b4c373639fc5d69067e62de3f2a0e44a037 Mon Sep 17 00:00:00 2001
        From: Sefa Eyeoglu <contact@scrumplex.net>
        Date: Fri, 17 Mar 2023 16:50:57 +0100
        Subject: [PATCH] amdgpu: allow any ctx priority

        Signed-off-by: Sefa Eyeoglu <contact@scrumplex.net>
        ---
         drivers/gpu/drm/amd/amdgpu/amdgpu_ctx.c | 2 +-
         1 file changed, 1 insertion(+), 1 deletion(-)

        diff --git a/drivers/gpu/drm/amd/amdgpu/amdgpu_ctx.c b/drivers/gpu/drm/amd/amdgpu/amdgpu_ctx.c
        index d2139ac12159..c7f1d36329c8 100644
        --- a/drivers/gpu/drm/amd/amdgpu/amdgpu_ctx.c
        +++ b/drivers/gpu/drm/amd/amdgpu/amdgpu_ctx.c
        @@ -107,7 +107,7 @@ static int amdgpu_ctx_priority_permit(struct drm_file *filp,
         	if (drm_is_current_master(filp))
         		return 0;
 
        -	return -EACCES;
        +	return 0;
         }
 
         static enum amdgpu_gfx_pipe_priority amdgpu_ctx_prio_to_gfx_pipe_prio(int32_t prio)
        -- 
        2.39.2
      '')
    ];

    meta = {
      description = "AMD GPU kernel module";
      license = lib.licenses.gpl3;
    };
  };
in
lib.mkIf config.nix4games.amdgpu.enable {
  boot.extraModulePackages = [ amdgpu_module ];
}
