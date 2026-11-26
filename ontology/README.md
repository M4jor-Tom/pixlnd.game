# ontology/ — Cube World rebuild

Read the [domain index](domain/index.md) for rules, `schema/` for structural declarations
and `instances/` for qualified sources and selected configuration.

## Current scope and decisions (2026-10-17)

Hybrid v1 is alpha progression + approved Steam content; A/S source descriptions are historical
reference, and X/cut or Omega-only content is roadmap coverage, not launch availability (item 8).
Regional gear power loss is **permanently excluded**: never propose or implement it, even for
Cube World cloning fidelity. It is not deferred or an alternative mode.
D1–D26 and subsequent approvals stand. The four selected gameplay choices are resolved;
[§7](domain/7_Open_points_for_validation.md#7-open-points-for-validation) links their current rules
and separates research uncertainties from hybrid behavior. Resistance's meaning and all five approved combat selections are
[defined with their dependencies](domain/3_Classes.md#stat) and constrained by the
[mitigation rules](domain/5_Constraints.md#constraint-catalog).
Combat hit-derived burning and poison use [independent applications](domain/3_Classes.md#status-effect).
Landscape qualifiers remain raw notes; desert-ruins identity is unresolved. Historical style
descriptions differ from `design.settlement.style-by-landscape`. Qualified `source_tags`
are distinct from confirmed `versions`; untagged foods do not acquire an A+S default.
Unmapped food, trait, affix and mixed-context histories remain unresolved.

## Controls

[Canonical controls](domain/controls.md) define distinct device-independent intentions.
[Controller profiles](domain/controller-profiles.md) own all physical mappings and coupling;
gamepad remains unselected. [Android](domain/controller-profiles.md#android) has its own touch
policy. `keybinds.json#hybrid` records keyboard defaults, not a semantic action catalog.

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
`?` on a source value marks uncertainty; [§7](domain/7_Open_points_for_validation.md#7-open-points-for-validation) separates active hybrid questions from
reference-only gaps. In type notation it means optional/nullable, not a missing design decision.

## Regenerate Godot domain classes

From the repo root, run `nix develop -c regenerate-domain` (or `regenerate-domain` inside the dev shell).
This renders `schema/pixlnd.yaml` into `game/generated/domain/` in place. Review `git diff -- game/generated/domain/`
before committing: the checked-in scripts have known differences from a fresh render.

## Validate JSON

```sh
for f in ontology/instances/*.json; do jq -e 'type == "object"' "$f" >/dev/null || exit 1; done
```
