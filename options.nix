{ lib, ... }:

with lib;

{
  options.nix4games = {
    mainUser = mkOption {
      type = types.str;
      example = "shiryel";
      description = "Main user of the system";
    };

    amdgpu.enable = mkEnableOption "enable amdgpu module";
    amdgpu.fullrgb = mkEnableOption "patch amdgpu with full_rgb.patch";
    amdgpu.no_cap_sys_nice = mkEnableOption "patch amdgpu with cap_sys_nice_begone.patch";

    audio.enable = mkEnableOption "enable audio module";
    cpu.enable = mkEnableOption "enable cpu module";
    graphics.enable = mkEnableOption "enable graphics module";
    kernel.enable = mkEnableOption "enable kernel module";
    kernel.enableZram = mkEnableOption "enable kernel zram config";
    network.enable = mkEnableOption "enable network module";
    nix.enable = mkEnableOption "enable nix module";
    services.enable = mkEnableOption "enable services module";
    polkit.enable = mkEnableOption "enable polkit module";
    oom.enable = mkEnableOption "enable out-of-memory module";
    dark-theme.enable = mkEnableOption "enable dark theme module";
    xdg-mimes.enable = mkEnableOption "enable xdg mimes module";
    xdg-portals.enable = mkEnableOption "enable xdg portals module";
    keepassxc-keyring.enable = mkEnableOption "enable KeePassXC Keyring module";
  };
}
