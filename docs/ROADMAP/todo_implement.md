# TODO — implementation work postponed by shipped slices

Every slice ships the lazy version and lists here what it skipped. Each line names the ontology
class or generator that governs it (`domain.md`) and, where one exists, the `ponytail:` comment in
code. Pick an item → sync rule (ontology first) → `router`. Not listed: §3 sections no slice has
started yet (see the folder table in `game/README.md`) and the `Ω`/`X` themes in this folder.

Status reconciled 2026-09-17. Resolve the affected open question in `todo_decide.md §E` before
implementation; an approved policy is not implementation authorization. Historical A/S descriptions
are not automatically hybrid targets. D4 exclusions (regional gear power loss, `+` items and worn
degradation) are not backlog features.

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
  discovered; hybrid multiplicity remains undecided in §E); the village node floats until its zones load;
  not visually checked beyond `--write-movie`.
- [ ] Flora, deposits, dungeons, POIs, missions (`gen-flora`, `gen-dungeon`, `gen-poi`, `gen-missions`) — not started.
- [ ] Temperature/humidity HUD (`design.climate.hud`) not shown; the land/village caption already runs (`hud-element`).

## Player (§3.2 player-character, slice e33c991)
- [x] Spawn = the (0,0) village square (`world.spawn-rule`, D22). Default seed 26879 spawns in deadlands (undead village).
- [ ] Climb (E grab, wall-jump), glider, swim breath/drowning (`abilities.json` movement kind;
  `flags.drowning`, `diving-breath`) — `player.gd` ponytail. Traversal prerequisites remain open in §E.
- [x] Dodge roll (D23): cost, movement, i-frames and passive rewards run; see Combat for remaining passives.
- [x] Fall damage (D13 numbers) — applied on landing; D23 clears fall tracking while rolling.
- [x] `player.level` grows: XP per kill + level-up (D19, `game/progression/`); enemy levels follow it
  through `design.enemy-level`. Still open: see Progression below.
- [ ] Character-creation UI for race, gender, class, spec and appearance: player remains a human capsule;
  `-- --class=<id>` already selects the class and its starting spec (`races.json#_creation`, D8 skin colour).
- [ ] Rebinding UI + persistence (S: remappable, saved) — `input_map.gd` builds defaults only
  (`input-binding`, `save-systems`).
- [ ] Camera: no follow smoothing/deadzone, `design.camera.shoulder-offset` unused, sniper Aim
  zoom (`ui.json#camera.aim`).
- [ ] Menu: the `menu` action only toggles mouse capture; no pause/options screen (`option`).
- [x] HP/stamina/combo/land/coins/level+xp HUD (code-built `hud.gd`); damage numbers, stun stars and buff icons
  run since D25; still missing: portrait, minimap, enemy name colours (`hud-element`, `ui.json`).

## Creatures (§3.2 creature + ai-behavior, D14 + D26)
- [x] Basic melee attack both ways, death, neutral retaliation (combat slice); ranged / mage roles shooting back
  (D26, `design.creature-roles`). Heroic Shout currently provokes/retargets by a zero-damage hit.
  Still missing: aggro table, timed taunt priority, group aggro, potions at low HP, enemy combos
  (`ai-behavior`, `creature.combat-role`); threat/taunt/group rules remain open in §E.
- [ ] A ranged / mage creature aims where the target *is*: no lead on a moving one, so strafing walks out of a
  slow mage bolt — `creature.gd#_shoot` ponytail.
- [ ] Line of sight is one head-to-head ray (`entity.gd#head`, a flat 1.5 blocks up): a wall — or a body taller
  than that — cancels the shot and the shooter never strafes for a clear angle, while a wolf or any other small
  creature is simply shot over — `creature.gd#_los` ponytail.
- [ ] A creature notices a target at `design.spawns.ai.aggro-range` (12) whatever its role; the role's `range`
  (ranged 14) only applies once it is already chasing, so the last 2 blocks never open a fight. Reconcile the two
  keys in a tuning pass (lower `range`, or give `design.spawns.ai` a role-aware aggro range).
- [ ] The wizard "staff/wand laser" and witch "ray attack" fire a bolt like every other mage: no beam role
  (`design.creature-roles` has `kind: projectile` only; `design.movesets` has the player's beam runtime).
- [ ] An `any-class` humanoid's rolled role is the whole class: no spec, weapon, armor or appearance behind it
  (`gen-spawns.humanoid-class`, `gen-npc-appearance`) — `spawner.gd#plan` ponytail.
- [ ] A creature hit ignores the player's armor (the reach bite and the shot both call `take_damage` raw, no
  `Combat.after_armor`) and can never crit — `creature.gd#_strike` ponytail.
- [ ] Steering is straight-line: no A* with climbing (`ai-behavior.pathfinding`); creatures
  stall on cliffs > 1 block.
- [ ] Capsules coloured by hostility until species models exist (`appearance`, `.cub` models →
  `create-game-assets`); `design.spawns.size-by-category` is the placeholder scale.
- [ ] Spawns ignore `creature.habitats` (caves, rivers, dungeons) and the `caves` / `pyramids` /
  `forest-dungeon-rosters` tables; only `landscape-rosters` are used.
- [ ] Alpha `+1..+4` creature multipliers; boss-ification (`gen-boss`); farm animals near settlements;
  night lanterns; midnight reset; possession (S). Humanoid identity beyond the rolled combat role is deferred above.
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
- [ ] Remaining hybrid decisions and source uncertainties: `domain.md §7` / `todo_decide.md §E`.
  D13 hitboxes and D15 armor numbers are already designed; optional fields are not unanswered facts.
- [x] Inventory, skill-tree and shop panels keep player time running while gating gameplay input
  (item 10, `44ab0a1`); other menu policies remain outside that repair.

## Items (§3.4, slice abaded3)
- [ ] Loot only from open-world kills: no dungeon chests, mission rewards, NPC weapon drops, leftovers,
  boss spirit cubes (`loot-rule`); species drops without an `ingredients.json` row (popcorn, jellies) are skipped.
- [ ] Ground items: coloured cubes, no item mesh; auto-pickup only coins; no middle-click drop for trading;
  lifetime is real seconds (`design.loot.ground.lifetime-s`), not tied to `game-clock`.
- [ ] Inventory panel: one list, no tabs / tooltips / drag / star rating (`screens.inventory`, `item-tooltip`);
  no class check on equip (red names), no quick-select wheel (Q takes the first consumable, instant, no sit/channel).
- [x] Shops (D22, `items/shop.gd`): weapon / armor / item vendors, `design.prices` buy + sell. Still open (`shop.gd` ponytail): stock
  never restocks (`c-midnight-reset`) and is re-rolled at the current level on every open; no gnome rarity unlocks, buy-back tab,
  identifier, adapter, gem trader. Item 10's native panel capture checks rendering with empty stock;
  the full vendor/stock/trade flow is not visually verified.
- [ ] No crafting, customization bench.

## Progression (§3.5, slice D19)
- [x] Skill tree (D20, `game/progression/skill_tree.gd`, `skill_panel.gd` on X): spending, unlock rule, per-point multipliers.
  Class actives have runtimes since D21 (see Combat). Still open: shared skills other than Swimming do nothing until pets,
  mounts, climbing, glider and boat exist; spec change at the trainer (`npc-role` class-trainer, A fee) and the panel is a flat list
  (no columns drawn, no tooltips). Its native rendering was checked in item 10; narrow-window clipping remains.
- [x] Level-up plays its `design.feel` bundle (D25): the popping "LEVEL UP!" toast, camera trauma and a
  synthesised sound. Still open: no flash / particles, and no real audio asset (`audio.json`).
- [ ] HUD level/xp progression transitions still need visual checks; the static level/xp line is visible
  in item 10's windowed combo captures (see HANDOFF gotchas).
- [ ] `power-gate` unread: any item level equips; no adaptation, no `+N` display.
- [ ] XP only from open-world kills by the last attacker; no mission / boss XP, no party share, no pet XP
  (`pet-xp` flag), no message-log "+N xp" toast (`hud-element` message-log).
- [ ] HUD shows level/xp as a text line; the portrait (head, name, class) is still missing (`hud-element` portrait).

## Settlements (§3.1 settlement, slice D22)
- [ ] Inn: heals and moves the respawn point only; no sleep-to-07:00 (no `game-clock`), no daily mission re-roll (S).
- [ ] NPCs never talk (`npc-role.dialogue`, speech bubbles); E resolves the service instantly.
- [ ] Villagers and animals inside town are absent, so `c-hostile-in-city` only keeps wild spawns 40 blocks away.

## Combat (§3.3, slices 457c947 + D21 + D23)
- [x] Defence (D23, `player.gd` + `creature.gd` from `design.defence`): M3 dodge roll with i-frames and per-passive rewards,
  M2-held block (shield / guardian / cyclone) with block-power + MP, the stealth bar (sneak / aim fill, camouflage pins,
  decay, attack / crit / MP bonus, aggro range cut), creature hits rolling stun / knockback on the player.
  A spitter's poison application (D26) and scheduled ticks (item 10 repair, 2026-09-17) bypass dodge;
  ordinary hits and burning retain their existing dodge behavior. Still open: the ninja crit window (`elusiveness`),
  counter-strike and hit-series passives do nothing; stealth ignores darkness / lamps (no game clock);
  knockback fade is a constant (`player.gd#PUSH_DECAY`);
  nothing visually checked; every D23 number is untuned.
- [x] Class abilities (D21, `game/combat/abilities.gd`): class nodes/ultimates run dash / channel / burst / buff /
  heal / projectile runtimes with `design.abilities` numbers; basic hits give MP to non-mages, mages regenerate it;
  M2 charged / instant special, status application, HUD MP and hotbar cooldown line run. Fire-missiles, bubbles and
  shuriken-attack throw projectiles (D24); Aim/Sneak fill the stealth bar and Camouflage pins it (D23), while
  Ninjutsu buffs damage/swing speed. Still open (`abilities.gd` ponytail): Shadow Shooter is a damage buff (no clone);
  Quicksand is a one-shot slow burst (no zone); no prone/aim zoom; Heroic Shout retargets by a zero-damage hit
  (no aggro table or settled taunt priority); Teleport is a 20-block dash (source distance unverified);
  no cast interruption (stun cancels only the M2 charge). Item 10's captures cover the HUD hit/miss counter and
  static hotbar, not every ability animation/effect; D21 numbers remain untuned.
- [x] Class-strike combo handling (item 10, `44ab0a1`): damaging burst/dash hits and channel ticks build combo;
  only a wholly missed damaging channel resets on normal/early end. Zero-damage taunts do not change combo
  or refresh its inactivity timer. Damage, costs, cooldowns and existing combo caps/expiry are preserved.
- [x] Movesets + projectiles (D24, `combat/projectile.gd`, `player.gd#_attack` from `design.movesets`): every class weapon-type has an M1 / M2
  runtime (melee spin / lunge / finisher, arrows with gravity, bolts, piercing returning boomerangs, staff at-cursor bursts, wand beams,
  bracelet bolts + splash ball), fire-missiles / bubbles are projectile volleys, shuriken-attack throws 5 before the backflip, dagger
  ambush poisons. Still open: no animations or hit timing (a swing is instant; the longsword lunge is a `move_and_collide` jump), the
  boomerang is not camera-steerable, wand M2 is one thick beam (not a held 10-hit ray), bow dud shots do not build combo, poison shares
  the burning slot (`entity.gd`, one of the two at a time), projectiles are coloured spheres with a fading-sphere trail and an impact
  flash (D25) but still no model or particles (creatures shoot the same projectiles since D26), the main scene picks the class only from `-- --class=<id>`, nothing visually
  checked; every D24 number is untuned.
- [x] Item instances, equipment slots, armor stat (D18, `game/items/`). Still open: the modifier roll only
  seeds the name — stats.json gives no roll term for damage/armor; gear hp/regen/tempo/crit are not
  applied (`gen-item-stats`; the hp roll term `2 − 8r` goes negative as written, `?`), rings/amulets
  never drop, no upgrade cubes (`item.upgrades`, `c-cube-cap`).
- [x] Two-handed weapon/shield conflicts are rejected atomically in either equip order (item 10).
  The broader approved equipment-model/slot implementation remains deferred (§E item 3); wand handedness is open.
- [ ] Combo only adds damage; armor piercing per combo and the per-weapon cap colours are missing
  (`combo-system`).
- [ ] Death: player respawns at the spawn point after 2 s; no revival statue / shrine, no enemy HP
  reset, no death screen; creatures drop loot (D18) and XP (D19) but no spirit cubes or corpse (`death`).
- [x] Game feel (D25, `game/combat/feel.gd` from `design.feel`): a feedback bundle per combat event — hit-stop on
  `Engine.time_scale` (up to 0.12 s on a kill), camera trauma shaking the Camera3D offsets + roll
  (`orbit_camera.gd`), a synthesised sound, floating damage numbers (crit / dot / hurt colours), impact flashes,
  projectile trails, stun stars over the head, the level-up toast pop and the HUD buff-icon row.
  Still open: **sounds are synthesised sine+noise blips** — no audio asset file exists in the repo, so every
  `audio.json#sfx-alpha-ids` id is a placeholder waveform (`feel.gd#sfx`); **no particles** — flashes, trails and
  impacts are fading spheres (`feel.gd#_sphere`); **shake / flash reduction is a design number only**
  (`design.feel.shake.shake-mult`), there is no accessibility option screen; **no hit animations or hit timing** —
  a swing still lands instantly and the feedback fires on the damage, not on a frame of an animation; **damage
  numbers are not depth-sorted** (`no_depth_test`, they draw over the world and overlap each other when several
  land at once); **buff icons are letter boxes**, no ability art, and the fill reads `left / duration-s` so a
  buff-duration multiplier makes it start above full. Dedicated visual checks of D25's effects remain;
  the recent static HUD captures do not cover them. Every D25 number is untuned.
- [ ] Remaining status coverage: taunt tint, dizzy, drowning, world/settlement effects and consumable/land buffs
  are not implemented. Stun / knockdown / knockback / burning / slow, poison (shared burning slot), class buffs,
  healing and the stealth bar already run (D21–D26). Independent poison/burning stacking remains deferred.
