# ontology/ — Cube World rebuild

Source of truth for the game. Read `domain.md` first.

```
ontology/
├── domain.md        canonical semantic layer: scope, competency questions, classes, relations,
│                    constraints, generators, open validation points (§7)
├── instances/       enumerable content, one JSON per family, entries keyed by stable ID
├── research/        the five sourced research dumps the ontology was built from (read-only)
├── model.gd         typed GDScript model (Godot 4.7): enums, Resource classes, loader + validator
└── validate.gd      headless check: `nix develop -c godot --headless -s ontology/validate.gd`
```

## Status (2026-09-07)

- Research complete; `domain.md` + 40 instance files + `model.gd` written.
- Owner decisions applied: **hybrid ruleset** (alpha progression + steam content), **Godot 4 +
  GDScript** (engine maintenance verified: 4.7.2 stable 2026-08-18), **region lock dropped**,
  all cut/Omega content deferred to `docs/ROADMAP/`.
- 2026-09-07 (later): every §7 open point settled (`docs/ROADMAP/todo_decide.md`); designed
  tunables live in `instances/generators.json#design`. Toolchain pinned in `flake.nix` (Godot 4.7.2,
  node, jq); `validate.gd` parsed and passed for the first time: 0 errors.
- Still open: only the single-source `?` facts in `domain.md` (rare zones, swamp-lands, mana-cubes,
  race hitboxes, chase drop, armor formula); none blocks engine work.
- 2026-09-08: stale `?` (water level, artifact traversal bonus) cleared; D11 settles the four hybrid
  gaps (block reward, regeneration, artifacts per land, `/pvp`) in `generators.json#design`.
- 2026-09-09: `stats.json` xp-to-next table corrected to what its own formula gives (L20 537, L50 760, L100 881).
- 2026-09-09: D19 XP per kill + level-up rules (`design.progression`, `c-xp-config`, `c-level-up`) for `game/progression/`;
  three table rows that a D16/D17 edit had prepended above the `domain.md` title moved back into §3.2 ai-behavior and §5.
- 2026-09-09: D20 skill tree spend rules (`design.abilities`, `keybinds.json#hybrid.skills-window` = X, hybrid `screens.skills`,
  `c-tree-shape`, `c-skill-spend`); the five rank-1 class nodes had `needs` 1, now 0 like every other tree root.
- 2026-09-10: D21 class ability runtimes (`design.abilities` per node, `design.resources.mp`, `design.special-attack`,
  `design.status-effects`, `c-ability-runtime`) for `game/combat/abilities.gd`; the D20 placeholder strike is retired.
- 2026-09-10: D22 settlements + spawn rule (`design.settlement`, `ui.json#screens.npc-service`, `c-settlement-config`) for `game/world/settlement.gd`,
  `game/items/shop.gd`; `world.spawn-rule` hybrid = the (0,0) village square.
- 2026-09-11: D23 defence (`design.defence`, sneak / aim / camouflage `stealth-per-s|stealth-full`, `c-defence-config`) for dodge / block /
  stealth in `game/entities/player.gd`; §5 `c-stat-roll` and `c-name-length` relabelled (nothing loadable carries them).
- 2026-09-11: D24 weapon movesets + projectiles (`design.movesets`, `design.abilities` runtime `projectile` / dash `throw`, `design.status-effects.poison`,
  `c-moveset-config`) for `game/combat/projectile.gd` and the M1 / M2 paths in `game/entities/player.gd`.
- 2026-09-11: D25 game feel (`design.feel` event bundles: hit-stop / camera trauma / synthesised sfx keyed by `audio.json#sfx-alpha-ids` /
  damage numbers / impact + trail / stun stars / buff icons / level-up pop, `c-feel-config`) for `game/combat/feel.gd`.
- 2026-09-09: D18 items, loot, inventory numbers + `c-loot-config` / `c-stack-rule` / `c-slot-accepts` for `game/items/`.
- 2026-09-08: D17 runtime profiling overlay (Godot Debug Menu, F3) + `design.frame-budget` / `c-frame-budget`.
- 2026-09-08: D16 simulation radius + `c-sim-radius` (creatures frozen beyond 80 blocks; the 4 FPS fix).
- 2026-09-08: D15 combat multipliers + class `hp-mult` for `game/combat/`.
- 2026-09-08: D14 spawn numbers + `c-roster-ids` (wetlands roster fixed) for creatures in `game/entities/`.
- 2026-09-08: D13 player numbers (movement, camera, hybrid keys) for `game/entities/` + `game/meta/`.
- 2026-09-08: D12 world numbers (zone/land size, heightfield, climate rules, palettes, land names)
  landed for the first gameplay slice, `game/world/`.
- 2026-09-08: router step done — `project.godot` + `game/` scaffold; `OntologyDB` autoload loads
  `instances/` through `model.gd` and aborts on any §5 violation. Layout: `game/README.md`.

## Instance files

| file | contents |
|---|---|
| rulesets.json | alpha / steam / omega feature flags |
| races.json, classes.json, specializations.json | player identity |
| abilities.json | ~65 skills, passives, movement abilities, alpha tree positions, steam inputs |
| weapon-types.json, equipment-slots.json, materials.json, rarities.json, affixes.json, item-types.json | item model |
| stats.json | resources, stats, alpha formulas (items + character) |
| status-effects.json | debuffs, buffs, hazards |
| consumables.json, ingredients.json, recipes.json, crafting-stations.json | crafting |
| key-items.json, pet-food.json | specials, artifacts, taming |
| creatures.json, creature-families.json, factions.json, npc-roles.json | living things |
| landscapes.json, terrain-features.json, flora.json, deposits.json, block-types.json | world |
| dungeon-types.json, poi-types.json, static-entities.json, buildings.json | structures |
| economy.json, mission-types.json | loops |
| keybinds.json, ui.json, slash-commands.json, audio.json | presentation |
| versions.json | timeline, alpha→steam delta, reception, fan fix-list |
| generators.json | numeric configs + invariants for every procedural system |

## Conventions

Version tags `A` (alpha 0.1.x), `S` (Steam 1.0), `Ω` (Omega, announced), `X` (cut / data-only).
`?` marks unverified or conflicting facts; each is listed in `domain.md §7`.

## Validate JSON

```sh
for f in ontology/instances/*.json; do node -e "JSON.parse(require('fs').readFileSync('$f'))" || echo "BAD $f"; done
```
