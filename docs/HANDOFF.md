# Handoff — resume here (written 2026-09-11, after the D23 defence slice)

Read this, then `git log --oneline -8`, then `docs/ROADMAP/todo_implement.md`. Nothing else is
needed to continue; the repo is self-describing from these three.

## What this project is
Cube World rebuild in Godot 4.7.2 + GDScript, **ontology-first**: `ontology/` is the source of
truth (`domain.md` classes/relations/constraints/generators, `instances/*.json` content,
`model.gd` typed loader + validator). Engine code in `game/` only *consumes* it. Every decision
the sources never settled is a numbered **D** entry: `domain.md §7` + `docs/ROADMAP/todo_decide.md`
(D1–D23 all taken). Designed numbers live in `ontology/instances/generators.json#design.<topic>`.

## State of the build (all committed and pushed to origin/master)
| commit | slice | what runs |
|---|---|---|
| c9107df | ontology closed | 40 instance files, validator 0 errors |
| 4430b5b | scaffold | `project.godot`, `OntologyDB` autoload loads + validates the ontology |
| 475e72b | world (§3.1, D12) | seeded heightfield lands, climate → landscape, names, zone streaming + trimesh collision |
| e33c991 | player (§3.2, D13) | CharacterBody3D walk/sprint/jump/swim/step-up/stamina, orbit camera, InputMap from `keybinds.json#hybrid` |
| 250c121 | creatures (§3.2, D14) | per-zone spawns from landscape rosters, idle/wander/chase/return FSM, `entity.gd` base |
| 457c947 | combat (§3.3, D15) | basic attack, combo, crit, armor floor, creature attacks + retaliation, death/respawn, fall damage, HUD |
| 69b5702 | perf (D16) | creatures frozen beyond `design.spawns.ai.sim-radius` (80 blocks): 4 → 60 FPS; `monitors/godot_threads.sh` red/green verdict |
| 602ee50 | docs (D17) | runtime profiling overlay + `design.frame-budget` decided in the ontology; **not consumed by code yet** (`todo_implement.md`) |
| aa45d0a, abaded3 | items (§3.4, D18) | gen-item / gen-item-stats (damage, armor) / names, inventory with stack + slot rules, loot on creature death as ground items, E pick-up, Q potion, B inventory panel, coin HUD |
| 141b4d7, ad7b0dd | progression (§3.5, D19) | XP per kill (`model.gd#xp_for_kill`, last attacker), level-up with overflow carry, max HP recompute + heal, 2 skill points/level banked, HUD level/xp line; `domain.md` stray head rows fixed, `stats.json` xp table corrected |
| 0aa89dc, 276e148 | skill tree (§3.5, D20) | `model.gd#skill_tree` + `c-tree-shape`, `skill_tree.gd` spend/unlock + per-point multipliers, X panel, keys 1–4 placeholder class strike with cooldown, swimming points → swim speed, test_skill_tree |
| eae931c, c3125cf | class abilities (§3.3, D21) | `combat/abilities.gd` dash / channel / burst / buff / heal runtimes from `design.abilities` (23 nodes), MP per hit / mage regen, M2 charged / instant special, stun / knockdown / knockback / burning / slow on creatures (`entity.gd`), HUD MP bar + hotbar cooldown line, `c-ability-runtime`, test_abilities |
| 529adac, 0d7bcdd | settlements (§3.1, D22) | `world_gen.gd#village_at` one village per land from the land seed, plateau in `height_at`, `settlement.gd` ring of box buildings + `npc.gd` service NPCs streamed by `world.gd`, spawner keeps wild groups 40 blocks off the square, `items/shop.gd` stock + `design.prices` buy / sell with `shop_panel.gd` (E at a vendor), trainer respec + inn rest as HUD toasts, `world.spawn-rule` = the (0,0) village square, `c-settlement-config`, test_settlement |
| 4478016, cfacf61 | defence (§3.3, D23) | `player.gd` M3 dodge roll (i-frames, 25 stamina, ninja MP / assassin stealth), M2-held block with a shield / as guardian / during cyclone (front cone × 0.2, block-power, MP per block), stealth bar (sneak / aim fill, camouflage pins, empties on a hit; attack / crit / MP bonus), `creature.gd` aggro range × stealth cut + hit rolls stun / knockback on the player (blocked / dodged hits carry nothing), HUD block-power + stealth bars, `c-defence-config`, test_defence |

Binaries: every push to `master` runs `.github/workflows/release.yml` (`firebelley/godot-export`
reads `export_presets.cfg`), which refreshes the rolling **`latest`** prerelease with
`pixlnd_*_amd64.deb` and `pixlnd.exe`. Both presets embed the `.pck`, so each is one file.

Playable now: `nix develop -c godot` — WASD/Shift/Space, mouse look, wheel zoom (0 = first
person), M1 attack, M2 hold-to-charge special (spends MP; with a shield equipped, or as guardian, holding it also blocks front hits), M3 while moving = dodge roll, E talk / pick up, Q life potion, B inventory, X skill tree, 1–4 class skills (once a point is in them), Esc frees the mouse. You spawn on the
village square of land (0,0), seed 26879, a deadlands land (grey undead-style boxes on a ring: blue capsules at their doors are the
weapon / armor / item vendors, class trainer and innkeeper; E opens the shop, respecs for 5 × level copper, or rests); red capsules are hostiles, small spinning
cubes are loot (colour = rarity, gold = coins). Kills give XP; the HUD line shows level, xp / needed
and banked skill points (about five even-level kills per level); spend them on X, then key 1 (Smash) leaps to the
nearest enemy and stuns it (100 stamina, 10 s cooldown that points shorten), 2 Cyclone channels, 3 War Frenzy buffs,
4 Rock Fist charges. Basic hits fill MP; hold M2 (bar turns pink) and release for a special that scales with the MP
spent. Every other key in `keybinds.json#hybrid` (Tab, F, T, C, M, F1, F3) is bound but does nothing yet. Buy a shield at the weapon vendor to block; the grey bar is block-power, the purple one stealth (rogue Sneak on key 2). Sell loot at a vendor to afford the stock.

## The loop for every slice (do not skip step 1)
1. **Ontology sync** — read the §3 class + §6 generator + `instances/*.json` for the feature.
   Whatever the sources never gave: add `design.<topic>` to `generators.json`, a `**D<n> … —
   DECIDED <date>**` line in `domain.md §7`, a `[x] D<n>` line in `todo_decide.md`, a status line
   in `ontology/README.md`. If instance data can drift, add a validator rule in `model.gd
   validate()` (see `c-roster-ids`). Run the validator.
2. **Router** — `game-from-ontology` → `router` skill picks engine/discipline skills; read them.
3. **Code** in the `game/` folder named by the §3 section (table in `game/README.md`). Lazy
   version first (ponytail rules); every deliberate cut gets a `ponytail:` comment **and** a
   line in `docs/ROADMAP/todo_implement.md`.
4. **One headless test per slice** (`game/**/test_*.gd`, `extends SceneTree`), plus the boot
   check. All checks are listed in `game/README.md`. Run each under `timeout` (see gotchas).
5. **Visual check**: `--write-movie` for 3D; HUD needs an in-game viewport capture (gotchas).
6. Update `game/README.md` folder table + checks, `todo_implement.md`, then commit when the
   owner says so (they have asked for a commit, and since D19 a push, at the end of each slice).

## Gotchas that cost time (all verified)
- Headless Godot has no class-name cache: engine scripts `preload("res://ontology/model.gd")`,
  never `CubeWorldModel` by name. Gameplay scripts never reference `OntologyDB` either; `main.gd`
  injects the design dicts (`player.setup(...)`, `creature.setup(...)`, `world.design = …`) so
  `-s` tests can drive them.
- `@onready` vars are null when `setup()` is called from a `SceneTree._init` test → use `$Node`
  inside `setup()`.
- A runtime error after an `await` in a `-s` test leaves the tree running forever → always
  `timeout 150 nix develop -c godot --headless -s <test>`. Never `pkill -f <script name>`; it
  matches your own shell.
- Godot front faces are **clockwise** (`zone_mesh.gd` emits that order).
- Vertex colours need `vertex_color_is_srgb = true` or the palette washes out.
- Hand-written `.tscn` node-typed `@export`s did not resolve → assign in code (`world.target`).
- `--write-movie` drops CanvasLayer UI: to see the HUD, temporarily save
  `get_viewport().get_texture().get_image()` from `main.gd` in a windowed run, then revert.
- zsh (the interactive shell here) does not word-split `$var`: `godot --headless $args` passes one
  argument and silently runs the main scene forever. Loops that build Godot arguments run under
  `nix develop -c bash -c '…'` (bash is in the flake for exactly this). Also: sed with `|` delimiter breaks on `|` in the text;
  Perl `$1[` is an array — use `${1}`.
- Zone build ≈ 40 ms on the main thread (2 per frame): expect hitches; threading is on the todo.
- Low FPS with idle-looking CPU/GPU = the main thread (physics) pegged: run the game, then
  `./monitors/godot_threads.sh` (red = physics catch-up spiral). Headless `--print-fps` reproduces it
  without any GPU. Root cause 2026-09-08: every creature simulated on trimesh zones (D16 fixed).

## Where things are
```
ontology/            domain.md, instances/, model.gd, validate.gd, README.md (status log)
game/ontology_db.gd  autoload: OntologyDB.data (typed), .ruleset, .design, .flag()
game/main.{tscn,gd}  wires World, Player, HUD, InventoryPanel, Sun, sky; spawn point; starting inventory
game/world/          world_gen.gd (lands, climate, heights, names, danger tier, creature level, village placement + plateau)
                     zone_mesh.gd, world.gd (zone + village streaming, spawning), spawner.gd, settlement.gd (layout, build)
game/entities/       entity.gd (HP/level/hostility/step-up, statuses: stun/knockback/burning/slow), player.gd (E: interact → talk / respec / rest / pick up), orbit_camera.gd, creature.gd, npc.gd
game/combat/         combat.gd (pure formulas), abilities.gd (D21 runtimes: cooldowns, costs, dash/channel/cast state, buffs)
game/items/          item.gd, items.gd (gen-item, stats, names, gen-loot, ground drops), inventory.gd,
                     ground_item.{tscn,gd}, inventory_panel.gd, shop.gd (stock, prices, buy / sell), shop_panel.gd
game/progression/    progression.gd (level settle; xp_for_kill is in ontology/model.gd), skill_tree.gd (points, spend rule,
                     per-point mults; nodes from model.gd#skill_tree), skill_panel.gd (X)
game/meta/           input_map.gd (keybinds.json#hybrid → InputMap), hud.gd (HP/MP/stamina bars, hotbar cooldown line)
docs/ROADMAP/        todo_decide.md (D1–D22), todo_implement.md (deferrals), cut/Omega specs
```

## Next slice (recommended order)
1. Projectiles + weapon movesets (§3.3 `weapon-type.m1/m2`; `todo_implement.md` Combat): bow / crossbow / staff / wand /
   bracelet basics as projectiles or beams, the burst-stubbed ultimates (fire-missiles, bubbles, shuriken), then game feel
   (hit-stop, damage numbers, stun stars / buff icons, sounds from `audio.json`).
2. Items backlog (`todo_implement.md` §3.4): rings/amulets, gear HP, upgrade cubes, tabs/tooltips.
3. World backlog: thread zone building (`world.gd` ponytail), a game clock (`c-midnight-reset`: restock, inn sleep), flora / dungeons / POIs
   (`gen-flora`, `gen-dungeon`, `gen-poi`), villagers with schedules (`gen-schedule`).

Memory for the agent runtime mirrors this file (`cubeworld-rebuild-status`), but this file is
the canonical handoff.
