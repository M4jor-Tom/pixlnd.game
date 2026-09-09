# TODO — decisions to take BEFORE any engine work

Priority zero. Resume here with any agent. Context: `ontology/domain.md` (§1 scope, §7 open
points), `ontology/instances/*.json`, `docs/ROADMAP/README.md`. Already decided on 2026-09-07:
D1 hybrid ruleset, D2 Godot 4.7 + GDScript, D3/D4 cut + Omega content → roadmap, region lock /
`+` items / worn degradation dropped.

**Status 2026-09-07 (evening): every decision below is taken and recorded.** Designed numbers
live in `ontology/instances/generators.json#design`. Nothing remains: run the `router` skill.

## A. Design decisions (owner)

- [x] **D5 Multiplayer target** — dedicated server (alpha style, IP/DNS join, seed in server
  config). Recorded: `rulesets.json#ruleset-hybrid.flags.multiplayer`, `domain.md §3 multiplayer-mode`.
- [x] **D6 Undocumented numbers** — all designed, recorded in `generators.json#design` + the
  file each row names:
  - [x] alpha per-point skill: flat +5 % effect / −5 % cooldown per point, floor 25 %, uncapped
  - [x] crit: ×2.0, chance above 100 % adds to the multiplier → `stats.json#stats.crit`
  - [x] item stat curve: alpha curve only, no 1.0 tier curve → `stats.json`
  - [x] prices: buy = base × level × rarity mult (1/2/4/8/16), sell 25 % → `economy.json#prices`
  - [x] artifacts: +5 % first, ×0.9 each next, floor 1 %; one traversal stat **and** attack + max HP
    with the same rule → `key-items.json#artifact`
  - [x] inventory stack cap: none → `domain.md §3 inventory`
  - [x] enemy HP/damage: cuwo npc-hp formula × per-family multiplier, white lvl-1 mob = 150–250 HP
  - [x] Circle of Power: +10 % attack, +10 % max HP in the land → `status-effects.json`
  - [x] recipes: cubes = 5 × size class (1/2/4), +1 gem per rarity tier above common → `recipes.json`
- [x] **D7 Alpha player cap** — configurable, default 4. Recorded: `generators.json#network-alpha`.
- [x] **D8 Skin colour at creation** — real option, per-race palette ours. Recorded: `races.json#_creation`.
- [x] **D9 First-person zoom** — kept. Recorded: `ui.json#camera`.
- [x] **D10 Ability merge in hybrid** — 3 alpha class columns (removed skills back at rank 3) +
  1 `ultimate` column holding the steam R skill, unlocked by 5 points in the spec's rank-3 skill.
  Recorded: `abilities.json` `alpha-tree` on every R skill, `domain.md §3 skill-tree`.
- [x] **D11 Hybrid gaps (2026-09-08)** — block gives MP (the bar specials spend); Regeneration =
  stamina only; artifacts 1–3 per land, seeded; `/pvp` dropped, PvP = `server.cfg` flag default off.
  Recorded: `generators.json#design` (`block-reward`, `regeneration`, `artifacts-per-land`, `pvp`).
- [x] **D12 World numbers (2026-09-08)** — zone 64², land 256² zones, 1 block = 1 m, sea level 96, fBm
  heightfield, climate rules, land names. Recorded: `generators.json#design.terrain|climate|names`,
  `landscapes.json#*.gen`.
- [x] **D13 Player movement, camera, keys (2026-09-08)** — walk/sprint/swim/jump/gravity/step-up/hitbox/stamina,
  orbit camera zoom range, hybrid key column. Recorded: `generators.json#design.movement|camera`, `keybinds.json#hybrid`.
- [x] **D14 Open-world spawns (2026-09-08)** — groups per zone, roster, hostility roll, NPC HP multiplier,
  wander/chase numbers. Recorded: `generators.json#design.spawns|enemy-hp`; wetlands roster fixed (`slimes` → ids).
- [x] **D15 Combat multipliers (2026-09-08)** — attack-power ×10, NPC damage ×12, armor floor 10 %, combo bonus,
  swing/windup/cooldown, respawn. Recorded: `generators.json#design.combat`, `classes.json#*.hp-mult`.
- [x] **D16 Simulation radius (2026-09-08)** — creatures beyond 80 blocks are frozen (fixes the physics catch-up
  spiral, 4 FPS). Recorded: `generators.json#design.spawns.ai.sim-radius`, `c-sim-radius`.
- [x] **D17 Runtime profiling and frame budget (2026-09-08)** — Godot Debug Menu add-on on F3 for players, physics
  catch-up cap. Recorded: `keybinds.json#hybrid.debug-menu`, `ui.json#hud.debug-menu`, `generators.json#design.frame-budget`, `c-frame-budget`.
- [x] **D18 Items, loot, inventory (2026-09-09)** — drop chances, rarity weights, level spread, ground-item lifetime,
  stack rule, starting inventory. Recorded: `generators.json#design.loot|stack-cap|starting-inventory`, `c-loot-config`,
  `c-stack-rule`, `c-slot-accepts`; `domain.md §3.4 inventory` props, relations `holds` / `equips`.

## B. Conflicting facts (pick a side)

- [x] **F1 Steam ability numbers** — recorded in `abilities.json`, `?` stripped:
  - [x] Heroic Shout: taunt 5 m + 50 % HP over 10 s
  - [x] Guardian Toughness: +25 % max HP
  - [x] Battle Fury trigger: 13 % per hit
  - [x] Shadow Shooter duration: 30 s
  - [x] Bubbles count: **6** (owner pick, guide value)
  - [x] Shuriken Toss cost: 25 stamina
  - [x] R-ultimate cooldowns: per-skill (20/30/40/60 s)
- [x] **F2 Rideable flags** — per-page (no). `pet-food.json` `rideable: false` on all 13.
- [x] **F4 Land difficulty — owner override, not the default.** Enemy level = band from lowest
  party level − X to highest + Y (solo: own level), X/Y in solo settings or `server.cfg`; each land
  rolls a danger tier (safe/normal/dangerous) at generation that fixes where in the band it sits.
  Recorded: `generators.json#design.enemy-level`, `landscapes.json#_shared`, `domain.md §3 land`.
- [x] **F6 Land geometry** — one land = one region cell; our own noise/water/heightmap.
  Recorded: `domain.md §3 land`.
- [x] **F8 Spirit Bell duration** — 30 s. `key-items.json#spirit-bell`.
- [x] **F9 Life Potion station** — anywhere. `consumables.json#life-potion`.
- [x] **F10 Alpha-id creatures "not in alpha"** — tagged `S`, alpha id reserved. `creatures.json`.
- [x] **F11 Warthog food** (banana mash) — obtainable. `pet-food.json`.

## C. Process gaps (do, no decision needed)

- [x] Godot 4.7.2 via `nix develop` (flake.nix); `godot --headless -s ontology/validate.gd` passes
- [x] `git init` the repo — done, first commit b9e0bfd.
- [x] Raw research corpus (740 wiki pages, cuwo clone) — not kept; `ontology/research/*.md` is
  what remains.

## D. Not decisions (info)

- F3 (`+` items / lore) is moot: region lock dropped.
- F5 split into D7/D8/D9 above, all decided.
- F7 Omega status (Vulkan vs UE5, silence since 2024) is roadmap-only.

## After all boxes are ticked — DONE 2026-09-08 (`project.godot`, `game/`)
Run the `router` skill: scaffold the Godot project, derive architecture from `domain.md §3`
classes, load `instances/` through `ontology/model.gd`.
