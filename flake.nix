{
  description = "pixlnd — Cube World rebuild toolchain";

  # unstable: 4.7.2 (D2 verified 2026-08-18); the stable channel still ships 4.7.1
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixgl = {
    # nix-community/nixGL#221: current nixpkgs, open-module detection and Vulkan ICD names.
    url = "github:KeeTraxx/nixGL/51471fb4760efda2defba73bc1c264b7ba5364c2";
    flake = false; # Imported with our nixpkgs below, without nixGL's separate toolchain.
  };

  outputs = { self, nixpkgs, nixgl }:
    let
      forAll = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
        (system: f system nixpkgs.legacyPackages.${system});
    in {
      apps = forAll (system: pkgs:
        let
          launcher = pkgs.writeShellScript "pixlnd" ''
            exec ${pkgs.godot_4}/bin/godot --path "${self}" "$@"
          '';
        in {
          default = {
            type = "app";
            program = toString launcher;
          };
        } // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          # --impure lets nixGL match userspace libraries to the host's NVIDIA kernel driver.
          nvidia = let
            drivers = (import nixgl {
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
              enable32bits = false;
            }).auto.nixVulkanNvidia;
          in {
            type = "app";
            program = toString (pkgs.writeShellScript "pixlnd-nvidia" ''
              exec ${drivers}/bin/${drivers.name} ${launcher} "$@"
            '');
          };
        });
      devShells = forAll (_system: pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            godot_4   # engine + headless validator: godot --headless -s ontology/validate.gd
            nodejs    # ontology edit/cross-ref scripts
            gdb       # native debugger (development tool only)
            jq        # JSON sanity checks on ontology/instances
            bash      # test loops: `nix develop -c bash -c ...` (zsh does not word-split $var, see HANDOFF gotchas)
          ];
          # ponytail: no export templates here; CI downloads its own (.github/workflows/release.yml).
          # Add godot_4-export-templates-bin only if a local --export-release is ever wanted.
        };
      });
    };
}
