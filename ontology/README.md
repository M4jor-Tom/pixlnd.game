# ontology/ — Cube World rebuild

Source of truth for the game. Read `domain/index.dsl` first.

```
ontology/
├── domain/index.dsl        canonical semantic layer: scope, competency questions, classes, relations,
│                    constraints, generators, open validation points (§7)
├── instances/       enumerable content, one JSON per family, entries keyed by stable ID
├── model.gd         typed GDScript model (Godot 4.7): enums, Resource classes, loader + validator
└── validate.gd      headless check: `nix develop -c godot --headless -s ontology/validate.gd`
```

## Current scope and decisions (2026-10-17)

Hybrid v1 is alpha progression + approved Steam content; A/S source descriptions are historical
reference, and X/cut or Omega-only content is roadmap coverage, not launch availability (item 8).
Regional gear power loss is **permanently excluded**: never propose or implement it, even for
Cube World cloning fidelity. It is not deferred or an alternative mode.
D1–D26 and subsequent approvals stand. The four selected gameplay choices are resolved;
[§7 (locator=7-open-points-for-validation)](domain/7_Open_points_for_validation.dsl) links their current rules
and separates research uncertainties from hybrid behavior. No unresolved entry remains in the
game-choice backlog. Resistance's meaning and all five approved combat selections are
[defined with their dependencies (locator=stat)](domain/3_Classes.dsl) and constrained by the
[mitigation rules (locator=constraint-catalog)](domain/5_Constraints.dsl).
Combat hit-derived burning and poison use [independent applications (locator=status-effect)](domain/3_Classes.dsl).
Implementation deferrals live in `docs/ROADMAP/todo_implement.md`; documentation approval grants
no runtime permission. Equipment-model and validation-contract implementation is also deferred.
Dated build notes include superseded placeholders, not proof of current coverage. For
"resume walking through items", follow `docs/HANDOFF.md`, `docs/lessons.md` and any retained selections,
not the gameplay slice loop. A green validator proves only its implemented checks, not full ontology consistency.

## Controls

[Canonical controls](domain/controls.dsl) define distinct device-independent intentions.
[Controller profiles](domain/controller-profiles.dsl) own all physical mappings and coupling;
gamepad remains unselected; Android's [native tool stack](decisions/android-native-touch-controls.md)
and [touch-profile policy (locator=android)](domain/controller-profiles.dsl) have a bounded first-slice
runtime and scoped profile validation; broader controls/reference enforcement remains deferred.
The first slice is owner hardware-tested on Android; detailed checklist coverage and render-cost
measurements are unrecorded. Desktop synthetic tests remain separate evidence. `keybinds.json#hybrid`
is the unchanged keyboard adapter, not a semantic catalog. The [controls contract (locator=contract)](domain/controls.dsl)
is documentation, not gameplay implementation authority.

## Instance files

| file | contents |
|---|---|
| rulesets.json | chosen hybrid flags; alpha / Steam historical reference; Omega announced roadmap |
| races.json, classes.json, specializations.json | player identity |
| abilities.json | ~65 skills, passives, movement abilities, alpha tree positions, inert canonical control references |
| weapon-types.json, equipment-slots.json, materials.json, rarities.json, affixes.json, item-types.json | item model |
| stats.json | resources, stats, alpha formulas (items + character) |
| status-effects.json | debuffs, buffs, hazards |
| consumables.json, ingredients.json, recipes.json, crafting-stations.json | crafting |
| key-items.json, pet-food.json | specials, artifacts, taming |
| creatures.json, creature-families.json, factions.json, npc-roles.json | living things |
| landscapes.json, terrain-features.json, flora.json, deposits.json, block-types.json | world |
| dungeon-types.json, poi-types.json, static-entities.json, buildings.json | structures |
| economy.json, mission-types.json | loops |
| controller-profiles.json | selected Android first-slice response/target constants and canonical action references |
| keybinds.json, ui.json, slash-commands.json, audio.json | keyboard adapter / canonical control references and presentation |
| versions.json | timeline, alpha→steam delta, reception, fan fix-list |
| generators.json | numeric configs + invariants for every procedural system |

## Conventions

Version tags `A` (alpha 0.1.x), `S` (Steam 1.0), `Ω` (Omega, announced), `X` (cut / data-only).
`?` on a source value marks uncertainty; `domain/7_Open_points_for_validation.dsl §7` separates active hybrid questions from
reference-only gaps. In type notation it means optional/nullable, not a missing design decision.

## Validate JSON

```sh
for f in ontology/instances/*.json; do jq -e 'type == "object"' "$f" >/dev/null || exit 1; done
```

## Structurizr domain tools

[workspace.dsl](workspace.dsl) is the actual parser entry; [domain/index.dsl](domain/index.dsl)
includes all eleven authoritative chapters. [Representation decision](decisions/structurizr-domain-representation.md).
This is representation only, not an ontology reasoner or new gameplay authorization.

Use Node (stdlib only), **Java 21**, curl and SHA-256 tools, with the consolidated
**Structurizr 2026.09.19** WAR from the [official binaries page](https://docs.structurizr.com/binaries).
Lite/old CLI are EOL. To launch the live entities graph from the repository root with flakes enabled:

```sh
nix run .#ontology-view
```

The flake app supplies the runtime, caches the pinned WAR outside the repository, and verifies its
SHA-256 before use. Open <http://localhost:8080>, choose **Entities definitions**, and press Ctrl-C
to stop the viewer. For direct export, locate, or test commands below, Nix users can enter a shell
providing the prerequisites (or install them normally):

```sh
nix shell nixpkgs#jdk21 nixpkgs#nodejs nixpkgs#curl nixpkgs#coreutils -c bash
```

Inside that shell, download the version-pinned official artifact into a user cache **outside the
repository**, and verify its checksum before every use, including reuse of a cached download:

```sh
export STRUCTURIZR_WAR="${XDG_CACHE_HOME:-$HOME/.cache}/pixlnd/structurizr/structurizr-2026.09.19.war"
mkdir -p "$(dirname "$STRUCTURIZR_WAR")"
[ -f "$STRUCTURIZR_WAR" ] || curl --fail --location \
  https://download.structurizr.com/structurizr-2026.09.19.war --output "$STRUCTURIZR_WAR"
printf '%s  %s\n' ac1a2806e246364b88261a542a36ca7f3006ef48e5de68830afa8672f58690f1 "$STRUCTURIZR_WAR" \
  | sha256sum --check - || exit 1
node tools/ontology.mjs export --out /tmp/ontology-export
node tools/ontology.mjs locate skill-tree
node tools/ontology.mjs locate '3_Classes.md#skill-tree-a'
node tools/test_ontology.mjs --workspace-json /tmp/ontology-export/workspace.json --viewer-check
node tools/ontology.mjs view --out .structurizr
# Browse http://localhost:8080 ; Ctrl-C stops only this viewer.
```

The pinned SHA-256 was checked against a separate download from that official versioned HTTPS
URL on 2026-10-17. It is a reproducibility/integrity pin, **not an upstream signed checksum**;
the official `.war.sha256` URL returned 404. No task-specific snapshot or temporary WAR is needed.

The viewer stages validated DSL and eleven generated native-documentation chapters under ignored
`/.structurizr/`, watches canonical DSL, and retains the last valid stage on a parse failure.
Local auto-refresh is 2000 ms; editing/layout autosave is disabled. Generated documentation is
read-only/non-authoritative, never synchronized back. Binaries, exports, logs and browser evidence
belong outside tracked source. `--source-root /tmp/disposable-ontology` supports isolated watch tests.
Staging accepts a new/empty directory or its own unchanged generated output (ownership marker
plus exact file inventory/hashes). It rejects source/repository ancestors, source descendants,
symlinked output paths, foreign files and edited generated files before writing anything.
Native local's regular `workspace.json` and regular-file `.structurizr/` runtime tree (logs,
search index, thumbnails) are retained, never overwritten by staging. For an old
unmarked stage or a refused destination, choose a fresh output directory; nothing is auto-adopted.

Source records use exact canonical IDs (DSL aliases use underscores). `source.*` properties are
**historical baseline file/line coordinates**, not current Markdown links. `locate` reports current
DSL file:line, accepting IDs or historical chapter/heading locators, including versioned headings.
Incoming file links use an explicit `locator=...` caption; URL fragments on DSL links are not supported.
Native docs display source locators as text where the server cannot serve repository files.

`Class`, `RelationDefinition`, `Constraint`, `Generator`, `Question` and `SectionNote` are flat custom
elements. Relations retain cardinality on the definition, with ordered/qualified incidence edges.
`EndpointTerm` means a source endpoint without a class definition (six terms, including magic-crystal),
not an invented class. Questions retain literal references, declared-record edges and unresolved terms.
Tables have named columns/ordered rows and cells; prose/code use individual readable note lines.
Cell states distinguish `text`, `empty-cell`, `missing-cell` and `absent-column`; only text has a value.
Optional types (`int?`) and uncertain source annotations (`S?`) remain literal and distinct.
Rule/formula strings are descriptions, not new executable validation.
Native docs mark omitted cells in short original rows as *missing source cell*, rather than
silently displaying them as explicit blank cells; undeclared columns remain absent.

Explicit HTML anchors in source notes/tables also have structured `anchor.NNN` metadata.
Use chapter-qualified locators such as `controls.md#block` or
`controller-profiles.md#android-response`; action IDs do not replace class IDs.
Two stale Android status sentences are reconciled to the later upstream hardware-tested profile;
source coordinates still name the original master text, not invented corrected-source lines.
