# Handoff — resume here (written 2026-09-08, after the D16 perf slice)

Read this, then `git log --oneline -8`, then `docs/ROADMAP/todo_implement.md`. Nothing else is
needed to continue; the repo is self-describing from these three.

## What this project is
Cube World rebuild in Godot 4.7.2 + GDScript, **ontology-first**: `ontology/` is the source of
truth (`domain.md` classes/relations/constraints/generators, `instances/*.json` content,
`model.gd` typed loader + validator). Engine code in `game/` only *consumes* it. Every decision
the sources never settled is a numbered **D** entry: `domain.md §7` + `docs/ROADMAP/todo_decide.md`
(D1–D17 all taken). Designed numbers live in `ontology/instances/generators.json#design.<topic>`.

## State of the build (all committed, master, owner pushes to GitHub themselves)
| commit | slice | what runs |
|---|---|---|
| c9107df | ontology closed | 40 instance files, validator 0 errors |
| 4430b5b | scaffold | `project.godot`, `OntologyDB` autoload loads + validates the ontology |
| 475e72b | world (§3.1, D12) | seeded heightfield lands, climate → landscape, names, zone streaming + trimesh collision |
| e33c991 | player (§3.2, D13) | CharacterBody3D walk/sprint/jump/swim/step-up/stamina, orbit camera, InputMap from `keybinds.json#hybrid` |
| 250c121 | creatures (§3.2, D14) | per-zone spawns from landscape rosters, idle/wander/chase/return FSM, `entity.gd` base |
| 457c947 | combat (§3.3, D15) | basic attack, combo, crit, armor floor, creature attacks + retaliation, death/respawn, fall damage, HUD |
| 69b5702 | perf (D16) | creatures frozen beyond `design.spawns.ai.sim-radius` (80 blocks): 4 → 60 FPS; `monitors/godot_threads.sh` red/green verdict |

Playable now: `nix develop -c godot` — WASD/Shift/Space, mouse look, wheel zoom (0 = first
person), M1 attack, Esc frees the mouse. You spawn at the centre of land (0,0), seed 26879, a
deadlands land; red capsules are hostiles.

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
   owner says so (they have asked for a commit at the end of each slice so far).

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
- zsh: `set -- $var` does not word-split; sed with `|` delimiter breaks on `|` in the text;
  Perl `$1[` is an array — use `${1}`.
- Zone build ≈ 40 ms on the main thread (2 per frame): expect hitches; threading is on the todo.
- Low FPS with idle-looking CPU/GPU = the main thread (physics) pegged: run the game, then
  `./monitors/godot_threads.sh` (red = physics catch-up spiral). Headless `--print-fps` reproduces it
  without any GPU. Root cause 2026-09-08: every creature simulated on trimesh zones (D16 fixed).

## Where things are
```
ontology/            domain.md, instances/, model.gd, validate.gd, README.md (status log)
game/ontology_db.gd  autoload: OntologyDB.data (typed), .ruleset, .design, .flag()
game/main.{tscn,gd}  wires World, Player, HUD, Sun, sky; spawn point; starter weapon
game/world/          world_gen.gd (lands, climate, heights, names, danger tier, creature level)
                     zone_mesh.gd, world.gd (streaming + spawning), spawner.gd
game/entities/       entity.gd (HP/level/hostility/step-up), player.gd, orbit_camera.gd, creature.gd
game/combat/         combat.gd (pure formulas)
game/meta/           input_map.gd (keybinds.json#hybrid → InputMap), hud.gd
docs/ROADMAP/        todo_decide.md (D1–D15), todo_implement.md (deferrals), cut/Omega specs
```

## Next slice (recommended order)
1. **§3.4 items**: item instances from `gen-item` / `gen-item-stats` (`stats.json`, `item-types.json`,
   `materials.json`, `rarities.json`, `affixes.json`), equipment slots, loot on creature death
   (`gen-loot`, `loot-rule`), inventory. Design gaps to settle as D18: drop rates, starting
   inventory, stack rules (D6 says no cap).
2. **§3.5 progression**: `level-formula` (already in `model.gd`: `power_for_level`, `xp_to_next`),
   XP on kill, skill points (D6/D10 tree) → `player.level` stops being a constant.
3. Then settlements + `world.spawn-rule`, or thread zone building.

Memory for the agent runtime mirrors this file (`cubeworld-rebuild-status`), but this file is
the canonical handoff.
