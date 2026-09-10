# game/ — engine layer

Consumes `ontology/`; never redefines it. New gameplay = ontology first (sync rule), then code here.

## Data flow
- `OntologyDB` (autoload) loads `ontology/instances/*.json` through `ontology/model.gd` at start,
  runs the §5 constraints, aborts the process on any error. Read-only for the whole run.
- `OntologyDB.ruleset` = the default ruleset (hybrid). Gate features with `OntologyDB.flag("…")`.
- `OntologyDB.design` = `generators.json#design`, the owner-designed numbers (D6–D19).
- Mutable state (world, characters, inventory) belongs to `save-data` (§3.7), not to the autoload.
- Engine scripts `preload("res://ontology/model.gd")` instead of naming `CubeWorldModel`: the
  class-name cache only exists after an editor scan, headless CI has none.

## Folders follow domain.md §3 (create a folder when its first scene lands)
| §3 section | folder | first pieces |
|---|---|---|
| 3.1 World | `world/` | **done (D12):** `world_gen.gd` gen-world/climate/terrain/name, `zone_mesh.gd` heightfield mesher, `world.gd` zone streaming + trimesh collision |
| 3.2 Entities | `entities/` | **player (D13) + creatures (D14):** `entity.gd` base (HP, level, hostility, step-up), `player.{tscn,gd}` walk/sprint/jump/swim/stamina, `orbit_camera.gd` SpringArm3D orbit, `creature.{tscn,gd}` idle/wander/chase/return FSM, `world/spawner.gd` gen-spawns per zone; next npc, pet |
| 3.3 Combat | `combat/` | **basics (D15) + class abilities (D21):** `combat.gd` pure formulas (weapon damage, armor floor, crit, combo, player/NPC HP+damage); `abilities.gd` runner (dash / channel / burst / buff / heal from `design.abilities`, cooldowns, costs, buff multipliers, absorb); MP + M2 special attack in `player.gd`; stun / knockback / burning / slow in `entity.gd`; next block, dodge, stealth bar, projectiles |
| 3.4 Items | `items/` | **basics (D18):** `item.gd` instance, `items.gd` gen-item / gen-item-stats (damage, armor) / item names / gen-loot + ground drops, `inventory.gd` stack + slot rules, `ground_item.{tscn,gd}` pick-up area, `inventory_panel.gd` (B); next crafting, shop, leftovers |
| 3.5 Progression | `progression/` | **basics (D19) + skill tree (D20):** `progression.gd` level settle (overflow, multi-level); XP per kill lives in `model.gd#xp_for_kill`, awarded by `creature.gd` to its last attacker, `player.gd#gain_xp` levels up (max HP, heal, banked skill points), HUD level/xp line; `skill_tree.gd` nodes from `model.gd#skill_tree`, spend/unlock rule, per-point multipliers; `skill_panel.gd` (X); `player.gd#use_class_skill` keys 1-4 → `combat/abilities.gd` (D21), swim speed per point; next power-gate, trainer respec, artifacts |
| 3.6 Missions | `missions/` | mission-type runtime, arena |
| 3.7 Meta | `meta/` | `input_map.gd` builds InputMap from `keybinds.json#hybrid`; `hud.gd` HP/MP/stamina/combo/land caption + hotbar cooldown line (D21); next server/client (`godot-multiplayer`), save-data |

## Checks
```
nix develop -c godot --headless -s ontology/validate.gd            # ontology constraints
nix develop -c godot --headless --quit                             # autoload + main scene boot
nix develop -c godot --headless -s game/world/test_world_gen.gd    # gen-world invariants (seed, range, names, mesh)
nix develop -c godot --headless -s game/entities/test_player.gd    # player physics (land, jump height, step-up, sprint, camera)
nix develop -c godot --headless -s game/entities/test_creatures.gd # gen-spawns determinism, rosters, level band, HP calibration, FSM
nix develop -c godot --headless -s game/combat/test_combat.gd       # formulas, hit/combo/whiff, retaliation, kill, respawn
nix develop -c godot --headless -s game/items/test_items.gd         # gen-item roll/stats/names, slots, stack rule, gen-loot rates, kill → drop → pick-up → Q
nix develop -c godot --headless -s game/progression/test_progression.gd   # xp-to-next table, xp-for-kill gap rule, settle, c-xp-config, kills → level 2
nix develop -c godot --headless -s game/progression/test_skill_tree.gd    # tree shape per spec, c-tree-shape, spend/unlock, per-point mults, key slots, key 1 smash + cooldown
nix develop -c godot --headless -s game/combat/test_abilities.gd    # c-ability-runtime, costs, smash dash+stun, cyclone ticks, buffs, rock fist, MP per hit, M2 charge, burning, heal cast, shield, bulwark
nix develop -c godot --write-movie /tmp/f.png --fixed-fps 30 --quit-after 100   # 3D frames of the real scene (the movie writer skips CanvasLayer UI)
./monitors/godot_threads.sh                                        # while the game runs: main-thread CPU, red = physics spiral (D16)
# HUD check: temporarily save get_viewport().get_texture().get_image() from main.gd, windowed run
```
