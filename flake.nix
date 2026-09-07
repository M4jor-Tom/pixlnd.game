{
  description = "pixlnd — Cube World rebuild toolchain";

  # unstable: 4.7.2 (D2 verified 2026-08-18); the stable channel still ships 4.7.1
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAll = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
        (system: f nixpkgs.legacyPackages.${system});
    in {
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            godot_4   # engine + headless validator: godot --headless -s ontology/validate.gd
            nodejs    # ontology edit/cross-ref scripts
            jq        # JSON sanity checks on ontology/instances
          ];
          # ponytail: no export templates yet, add godot_4-export-templates-bin when godot-export runs
        };
      });
    };
}
