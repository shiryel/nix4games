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
    audio.enable = mkEnableOption "enable audio module";
    cpu.enable = mkEnableOption "enable cpu module";
    graphics.enable = mkEnableOption "enable graphics module";
    kernel.enable = mkEnableOption "enable kernel module";
    network.enable = mkEnableOption "enable network module";
    nix.enable = mkEnableOption "enable nix module";
    services.enable = mkEnableOption "enable services module";
    theme.enable = mkEnableOption "enable theme module";
    xdg_mimes.enable = mkEnableOption "enable xdg mimes module";
    xdg_portals.enable = mkEnableOption "enable xdg portals module";
  };
}
