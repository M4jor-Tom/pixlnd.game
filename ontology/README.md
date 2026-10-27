# ontology/ — Cube World rebuild

Source of truth for the game. Read `domain/index.md` first.

```
ontology/
├── domain/index.md        canonical semantic layer: scope, competency questions, classes, relations,
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
[§7](domain/7_Open_points_for_validation.md#7-open-points-for-validation) links their current rules
and separates research uncertainties from hybrid behavior. No unresolved entry remains in the
game-choice backlog. Resistance's meaning and all five approved combat selections are
[defined with their dependencies](domain/3_Classes.md#stat) and constrained by the
[mitigation rules](domain/5_Constraints.md#constraint-catalog).
Combat hit-derived burning and poison use [independent applications](domain/3_Classes.md#status-effect).
Implementation deferrals live in `docs/ROADMAP/todo_implement.md`; documentation approval grants
no runtime permission. Validation-contract enforcement remains partial: required identity catalogs/raw
shapes, bidirectional class/spec ownership and ordered indices, shared skill roots/links and Assassin's
single rank-3 Camouflage exception (`test_identity_skills.gd`); required race/catalog rows,
whole movesets and their selected shapes/references, district building/class references and landscape
dungeon/POI references have bounded checks (`test_required_catalogs.gd`, `test_world_references.gd`).
Landscape qualifiers remain raw notes; desert-ruins identity is unresolved, not a resolved alias.
Mapped heterogeneous catalogs/configuration, raw typed-conversion shapes, climate expressions,
family membership and building role/station/style closure have required-input checks
(`test_required_inputs.gd`). Historical landscape style descriptions stay verbatim; bounded
reference resolution is distinct from the runtime `design.settlement.style-by-landscape` map.
Qualified annotations remain exact `source_tags`, separate from confirmed `versions`. Finite
`source_at` resolution retains explicit/envelope origin; `test_provenance.gd` checks the §5 mappings
and malformed selected-content tags. Untagged foods no longer receive fabricated A+S history.
Unmapped food/trait/affix/mixed-context histories remain unresolved, not complete provenance coverage.
Artifact config/descriptions now reflect the approved logarithm and separate historical S reports;
`test_artifact_corrections.gd` checks only that bounded correction. Artifact-specific production
enforcement, generation/runtime, persistence and remaining precision stay in the backlog,
alongside remaining equipment behavior.
Dated build notes include superseded placeholders, not proof of current coverage. For
"resume walking through items", follow `docs/HANDOFF.md`, `docs/lessons.md` and any retained selections,
not the gameplay slice loop. A green validator proves only its implemented checks, not full ontology consistency.

## Controls

[Canonical controls](domain/controls.md) define distinct device-independent intentions.
[Controller profiles](domain/controller-profiles.md) own all physical mappings and coupling;
gamepad remains unselected; Android's [native tool stack](decisions/android-native-touch-controls.md)
and [touch-profile policy](domain/controller-profiles.md#android) have a bounded first-slice
runtime and scoped profile validation; broader controls/reference enforcement remains deferred.
The first slice is owner hardware-tested on Android; detailed checklist coverage and render-cost
measurements are unrecorded. Desktop synthetic tests remain separate evidence. `keybinds.json#hybrid`
is the unchanged keyboard adapter, not a semantic catalog. The [controls contract](domain/controls.md#contract)
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
`?` on a source value marks uncertainty; `domain/index.md §7` separates active hybrid questions from
reference-only gaps. In type notation it means optional/nullable, not a missing design decision.

## Validate JSON

```sh
for f in ontology/instances/*.json; do jq -e 'type == "object"' "$f" >/dev/null || exit 1; done
```
