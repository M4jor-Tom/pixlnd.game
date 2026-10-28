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
| 3.1 World | `world/` | **done (D12) + settlements (D22) + finite world generation (World/reset item 1) + boundary/player overview (item 2):** `world_gen.gd` gen-world/climate/terrain/name + `village_at` (placement, plateau in `height_at`), `zone_mesh.gd` heightfield mesher, `world.gd` zone streaming + trimesh collision + village streaming, `settlement.gd` ring of box buildings + NPCs, `world_map.gd` fixed outline/player view, player boundary guard, spawner skips the square; next flora, dungeons, POIs |
| 3.2 Entities | `entities/` | **player (D13) + creatures (D14):** `entity.gd` base (HP, level, hostility, step-up), `player.{tscn,gd}` walk/sprint/jump/swim/stamina, `orbit_camera.gd` SpringArm3D orbit, `creature.{tscn,gd}` idle/wander/chase/return FSM, `world/spawner.gd` gen-spawns per zone, `npc.gd` service NPC at a door (D22, unattackable); `player.gd` dodge / block / stealth bar + statuses on the player, `creature.gd` stealth aggro range + hit statuses (D23); combat roles (D26): `spawner.gd` gives every group a `design.creature-roles` role (`any-class` humanoids roll melee / ranged / mage), `creature.gd` ranged / mage keep their distance, need line of sight, wind up and fire a `combat/projectile.gd` shot that applies statuses and never hits another creature; canonical logical pair/pack targeting and protected return via `combat/targeting.gd`; next villagers, pet |
| 3.3 Combat | `combat/` | **basics (D15) + class abilities (D21):** `combat.gd` pure formulas (weapon damage, armor/Resistance defence stages, crit, combo, player/NPC HP+damage); `abilities.gd` runner (dash / channel / burst / buff / heal from `design.abilities`, cooldowns, costs, buff multipliers, absorb); MP + special attack in `player.gd`; stun / knockback / slow and independent burning/poison applications in `entity.gd`; dodge / block / stealth in `entities/player.gd` from `design.defence` (D23); `projectile.gd` shots + basic / special per weapon-type from `design.movesets` in `entities/player.gd` (D24); game feel (D25): `feel.gd` plays a `design.feel` bundle per event (hit-stop on `Engine.time_scale`, camera trauma on `orbit_camera.gd`, a synthesised `AudioStreamGenerator` blip, floating damage numbers, impact flash, projectile trail, stun stars) — hooked in `player.gd` (hit / crit / kill / hurt / block / dodge / shoot / level-up / pick-up), `entity.gd` (dot numbers, stars) and `projectile.gd`; creature shots reuse the same projectile + impact bundles (D26); next hit animations |
| 3.4 Items | `items/` | **basics (D18):** `item.gd` instance, `items.gd` gen-item / gen-item-stats (damage, fixed HP, armor, Resistance) / item names / gen-loot + ground drops, `inventory.gd` stack + slot rules, `ground_item.{tscn,gd}` pick-up area, `inventory_panel.gd` (inventory control); `shop.gd` stock + `design.prices` buy/sell, `shop_panel.gd` (NPC interaction at a vendor, D22); next crafting, leftovers |
| 3.5 Progression | `progression/` | **basics (D19) + skill tree (D20):** `progression.gd` level settle (overflow, multi-level); XP per kill lives in `model.gd#xp_for_kill`, awarded by `creature.gd` to its last attacker, `player.gd#gain_xp` levels up (max HP, heal, banked skill points), HUD level/xp line; `skill_tree.gd` nodes from `model.gd#skill_tree`, spend/unlock rule, per-point multipliers; `skill_panel.gd` (skills-window control); `player.gd#use_class_skill` class slots 1–4 → `combat/abilities.gd` (D21), swim speed per point; `skill_tree.gd#respec` at the class trainer (NPC interaction, D22); new-equip power gate uses live character level; next artifacts |
| 3.6 Missions | `missions/` | mission-type runtime, arena |
| 3.7 Meta | `meta/` | `input_map.gd` builds InputMap from `keybinds.json#hybrid`; `hud.gd` HP/MP/stamina/combo/land caption (+ village, D22) + hotbar cooldown line (D21) + service toasts + block-power / stealth bars, blocking text (D23) + level-up toast pop and the buff-icon row from `design.feel` (D25; "stunned!" is now 3D stars over the head); `world/world_state.gd` + `world/save_data.gd` retain implemented character/world state; next server/client (`godot-multiplayer`) |

## Saved-world foundation

`main.gd` owns mutable `WorldState` and validated atomic JSON save/load (`user://world.json`;
`--save-path=/absolute/path.json` selects another file). A fresh save alone receives the starting kit
and 07:00 clock. Invalid saves stop with diagnostics without overwriting the original; no legacy
migration or offline time advancement. Capture retains hero ID/class/spec, level/XP, banked/spent
skills, coins, bag/equipment (including spirits) and per-world position/respawn, not transient player
HP/statuses/cooldowns; restore refills HP. Validation establishes current-rule validity, not earned
progression. Lifecycle saves cover state transitions, streaming unload and graceful shutdown,
not a promised crash-checkpoint cadence. Portable-world import UI, recipes, artifacts/source claims,
pets, exploration, personal travel/lore and networking remain unfinished.

`world.configure(ontology, design, state, party_provider)` injects connected characters; party
min/max levels include awaiting-respawn members, and empty parties defer generation. Ambient
logical incarnations and their independent threat/order/provocation outlive zone nodes. Midnight
renews eligible dead ambient members, never surviving incarnations. The clock runs at design's
10× rate independently of presentation hit-stop. `WorldState` supplies closed-volume/coalesced
refresh and completion-before-refresh callbacks for future site owners; site owners use those callbacks for safe renewal. Boss/content state, source/cycle reward receipts, rescue completion and remaining daily vendor gear share those lifecycle saves. Delivered ground loot keeps ordinary pickup/expiry/unload retirement; undelivered payloads and pending gear classes survive restart.

Either hand slot may be independently empty; removing one item leaves the other untouched.
Existing class/slot/2H restrictions remain. New equip attempts require item power no greater than
live character power, including after level-up or restore. Rejection leaves inventory, stats and
notifications unchanged; structurally legal already-worn gear is retained/refilled on restore,
not retroactively evicted. Carry/trade, consumables and carried spirits are unaffected.
New weapon-dependent requests require a main-hand
weapon without spending on rejection, while a shield alone retains blocking and worn stats.
Independent buffs/heals/movement/taunts and committed effects keep their existing rules.

## Initial playable sites

`world_gen.gd` jointly validates a seeded village, all six sites and four-wide access before
publication. An ocean search failure yields a dry 64-square settlement hub, islands and
collidable boardwalks. One empty house contains the village access passage; services and the
fixed building ring remain. Failed generation reports seed/land/candidate diagnostics and publishes
no partial land. `encounter_gen.gd` holds geometry/stable assignments; `encounter_site.gd` builds
floors, six-high ruins, four-by-five doors and visibly bounded battlefields from the same components
used by closed occupancy. Terrain cuts cannot protrude through access.

`world.ensure_land`, `stream_sites`, `populate_site` and `refresh_site` own the actual streaming
seam. Reproduction depends on relevant seed/coordinates, input data/design/configuration and
generator/engine revision, not seed alone; saves do not pin those revisions or promise cross-version
bit identity. Same-seed worlds have independent IDs and mutable histories. `WorldState.lands` saves joint geography/pack roles/home positions/permanent special/spirit
choices independently of `sites[id].mobs` current incarnations and `spirit_levels` initial boss
levels. There are 46 skeletons (seven bosses) and four unattackable captives per land; ambient
rosters are unchanged and authored support/access is reserved from wild generation. Genuine safe
renewal regenerates only defeated members using the current connected-party band; surviving HP,
positions, levels and threat remain. Save validation rejects partial sites, altered geometry,
assignments, packs, counts and local NPC curves. Cleared suppliers complete through captive conversation or automatic last-player exit before pending refresh; completed rescues never regenerate.

`boss_special.gd` executes each saved stomp/charge assignment through the real creature simulation
and current-target authority: floor warnings, physical defence/status handling, swept charge,
recovery/cooldown, interruptions and lifecycle cancellation. `encounter_contents.gd` builds eight
collision-bearing stone rubble blocks per arena with actor-safe 72-world-hour restoration, two
persisted spike phases with their distinct defence path, and direct-only furnishing HP. Each ruins
room saves a shared creation/renewal level for new guards and furnishings; survivors retain their
incarnations. Table pairs issue independently before break, with source/cycle delivery records.
The focused checks below drive actual main/world nodes, damage, pickup, renewal and cold saves;
they do not certify the separately deferred native collision issue.

Site deaths issue shared ordinary rolls plus guaranteed boss gear and the two ruins bosses' fixed-type/initial-level spirits. Mission packages snapshot distinct inside classes at final death (including awaiting-respawn members), fall back to the finisher, or defer to the first later entrant. Camp completion and captive conversation/last-exit deliver once; no extra completion XP. Spirits can be carried, not attached.

Weapon/armor vendors retain their generated gear and purchases across reopening/restart. Four land-shared supplier rescues raise the common ceiling through legendary at the next ordinary daily generation/restock, never an immediate rescue reroll. Consumables stay unlimited and prices/quantities unchanged. Full independent review, packaged staged/committed-input checks and native feature/HUD movie remain acceptance/publication gates; focused checkout tests do not certify the deferred native collision issue.

## Correction validation checkpoint

The six authorized game-review corrections passed selected-group independent review, the full
65-invocation quality gate, isolated main boot and ten affected windowed regression scripts.
Inspected real-main viewport/HUD frames cover stun Jump/Quick Item rejection and expiry, plus
inventory power rejection and later progression-based admission. Input/touch injection is synthetic,
not Android hardware acceptance. The supplemental creature-motion discrepancy was traced to spawning
before the teleported player synchronized with physics: contact recovery/platform carry contaminated
all three assertions. A fixture-only synchronization wait passes the one-variable counterfactual;
normal-callback chase, pure stun, real knockback and recovery have inspected native captures, and
stun-motion/boss-special checks pass headless and windowed. Independent F3 resolution and final
integrated correction reviews passed with no findings. The old combined run remains failed;
F1/F4/F5 observations compose with their passing scoped regressions rather than claiming that
capture was a clean combined run. The accepted checkpoint and its visual qualifications are retained
in Git history at `4bf90b7:docs/pixlnd-8158ab2-game-review.md`. Normal pre-push and remote/CI checks
govern publication. F6/F7/F9 subsequently passed the combined 71-invocation gate and independent implementation
reviews. Cyclone now rotates the body clockwise once per game second, contacting targets in angular
order and retaining partial facing at duration/fuel exhaustion; camera-directed movement, subsequent
attacks and ordinary blocking remain independent. All implemented item producers convert source
level to bounded item power before spread, with coupled current-rule save checks. Apple uses healing
coefficient 20 through selected Use, Quick Item and synthetic Android input. Native main/HUD checks
cover both warrior specializations, partial stop, ordinary controls, Apple effects, vendor purchases,
progression-based equip admission and cold restore. These are not Android hardware, complete
streaming/performance, legacy-save migration or parked collision-resolution acceptance. The native
[changelog demonstration](../docs/changelogs/pre-v1/20261028164624_game-review-corrections_f5bbdba.md)
is a staged real-state example, not exhaustive regression footage. Final media review and normal
publication checks remain separate gates.

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
Persistence tests require `PIXLND_TEST_DIR` to name an existing, writable, isolated absolute scratch
directory. They never use `user://`. Keep test saves/logs there and use a separate explicit save path
for boot checks. Run every Godot invocation under `timeout` (including older commands below).
Use the [current calibrated deadlines](../docs/quality-checks.md), with `timeout` inside Nix;
older command samples below do not override those deadlines.
```sh
# export PIXLND_TEST_DIR=/absolute/path/to/isolated-check-output
nix develop --no-update-lock-file -c timeout 681 godot --headless -s ontology/test_channel_config.gd # required raw/loaded finite angular speed and drain; zero-drain positive controls
nix develop --no-update-lock-file -c timeout 681 godot --headless -s ontology/test_apple_healing_config.gd # exact raw/loaded Apple runtime coefficient and malformed/missing negatives
nix develop --no-update-lock-file -c timeout 681 godot --headless -s game/combat/test_cyclone.gd # both specs, ordered directional contacts, partitions/endpoints/fuel, moving bodies, facing/camera ownership and synchronous cancellation
nix develop --no-update-lock-file -c timeout 681 godot --headless -s game/items/test_item_power.gd # literal source-to-power producer anchors/clamps, RNG preservation, reward/vendor/table units and powered imports
nix develop --no-update-lock-file -c timeout 681 godot --headless -s game/world/test_item_power_cold.gd # real six-site saves, pending/delivered receipts, purchased stock, bounded fresh-process restore and invalid-load original-file protection
nix develop --no-update-lock-file -c timeout 681 godot --headless -s game/items/test_apple_healing.gd # real selected/Quick/synthetic Android Use: healing, cap, rarity/power and selected-stack consumption
nix develop --no-update-lock-file -c timeout 227 godot --headless -s game/entities/test_stun_motion.gd # normal creature physics: pure stun stops CHASE/WANDER/protected RETURN; both knockback orders, wall/slide consumed residual, expiry/resumption, gravity/clocks and simulation/death freeze
nix develop --no-update-lock-file -c timeout 227 godot --headless -s game/entities/test_stun_input.gd # normal-callback mapped keys/native synthetic touch: stun blocks jump/sustain/ascent; dead/stunned Talk/Pick Up/Use reject, real services and selected panels; expiry/fresh requests, passive coins and live timers/push
nix develop --no-update-lock-file -c timeout 227 godot --headless -s game/entities/test_landing_death.gd # real-floor fatal landing stops mapped Q/basic/Smash edges; nonlethal and lethal-DOT controls, one death signal, retained items/coins/XP and equipped-max respawn
timeout 150 nix develop --no-update-lock-file -c godot --headless -s ontology/test_artifact_corrections.gd # bounded checked-in artifact logarithm/config and historical/hybrid description correction; not production artifact enforcement/runtime
timeout 150 nix develop --no-update-lock-file -c godot --headless -s ontology/test_identity_skills.gd # raw identity catalogs/shapes, ordered spec ownership, shared roots/links and Assassin single rank-3 Camouflage; cumulative diagnostics
timeout 150 nix develop --no-update-lock-file -c godot --headless -s ontology/test_provenance.gd # exact qualified tags, finite §5 source envelopes/overrides, malformed annotations and unresolved-history controls
timeout 150 nix develop --no-update-lock-file -c godot --headless -s ontology/test_required_inputs.gd # finite §5 heterogeneous catalogs/configs, raw conversion hazards, climate/family/building/service/style closure; cumulative missing/malformed inputs
timeout 150 nix develop --no-update-lock-file -c godot --headless -s ontology/test_required_catalogs.gd # required/malformed whole races and movesets, real loader and cumulative/prior errors
timeout 150 nix develop --no-update-lock-file -c godot --headless -s ontology/test_world_references.gd # district building/class and landscape dungeon/POI closure, malformed references and retained annotations
timeout 150 nix develop --no-update-lock-file -c godot --headless -s game/world/test_spawner.gd # real ordinary plans exclude always-boss species regardless of category; mixed/boss-capable/category controls preserve RNG draws
timeout 150 nix develop --no-update-lock-file -c godot --headless -s ontology/test_validation_fail_closed.gd # malformed loot/reference continuation, actual CLI exit truth table/prior load errors and OntologyDB false/empty abort; child logs stay in PIXLND_TEST_DIR
timeout 150 nix develop -c godot --headless -s ontology/test_encounter_rewards_config.gd # exact required package/loot/daily shop inputs, cumulative malformed/missing parents and references
timeout 150 nix develop -c godot --headless -s game/items/test_encounter_rewards.gd # actual death/shared pickup/expiry/unload/restart, seven boss guarantees, fixed spirits and class-legal gear
timeout 150 nix develop -c godot --headless -s game/world/test_supplier_shops.gd # actual main vendor/captive interactions, last-exit-before-refresh, class snapshot/deferral, saved purchases/daily ceilings and exact save negatives
timeout 150 nix develop -c godot --headless -s ontology/test_encounter_feature_config.gd # required special/rubble/spike/furnishing inputs, recursive cumulative negatives
timeout 150 nix develop -c godot --headless -s game/combat/test_boss_special.gd # actual main stomp/charge, both stun/knockback orders in active warnings/charge with preserved push and wall consumption, physical defence/sweep/rubble/walls, timer/cancel/inactive/unload/restart and saved-state negatives
timeout 150 nix develop -c godot --headless -s game/world/test_encounter_contents.gd # actual collision/HP/pickup/independent table pairs, ordinary nonlethal/lethal prop-only contact retirement/no spill/no combat rewards, trap defences/phases/hitsets, safe restoration, room renewal and saved-state negatives
timeout 150 nix develop -c godot --headless -s ontology/test_playable_site_config.gd # selected geometry/population/local-stat/assignment inputs, cumulative missing/malformed/changed negatives
timeout 150 nix develop -c godot --headless -s game/world/test_playable_sites.gd # joint generation, cold reversed-order village/sites/routes/assignments, all-six/counts/closed occupancy/access/bounds, all-sea hub and atomic failure
timeout 150 nix develop -c godot --headless -s game/world/test_playable_sites_runtime.gd # real main/world geometry/collision/route-width/steps, ocean/boundary terrain, unload/renewal/restart and exact-content save negatives
timeout 450 nix develop -c godot --headless -s game/world/test_local_frame_routes.gd -- --land=-512,-512 --ocean # actual player capsule across all dry-hub/boardwalk/site routes; omit --ocean for natural terrain, select other lands with --land=x,z
timeout 150 nix develop -c godot --headless -s ontology/test_initial_encounter_config.gd # exact-one hybrid settlement/config negatives
timeout 150 nix develop -c godot --headless -s ontology/test_state_targeting_config.gd # selected AI/clock/taunt inputs, missing/malformed/changed negatives
timeout 150 nix develop -c godot --headless -s game/items/test_independent_hands.gd # shield-only/off-hand-1H lifecycle, worn stats/blocking/no attacks, independent removals and illegal loadouts
timeout 150 nix develop -c godot --headless -s game/entities/test_unarmed.gd # all specs, no-spend rejection, independent actions and committed effects
timeout 150 nix develop -c godot --headless -s game/entities/test_creature_ai_contract.gd # actual HP threat, ties/stealth/DOT, packs/sight/taunts, return/absence/death/finisher
timeout 150 nix develop -c godot --headless -s game/world/test_encounter_clock.gd # closed unions, coalescence, deferred refresh, completion ordering/no offline time
timeout 150 nix develop -c godot --headless -s game/world/test_save_data.gd # atomic character/world roundtrip, equipment/skills/spirits, retained worn +40 at level10/refill, new +40 re-equip rejection/progression and restored +32 admission, invalid-save/original protection
timeout 150 nix develop -c godot --headless -s game/world/test_saved_runtime.gd # real main/world unload/restart/midnight and empty/independent-hand lifecycle/HUD boots

timeout 900 bash tests/test_flake.sh                            # pure default/platform checks; NVIDIA headless boot if a module is loaded
nix develop -c godot --headless -s ontology/validate.gd            # ontology constraints
nix develop -c godot --headless -s ontology/test_equipment_config.gd # slot indices/parents, raw item-type/weapon ownership/capacity and Wand/recipe negatives + cumulative diagnostics
nix develop -c godot --headless -s ontology/test_world_bounds_config.gd # selected finite world scales and missing/malformed parent paths
nix develop -c godot --headless -s ontology/test_gear_hp_config.gd # fixed HP required/finite/exact inputs and cumulative negatives
nix develop -c godot --headless -s ontology/test_dot_config.gd     # required/malformed DOT rows, exact selected numeric inputs and accumulated negatives
nix develop -c godot --headless -s ontology/test_resistance_config.gd # selected Resistance floor, active material multipliers, armor slots and fail-closed negatives
nix develop -c godot --headless -s ontology/test_android_profile.gd # required/malformed profile and canonical action-reference negatives
timeout 150 nix develop -c godot --headless --quit -- --save-path="${PIXLND_TEST_DIR:?set isolated output directory}/boot.json" # isolated real boot
nix develop -c godot --headless -s game/world/test_world_bounds.gd # finite lands, edge meshes, spawn plans and streaming
nix develop -c godot --headless -s game/world/test_world_travel.gd # true-limit edges/corners, spawn-scale wall slide, turn-back, movement paths and Teleport cost/cooldown/distance
nix develop -c godot --headless -s game/meta/test_world_map.gd # boundary projection/toggle, live simulation, gameplay gates and synthetic Android ownership/layout
nix develop -c godot --headless -s game/world/test_world_gen.gd    # gen-world invariants (seed, range, names, mesh)
nix develop -c godot --headless -s game/world/test_settlement.gd   # village placement / plateau / layout, no spawns near the square, shop stock + prices, buy / sell, respec, inn, interact → NPC
nix develop -c godot --headless -s game/entities/test_player.gd    # player physics (land, jump height, step-up, sprint, camera)
nix develop -c godot --headless -s game/meta/test_android_touch.gd # real native joystick/buttons, ownership, simultaneous streams, cancel/Back/layout/dp, root screen events
nix develop -c godot --headless -s game/entities/test_android_controls.gd # native events -> player/camera, separated controls, ordered resource/busy/UI gating, touch inventory wrong-class red/rejection and operations/scroll, cancellation, high-DPI panels
nix develop -c godot --headless -s game/entities/test_panel_time.gd # desktop wrong-class red/rejection + touch inventory/skills/shop: live DOT, cooldowns, buff/dodge expiry, blocked gameplay input, close/reopen movement, lethal DOT
nix develop -c godot --headless -s game/entities/test_creatures.gd # gen-spawns cold reversed-order groups/roles/positions/stats/seeds, ordinary rosters, level band, HP calibration, FSM
nix develop -c godot --headless -s game/entities/test_creature_roles.gd   # c-creature-roles, role parsing/spawn groups, ranged keep-away/LOS/shot, two-player ordinary cardinality with block/dodge/lethal protection, multi-player mage splash + burning, poison dodge exception, no friendly fire, guaranteed selected enemy-hit effects
nix develop -c godot --headless -s game/combat/test_combat.gd       # formulas, hit/combo/whiff, retaliation, kill, respawn
nix develop -c godot --headless -s game/items/test_items.gd         # gen-item roll/stats/names, slots, legal loadouts, atomic 2H/shield conflict rejection in either equip order, stack rule, gen-loot rates, kill → drop → pick-up → quick-item
nix develop -c godot --headless -s game/items/test_equipment.gd     # live power1/+2 and power32/+32/+33/+40 admission, real progression, atomic HP/weapon/charge/coin/signal rejection; starters, trade/consumables/spirits; canonical class/slot/hands/rings and local identity
nix develop -c godot --headless -s game/items/test_gear_hp.gd       # literal slot/material/roll/upgrade HP, eligible +1/10-upgrade swaps/no healing, distinct above-power rejection, notifications, initial/level/respawn HP, HUD and percentage consumers
nix develop -c godot --headless -s game/progression/test_progression.gd   # xp-to-next table, xp-for-kill gap rule, settle, c-xp-config, kills → level 2
nix develop -c godot --headless -s game/progression/test_skill_tree.gd    # tree shape per spec, c-tree-shape, spend/unlock, per-point mults, class slots, first-slot smash + cooldown
nix develop -c godot --headless -s game/combat/test_dot_applications.gd # independent/staggered/mixed applications, exact first/final ticks, coarse/fragmented dt, source lifetime, synchronous clear/death
nix develop -c godot --headless -s game/combat/test_abilities.gd    # c-ability-runtime, costs, Shout/Bubbles exact/crossing/large-step HoT totals, staggered expiry/cap/reset/death, smash dash+stun, cyclone ticks, buffs, Camouflage 6/7-point expiry/rejection/recast boundaries through real runner, rock fist, MP per hit, special charge, burning, heal cast, shield, bulwark
nix develop -c godot --headless -s game/combat/test_class_combos.gd # burst/dash hit/miss, whole-channel normal/early end, gains/caps/inactivity, neutral taunts/heals/buffs/movement, projectile side heal
nix develop -c godot --headless -s game/combat/test_defence.gd      # c-defence-config, dodge cost / roll / i-frames / rewards, shield + guardian block, same-interval block exhaustion / final-hit status protection, stealth fill / aggro / hit bonus / camouflage / decay, enemy-hit stun + knockback
nix develop -c godot --headless -s game/combat/test_resistance.gd  # c-attack-defence, c-resistance-mitigation, c-resistance-dot; gear, attack-type/in-flight classification, creature baseline, ordered defence and once-only burn inheritance
nix develop -c godot --headless -s game/combat/test_projectiles.gd  # c-moveset-config, ordinary Bow/Crossbow/Bracelet/Shuriken one-contact flight, selected crit/status/defence/return reduction/lethal/unequip, splash volleys and outbound/return Boomerang multi-target, beam/cursor/melee/ability AoE, arc whiff, dagger poison, lunge/finisher, four-hit crit-derived burn
nix develop -c godot --headless -s game/combat/test_feel.gd        # c-feel-config, hit-stop freeze + real-time restore + overlap, trauma decay to rest, damage number spawned / freed, kill bundle, hurt number, stun stars, projectile trail + impact, level-up, every event's synthesised sfx
nix develop -c timeout 300 godot --windowed --write-movie /tmp/demo.avi --fixed-fps 15 --quit-after 300 # native 3D movie; CanvasLayer HUD needs verified viewport composition
./monitors/godot_threads.sh                                        # while the game runs: main-thread CPU, red = physics spiral (D16)
# Native HUD movie: compose real gameplay/UI in an owned SubViewport; decode and inspect the encoded HUD, not only separate PNGs
```
