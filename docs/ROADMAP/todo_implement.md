# TODO — implementation work postponed by shipped slices

Every slice ships the lazy version and lists here what it skipped. Each line names the ontology
class or generator that governs it (`domain.md`) and, where one exists, the `ponytail:` comment in
code. Pick an item → sync rule (ontology first) → `router`. Not listed: §3 sections no slice has
started yet (see the folder table in `game/README.md`) and the `Ω`/`X` themes in this folder.

## World (§3.1, slice 475e72b)
- [ ] Zone build (~40 ms mesh + trimesh) runs on the main thread, ≤2 zones/frame; hitches on load
  and when crossing zones. Thread it (`WorkerThreadPool`) — `world.gd` ponytail.
- [ ] Heightfield only: no caves, overhangs, rivers/waterfalls, lakes, plateaus/mesas, roads with
  tunnels/bridges (`gen-terrain`, `terrain-features.json`). Needs a real voxel mesher — `zone_mesh.gd`.
- [ ] Beach and snow lines are global thresholds (`design.terrain.beach-above-sea|snow-above`);
  should follow `landscape.gen` (no snow line in deserts, snow at any height in snowlands).
- [ ] Water is a flat quad at sea level: no waves, no lava/toxic river variants, no
  `landscape.hazards` (cold-water slow, toxic poison, lava burn → `status-effect`).
- [ ] Horizon shows the sky's ground hemisphere past `view-zones` = 4; add distance fog or a
  coarse far-terrain LOD (`design.terrain.view-zones`).
- [ ] Artifact count per land (D11, `design.artifacts-per-land`) is not rolled at land generation
  yet — roll it in `WorldGen.land_at` when artifacts get a slice.
- [x] Settlements (D22, `world/settlement.gd`): one village per land, plateau, ring of box buildings, service NPCs. Still open
  (`settlement.gd` ponytail): no districts, procedural rooms / roofs, doors or interiors (buildings are solid boxes), villagers,
  animals, schedules (`gen-schedule`), lanterns, dens / sewers, watchtowers; one village per land only (S: several, hidden until
  discovered); the village node floats until its zones load; not visually checked beyond `--write-movie`.
- [ ] Flora, deposits, dungeons, POIs, missions (`gen-flora`, `gen-dungeon`, `gen-poi`, `gen-missions`) — not started.
- [ ] Land caption, temperature/humidity HUD (`design.climate.hud`) not shown (`hud-element`).

## Player (§3.2 player-character, slice e33c991)
- [x] Spawn = the (0,0) village square (`world.spawn-rule`, D22). Default seed 26879 spawns in deadlands (undead village).
- [ ] Climb (E grab, wall-jump), dodge roll, glider, swim breath/drowning (`abilities.json`
  movement kind; `flags.drowning`, `diving-breath`) — `player.gd` ponytail.
- [x] Fall damage (D13 numbers) — applied on landing since the combat slice; dodge does not yet negate it.
- [x] `player.level` grows: XP per kill + level-up (D19, `game/progression/`); enemy levels follow it
  through `design.enemy-level`. Still open: see Progression below.
- [ ] Race, gender, class, spec, appearance: player is always `human` / capsule
  (`player-character` creation, `races.json#_creation`, D8 skin colour).
- [ ] Rebinding UI + persistence (S: remappable, saved) — `input_map.gd` builds defaults only
  (`input-binding`, `save-systems`).
- [ ] Camera: no follow smoothing/deadzone, `design.camera.shoulder-offset` unused, sniper Aim
  zoom (`ui.json#camera.aim`).
- [ ] Menu: the `menu` action only toggles mouse capture; no pause/options screen (`option`).
- [x] HP/stamina/combo/land/coins/level+xp HUD (code-built `hud.gd`); still missing: portrait, MP, minimap,
  damage numbers, enemy name colours + stars, buff icons (`hud-element`, `ui.json`).

## Creatures (§3.2 creature + ai-behavior, slice pending)
- [x] Basic melee attack both ways, death, neutral retaliation (combat slice). Still missing: aggro
  table, taunt, stun, group aggro, potions at low HP, enemy combos, ranged/mage roles
  (`ai-behavior`, `creature.combat-role`).
- [ ] Steering is straight-line: no A* with climbing (`ai-behavior.pathfinding`); creatures
  stall on cliffs > 1 block.
- [ ] Capsules coloured by hostility until species models exist (`appearance`, `.cub` models →
  `create-game-assets`); `design.spawns.size-by-category` is the placeholder scale.
- [ ] Spawns ignore `creature.habitats` (caves, rivers, dungeons) and the `caves` / `pyramids` /
  `forest-dungeon-rosters` tables; only `landscape-rosters` are used.
- [ ] Humanoid spawns get no class/spec/equipment/appearance (`gen-spawns.humanoid-class`,
  `gen-npc-appearance`); alpha `+1..+4` multipliers; boss-ification (`gen-boss`); farm animals
  near settlements; night lanterns; midnight reset; possession (S).
- [ ] `creature-families.json` has no `hp-mult` yet (`design.enemy-hp.family-mult` defaults to 1).
- [ ] Creatures never despawn except with their zone; no per-zone spawn cap or respawn timer.
- [ ] Creatures beyond `design.spawns.ai.sim-radius` (80 blocks, D16) are frozen mid-state, not LOD-ed: no
  slow tick, no catch-up when they wake. Zone colliders are still trimeshes (`ConcavePolygonShape3D`); a
  `HeightMapShape3D` would cut the per-body cost if the radius ever grows — `creature.gd`, `world.gd`.
- [ ] Creatures spawned outside `sim-radius` sit 1 block above ground until they wake, then drop
  (`gen-spawns` positions = ground + 1) — settle them on spawn or snap on wake, `spawner.gd`.
- [ ] `sim-radius` measures distance to `creature.target` (the player, or the last attacker); with
  `multiplayer-mode` it must be the nearest player — `creature.gd`.

## Meta / tooling
- [ ] Save-data (§3.7): nothing persists (world seed, character, discovered lands).
- [ ] Dedicated server (D5, `multiplayer-mode`): single-player only; `server.cfg` flags (pvp,
  player cap, level band X/Y) unread.
- [ ] Export templates missing from `flake.nix`: CI downloads its own
  (`.github/workflows/release.yml`), so only a *local* `--export-release` is blocked — add
  `godot_4-export-templates-bin` if that is ever wanted.
- [ ] Visual checks are manual (`--write-movie`); no reference-frame comparison in CI.
- [ ] Runtime profiling overlay (D17, `hud-element` debug-menu): add the Godot Debug Menu add-on
  (`addons/debug_menu`, MIT, Asset Library "Debug Menu"), map `keybinds.json#hybrid.debug-menu` (F3) to its
  `cycle_debug_menu` action in `input_map.gd`, keep it in release exports. It shows GPU + driver, so it also
  answers the untested XWayland-vs-native-Wayland question; `monitors/godot_threads.sh` becomes dev/CI only.
- [ ] `design.frame-budget` (D17) is not consumed yet: set `Engine.max_physics_steps_per_frame` and
  `Engine.physics_ticks_per_second` from it in `main.gd` (`c-frame-budget`).
- [ ] ~30 single-source `?` facts in `ontology/instances` wait for playtesting (see §7).

## Items (§3.4, slice abaded3)
- [ ] Loot only from open-world kills: no dungeon chests, mission rewards, NPC weapon drops, leftovers,
  boss spirit cubes (`loot-rule`); species drops without an `ingredients.json` row (popcorn, jellies) are skipped.
- [ ] Ground items: coloured cubes, no item mesh; auto-pickup only coins; no middle-click drop for trading;
  lifetime is real seconds (`design.loot.ground.lifetime-s`), not tied to `game-clock`.
- [ ] Inventory panel: one list, no tabs / tooltips / drag / star rating (`screens.inventory`, `item-tooltip`);
  no class check on equip (red names), no quick-select wheel (Q takes the first consumable, instant, no sit/channel).
- [x] Shops (D22, `items/shop.gd`): weapon / armor / item vendors, `design.prices` buy + sell. Still open (`shop.gd` ponytail): stock
  never restocks (`c-midnight-reset`) and is re-rolled at the current level on every open; no gnome rarity unlocks, buy-back tab,
  identifier, adapter, gem trader; the shop panel was not visually checked.
- [ ] No crafting, customization bench.

## Progression (§3.5, slice D19)
- [x] Skill tree (D20, `game/progression/skill_tree.gd`, `skill_panel.gd` on X): spending, unlock rule, per-point multipliers.
  Class actives have runtimes since D21 (see Combat). Still open: shared skills other than Swimming do nothing until pets,
  mounts, climbing, glider and boat exist; spec change at the trainer (`npc-role` class-trainer, A fee) and the panel is a flat list
  (no columns drawn, no tooltips) and was not visually checked.
- [ ] Level-up has no feedback beyond the HUD line: no sound, flash or "level up" toast (`game-feel`, `audio.json`).
- [ ] The HUD level/xp line was not visually checked (windowed viewport capture, see HANDOFF gotchas).
- [ ] `power-gate` unread: any item level equips; no adaptation, no `+N` display.
- [ ] XP only from open-world kills by the last attacker; no mission / boss XP, no party share, no pet XP
  (`pet-xp` flag), no message-log "+N xp" toast (`hud-element` message-log).
- [ ] HUD shows level/xp as a text line; the portrait (head, name, class) is still missing (`hud-element` portrait).

## Settlements (§3.1 settlement, slice D22)
- [ ] Inn: heals and moves the respawn point only; no sleep-to-07:00 (no `game-clock`), no daily mission re-roll (S).
- [ ] NPCs never talk (`npc-role.dialogue`, speech bubbles); E resolves the service instantly.
- [ ] Villagers and animals inside town are absent, so `c-hostile-in-city` only keeps wild spawns 40 blocks away.

## Combat (§3.3, slices 457c947 + D21)
- [x] Class abilities (D21, `game/combat/abilities.gd`): every tree node runs a dash / channel / burst / buff / heal with
  `design.abilities` numbers, MP gain per hit / mage regen, M2 charged / instant special, stun / knockdown / knockback /
  burning / slow on creatures, HUD MP bar + hotbar cooldown line. Still open (`abilities.gd` ponytail): fire-missiles,
  bubbles, shuriken-attack are self-centred bursts (no projectiles); shadow-shooter is a damage buff (no clone); quicksand
  is a one-shot slow burst (no zone); aim, sneak, camouflage, ninjutsu are damage / speed buffs (no `stealth` bar, no prone
  zoom); heroic-shout taunts by a 0-damage hit (no aggro table); teleport is a 20-block dash (sources say ~60 `?`);
  cyclone has no block; no cast interruption; creatures never apply statuses to the player; no dodge (`c-dodge-cost`),
  block / block-power (`block`), or stun stars / buff icons on the HUD (`ui.json#hud.stun-stars|buff-icons`); every D21
  line was not visually checked (windowed capture, HANDOFF gotchas); every D21 number is untuned.
- [ ] Hit test is a sphere in front of the camera yaw; no weapon movesets, hit timing, or
  ranged/projectile weapons (`weapon-type.m1/m2`; bow, staff, boomerang).
- [x] Item instances, equipment slots, armor stat (D18, `game/items/`). Still open: the modifier roll only
  seeds the name — stats.json gives no roll term for damage/armor; gear hp/regen/tempo/crit are not
  applied (`gen-item-stats`; the hp roll term `2 − 8r` goes negative as written, `?`), rings/amulets
  never drop, no upgrade cubes (`item.upgrades`, `c-cube-cap`), no `+` items.
- [ ] Combo only adds damage; armor piercing per combo and the per-weapon cap colours are missing
  (`combo-system`).
- [ ] Death: player respawns at the spawn point after 2 s; no revival statue / shrine, no enemy HP
  reset, no death screen; creatures drop loot (D18) and XP (D19) but no spirit cubes or corpse (`death`).
- [ ] Game feel: hit flash only; no hit-stop, shake, knockback, damage numbers, sounds
  (`game-feel`, `audio.json`).
- [ ] Status effects (`status-effects.json`) not applied by anything.
