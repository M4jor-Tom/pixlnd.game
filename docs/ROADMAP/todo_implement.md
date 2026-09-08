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
- [ ] Flora, deposits, settlements, dungeons, POIs, missions (`gen-flora`, `gen-settlement`,
  `gen-dungeon`, `gen-poi`, `gen-missions`) — not started; lands are empty terrain.
- [ ] Land caption, temperature/humidity HUD (`design.climate.hud`) not shown (`hud-element`).

## Player (§3.2 player-character, slice e33c991)
- [ ] Spawn = centre of land (0,0) (`main.gd` ponytail). `world.spawn-rule` = near a village;
  needs settlements. Default seed 26879 spawns in deadlands.
- [ ] Climb (E grab, wall-jump), dodge roll, glider, swim breath/drowning (`abilities.json`
  movement kind; `flags.drowning`, `diving-breath`) — `player.gd` ponytail.
- [x] Fall damage (D13 numbers) — applied on landing since the combat slice; dodge does not yet negate it.
- [ ] `player.level` is a constant 1: `level-formula`, XP, skill points (`skill-tree`) not started;
  enemy levels therefore sit in the 1..6 band.
- [ ] Race, gender, class, spec, appearance: player is always `human` / capsule
  (`player-character` creation, `races.json#_creation`, D8 skin colour).
- [ ] Rebinding UI + persistence (S: remappable, saved) — `input_map.gd` builds defaults only
  (`input-binding`, `save-systems`).
- [ ] Camera: no follow smoothing/deadzone, `design.camera.shoulder-offset` unused, sniper Aim
  zoom (`ui.json#camera.aim`).
- [ ] Menu: the `menu` action only toggles mouse capture; no pause/options screen (`option`).
- [x] HP/stamina/combo/land HUD (code-built `hud.gd`); still missing: portrait, XP, MP, minimap,
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

## Meta / tooling
- [ ] Save-data (§3.7): nothing persists (world seed, character, discovered lands).
- [ ] Dedicated server (D5, `multiplayer-mode`): single-player only; `server.cfg` flags (pvp,
  player cap, level band X/Y) unread.
- [ ] Export templates missing from `flake.nix` (ponytail comment) — add when `godot-export` runs.
- [ ] Visual checks are manual (`--write-movie`); no reference-frame comparison in CI.
- [ ] ~30 single-source `?` facts in `ontology/instances` wait for playtesting (see §7).

## Combat (§3.3, slice pending)
- [ ] Only `basic-attack` exists: no special attack / charge, block + block-power, dodge i-frames,
  stealth bar, MP gain and spending, class abilities, ultimates (`ability`, `special-attack`,
  `block`, `dodge`, `stealth`, `c-mp-range`, `c-dodge-cost`).
- [ ] Hit test is a sphere in front of the camera yaw; no weapon movesets, hit timing, or
  ranged/projectile weapons (`weapon-type.m1/m2`; bow, staff, boomerang).
- [ ] Item modifier roll (0..20) ignored in `combat.gd` damage; no item instances, equipment
  slots or armor stat on anyone (`item`, `equipment-slot`, `gen-item-stats`).
- [ ] Combo only adds damage; armor piercing per combo and the per-weapon cap colours are missing
  (`combo-system`).
- [ ] Death: player respawns at the spawn point after 2 s; no revival statue / shrine, no enemy HP
  reset, no death screen; creatures vanish (no loot, XP, spirit cubes, corpse) (`death`, `gen-loot`).
- [ ] Game feel: hit flash only; no hit-stop, shake, knockback, damage numbers, sounds
  (`game-feel`, `audio.json`).
- [ ] Status effects (`status-effects.json`) not applied by anything.
