{
  description = "pixlnd — Cube World rebuild toolchain";

  # unstable: 4.7.2 (D2 verified 2026-08-18); the stable channel still ships 4.7.1
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAll = f: nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ]
        (system: f nixpkgs.legacyPackages.${system});
    in {
      apps = forAll (pkgs:
        let
          ontologyView = pkgs.writeShellApplication {
            name = "ontology-view";
            runtimeInputs = with pkgs; [ coreutils curl temurin-jre-bin-21 nodejs ];
            text = ''
              if [ ! -f "$PWD/ontology/workspace.dsl" ]; then
                echo "Run nix run .#ontology-view from the repository root." >&2
                exit 1
              fi

              war="''${XDG_CACHE_HOME:-$HOME/.cache}/pixlnd/structurizr/structurizr-2026.09.19.war"
              mkdir -p "$(dirname "$war")"
              part="$war.part"
              if [ ! -f "$war" ]; then
                curl --fail --location --silent --show-error --retry 3 --retry-all-errors --continue-at - --output "$part" https://download.structurizr.com/structurizr-2026.09.19.war
                printf '%s  %s\n' ac1a2806e246364b88261a542a36ca7f3006ef48e5de68830afa8672f58690f1 "$part" | sha256sum --check - || { rm -f "$part"; exit 1; }
                mv "$part" "$war"
              fi
              printf '%s  %s\n' ac1a2806e246364b88261a542a36ca7f3006ef48e5de68830afa8672f58690f1 "$war" | sha256sum --check -
              export STRUCTURIZR_WAR="$war"
              exec node "${self}/tools/ontology.mjs" view --source-root "$PWD/ontology" --out "$PWD/.structurizr"
            '';
          };
        in {
          default = { type = "app"; program = "${pkgs.godot_4}/bin/godot"; };
          ontology-view = { type = "app"; program = "${ontologyView}/bin/ontology-view"; };
        });
      devShells = forAll (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            godot_4   # engine + headless validator: godot --headless -s ontology/validate.gd
            nodejs    # ontology edit/cross-ref scripts
            jq        # JSON sanity checks on ontology/instances
            bash      # test loops: `nix develop -c bash -c ...` (zsh does not word-split $var, see HANDOFF gotchas)
          ];
          # ponytail: no export templates here; CI downloads its own (.github/workflows/release.yml).
          # Add godot_4-export-templates-bin only if a local --export-release is ever wanted.
        };
      });
    };
}
