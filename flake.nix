{
  description = "NixOS modules for a gamming desktop";

  outputs = { nixpkgs, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      nixosModules.nix4games.imports = [
        ./options.nix
        ./modules/amdgpu.nix
        ./modules/audio.nix
        ./modules/cpu.nix
        ./modules/graphics.nix
        ./modules/kernel.nix
        ./modules/network.nix
        ./modules/nix.nix
        ./modules/services.nix
        ./modules/theme.nix
        ./modules/xdg_mimes.nix
        ./modules/xdg_portals.nix
      ];

      # when using "packages" `nix flake show` gives "error: expected a derivation"
      # to build docs use: nix build .\#legacyPackages.x86_64-linux.docs.optionsJSON
      #legacyPackages = forAllSystems (system:
      #  let
      #    pkgs = nixpkgs.legacyPackages.${system};
      #    lib = pkgs.lib;
      #    eval = lib.evalModules {
      #      modules = [
      #        { _module.check = false; }
      #        ./modules
      #      ];
      #    };
      #  in
      #  with builtins;
      #  with lib;
      #  {
      #    docs = pkgs.buildPackages.nixosOptionsDoc {
      #      options = eval.options;

      #      transformOptions =
      #        let
      #          prefix_to_strip = (map (p: "${toString p}/") ([ ./. ]));
      #          strip_prefixes = flip (foldr removePrefix) prefix_to_strip;
      #          fix_urls = (x: { url = "https://github.com/shiryel/nix4games/blob/master/${x}"; name = "<shiryel/nix4games>"; });
      #        in
      #        opt: opt // {
      #          declarations = map
      #            (d: pipe d [
      #              strip_prefixes
      #              fix_urls
      #            ])
      #            opt.declarations;
      #        };
      #    };
      #  }
      #);
    };
}
