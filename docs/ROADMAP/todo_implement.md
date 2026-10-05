# TODO — implementation work postponed by shipped slices

Every slice ships the lazy version and lists here what it skipped. Each line names the ontology
class or generator that governs it (`domain.md`) and, where one exists, the `ponytail:` comment in
code. Pick an item → sync rule (ontology first) → `router`. Not listed: §3 sections no slice has
started yet (see the folder table in `game/README.md`) and the `Ω`/`X` themes in this folder.

Status reconciled 2026-09-17. Resolve the affected open question in `todo_decide.md §E` before
implementation; an approved policy is not implementation authorization. Historical A/S descriptions
are not automatically hybrid targets. D4 exclusions (regional gear power loss, `+` items and worn
degradation) are not backlog features.

Owner clarification (2026-09-28, validation mapping item 4): the game is undeployed and no player
data exists to migrate. Require current rules directly (`domain.md §0/§5`); data-correction debt
below means replacing checked-in stale definitions when authorized, never migration code,
legacy-read fallbacks or obsolete-format compatibility. Implementation remains unauthorized.

**Current attribution checkpoint (2026-10-05):** 53/54 approved without amendments; 53
recorded, 54 recording pending, both awaiting post-recording independent review/final receipts.
Queue/status: `docs/todo_handle_reconciled_items.md` / `todo_decide.md §E`; canonical: `domain.md §5` / §7.
Silk/Spinning Wheel quantities stay HOLD, not refusal or new 27/36 ballots; other histories remain
research. No new implementation authority or whole-topic completion.

## World (§3.1, slice 475e72b)
- [ ] World/reset item 1 (`domain.md#world`, `c-world-bounds`, `gen-world`): enforce the approved
  finite 1024×1024-land grid, coordinates −512..511 on each horizontal axis, without wrapping.
  Current terrain generation/streaming is unbounded; live `world-scales.invariants` still says
  “no borders”. Direct data correction, checker and generation/runtime enforcement remain unauthorized.
- [ ] World/reset item 2 (`domain.md#world`, `c-world-bounds`): mark the outer boundary on the
  map and block outward travel including flight/teleport destinations; allow turning back, with
  no special damage/death/forced teleport. Map/travel enforcement is deferred.
- [ ] World/reset item 3 (`domain.md#game-clock`, `c-midnight-reset`): daily return of defeated
  ordinary-dungeon/repeatable-daily enemies including bosses; completed one-time guards/boss stay
  cleared, artifact/book claims never renew, world improvements keep their existing reset rules.
  Clock/dungeon/mission/save enforcement, direct data correction and checker work remain unauthorized.
- [ ] World/reset item 4 (`domain.md#game-clock`, `c-midnight-reset`): defer occupied dungeon/quest
  refresh until all players leave; coalesce missed midnights into one refresh using item 3's
  eligibility. No clock-triggered healing/replacement of survivors or ongoing-fight wipe; preserve
  threat/home-return rules and fresh genuine respawns. Occupancy/reset enforcement is unauthorized.
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
  animals, schedules (`gen-schedule`), lanterns, dens / sewers, watchtowers; the village node floats until its zones load;
  not visually checked beyond `--write-movie`. S settlements are hidden until discovered (reference).
  One settlement per land is the final hybrid target (item 1, §E), not backlog.
- [ ] Flora, deposits, dungeons, POIs, missions (`gen-flora`, `gen-dungeon`, `gen-poi`, `gen-missions`) — not started.
- [ ] Temperature/humidity HUD (`design.climate.hud`) not shown; the land/village caption already runs (`hud-element`).

## Player (§3.2 player-character, slice e33c991)
- [x] Spawn = the (0,0) village square (`world.spawn-rule`, D22). Default seed 26879 spawns in deadlands (undead village).
- [ ] Climb (E grab, wall-jump), glider, swim breath/drowning (`abilities.json` movement kind;
  `flags.drowning`, `diving-breath`) — `player.gd` ponytail. Approved traversal gates/debt are below.
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

## Traversal (approved documentation, implementation unauthorized)
- [ ] Riding item 1 (`domain.md#pet`, `c-riding`): enforce 5 Pet Master + ≥1 Riding point,
  global Reins and a rideable tamed pet; retain further-point speed benefits. Live-data and
  runtime changes are deferred; no new species permission, Reins route or slot is approved.
- [ ] Gliding item 2 (`domain.md#skill-tree`, `c-gliding`): 5 Climbing + ≥1 Hang Gliding point
  and a vendor-bought Hang Glider equipped in `special`; further points improve speed.
  Purchase alone does not unlock flight. Vendor/data/slot/runtime enforcement remains deferred.
- [ ] Sailing item 3 (`domain.md#skill-tree`, `c-sailing`): 5 Swimming + ≥1 Sailing point
  and a vendor-bought Boat equipped instead of the glider in `special`; further points improve
  speed. Vendor/data/slot/runtime enforcement remains deferred; no dual equip or new slot.
- [ ] Climbing item 4 (`domain.md#key-item`, `#skill-tree`, `c-climbing`): basic climbing without
  points/Spikes, skill drain reduction, global Spikes reducing consumption by 75%, not the S
  infinite-endurance behavior. Live data/runtime remain unchanged; do not infer a skill
  reduction curve/floor from the percentage.
- [ ] Climbing item 5 (`domain.md#key-item`, `c-climbing`): apply Spikes to the remaining
  skill-adjusted cost (×0.25), never additive percentage points. No artifact-combination rule
  or skill reduction curve/floor is chosen; implementation remains separately unauthorized.

## Creatures (§3.2 creature + ai-behavior, D14 + D26)
- [x] Basic melee attack both ways, death, neutral retaliation (combat slice); ranged / mage roles shooting back
  (D26, `design.creature-roles`). Heroic Shout currently provokes/retargets by a zero-damage hit.
  Still missing: aggro table, timed taunt priority, group aggro, potions at low HP, enemy combos
  (`ai-behavior`, `creature.combat-role`); all fourteen approved aggro items are recorded in §E.
  All approved aggro policies remain deferred implementation, not permission to change live JSON.
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
- [ ] Creature-family implementation is deferred pending separate authorization (`domain.md#creature-family`,
  family items 1–9 in §E). Live JSON still gives Skeleton Dog primary `skeletons`, not approved `dogs`;
  the 25 missing assignments, descriptive memberships and constraint support await direct data correction
  and model/loader/validator work. No runtime family scaling or family `hp-mult` data exists (`design.enemy-hp.family-mult`
  defaults to 1). No new numerical stat modifier is approved. Skeleton Dog's 1% dog-relative encounter
  chance is independent per individual dog wherever dogs already spawn, permitting mixed packs and
  preserving settlement safety. Item 7 selects Collie for ordinary outcomes in existing skeleton-only
  dog encounters, preserving dog frequency/pack sizes, and makes Skeleton Dog non-aggressive and
  tameable. Item 8 specifies normal dog behavior, including ordinary retaliation/pack/taming reactions,
  not a Skeleton-Dog-only passivity exemption. Item 9 shares Bubble Gum with Collie while retaining
  subtype 19 from Collie, not assigning Skeleton Dog that ID. Live rosters/traits and single-species
  `pet-food.tames` remain unchanged; shared-food model/loader/validator support awaits authorization.
  No runtime work, riding permission or extra unrestricted skeletal spawns is authorized here.
- [ ] Creatures never despawn except with their zone; no per-zone spawn cap or respawn timer.
  Zone-owned nodes currently disappear on unload; preserving logical threat/order across temporary
  unload/disconnect is approved but unimplemented (`domain.md#ai-behavior`, Aggro 11 in §E).
  Persistence item 9 additionally retains surviving-mob threat/order/provocation across restart.
- [ ] Creatures beyond `design.spawns.ai.sim-radius` (80 blocks, D16) are frozen mid-state, not LOD-ed: no
  slow tick, no catch-up when they wake. Elapsed-gameplay-time threat decay / taunt expiry is
  approved but unimplemented (Aggro 12 in §E); movement/attacks stay frozen and other status timers
  are outside that approval. Zone colliders are still trimeshes (`ConcavePolygonShape3D`); a
  `HeightMapShape3D` would cut the per-body cost if the radius ever grows — `creature.gd`, `world.gd`.
- [ ] Creatures spawned outside `sim-radius` sit 1 block above ground until they wake, then drop
  (`gen-spawns` positions = ground + 1) — settle them on spawn or snap on wake, `spawner.gd`.
- [ ] `sim-radius` measures distance to `creature.target` (the player, or the last attacker); with
  `multiplayer-mode` it must be the nearest player — `creature.gd`.

## Persistence / authority (approved documentation, implementation unauthorized)

Canonical rules: `domain.md#save-data`, `#multiplayer-mode`, `#game-clock`, `#ai-behavior`.
No save/network implementation exists; current `main.gd` creates a new hero and starting kit.
- [ ] Item 1 — portable character progression, possessions and pets including progression (`save-data`).
- [ ] Item 2 — per-character/world position, respawn, travel and lore; separate saved-world identity from seed (`save-data`).
- [ ] Item 3 — world-shared terrain exploration, distinct from personal shrine/flight/lore unlocks (`world.discovered-zones`).
- [ ] Item 4 — persist world-shared supplier/barrier/village-curse changes under existing reset rules (`save-data`).
- [ ] Item 5 — personal artifact/one-time-book source claims per saved world (`c-permanent-source-claim`), preserving duplicate recipes and ordinary loot.
- [ ] Item 6 — server validation of action requests and authoritative gameplay outcomes (`multiplayer-mode`), not Alpha client trust.
- [ ] Item 7 — rule-valid trusted-co-op imports; explain rejection without modifying the original save (`multiplayer-mode`); no provenance guarantee.
- [ ] Item 8 — save/resume world time without downtime advance or catch-up; running empty servers keep approved timers, not full distant AI (`game-clock`).
- [ ] Item 9 — surviving logical-mob threat/order/provocation across restart; preserve normal resets and taunt termination (`ai-behavior`, `c-threat-pair`).

## Validation contract (documentation approved; implementation unauthorized)
- [ ] Source item 32 (`domain.md#pet-food`): the daily stocked-type report selects no purchase
  quantity or source-build attribution; daily amounts/food histories remain research. No stock,
  purchase or carrying rule changes, label inference or data/checker/runtime work authorized.
- [ ] Source item 33 (`domain.md §5`): Slime “Mountain Areas”/colour reports establish no
  named-Mountains scope, numerical rarity, universal colour distribution or release history;
  no encounters, family/roster declarations or source labels change.
- [ ] Source item 34 (`domain.md §5`): individual Runner habitat reports date no memberships
  or taming; Desert-only exclusivity does not extend to Snow/Leaf/family. No species or foods move.
- [ ] Source item 35 (`domain.md §5`): UI placement disagreement remains unresolved, not a
  HUD move; approximate messages select no exact cap, historical keys preserve Assassin’s exception.
  No screenshot/build verification, release ancestry or interface/control changes.
- [ ] Mapping item 1 (`domain.md §5`): taxonomy/style ID, shape and reference checks without
  invented source tags; preserve embedded historical facts and separately scoped rosters/buildings.
  Direct data correction and model/loader/validator changes await separate authorization.
- [ ] Mapping/source items 2/6/12–14/16/30–31 (`domain.md#pet-food`): finish individual food release histories
  beyond pinned cuwo names, conflicting/blank Koala reports, S-food pairs and the current
  Alpha-focused Kotaku guide's wiki-credited pairs (not an authenticated 2013 list); first
  obtainability, working original-build taming and Leaf/Candy chronology stay unresolved.
  Leaf 10086's unidentified-version unobtainability/cheat-acquisition report does not establish
  cheat-fed taming or date either bait; Candy stays Koala's bait and Leaf stays cut.
  Data correction and model/loader/validator work need separate authorization.
  Current A+S fallback is not evidence; shared-food pairings and source IDs remain unchanged.
- [ ] Mapping item 3 (`domain.md §5`): preserve qualified reference annotations in later
  model/loader/validator handling; current parsing strips `?`. No schema or parser change is
  authorized now, nor content selection or a decision on Swamp Lands identity.
- [ ] Mapping item 4 (`domain.md §5`): implement the recorded required-path/shape, bounded
  source-inheritance and layer-specific checks when separately authorized, including missing-whole-input
  negatives and cumulative errors. Require current artifact log config directly; no old decay/floor
  alternative. Source items 7–9/17 record bounded mixed-container/patch/encounter reports, not whole-file labels;
  per-membership fauna histories and other embedded traits remain research (§E), not roster corrections.
  Item 18 attributes cotton quantities only; noncotton/weapon quantities and refining yields/ratios stay open.
  Item 19 does not complete stock/loot/probability or daily pet-food-amount research or change economy rules.
  Item 20 leaves original population censuses, undead exceptions, animal composition and accumulation cause open.
  Item 21 leaves shipped A*/daily routes/nightly lanterns and literal dialogue histories open; no hint rewards.
  No fauna history from landscape versions or invented tags/schemas/compatibility.
- [ ] Source item 15 (`domain.md §5`): three dated community-wiki UI patch reports do not
  complete UI/camera/static/candle/furniture/audio/dialogue histories or authorize interface work.
  Historical `+` equipment and regional gear power loss stay excluded; other research remains open.
- [ ] Source item 28 (`domain.md §5`): Golem/Troll named-species reports establish no
  family/boss-wide trait inheritance or confirmed original Alpha/Steam histories. Habitat/other
  traits remain research; no attacks, scaling, encounters or new behavior implementation authorized.
- [ ] Source item 27 (`domain.md §5`): qualitative refining chains establish no yields/ratios,
  input/output counts or original Alpha/Steam recipes; current input 1 values are not verified
  history. Silk-station history remains research; no recipe/station change or new quantity default.
- [ ] Source item 22 (`domain.md §5`): prefix-list attribution does not resolve exact possessive-name
  or original-prefix generation/release histories; keep the always-named Epic/Legendary guarantee.
  No names, naming frequency, prefixes or label changes are authorized.
- [ ] Source item 24 (`domain.md §5`): candle release/pickup/activation histories remain research;
  appearance/placement reports prove no exclusive locations and authorize no lighting/placement changes.
- [ ] Source item 25 (`domain.md §5`): campsite furniture/release histories remain research;
  no mandatory contents, exact stool/bench IDs, sitting-heal effect or cooking behavior selected.
- [ ] Source items 10–11/23/26/29 (`domain.md §5`): original Alpha/Steam furniture-sleep activation,
  healing, rate and baseline/units remain research. Pinned cuwo normal-clock code/definition-only
  sleep constant, community Sleep/Bedroll reports, archived 2013 Camp Bed and early Sleep 4042's
  paired approximate intervals do not resolve them; documentary timing is not introduction or
  demonstrated behavior. Retain “Requires Testing”
  and ambiguous inn wording; no inferred controls, healing/rate, bench/stool rule or hybrid inn change.

- Source item 53 (`domain.md §5`): generic arrow firing and Bows/Crossbows > Boomerangs report gives no numerical ranges, edition or first appearance. Unlimited arrows, MP costs, tags and D24 movesets stand; no new ammunition/range implementation debt is selected.

- Source item 36 (`domain.md §5`): cobweb/Spinning Wheel report names no output or counts; item 27's silk chain stands. Original recipes/yields remain research; no station or recipe change.

- Source item 37 (`domain.md#pet-food`): reported Lollipop/Emerald acquisition establishes no odds, first appearance or successful taming; Owl pairing stays, Lolly is distinct. No loot change.

- Source item 38 (`domain.md#pet-food`): candy identity, daily quantities and food histories stay research; six reported names are not universal/exhaustive stock. One-coin flask price selects no food prices.

- Source item 39 (`domain.md §5`): named Snout dodge/Intuition reports grant no exclusivity, family inheritance or new attacks. Charged-shot model-growth bug is historical only: **do not implement it**.

- Source item 40 (`domain.md §5`): Undead village report is not exclusive towns/census; cities-thread faction/Undead reply is speculation, with no tested build or biome exception. Populations/Skeleton Dog stand.

- Source item 41 (`domain.md §5`): some mobs bringing out lanterns gives no universal nightly schedule, activation/put-away timing or A* route. Shipped schedule/lantern histories remain research; no lighting change.

- Source item 42 (`domain.md §5`): individual dark-Alpaca list proves no exclusivity, new plains biome or whole-family Desert distribution. Per-membership history stays research; habitats/foods unchanged.

- Source item 43 (`domain.md §5`): three possessive examples recover no generation algorithm or release history. Preserve legendary/Exceptional disagreement, historical + spelling only and always-named guarantee; no naming change.

- Source item 44 (`domain.md §5`): retrieved 28-title catalog does not authenticate shipped soundtrack/completeness or Dungeon–Bgum/Maintheme–Explorers/Ocean–2017 identities. Audio histories remain research; declarations/assets/playback unchanged.

- Source item 45 (`domain.md §5`): vendor stock report keeps sometimes/unnamed treat; no universal stock, price, quantity or chronology, and no sugar-cube/candy mapping. Shop rules unchanged; stock histories remain research.

- Source item 46 (`domain.md §5`): questionable conversion report confirms neither exactly one nor 1–3 Heartflowers. Quantities/original-build behavior stay research; conversion unchanged.

- Source item 47 (`domain.md §5`): Deposit's 1–3 nuggets does not verify every gem, Ice Crystal or Sandstone yield. Per-kind counts/odds remain research; mining unchanged.

- Source item 48 (`domain.md §5`): Iron Cube/non-common gem report supplies no quantities/station or cotton-to-iron proof. Noncotton recipe histories stay research; hybrid recipes unchanged.

- Source item 49 (`domain.md §5`): Cotton Yarn/Iron Cube report verifies no current 2+5 bill, station or release history. Recipe gaps remain research; costs/materials unchanged.

- Source item 50 (`domain.md §5`): individual habitat/no-adult-grouping report proves no pack counts or Baby Elephant rule. Encounter histories stay research; no spawn change authorized.

- Source item 51 (`domain.md §5`): rapid swiping is attack-qualified/qualitative, not verified audio or unconditional ambience. Audio histories stay research; other Wraith traits unchanged.

- Source item 52 (`domain.md §5`): reported Steam absence supplies no census/first Alpha appearance or hybrid removal. Species histories remain research; roster/food/mount rules unchanged.

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
- [ ] Wand item 1 (`domain.md#weapon-type`, `c-hands`): correct provisional checked-in handedness to
  2H and the common recipe from 10 to 20 wood cubes; enforce no other hand item and the existing
  32-cube limit, preserving damage/attacks and rarity gems. Equipment/crafting/customization and
  validation coverage require separate authorization; no live data or runtime changed.
- [ ] Books/formulas item 1 (`domain.md#book-of-crafting`, `c-book-recipe-persistence`): persist
  book-learned recipes with the character across lands/sessions, without relearning on travel.
  Direct data correction and crafting/save-data implementation remain unauthorized; cross-world
  portability now follows persistence item 1 (`save-data`).
- [ ] Books/formulas item 2 (`domain.md#recipe`, `c-recipe-learning`): shared character recipe
  collection; books teach only unknown recipes without rerolls/compensation; known formula
  scrolls remain unconsumed. Data/learning/UI enforcement awaits separate authorization.
- [ ] Books/formulas item 3 (`domain.md#power-gate`, `c-power-gate`): record book recipes
  immediately but display/enforce above-power crafting locks until requirements are reached;
  preserve formula learning's power requirement. Known-but-locked duplicates grant no bypass
  or compensation and leave known formula scrolls unconsumed. Runtime/UI/data work is unauthorized.

## Progression (§3.5, slice D19)
- [ ] Assassin item 1 (`domain.md#skill-tree`, `c-tree-shape`): clarify live `also-ultimate`
  metadata and add validation coverage for the approved single rank-3 Camouflage exception
  when separately authorized. Current key-3/no-key-4 runtime already matches; no fourth-node,
  alternate-key or duplicate-cast implementation is requested. JSON/tests/validator unchanged.
- [ ] Artifact items 1–6 (`domain.md#artifact`, `c-artifact-stat`): implement the approved
  logarithmic total (initial z=0.1), equal additive shares and current artifact-free stat basis;
  matching-only traversal counts versus all-artifact attack/maximum-HP counts. No artifact levels,
  traversal-gate bypass, old decay/floor, replacement clamp or extension to ordinary gear.
  Live `generators.json#design.artifact`, `key-items.json#artifact` and hybrid `rulesets.json`
  wording still carry old D6 policy; replace directly only with separate authorization. Model/loader/
  validator support, generated rewards and runtime recalculation remain deferred and unauthorized.
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
- [ ] Item 1's exact-one-settlement target (`domain.md#settlement`): correct the conflicting hybrid
  `settlements-per-land: "many"` flag and enforce the exact count; current config is 1 but validation
  allows ≥1 and placement can fail on all-sea land. No live-data, validator or generation changes authorized.
- [ ] Inn item 2 (`domain.md#game-clock`): implement separate paid timed sleep, preserving free recovery.
  Runtime has no clock/skip; the hybrid `inn-cost` flag lacks the service distinction.
  Direct data correction and implementation remain unauthorized.
- [ ] Inn item 3 (`c-midnight-reset`): apply ordinary resets once on a midnight-crossing skip,
  without sleep-specific shop refreshes/mission rerolls. S refresh records are reference, not hybrid
  targets. Cleared dungeon/quest enemy eligibility and occupied-site timing follow world/reset items 3–4 above.
- [ ] Inn item 4 (`game-clock`, `multiplayer-mode`): connected-player agreement and success-only
  initiator payment are unimplemented; free recovery needs no agreement. No vote timeout or
  disconnect protocol is specified; no networking/payment implementation authorized.
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
  (no aggro table or timed taunt implementation; approved rules in §E); Teleport is a 20-block dash (source distance unverified);
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
  The broader approved equipment-model/slot implementation remains deferred (§E item 3);
  the approved two-handed wand's data correction/enforcement is deferred under Items above.
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
