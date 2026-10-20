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

## Folders follow ontology/domain/index.md §3 (create a folder when its first scene lands)
| §3 section | folder | first pieces |
|---|---|---|
| 3.1 World | `world/` | **done (D12) + settlements (D22) + finite world generation (World/reset item 1):** `world_gen.gd` gen-world/climate/terrain/name + `village_at` (placement, plateau in `height_at`), `zone_mesh.gd` heightfield mesher, `world.gd` zone streaming + trimesh collision + village streaming, `settlement.gd` ring of box buildings + NPCs, spawner skips the square; next flora, dungeons, POIs |
| 3.2 Entities | `entities/` | **player (D13) + creatures (D14):** `entity.gd` base (HP, level, hostility, step-up), `player.{tscn,gd}` walk/sprint/jump/swim/stamina, `orbit_camera.gd` SpringArm3D orbit, `creature.{tscn,gd}` idle/wander/chase/return FSM, `world/spawner.gd` gen-spawns per zone, `npc.gd` service NPC at a door (D22, unattackable); `player.gd` dodge / block / stealth bar + statuses on the player, `creature.gd` stealth aggro range + hit statuses (D23); combat roles (D26): `spawner.gd` gives every group a `design.creature-roles` role (`any-class` humanoids roll melee / ranged / mage), `creature.gd` ranged / mage keep their distance, need line of sight, wind up and fire a `combat/projectile.gd` shot that applies statuses and never hits another creature; next villagers, pet, aggro table |
| 3.3 Combat | `combat/` | **basics (D15) + class abilities (D21):** `combat.gd` pure formulas (weapon damage, armor/Resistance defence stages, crit, combo, player/NPC HP+damage); `abilities.gd` runner (dash / channel / burst / buff / heal from `design.abilities`, cooldowns, costs, buff multipliers, absorb); MP + special attack in `player.gd`; stun / knockback / slow and independent burning/poison applications in `entity.gd`; dodge / block / stealth in `entities/player.gd` from `design.defence` (D23); `projectile.gd` shots + basic / special per weapon-type from `design.movesets` in `entities/player.gd` (D24); game feel (D25): `feel.gd` plays a `design.feel` bundle per event (hit-stop on `Engine.time_scale`, camera trauma on `orbit_camera.gd`, a synthesised `AudioStreamGenerator` blip, floating damage numbers, impact flash, projectile trail, stun stars) — hooked in `player.gd` (hit / crit / kill / hurt / block / dodge / shoot / level-up / pick-up), `entity.gd` (dot numbers, stars) and `projectile.gd`; creature shots reuse the same projectile + impact bundles (D26); next hit animations |
| 3.4 Items | `items/` | **basics (D18):** `item.gd` instance, `items.gd` gen-item / gen-item-stats (damage, fixed HP, armor, Resistance) / item names / gen-loot + ground drops, `inventory.gd` stack + slot rules, `ground_item.{tscn,gd}` pick-up area, `inventory_panel.gd` (inventory control); `shop.gd` stock + `design.prices` buy/sell, `shop_panel.gd` (NPC interaction at a vendor, D22); next crafting, leftovers |
| 3.5 Progression | `progression/` | **basics (D19) + skill tree (D20):** `progression.gd` level settle (overflow, multi-level); XP per kill lives in `model.gd#xp_for_kill`, awarded by `creature.gd` to its last attacker, `player.gd#gain_xp` levels up (max HP, heal, banked skill points), HUD level/xp line; `skill_tree.gd` nodes from `model.gd#skill_tree`, spend/unlock rule, per-point multipliers; `skill_panel.gd` (skills-window control); `player.gd#use_class_skill` class slots 1–4 → `combat/abilities.gd` (D21), swim speed per point; `skill_tree.gd#respec` at the class trainer (NPC interaction, D22); next power-gate, artifacts |
| 3.6 Missions | `missions/` | mission-type runtime, arena |
| 3.7 Meta | `meta/` | `input_map.gd` builds InputMap from `keybinds.json#hybrid`; `hud.gd` HP/MP/stamina/combo/land caption (+ village, D22) + hotbar cooldown line (D21) + service toasts + block-power / stealth bars, blocking text (D23) + level-up toast pop and the buff-icon row from `design.feel` (D25; "stunned!" is now 3D stars over the head); next server/client (`godot-multiplayer`), save-data |

## Controls contract

Consume [canonical player intentions](../ontology/domain/controls.md) and their
[controller profiles](../ontology/domain/controller-profiles.md), not physical names from
ability/source prose. `keybinds.json#hybrid` remains the unchanged keyboard adapter; it does
not implement the newly separated catalog. The profile records shared inputs, aliases, raw
camera/native UI paths and registered-only actions. Gamepad remains unselected; Android's
[native tool stack](../ontology/decisions/android-native-touch-controls.md) and
[touch profile](../ontology/domain/controller-profiles.md#android) have a first-slice runtime:
`android_touch.gd` injects separate native touch channels into player/camera and coordinates
exclusive, live inventory/skills/shop panels with explicit selected-item operations.
`main.gd` selects it only on Android; keyboard/mouse behavior is unchanged. The UI-only
SubViewport isolates native widgets and owned panel pointers from emulated mouse gameplay.
Safe-area/DPI metrics map to viewport coordinates; invalid metrics or a too-small layout
reject input with a diagnostic instead of shrinking targets. The owner has tested the game on
Android hardware. Device/OS details, individual acceptance-check coverage and render-cost measurements
are unrecorded; desktop synthetic regressions and windowed captures do not establish those results.
Broader controls work still needs separate authority; bounded debt is in
[the implementation backlog](../docs/ROADMAP/todo_implement.md#device-independent-controls-documentation-only).

## Authorized gameplay slices

Only start a slice with separate owner authorization; ontology decisions are not implementation
permission. Follow the sync rule in `AGENTS.md`. If instance data can drift, add a validator rule
in `ontology/model.gd`'s `validate()` (see `c-roster-ids`). Validate before coding, then use
`game-from-ontology` → `router` to choose the implementation skills. Add a bounded headless test
per slice and run the boot check, then inspect windowed 3D/HUD captures. Update this folder/check
reference and `docs/ROADMAP/todo_implement.md`; follow the repository's ponytail and changelog
rules. Commit and push only with current owner authority.

## Additional verified gotchas

Other architecture/test gotchas are in `AGENTS.md`.
- Godot front faces are **clockwise** (`world/zone_mesh.gd` emits that order).
- Vertex colours need `vertex_color_is_srgb = true` or the palette washes out (`world/world.gd`).
- In the original hand-written `.tscn` scenes, node-typed `@export` references did not resolve;
  assign `world.target` in code.
- For Markdown rewrites, escape a sed delimiter that occurs in the text; disambiguate Perl `$1`
  as `${1}` before `[` to avoid array access.

## Nix launchers

`nix run /path/to/pixlnd` selects the bundled game independently of the working directory.
On an x86-64 Linux
system using Ubuntu or another non-NixOS distribution with a loaded NVIDIA driver, use:

```sh
nix run --impure .#nvidia
# After publication, without a checkout:
nix run --refresh --impure github:M4jor-Tom/pixlnd.game#nvidia
```

The optional launcher supplies matching proprietary NVIDIA userspace libraries for Vulkan
and OpenGL; `--impure` permits host-driver detection. It does not install or replace the
host kernel driver, and it needs a matching installer available from NVIDIA. The first run
may download and build the userspace package; driver updates require re-evaluation.
It does not select a different renderer or change the default app/dev shell.
See the [technical choice](../ontology/decisions/nix-nvidia-launcher.md) for the compatibility pin.
Arguments are forwarded unchanged, for example `nix run --impure .#nvidia -- -- --class=ranger`.

## Checks
```sh
timeout 900 bash tests/test_flake.sh                            # pure default/platform checks; NVIDIA headless boot if a module is loaded
nix develop -c godot --headless -s ontology/validate.gd            # ontology constraints
nix develop -c godot --headless -s ontology/test_world_bounds_config.gd # selected finite world scales and missing/malformed parent paths
nix develop -c godot --headless -s ontology/test_gear_hp_config.gd # fixed HP required/finite/exact inputs and cumulative negatives
nix develop -c godot --headless -s ontology/test_dot_config.gd     # required/malformed DOT rows, exact selected numeric inputs and accumulated negatives
nix develop -c godot --headless -s ontology/test_resistance_config.gd # selected Resistance floor, active material multipliers, armor slots and fail-closed negatives
nix develop -c godot --headless -s ontology/test_android_profile.gd # required/malformed profile and canonical action-reference negatives
nix develop -c godot --headless --quit                             # autoload + main scene boot
nix develop -c godot --headless -s game/world/test_world_bounds.gd # finite lands, edge meshes, spawn plans and streaming
nix develop -c godot --headless -s game/world/test_world_gen.gd    # gen-world invariants (seed, range, names, mesh)
nix develop -c godot --headless -s game/world/test_settlement.gd   # village placement / plateau / layout, no spawns near the square, shop stock + prices, buy / sell, respec, inn, interact → NPC
nix develop -c godot --headless -s game/entities/test_player.gd    # player physics (land, jump height, step-up, sprint, camera)
nix develop -c godot --headless -s game/meta/test_android_touch.gd # real native joystick/buttons, ownership, simultaneous streams, cancel/Back/layout/dp, root screen events
nix develop -c godot --headless -s game/entities/test_android_controls.gd # native events -> player/camera, separated controls, ordered resource/busy/UI gating, all touch panel operations/scroll, cancellation, high-DPI panels
nix develop -c godot --headless -s game/entities/test_panel_time.gd # desktop + touch inventory/skills/shop: live DOT, cooldowns, buff/dodge expiry, blocked gameplay input, close/reopen movement, lethal DOT
nix develop -c godot --headless -s game/entities/test_creatures.gd # gen-spawns determinism, rosters, level band, HP calibration, FSM
nix develop -c godot --headless -s game/entities/test_creature_roles.gd   # c-creature-roles, role parsing, role per spawned group, ranged keep-away / LOS / shot, mage splash + burning, poison application/ticks through dodge, unchanged burning/direct-hit dodge, no friendly fire, blocked shot, enemy-hit roll
nix develop -c godot --headless -s game/combat/test_combat.gd       # formulas, hit/combo/whiff, retaliation, kill, respawn
nix develop -c godot --headless -s game/items/test_items.gd         # gen-item roll/stats/names, slots, atomic 2H/shield conflict rejection in either equip order, stack rule, gen-loot rates, kill → drop → pick-up → quick-item
nix develop -c godot --headless -s game/items/test_gear_hp.gd       # literal slot/material/roll/upgrade HP, class bases, swaps/no healing, rejected equip, notifications, initial/level/respawn HP, HUD and percentage consumers
nix develop -c godot --headless -s game/progression/test_progression.gd   # xp-to-next table, xp-for-kill gap rule, settle, c-xp-config, kills → level 2
nix develop -c godot --headless -s game/progression/test_skill_tree.gd    # tree shape per spec, c-tree-shape, spend/unlock, per-point mults, class slots, first-slot smash + cooldown
nix develop -c godot --headless -s game/combat/test_dot_applications.gd # independent/staggered/mixed applications, exact first/final ticks, coarse/fragmented dt, source lifetime, synchronous clear/death
nix develop -c godot --headless -s game/combat/test_abilities.gd    # c-ability-runtime, costs, smash dash+stun, cyclone ticks, buffs, rock fist, MP per hit, special charge, burning, heal cast, shield, bulwark
nix develop -c godot --headless -s game/combat/test_class_combos.gd # burst/dash hit/miss, whole-channel normal/early end, gains/caps/inactivity, neutral taunts/heals/buffs/movement, projectile side heal
nix develop -c godot --headless -s game/combat/test_defence.gd      # c-defence-config, dodge cost / roll / i-frames / rewards, shield + guardian block, same-interval block exhaustion / final-hit status protection, stealth fill / aggro / hit bonus / camouflage / decay, enemy-hit stun + knockback
nix develop -c godot --headless -s game/combat/test_resistance.gd  # c-attack-defence, c-resistance-mitigation, c-resistance-dot; equipped gear, creature baseline, ordered defence and once-only burn inheritance
nix develop -c godot --headless -s game/combat/test_projectiles.gd  # c-moveset-config, bow arrow hit / arc whiff / volley, wand beam, staff at-cursor + range, bracelet knockdown, fire-missiles, boomerang ticks + return, dagger poison, longsword lunge, shuriken throw, greatsword finisher, real four-hit crit-derived burn volley, lethal hit status rejection
nix develop -c godot --headless -s game/combat/test_feel.gd        # c-feel-config, hit-stop freeze + real-time restore + overlap, trauma decay to rest, damage number spawned / freed, kill bundle, hurt number, stun stars, projectile trail + impact, level-up, every event's synthesised sfx
nix develop -c godot --write-movie /tmp/f.png --fixed-fps 30 --quit-after 100   # 3D frames of the real scene (the movie writer skips CanvasLayer UI)
./monitors/godot_threads.sh                                        # while the game runs: main-thread CPU, red = physics spiral (D16)
# HUD check: temporarily save get_viewport().get_texture().get_image() from main.gd, windowed run
```
