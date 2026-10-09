# Cube World Rebuild — Domain Ontology (canonical layer)

Source of truth for the rebuild of **Cube World** (Picroma / Wollay). Code, data and content are
derived from this file and `instances/`. Nothing downstream may drift ahead of it.

## 0. Conventions

- Every class, relation, generator and instance has a **stable kebab-case ID**. IDs never change
  once referenced; rename the `name`, not the `id`.
- **Version tags** mark where a fact comes from, not pixlnd availability or implementation
  status. A feature may exist in several source versions; hybrid scope follows §1 and approvals.
  - `A`  Alpha 0.1.0 / 0.1.1 (July 2013)
  - `S`  Steam 0.9.x beta → 1.0.0-1 (Sept 23 – Oct 1 2019)
  - `Ω`  Cube World Omega (announced 2023-05-25, unreleased; only announced facts)
  - `X`  present in shipped data / devlog but cut, unused or never functional
- `?` after a source value marks uncertainty, including qualified version annotations such as `S?` / `A?` (§5 Validation-contract mapping item 3); §7 separates active hybrid questions from reference-only research gaps. In type notation (`int?`, `ref?`), it instead means nullable/optional, not an unanswered design question.
- Properties are split **intrinsic** (belong to the thing) vs **extrinsic** (references to other IDs).
- Runtime-generated content (terrain, dungeons, names, loot rolls, bosses) is **not** enumerated;
  its **generator** is a class (§6) and its config lives in `instances/generators.json`.
- Numeric formulas are written in plain infix. `lvl` = character level, `n` = item level.

**Undeployed-game clarification (owner, 2026-09-28):** no player data exists to migrate.
Require current approved definitions directly; obsolete checked-in values need direct replacement
when separately authorized, not save/config migrators, legacy-read fallbacks or compatibility
paths. Older “migration” deferrals in this document mean data correction/enforcement debt only,
not a migration plan. Stable source IDs and previously approved names remain unchanged.

Research dumps behind this file: `research/research_*.md` (classes/combat, items, world, creatures/quests,
systems). Primary sources: cubeworld.fandom.com, cuwo (alpha server reimplementation, exact data
layouts), CWSDK (1.0 modding SDK), coremaze stat reverse-engineering, Wollay's 2011–2013 devlog
(Wayback), picroma.com 2013, wollay.com (Omega), Steam patch notes and guides.

---

## 1. Scope

**Reference domain:** a seed-driven voxel, third-person action RPG, historically described as
“infinite” (not the hybrid bound below), with 8 races ×
4 classes × 2 specializations, procedurally generated lands (biomes, dungeons, settlements,
missions), a tame-anything pet system, crafting, and drop-in co-op. The original Cube World
shipped two rulesets with **mutually exclusive progression**; these are historical comparisons,
not additional playable modes in pixlnd. The chosen hybrid target is listed alongside them:

| Ruleset | Progression | Gear scope | Traversal unlocks | Fast travel |
|---|---|---|---|---|
| `ruleset-alpha` (A) | XP → levels → 2 skill points/level, skill tree, item power +1..+100 | global, Adaptation re-levels gear | skill tree + bought glider/boat | portals (rune stones), revival statues |
| `ruleset-steam` (S) | no XP; level = artifacts found; gear is the only combat power | **region-locked**; `+` items work in adjacent regions | per-region key items + artifacts | shrines of life, flight masters |
| **`ruleset-hybrid` (chosen)** | alpha XP/levels/skill tree | global, never degrades | skill tree + key items (global once found) + artifacts | portals, shrines, flight masters |

Everything else (world, creatures, weapons, combat feel, crafting stations, pets, settlements) is
shared with version-specific deltas.

**Decision D1 (owner, 2026-09-07): ship `ruleset-hybrid`.** Alpha progression (XP → levels →
skill points, skill tree, item power, adaptation, spirit cubes, formulas) **plus** approved Steam
content, subject to D3/D4 and subsequent approvals (key items, artifacts, lore, arenas, factions
and events, shrines, flight masters, elixirs, gnome suppliers, books of crafting).
**Region lock is dropped** (D4): equipment never loses power
when the character travels; there are no `+` items, no `worn` degradation, no per-land inventory
pages, and key items work everywhere once found. Artifacts stay as permanent collectibles
with traversal and D6 attack/maximum-HP rewards, but do not grant character levels.
Flags in `instances/rulesets.json#ruleset-hybrid`.
Alpha/Steam rulesets remain documented for reference only.

**Permanent exclusion (owner reaffirmed 2026-09-15):** never propose or implement regional
gear power loss in pixlnd, even for Cube World cloning fidelity. This is not a v2 deferral or
an alternative mode. Historical region-lock data is reference only, never an implementation target.

**Hybrid v1 scope (item 8, owner approved 2026-09-15):** the approved hybrid above, with D1–D26
and subsequent reconciliation approvals preserved. Ontology coverage is broader than v1:
`X` cut/data-only content and `Ω`-only announcements are reference/roadmap material, not launch
availability, even if a historical flag is true. Their existing definitions and provenance remain.
**Current-build coverage:** dated slice notes and `generators.json#design` describe approved
implementation stages, including temporary approximations, not proof that the final target is
implemented. Later decisions supersede earlier placeholders. Unresolved hybrid merges remain
in `docs/ROADMAP/todo_decide.md §E`; this scope clarification
does not decide them or authorize gameplay changes.
**Out of scope:** Picroma's engine internals (Plasma GUI runtime, DX11 renderer), the exact
network byte layout of the 2013 protocol (kept as reference only), Steam platform integration,
Omega content beyond what was publicly announced.
**Roadmap, not a release promise:** cut content and Omega-only systems (weather, procedural body
parts, signature abilities per species, coarse-map-first generation) remain in `docs/ROADMAP/`
under D3/D4. Modeling them does not authorize enabling them; a later inclusion needs owner approval.

---

## 2. Competency Questions

Each must be answerable from the model + instances. Data requirement in the right column.

| # | Question | Answered by |
|---|---|---|
| CQ1 | What can the player be? (race, gender, class, spec, appearance) | `race`, `character-class`, `specialization`, `appearance` |
| CQ2 | What can the player *do* in combat, with which input, at what cost/cooldown, in which version? | `ability`, `weapon-type` (moveset), `resource`, `input-binding` |
| CQ3 | How much damage / HP / armor does an item or character have? | `stat`, `item` + `item-stat-formula` generator, `level-formula` |
| CQ4 | What exists in the world and where? (biomes → flora, fauna, structures) | `landscape`, `terrain-feature`, `creature`, `flora`, `deposit`, `dungeon-type`, `poi-type`, relations `spawns-in`, `placed-in` |
| CQ5 | How is the world laid out numerically? (block, zone, region, mission grid, seed) | `world`, `zone`, `land`, `generators.json` scales |
| CQ6 | Which creature drops / is tamed by / can be ridden / can become a boss? | `creature`, `pet-food`, relations `tamed-by`, `drops`, `boss-ification` generator |
| CQ7 | What is an item? (type, subtype, material, rarity, level, cubes, name) | `item`, `item-type`, `material`, `rarity`, `affix`, `item-name` generator |
| CQ8 | How is gear obtained, crafted, upgraded, identified, sold? | `recipe`, `crafting-station`, `shop`, `formula`, `book-of-crafting`, `leftovers`, `spirit-cube`, `adaptation` |
| CQ9 | How does the player progress, in each ruleset? | `ruleset`, `skill-tree`, `power-level`, `artifact`, `region-lock`, `lore`, `gnome-supplier` |
| CQ10 | What tasks does the world offer and what do they reward? | `mission-type`, `arena`, relations `rewards` |
| CQ11 | Who lives in settlements and what services do they give? | `settlement`, `district`, `building`, `npc-role`, `shop` |
| CQ12 | How do NPCs / enemies behave, how many aggro points does each mob hold against each player, and whom does it target? (hostility, groups, patrols, schedules, potions) | `hostility`, `ai-behavior`, `creature` fields; relations `threat`, `current-target` and relation property `aggro-points` |
| CQ13 | What status effects exist and what applies them? | `status-effect`, relation `applies` |
| CQ14 | What is the day/night cycle, what resets, how does sleep work? | `game-clock` |
| CQ15 | What persists between sessions and across worlds? | `save-data`, `world`, `player-character` |
| CQ16 | How does multiplayer work in each version? | `multiplayer-mode`, `slash-command` |
| CQ17 | What is on screen and which key does what? | `hud-element`, `input-binding`, `option` |
| CQ18 | What was in which version, and what did fans ask to fix? | `ruleset` feature flags, `instances/versions.json` |
| CQ19 | What did Omega announce, retained as roadmap/reference rather than v1 content? | `Ω`-tagged classes/fields |

---

## 3. Classes

Format per class: **id** — one-line definition. `versions`. Property table. Instances file.

### 3.1 World

### world
The single playable universe instance. `A S`
Hybrid saved-world identity is distinct from the generation seed (`save-data`, persistence item 2).

**Hybrid world/reset item 1 (owner approved, 2026-09-28):** the world is a finite square of
**1,024 × 1,024 lands (1,048,576 total)**, one land per region. Each land is **16,384 blocks
across** (D12), giving **16,777,216 blocks / roughly 16,777 km per side**. Land coordinates
run **−512 through 511 inclusive on each horizontal axis**. This is enormous but bounded,
not unlimited generation or a wrapping world. Historical “infinite” / “no borders” descriptions
do not override this hybrid limit. Boundary enforcement and live-data/checker migration remain
deferred; the current terrain streamer does not enforce the bound.

**Hybrid world/reset item 2 (owner approved, 2026-09-28; depends on item 1):** mark the
outer world boundary on the map and **prevent outward travel**, including **flight and
teleport destinations**. Players can turn back; crossing attempts cause **no special damage,
death or forced teleport**. This chooses no edge art, warning UI, biome or numerical buffer.
Map/travel enforcement remains deferred and unauthorized.

| prop | type | i/e | notes |
|---|---|---|---|
| seed | uint32 | i | A: chosen per world at creation (server default 26879); S: one fixed shared seed, no UI |
| name | string | i | A only (world list) |
| day | int | i | day counter |
| time-ms | int 0..86_400_000 | i | ms of game day |
| spawn-rule | enum `near-village` | i | S 0.9.1-3: new chars spawn near a village; A: world spawn (0,0 area); hybrid (D22): the square of the land (0,0) village |
| discovered-zones | set<zone-coord> | i | hybrid: world-shared terrain exploration (persistence item 3 below); A: shared by all visitors |
| origin-poi | `poi-type` ref | e | S: `wollays-house` at block (0,0) |
Instances: none (runtime). Config: `generators.json#world-scales`.

**Hybrid persistence item 3 (owner approved, 2026-09-28):** explored terrain belongs to
that saved world and is visible to all its visitors, including later arrivals. Seeing a place
on the shared map grants **no personal shrine activation, flight access or lore knowledge**;
those remain character/world records (`save-data`, item 2). Exploration helps the group, but
newcomers inherit the already-explored map rather than starting with a private blank map.

### zone
Terrain streaming unit (alpha "chunk"). `A S`
| prop | type | notes |
|---|---|---|
| size-blocks | int | A: 256×256; S: 64×64 (`BLOCKS_PER_ZONE = 64`); hybrid: 64 (D12, `generators.json#design.terrain`) |
| columns | `field`[] | one per (x,y); `field` = base-z + vertical run of `block` |
| static-entities | `static-entity`[] | doors, chests, furniture, stations |
| spawns | `creature` spawn list | per-zone spawn structs (hostility, type, class, spec, level, power-base, appearance, 13 items, name) |
| chunk-items | dropped `item`[] | ground items with rotation, scale, drop-time |
| retire | rule | unloaded when unvisited; dropped items vanish after ~1 game week |

### block
One voxel. `A S`
| prop | type | notes |
|---|---|---|
| type | `block-type` ref | 5-bit id, see `instances/block-types.json` |
| rgb | u8×3 | per-voxel colour, no palette |
| breakable | bool | by bombs / boss terrain damage; regenerates after ~3 game days |
Block scale: 1 block = 65536 native units (16.16 fixed). Character ≈ 2 m.

### block-type
Enumeration of voxel kinds; alpha and 1.0 tables differ. `A S` → `instances/block-types.json`.

### land
A named, bordered gameplay region of one `landscape`. What the wiki calls "region"/"land". `A S`
| prop | type | i/e | notes |
|---|---|---|---|
| name | string | i | `<Name> Plains/Hills/Mountains/…`; names not unique |
| landscape | ref | e | exactly one |
| level | int | i | hybrid (F4): each creature rolls in the party band [min−X, max+Y], shifted by the land's danger-tier → `generators.json#design.enemy-level`. A: shared, rose with distance |
| danger-tier | safe / normal / dangerous | i | F4: rolled once at generation |
| tier-range | `mob-strength-tier`[] | i | S: regions host white→yellow enemies, dungeons above surface |
| rarity | int 0..4 | i | A devlog "rare zones": stronger monsters, better loot `?` |
| realm | `realm` ref | e | S: the kingdom/cult/tribe whose lore covers it |
| border | polygon (map only) | i | internal land border: dotted line on map, no physical wall (A devlog kingdoms had walls `X`); hybrid outer world boundary follows `world` item 2 |
| inventory-page | — | — | S: each land owns an inventory tab (see `inventory`) |
| key-items | `key-item`[] ≤ 9 | e | S: up to 4 movement + 3 ticket + treasure spirit + ember |
| gnome-suppliers | 4 | e | S |
| books-of-crafting | 4 | e | S |
| wizard-towers | ≤ 5 | e | S |
| circles-of-power | 1..n | e | S |
| artifacts | 1..n | e | S |
| settlements | hybrid / A: exactly 1; S: several | e | |
| coords | int×2 | i | land-grid cell (F6); hybrid −512..511 inclusive on each horizontal axis (§3.1 world); `seed = hash(world.seed, coords)`, every roll of the land derives from it (D12) |
Internal grid: alpha region = 64×64 zones = 16 384 blocks; 8×8 mission cells per region;
world addressable as 1024×1024 regions (finite). One gameplay `land` = one internal region cell
(F6, decided); heightmap, water level and noise are our own.

### landscape
Biome family with climate, palette, flora, fauna and structure rosters. `A S Ω`
→ `instances/landscapes.json` (13: greenlands, snowlands, deserts, jungles, lava-lands, oceans,
savannahs, wetlands, swamp-lands`?`, dark-woods, deadlands, mountains, mushroom-lands `X`).
| prop | notes |
|---|---|
| climate | temperature / humidity band selecting the biome (devlog 2012-01) |
| sky / lighting | e.g. green sky in deadlands; lava lands and dark woods dark by day |
| hazard | cold-water slow, toxic-river poison, lava burn (S) |
| settlement-style | architecture theme |
| flora, fauna, dungeon-types | ID lists |
| gen | ours (D12): `relief` (height multiplier), `base` (height offset, blocks), `surface` block-type, `top`/`cliff` RGB |
| versions | shipped in A, S, both, or `X` |

### terrain-feature
Natural formation placed inside a land. `A S` → `instances/terrain-features.json`
(mountain, plateau/cliff, valley, canyon+mesa, cave, river+waterfall, lake, lava-lake, volcano,
island, sky-island `S`, forest (generic/birch/pine, dungeon-forest), field, road+bridge+tunnel,
oasis, cloud (no collision), giant-rock `A`, giant-tree `A`, graveyard).

### climate
Continuous fields sampled per position. `A S`
| prop | notes |
|---|---|
| temperature-c | shown in HUD; desert ≈ 36 °C |
| humidity-pct | shown in HUD; desert ≈ 5 % |
| effects | snow presence, berry/heartflower spawns (S guide) |

### flora
Harvestable or decorative plant object; harvested by attacking. `A S` → `instances/flora.json`.
| prop | notes |
|---|---|
| yields | `ingredient` ref + count range (e.g. bush → 1–3 wood log + plant fiber) |
| landscapes | where it spawns |
| respawn | at 0:00 (S) |
| light | shimmer mushroom glows blue |

### deposit
Mineral node in caves / underwater caves. `A S` → `instances/deposits.json` (iron, silver, gold,
sandstone, emerald, sapphire, ruby, diamond, ice-crystal). Yields 1–3; respawn at 0:00; rarely
inside boulders that need a bomb.

### settlement
Village or city. `A S`
| prop | notes |
|---|---|
| style | `settlement-style` from landscape (european-framework, medieval-stone, na-wood, log, desert, jungle, undead, lava, ocean) |
| districts | `district`[] (A: trade, crafting, adventurer/class, pet quarter (`X`), portal, palace) |
| buildings | `building`[] |
| population | `race` mix (humans majority; undead villages in deadlands/dark woods) + village animals |
| visibility | A: always on map; S: hidden until discovered |
| count-per-land | hybrid / A: 1; S: several |
| sewer | S: dungeon under some 5★ villages holding an artifact |
| petrified | bool, S: witch curse until witch killed |
| possessed | bool, S: demon portal active in land |
| layout | hybrid (D22): one per land from the land seed, terrain flattened under `design.settlement.radius`, box buildings on a ring, one NPC per service building; numbers `design.settlement` |

**Hybrid settlements item 1 (owner approved, 2026-09-27):** exactly one settlement per land
is the final target, not a temporary limit pending multiple settlements. Other D22 layout,
services and settlement-safety rules are unchanged. Live `rulesets.json#ruleset-hybrid.flags`
still says `settlements-per-land: "many"`; flag migration and enforcement remain deferred.
`design.settlement.per-land` already equals 1; the current validator only checks ≥1.

Hybrid village-curse state is world-shared and persistent under `save-data` item 4.
Settlement-style records are hybrid configuration under §5 Validation-contract mapping item 1.

### district
City quarter. `A` → `instances/buildings.json#districts`.

### building
Functional structure in a settlement. `A S` → `instances/buildings.json` (inn, weapon-shop,
armor-shop, item-shop/general-store, identifier/analyst, smithy, clothier, workshop/carpenter,
class-trainer ×4 / guild, adapter `A`, flight-master `S`, den, house, watchtower, well, market
stalls). Each links to `npc-role`s and `crafting-station`s inside it.

### dungeon-type
Built or natural structure that hosts a mission objective. `A S` → `instances/dungeon-types.json`.
| prop | notes |
|---|---|
| naming | e.g. "Castle ___", "Ruins of ___", "Temple of ___", "Catacombs of ___", "Pyramid of ___" |
| landscapes | placement |
| layout | A: linear route + one dead end with rewards; S: room gauntlet, several bosses of rising tier |
| entrance | e.g. pyramid: top; temple: near top → spiral down; castle: front gate locked until nearby enemies dead |
| contents | traps `A` (spike; fire/stomp in data `X`), vases `A`, tables with loose items `A`, one-time chests `S`, artifact at end `S`, magic barriers `S` |
| roster | enemy faction/race set (forest dungeons: insect, animal-i, animal-ii, undead, orc, human, beetle, dwarf) |
Alpha location table (cuwo): Village, Mountain, Forest, Lake, Ruins, Gravesite, Canyon, Valley,
Crater, Cave, Portal, Rock, Tree, Peak, Castle, Catacombs, Palace, Temple, Pyramid, Island.

### poi-type
Non-dungeon point of interest / event site. `A S` → `instances/poi-types.json` (campsite, arena,
wizard-tower, circle-of-power, demon-portal, mana-pump, mana-inductor, mana-tree, shrine-of-life,
revival-statue `A`, portal `A`, bird-statue, lore-site (menhir/tablet/crypt/henge), molehill,
bone-pile, hornet-nest, slime-well, old-hut, hidden-treasure (log/sky statue/cave), airship,
wollays-house, kingdom-frontier-wall `X`).

### static-entity
Interactive or decorative world object with orientation and open/closed/sat state. `A S`
→ `instances/static-entities.json` (78 alpha ids: doors, gates, traps, lever, chests, furniture,
market stands, shelves, corpse, rune stone, artifact pedestal, flower boxes, street lights,
fences, vases, campfire, tent, beach umbrella/towel, sleeping mat, 7 crafting stations).
Dynamic subset: sit-able {sleeping-mat, stool, bench, bed}; open-able {window, castle-window,
door, big-door, chest}.

### realm
Procedural kingdom / realm / cult / tribe that historically owned several lands. `S`
| prop | notes |
|---|---|
| kind | kingdom \| realm \| cult \| tribe |
| name | procedural (Kurlent, Arigorar, Annoia, Asionia…) |
| leader | name, personality trait, birth year, hometown, tomb location |
| capital | name, founding year, optional destruction date |
| magic-or-technology | flavour text |
| lore-pct | 0..100 per player; each lore site ≈ +10 % |
| artifacts | `artifact`[] revealed on map at 100 % |
Hostile NPCs in a land can be labelled with the realm's name.

### game-clock
Time, resets and sleep. `A S`
| prop | value |
|---|---|
| speed | 10× real time (1 game min ≈ 6 s; day = 2 h 24 min real) |
| sleep-speed | A/S reference: 100× (baseline/units unresolved, §5 source item 10; clock only, world does not simulate faster); hybrid inn skip below |
| midnight-reset | 0:00: respawn eligible monsters, regenerate daily missions, respawn deposits and wilderness plants, restock shops, re-close divine doors; hybrid cleared-enemy eligibility and occupied-site timing follow world/reset items 3–4 below (historical S exclusion uncertain) |
| inn-reset | A/S reference: innkeeper 18:00–06:00 → set 07:00; A free; S 10 coins, also re-rolls daily missions; hybrid services below |
| night | very dark; lanterns; stealth builds faster in darkness |
| weather | none in A/S; Ω: rain, snow, moving clouds, freezing water |

**Hybrid world/reset item 3 (owner approved, 2026-09-28):** defeated enemies, **including
bosses**, in **ordinary dungeons and repeatable daily encounters** return with the daily reset.
Enemies belonging to a **completed one-time objective stay cleared**, including its guards
and boss. Enemy resets **never renew an artifact or book claim**: personal source claims and
world-shared improvements retain their approved scopes and reset rules (`save-data`, items 4–5).
Tomorrow may offer another daily boss fight, but never recreate a completed supplier-rescue
encounter. Daily-enemy eligibility does not change other mechanics' resets or reward rules.
Live-data/checker migration and reset/save implementation remain deferred and unauthorized.

**Hybrid world/reset item 4 (owner approved, 2026-09-28):** an **occupied dungeon/quest
site waits until all players leave** before applying its pending daily refresh, using item 3's
eligibility. **Multiple missed midnights produce one refresh**, never stacked waves. The clock
change itself **never heals or replaces living enemies or erases an ongoing fight**; a run
spanning midnight can finish without defeated guards respawning behind the party. Ordinary
threat decay, targeting and home-return rules remain unchanged (`ai-behavior`): genuine mob
death/respawn starts fresh, not a clock-triggered wipe of surviving mobs. No site radius,
occupancy grace period or storage format is chosen. Occupancy/reset enforcement is deferred.

**Hybrid settlements/inn item 2 (owner approved, 2026-09-27):** inn recovery fully heals and
sets the respawn point **for free at any time**. A separate sleep service costs **10 copper**,
is available **18:00–06:00**, and skips the clock to the **next 07:00**: 22:00 reaches tomorrow
morning; 02:00 reaches that morning. This is a clock skip, not fast-forwarded combat, status
effects or cooldowns. The sleep hours and fee do not restrict free recovery.

**Hybrid settlements/inn item 3 (owner approved, 2026-09-27; depends on item 2):** apply
ordinary midnight resets **once when the skip crosses midnight**. Sleeping at 23:00 crosses
midnight; sleeping at 02:00 does not. Sleeping itself grants **no extra shop refresh or mission
reroll**. Cleared dungeon/quest enemy eligibility and occupied-site timing follow world/reset
items 3–4 above.

**Hybrid settlements/inn item 4 (owner approved, 2026-09-27; depends on item 2):** **all
connected players must explicitly agree** before the shared clock skips. The initiating player
pays the **single 10-copper fee only when the skip succeeds**. A refusal blocks the skip and
nobody loses money. Free recovery needs no agreement. This specifies no voting timeout or
disconnect protocol.

Documentation only: `design.settlement.inn` and current runtime still provide free recovery
without a clock/skip. The hybrid `inn-cost: 10` flag does not distinguish the two services;
`generators.json#time` and A/S inn records are not a complete hybrid service contract.
The S sleep-specific refreshes in `economy.json#rules` / `npc-roles.json#innkeeper` are reference,
not hybrid policy. Live-data migration and runtime implementation remain deferred and unauthorized.

**Hybrid persistence item 8 (owner approved, 2026-09-28):** a **shut-down world accumulates
no gameplay time**. Its clock and timed resets resume from saved time, without offline combat
or overnight reset catch-up. A dedicated server that remains running continues normally even
with nobody connected. This preserves D16's frozen distant movement/attacks and the approved
elapsed-gameplay-time threat/taunt timers (`ai-behavior`); it does not require simulating every
creature in an empty world. Approved inn sleep remains its distinct clock-skip rule above.
No character-absent cooldown/status policy, serialization/checkpoint cadence or crash-recovery
policy is chosen. Clock/save implementation remains deferred and unauthorized.

### 3.2 Entities

### entity
Anything with a position, HP and appearance. Base of player, NPC, creature, pet, bomb. `A S`
| prop | type | notes |
|---|---|---|
| pos, velocity, accel, roll/pitch/yaw | vectors | pos as int64 native units |
| hostility | `hostility` enum | friendly-player 0, hostile 1, friendly 2/4/5, named-friendly 3, target 6 |
| species | `race` or `creature` ref | stable ontology ID; numeric source entity IDs use the source version's namespace (see `creature`) |
| class, specialization | refs | humanoids only (any humanoid NPC may have any class) |
| hp, mp, stamina, block-power, stealth | `resource` | |
| level, xp | int | A; S: level = artifact count |
| power-base | u8 | NPC power tier |
| hp/damage/armor/resi multipliers | float | NPC scaling knobs |
| hit-counter, last-hit-time | | combo state |
| stun-time, slowed-time, blue-time (frozen), speed-up-time | ms | status timers |
| flags | bitset | climbing, attacking, glider, hostile, lantern, stealth |
| appearance | `appearance` | |
| equipment | `item`[13] | slot table in `instances/equipment-slots.json` |
| skills | u32[11] | A skill points (pet-taming, riding, climbing, gliding, swimming, sailing, ability1..5) |
| mana-cubes | u32 | A currency for cubes `?` |
| name | ≤16 ASCII | |
| parent-owner | entity id | pets, clones, bombs |

### appearance
Rigid-part voxel body. `A S Ω`
| prop | notes |
|---|---|
| hair-rgb | free RGB |
| model ids | head, hair, hand, foot, body, tail, shoulder, wing (`.cub` models) |
| per-part scale/offset/rotation | head, body, hand, foot, shoulder, weapon, tail, wing; body/arm/feet/wing/back pitch |
| flags | double-scale (bosses), immovable |
| expression | Ω: neutral/happy-angry/sad/surprised/sleeping/blink |
Ω: all parts procedural (no hand-modelled hair/face/hands).

### race
Playable species (8) + NPC-only humanoids. `A S Ω` → `instances/races.json`.
| prop | notes |
|---|---|
| playable | bool |
| genders | male, female |
| size-class | small (dwarf, goblin: fit through windows) / normal / large (orc) |
| customization | hair count M/F, head count M/F (alpha asset counts), quirks (frogman "hair" = eyes; dwarf beards/braids; orc jaws; lizard eyelashes) |
| stats | **none** (purely cosmetic); hitbox capsule by size-class (D13, `generators.json#design.movement.hitbox`) |
| voice | race-specific groans |

### character-class
One of Warrior, Ranger, Mage, Rogue. `A S Ω` → `instances/classes.json`.
| prop | notes |
|---|---|
| id-number | 1..4 (cuwo) |
| weapon-types | 3 families each |
| armor-material | iron / linen / silk / cotton |
| mp-generation | warrior: hits & blocking; ranger: hits (sniper: stealth); rogue: hits (assassin: stealth; ninja: dodges); mage: passive regen to 100 |
| special-attack-mode | charged (warrior, ranger, mage) vs instant (rogue) |
| hp-mult | player max-HP class multiplier from `stats.json#player-hp` (warrior 1.30, ranger 1.10, rogue 1.20, mage 1.00) |
| specializations | 2 |

### specialization
Sub-class chosen at a trainer (A: fee; S: free at guild). `A S` → `instances/specializations.json`.
Holds passives and the version-specific ability kit. Player spawns as the first spec of the class.

### player-character
A saved hero. `A S`
| prop | notes |
|---|---|
| race, gender, class, spec, appearance, name | creation |
| level, xp, skills[11] | A |
| artifacts | hybrid: collected permanent stat rewards (§3.4), not character levels; S reference: level = count |
| inventory, equipment, coins, platinum `A` | |
| known-recipes | hybrid: one set of recipes shared by book/formula learning, with no source-specific duplicates; recipes persist across lands/sessions/worlds (§3.7 save-data); A formulas learned; S books per land (reference) |
| lore-known | hybrid: per character, realm and saved world (§3.7 save-data); S: per realm |
| discovered lands/portals/shrines/flight-points | hybrid: terrain exploration uses world.discovered-zones; personal travel unlocks remain per character/world (§3.7 save-data) |
| pets (cages), active pet, pet slot | |
| position, respawn point | hybrid: per character per saved world (§3.7 save-data) |
| world-independent | hybrid: portable hero and progression between solo worlds and servers (§3.7 save-data, persistence item 1); A: any character enters any world; S: one world |
| starting-kit | A: class weapons + gold ring + silver ring; S: 3 weapon sets + chest + 5 life potions |

### npc-role
Function of a humanoid NPC in a settlement or event. `A S` → `instances/npc-roles.json`
(villager, weapon-vendor, armor-vendor, item-vendor, identifier/analyst, innkeeper, class-trainer
`A`, guild-receptionist `S`, adapter `A`, flight-master `S`, gem-trader `S`, gnome-supplier `S`,
arena-master `S`, carpenter, guard, adventurer (roaming groups, may be hostile), captive,
old-man quest giver `X`, architect `X`, disenchanter `X`, sage `A`).
| prop | notes |
|---|---|
| schedule | A* daily path: home → park → shops → inn; sleeps at night |
| dialogue | speech bubbles; random banter; hints (missions, key items, lore); speech-bubble mission marker `A` |
| services | shop / sleep / respec / travel / identify / adapt |

### creature
A non-player species (animal, insect, aquatic, monster, humanoid enemy, boss species). `A S Ω`
→ `instances/creatures.json` (~150).
| prop | type | notes |
|---|---|---|
| alpha-entity-id | int? | legacy name for the numeric source entity ID, not alpha-only; JSON `aid`, typed `alpha_entity_id`; null = unrecorded |
| family | `creature-family` ref? | optional primary balancing family; only this family supplies family stat modifiers |
| descriptive-families | set<`creature-family` ref> | zero or more descriptive memberships; never supply or stack stat modifiers |
| category | animal \| insect \| aquatic \| plant-creature \| monster \| undead \| demon \| elemental \| humanoid \| boss-species \| static-target \| unused |
| hostility-default | hostile \| neutral \| passive \| friendly \| variable (by tribe) |
| landscapes | refs | |
| habitats | caves, rivers, dungeons, graveyards, pyramids… |
| group-size | range | e.g. runners 3–5 |
| combat-role | melee \| ranged \| mage \| any-class \| none | humanoids may be any class |
| tame-food | `pet-food` ref? | null = untameable |
| rideable | bool | per-page value (F2); the 1.0.0-1 bug made all rideable |
| pet-types | melee, ranged, tank, healer, mount | |
| boss-species | bool | always-boss species (troll, yeti, cyclops…) |
| boss-capable | bool | may spawn as boss-ified variant |
| breaks-terrain | bool | boss species |
| drops | species-specific items (parrot feather, onion slice, radish slice, popcorn) | random tier loot otherwise |
| abilities | notable moves (troll earthquake, cyclops charge/cyclone, djinn summon slimes, snout beetle charged shot, zombie bite `A`, wraith unkillable) |
| signature-ability | Ω per species (zombie eat, ogre belly slide, slime divide, crab claw boomerang, hornet poison sting, hedgehog spike swirl, bat vampiric bite) |
| drinks-potions | bool | ogre, mermaid, insect guard, NPCs |
| lantern-at-night | bool | |
| versions | | |

Source IDs (reconciliation item 6, approved 2026-09-15): the cuwo alpha reference table covers
0..155; post-alpha additions may have larger IDs. Radishling Sprout / Mineral Water share 192,
and Caterpillar / Mixed Salad share 293 (`research/research_creatures_quests.md §2.5`).
Version tags, not the integer alone, record provenance: an alpha-reserved ID does not prove
alpha availability (F10). Preserve stable creature IDs, numeric source IDs, version tags and
`tame-food` / `pet-food.tames` pairings. Keep the legacy field names for compatibility; do not
clamp later IDs to the alpha range or invent values for unrecorded IDs.

### creature-family
Shared base form. → `instances/creature-families.json` (top-level family `members` lists,
not nested spawn rosters). These taxonomy records follow §5 Validation-contract mapping item 1.

**Hybrid family item 1 (owner approved with amendment, 2026-09-27):** a creature has at most
one primary balancing family (`family` / `member-of-family`). Multiple descriptive memberships
(`descriptive-families` / `descriptive-member-of-family`) may coexist, but never supply or stack
family stat modifiers. Top-level family `members` lists describe memberships, not multiple
primary assignments or automatic species-trait inheritance.

**Skeleton Dog (`skeleton-dog`) has primary family `dogs`, not `skeletons`.** It retains descriptive
membership in both dogs and skeletons; its `undead` category is independent and unchanged.
Other existing primary assignments remain. The family assignment itself changes no taming,
abilities, drops, hostility, habitats or pack aggro, and introduces no numerical family modifier.
Items 4–6 below separately decide encounter rarity and extend variant habitat permission,
not combat/loot tiers.

Documentation only: live `creatures.json` still assigns Skeleton Dog to `skeletons`; migration,
model/loader/validator support and runtime family scaling remain deferred and unauthorized.
There is no live family `hp-mult` data or runtime family scaling today.

**Hybrid family item 2 (owner approved, 2026-09-27):** these 25 missing primary assignments
are authoritative. Preserve all other existing assignments except item 1's Skeleton Dog override.
No numerical changes, new family classifications or species-trait inheritance are introduced.
Live JSON still lacks these assignments; migration remains deferred.

| primary family | creature IDs |
|---|---|
| cats (3) | `cat`, `brown-cat`, `white-cat` |
| sprouts (9) | `onionling`, `desert-onionling`, `radishling`, `radishling-sprout`, `cormling`, `cormling-sprout`, `chiling`, `habanero`, `bloomling` |
| guardians (2) | `ancient-guardian-anubis`, `ancient-guardian-horus` |
| trolls (3) | `troll`, `dark-troll`, `yeti` |
| fish (8) | `sapphire-fish`, `lemon-fish`, `seahorse`, `shark`, `lantern-fish`, `maw-fish`, `piranha`, `blowfish` |

**Hybrid family item 3 (owner approved, 2026-09-27):** creatures outside the defined families
may remain unassigned. With no primary family, the family modifier is **×1.0**, preserving all
other ordinary stat calculations (`design.enemy-hp` already records this default). Do not invent
catch-all families merely to fill every entry.

**Hybrid family item 4 (owner approved with amendment, 2026-09-27):** Skeleton Dog has a
**1% encounter chance relative to dog spawns**; the remaining 99% are non-skeletal dogs.
This replaces the proposed one-tenth relative species-selection weight. The denominator is dog
spawns, not all creatures, and 1% is a probability, not a guaranteed quota every 100 encounters.
It grants no extra combat strength or loot tier.

**Hybrid family item 5 (owner approved, 2026-09-27):** roll the 1% chance independently for
**each individual dog**, not once per pack. Packs may mix ordinary and skeletal dogs. The
denominator remains dog spawns, with no per-species weighting or guaranteed quota.

**Hybrid family item 6 (owner approved, 2026-09-27):** apply the rare dog variant **wherever
dogs already spawn**, not only Skeleton Dog's former dungeons/dark woods/deadlands habitats.
Preserve existing settlement safety (`c-hostile-in-city`); this does not make protected town
inhabitants attackable. This habitat permission itself changes no species' abilities, taming, drops,
hostility, combat/loot tiers or pack aggro; item 7 separately amends Skeleton Dog's temperament
and tameability.

**Hybrid family item 7 (owner approved with amendment, 2026-09-27):** use **Collie (`collie`)**
for ordinary outcomes wherever an already-established dog encounter defines only Skeleton Dog.
The live deadlands roster is the explicit affected roster. Preserve existing ordinary-dog
selections elsewhere, dog encounter frequency and pack sizes. Each individual still rolls 99%
ordinary / 1% skeletal; do not add unrestricted Skeleton Dog spawns or new dog locations.
Collie's existing traits, including its untameable dungeon-patrol exception, remain unchanged.

**Owner amendment:** Skeleton Dog is **non-aggressive and tameable**, superseding its former
hostile/untameable policy. Items 8–9 below clarify normal dog behavior and taming food.
Existing general taming eligibility restrictions and settlement protection remain; no riding
permission, numerical source ID, combat/loot bonus or other species-trait change is granted.

**Hybrid family item 8 (owner clarified, 2026-09-27):** Skeleton Dog is a different dog breed,
not a special behavior category. It follows **normal dog behavior in the same encounter and
state**, including ordinary aggression/retaliation, pack response and taming reactions. Item 7's
non-aggression means the ordinary dog's baseline, not unconditional passivity overriding normal
encounter/provocation rules. The proposed Skeleton-Dog-only immunity to retaliation and to the
usual taming-induced group hostility is not adopted. Once tamed, normal pet behavior applies.
The stable species ID, primary `dogs` family, descriptive memberships and independent `undead`
category remain; “dog race” does not introduce a playable `race` or new species-trait inheritance.

**Hybrid family item 9 (owner approved, 2026-09-27):** the same **Bubble Gum (`bubble-gum`)**
tames both Collie and Skeleton Dog, under their ordinary eligibility rules. Keep Bubble Gum's
existing availability and prices; add no food, recipe or family-wide bait inheritance.
The shared-food/source-ID contract is in §3.4 `pet-food` / §5 `c-food-id`.

Documentation only: live rosters/traits and Bubble Gum's single-species mapping still lack
these decisions. Migration, model/loader/validator support and runtime enforcement remain
separately deferred and unauthorized.

### pet
A tamed creature owned by a player. `A S`
| prop | notes |
|---|---|
| species | `creature` ref |
| name | via `/namepet` |
| cage | `item` of type pet (turtle cage = shell) |
| level, xp | hybrid: retained with the portable hero (§3.7 save-data); A reference: did not persist in multiplayer |
| hydration | A: droplets under HP; drains while riding; refill in water |
| scaling | S: from owner's weapon/armor rating incl. `+` gear |
| boss-origin | tamed boss keeps skills, normal size; reverts to normal on reload |
| behaviour | never initiates; attacks owner's target; recall/ride key; teleports to owner if far (S); revives ~1 min after death or on re-slot; ignores wraiths |
| riding | A reference: pet-master 5 → riding skill; S reference: land's `reins`; hybrid gate below; dismount on attack/dodge/fall/shift/pet death/water |

**Hybrid traversal item 1 (owner approved, 2026-09-28):** mounting requires **5 Pet Master
points and at least 1 Riding point**, globally acquired **Reins**, and a **rideable tamed pet**.
Further Riding points retain their speed benefit. This grants no new species riding permission,
Reins acquisition route or equipment slot. Live data and runtime enforcement remain deferred.

### faction
Lore/gameplay group. `S` (tweeted 2015) → `instances/factions.json` (order-of-the-light,
druids-of-mana, unholy-pact, steel-empire, cult-of-doom, bloodaxe-clan, obsidian-knights,
thaldania-cult, bandits `A`, benkal-pirates).

### hostility
Enum: hostile (red bar, attacks on sight, outside cities) / neutral (green, retaliates) /
friendly (blue, unattackable, waves) / friendly-player / named-friendly / target. `A S`

### ai-behavior
Rules shared by enemies. `A S`
| rule | value |
|---|---|
| aggro | table per attacker; damage adds aggro; highest aggro targeted; taunt (heroic shout, 5 m) forces; full stealth → zero aggro gain |
| perception | hybrid: spawned packs share current sightings, not threat/order; eligibility and protected-return rules below govern each member independently |
| pathfinding | A* with climbing and arbitrary bounding boxes; chases "to the most unreachable locations" |
| patrol | ogre + collie patrols in dungeons, stronger than static guards; forest guards at campfires; some paths ignore stealthed players |
| stun | stars over head; immune to re-stun while stars visible (players too) |
| potions | humanoids drink at low HP |
| combo | enemies build combos against players (armor pierce) |
| chase | wraith pursues longer; most drop chase eventually `?` |
| clones | some bosses/NPC mages summon doppelgangers |
| possession | S: demon portal randomly possesses NPCs in the land (bigger, red, tougher, respawn possessed) |
| simulation | hybrid: beyond `design.spawns.ai.sim-radius`, movement and attacks stay frozen (D16); threat decay and taunt expiry reflect elapsed gameplay time (approved 2026-09-27, below). Distance = nearest player once `multiplayer-mode` lands (single player: the one player). |

Hybrid aggro rules (owner approved 2026-09-18/19 and 2026-09-27, documentation only; relation definitions in
§4, constraints `c-threat-pair` / `c-current-target` in §5):
- **Pack membership (owner approved 2026-09-27):** creatures generated together as one
  spawned pack belong to that group. Nearby packs do not merge merely because they share
  a species or faction. Membership concerns spawned individuals, not `creature` definitions.
- **Pack response (owner approved 2026-09-27):** a hostile pack responds when a member
  detects a player. Damaging a neutral member provokes its combat-capable packmates against
  that aggressor, not uninvolved players. Friendly/passive creatures are excluded. Returning
  members finish their protected return rather than being pulled back into combat. Neutral
  provocation establishes aggressor-specific eligibility, not unconditional pursuit at zero
  threat without detection; taunt alone grants no lasting neutral eligibility (below).
- **Shared awareness (owner approved 2026-09-27):** packmates share current sightings, not
  threat points or engagement order. Detection in these targeting rules includes a packmate's
  current sighting, so a member can react around a corner while another detects the player.
  Once nobody in the pack detects that player, there is no retained shared sighting; each mob's
  own remaining threat governs continued pursuit. Apply targeting priorities independently per
  mob, preserving hostility/provocation eligibility and each member's protected return.
- **Damage contribution (owner correction, 2026-09-18):** add **1 aggro point per 1% of the
  mob's maximum HP actually removed** by the attacker: `aggro gained = 100 × HP removed / mob max HP`.
  Except at full stealth (below), use actual HP loss after reduction/absorption, not attempted
  damage; zero HP loss adds none.
  Preserve fractional points (0.5% HP loss adds 0.5 points). Equal percentages generate equal
  threat at every progression level, so fixed-rate decay does not last longer just because
  HP/damage numbers are larger. This supersedes the raw-HP conversion, not the targeting rules.
- **Full stealth (owner approved 2026-09-27):** full stealth prevents new damage-generated
  threat; it neither erases existing threat nor cancels an active taunt. Check the attacker's
  stealth when damage lands, before that hit consumes the stealth bar; check each damage-over-time
  tick individually. Camouflage can sustain threat-free damage while it keeps stealth full.
  Partial stealth retains its existing detection-range reduction, with no additional threat
  multiplier. Existing positive threat can still sustain pursuit; ordinary zero-threat targeting
  still requires detection. Stealth is not automatic rescue for an existing target, but can allow
  attacks without pulling an enemy that cannot detect the attacker.
- **Current-target ties:** during ordinary threat-based targeting, retain the current target
  when tied for highest threat. Another attacker must exceed it to displace it through threat
  alone; equal scores do not cause arbitrary switching.
- **Other-target ties:** when the highest threat is positive and the current target is not
  among the highest-threat attackers, choose the tied leader who engaged that enemy first,
  not the nearest or latest hitter, nor randomly. Higher threat and current-target retention
  take precedence over engagement order; zero-threat fallback is defined below.
- **Zero-threat fallback (owner approved 2026-09-19):** in ordinary targeting, when no eligible
  positive-threat player takes priority and there is no valid current target, choose the nearest
  eligible player among those the mob normally detects. This does not generate aggro or assign an
  engagement-order position. Retaining a valid current target tied for highest threat still
  takes precedence: a closer zero-threat player does not displace it. **Exact-distance ties
  (owner approved 2026-09-27):** choose once at random with equal chances among equally nearest
  detected players, then retain that target under the existing tie rule; do not repeatedly reroll.
- **Heroic Shout (owner approved 2026-09-27):** affected enemies must target the caster
  for **3 seconds**, overriding ordinary threat priority without adding or copying aggro points
  or assigning engagement order. Damage gains and decay continue underneath. On expiry, resume
  ordinary targeting, including retention of a valid tied current target; lasting control is
  not guaranteed. Preserve the existing **5-metre radius**, healing (50% max HP over 10 seconds),
  30-second base cooldown and existing skill-point scaling; this adds no taunt-duration scaling.
- **Neutral eligibility after taunt (follow-up 14, owner approved 2026-09-27):** taunt alone
  adds no neutral provocation or lasting ordinary eligibility for a previously uninvolved caster.
  When it expires, reconsider legitimate aggressors under ordinary targeting and detection rules;
  return home if no eligible target remains. A tied current target is retained only if ordinarily
  eligible, not merely because it was forced by taunt. For example, A damages a neutral pack and
  B only taunts: at expiry with all scores zero, reconsider A if detected, not B merely for taunting.
  If B damages the pack, the existing aggressor-specific pack-provocation rule applies.
- **Taunt eligibility (owner approved 2026-09-27):** Heroic Shout affects hostile enemies
  and already-provoked neutral enemies within 5 metres, including through cover; walls do not
  block application. It does not provoke peaceful neutrals or affect friendly/passive creatures.
- **Competing taunts (owner approved 2026-09-27):** the latest successful taunt replaces the
  previous one and starts its own duration; replaced taunts never resume. For genuinely
  simultaneous taunts, choose one caster randomly once. **Winner scope (follow-up 13, owner
  approved 2026-09-27):** each affected enemy chooses independently among simultaneous eligible
  taunters whose casts reached that enemy. A pack may split between casters; there is no shared
  winner or guarantee of keeping the pack together.
- **Taunt termination (owner approved 2026-09-27):** starting return cancels any active taunt;
  new taunts cannot interrupt protected return or queue for afterward. Outside return, a taunt
  ends early if its caster dies or disappears. Moving beyond the initial 5-metre casting radius
  alone does not cancel it; the existing home leash still applies.
- **Continuous decay (rate approved 2026-09-18):** each mob tracks each player's threat
  separately and subtracts **1 aggro point per elapsed second**, both while fighting and while
  not fighting. Decay is continuous (0.5 seconds removes 0.5 points), not whole-second ticks.
  Hits keep adding their normal damage-based threat while decay continues; attacking does not
  pause or restart the countdown.
- **Distant timers (owner approved 2026-09-27):** threat decay and taunt expiry use elapsed
  gameplay time even while the mob is outside the simulation radius. On reactivation, remaining
  threat and taunt duration reflect the time that passed; movement and attacks remain frozen
  while distant. This approval does not extend to every other status timer or choose how to
  implement elapsed-time accounting.
- **Retained threat:** switching targets does not clear other players' remaining threat. If the
  higher-threat teammate dies, a player with remaining positive threat can be targeted again
  according to the normal highest-threat/tie rules; losing priority is not being "forgiven".
- **Zero threat (approved 2026-09-18):** decay stops at zero, never going negative. At zero,
  past hits alone no longer justify ordinary pursuit of that player; there is no separate damage
  memory extending it. Without an active taunt, if the mob no longer detects that player, it stops
  pursuing them. Normal detection of an eligible player (hostile or provoked-neutral rules) can
  still start or maintain aggression at zero; reaching zero is not immunity.
  Other players' remaining threat is unchanged; full stealth does not erase it.
- **Zero-threat tie-breaker memory (owner correction, 2026-09-19):** when a mob's aggro toward
  a player reaches zero, discard that player's remembered engagement-order position for that
  mob. Do not retain or restore pre-zero tie-breaking priority. Other players' scores and order
  are unchanged. Normal hostile detection, higher-threat priority and current-target tie
  retention still apply; clearing historical order does not force a target switch.
- **Fresh engagement order (owner approved 2026-09-19):** after reaching zero, assign a new
  engagement-order position when that player's aggro toward that mob next rises above zero,
  after players whose existing positions remain valid. Under the approved damage rule, this
  requires damage that generates positive aggro, not proximity, detection or a missed attack.
  Higher threat and current-target tie retention still take precedence. Zero-threat fallback
  does not assign an engagement-order position, nor does taunting.
- **Player death (approved 2026-09-19):** death immediately clears every mob's aggro points
  toward that player, without changing surviving teammates' scores or their normal decay.
  After respawn, the player rebuilds aggro from zero; normal hostile detection still applies.
  Death also clears that player's engagement-order position with every mob. Fresh assignment
  follows the rule above; surviving teammates keep their positions. Higher aggro and current-target
  retention still take precedence.
- **Escape (owner approved 2026-09-19):** getting away or ending pursuit alone does not clear
  that player's remaining positive aggro or engagement-order position with the mob. Normal decay
  continues; reaching zero clears the old position, and regaining positive threat assigns a fresh
  one as above. Other players' scores and order are unchanged. This governs memory, not chase distance.
- **Temporary absence (owner approved 2026-09-27):** within the same running world,
  temporary player disconnect or zone unloading does not grant an extra threat/order wipe.
  Preserve the logical mob/player pair's remaining state under normal decay and approved resets;
  an absent player cannot be targeted. Reconnecting before threat expires can restore eligibility
  under normal targeting rules, not guaranteed priority. A mob that actually dies and respawns
  starts with fresh threat/order. Restart retention follows persistence item 9 below;
  neither decision chooses a storage strategy.
- **Restart persistence (hybrid persistence item 9, owner approved 2026-09-28):** save each
  **surviving logical mob's remaining threat, engagement order and neutral provocation** across
  a server restart. Restarting alone grants no wipe; shutdown downtime causes no decay under
  `game-clock` persistence item 8. Resume normal targeting and return-home rules: absent players
  cannot be targeted, and caster disappearance still terminates taunts. Each mob/player pair
  remains independent; normal gains/decay and the approved zero, player-death and home-arrival
  resets still apply. Actual mob death/respawn starts fresh, not from the saved survivor record.
  For example, saved threat of 10 resumes at 10, then ordinary decay or completed return can
  clear it. This promises no full combat snapshot, resurrected target node, guaranteed target
  priority, resumed expired/terminated taunt or unrelated HP/status/cooldown persistence.
- **Return-home trigger (owner approved 2026-09-19):** during pursuit, crossing the existing
  home leash (`design.spawns.ai.leash`, 30 blocks measured from the mob's home) starts return
  regardless of remaining aggro or taunt. Within the leash, if its target dies, disappears, or
  (outside an active taunt) has zero aggro and is no longer detected, first consider other living
  eligible players with positive aggro using the approved highest-threat/tie rules. If none
  remain, normal detection of eligible players can still sustain combat; otherwise return home.
  Starting return does not clear aggro or engagement order; normal decay continues. Protected return and the arrival reset follow below.
- **Protected return (owner approved 2026-09-19):** attacks do not restart pursuit once the
  mob is returning, including after it moves back inside the home leash. During return, its
  movement speed is **×2 the normal return speed** (currently `design.spawns.ai.chase`: 6.5 →
  **13 blocks/s**), and damage it would otherwise receive is reduced by **90%** (it takes 10%),
  including poison and burning ticks. These temporary return-state modifiers do not change
  ordinary chase speed or define the general resistance stat. Existing status effects still
  apply; no status cleansing or crowd-control immunity is granted.
  On reaching home alive, restore **full HP once** and end the return-speed/damage-reduction
  bonuses. A mob killed before arrival stays dead. Aggro follows the existing gain/decay rules
  during return; taunts cannot interrupt it (taunt termination above).
  This discourages repeated damage during retreat but does not make retreat kills impossible.
- **Arrival aggro/order reset (owner approved 2026-09-19):** on completing return home alive,
  clear that mob's remaining aggro points and engagement-order positions toward **every player**,
  once, alongside its full-HP recovery. During the journey, gains and decay continue normally;
  starting return is not a wipe. Other mobs' threat/order records are unchanged. Normal hostile
  detection and existing targeting priorities still apply; zero aggro grants no immunity.
  Damage after arrival builds fresh aggro and order normally, including subsequent poison/burning
  ticks, because arrival does not cleanse statuses.
- **Neutral forgiveness (owner approved 2026-09-27):** completing return home also clears
  that creature's provocation toward every aggressor. It becomes peaceful again; merely seeing
  the previous aggressor, directly or via pack awareness, cannot re-provoke it. A new damaging
  attack can provoke it again under the pack-response rule. Arrival is individual: it does not
  clear other packmates' provocation, threat or engagement order.

Approved batch application and unresolved subcases are tracked in §7 / `todo_decide.md §E`.
These documentation decisions do not authorize runtime or live-data changes.

Hybrid (D26): every creature has a `combat-role` (melee, ranged, mage, any-class, none) parsed from `creatures.json`
`role` text (humanoids may be `any-class`: one of melee/ranged/mage rolled per spawned group, weighted); melee is
today's reach attack. ranged / mage chase to a `range`, back off below a `keep-away` distance, need line of sight,
then wind up and fire a projectile (`design.creature-roles`, keyed by role and overridable per species — spitter,
snout-beetle) that damages through the target's normal dodge / block / i-frames and rolls its `applies` statuses on a
landed hit — poison is never avoided by dodge (§3.3 status-effects). A creature shot never damages another creature.
`c-creature-roles`.

### mob-strength-tier
S enemy power colour: white (150–250 HP, farm animals) < green < blue < purple (dungeon base) <
yellow (legendary; minotaurs, some collies). A equivalents: land level + `+1..+4` multiplier
and boss tag; landmark name colour white/blue/red vs player. → `instances/rarities.json#tiers`.

### 3.3 Combat

### resource
Depletable bar. `A S` → `instances/stats.json#resources`: hp, mp (0–100), stamina, block-power,
stealth, diving-breath `S`, pet-hydration `A`.

### stat
Derived number on characters and items. `A S` → `instances/stats.json#stats`: hp, attack-power,
spell-power, armor, resistance, crit, haste (alpha "tempo"), regeneration (stamina only, D11),
mana-regeneration `A`, block-power, weapon-rating & armor-rating `S` (average star tier),
power-level `A`, movement speeds (climb, swim, dive, ride, glide, sail), light-radius.
Rules: armor is subtractive with a 10 % floor (D15, `design.combat.armor-floor`); combo counter
ignores a growing share of armor; stats roughly double per rarity tier (display) vs ×2^0.25 in the
raw curve `?`.

### ability
An active or passive skill. `A S Ω` → `instances/abilities.json` (~65).
| prop | notes |
|---|---|
| kind | active \| passive \| shared-passive (alpha tree) \| movement |
| owner | class \| specialization \| all |
| versions | A / S / both; `removed-in-s`, `added-in-s` |
| input | S: m1, m2, m3-still, shift, shift-m1, shift-m2, shift-space, r, e, f, t, space; A: keys 1–4 |
| cost | mp / stamina / all-stamina / all-mp / none |
| cooldown-s, duration-s | |
| effect | structured summary + numbers (e.g. cyclone tick 0.25 s; fire missiles 4 × ≈3 SP) |
| alpha-tree | column, rank-needed (1 to unlock first, 5 in previous), per-point effect (D6: +5 % effect / −5 % cooldown per point, floor 25 %) |
| alpha-ability-id | cuwo id (21 kick, 34 healing-stream, 48 intercept, 49 teleport, 50 retreat, 54 smash, 79 sneak, 86 cyclone, 88 fire-explosion, 96 shuriken, 97 camouflage, 99 aim, 100 swiftness, 101 bulwark, 102 war-frenzy, 103 mana-shield) |
| applies | `status-effect` refs |
Runtime (D21): every class node and ultimate has a `design.abilities` entry naming one of six runtimes (dash, channel,
burst, buff, heal, projectile — D24: shots along the aim; a dash may `throw` shots first) with its numbers, cost (mp / stamina, a number or `all`) and cooldown; strikes apply the ability's
`applies` through `design.status-effects` (`c-ability-runtime`). Shared-column skills have no runtime here (swimming scales
swim speed; pet, mount, climb, glider, boat wait for their systems).

### weapon-type
Weapon family with handedness, class and moveset. `A S` → `instances/weapon-types.json` (21 alpha
subtypes; 17 usable).
| prop | notes |
|---|---|
| class | |
| hands | 1h-dual \| 1h-with-shield \| 2h \| offhand |
| damage-k | alpha curve multiplier: 2 dagger/fist/shield, 4 one-handed, 8 two-handed |
| cube-capacity | 16 (1h) / 32 (2h, shield) |
| combo-cap | fists 50, staff 50, longsword 30, bow/crossbow 30, wand 20, bracelets 20, boomerang 80 |
| m1 / m2 | moveset summary (e.g. bow M2 volley 4–5 arrows; dagger M2 ambush stun + poison) |
| material | wood (workbench) / iron (anvil) / gold-silver (bracelets) |

**Hybrid Wand item 1 (owner approved, 2026-09-28):** a wand is **mechanically two-handed**,
even if held visually in one hand. Equip one wand with **no other hand item**, including a
second wand or bracelet; the pose grants no off-hand capacity. Preserve its Mage restriction,
existing damage (`damage-k: 8`), beam attacks, combo rules and **32-cube upgrade limit**.
Under D6's existing two-handed size class, a **common wand costs 20 wood cubes at a workbench**
(`5 × 4`), with existing rarity-gem requirements unchanged. This selects a complete two-handed
loadout, not a one-handed pairing or a new damage/upgrade exception.

Documentation only: live `weapon-types.json#wand.hands` still says `1h (2h in wiki)`, parsed
as one-handed, and `recipes.json#gear-weapons.wand` still lists 10 wood cubes. Those provisional
values do not override this rule. Live-data migration, equipment/crafting/customization enforcement
and validation coverage remain separately deferred and unauthorized.

Hybrid (D24): `design.movesets.<weapon-type>.m1|m2` gives every class weapon its runtime — melee sphere (swing / radius mults,
spin around the player, lunge, finisher status), projectile (count, spread, speed, gravity, life, hit radius, splash, pierce,
return), beam (instant ray) or at-cursor (sphere where the aim lands); `c-moveset-config`. Alpha m1/m2 prose stays the source.

Hybrid (D25): `design.feel.events` bundles feedback per combat event (hit-stop, camera trauma, sound, damage number,
impact flash) — hit, crit, kill, hurt, block, dodge, shoot, impact; sounds synthesised from `design.feel.sfx` keyed by
`audio.json#sfx-alpha-ids` until real assets exist; `c-feel-config`.

### combo-system
Hit counter near cursor; +1 per landed hit; ignores growing share of armor and adds damage; any
whiffed attack resets; expires ~5 s idle; transfers between targets; per-weapon cap (turns blue with
"!"); enemies do the same. `A S`

Hybrid damaging-channel miss boundary (walkthrough item 10, owner approved 2026-09-17): judge
one whole channel, not individual ticks. Empty ticks do not trigger a miss reset. When the
channel ends, including an early end, reset combo for a miss only if no hit landed during that
channel. Normal inactivity expiry still applies throughout; successful-hit combo gains and
per-weapon caps are unchanged.

Hybrid zero-damage taunts (walkthrough item 10, owner approved 2026-09-17) are combo-neutral:
they neither increase nor reset combo, and do not refresh its inactivity timer, whether or not
any enemy is affected. Normal inactivity expiry still applies. Existing taunt/healing effects
are unchanged; this does not settle threat amounts or targeting rules.

Class-ability combo runtime authorization (walkthrough item 10, owner approved 2026-09-17):
repair missing non-projectile class-strike combo handling and add regressions for the above
rules. Reuse the existing landed-hit gain, inactivity timer and weapon cap; preserve damage,
costs, cooldowns, taunt/healing effects and projectile/weapon attack behavior. Empty channel
ticks never reset combo; a wholly missed damaging channel resets on normal or early end.
Zero-damage taunts remain neutral even with no targets. No other deferred work is authorized.

### special-attack
M2. Warrior/Ranger/Mage hold to charge (MP bar turns pink for the amount to be spent; more MP =
more damage and stun/knockdown chance); Rogue instant. Mage M2 costs 30 MP (S). `A S`

### combat-block
Defensive action, distinct from the terrain [block](#block).
Hold M2 with shield (Guardian: any weapon; any warrior during Cyclone); drains `block-power`,
regenerates when not blocking (faster during Cyclone); successful block gives MP (D11:
the bar specials spend); Guardian block power ×2. `A S`
Hybrid (D23): M2 held blocks and charges the special at once; numbers `design.defence.block`.

Hybrid exhaustion (walkthrough item 10, runtime repair authorized 2026-09-17): judge each hit
using the block-power available when it arrives. An eligible hit with positive power is blocked
normally, even if its cost empties the bar; its attached statuses remain blocked too. Subsequent
hits at zero power receive neither block reduction nor block MP rewards or status protection,
even before the next defence update. Other defences still apply. Preserve all block numbers,
regeneration, Guardian and Cyclone rules. Authorization covers only this repair and its regression;
panel-time, combo, broader slot-model and validator fixes remain separate, deferred work.

### dodge
M3 while moving: roll with i-frames (not vs spike traps / dagger poison), costs 25 stamina (25 %),
dismounts, negates fall damage on landing. Ninja gains +25 MP and guaranteed crit; Assassin gains
stealth. `A S`
Hybrid (D23): `design.defence.dodge` (roll 4 blocks in 0.4 s, i-frames 0.4 s; the crit window is not built).

### stealth
Separate bar: up to +20 % attack power, +50 % crit, faster MP gain, near-zero aggro at full;
decays when not generated; sources: sneak (faster still / in dark, slower in daylight / near
lamps), assassin specials, camouflage (instant full), sniper aim `A` / charging `S`. `A S`
Hybrid (D23): `design.defence.stealth` + `design.abilities.<id>.stealth-per-s|stealth-full`; no darkness / lamp rule until a game clock exists.
Hybrid threat behavior (approved 2026-09-27): full stealth means zero new damage-generated
threat, not a threat wipe or taunt cancellation; landing-time checks and DOT follow §3.2 `ai-behavior`.

### status-effect
→ `instances/status-effects.json`: poison, burning, slow/frozen (blue tint), stun (stars),
knockdown, knockback, taunt (red tint), stealth (transparent), possessed `S`, mana-absorption `S`,
petrified `S`, dizzy (glider crash), drowning `S`, injured `X` (2012 devlog death debuff),
buffs: battle-fury, berserker-rage stacks, torrent stacks, hit-series, fire-spark, intuition,
elusiveness-window, elixir ×4, beverage-resistance ×3, circle-of-power, mana-shield `A`, bulwark `A`,
war-frenzy `A`, scouts-swiftness `A`, camouflage, ninjutsu, shadow-shooter clone.

Hybrid poison (D26; narrow runtime repair authorized in walkthrough item 10, 2026-09-17):
scheduled poison damage is not prevented by dodge i-frames. Preserve poison's identity through
tick delivery even in the current shared burning-slot approximation. This repair changes neither
poison damage, duration or cadence nor current burning/direct-hit dodge behavior. Separate poison
stacking, independent burning/poison slots and other runtime corrections are outside this authorization.

### death
No penalty in A or S (no gold/item/XP loss). A: press R → nearest revival statue (never far), enemy
HP resets. S: only to an *activated* shrine of life; boss HP resets unless shrine is close.
`X`: 2012 "injured" debuff (reduced max HP, band-aids, cured by eating).

### 3.4 Items

### item
Concrete item instance (alpha `ItemData`, 88 bytes). `A S`
| prop | type | notes |
|---|---|---|
| type, sub-type | `item-type` ref | |
| modifier, minus-modifier | u32 | seed for stat roll (roll = ((attributes<<16)+modifier) % 21) and name |
| rarity | `rarity` ref | 0..4 (5+ mythical bug) |
| material | `material` ref | |
| flags | u8 | adapted etc. |
| level | i16 | A power +1..+100 (+ for consumables/formulas too); S hidden, region-bound |
| upgrades[32] | `item-upgrade` | x,y,z i8 + material + level: placed cubes |
| upgrade-count | u32 | |
| land | `land` ref | S: origin region (region lock) |
| plus | bool | S: `+` suffix; works in adjacent lands |
| name | derived | `item-name` generator |

### item-type
25 alpha main types with subtypes. → `instances/item-types.json`.

### material
31 material ids incl. 4 spirits. → `instances/materials.json`. Fields: class restriction, station,
raw → refined chain, unobtainable flag (`X` bone, saurian, mammoth, obsidian, parrot).

### rarity
7 tiers: worn `S` (grey; degraded), common (white ★), uncommon (green ★★, emerald), rare (blue
★★★, sapphire), epic (purple ★★★★, ruby, named), legendary (yellow ★★★★★, diamond, named),
mythical `A X` (bug). Same scale colours enemies and missions. → `instances/rarities.json`.

### affix
Name prefix per rarity tier + "of <Name>" / "<Name>'s" for epic/legendary. → `instances/affixes.json`.

### equipment-slot
13 indexed entity storage positions, including reserved `unknown-0` (not usable). The 12 usable
positions are amulet, chest, gloves, boots, shoulders, main-hand, off-hand, ring-left, ring-right,
lamp, special and pet. Preserve every index in `instances/equipment-slots.json`; no extra slot
or stat bonus is added. The quick consumable (Q) is separate: selecting it does not displace gear.

Approved hybrid model (reconciliation item 3, 2026-09-15): `accepts` names `item-type` IDs,
with subtype restrictions where needed:
- `lamp` accepts `light` (subtype `lamp`).
- `special` accepts `special` (subtypes `hang-glider` or `boat`), one equipped at a time.
- Hand slots accept `weapon`; shields are weapon subtypes, not a separate item type.
  Existing class and handedness restrictions still apply (`c-weapon-class`, `c-hands`).
- `pet` accepts a `pet-cage` or `pet-food` during taming, without replacing the Q selection.
- Armor and jewelry retain their matching slots; `unknown-0` accepts nothing.

The item-3 slot-model approval is ontology-only: normalizing live slot JSON and its consumers
awaits separate authorization (`docs/ROADMAP/todo_decide.md §E`). Wand handedness is approved
under `weapon-type`; traversal approvals are recorded separately under `skill-tree` / `pet`.
Gliding/sailing require the respective Hang Glider/Boat equipped in `special`, not merely bought
(traversal items 2–3, approved 2026-09-28). They share that single slot; no dual equip or new slot.

Hybrid hand-conflict repair (item 10, authorized 2026-09-17): reject an equip attempt that would
pair a two-handed weapon with a shield, regardless of equip order. Leave existing equipment and
the attempted item in the bag unchanged; do not auto-unequip, delete or duplicate either item.
The repair uses loaded handedness classifications without changing them; it did not settle the
then-provisional wand classification. The later Wand item 1 rule is recorded under `weapon-type`;
its live-data migration remains deferred. Valid one-handed-plus-shield setups, two-handed weapons
alone and non-conflicting slot replacements keep working. This authorizes only the conflict
repair and regressions, not the broader slot model, class restrictions, dual-wield routing,
Guardian/Cyclone blocking changes, or the later Wand item 1 migration.

### consumable
Food (sit, immobile, heal over 15 s), potion (channel while moving), elixir `S` (10 min +20 % stat),
beverage `S` (10 min hazard resistance), bomb (100-HP fuse "pet" entity, breaks boulders, chains,
hurts players; A +1/+5/+10). → `instances/consumables.json` with recipes.
Heal formula A: `item-base-hp(n, rarity) × 200` (life/cactus potion, ginseng soup, snowberry mash,
mushroom spit) or `× 100` (pineapple slice, pumpkin muffin).

### ingredient
Gatherable, drop or refined crafting material. → `instances/ingredients.json`.

### recipe
Inputs → output at a station. `A S` → `instances/recipes.json` (gear quantity table by rarity ×
slot, food, potions, elixirs, beverages, refining, rings/amulets, water flask).

**Hybrid books/formulas item 2 (owner approved, 2026-09-28):** books and formulas teach into
one character recipe collection (`known-recipes` / `knows-recipe`), not separate source-specific
unlocks. Learning the same recipe twice grants nothing extra. A book teaches **only its unknown
recipes**, with **no rerolls or compensation** for known ones; four recipes with three already
known teach one. Attempting to learn an **already-known formula leaves the scroll unconsumed**.
Overlap can make later books less rewarding. This chooses no recipe-generation or identity defaults.
A known recipe need not be usable: book-recorded recipes may be power-locked (`power-gate`, item 3).
Live-data migration and recipe-learning implementation remain deferred.

### crafting-station
7 stations + campfire + "anywhere". → `instances/crafting-stations.json`.

### formula
`A` recipe scroll (item type 2) with +N level; sold by vendors, dropped by tier, on dungeon tables;
right-click to learn once power suffices. Historically replaced in S by `book-of-crafting`;
both sources remain in hybrid and share recipe knowledge/duplicate handling (`recipe`, item 2).

### book-of-crafting
`S` 4 per land (uncommon/rare/epic/legendary), 3–4 recipes each, from hammer-icon missions; only
recipe source; recipes land-scoped. These are historical S rules, not hybrid exclusivity or scope.

**Hybrid books/formulas item 1 (owner approved, 2026-09-28):** books and formulas both remain
in the hybrid game. Recipes learned from books are **permanent for that character across lands
and sessions**; moving to another land never requires relearning them. Persistence item 1
(§3.7) extends character recipe knowledge across worlds, without shared-account knowledge. Crafting materials and
equipment strength are unchanged. Shared knowledge/duplicates follow `recipe` item 2;
immediate recording and power-locked crafting follow `power-gate` item 3.
Live-data migration and implementation remain deferred.

Hybrid one-time book-source claims are personal per saved world (`save-data`, persistence item 5).

### customization-bench
Attach `material-cube`s (wood on wood, iron on metal; +0.1 effective level each; 16/32 cap) and
`spirit-cube`s `A` at 3-D positions on the weapon model (rotate with M3, drag cubes). Removal
destroys the cube.

### spirit-cube
`A` boss drop: one per eligible non-mission boss kill, always the same type/level per boss.
Fire (+fire damage), wind (+attack & move speed per combo hit), ice (slows target, blue), unholy
(life steal on specials scaling with combo). Level must satisfy
`weapon-level − 10 ≤ cube-level ≤ weapon-level`.

Hybrid retains the recorded alpha exception (reconciliation item 7, approved 2026-09-15):
mission bosses, including Saurians, drop no spirit cube; their normal mission rewards are
unchanged. Sources: `creatures.json#saurian`, `mission-types.json#alpha.boss-kill`.

### leftovers
Unidentified gear drop (type 14) with tier colour and +N; identified for a fee at the identifier
(A) / analyst (S); may roll one tier higher; land-bound `S`. `A S`

### adaptation
`A` adapter re-levels an item to the player's power for `platinum-coin`s (boss/mission reward);
lowering is free. Removed in S.

### pet-food
Item type 20. `tames` identifies explicitly approved creature species by stable ID; each creature
still has at most one `tame-food`. Normally a food names one species and its numeric subtype
matches that species' known source entity ID, including post-alpha IDs (`c-food-id`).

**Shared-food exception (family item 9, approved 2026-09-27):** Bubble Gum names both `collie`
and `skeleton-dog`. It remains one food item, with subtype **19** anchored to Collie's source ID;
this neither assigns 19 to Skeleton Dog nor invents its unrecorded source ID. All other food
pairings and numeric identities remain unchanged; membership in `dogs` grants no bait pairing.
One of each food carried at a time still applies, not one Bubble Gum per target species.
Live `pet-food.tames`, model/loader and validator remain single-species; migration is deferred.
→ `instances/pet-food.json` (58 obtainable + 5 cut `X`).

**Validation-contract source item 5 (owner approved, 2026-10-04):** this count follows the
58 `foods` and five `cut` entries. The older six-food cut lists in
`research/research_items.md §5` / `research/research_creatures_quests.md §2.7` include Banana
Mash; F11 keeps it obtainable for Warthogs. Correcting the summary changes no food, pairing
or availability and supplies no missing sixth cut entry.

**Validation-contract mapping item 2 (owner approved, 2026-09-28):** record provenance
individually for each food from evidence, not a blanket family default or copied target-creature
history. Unsupported historical claims remain explicitly unresolved; the loader's current A+S
fallback for untagged foods is not provenance authority. Preserve existing sourced facts and all
approved taming pairings, including shared Bubble Gum, availability/prices and numeric source IDs
(`c-food-id`). Adding Skeleton Dog as a target does not rewrite Bubble Gum's history. This policy
assigns no new A/S/X labels. Per-food source research remains unfinished; live-data/model/loader/
validator migration remains separately unauthorized.

**Validation-contract source item 6 (owner approved after clarification, 2026-10-04):**
**evidence** is a traceable source supporting a specific claim, possibly incompletely;
an **assumption** extends beyond what it establishes. Record the supported claim, source and
limits here; unsupported release history stays unresolved, not converted into A/S labels.
At item 6's historical checkpoint, retained research was the evidence inspected, not fresh
verification of cuwo, binaries or external pages. Item 12 below adds direct cuwo inspection;
the mixed pairing table still does not establish every food's A+S release presence.

| foods / existing annotations | supported evidence | unresolved limits |
|---|---|---|
| 47 of the 48 untagged `foods` (all except `eucalyptus-candy`) | `research/research_items.md §0.2`, type 20, explicitly names these foods under its Alpha identifier-table heading, attributed to cuwo ITEM_NAMES / coremaze. Naming, not numeric range, supplies this local Alpha lead. | No proof here of working Alpha taming, introduction dates, A-only or A+S release presence; no new blanket annotation. |
| `eucalyptus-candy` (untagged) | `research/research_items.md §5` reports replacement of unused Kaliptus Leaf; both JSON notes retain that relationship. | Not named in §0.2; replacement date and A/S history unresolved. Omission is not proof of Alpha absence. |
| Ten existing S foods: `buckhorn`, `banana-mash`, `mineral-water`, `spring-water`, `peanut`, `chocolate-ice-cream`, `raspberry-juice`, `mixed-salad`, `radicchio-salad`, `cabbage-rolls` | Preserve `pet-food.json#foods` annotations. §5 additionally reports Banana Mash “listed obtainable by 1.0 guides”, with pooled wiki/Steam/Gamepressure citations. | This pass does not independently confirm all ten histories. Banana Mash has reported Steam-era obtainability, not an established first appearance or proof of Alpha absence; F11's approved obtainability stands. Creature tags/IDs do not date their foods. |
| Five existing X foods: `apple-pie`, `liquid-drop`, `charred-steak`, `wasabi-sauce`, `kaliptus-leaf` | Preserve `pet-food.json#cut`; §5 and `research/research_creatures_quests.md §2.7` name these cut/unused foods (item 5 resolves their lists' Banana Mash conflict). | X does not establish a calendar date or A/S ancestry; Kaliptus Leaf's replacement chronology is undated. |

No availability, pairing, taming, price, source ID, loader default or checker changes follow
from this evidence record. Food release-history research remains incomplete.

**Validation-contract source item 12 (owner approved, 2026-10-04):** directly inspected cuwo
revision **`240bb61ec42abb10a73d750ce72f243e04e55509`**
[`strings.py:2758–2913`](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/cuwo/strings.py#L2758-L2913)
contains specific food names at the slots of **47 of the 48 currently untagged foods**;
Eucalyptus Candy's current subtype **89** instead says generic **`Bait`**. This strengthens
item 6's retained naming lead by verifying this open-source server reimplementation's table,
not original Alpha/Steam obtainability, working taming, introduction dates or release presence.
Generic `Bait` proves neither Alpha absence, replacement timing nor unused status; numeric IDs
alone do not date content. Source spellings such as `CinnamonRole` / `BiscuitRole` authorize no
ID/display-name changes. No cuwo code is added to pixlnd and no new A/S labels follow.
Existing pairings, including Bubble Gum's Collie/Skeleton Dog exception and subtype 19 anchor,
availability and all approved rules stand.

**Validation-contract source item 13 (owner approved, 2026-10-04):** conflicting Koala-food
reports are explicit: Steam guides [1873333729](https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729),
[1865509515](https://steamcommunity.com/sharedfiles/filedetails/?id=1865509515) and
[1879943518](https://steamcommunity.com/sharedfiles/filedetails/?id=1879943518) name
**Eucalyptus Candy → Koala**; [Gamepressure](https://www.gamepressure.com/cubeworld/taming-and-locating-pets/zfca65)
says **Kaliptus Leaf → Koala**. The inspected current-body captures were retrieved
**2026-10-04T17:17:23–25Z** in the prior session, re-inspected here, not re-fetched by this
writer or archived original publication bodies. Displayed publication/update dates do not date
row additions; reports are not proven independent. Guide 1865509515 retains pet-XP wording,
so its body is not uniformly version-clean. `Unknown`, `?` and `NO` occupy biome/rideability
columns, not taming-efficacy judgments. None establishes replacement timing, unused status or
demonstrates working taming. **Eucalyptus Candy remains Koala's food; Kaliptus Leaf remains
cut**. The retained replacement note stands with chronology unresolved; no guide reverses it
or changes source labels, availability or hybrid rules.

**Validation-contract source item 14 (owner approved, 2026-10-04):** individually attribute
these **ten already S-annotated foods** to the inspected guides' food/pet columns. Guide links
and current-capture qualifications are in item 13 above; these are community reports only.

| existing food | reported pet | Steam guide ID |
|---|---|---|
| Banana Mash | Warthog | 1865509515 and 1879943518 |
| Buckhorn | Beaver | 1873333729 |
| Cabbage Rolls | Snail | 1873333729 |
| Chocolate Ice Cream | Baby Mammoth | 1873333729 |
| Mineral Water | Radishling Sprout | 1873333729 |
| Mixed Salad | Caterpillar | 1873333729 |
| Peanut | Baby Elephant | 1873333729 |
| Radicchio Salad | Earth Caterpillar | 1873333729 |
| Raspberry Juice | Flamingo | 1873333729 |
| Spring Water | Cormling Sprout | 1873333729 |

These reports establish neither first appearances, Alpha absence, per-food obtainability nor
demonstrated successful taming. They do not date individual row additions or prove independent
reports or exclusively S history. Existing S annotations are preserved, not newly inferred or
confirmed. Rideability columns do not override **F2**. All pairings, labels, prices and IDs,
**F11's obtainable Banana Mash**, shared Bubble Gum and hybrid rules remain unchanged.

**Validation-contract source item 16 (owner approved, 2026-10-04):** the archived community
[Koala page](https://web.archive.org/web/20130708192756/http://cubeworldwiki.net/index.php/Koala),
snapshot **20130708192756**, revision **4032**, has an **empty Food cell**. It supplies no food
identity. Its Rideable cell is also empty, with no inference overriding F2; classifying Koala
as a pet is not demonstrated taming. The snapshot date and displayed last edit (7 July 2013,
13:47) do not date either bait's introduction or replacement. This report proves neither Alpha
absence, either bait's obtainability nor successful taming. **Eucalyptus Candy remains Koala's
bait; Kaliptus Leaf remains cut**, with chronology unresolved (items 6/12–14). The source-scout
capture was retrieved 2026-10-04 and inspected here, not re-fetched or behavior-tested by this
writer. No pairing, availability, source label or hybrid rule changes.

**Validation-contract source item 30 (owner approved, 2026-10-04):** Patricia Hernandez's
currently retrieved [Tips For Playing The Cube World Alpha](https://kotaku.com/tips-for-playing-the-cube-world-alpha-885739884)
explicitly credits its ten pet/food reports to the
[Cube World Wiki](http://wiki.cubeworldforum.org/index.php?title=Pets). Exact list text:

> Bunny: Carrot
> Chicken: Cereal bar
> Hornet: Popcorn
> Mole: Chocolate Donut
> Monkey: Banana split
> Peacock: Chocolate cookie
> Sheep: Cotton candy
> Squirrel: Strawberry Cake
> Terrier: Waffle
> Turtle: Cinnamon role

The source's **“Cinnamon role”** is retained only as quotation, not a local name/ID correction
or different pairing. Metadata gives publication **2013-07-23T23:00:00+00:00** and modification
**2025-07-11T00:15:25+00:00**; this edited current body is **not an authenticated 2013 body**.
Saved raw HTML, list/metadata and capture sidecars were inspected here; source-scout request-start
**2026-10-04T22:31:56Z** is not response completion. No external re-fetch or original-build testing.
An Alpha-focused pairing report is not independent per-food testing or proof of the initial
publication's list, first appearance, obtainability or demonstrated successful taming. Generic
enemy-drop/shop advice establishes no per-food acquisition or guaranteed stock. Existing food
pairings, availability, prices, IDs and all hybrid rules stand; no new A/S labels or taming/stock
mechanics follow. Individual food histories remain research.

**Validation-contract source item 31 (owner approved, 2026-10-04):**
[Kaliptus Leaf revision 10086](https://cubeworld.fandom.com/wiki/Kaliptus_Leaf?oldid=10086),
edited **2014-07-20T23:29:44Z**, associates Leaf with Koala and reports it **“currently
unobtainable in this version”**, but obtainable **“with cheats”**. **“This version” is
unidentified**; the food/taming wording is not demonstrated cheat-fed taming or original-build
functionality. Neither the edit date nor earliest returned revision dates Alpha/Steam presence,
introduction or when Eucalyptus Candy replaced Leaf.

Saved raw revision body/metadata and capture sidecars were inspected here, not externally
re-fetched, cheat-executed or original-build tested. Source-scout request-start
**2026-10-04T22:32:19Z** is not response completion; documentary edit timing is not release
history. **Eucalyptus Candy remains Koala's bait; Kaliptus Leaf remains cut** (items 6/13/16).
Replacement chronology, per-food obtainability and successful original taming remain research.
No pairing, availability, source label, ID or hybrid rule change follows.

**Validation-contract source item 32 (owner approved, 2026-10-05):**
[Pet Food revision 20438](https://cubeworld.fandom.com/wiki/Pet_Food?oldid=20438), edited
**2025-10-15T03:26:50Z**, says **“Each town has one type of pet food per day”**. This
community report identifies a **stocked food type**, not how many units can be purchased:
stocking only Carrots says nothing here about how many carrots can be bought. The sentence
identifies no Alpha/Steam build or release history. It selects neither a one-unit purchase
limit nor unlimited purchases; the separate **one-of-each-food carrying rule remains unchanged**.

Saved raw revision body/metadata and capture sidecars were inspected from the prior scout's
2026-10-04 capture, not externally re-fetched, image-inspected or original-build tested.
Edit/capture timing is not release evidence. The page's stale Banana Mash-unused and
single-pet-per-food clauses cannot override **F11's obtainable Banana Mash** or **shared
Bubble Gum for Collie/Skeleton Dog**, with subtype 19 anchored to Collie. Daily quantities
and individual food histories remain research; no stock, purchases, pairing, availability,
prices, IDs, source labels or live declarations change.

**Validation-contract source item 37 (owner approved, 2026-10-05):**
[Steam guide 1879943518](https://steamcommunity.com/sharedfiles/filedetails/?id=1879943518)
says **“For example, I found a Lollipop from an Emerald Deposit!”**. This is the narrator's
acquisition report, not an authenticated drop table, guaranteed mining reward, drop odds,
first appearance or demonstrated successful taming. **Lollipop → Owl remains unchanged**;
Lollipop is not Snout Beetle's **Lolly**.

The saved raw guide body/sidecars were inspected from the retained **2026-10-04T17:17:25Z**
capture, not externally re-fetched or original-build tested. Source/edit/capture dates do not
authenticate release history. Per-food obtainability/taming histories remain research; no loot,
pairing, availability, prices, IDs, source labels or live declarations change.

**Validation-contract source item 38 (owner approved, 2026-10-05):**
[Steam guide 1879943518](https://steamcommunity.com/sharedfiles/filedetails/?id=1879943518)
reports differing village offerings and gives the literal list **“candy, carrot, bubble gum,
chocolate donut, waffle, cotton candy”**. **Candy remains ambiguous**, not a guessed Sugar
Candy or Sugar Cube identity. The list is neither exhaustive stock nor a promise that every
village offers all six, and supplies no purchase-quantity rule. The nearby **one-coin price
is for empty flasks, not these foods**.

Saved raw body/sidecars and capture limits follow item 37. This report does not select stock,
prices or carrying rules or date individual foods. Existing one-of-each-food carrying,
F11 Banana Mash, shared Bubble Gum and all pairings stand; no labels or live-data changes.
Daily quantities, food identities and release histories remain research.

### key-item
`S` land-bound "special" items (A: glider & boat were bought items in the special slot).
→ `instances/key-items.json`: hang-glider, boat, reins, climbing-spikes (movement, 4/land);
divine-harp, sky-whistle, spirit-bell (ticket, 3/land); treasure-spirit, eternal-ember,
iron-lamp (`A` item / `S` innate F ability), dungeon keys (gold/silver/copper/boss keys), flute
(auto-owned, activates shrines), alpha special-accessory data `X` (key, jewel case, medicine,
antivenom, band-aid, crutch, bandage, salve).

Hybrid key items work globally once acquired (`c-gear-global`); the land-bound S records above
are historical reference. Reins are required alongside training and a rideable tamed pet
(`pet`, traversal item 1), not an alternative to either. No Reins slot or new acquisition route
is approved. Hybrid gliding/sailing need the respective vendor-bought, equipped Hang Glider/Boat
plus training (`skill-tree`, traversal items 2–3); A/S acquisition records do not override these rules.

**Hybrid traversal item 4 (owner corrected, 2026-09-28):** globally acquired **Climbing Spikes
reduce climbing stamina consumption by 75%**, rather than eliminating it. Basic climbing and
Climbing points' drain reduction follow `skill-tree`. The infinite-climbing/no-stamina S behavior
in `key-items.json#climbing-spikes` and `abilities.json#climb` is reference only, not a hybrid
target. Live-data migration and runtime enforcement remain deferred.

**Hybrid traversal item 5 (owner approved separately, 2026-09-28):** apply Spikes **after the
Climbing skill reduction**: `climbing cost with Spikes = skill-adjusted climbing cost × 0.25`.
Do not add 75 percentage points to the skill reduction. Illustrative only, not balance defaults:
if skill reduces a climb's cost from 10 stamina to 8, Spikes reduce 8 to **2**, not 0.5.
Climbing points retain their drain-reduction benefit alongside Spikes; Spikes alone do not turn
a positive skill-adjusted cost into zero. This defines neither the skill reduction curve/floor
nor artifact-combination semantics.

### artifact
Relic collectible from `S`; permanent and works everywhere; hybrid count is 1–3 per land (D11).
Named "<Ring|Stone|…> of <Name>", bound to a realm; found at dungeon ends, vaults, sewers,
sky islands and some mission chests. **S reference only:** each relic granted +1 level;
riding/climbing/gliding bonuses were reportedly non-functional in 1.0 (functional in hybrid, D6).
Static entity id 46 "Artifact" exists in alpha data `X`.

Hybrid artifact-source claims are personal per saved world (`save-data`, persistence item 5).

**Hybrid artifacts item 1 (owner corrected, 2026-09-28):** count contributors **separately
for each traversal stat**, not globally across traversal kinds. All collected artifacts that
contribute to the same stat share its **current contribution equally**; acquisition order does
not preserve earlier, larger grants. Collecting a different traversal kind does not reduce
this stat's contributors' rate. The initial exponential equal-share examples are superseded
by item 5's logarithmic total below.
This artifact-count mechanism does not extend to other item kinds. Existing level/rarity
curves, power gates and other non-artifact rules remain unchanged; inspect and ask before
changing any existing reduction mechanism.

**Hybrid artifacts item 2 (owner approved, 2026-09-28):** contributions to an affected stat
**add**, never multiply or compound artifact-on-artifact. Let `B(x)` be the **fractional total
bonus** from its `x` contributing artifacts. For `x > 0`, each artifact's equal current share
is `B(x) / x`; their sum is `B(x)`, not `x × B(x)`. The total curve is recorded separately in item 5.

**Hybrid artifacts item 3 (owner approved, 2026-09-28):** first compute the affected stat
normally **without artifacts**, including applicable level, equipment, skills and buffs.
Then `stat with artifacts = current artifact-free stat × (1 + B(x))`. Recalculate when
ordinary stat inputs change; never snapshot the stat at pickup. This adds no stat target
or unrelated effect.

**Hybrid artifacts item 4 (owner approved after clarification, 2026-09-28):** every artifact
still grants **exactly one** of the seven existing traversal kinds (`climb-speed`, `swim-speed`,
`diving-skill`, `ride-speed`, `glide-speed`, `sail-speed`, `light-radius`) **plus attack and
maximum HP**. Attack and maximum HP use the **same recalculation** as traversal, each counting
**all collected artifacts**, because every artifact grants both. Each traversal stat counts
only its matching artifacts, separately. Artifacts grant no character levels and bypass no
existing traversal training/item gates; no equipment slot is added.

**Hybrid artifacts item 5 (owner approved with initial z=0.1, 2026-09-28):** for the affected
stat's **nonnegative integer count** `x`, the fractional total bonus is:

`B(x) = 0.05 × ln(1 + z × x) / ln(1 + z)`, with `z > 0`; **initial z = 0.1**.

`B(0) = 0` (no stat change), `B(1) = 0.05` (5%). Totals strictly increase as more contributing
artifacts are collected, with diminishing marginal gains and **no hard cap**. Equal current
shares follow item 2, and the current-stat multiplier follows item 3. Larger positive `z`
gives stronger diminishing returns; `z` is adjustable for balance. The normalized logarithm's
base cancels, so there is **no separate y tuning knob**.
Rounded total examples at z=0.1: two contributors give **9.565%**, three
**13.764%**; these are totals, not individual grants.

**Hybrid artifacts item 6 (owner approved, 2026-09-28):** **remove the old per-artifact 1%
floor**. The approved logarithmic curve replaces D6's ×0.9 accumulation/decay rule and its
floor; there is no hidden clamp, minimum per-artifact contribution or minimum marginal gain.
The first artifact remains 5%.

Documentation only: live `generators.json#design.artifact` still stores D6's `first: 0.05`,
`decay: 0.9`, `floor: 0.01`; `key-items.json#artifact` still mixes historical S levels with
old D6 accumulation text, and `rulesets.json#ruleset-hybrid._rule` still says D6 bonuses are
unchanged. These do not override the current rules above. Direct replacement of obsolete checked-in values,
model/loader/validator support and generated-artifact/runtime enforcement remain deferred and
unauthorized; no legacy format or migration support is required (§0).

### currency
A: copper/silver/gold (100:1), platinum (adaptation only); S: single coin counter, auto-pickup by
walking. Prices/incomes in `instances/economy.json`.

### shop
Vendor with stock rules. → `instances/economy.json#shops` (weapon, armor, item/general, identifier,
gem-trader `S` roaming, inn, guild, flight-master, adapter `A`). S: stock rarity capped by rescued
gnomes; restock daily; buy-back tab; A: sales final, +1..+100 stock.

### inventory
The per-character bag and worn gear. `A S`
| prop | type | notes |
|---|---|---|
| entries | (`item`, count)[] | no slot limit; count > 1 only for stackable item-types (`design.stack-cap`, c-stack-rule) |
| equipment | `equipment-slot` → `item` | at most one item per usable slot; type/subtype restrictions in `equipment-slot` (c-slot-accepts); excludes the separate Q selection |
| coins | u32 | copper (`currency`); auto-picked up (`design.loot.ground`) |
| start | `design.starting-inventory` | D18: starter weapon equipped + 5 life potions |

Stacks have no cap (D6; one of each pet food). Tabs: equipment, special `S`,
items, ingredients, pets, artifacts `S` (A: amulets tab). S: one page per visited land. Key: B (or I `A`).
Quick-select wheel (Tab, A/D) chooses the Q item.

### loot-rule
Drops random by enemy tier ±1 (bosses +1 `S`); leftovers of player tier from same-colour
enemies; species drops; A eligible non-mission boss: spirit cube + gear of same +N;
mission bosses (including Saurians) drop no spirit cube in A / hybrid, keeping their normal
mission rewards; +4 dungeon chest → mythical `A X`;
S mission reward ≥1 class-fitting piece one rarity above quest colour + coins + 1 potion + gems;
dropped items last ~1 game week; mission NPCs drop rewards once. → `generators.json#loot`.
Open-world numbers (drop chances, rarity weights, level spread, ground lifetime, pickup radius):
`generators.json#design.loot` (D18).

### 3.5 Progression

### ruleset
Feature-flag bundle selecting alpha or steam progression. → `instances/rulesets.json`.

### level-formula `A`
`power(lvl) = (101·lvl − 81)/(lvl + 19)` (cap +100 at lvl 1981); `xp-to-next(lvl) = int(1050 −
1000/(0.05·(lvl−1)+1))`; `base-hp(lvl) = 2^((1 − 1/(0.05·(lvl−1)+1))·3)`; player HP = base × 2 ×
max-hp-multiplier; class HP multipliers warrior 1.30 (guardian ×1.25 more), ranger 1.10, rogue 1.20,
mage 1.00; 2 skill points per level; no level cap (int32). XP per kill: `design.progression` (D19).

### skill-tree `A`
11 slots. Shared chains (5 points unlock next): pet-master → riding; climbing → hang-gliding;
swimming → sailing. Class column: skill-1 (1 pt) → skill-2 (5 in skill-1) → skill-3 spec-specific
(5 in skill-2). Points reduce cooldown and scale one effect: +5 % effect and −5 % cooldown per
point, cooldown floor 25 %, uncapped (D6). Respec at class trainer.
Hybrid (D10): a 4th `ultimate` column per class holds the Steam R skill, unlocked by 5 points in
the spec's rank-3 skill; the six alpha-removed rank-3 skills return in their class column.
Assassin's single-skill exception is defined below.
Spending (D20): one banked point per click on the X screen (`ui.json#screens.skills`, `keybinds.json#hybrid.skills-window`);
a node opens when the previous node of its column holds `alpha-tree.needs` points (roots 0); class ranks 1–3 + ultimate
fire on keys 1–4 (their runtimes: `design.abilities`, D21); per-point multipliers `design.skill-point`;
respec at the class trainer refunds every point to the bank for a fee (`design.settlement.trainer`, D22).

**Hybrid Assassin item 1 (owner approved, 2026-09-28):** Camouflage's alpha rank-3 skill and
Steam ultimate are **the same ability**, not separately purchased copies. After **5 Sneak
points**, spend at least **1 Camouflage point** to use it on **key 3**. Assassin has **no
separate fourth node or key-4 ability**, even after five Camouflage points; `also-ultimate`
denotes the shared source identity, not another unlock. There is one point investment, one
cooldown and one buff, with no extra charge or duplicate purchase. Keep Camouflage's existing
effect, duration, cooldown, per-point scaling and approved stealth/threat rules unchanged.
This is an explicit Assassin exception to D10's separate ultimate node; other specializations
and the remaining D10/D20 rules stand. The player has three distinct class skills rather than
paying twice for the same skill. Current key-3/no-key-4 runtime already matches; live metadata
clarification and validation coverage remain separately deferred, not authorized by this approval.

Hybrid traversal item 1 (approved 2026-09-28): the riding chain also requires global Reins
and a rideable tamed pet; training and further-point speed benefits follow `pet` / `c-riding`.

**Hybrid traversal item 2 (owner approved, 2026-09-28):** gliding requires **5 Climbing
points + at least 1 Hang Gliding point** and an **equipped Hang Glider bought from an item
vendor**. Further Hang Gliding points improve glide speed. Buying alone is insufficient;
the glider occupies the existing single `special` slot, not an extra slot. Live-data migration
and runtime enforcement remain deferred.

**Hybrid traversal item 3 (owner approved, 2026-09-28):** sailing requires **5 Swimming
points + at least 1 Sailing point** and an **equipped Boat bought from an item vendor**.
Further Sailing points improve sailing speed. Buying alone is insufficient; equip the boat
instead of the glider in the existing single `special` slot, never both. Live-data migration
and runtime enforcement remain deferred.

**Hybrid traversal item 4 (owner corrected, 2026-09-28):** basic climbing requires **neither
skill points nor Spikes**. Climbing points reduce stamina drain; global Spikes reduce climbing
stamina consumption by **75%**, not an exemption from stamina costs (`key-item`). Five Climbing
points remain the Hang Gliding prerequisite under item 2. This principle does not define the
skill reduction curve/floor. Item 5 separately applies Spikes to the remaining skill-adjusted
cost (×0.25), not additive percentage points (`key-item`).

### power-gate `A`
Item `+N` usable at full strength only if player power ≥ N; formulas learnable likewise.

**Hybrid books/formulas item 3 (owner approved, 2026-09-28):** books record their unknown
recipes **immediately, regardless of current power**. A recipe above the character's power
remains **known but visibly locked against crafting until that power requirement is reached**.
It is a future crafting goal, not immediate crafting access. Formula learning retains its
existing sufficient-power requirement; books do not bypass recipe progression or change item
strength, materials or station requirements.

Known-but-locked recipes count as known for item 2's duplicate rules: another book teaches
nothing extra for them, and an already-known formula remains unconsumed. Neither source removes
the power lock or grants compensation for a duplicate. Runtime/UI enforcement and live-data
migration remain separately deferred and unauthorized.

### region-lock `S` — **DROPPED (D4)**
Reference only. In 1.0 gear, leftovers, bombs' loot and key items were bound to origin `land`;
outside they became worn/grey (e.g. 194.1 → 5.4 dmg) or stopped working; `+` items kept full stats
in adjacent lands. The hybrid ruleset removes all of it: `item.land`, `item.plus`, `rarity.worn`,
`land.inventory-page` and constraints `c-region-lock` / `c-plus-adjacent` are inert.
Permanently excluded from pixlnd: never propose or implement regional gear power loss, even
for cloning fidelity (owner reaffirmed 2026-09-15, §1).

### lore `S`
Per realm; lore sites ≈ +10 % each; 100 % reveals all its artifacts on the map (all its lands);
`+` loot from 100 % is moot (F3: `+` items dropped with region lock).

### gnome-supplier `S`
4 captives per land at white/green/blue/purple missions; each rescue raises shop stock one rarity.
Hybrid rescues benefit the saved world, not only the rescuer (`save-data`, persistence item 4).

### circle-of-power `S`
Kill restless warrior (5★) → eternal ember → light brazier → land-wide power buff (+10 % attack, +10 % max HP, D6);
several per land; one ember per participant.

### 3.6 Missions

### mission-type
→ `instances/mission-types.json`. Alpha: boss kill at a dungeon or terrain landmark (crossed
swords), 8×8 cells per region, regenerates daily, rewards XP + platinum + items, green speech
bubble villagers point to it. Steam (~25): combat/invasion, gnome supplier, book of crafting,
wizard tower/magic barrier, circle of power, demon portal/altar, mana pump, mana inductor, mana
tree, grand boss (skull), arena, artifact dungeon (orange circle), key item (item icon), old hut
witch, captured NPC, molehill / bone pile / hornet nest / slime well, faction encounters (unholy
pact, dark cultists, obsidian knights, order of light, druids of mana, steel empire), camps,
vaults, sky islands, lore sites, hidden treasure.
| prop | notes |
|---|---|
| icon | map glyph |
| tier | white/green/blue/purple/yellow (hidden white until visited on foot `S`) |
| repeat | daily / once per land |
| reward | see `loot-rule` |
| structures | poi/dungeon refs |

### arena `S`
5 waves: W/G, W/G, G/B, B/P, P/Y boss; any species (saurian, mammoth, yeti, mana mech, spectrino
pairs); hosted by a Bloodaxe orc; resets daily; 18–50 coins + gear; more common in oceans.

### 3.7 Meta

### multiplayer-mode
Hybrid (D5/D7): dedicated server, alpha style; max players configurable, default 4.
Shared-clock inn sleep consent/payment follows `game-clock` item 4 (approved 2026-09-27).
A: dedicated `Server.exe`, TCP 12345, seed from `server.cfg`, connect by IP/DNS, 4 players (alpha-era wiki said 10),
client-authoritative, chat + `/connect /disconnect /name /namepet /pvp` (`/pvp` dropped, D11: `server.cfg` flag `pvp`, default off), item trading by drop.
S: Steam-friends P2P (J), shared seed, keep own position, meet via free flights to friends,
artifacts lootable by all, ember per participant, other players' level on highlight, emotes
`/sit /wave /dance /pet`; no PvP, no trading UI, no dedicated server.

**Hybrid persistence item 6 (owner approved, 2026-09-28):** clients **request actions**;
the server validates movement, attacks, costs, damage, loot, purchases and progression against
the rules and decides gameplay outcomes. A client cannot simply announce extra money or a
successful hit. Client predictions may need correction to authoritative outcomes.
Alpha's client-authoritative protocol and `generators.json#network-alpha` are historical
reference, not hybrid authority. This chooses no transport/protocol, anti-cheat numeric defaults
or central trust service. Networking and enforcement remain deferred and unauthorized.

**Hybrid persistence item 7 (owner approved, 2026-09-28; depends on item 1):** accept
**rule-valid portable characters as trusted-co-op imports**, without requiring a central
progression service. Reject an invalid import with an explanation and **leave the original save
untouched**; never silently strip items or levels. A legally shaped edited save can still pass:
item 6's authority over gameplay after joining cannot prove where imported progression was earned
and does not make portable progression cheat-proof. No provenance proof, closed economy or
global concurrency guarantee is promised. Import validation/enforcement remains deferred.

### input-binding
Default keys per version. → `instances/keybinds.json`. A: no remapping; S: remappable, saved.
Hybrid defaults (D13): `keybinds.json#hybrid`, the engine builds its InputMap from it.

### hud-element
→ `instances/ui.json`: portrait+name+level/class+HP+XP (A), coins + key-item bar (S), HP/MP/stamina
bars, hotbar (M1, M2, 1–4 `A`, Q), stealth bar, pet HP/XP/hydration, message log, minimap (3-D,
rotating, scalable), compass, time/temperature/humidity, land caption, buff icons `S`, help widget
`S`, damage numbers, combo counter, stun stars, enemy name colours + stars, chat, world map (3-D
voxel, zoom 1:4..1:256, markers, missions, players, shrines, flight points), overview map `A`,
character sheet (power, HP, armor, resi, crit, haste, reg, weapon/armor rating), skills window `A`,
crafting window, inventory, quick-select wheel, customization bench UI, character creation, world
selection `A`, friends widget `S`. Hybrid (D17): `debug-menu` — the runtime profiling overlay any player
can open without a dev environment (Godot Debug Menu add-on: FPS, frametime, CPU/GPU graphs, GPU +
driver, OS; F3 cycles hidden/compact/full; shipped in release exports).

Hybrid (D25): damage numbers, stun stars and buff icons run; sounds are synthesised from `design.feel.sfx`
until audio assets exist.

Hybrid panel-time policy (walkthrough item 10, owner approved 2026-09-17): opening the inventory,
skill-tree or shop panel does not pause time, in either solo or multiplayer. The world and player
timers continue together: enemies and projectiles remain active, damage-over-time effects tick,
cooldowns count down, buffs expire and dodge protection ends under their existing rules. Opening
these panels grants no immunity or extension of protection; players remain vulnerable while browsing.
This does not decide new input availability or the behavior of other panels/menus.
Panel-time runtime authorization (walkthrough item 10, owner approved 2026-09-17): repair the
player-only timer freeze and add regressions for these three panels. Preserve current gameplay
input restrictions, balance and other menus; advance existing simulation rather than admitting
new movement, combat or interaction input. Other runtime fixes remain separately deferred.

### option
→ `instances/ui.json#options`: FPS limit (default 111), invert Y, camera speed, resolution,
windowed, render distance, AA samples (`options.cfg`), rarity display, music loop `S`, volumes,
UI scale F2/F3, hide UI F4, minimap scale F5/F6.

### save-data
A: `Save/characters.db` (sqlite `blobs(key,value)`; character blob ≈ EntityData), per-world
`world.db` (discovered map); assets `data1.db`/`data2.db`; characters world-independent.
S: per-world sqlite (`world_db_database`), Steam Cloud listed. Pets' XP didn't persist in
multiplayer `A`.

**Hybrid persistence item 1 (owner approved, 2026-09-28):** a hero carries their identity,
level/XP, skills, inventory, equipment, money, recipes, acquired key items, artifacts and pets,
**including pet progression**, between solo worlds and servers. These remain that character's
progress; other characters do not inherit them automatically. Experienced heroes can enter
fresh worlds with their existing strength. Equipment never weakens on travel (§1).

**Hybrid persistence item 2 (owner approved, 2026-09-28):** position, respawn point,
travel unlocks and lore are saved **per character per saved world**, separate from portable
progression. Returning restores that world's records; first entry uses its starting location
under the existing D22 `world.spawn-rule`, not a new spawn policy. Independently created worlds
have separate mutable histories even when their seeds match. Seed equality determines generation
and geography, **not saved-world identity**; no storage format or identity-allocation scheme is chosen.

**Hybrid persistence item 4 (owner approved, 2026-09-28):** supplier rescues, removed
barriers and resolved village curses belong to **that saved world**, not the character who
completed them. Their effects benefit everyone there, including later arrivals, and survive
sessions **subject to each mechanic's existing reset rules**. Visitors inhabit one consistent
world and may find these objectives already completed. This persistence rule sets no new reset
schedule; cleared dungeon/quest enemy eligibility follows `game-clock` world/reset item 3.

**Hybrid persistence item 5 (owner approved, 2026-09-28):** each character may claim a
given **artifact or one-time book source once in that saved world**. Another character's claim
does not consume theirs; later visitors can still collect their own **at the source**, not by
automatic remote award. Leaving, restarting or returning never renews an existing claim;
neither do daily enemy resets (`game-clock`, world/reset item 3).
Genuinely separate worlds, including independently created matching-seed worlds, offer additional
sources; item 1's portable heroes can therefore earn additional artifacts by world-hopping.
Existing recipe-duplicate rules still apply (`recipe`): no compensation, rerolls or account-wide
knowledge. Ordinary ground loot is unchanged; this is not a blanket all-reward instancing rule.

World time across shutdown follows `game-clock` item 8; surviving logical mobs
retain threat/order/neutral provocation across restart under `ai-behavior` item 9.

Documentation only: save-data and networking are unimplemented; these policies do not authorize
runtime, live-data, model/loader/validator or test changes.

### slash-command
→ `instances/slash-commands.json`.

### audio
Composer Wollay. Tracks and SFX ids → `instances/audio.json`. Races have distinct voices.

### version
→ `instances/versions.json`: dated feature timeline (devlog 2011–2013, alpha patches 2013-07-05 /
07-23, beta 0.9.1-3 … 0.9.3-0, 1.0.0-0/1, Omega posts 2023) and the recurring fan fix-list.

---

## 4. Relations

One row per fact type. Cardinality as `domain → range`.

| id | domain | range | card. | meaning |
|---|---|---|---|---|
| has-specialization | character-class | specialization | 1→2 | |
| uses-weapon | character-class | weapon-type | 1→3 families | |
| wears-material | character-class | material | 1→1 | iron/linen/silk/cotton |
| grants-ability | specialization ∪ character-class | ability | 1→n | versioned |
| unlocks-next | ability | ability | 1→0..1 | alpha tree: 5 points |
| bound-to-input | ability | input-binding | 1→1 per version | |
| costs | ability | resource | 1→0..n | amount per resource, scoped by ruleset |
| applies | ability ∪ weapon-type ∪ hazard | status-effect | n→n | |
| has-moveset | weapon-type | ability (m1, m2) | 1→2 | |
| knows-recipe | player-character | recipe | n→n | one known fact per character/recipe, shared by books and formulas (`known-recipes`), even while power-locked; knowledge alone does not grant crafting usability; recipes persist across lands/sessions/worlds (§3.7 save-data), not shared-account knowledge |
| crafted-at | recipe | crafting-station | 1→1 | |
| consumes | recipe | ingredient ∪ material | 1→n | with counts |
| produces | recipe | item-type ∪ consumable | 1→1 | |
| refines-to | ingredient | ingredient | 1→1 | nugget→cube, fiber→yarn, log→wood cube |
| yields | flora ∪ deposit ∪ creature | ingredient | 1→n | count range |
| spawns-in | creature ∪ flora ∪ deposit | landscape ∪ terrain-feature ∪ dungeon-type ∪ poi-type | n→n | |
| placed-in | dungeon-type ∪ poi-type ∪ settlement | landscape | n→n | |
| tamed-by | creature | pet-food | 1→0..1 | stable ID pairing; one food may serve multiple explicitly approved species (Bubble Gum: Collie and Skeleton Dog); numeric identity follows c-food-id, not family inheritance |
| member-of-family | creature | creature-family | 1→0..1 | optional primary balancing family (`creature.family`); sole source of family stat modifiers |
| descriptive-member-of-family | creature | creature-family | 1→0..n | descriptive memberships only (`creature.descriptive-families`); never supply or stack stat modifiers |
| belongs-to-faction | creature ∪ npc-role | faction | n→n | |
| hosts | dungeon-type ∪ poi-type | mission-type | n→n | |
| rewards | mission-type ∪ arena ∪ poi-type | item-type ∪ key-item ∪ artifact ∪ currency ∪ book-of-crafting | n→n | |
| guards | creature (boss) | artifact ∪ key-item ∪ gnome-supplier ∪ magic-crystal | n→n | |
| drops | creature | item ∪ spirit-cube ∪ leftovers ∪ currency | n→n | random by tier + species list |
| holds | inventory | item | 1→n | count per entry; c-stack-rule |
| equips | entity | item | 1→0..12 | at most one per usable equipment-slot; reserved index 0 and separate Q selection excluded; c-slot-accepts |
| threat | entity (mob) | entity (player-character) | n→n | hybrid mob/player combat state, retained across temporary absence and surviving-mob restart (§3.2); optional per ordered pair, with one numeric `aggro-points` amount; c-threat-pair |
| current-target | entity (mob) | entity (player-character) | 1→0..1 | hybrid mob/player target selection, separate from threat amounts; multiple mobs may select the same player; c-current-target |
| requires-key-item | poi-type ∪ dungeon-type ∪ ability | key-item | n→n | divine door→harp, crypt gate→bell, bird statue→whistle; hybrid riding→reins (acquired, c-riding), hang-gliding→hang-glider and sailing→boat (equipped, c-gliding/c-sailing); global scope |
| located-in | settlement ∪ dungeon ∪ poi | land | n→1 | |
| owned-by-realm | land | realm | n→1 | S |
| reveals | realm (lore 100 %) | artifact | 1→n | S |
| bound-to-land | item ∪ key-item ∪ leftovers | land | n→1 | S region lock |
| works-in-adjacent | item(plus) | land | n→n | S |
| raises-stock | gnome-supplier | shop | 1→n | one rarity per rescue |
| sells | shop | item-type ∪ pet-food ∪ formula ∪ key-item | n→n | versioned |
| offers-service | building | npc-role | 1→n | |
| contains-station | building | crafting-station | 1→n | |
| in-district | building | district | n→1 | A |
| styled-by | settlement | landscape | n→1 | architecture theme |
| equips-in | item-type | equipment-slot | n→n | permitted slots, not simultaneous copies of an item; rings and weapons have multiple eligible positions, subject to c-slot-accepts |
| restricted-to-class | weapon-type ∪ material | character-class | n→0..1 | |
| has-hazard | landscape ∪ terrain-feature | status-effect | n→n | cold-water, toxic, lava |
| countered-by | status-effect | consumable | n→n | hot chocolate, green smoothie, lemonade |
| raises-stat | artifact ∪ ability ∪ spirit-cube ∪ elixir | stat | n→n | hybrid artifacts: exactly one traversal stat plus attack and max HP; per-stat counting and recalculation follow §3.4 artifact / c-artifact-stat |
| mounts | player-character | pet | 1→0..1 | hybrid training + global Reins + rideable tamed pet: c-riding; A skill-only / S land Reins are reference |
| owns | player-character | pet | 1→n | cages |
| possesses | poi-type(demon-portal) | npc-role ∪ creature | 1→n | S |
| petrifies | creature(witch boss) | settlement | 1→1 | S |
| scales-with | pet | stat(weapon-rating, armor-rating) | 1→2 | S |
| adjacent-to | land | land | n→n | derived from grid |
| enabled-by | ability ∪ item-type ∪ mechanic | ruleset | n→n | feature flags |

### Threat and current target (hybrid)

Owner-requested clarification (2026-09-18), documentation only. These relations describe the
approved mob/player scope. A **mob** is an individual non-player combat `entity`, not the shared
`creature` species definition; the player endpoint identifies an individual `player-character`.
For threat/order retention, these are logical mob/player identities, not only currently spawned
nodes. Temporary absence and surviving-mob restart preserve the approved remaining state under
§3.2; `current-target` still requires a present, living player entity. Restart retention promises
no restored target node, chooses no storage strategy and adds no combat pairings.

**Threat** is the directed mob → player relationship, not a separate global player stat.
Its numeric property **`aggro-points`** measures the relationship's strength, in **aggro points**
(also called threat points). Each mob can track zero or more players and each player can have
incoming threat relations from zero or more mobs, independently. **`current-target`** identifies
at most one player that a mob is currently targeting; changing it does not erase other threat
relations. Ordinary selection uses that mob's own scores and the rules in §3.2 `ai-behavior`.
Heroic Shout temporarily overrides `current-target`, not `threat`: it grants neither aggro
points nor engagement order, and taunt alone adds no neutral provocation or lasting eligibility.
When it ends, ordinary targeting resumes unless protected return applies (§3.2).

Illustrative runtime facts, not static instance data or balance defaults:
```text
mob-a --threat {aggro-points: 20}--> player-you
mob-a --threat {aggro-points: 30}--> player-teammate
mob-a --current-target-----------> player-teammate
mob-b --threat {aggro-points: 40}--> player-you
mob-b --current-target-----------> player-you
```

Pack membership is the generated grouping of mob individuals (§3.2), not `member-of-family`
or `belongs-to-faction`. Shared current sightings do not copy `threat`, engagement order or
`current-target`; each mob selects independently under §3.2. Open questions are in §7.

---

## 5. Constraints

### Validation contract (item 9, owner approved 2026-09-17)

This is the required validation behavior, **not a claim that the current checker implements it**.
Approval covers ontology documentation only; loader, validator, generator and gameplay changes
remain separately authorized work (`docs/ROADMAP/todo_decide.md §E`).

- **Required data:** tables and config blocks needed by active, approved hybrid systems must
  be present and have the documented root/row shapes. Missing data must fail validation, not
  silently skip its checks; this includes the race catalog and the whole `design.movesets`
  block. Derive required paths from the approved domain and dependencies, not from whichever
  files happen to load. Reference/roadmap coverage does not by itself enable a hybrid system
  or require its runtime implementation.
- **Existing rules:** validate class/spec references in both directions, two specs per class
  with distinct indices 0/1 and index 0 first, shared skill-column roots and weapon upgrade
  capacities according to their approved definitions. Preserve the approved Assassin single-node
  exception (§3.5) and the approved two-handed wand (§3.3); do not settle open choices through
  a validator default.
- **Provenance:** versioned content must resolve at least one source-version tag, explicitly
  or through an inheritance rule documented for that family and its source. Missing tags
  are not permission to assume A/S, infer provenance from a numeric ID, or enable content.
  Item 9 alone established no per-family inheritance rules; item 4 below records the bounded
  mappings now approved. Unscoped histories remain research. Metadata/config containers are
  not automatically content instances.
  Taxonomy/style config, pet-food evidence and qualified reference annotations follow the
  Validation-contract mapping below.
- **Definitions versus generated instances:** load-time checks validate available definitions
  and generator configuration, not nonexistent generated objects. For artifacts, check the
  definition's seven approved traversal stat kinds and approved bonus configuration at load time;
  generator/runtime checks separately verify each generated artifact has exactly one of
  those traversal bonuses plus attack and max HP. The approved accumulation curve, counts and
  recalculation are in §3.4 `artifact`; direct data correction and enforcement remain deferred.
  Passing definition checks is not evidence that generated rewards or runtime behavior work.
- **Result:** validation succeeds only when the accumulated load/validation error collection
  is empty. Earlier load errors remain failures even if a validation pass adds no new errors.
  Malformed data must produce an error rather than be silently discarded or treated as valid.

The required paths, permitted source inheritance and check boundaries are mapped below.
Resolve remaining source attribution from evidence before its affected checks; ask the owner
only where approved rules leave a genuine choice, never fill gaps by guessing.
Negative regressions must cover missing whole inputs as well as invalid entries. No balance,
content selection or live data changes are authorized by this contract.

### Validation-contract mapping (owner approved, 2026-09-28)

**Item 1 — Hybrid taxonomy/configuration:** the 12 top-level families in
`creature-families.json` (`beetles`, `runners`, `slimes`, `alpacas`, `dogs`, `cats`, `golems`,
`trolls`, `skeletons`, `sprouts`, `guardians`, `fish`) and `buildings.json#settlement-styles`
are source-independent hybrid taxonomy/style configuration. Validate their stable IDs, shapes
and references; do not manufacture A/S ancestry or derive it from member-version unions.
This is not a whole-file exemption: separately sourced historical facts, including embedded
trait descriptions, retain their provenance; nested spawn rosters and versioned buildings/districts
are outside this classification. Existing family assignments, creature behavior, encounters and
settlement styles stand; no species-trait inheritance or numerical family modifier is introduced.

**Item 2 — Individual pet-food provenance:** evidence and unresolved claims follow §3.4
`pet-food`, independently of approved taming pairings and numeric source identity.

**Item 3 — Qualified source annotations:** retain `S?` and `A?` as uncertainty-qualified
source annotations for reference records, not confirmed S/A history. These annotations do not
independently establish hybrid availability; explicit hybrid decisions still govern it (§1).
An uncertain Swamp Lands reference remains useful for research without deciding its identity or
adding a distinct shipping biome. Do not delete or reject a reference merely for its qualified
tag, or silently promote it to confirmed history. This chooses no runtime schema/type or parser
behavior: the current parser strips `?`; preserving the qualification in model/loader/validator
handling remains deferred and unauthorized.

#### Item 4 — Required inputs, source scopes and check boundaries

Owner approved 2026-09-28, with the undeployed-game clarification in §0. This maps existing
rules, not new content, balance or a serialization schema. Required means dependencies of the
**approved hybrid**, including unimplemented systems, not merely today's consumers. Within a
mixed file, historical A/S alternatives, X/cut and Omega-only rows remain reference; requiring
its active definitions does not activate every row or require generating objects at load time.

**Required paths and shapes.** Paths below are relative to `ontology/instances/`; each file
root is an object. Braces enumerate exact sibling paths, not arbitrary keys. A catalog is an
ID→row-object map unless noted. Metadata (`$schema`, `_doc`, source notes, examples and negative
research) is not a content row; neither silently discard malformed catalog rows nor flatten
legitimate arrays/scalars/config into invented instances. The §3 definitions and constraint
catalog govern row fields and numeric/reference rules; the inventory locates their inputs.

| dependency | required definition/config paths and heterogeneous shapes |
|---|---|
| Identity and skills (§3.2/§3.5) | `races.json`, `classes.json`, `specializations.json`, `abilities.json` catalogs; `abilities.json#<id>.alpha-tree` is a per-ability object, not a root table. |
| Combat and item types (§3.3/§3.4) | `weapon-types.json`, `materials.json`, `item-types.json`, `rarities.json`, `status-effects.json` catalogs. Rarity comparison maps `mob-strength-tiers-s` / `alpha-relative-colors` are separate reference config; `status-effects.json#ability-buffs` is a definition-reference object and `#not-found` a negative-research array, not effects to instantiate. |
| Stats and slots (§3.3–5) | `stats.json#{resources,stats}` catalogs and `#{alpha-item-stat-formulas,alpha-character-formulas}` mixed formula objects (strings, numbers, tables); `equipment-slots.json#slots` an array of rows with `id`/index, `#extra` an object of separate quick-use/taming descriptions, `#rules` a string array. Current slot acceptance text must conform to §3.4, not redefine it. |
| Creatures and pets (§3.2/§3.4) | `creatures.json` catalog; the 12 `creature-families.json` config objects listed in item 1; `#landscape-rosters` maps to creature-ID arrays; `#forest-dungeon-rosters` maps to objects with `members` arrays and `boss` strings, including race/family tokens, not uniformly creature IDs. `pet-food.json#foods` catalog; `#rules` / `#shop-set` arrays; `#cut` a separate reference catalog. |
| World and encounters (§3.1/§3.6) | `landscapes.json`, `terrain-features.json`, `flora.json`, `deposits.json`, `dungeon-types.json`, `poi-types.json`, `factions.json` catalogs (realm-name examples are not factions); `landscapes.json#<id>.gen` objects for generated hybrid landscapes. `mission-types.json#{alpha,steam}` nested catalogs, with `_shared` config and `steam.region-completion-order` guide array distinct from mission rows. |
| Blocks and structures (§3.1) | `block-types.json#alpha` numeric-key→row objects plus `flags`, `#steam` numeric-key→strings plus `note`, `#{scale,cub-format}` config objects; `static-entities.json#by-id` numeric-key→name strings, `#behaviour` a mixed description map, `#s-additions` string array, `#candles` config object. Numeric table presence is not content availability. |
| Crafting and traversal (§3.4/§3.5) | `consumables.json`, `ingredients.json`, `crafting-stations.json`, `key-items.json` catalogs with separate summary/config objects (`consumables#rules`, `key-items#counts-per-land-s` and cut `#special-accessories-x`). `recipes.json#{gear-armor-quantities,gear-weapons,refining,recipe-sources,customization}` mixed rule/recipe objects; `#{cooking,alchemy}` objects referring to consumables; `#crafting-tabs-a` string array. `key-items.json#artifact.stat-kinds` is the seven-kind definition array, not generated rewards. |
| Settlements and economy (§3.1/§3.4) | `buildings.json#{districts,buildings}` catalogs, `#{settlement-styles,population,map-visibility}` config objects; `npc-roles.json` catalog (dialogue corpus separate); `economy.json#{currency,incomes,prices,shops,rules,loot}` mixed source/config objects. Approved hybrid services, prices and resets govern, not historical alternatives. |
| Names (gen-name) | `affixes.json#{common,uncommon,rare,epic,legendary,name-forms}` string arrays; examples are reference and `#plus-suffix` is an excluded S mechanic, not hybrid naming. |
| Rules, controls and presentation (§3.7) | `rulesets.json#ruleset-hybrid` object with `flags` object and default boolean; other rulesets reference only. `keybinds.json#hybrid` binding object; `ui.json#{hud,screens,options,camera}` grouped objects; `audio.json#sfx-alpha-ids` string array (includes descriptive entries, not all asset IDs). `slash-commands.json` command-key→row catalog with separate `cuwo-server-commands` array / `chat-rules` object; only approved commands, never `/pvp`. Historical audio backend/track records are not runtime asset requirements. |

`versions.json#{timeline,alpha-to-steam-delta,reception}` (array/object/object) is history
coverage, not an active gameplay dependency merely because the directory loader visits it.
Reference data still needs structural validity and qualified attribution; no whole-file exemption
or uniform row-shape assumption follows from the active/reference distinction.

`generators.json#design` is required as an object. Its required children are grouped below;
existing config constraints specify dependent fields. Current obsolete values do **not** satisfy
later approvals. In particular, require the approved artifact logarithm directly, not decay/floor
as an accepted alternate format. This chooses no new JSON keys for that rule.

| dependency | exact `design` children and nested shapes |
|---|---|
| World/spawns | `{enemy-level,enemy-hp,terrain,climate,names,spawns}` objects; `terrain.{height,heightfield}` and `spawns.ai` objects, `climate.rules` array of `[landscape-id, expression-string]`, `names.syllables` string array / `names.land-suffix` map of string arrays. |
| Skills/combat | `{skill-point,abilities,resources,special-attack,status-effects,progression,crit,movement,camera,combat,defence,movesets}` objects; `abilities.runtimes` / `movesets.kinds` arrays, ability/moveset entries objects (including documented aliases); `resources.mp`, `movement.stamina`, `defence.{dodge,block,stealth,enemy-hit}` objects. Whole `movesets`, `default` and required class-weapon entries cannot be skipped when absent. |
| Roles/feedback/engine | `{creature-roles,feel,frame-budget}` objects; `creature-roles.{any-class,melee,ranged,mage,species}` objects and `default` string; `feel.{hit-stop,shake,numbers,impact,trail,level-up,events,sfx}` objects with event/sound references and colour arrays per the catalog. |
| Inventory/settlements | `{prices,stack-cap,loot,starting-inventory,settlement}` objects; `stack-cap.stackable` / `loot.consumable-pool` arrays; `loot.{coins,rarity-weights,gear-kinds,ground}` objects; `settlement.buildings` array, `settlement.npc.roles` / `settlement.style-by-landscape` maps, `settlement.style-colors` map of two-colour arrays, `settlement.{shop,inn,trainer}` objects. |
| Other approved systems | `{artifact,artifacts-per-land,circle-of-power,recipes,pvp}` objects, regardless of incomplete consumers. `{item-stat-curve,block-reward,regeneration}` are **strings**, not object blocks. |

Other `generators.json` inputs for §6 are mixed historical/approved-system objects:
`{world-scales,seed,time,climate,land,terrain,settlement,dungeon,spawns,boss,names,item,realm,npc-appearance,schedule,key-items-s}`;
`loot` and `level-formulas-alpha` are string references. Check approved dependencies within these
containers, not every source-specific alternative as hybrid config. `coarse-map-omega` and
`network-alpha` are reference-only objects; no borders, sleep-fast-forward and client authority
in older source descriptions cannot override the approved bounds, inn skip and server authority.
There is no current save-schema file or generated-object catalog to invent as a required input.

**Permitted source inheritance.** This is a finite mapping of explicit source envelopes, not
an A+S default. Apply only to the stated table facts or subfacts without their own annotation;
retain explicit row-level X, `A?`/`S?`, uncertainty and narrower exceptions. Source-table origin
proves neither shipped source functionality nor hybrid availability. Item 1's taxonomy/style
configuration and owner-authored `design` / hybrid bindings need no invented historical ancestry.

| source envelope | inherited historical scope and evidence boundary |
|---|---|
| `block-types.json#{alpha,steam}` | A / S table facts respectively (`research/research_world.md §2.3`); flags/notes remain metadata, not block instances. |
| `item-types.json` alpha type/subtype table | A table origin from `_doc` (cuwo ItemData), corroborated by `research/research_systems.md §9.2`; retain explicit X rows and nested cut qualifiers. `_s-additions` supplies S subfacts only. Type 20 does not date individual foods. |
| `static-entities.json#by-id` / `#s-additions` | A STATIC_NAMES / S additions (`_doc`, `research/research_systems.md §9.1`). Do not extend to mixed `behaviour` or unscoped `candles`; explicit fire/stomp X and alpha artifact ID 46 never establish working alpha artifact gameplay. |
| `mission-types.json#{alpha,steam}` | A / S catalog scopes (`research/research_creatures_quests.md §7.1–2`); `alpha.quests-cut` stays X. `_shared` and completion-order are source rules/guide metadata, not missions. |
| `rarities.json#{mob-strength-tiers-s,alpha-relative-colors}` | S / A comparison facts only; do not propagate through rarity references. |
| `stats.json#{alpha-item-stat-formulas,alpha-character-formulas}` | A formula sources explicitly identify coremaze 0.1.1 reverse engineering / cuwo; this does not resolve uncertain formula correctness. |
| `audio.json#sfx-alpha-ids` | A identifier-list origin (`research/research_systems.md §8`), not asset availability or dates for tracks. |
| `equipment-slots.json#slots` and `#extra.consumable` | A storage-table / separate consumable-field origin (`research/research_systems.md §5.1/§9.2`); preserve partly inferred indices and row/subfact annotations. Approved hybrid slot rules remain independent. No A+S blanket on equip rules. |
| `keybinds.json` action-row `A` / `S` cells | That cell's source only (`research/research_systems.md §5.3`); em dash records absence, not a binding. Mixed `map-controls` and `hybrid` receive no inherited A+S tags. |
| Explicit source subfacts in mixed containers | `economy.json#{currency,incomes,prices}.{A,S}`, `#shops.weapon-shop.stock.{A,S}`, `#shops.item-shop.sells.{A,S}`, `#rules.buy-back.{A,S}`, `#loot.{A-boss,A-dungeon,S-mission,S-dungeon}`; `recipes.json#crafting-tabs-a`, `#recipe-sources.{A,S}`, `#customization.{spirit-cubes-a,fully-modded-legendary-plus-s}`; `buildings.json#map-visibility.{A,S}`, `audio.json#ambient.{S,Ω}`, `key-items.json#counts-per-land-s`: only the explicitly named source subfact, never the whole mixed parent. Excluded regional mechanics remain reference. |
| Explicit generator source sections | `generators.json#world-scales.{alpha,steam}`, `#seed.{alpha-default,alpha-source,steam}`, `#land.{alpha-level,alpha-rarity,steam-tiers,steam-per-land,alpha-per-land}`, `#settlement.{alpha-count,steam-count,districts-alpha,inn.A,inn.S}`, `#dungeon.{alpha-layout,steam-layout,traps-alpha,traps-data-x,boss.A,boss.S,artifact-s,size-cap-s}`, `#boss.{alpha-size-scaling,alpha-spirit-drop,steam-loot,coins-s}`, `#npc-appearance.omega`, `#{coarse-map-omega,key-items-s,level-formulas-alpha,network-alpha}`: A/S/X/Ω only as explicitly identified there; preserve local hybrid overrides, never tag all generators A+S. |

Untagged histories outside these scopes remain **source research/attribution**, not guessed
labels or new gameplay ballots: individual foods; roster and embedded family traits; affix
prefixes; mixed recipe/shop/population/UI facts; unscoped audio, static behavior/candles and
dialogue/example claims. The mixed food table in `research/research_items.md §5` supplies
pairings, not per-food A+S history; preserve existing sourced S/X food facts and F11 Banana Mash.
Neither referenced species nor numeric IDs lend tags. `status-effects.json#ability-buffs` points
to existing definitions; `#not-found` creates none. `versions.json` keeps its history schema
(dates and scalar release identifiers, not content-tag arrays); cuwo command lists keep their
modded-server context, not stock-command or hybrid approval. No new labels or parser schema
are selected for these remaining cases. Subsequent bounded findings and unresolved scope are
recorded in item 6 (§3.4 `pet-food`) and item 7 below, not whole-container attribution.

**Check boundaries.** Load checks concern the above definitions/config, including required
presence before iteration, valid references/shapes and cumulative errors under item 9. Numeric
predicates remain in the constraint catalog; no duplicate balance table is introduced here.

| rules | definition/config load | generated objects, runtime and save/import checks |
|---|---|---|
| Class/spec/tree | Both reference directions, two specs with distinct indices 0/1 and index 0 first, shared roots/links, Assassin exception and ability config coverage. | Starting spec; spend/prerequisite/bank/respec, costs/cooldowns and actual effects. |
| Items/stats/recipes | Types, materials, slots, wand hands/recipe, capacities, formula/ingredient/station references and approved configuration. | Generated rarity/roll/stats/names; actual upgrades and equip class/slot/hand/power limits, stacks, transactions and recipe knowledge/duplicates/locks. Generated-rarity checks do not remove mythical/worn reference definitions. |
| Families/pets | Primary/descriptive references, roster IDs, food pairings/source identity and rideability. | Primary-only scaling, per-dog 1% generation/Collie fallback, normal dog behavior, taming/one-active-pet and training/item/equip traversal gates. Provenance is not inferred from these relations. |
| Artifacts (`c-artifact-stat`, §3.4) | Seven-kind `key-items.json#artifact.stat-kinds` definition and `generators.json#design.artifact` conforming to the approved normalized logarithm (5% first, positive adjustable z, initial z=0.1, no decay/1% floor). Old decay/floor cannot pass as an alternate. | Generation: exactly one approved traversal kind plus attack and max HP. Runtime: matching contributors per traversal stat, all artifacts for attack/HP, equal additive shares of the logarithmic total, recalculated from current artifact-free stats. No levels or gate bypass; personal source claims follow §3.7. |
| World/settlement/mission (§6) | Bounds/scales, climate rule shapes and parseability, rosters/styles/buildings/roles, sites/rewards and generator config. | Seeded geography, finite bounds, exact-one settlement, placement/count/lock/wave/boss-fit/loot invariants; map/travel boundary, protected settlements, clock/inn/reset/occupied-site rules and nonrenewing permanent claims. No generated-world census at load time. |
| AI/combat | Ability/status/moveset/projectile/role references and numeric config, including simulation-radius relationship. | Threat pairs/order/target eligibility, pack response, home return, actual hit/damage/status/dodge/block/combo behavior and live panel time. Valid config alone proves none of these effects. |
| Persistence/authority (§3.7) | Available rule/config definitions only; no invented save format or transport. | Server-validated actions/outcomes; portable versus character/world versus shared-world ownership; source claims, no downtime catch-up and surviving-mob retention. Validate imports against current rules; reject invalid imports with explanation and original save untouched, not conversion or a claim of earned-progression proof. |
| UI/engine/assets | Binding/UI/sound/format declarations and frame-budget config. | Player-name input limits, actual RGB payloads, map/input/HUD/feedback and physics/catch-up behavior; nonexistent generated payloads are not malformed definitions. |

Future regressions must exercise each predicate at its mapped boundary, including item 9's
missing-whole-input cases. A passing current validator does not prove this mapping's enforcement;
direct data correction and loader/validator/generator/runtime work remain unauthorized.

#### Item 7 — Bounded mixed-source findings (owner approved, 2026-10-04)

These citations record only the named subfacts in existing mixed containers; they grant no
whole-file ancestry or new labels. Sources inspected are the retained `research/` dumps, not
freshly retrieved external pages. Existing approvals, source qualifications and cut status stand.

| existing subfact | evidence and historical limit |
|---|---|
| `creature-families.json#runners.traits` | `research/research_creatures_quests.md §2.1` explicitly scopes animals A+S unless noted: its Runner row describes large two-legged neckless birds, groups 3–5, high attack tempo/run speed and all but Lava Lands. This supports those descriptions only, not unrelated family traits or roster ancestry. |
| `recipes.json#customization.material-cubes`, `ui.json#screens.customization-bench` | `research/research_items.md §3.5` explicitly A: matching wood/metal material, 16/32 capacities, M3 rotation, cube placement and destruction on removal; each cube adds **≈0.1** effective level. S separately supports the bench's material-cube upgrading, not every Alpha numeric/UI detail. Its 58–67 damage anecdote is community evidence, not a universal bonus. |
| `economy.json#rules.sell-price-tooltip`, `#loot.npc-rewards`; dated `ui.json` subfacts | `research/research_systems.md §1.3`: S 0.9.1-4 (2019-09-25) removes tooltip sell price, limits NPC rewards to once, saves remapped controls and adds music looping; 0.9.1-6 (09-27) adds configurable anti-aliasing samples and reduced background refresh; 0.9.3-0 (09-29) adds the Esc help button and default-on help for new characters. These date those patches, not every shop, loot or screen statement. |
| `audio.json#music-rules`, `#voices`; `ui.json#options` audio settings | `research/research_systems.md §8` reports S looping, separate volume sliders and xAudio2; §5.4 lists Alpha volume controls. §8's Alpha SOUND_NAMES paragraph reports race-specific voices, not retrieved assets or confirmed S voice history. The historical backend is not a pixlnd dependency. |
| `static-entities.json#behaviour` selected interactions | `research/research_systems.md §1.3`: S 0.9.1-4 prevents object use through walls; 0.9.2-0 (2019-09-28) prevents Mage teleport through gates. `research/research_world.md §7–8` supports Alpha empty house chests, decorative trade stalls/crates/barrels, dungeon spike traps and breakable vases; S one-time dungeon chests. This does not date all bundled clauses (including trap dodge penetration, furniture healing or campfire use). |
| `npc-roles.json#dialogue-corpus` selected subfacts | `research/research_world.md §9` reports Alpha green mission bubbles and pre-alpha EN/DE procedural quests cut before Alpha. `research/research_systems.md §1.3` dates S speech-bubble dialogue options to 0.9.2-0. `research/research_creatures_quests.md §7.3` gives the Skeleton Horse lore tablet as an S **example**, not a required literal line or whole-corpus attribution. |
| Dated previews: `static-entities.json#behaviour.lever`, `buildings.json#population.schedule`, `ui.json#screens.character-creation` / `#camera` | `research/research_systems.md §1.1` reports levers in 2012-02-10 dungeons, daily NPC routes in the 2012-12-04 AI preview, random creation background on 2013-01-28 and zoom-to-first-person on 2011-06-09. These are pre-alpha development reports, not proof the exact functions shipped; §7 leaves S first-person documentation uncertain. D9's approved hybrid camera is independent. |
| `audio.json#tracks` | `research/research_systems.md §8` records publication/catalog leads: Explorers (2013 video theme), faction tracks (2015-10-04/05/06), Bgum (2016-08-21 **?**), Omega (2023); `research/research_world.md §1` reports new ocean music in the 2017-04-01 tweets. Publication/preview dates do not establish build inclusion. `research/research_creatures_quests.md §7.2` explicitly reports S Spirit World spooky music/fog, not a retrieved named track identity or date. New Lands/Awakening dates and the full 2019 tracklist remain unresolved. |

**Remaining source research:** landscape/forest-dungeon roster memberships and other embedded
traits; exact affix lists/name examples; recipe/refining quantities; unscoped shop/loot claims;
population and shipped schedules; other UI/camera details; candles/furniture; remaining audio
and dialogue/example histories. `research/research_world.md §3.2` dates **landscapes**, not all
adjacent fauna: its Jungle A+1.0 row includes Warthog/Elephant/Baby Elephant, explicitly S
elsewhere; Snow Leopard retains S? in `research_creatures_quests.md §2.1`. Neither that Ver
column nor species tags/IDs alone date individual habitat memberships; unscoped reports stay undated.
`research_items.md §3.4` expressly assumes other armor materials follow cotton and leaves
per-weapon counts undocumented; D6 and the approved Wand rule are independent hybrid decisions.
Population/community observations (`research_creatures_quests.md §4`), unversioned candle
details (`research_items.md §4`) and dialogue examples/hypotheses do not become universal or
confirmed release facts. No encounter, crafting, shop or presentation change is authorized.

#### Item 8 — Additional dated patch evidence (owner approved, 2026-10-04)

Retained `research/research_systems.md §1.2–1.3` reports the following specific patch facts,
not fresh external verification or dates for unrelated features:

| subfact | reported patch and evidence limit |
|---|---|
| `ui.json#options.invert-y` | Alpha 2013-07-05 added invert-Y (§1.2, cited wiki `July_5th,_2013`). |
| `ui.json#options.fps-limit` | Alpha 2013-07-23 added the FPS limit, default **111 FPS** (§1.2, cited wiki `July_23rd,_2013`). Patch dates do not resolve the uncertain Alpha version numbers (§11). |
| Independent minimap scaling | S **0.9.1-3, 2019-09-24**: minimap scalable separately from the HUD (§1.3, cited patch page `0.9.1-3`), not blanket UI ancestry. |
| `consumables.json#snowberry-mash` crafting | S **0.9.1-5, 2019-09-26** lists “craft Snow Berry Mash” among fixes (§1.3, cited `0.9.1-5`): a crafting-functionality report, not verified first introduction or support for every recipe detail. |
| Music looping | S **0.9.2-0, 2019-09-28** reports “music loop fixed” (§1.3, cited `0.9.2-0`), distinct from the **2019-09-25** option addition already recorded in item 7. No track-inclusion claim follows. |

No controls, recipes, audio, source labels or live JSON change; remaining histories stay open.

#### Item 9 — Specific historical reports, not gameplay rules (owner approved after clarification, 2026-10-04)

These retained reports support only the named subfacts, not entire rosters, recipe tables or
interfaces. No external pages/code were freshly verified; approved hybrid rules remain authoritative.

| subfact | retained evidence and limit |
|---|---|
| Slime encounters | `research/research_creatures_quests.md §2.4` explicitly reports **Alpha slimes with Djinn in deserts** and **Steam Slime Wells**. Other habitat/roster claims receive no blanket ancestry. |
| Slime Divide | `research/research_creatures_quests.md §9` dates the **Omega preview to 2023-06-26**. This is not confirmed Alpha/Steam functionality or shipped hybrid behavior; Omega-only splitting remains outside v1. |
| `recipes.json#gear-weapons.metal-weapon-common` | `research/research_items.md §3.1/§3.4` reports one **Steam common metal weapon example: five iron cubes at an anvil**. It neither establishes other weapon costs nor supplies a new hybrid default; exact per-weapon counts remain a source gap. D6 and the approved 20-wood-cube wand recipe stand independently, without conflict. |
| Shop stock | `research/research_items.md §7.2` distinguishes **Alpha identical restocked goods** from **Steam new stock each day**. Restocking and changing contents are distinct; this does not change hybrid shop/reset rules or attribute every shop/loot claim. |
| Steam map details | `research/research_world.md §10` reports **1:4–1:256 zoom**, displayed coordinates and **player-placed star markers**. These do not date the whole map interface or establish Alpha equivalents. |

No encounters, crafting costs, shops or map behavior change; exact affix histories and other
unsupported claims remain open under item 7. No new feature or source labels are authorized.

#### Item 10 — Historical sleep-speed wording (owner approved, 2026-10-04)

`static-entities.json#behaviour` says sleeping advances the clock “100x”. Retained
`research/research_systems.md §7` cites cuwo `NORMAL_TIME_SPEED = 10`, `SLEEP_TIME_SPEED = 100`
and approximately two game minutes per real second. These reports do not clearly establish
whether “100x” compares against real time or normal gameplay time. **The historical multiplier's
baseline/units remain unresolved pending source-code verification**, including actual stepping;
100 absolute and 10 normal could be compatible, so this is not a proven numerical contradiction.
This is retained research, not freshly inspected code; no replacement number or source tag is selected.

Hybrid normal time remains **10× real time**, and approved paid/consensual inn sleep still skips
to the **next 07:00** (23:00 → 07:00), with the existing midnight-reset rules, not fast-forwarded
combat/status effects/cooldowns (§3.1). This qualifies history, not hybrid clock policy or furniture
gameplay. `generators.json#time` and all other live JSON remain unchanged.

#### Item 11 — Verified cuwo clock code and its limits (owner approved, 2026-10-04)

Freshly inspected cuwo revision **`240bb61ec42abb10a73d750ce72f243e04e55509`** is an
open server reimplementation, not the original Alpha or Steam binary. Its
[`constants.py:23–26`](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/cuwo/constants.py#L23-L26)
defines `MAX_TIME = 86,400,000` game milliseconds, `NORMAL_TIME_SPEED = 10.0` and
`SLEEP_TIME_SPEED = 100.0`.

[`server.py:867–876`](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/cuwo/server.py#L867-L876)
calculates elapsed clock time from the loop-time difference × `time_modifier` ×
`NORMAL_TIME_SPEED` × 1000, plus a clock offset. With the
[default modifier 1.0](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/config/base.py#L10-L11),
this is **10,000 game milliseconds per real second**: six real seconds per game minute,
144 real minutes per day. This establishes that revision's normal calculation, not original-game behavior.

An exact-symbol search of its tracked source finds `SLEEP_TIME_SPEED` **only at its definition**,
not in the clock calculation. This revision therefore does not establish historical sleep selection,
speed or baseline, or justify the retained “approximately two game minutes per real second” report.
The code was inspected, not executed; original Alpha/Steam sleeping units remain unresolved under item 10.
No replacement sleep rate or source label is selected. Hybrid normal time, approved inn skip/reset/
consent/payment rules and all live JSON remain unchanged; this is documentation only.

#### Item 15 — Three dated UI patch reports (owner approved after clarification, 2026-10-04)

Freshly retrieved **community-wiki patch transcriptions** (source-scout MediaWiki response,
revision bodies/metadata inspected here) report only these changes:

| reported patch / body release date | exact reported change |
|---|---|
| [0.9.2-0, 2019-09-28](https://cubeworld.fandom.com/wiki/0.9.2-0?oldid=12461) | “Removed invisible orc hairstyles from character creation.” |
| [0.9.3-0, 2019-09-29](https://cubeworld.fandom.com/wiki/0.9.3-0?oldid=12493) | “Level of other players is now displayed when they are highlighted.” |
| 0.9.3-0, 2019-09-29 (same revision) | “Item receipt notifications now consider plus-equipment.” |

The bodies' release dates are distinct from wiki revision/edit timestamps:
**12461: 2019-09-28T13:28:08Z**; **12493: 2019-09-30T03:46:06Z**. These are not primary
developer posts or independently tested original behavior; they establish reported patch
changes, not complete interface histories, first introductions or broad ancestry.
No live UI, camera or notification work follows. Historical `+` equipment remains excluded
from pixlnd, and regional gear power loss remains **permanently excluded** (§1); approved
interface/game rules and all live declarations remain unchanged.

#### Item 17 — Forest and Beetle encounter reports (owner approved, 2026-10-04)

[Forest revision 10997](https://cubeworld.fandom.com/wiki/Forest?oldid=10997) reports these
eight dungeon-forest rows, preserving the source's nouns and boss alternatives:

| forest type | reported residing mobs | reported boss |
|---|---|---|
| Insect | Insektoids, Flies and Mosquitoes | Insektoid |
| Animal (I) | Lizardmen, Crows, Moles, Pigs and Biters | Lizardman |
| Animal (II) | Goblins, Crows, Moles, Pigs and Biters | Goblin |
| Undead | Undeads, Zombies, Skeletons, Frighteners, Vampires and Slimes | Undead |
| Orc | Orcs, Collies, Terriers, Pigs and Ogres | Orc |
| Human | Humans, Minotaurs, Werewolves, Collies, Black Cats and Jesters | Human |
| Beetle | Bark Beetles, Lemon Beetles and Snout Beetles | Bark Beetle / Lemon Beetle / Snout Beetle |
| Dwarf | Dwarves, Moles and Rocklings | Dwarf |

Live `creature-families.json#forest-dungeon-rosters` uses `cat` and `boss: beetle` as
abstractions, not exact source quotations; this approval does not correct that data.
[Beetle revision 19899](https://cubeworld.fandom.com/wiki/Beetle?oldid=19899) reports
**most landscapes except Snowlands**, **usually groups of 3–5**, and Fire Beetles
**exclusively in Deserts and Lava Lands**. “Most” is not exhaustive every-other-biome
coverage; “usually” is not a guaranteed pack size. No encounter, family or roster changes.

These and subsequent pinned community-wiki records below were retrieved by source scouts
on **2026-10-04**, with captured revision bodies/metadata inspected by this writer, not
externally re-fetched or original behavior tested. Wiki edit/capture dates are not release
or introduction dates. This report supplies no A/S release attribution or availability for
the Forest page's separately planned forests; per-membership histories/other traits remain research.

#### Item 18 — Cotton-only armor quantities (owner approved, 2026-10-04)

[Cotton Armor revision 12947](https://cubeworld.fandom.com/wiki/Cotton_Armor?oldid=12947)
reports a full **20-row cotton table**, summarized here by rarity (Cotton Yarn quantities):

| rarity | chest | shoulder | gloves | boots | additional gems |
|---|---|---|---|---|---|
| Common | 10 | 6 | 5 | 5 | none |
| Uncommon | 20 | 12 | 10 | 10 | Emerald: chest 4, each other piece 2 |
| Rare | 30 | 18 | 15 | 15 | Sapphire: chest 4, each other piece 2 |
| Epic | 40 | 24 | 20 | 20 | Ruby: chest 4, each other piece 2 |
| Legendary | 50 | 30 | 25 | 25 | Diamond: chest 4, each other piece 2 |

Thus the source reports a common chest at **10 yarn**, a legendary chest at **50 yarn +
4 diamonds**. This attributes the existing reported table, not a newly selected crafting bill.
Community-report/capture/date limits follow item 17. It establishes neither equivalent iron,
linen or silk costs, per-weapon quantities nor a release date. The other-material generalization
in `recipes.json` remains an assumption; **D6 and the approved Wand's 20 wood cubes stand
independently and unchanged**. No recipe, station, label or live-data changes.

#### Item 19 — Bounded shop-stock and Leftovers reports (owner approved, 2026-10-04)

[Item Shop revision 19791](https://cubeworld.fandom.com/wiki/Item_Shop?oldid=19791)
explicitly reports **Alpha** materials, Pet Food, Key Items and Formulas **+1..+100 in any
class type**; its **Steam** stock passage requires **all four Supplier Gnomes** before
legendary rings and amulets are sold. This attributes those clauses, not the complete stock
catalog or exact daily pet-food quantity. Existing stock/reset/supplier/pricing rules stand.

[Leftovers revision 14748](https://cubeworld.fandom.com/wiki/Leftovers?oldid=14748) reports
**a chance of animal drops**, an identification fee depending on **power level and quality**,
and **a possible one-tier-higher item**: epic → legendary is a possibility, not a guarantee.
It supplies no drop/upgrade odds or same-colour enemy/player-tier restrictions. Neither page
establishes release chronology beyond its explicit report scope; community/capture/date limits
follow item 17. Existing loot/reward rules remain unchanged. No shop, pricing, loot or source-label
changes, excluded `+` equipment proposal or regional mechanic follows.

#### Item 20 — Population observations, not a census (owner approved, 2026-10-04)

[Human revision 19440](https://cubeworld.fandom.com/wiki/Human?oldid=19440) says humans
are the **majority** of city residents, not that towns are **all-human**.
[City revision 20239](https://cubeworld.fandom.com/wiki/City?oldid=20239) gives village
animals **“such as” Collies, Cats, Sheep, Terriers and Pigs**, and reports that more NPCs
**accumulate the longer the player stands in town**. These are community observations with
item 17's capture/date limits, not an exhaustive or mandatory every-town roster.

Majority does not prove exclusivity or a numeric ratio. These passages supply no original
Alpha/Steam census, undead-exception scope, accumulation cause, growth/spawn algorithm or
stable timing. The retained all-human community observation is not converted into an
exhaustive rule or a demonstrated original-behavior contradiction. Existing hybrid settlements
and safety remain unchanged; no population, encounter, source-label or live-data changes.

#### Item 21 — Isolated NPC observations, not a daily schedule (owner approved, 2026-10-04)

The following community-wiki reports retain item 17's source-inspection/capture/date limits:

| pinned source | reported observation |
|---|---|
| [Trade District revision 16522](https://cubeworld.fandom.com/wiki/Trade_District?oldid=16522) | During the day **many NPCs** wander the market area. |
| [Campsite revision 18924](https://cubeworld.fandom.com/wiki/Campsite?oldid=18924) | NPCs and even monsters **occasionally rest at campsites**. |
| [NPCs revision 20300](https://cubeworld.fandom.com/wiki/NPCs?oldid=20300) | NPCs stop moving and face the player within **interaction proximity**; **some NPCs** offer mission/key-item hints. |

These isolated descriptions do not establish a universal ordered **home → park → shops → inn**
route, A*, numeric interaction range, exact literal dialogue, timings, nightly lantern coverage
or shipped Alpha/Steam history. In its separately **Steam-only Clans and Lore** section, NPCs
says **“It's theorized that reading lore helps NPCs tell the player more secret locations.”**
That remains a hypothesis, not a promised hint reward or mechanic. No schedule, dialogue,
hint-reward, furniture/sleep rule, source label or runtime change follows; remaining histories
stay research, not unanswered proposals.

#### Item 22 — Existing rarity-prefix lists (owner approved, 2026-10-04)

[Rarity revision 9901](https://cubeworld.fandom.com/wiki/Rarity?oldid=9901), edited
**2014-02-06T11:29:33Z**, contains all five existing Common–Legendary prefix lists in
`affixes.json`: ten entries each for Common, Uncommon, Rare and Epic, eleven for Legendary.
Rare and Epic share the same list; the source spelling **Battle-tested** is retained.
It gives examples **“Polished Iron Dagger of Xemi”** and **“Legendary Iron Shield of Kiba”**,
and says Epic/Legendary items **“often”** have lore names. That is the community report's
historical claim, not a weakening of pixlnd's approved **always-named Epic/Legendary equipment**
guarantee (§6 gen-name).

The saved raw revision body/metadata and extracted text were inspected here; the source-scout
capture was retrieved **2026-10-04**, not externally re-fetched or original-build tested by
this writer. Its edit date (or earliest returned revision) proves neither first publication,
feature introduction nor original Alpha/Steam behavior. Exact possessive-name and original-prefix
generation/release histories remain unresolved. No names, naming frequency, prefixes, source
labels or live declarations change.

#### Item 23 — Furniture-sleep reports, not a selected rate (owner approved, 2026-10-04)

[Sleep revision 17998](https://cubeworld.fandom.com/wiki/Sleep?oldid=17998), edited
**2024-01-04T06:55:34Z**, reports interacting with a **bed or bedroll** using **R in Alpha /
E in Steam**, regenerating HP **without restoration items**, and being unable to do so
**in combat stance**. It also reports approximately **two game minutes per second** while
asleep; that speed sentence has no individually identified Alpha/Steam build scope.
[Bedroll revision 11769](https://cubeworld.fandom.com/wiki/Bedroll?oldid=11769), edited
**2019-04-23T19:59:38Z**, estimates **10 health per second**, explicitly **“Requires Testing”**.
Its **“does not pass time like an Inn”** wording does not clearly distinguish clock acceleration
from an inn skip. Neither page demonstrates either rate in an identified original build or
resolves historical sleep baseline/units (items 10–11); no numerical contradiction is proven.

Saved raw revision bodies/metadata and extracted passages were inspected here, from source-scout
captures retrieved **2026-10-04**, not externally re-fetched or original behavior tested by this
writer. Edit/capture dates do not date feature introductions. These community reports select
no furniture controls, healing numbers or sleep mechanics, and do not extend bed/bedroll claims
to bench/stool IDs. Free inn recovery and separate paid, consensual sleep to the **next 07:00**,
with the approved reset/payment rules, remain unchanged (§3.1). No rate, source label or live
furniture/clock declaration changes; original activation/healing/rate histories remain research.

#### Item 24 — Candle appearance and placement reports (owner approved, 2026-10-04)

[Candle revision 19929](https://cubeworld.fandom.com/wiki/Candle?oldid=19929), edited
**2024-08-19T20:04:14Z**, reports the existing `static-entities.json#candles` descriptions:
**red/pink candles in dungeons, palaces and castles, emitting yellow light**;
**green candles in ruins and catacombs, emitting green light**; and **small, tall and large
forked** sizes. These are community appearance/placement descriptions, not proof of exclusive
locations: “found” does not mean “only found”.

The saved raw revision body/metadata and extracted passage were inspected here, from the
source-scout capture retrieved **2026-10-04**, not externally re-fetched, image-inspected or
original-build tested by this writer. The unscoped candle clauses supply no Alpha/Steam
introduction dates; edit/capture dates are not release dates. Pickup/activation behavior and
release histories remain unresolved. No lighting, placement, colors, sizes, source labels or
live declarations change.

#### Item 25 — Campsite furniture, not mandatory contents (owner approved, 2026-10-04)

[Campsite revision 18924](https://cubeworld.fandom.com/wiki/Campsite?oldid=18924), edited
**2024-08-07T07:34:17Z**, separately describes **campfires that “often” accompany campsites**,
**chairs for sitting**, and decorative **barrels, tables, tents and wagons**. This is a community
furnished-resting-place report, not a required complete layout for every camp. Item 21's
occasional NPC/monster-resting observation remains distinct and unchanged.

The saved raw revision body/metadata and extracted passage were inspected here, from the
source-scout capture retrieved **2026-10-04**, not externally re-fetched, image-inspected or
original-build tested by this writer. These unscoped furniture clauses do not inherit Steam
from the page's separate Steam map/boss paragraph. “Often” does not mean every camp, and
edit/capture dates supply no release chronology. No exact stool/bench IDs, sitting-heal effect,
cooking behavior or required camp contents are selected. Furniture/release histories remain
research; no campsite layout, sleep rule, source label or live declaration changes.

#### Item 26 — Archived camp-bed sleep report (owner approved, 2026-10-04)

The archived [Camp Bed article, reached through Bedroll](https://web.archive.org/web/20130711002813id_/http://cubeworldwiki.net:80/index.php/Bedroll),
revision **6155**, says sleeping **“simultaneously speeds up time and replenishes health.”**
Wayback snapshot **20130711002813** and header Memento-Datetime **2013-07-11T00:28:13Z**
establish documentary timing, not feature introduction or demonstrated original-build behavior.
The body says last modified **10 July 2013 at 05:23**, timezone unspecified.

Saved body/headers/metadata were inspected here; capture timestamp **2026-10-04T21:01:27Z**
was recorded before the response (HTTP 200 / curl exit 0), not its completion time. No external
re-fetch, image inspection or original-build execution. This community report selects no rate,
controls, combat restriction, Steam scope, bench/stool effect or inn-like skip. Free inn recovery
and separate paid, consensual sleep to the **next 07:00**, with approved reset/payment rules,
remain unchanged (§3.1); original sleep histories and baseline/units remain research (items 10–11/23).
No furniture/clock declaration, source label or gameplay change follows.

#### Item 27 — Qualitative refining chains (owner approved, 2026-10-04)

These pinned community passages attribute qualitative conversions and only explicitly named
stations, not input/output counts or original Alpha/Steam recipes:

| source / revision edit timestamp | reported conversion / station |
|---|---|
| [Furnace 19644](https://cubeworld.fandom.com/wiki/Furnace?oldid=19644), **2024-08-11T18:55:41Z** | Iron, Silver and Gold Nuggets → material cubes at a Furnace. |
| [Saw 19638](https://cubeworld.fandom.com/wiki/Saw?oldid=19638), **2024-08-11T18:50:27Z** | Wood logs → Wood Cubes at a Saw. |
| [Linen Yarn 18758](https://cubeworld.fandom.com/wiki/Linen_Yarn?oldid=18758), **2024-08-07T00:34:05Z** | Plant fibers → Linen Yarn at a Spinning Wheel. |
| [Cotton Yarn 18783](https://cubeworld.fandom.com/wiki/Cotton_Yarn?oldid=18783), **2024-08-07T01:06:25Z** | Cotton capsules → Cotton Yarn at a Spinning Wheel. |
| [Silk Yarn 18784](https://cubeworld.fandom.com/wiki/Silk_Yarn?oldid=18784), **2024-08-07T01:06:46Z** | Cobweb → Silk Yarn; this passage specifies **no station**. |

Saved raw bodies/metadata and wikitext were inspected here from prior current-body captures
(batch timestamp **2026-10-04T17:17:32Z**), not newly discovered, externally re-fetched or
archival release bodies. Edit/capture dates supply no release/introduction history or demonstrated
original-build behavior. No ratio, yield or 1:1 conversion follows; `recipes.json#refining`'s
input **1** values are not verified history. Silk-station history and refining quantities remain
research. The separate Spinning Wheel yarn-to-armor clause is not used to redefine stations.
**D6 and the approved two-handed wand/boomerang costs of 20 wood cubes remain unchanged.**
No recipe, station, source label, live-data or gameplay change follows.

#### Item 28 — Named Golem AND Troll reports (owner approved, 2026-10-04)

[Golem revision 19270](https://cubeworld.fandom.com/wiki/Golem?oldid=19270), edited
**2024-08-09T02:02:45Z**, describes **elemental giants** and a **thrown boulder resembling
an Iron Deposit**. These unscoped trait sentences do not inherit Steam from the adjacent
mission sentence. “Most landscapes” versus infobox “All” proves no exhaustive habitat list.
[Troll revision 19806](https://cubeworld.fandom.com/wiki/Troll?oldid=19806), edited
**2024-08-13T16:42:07Z**, says **“Like all boss type monsters, it can break terrain.”**
Record only the **named Troll terrain-breaking report**, not that universal boss generalization.

Saved raw bodies/metadata and extracted wikitext were inspected here; retrieval batch timestamp
**2026-10-04T21:00:24Z** is not an individual response completion time. These are current edited
community-wiki bodies, not archival release bodies, externally re-fetched pages or original-build
execution. Edit/capture dates establish no release/introduction dates or confirmed Alpha/Steam
trait histories. Neither report grants **Dark Troll/Yeti/Ember Golem/Snow Golem inheritance**,
new attacks, scaling or encounters, or establishes big-weapon/Earthquake traits. Habitat and other
trait histories remain research; earlier family/species approvals stand. No source label, live
declaration or gameplay change follows; this records reports, not newly implemented traits.

#### Item 29 — Early sleep instructions and clock estimates (owner approved, 2026-10-04)

[Sleep revision 4042](https://cubeworld.fandom.com/wiki/Sleep?oldid=4042), edited
**2013-07-12T06:25:26Z**, instructs approaching the **head of a bed and hitting R** and
reports sleep's main use as **refilling HP**. It estimates **one game minute per about six
real seconds normally**, versus **one game minute per about half a real second sleeping
at camp**, separately describing an **inn-at-night jump straight to morning**.

The saved raw revision body/metadata and capture sidecars were inspected here, not externally
re-fetched or original-build tested. Source-scout request-start **2026-10-04T22:31:55Z** is not
response completion; the edit date is documentary timing, not feature introduction. These are
paired community estimates, not verified original Alpha/Steam rates or a resolution/replacement
of the qualified **100×** reference (items 10–11/23/26). No ratio, furniture
controls, numeric healing, combat restriction or bench/stool extension is selected. Free inn
recovery and separate paid, consensual sleep to the **next 07:00**, with approved reset/payment
rules (§3.1), remain unchanged. No clock/furniture declaration, source label or gameplay change;
original sleep activation/healing/rate/baseline histories remain research.

#### Item 33 — Slime habitat and colour reports (owner approved, 2026-10-04)

[Slime revision 19848](https://cubeworld.fandom.com/wiki/Slime?oldid=19848), edited
**2024-08-14T22:13:29Z**, describes uncommon monsters naturally spawning in **“Mountain
Areas”** and says **“Slimes will appear in any color in any biome”**, including **Blue
Slimes not being restricted to Snowlands**. These are unscoped community habitat/colour
reports, not numerical rarity, the named **Mountains landscape** specifically or a guarantee
of every colour in every land. The nearby Steam Slime Wells / Alpha Djinn-in-Deserts bullets
(item 9) do not date these clauses or give whole-family ancestry.

Saved raw revision body/metadata and capture sidecars were inspected, from a prior scout's
2026-10-04 capture, not externally re-fetched, image-inspected or original-build tested.
Edit/capture timing is not release or first-introduction evidence. Existing species/family
and roster declarations are unchanged; their broader wording is not verified by this passage.
Per-membership histories remain research; no encounters, source labels, rarity or live-data
changes follow.

#### Item 34 — Three individual Runner habitat reports (owner approved, 2026-10-04)

[Runner revision 19849](https://cubeworld.fandom.com/wiki/Runner?oldid=19849), edited
**2024-08-14T22:13:45Z**, reports these individual memberships:

| named creature | reported habitat |
|---|---|
| Snow Runner | inhabits Snowlands |
| Leaf Runner | lives in Jungles |
| Desert Runner | spawns **exclusively in Deserts** |

Exclusivity belongs only to the Desert Runner sentence, not Snow/Leaf Runners or the whole
family. These unscoped community reports supply no release dates, whole-family ancestry or
new successful-taming proof; adjacent food sentences remain reports, not demonstrated taming.
Saved raw body/metadata and capture sidecars were inspected from the prior scout's 2026-10-04
capture, not externally re-fetched, image-inspected or original-build tested. Edit/capture
timing is not release/first-introduction evidence. Existing species memberships, foods, family
and roster declarations remain unchanged; no species moves, bait, source labels or encounters
are selected. Per-membership release histories and other traits remain research.

#### Item 35 — Limited HUD descriptions and placement disagreement (owner approved, 2026-10-04)

[User interface revision 14709](https://cubeworld.fandom.com/wiki/User_interface?oldid=14709),
edited **2019-10-30T21:31:20Z**, reports a **lower-right Message Area** with the last
**“nine or so” item/XP messages**, **lower-centre HP/MP and Quick Slot Bar** (M1, M2,
historical keys 1–4 and Q), and **upper-right Environment Display** (time, temperature,
humidity, minimap and compass). It also puts **Character Details upper-right** (head, name,
level/class, HP and current/needed XP), unlike **top-left** in `ui.json#hud.portrait` and
`research/research_systems.md §5.1`. Preserve this textual disagreement; no HUD move or
screenshot-based resolution follows.

Saved raw revision body/metadata and capture sidecars were inspected from the prior scout's
2026-10-04 capture, not externally re-fetched or original-build tested; **no screenshot was
inspected**. The 2019 edit identifies no original build or feature introduction and supplies
no blanket Alpha/Steam UI ancestry. **“Nine or so” is approximate, not an exact message cap**;
historical keys 1–4 do not override **Assassin's approved key-3/no-key-4 exception** (§3.5).
Existing layout, controls, message limits and live declarations remain unchanged; no source
labels or interface work follows. Remaining UI/camera histories stay research.

#### Item 36 — Cobweb processing at a Spinning Wheel (owner approved, 2026-10-05)

[Steam guide 1873333729](https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729)
says **“Spinning Wheel - Used for spinning cobwebs and cotton into usable materials/”**.
This supplies a cobweb-processing station lead beyond item 27's station-unspecified Silk Yarn
passage, but names **neither the output nor quantities**. It does not verify one cobweb → one
yarn or redefine the existing silk chain, recipes or stations.

The saved raw guide body and capture sidecars were inspected from the retained
**2026-10-04T17:17:23Z** capture, not externally re-fetched, image-inspected or original-build
executed. Source/edit/capture dates establish no release or introduction history. Refining
quantities and original recipes remain research; no crafting, source-label or live-data change.

#### Item 39 — Snout Beetle traits and a visual bug report (owner approved, 2026-10-05)

[Snout Beetle revision 19194](https://cubeworld.fandom.com/wiki/Snout_Beetle?oldid=19194),
edited **2024-08-08T23:50:27Z**, reports **dodging and Intuition**, and a bug causing a
**charged shot's model to continuously grow until it takes up the entire screen**.
Record only these named-species reports, not the source's **“only monsters”** exclusivity,
Beetle-family inheritance, growing damage or new attack behavior.

**Owner amendment: “Approved (I don't want a bug implemented)”. The visual bug is historical
documentation only; do not implement it.** Saved raw revision body/metadata and capture
sidecars were inspected, not externally re-fetched, image-inspected or original-build tested.
Edit/capture dates do not authenticate Alpha/Steam trait or release histories. Existing combat,
encounters and declarations stand; no attacks, bug, source labels or live-data changes.

#### Item 40 — Undead villagers versus population speculation (owner approved, 2026-10-05)

[Undead revision 18595](https://cubeworld.fandom.com/wiki/Undead?oldid=18595), edited
**2024-08-06T07:14:42Z**, describes **humanoid Undead as passive villagers in Deadlands
and Dark Woods**, not exclusively Undead towns or a population census.
The [cities thread](https://steamcommunity.com/app/1128000/discussions/0/1633040337766628105/)
displays **10 September 2019**: its OP says **“all cities are human”**; the reply suggests
faction cities and conditionally Undead inhabitants, explicitly saying **“We can't say for
sure”** and **“it's only speculation at this point”**. It identifies no tested build and
supplies no Deadlands/Dark Woods exception.

Saved raw wiki revision/metadata, thread body/date and sidecars were inspected, not externally
re-fetched or original-build tested. Displayed/edit/capture dates do not authenticate original
behavior or release history. The wiki report and speculative thread do not overturn item 20,
settlement populations/safety or **Skeleton Dog's separate approved dog rules**. No census,
population algorithm, encounter, source label or live declaration is changed.

#### Item 41 — Some mobs bring out lanterns (owner approved, 2026-10-05)

[Darkmega's Steam guide 1871398574](https://steamcommunity.com/sharedfiles/filedetails/?id=1871398574)
says dark nights make light sources, including **“some mobs who bring out lanterns”**,
easier to see. This limited observation establishes neither **every villager's nightly
schedule**, lantern activation/put-away timing nor an `A*` route; it complements item 21,
not a complete shipped schedule.

The actual retained raw `guide.body` and sidecars were inspected from the prior scout's
**2026-10-04T21:01:17Z** capture, not externally re-fetched, image-inspected or original-build
tested. Capture/publication timing is not release evidence. Adjacent inn/reset/traversal
advice does not override hybrid rules. No lantern, lighting, schedule, source-label or live
change; original schedule and lantern histories remain research.

#### Item 42 — Individual dark-Alpaca habitats (owner approved, 2026-10-05)

[Alpaca (dark) revision 19843](https://cubeworld.fandom.com/wiki/Alpaca_(dark)?oldid=19843),
edited **2024-08-14T22:12:11Z**, lists **Greenlands, Snowlands and plains** for the
individual dark Alpaca. **Plains is descriptive wording, not a newly defined biome**.
This establishes neither exclusive distribution nor the whole Alpaca family's Desert
presence; it does not redefine any food or habitat.

Saved raw revision body/metadata and sidecars were inspected, not externally re-fetched,
image-inspected or original-build tested. Edit/capture timing is not release/first-appearance
evidence or blanket family ancestry. Existing species/family/roster and taming declarations
stand; per-membership histories remain research, with no animals moved, labels or live changes.

#### Item 43 — Possessive item-name examples (owner approved, 2026-10-05)

The [trading thread](https://steamcommunity.com/app/1128000/discussions/0/1735507058422798015/)
reports these exact possessive item names:

- **Drakzic's Brilliant Iron Dagger+**
- **Izaira's Brilliant Wood Boomerang+**
- **Lorax's Exceptional Cotton Gloves+**

Its blanket **“legendary + items”** claim disagrees with the **Exceptional** prefix's
existing rarity lists. Preserve that disagreement, not a rarity reassignment. Historical
**`+` spelling grants no excluded mechanics** or regional gear power loss (§1).
These examples do not recover the naming algorithm or weaken **always-named Epic/Legendary
equipment** (§6); item 22's original generation/release histories remain research.

Saved raw thread body/date and capture sidecars were inspected, not externally re-fetched or
original-build tested. Displayed/edit/capture timing supplies no authenticated original behavior
or release history. No generated names, naming frequency, rarity, source labels or live changes.

#### Item 44 — Retrieved music catalog, not authenticated shipped soundtrack (owner approved, 2026-10-05)

The retrieved [KHInsider catalog](https://downloads.khinsider.com/game-soundtracks/album/cube-world-gamerip)
claims **Steam/Windows**, **2019**, **Gamerip**, uploaded by **MuttMondo**, added
**24 June 2021**, with these **28 titles** in listed order:

Beach; Boss; City; Cult Of Doom; Deadlands; Desert; Druids Of Mana; Dungeon; Enchanted Forest;
Greenlands; Home; Jungle; Maintheme; Mountains; Night; Ocean; Order Of The Light; Savannah;
Shrine; Steel Empire; Success; Tribe; Unholy Pact; Village; Village2; Winter; Wood; Woodlands.

These are **catalog claims, not authenticated build inclusion or completeness**. No audio
was inspected: **Dungeon is not proven Bgum**, **Maintheme is not proven Explorers**, and
**Ocean is not proven the 2017 preview**. Existing music declarations stand; the old
`audio.json#tracks._gap` is retained live-data state, not a claim that this catalog was never
retrieved. Item 7's full original soundtrack and identity histories remain research.

Saved raw catalog header/all title cells and capture sidecars were inspected, not externally
re-fetched, audio-downloaded/played or original-build tested. Addition/year/capture dates do
not authenticate a build manifest or release history. No soundtrack assets, playback, track
identity, source labels or live declarations change.

#### Item 45 — Additional Item Vendor stock report (owner approved, 2026-10-05)

[Steam guide 1873333729](https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729)
says **“Vendor that sells glass bottles, sugar cubes, bombs, and sometimes another pet
treat.”** Keep **sometimes** and the **unnamed treat**, not a fixed bait identity or
universal always-available stock. Sugar cubes are not thereby item 38's ambiguous candy.
This vendor sentence is additional to item 19's Item Shop/Leftovers evidence, not a replacement.

Saved raw body/sidecars and capture limits follow item 36. The report supplies no prices,
quantities, first appearance or release chronology and selects no stock or purchase rule.
Existing shop/reset/pricing rules and live declarations stand; stock/quantity/food histories
remain research. No purchases, source labels, loot or gameplay changes follow.

#### Item 46 — Questionable Iceflower conversion report (owner approved, 2026-10-05)

[Iceflower revision 15027](https://cubeworld.fandom.com/wiki/Iceflower?oldid=15027) says
**“The Iceflower can be used on a Campfire to receive a Heartflower.”** The immediately
adjacent **“Something gourmet, like a steakhouse filet or a cut still on the bone.”** is
unrelated text: retain this as a **questionable qualitative community report**, not verified
conversion behavior. It confirms neither exactly one Heartflower nor the existing **1–3**
yield in `ingredients.json#iceflower` / `recipes.json#refining.heartflower-from-iceflower`.
Quantities and authenticated original-build behavior remain unresolved; no conversion changes.

For items 46–52, saved raw community-wiki revision bodies/metadata and capture sidecars were
inspected, not externally re-fetched or original-build tested. Captures are dated **2026-10-05**,
including the retained Iron Armor/Fists response; wiki edit/capture dates are not release or
introduction dates. These reports select no new A/S labels, live-data or gameplay changes.
Items 1–45 and all approved hybrid rules stand; remaining histories stay research.

#### Item 47 — Deposit nuggets, not a range for every gem (owner approved, 2026-10-05)

[Deposit revision 19729](https://cubeworld.fandom.com/wiki/Deposit?oldid=19729) reports
**1–3 nuggets** when destroying deposits. Its surrounding **ore and gems** wording is
ambiguous; the quantity's explicit noun is **nuggets**, not every gem or deposit kind.
This does not verify §3.1 / `deposits.json`'s generic 1–3 yield for gems, Ice Crystal or
Sandstone. Per-kind yields/probabilities remain research, not selected ranges or odds.
Source-inspection/date limits follow item 46;
mining rewards, refining rules, labels and live declarations remain unchanged.

#### Item 48 — Iron armor ingredients, not quantities (owner approved, 2026-10-05)

[Iron Armor revision 12983](https://cubeworld.fandom.com/wiki/Iron_Armor?oldid=12983)
reports **Iron Cubes + required gems for non-common armor**.
This is ingredient evidence only: no counts or crafting station are supplied. It does not
verify iron costs from item 18's cotton table or the other-material assumption in
`recipes.json#gear-armor-quantities`, nor generalize to linen/silk. Noncotton quantities and
station histories remain research; **D6 and approved hybrid recipes stand unchanged**.
Source-inspection/date limits follow item 46; no recipes, labels or live declarations change.

#### Item 49 — Fist materials, not a crafting bill (owner approved, 2026-10-05)

[Fists revision 20017](https://cubeworld.fandom.com/wiki/Fists?oldid=20017) reports
**Cotton Yarn and Iron Cubes** as crafting requirements. It supplies no counts or station
and confirms neither the current **2 yarn + 5 iron cubes** nor the Anvil in
`recipes.json#gear-weapons.fist`. Recipe quantities, station and release histories
remain research; **D6 and approved hybrid recipes stand unchanged**. Source-inspection/date
limits follow item 46; no crafting costs, materials, labels or live declarations change.

#### Item 50 — Individual Baby Mammoth habitat and grouping report (owner approved, 2026-10-05)

[Baby Mammoth revision 20097](https://cubeworld.fandom.com/wiki/Baby_Mammoth?oldid=20097)
reports **Snowlands-only habitat** and that Baby Mammoths **do not group with adult Mammoths**.
This individually attributes the retained `research_creatures_quests.md:80` report, not
a new spawn guarantee or pack count. The source's comparison with Baby Elephant establishes
**no new Baby Elephant grouping rule** or inherited family trait. Source-inspection/date limits
follow item 46; no release chronology, encounters, habitats, food/mount rules, labels or live
declarations change. Other encounter histories remain research.

#### Item 51 — Wraith swiping sound when attacking (owner approved, 2026-10-05)

[Wraith revision 20152](https://cubeworld.fandom.com/wiki/Wraith?oldid=20152) reports
**rapid swiping sounds when attacking despite having no limbs**. Keep the **attack condition**:
this is not an unconditional ambient sound rule for `audio.json#ambient.S`. **Rapid** is
qualitative, not a measured rate or authenticated sound identity. No audio, images or assets
were inspected; source-inspection/date limits follow item 46 and establish no new source-era tag.
Existing pursuit, unkillability and pet-avoidance descriptions are not reopened. Audio/behavior
histories remain research; no sounds, behavior, labels or live declarations change.

#### Item 52 — Reported Wolf absence from Steam (owner approved, 2026-10-05)

[Wolf revision 20167](https://cubeworld.fandom.com/wiki/Wolf?oldid=20167) explicitly says
**“Wolf does not exist in the Steam Version.”** This corroborates the retained historical
**Alpha-only** description (`research_creatures_quests.md:121`, `creatures.json#wolf`),
not an authenticated roster census or first Alpha appearance. Source-inspection/date limits
follow item 46; no release chronology or broader roster ancestry follows. **Wolves remain in
the approved hybrid game**: this historical absence report selects no removal, new food/mount
rule, source label or live-data change. Remaining species histories stay research.

#### Item 53 — Ranger firing and comparative range (owner approved, 2026-10-05)

[Bows revision 19306](https://cubeworld.fandom.com/wiki/Bows?oldid=19306)'s generic
**Description** reports that **arrows can be fired in any direction, even out of combat**,
and that **Bows and Crossbows reach further than Boomerangs**. Its **unlimited arrow
ammunition** corroborates the existing rule (`weapon-types.json#bow`,
`research_classes_combat.md §4`), not free M2 attacks. The direction sentence concerns
arrows, not unrelated weapons. This qualitative comparison supplies no numerical ranges,
particular edition or first appearance; existing MP costs, source tags and D24 movesets stand.

The saved public-safe article-text extract and allowlisted metadata were inspected, not
externally re-fetched or original-build tested. This is rendered-DOM article text, **not raw
HTTP bytes**; the revision pin comes from captured metadata, not a separately fetched pinned
URL. Modification timestamps are unavailable; the **2026-10-05** capture is not a release
date. Original authenticated DOM/owner HTML is private and must not be published. No gameplay,
live declarations, labels, balance or checker changes follow; remaining histories stay research.

#### Item 54 — NPC-attributed dungeon warning (owner approved, 2026-10-05)

[Dungeon revision 19603](https://cubeworld.fandom.com/wiki/Dungeon?oldid=19603) quotes
**“Dungeons are a dangerous place. Don't forget to take some potions with you.”** and
attributes it to **“-NPCs”**. The quotation follows **Conceptualized Content** and the
adjoining **“On Instagram, you can see early progress of 2019 cube world.”** sentence.
Preserve that placement **without deciding the quotation itself is conceptual-only** or
claiming the preview was inspected. This supplies no shipped speaker, dialogue trigger,
edition or release chronology; the preview sentence is not an authenticated release date.

The existing `npc-roles.json#dialogue-corpus.known-lines` already includes the exact line
(`research_creatures_quests.md §4`). This records attribution, **not dialogue delivery**,
a potion requirement or a new quest. Public-safe source/metadata inspection and date/privacy
limits follow item 53; no preview, original build, images or assets were inspected/executed.
Existing dialogue declarations and hybrid rules stand; other dialogue histories remain research.
No gameplay, live declarations, source labels or checker changes follow.

#### Item 55 — Historical Steam UI/minimap controls (standing sourcing approval, 2026-10-05)

[How to play guide for Cube World revision 20077](https://cubeworld.fandom.com/wiki/How_to_play_guide_for_Cube_World?oldid=20077),
under **Controls / Steam Version**, reports **F2 makes UI smaller / F3 bigger**, with each
explicitly not affecting the minimap; **F4 hides UI**; **F5 makes the minimap smaller / F6 bigger**.
This precisely attributes the existing historical `keybinds.json#{ui-scale,hide-ui,minimap-scale}.S`
cells and §3.7 option descriptions. Item 8's independent-minimap-scaling patch report remains
separate: this guide supplies no first appearance or patch date for these exact controls.

The retained public MediaWiki revision body and matching extracted JSON were inspected, not
externally re-fetched, image-inspected or original-build tested. Edited **2024-08-22T18:15:12Z**;
prior capture sidecars record request start and response end **2026-10-05T00:38:32Z**.
Edit/capture dates are not release dates or evidence of demonstrated original behavior.
This is a bounded community report, not whole-guide ancestry or adoption of its unrelated skill
cooldown/pet-food claims. **D17's hybrid F3 debug-menu binding remains unchanged**; no hybrid
control selection, UI implementation, source label, live declaration or checker change follows.
Other UI/control histories remain research.

#### Item 56 — Historical interaction/climbing reports (standing sourcing approval, 2026-10-09)

[How to play guide for Cube World revision 20077](https://cubeworld.fandom.com/wiki/How_to_play_guide_for_Cube_World?oldid=20077),
under **Controls / Alpha Version** and **Controls / Steam Version**, labels **Alpha R / Steam E**
**Interact**: opening chests, talking to NPCs and picking up items. It labels **Alpha Ctrl / Steam E**
**Climb**: climbing walls at a stamina cost.

Preserve the disagreement: the Alpha guide groups pickup under **R**, while
`keybinds.json#pick-up.A` separately declares **E**. This does not resolve that history or change
either declaration. The guide does not establish hold, grab/Shift qualifiers, first appearance,
patch date or demonstrated original-build behavior. Public evidence/date limits follow item 55;
this is not whole-guide ancestry. **D13's hybrid interaction, pickup and climbing remain E**;
no gameplay, live declarations, source labels or checker changes.

### Constraint catalog

| id | rule | layer |
|---|---|---|
| c-race-class | any race × any class × either gender is valid | type |
| c-spec-of-class | specialization.class == character.class; player starts as spec index 0 | load |
| c-one-active-pet | at most one pet summoned; one of each pet-food carried | runtime |
| c-riding | hybrid: mounting requires 5 Pet Master points, ≥1 Riding point, globally acquired Reins and a rideable tamed pet; further Riding points improve speed; no new species riding permission, Reins route or slot (§3.2 pet) | runtime (deferred) |
| c-gliding | hybrid: gliding requires 5 Climbing points, ≥1 Hang Gliding point and a Hang Glider bought from an item vendor and equipped in the single special slot; buying alone is insufficient; further Hang Gliding points improve speed (§3.5) | runtime (deferred) |
| c-sailing | hybrid: sailing requires 5 Swimming points, ≥1 Sailing point and a Boat bought from an item vendor and equipped in the single special slot; buying alone is insufficient; further Sailing points improve speed; boat and glider cannot be equipped together (§3.5) | runtime (deferred) |
| c-creature-family | primary and descriptive references name defined creature families; at most one primary per creature, consistent with §3.2 approved assignments; without a primary, the family modifier is ×1.0 and other ordinary stat calculations remain; descriptive memberships never supply or stack family stat modifiers, nor imply species-trait inheritance | load+runtime (deferred) |
| c-skeleton-dog-encounter | Skeleton Dog has an independent 1% chance per individual dog spawn, not per pack, all creatures or a relative species weight; mixed packs are permitted and no quota is guaranteed; applies wherever dogs already spawn, preserving settlement safety; existing skeleton-only dog encounters use Collie for ordinary outcomes, preserving dog frequency/pack sizes and other existing ordinary selections, not extra unrestricted skeletal spawns (§3.2) | generator (deferred) |
| c-skeleton-dog-taming | Skeleton Dogs follow normal dog behavior for the same encounter/state, including retaliation, pack response and taming reactions, with no skeleton-only passivity exception (§3.2 item 8); Bubble Gum tames them under general eligibility restrictions and settlement protection (§3.2 item 9) | runtime+data (deferred) |
| c-food-id | pet-food.tames names defined creatures by stable ID and agrees with each creature's tame-food; normally the food subtype matches its species' known source entity ID (alpha or post-alpha, no alpha-range clamp); the sole approved shared-food exception is Bubble Gum → Collie and Skeleton Dog, retaining subtype 19 from Collie without assigning it to Skeleton Dog; other pairings/IDs are unchanged (§3.4) | load (shared-food support deferred) |
| c-weapon-class | equipping weapon-type/armor material requires matching class (red name otherwise) | runtime |
| c-hands | 1H ×2 or 1H + shield or one 2H; bracelets need two for full damage; hybrid wand is mechanically 2H with no other hand item, regardless of pose (§3.3 weapon-type; wand enforcement deferred) | runtime |
| c-cube-cap | upgrades ≤ 16 (1H) / 32 (2H, shield); wood cubes only on wood weapons, iron on metal | load+runtime |
| c-spirit-level | A: weapon.level − 10 ≤ spirit.level ≤ weapon.level | runtime |
| c-power-gate | A / hybrid: item.level ≤ power(player.level) for full strength; formula learning retains its sufficient-power requirement. Hybrid books record recipes immediately, but above-power recipes remain known and visibly locked against crafting until their requirement is reached; duplicate acquisition never removes the lock (§3.5 power-gate) | runtime (recipe enforcement deferred) |
| c-book-recipe-persistence | hybrid: book-learned recipes remain known to that character across lands and sessions, with no relearning on travel, including between worlds under persistence item 1 (§3.7 save-data) | runtime+save-data (deferred) |
| c-permanent-source-claim | hybrid: at most one claim per character/saved-world/artifact-or-one-time-book-source; claims remain available to other characters at the source and are not renewed by leaving, restarting, returning or daily enemy resets (§3.7 save-data, item 5; §3.1 world/reset item 3); ordinary ground loot unchanged | runtime+save-data (deferred) |
| c-recipe-learning | hybrid: books/formulas share one known-recipe set per character, including known-but-power-locked recipes; repeated learning grants nothing extra; books teach only unknown recipes without rerolls/compensation; an already-known formula remains unconsumed, without bypassing c-power-gate (§3.4 recipe) | runtime (deferred) |
| c-region-lock | DROPPED (D4). S reference: item.land ≠ current land ∧ ¬plus → worn; key items inert | — |
| c-plus-adjacent | DROPPED (D4). S reference: plus item full stats iff current land adjacent | — |
| c-gear-global | hybrid: an item's stats are identical in every land; key items and artifacts work everywhere once found | runtime |
| c-climbing | hybrid: basic climbing needs neither points nor Spikes; Climbing points reduce stamina drain and global Climbing Spikes reduce consumption by 75%, not eliminate it; 5 Climbing points remain a Hang Gliding prerequisite; item 5 applies Spikes after skill reduction (remaining cost ×0.25), never additive percentage points; no skill curve/floor or artifact-combination rule inferred (§3.4/§3.5) | runtime (deferred) |
| c-rarity-range | rarity ∈ 0..4 for generated items (5 = mythical bug, off by default) | load |
| c-stat-roll | roll = ((attributes<<16)+modifier) mod 21 ∈ 0..20 | generator |
| c-loot-config | `design.loot`: every chance ∈ [0,1]; rarity-weights keys are rarities ≤ legendary with a positive sum; level-spread ≥ 0; gear-kinds and stack-cap.stackable name item-types; consumable-pool names consumables | load |
| c-stack-rule | only `design.stack-cap.stackable` item-types stack (no cap, D6); gear (has a modifier roll) is one item per entry | runtime |
| c-slot-accepts | an item equips only in a usable equipment-slot whose `accepts` lists its item-type and whose subtype restrictions it satisfies (§3.4 equipment-slot); weapon-type `offhand` hands → off-hand only; c-weapon-class and c-hands still apply | runtime |
| c-mp-range | mp ∈ [0, 100]; mage regenerates passively, others gain by hits/blocks/stealth/dodges; numbers `design.resources.mp` (D21) | runtime |
| c-stun-immunity | cannot re-stun while stars shown | runtime |
| c-threat-pair | at most one `threat` relation per ordered logical mob/player entity pair; each present relation has exactly one non-negative numeric `aggro-points` amount in aggro points, independent of other pairs; changing `current-target` does not clear it; decay/gains (including the full-stealth damage exception), the zero floor, player-death and arrival clearing, and escape/temporary-absence retention follow §3.2; actual mob death/respawn starts fresh, but midnight itself grants no survivor wipe (§3.1 world/reset item 4); decay reflects elapsed gameplay time even outside simulation radius; surviving-mob restart retains threat/order/neutral provocation under persistence item 9 (§3.2), with no downtime decay (§3.1) | runtime+save-data (deferred) |
| c-current-target | at most one present, living player target per mob; ordinary targeting compares that mob's eligible players by highest `aggro-points`, retains a tied current target, otherwise breaks positive-threat ties by earliest engagement; without a positive-threat priority or valid current target, choose the nearest normally detected zero-threat player without granting aggro/order (§3.2); player-death, zero-threat and arrival order resets, escape retention and fresh assignment follow §3.2; at zero, ordinary pursuit requires normal detection and hostility/provocation eligibility; equally nearest fallback ties are chosen randomly once with equal chances, then normal retention applies; Heroic Shout temporarily overrides ordinary targeting without threat/order gain; eligibility, duration, replacement, per-enemy simultaneous arbitration and termination follow §3.2; taunt expiry reflects elapsed gameplay time even outside simulation radius; taunt alone adds no neutral provocation or lasting ordinary caster eligibility (§3.2) | runtime |
| c-pack-response | only the generated pack responds, under the hostile-detection / aggressor-specific neutral-provocation rules in §3.2; friendly/passive creatures are excluded and protected return cannot be interrupted; share current sightings only, never threat/order, and select targets independently; each neutral clears its own provocation on arrival (§3.2) | runtime |
| c-return-home | pursuit beyond the home leash starts return regardless of threat; within it, target loss checks eligible positive-threat players then normal detection of eligible players (§3.2); attacks do not restart pursuit during return; ×2 normal return speed and 90% damage reduction (including DOT) until reaching home alive, then full HP and clear this mob's aggro/order toward every player and its neutral provocation once, ending both bonuses; no revival, cleansing or CC immunity; gains/decay continue until arrival and other mobs' records are unchanged; starting return cancels taunt, and new taunts neither interrupt nor queue for afterward | runtime |
| c-combo-reset | any attack with a hitbox that misses resets combo to 0, subject to the hybrid whole-channel and combo-neutral zero-damage-taunt rules in §3.3 combo-system; cap per weapon-type | runtime |
| c-dodge-cost | dodge costs 25 stamina; requires movement; standing still M3 = class skill (S); hybrid numbers `design.defence.dodge` (D23) | runtime |
| c-no-death-penalty | death never removes gold/items/xp; respawn at statue (A) / activated shrine (S) | runtime |
| c-time-speed | clock 10× real while the world runs; hybrid shutdown adds no gameplay time or reset catch-up (persistence item 8, §3.1); reference sleep 100× clock-only (baseline/units unresolved, source item 10 above); hybrid inn sleep skips to the next 07:00 without fast-forwarding combat/status effects/cooldowns (§3.1) | runtime (clock/save enforcement deferred) |
| c-midnight-reset | at 0:00 respawn eligible mobs, regen daily missions, deposits, plants; restock shops; hybrid defeated ordinary-dungeon/repeatable-daily enemies including bosses return, completed one-time-objective guards/boss stay cleared, and artifact/book claims never renew; preserve world improvements' existing reset rules; occupied dungeon/quest sites wait until all players leave, coalescing missed midnights into one pending refresh; the clock itself never heals/replaces living enemies or erases a fight, preserving ordinary threat/home-return rules (§3.1 world/reset items 3–4); sleep applies ordinary midnight resets once only if crossing midnight, never extra shop refreshes/mission rerolls merely for sleeping (§3.1) | runtime+save-data (deferred) |
| c-inn-hours | hybrid: separate 10-copper sleep service only 18:00–06:00 → next 07:00; all connected players explicitly agree, initiator pays the single fee only on success; refusal blocks skip without charge; healing and setting respawn stay free at any time without agreement (§3.1) | runtime |
| c-land-count | hybrid: exactly 1 settlement per land (approved 2026-09-27); S per land: gnomes = 4, books = 4, movement items ≤ 4, ticket items ≤ 3, key items ≤ 9, towers ≤ 5, settlements ≥ 1; A per land: settlements = 1, missions = 64 cells | generator |
| c-key-item-need | a key item spawns only if its lock type exists in the land | generator |
| c-boss-size | A: boss size/strength from 1 at lvl 1 to full at lvl 10; S: dungeon boss size capped so it fits inside | generator |
| c-arena-waves | exactly 5 waves with tier ladder W/G, W/G, G/B, B/P, P/Y | generator |
| c-mission-reward | S reward rarity = quest tier + 1 (cap legendary) | generator |
| c-world-bounds | hybrid: finite 1024×1024 lands, one land = one region, coordinates −512..511 inclusive on each horizontal axis; 16,384 blocks per land and 16,777,216 blocks per world side; no wrapping; outer boundary marked on map, outward travel including flight/teleport destinations prevented, with turn-back allowed and no special damage/death/forced teleport (§3.1 world) | generator+runtime/UI (deferred) |
| c-zone-size | A zone 256² blocks, region 64² zones; S zone 64² blocks; hybrid zone 64², land 256² zones (D12) | engine |
| c-block-rgb | every solid block has its own RGB; (0,0,0) in `.cub` = empty | data |
| c-name-length | player-character name 2..16 ASCII 32–126 (character creation; creature display names are free text) | runtime |
| c-versions-nonempty | every versioned content instance resolves ≥1 source-version tag explicitly or via a documented family/source inheritance rule, never guessed (item 9); source-independent config, qualified annotations and bounded inheritance follow Validation-contract mapping items 1, 3 and 4 above | load |
| c-roster-ids | every id in `creature-families.json#landscape-rosters` is a creature (D14) | load |
| c-rideable-conflict | resolved (F2): every `rideable` is a boolean, per-page value; a `?` here is a load error | load |
| c-hostile-in-city | villagers/animals inside settlements unattackable unless possessed | runtime |
| c-artifact-stat | definition/config and generated/runtime boundaries follow mapping item 4 above; seven traversal kinds, approved logarithmic config only, one kind plus attack/max HP per artifact and §3.4 accumulation; direct data correction/enforcement deferred | load+generator/runtime (deferred) |
| c-sim-radius | `design.spawns.ai.sim-radius` ≥ `aggro-range` + `leash`, so a creature can still notice you and walk home while you are around (D16) | load |
| c-frame-budget | physics 60 Hz; a tick slower than its budget slows game time instead of stacking catch-up ticks: `Engine.max_physics_steps_per_frame` = `design.frame-budget.max-catch-up-steps` (D17) | engine |
| c-xp-config | `design.progression`: kill-fraction ∈ (0,1]; gap-mult-range = [lo, hi] with 0 ≤ lo ≤ 1 ≤ hi; gap-per-level ≥ 0 (D19) | load |
| c-level-up | level never decreases; after settling, xp < xp-to-next(level); each level gained adds exactly `skill-points-per-level` (D19) | runtime |
| c-tree-shape | for every specialization the tree read from `abilities.json#alpha-tree` has exactly one class node per rank 1..3 and ≤ 1 ultimate; Assassin has Camouflage only at rank 3 and no separate ultimate node (§3.5, exception enforcement deferred); rank 1 and shared-column roots have `needs` 0, one root per shared column, every `unlocks-next` names a node of the same column (D20) | load |
| c-skill-spend | a point is spent only from the banked pool, one at a time, on a node whose prerequisite holds `needs` points; points never leave a node outside a trainer respec (D20) | runtime |
| c-ability-runtime | every class-column and ultimate node of every spec tree has a `design.abilities` entry whose `runtime` is in `runtimes`; cost mp ≤ 100, stamina ≤ `design.movement.stamina.max` or `all`; cooldown-s > 0; dash distance > 0, strike / burst / channel radius > 0, buff / channel duration-s > 0, heal cast-s ≥ 0, projectile / dash `throw` shots as c-moveset-config (D24); `design.status-effects` keys are status-effect ids and an `as` names another key (D21) | load |
| c-settlement-config | `design.settlement`: per-land = 1 (exact-count enforcement deferred), radius > blend ≥ 0, ring-radius < radius, every `buildings` entry is a `buildings.json#buildings` id, every service role is an `npc-roles.json` id, every landscape with a `gen` block has a `style-by-landscape` entry naming a `buildings.json#settlement-styles` id with two `style-colors`, `shop.rarity-cap` is a rarity ≤ legendary, `no-hostiles-within` ≥ radius (D22) | load |
| c-defence-config | `design.defence`: dodge stamina ∈ (0, stamina max], distance / duration-s > 0, iframe-s ≥ 0, every on-dodge key is a passive ability; block max / power-per-hit > 0, damage-reduction ∈ [0,1], front-dot ∈ [−1,1], regen-per-s ≥ 0, guardian-mult ≥ 1; stealth decay-per-s ≥ 0, still-mult ≥ 1, aggro-cut ∈ [0,1]; enemy-hit chances ∈ [0,1]; every `design.abilities` stealth-per-s ≥ 0 (D23) | load |
| c-moveset-config | `design.movesets`: every key is a weapon-type or `default`, an `as` names a plain entry; m1 / m2 `kind` ∈ `kinds`; `applies` (and finisher applies) are `design.status-effects` keys; damage-mult > 0; melee swing-mult / radius-mult > 0, lunge ≥ 0, finisher every ≥ 2 with chance ∈ [0,1]; projectile speed / radius / life-s > 0, count ≥ 1, spread / gravity / splash ≥ 0, pierce needs tick-s > 0; beam / at-cursor range / radius > 0; every non-offhand class weapon-type has an entry (D24) | load |
| c-feel-config | `design.feel`: hit-stop.time-scale ∈ (0,1), max-s ∈ (0,1], every `events.*.hit-stop-s` ∈ [0, max-s]; every `events.*.trauma` ∈ [0,1]; shake.decay-per-s > 0, max-offset ≥ 0, max-roll-deg ≥ 0, shake-mult ≥ 0; every `events.*.sfx` names an `audio.json#sfx-alpha-ids` id with a `design.feel.sfx` entry; every sfx hz > 0, len-s ∈ (0,1], noise ∈ [0,1] and has a `slide`; numbers.life-s > 0, crit-scale ≥ 1, rise-blocks > 0, font-size > 0, every colour a 3-array in [0,1] and a `hit` colour present (the fallback); impact.impact-s / impact-radius > 0, trail.trail-s / trail-every-s > 0, level-up.pop-s > 0, pop-scale ≥ 1, text non-empty; the required event ids `hit crit kill hurt block dodge shoot impact level-up pickup coin` all present (D25) | load |
| c-creature-roles | `design.creature-roles`: `default` ∈ {melee, ranged, mage}; every `any-class` key ∈ {melee, ranged, mage}, every weight ≥ 0, sum > 0; `melee.kind == "melee"`; `ranged` / `mage` `kind == "projectile"` with range > keep-away ≥ 0, windup-s ≥ 0, cooldown-s > 0, damage-mult > 0, `shot` passing the moveset shot checks (speed / radius / life-s > 0 …), every `applies` id a `design.status-effects` key, `sfx` an `audio.json#sfx-alpha-ids` id with a `design.feel.sfx` entry, `color` a valid html colour; every `species` key is a `creatures.json` id, every override key one of `range keep-away windup-s cooldown-s damage-mult shot applies sfx color`, and the merged result (species `shot` replaces the whole shot dict) obeys the same rules (D26) | load |
| c-drowning | S only: breath depletes underwater; empty → HP loss; wall-hold pauses | runtime |
| c-gate-doors | divine doors re-close at 0:00; bell spirit world lasts 30 s (F8) | runtime |

---

## 6. Generators

Procedural systems. Config + invariants in `instances/generators.json`. Seeds make output
reproducible; each generator lists invariants that a test can assert.

| id | input | output | invariants |
|---|---|---|---|
| gen-world | seed | hybrid: finite 1024×1024 grid of internal regions → lands; reference generation neighbourhood: region data 3×3 around player, region seeds 7×7 | same seed = same generation/geography, not mutable saved-world identity (§3.7); hybrid coordinates −512..511 on each horizontal axis, no wrapping (c-world-bounds); live `world-scales.invariants` “no borders” wording is not hybrid authority |
| gen-climate | seed, x, y | temperature, humidity, continent, relief → landscape choice (rules: `design.climate`) | equal-sized lands; features can appear off-biome (volcano in snow) |
| gen-terrain | land, zone coords | heightfield columns, caves, rivers+waterfalls, lakes, mountains/plateaus, mesas, overhangs; per-voxel RGB by block type & landscape palette | walkable roads with tunnels/bridges; water at rivers/lakes/oceans |
| gen-coarse-map `Ω` | land seed | coarse map placing streets, buildings, rivers, bridges, trees, caves logically before voxel detail | every structure reachable by road |
| gen-flora | landscape, zone | trees (procedural, unique), bushes, scrubs, cacti, flowers, mushrooms, fields | per-landscape rosters |
| gen-settlement | land | 1 (hybrid / A) / n (S) settlements: districts, procedural buildings (rooms, sizes, roofs), styles, NPC population + schedules, shops, inn, trainers, flight master (S) | ≥1 inn (A several, S exactly 1); shops per district; hybrid numbers `design.settlement` (D22) |
| gen-dungeon | land, dungeon-type, tier | layout (A linear + dead end; S room gauntlet), traps `A`, chests, spawns in groups 2–4, boss(es), artifact `S`, locks needing key items | entrance rules per type; at least one boss; artifact at end (S castles always); hybrid enemy refresh eligibility/timing and permanent claims follow c-midnight-reset |
| gen-poi | land | campsites, arenas, towers ≤5, circles, portals, pumps, trees, shrines, lore sites, spawner nests, hidden treasure, sky islands | counts in `c-land-count` |
| gen-missions | land, day | A: 8×8 cell boss missions; S: typed missions with icons and tiers, daily regeneration | tier ladder white→yellow present; S: gnomes/books once per land; hybrid refresh and source claims follow c-midnight-reset / §3.7 save-data |
| gen-spawns | zone, land level/tier | creature spawns: species by landscape roster, group sizes, hostility, humanoid class/spec, `+1..+4` multipliers (A), boss-ification chance; open-world numbers `design.spawns` (D14); role per group: creature combat-role, any-class rolled from `design.creature-roles.any-class` (D26) | dungeon mobs above surface tier; farm animals white |
| gen-boss | spawn | named, enlarged, coloured-tier variant with 1–2 random special moves; always-boss species; one fixed-type/level spirit cube per eligible non-mission boss kill (A / hybrid) | size scaling rule; terrain breaking; mission bosses, including Saurians, drop no spirit cube; normal mission rewards unchanged |
| gen-name | seed, kind | land names (`<Name> Plains…`), dungeon names ("Castle ___"), realm/leader/capital names, item names (affix + material + type + of-name), boss names, NPC names, quarter names | epic/legendary items always named |
| gen-item | tier/level, rarity roll, type, material, land (S) | `item` with modifier roll; stats via `gen-item-stats` | rarity ≤ legendary except mythical bug |
| gen-item-stats `A` | item | damage/HP/armor/resi/regen/tempo/crit from coremaze curves: `curve(n,r) = 2^((1 − 1/((n−1)·0.05+1))·3) · 2^(r·0.25)`, `curve2 = curve/8`, `n = level + 0.1·cubes`; per-type k and material multipliers | monotone in level and rarity; roll ∈ 0..20 |
| gen-loot | source level, species, seed | drops per `loot-rule`: coins, gear via `gen-item`, consumables, species items; numbers `design.loot` (D18) | level = source ± spread, ≥ 1; rarity ≤ legendary; same seed = same drops; bosses +1 rarity (S) |
| gen-realm `S` | region cluster seed | realm kind, names, leader bio, capital, lore sites, artifact set | 100 % lore ⇒ all artifacts revealed |
| gen-npc-appearance | race, gender, seed | head/hair model ids, hair RGB, part scales (Ω: fully procedural bodies, expressions) | asset counts in `races.json` |
| gen-schedule | settlement | daily A* paths for villagers; lantern at night; campsite rests | sleep at night |
| gen-key-items `S` | land | subset of the 9 key items consistent with locks present | `c-key-item-need` |

---

## 7. Open points for validation

Dated owner decisions (D) and research fact records (F), not a claim that every hybrid detail is
settled or implemented. The current open questions and approval/application checkpoint are in
`docs/ROADMAP/todo_decide.md §E`; preserve those deferrals. Earlier slice approximations below
are historical implementation stages, superseded where later decisions say so.

### Current unresolved hybrid questions (2026-10-05)

This index mirrors the open list in `docs/ROADMAP/todo_decide.md §E`; it does not choose defaults
or authorize implementation. Resolve each question before its affected slice.
Aggro items 1–14, including the two former open follow-ups, are approved and recorded in §3.2
(2026-09-27; `todo_decide.md §E`); implementation remains deferred.
Creature family items 1–9 are recorded: Skeleton Dog follows normal dog behavior, not a
skeleton-only passivity exception, and shares Bubble Gum with Collie. The independent 1% per-dog
chance, existing habitat scope and Collie fallback stand. No unanswered family proposal remains;
implementation is separately deferred.
Settlements/inn items 1–4 are recorded in §3.1 (2026-09-27). Traversal items 1–5 are recorded
(2026-09-28): training/item gates, corrected 75% Spikes reduction and remaining-cost stacking.
No presented traversal question remains. Books/formulas items 1–3 are recorded in §3.4/§3.5
(2026-09-28): permanent/global book recipes, shared knowledge/duplicates and immediate recording
with power-locked crafting. No presented books question remains; cross-world portability is
recorded under persistence item 1 (§3.7). **Artifact items 1–6 — DECIDED 2026-09-28:** recorded in §3.4; logarithmic
accumulation (initial z=0.1) replaces D6's decay/floor, preserving its rewards and other decisions.
No presented artifact question remains; independent review and parent verification passed
(`todo_decide.md §E`, with verification limits).
**Assassin item 1 — DECIDED 2026-09-28:** Camouflage is one rank-3 skill on key 3, with no
separate ultimate node or key-4 ability (§3.5). No presented Assassin question remains.
**Wand item 1 — DECIDED 2026-09-28:** mechanically two-handed despite a one-hand pose;
existing damage/attacks and 32-cube limit stand; common crafting costs 20 wood cubes under D6
(§3.3 `weapon-type`). No presented Wand question remains.
Direct data correction and implementation remain deferred; world/reset item 3 records cleared
dungeon/quest enemy eligibility (§3.1). Persistence approvals and recording status follow.

**Persistence / authority items 1–9 — DECIDED 2026-09-28:** all nine documentation decisions
are recorded. No presented Persistence / authority question remains.
Canonical rules: §3.1/§3.2/§3.7. Implementation is deferred; independent review and parent
verification passed (`todo_decide.md §E`, including evidence limits).
**World bounds / resets items 1–4 — DECIDED 2026-09-28:** all four recorded in
§3.1/§3.7/§5/§6. No presented world/reset question remains. Independent review and parent
verification passed (`todo_decide.md §E`, including evidence limits); implementation remains deferred.
**Validation-contract mapping items 1–4 — DECIDED 2026-09-28:** items 1–3 stand; item 4
records required heterogeneous paths/shapes, bounded source inheritance and check boundaries in
§5, requiring current definitions directly for this undeployed game (§0). No presented question
remains; source research/attribution below is unfinished. Enforcement is separately unauthorized.

**Validation-contract source item 5 — DECIDED 2026-10-04:** the pet-food summary is
corrected to 58 obtainable + five cut (§3.4), preserving F11.
**Validation-contract source item 6 — DECIDED 2026-10-04:** §3.4 records the named-food
Alpha lead, undated replacement and retained S/X annotations with their evidence limits;
unsupported release histories remain unresolved, not newly assigned labels.
**Validation-contract source item 7 — DECIDED 2026-10-04:** §5 records narrowly supported
mixed-container subfacts, dated previews and remaining uncertainty, not blanket inheritance.
Items 5–7 passed independent source review and parent verification (`todo_decide.md §E`,
including check limits); historical research and enforcement remain unfinished.
**Validation-contract source item 8 — DECIDED 2026-10-04:** §5 records additional dated
patch reports and their limits.
**Validation-contract source item 9 — DECIDED 2026-10-04:** §5 records the clarified
encounter/crafting/shop/map reports with narrow limits, not new gameplay rules.
**Validation-contract source item 10 — DECIDED 2026-10-04:** §5 qualifies historical
sleep-speed baseline/units as unresolved; hybrid normal time and inn skip remain unchanged.
Items 8–10 passed fresh independent source review and parent diff/validator/boot verification
(`todo_decide.md §E`, including limits); historical research and enforcement remain unfinished.
**Validation-contract source item 11 — DECIDED 2026-10-04:** §5 records fresh, revision-pinned
cuwo normal-clock code and the sleep constant's definition-only occurrence, not original Alpha/Steam
sleeping behavior. Item 10's historical units remain unresolved; no gameplay or live data change.
Fresh independent source review and parent diff/validator/boot verification passed
(`todo_decide.md §E`, including limits); source research and enforcement remain unfinished.

**Validation-contract source item 12 — DECIDED 2026-10-04:** §3.4 `pet-food` records the
pinned cuwo naming table and generic subtype-89 limit, not original-game food history.

**Validation-contract source item 13 — DECIDED 2026-10-04:** §3.4 records conflicting
Koala-food community reports, preserving Eucalyptus Candy, cut Kaliptus Leaf and unresolved chronology.

**Validation-contract source item 14 — DECIDED 2026-10-04:** §3.4 individually attributes
ten existing S-food pair reports, not first appearances, obtainability or successful taming.

**Validation-contract source item 15 — DECIDED 2026-10-04:** §5 records three revision-pinned
community-wiki UI patch reports, not interface work or restoration of excluded `+` equipment.
Items 12–15 passed fresh independent source review and parent actual-diff audit / bounded
validator/boot verification (`todo_decide.md §E`, including evidence limits).
Remaining histories are research, not unanswered proposals.

**Validation-contract source item 16 — DECIDED 2026-10-04:** §3.4 records the archived
Koala report's empty Food cell, not food identity, chronology or demonstrated taming.

**Validation-contract source item 17 — DECIDED 2026-10-04:** §5 records eight Forest rows
and bounded Beetle reports, not roster changes or release attribution.

**Validation-contract source item 18 — DECIDED 2026-10-04:** §5 attributes cotton quantities,
not other-material/weapon costs or new recipes.

**Validation-contract source item 19 — DECIDED 2026-10-04:** §5 records stock/Leftovers
reports, not probabilities, tier restrictions or economy changes.

**Validation-contract source item 20 — DECIDED 2026-10-04:** §5 distinguishes population
observations from a census or spawn algorithm.

**Validation-contract source item 21 — DECIDED 2026-10-04:** §5 records isolated NPC reports
and the lore-hint hypothesis, not a complete schedule or rewards.
Items 16–21 passed fresh independent source/diff/log review and parent actual-diff audit /
bounded validator/boot verification (`todo_decide.md §E`, including evidence limits).
Remaining histories are research, not unanswered proposals.

**Validation-contract source item 22 — DECIDED 2026-10-04:** §5 attributes the existing
rarity-prefix lists, preserving the always-named guarantee and unresolved name histories.

**Validation-contract source item 23 — DECIDED 2026-10-04:** §5 records bed/bedroll reports
and uncertain rates/inn wording, not furniture mechanics or a hybrid inn change.

**Validation-contract source item 24 — DECIDED 2026-10-04:** §5 attributes candle appearance
and placement reports, not exclusive locations, release dates or pickup/activation behavior.

**Validation-contract source item 25 — DECIDED 2026-10-04:** §5 attributes limited campsite
furniture reports, not mandatory layouts, sitting-heal/cooking rules or release history.
Items 22–25 passed fresh independent source/diff/log review and parent actual-commit/diff
audit / bounded validator/boot verification (`todo_decide.md §E`, including evidence limits).
Remaining histories stay research, not unanswered proposals.

**Validation-contract source item 26 — DECIDED 2026-10-04:** §5 records the archived
2013 Camp Bed report's qualitative sleep/time/health combination, not rates or demonstrated
original behavior.

**Validation-contract source item 27 — DECIDED 2026-10-04:** §5 attributes qualitative
metal/wood/linen/cotton/silk refining chains, not quantities, silk station or release histories.

**Validation-contract source item 28 — DECIDED 2026-10-04:** §5 attributes named Golem
(elemental giant/boulder) and Troll (terrain breaking) reports, not universal family/boss traits
or release histories. Items 26–28 passed fresh independent source/diff/log review and parent
actual-commit/diff audit / bounded validator/boot verification (`todo_decide.md §E`, with limits).
Remaining histories stay research, not unanswered proposals at that historical checkpoint.

**Validation-contract source item 29 — DECIDED 2026-10-04:** §5 records Sleep 4042's
head-of-bed R/HP-refill report and paired approximate normal/camp game-minute intervals,
not selected controls, healing or clock mechanics.

**Validation-contract source item 30 — DECIDED 2026-10-04:** §3.4 `pet-food` attributes
the current Alpha-focused Kotaku guide's ten wiki-credited pair reports, not an authenticated
2013 list, per-food obtainability, first appearances or demonstrated taming; no new A/S labels.

**Validation-contract source item 31 — DECIDED 2026-10-04:** §3.4 `pet-food` records
Leaf 10086's Koala association/unidentified-version unobtainability/cheat-acquisition report,
not demonstrated taming or chronology; Candy stays Koala's bait and Leaf stays cut.
Items 29–31 passed fresh independent source/diff/log review and parent actual-commit/diff audit /
bounded validator/boot verification (`todo_decide.md §E`, with limits) at that historical checkpoint.
Remaining histories stay research.

**Validation-contract source item 32 — DECIDED 2026-10-05:** §3.4 `pet-food` attributes
the daily stocked-type report, not a one-unit purchase limit or any selected quantity. Existing
carrying rules, obtainable Banana Mash and shared Bubble Gum remain unchanged.

**Validation-contract source item 33 — DECIDED 2026-10-04:** §5 attributes Slime
habitat/colour reports, not named-Mountains scope, numerical rarity or guaranteed distribution.
**Validation-contract source item 34 — DECIDED 2026-10-04:** §5 attributes Snow/Leaf/Desert
Runner memberships, with exclusivity only for Desert Runner, not release/taming proof.
**Validation-contract source item 35 — DECIDED 2026-10-04:** §5 attributes limited HUD reports,
preserving the Character Details placement disagreement, approximate messages and Assassin exception.
Items 33–35 passed fresh independent saved-source/diff/log review and parent actual-commit/diff
comparison / bounded validator/boot verification (`todo_decide.md §E`, with evidence limits).
Item 32's later approval is recorded above; verification evidence follows `todo_decide.md §E`.
No presented unanswered proposal remains.

**Validation-contract source item 36 — DECIDED 2026-10-05:** §5 item 36 records
Cobweb/cotton station lead, not output identity or quantities.

**Validation-contract source item 37 — DECIDED 2026-10-05:** §3.4 pet-food records
Narrator acquisition report, not guaranteed drops or taming proof.

**Validation-contract source item 38 — DECIDED 2026-10-05:** §3.4 pet-food records
Literal six-name list with ambiguous candy; flask price is not food pricing.

**Validation-contract source item 39 — DECIDED 2026-10-05:** §5 item 39 records
Named-species traits; visual bug documentation only, never implementation.

**Validation-contract source item 40 — DECIDED 2026-10-05:** §5 item 40 records
Passive humanoid villagers report separated from dated thread speculation.

**Validation-contract source item 41 — DECIDED 2026-10-05:** §5 item 41 records
Some-mobs dark-night observation, not universal schedules or timing.

**Validation-contract source item 42 — DECIDED 2026-10-05:** §5 item 42 records
Individual Greenlands/Snowlands/plains report, not whole-family distribution.

**Validation-contract source item 43 — DECIDED 2026-10-05:** §5 item 43 records
Exact possessive spellings; rarity disagreement and excluded plus mechanics preserved.

**Validation-contract source item 44 — DECIDED 2026-10-05:** §5 item 44 records
28 catalog titles/metadata, not authenticated inclusion or preview identities.

**Validation-contract source item 45 — DECIDED 2026-10-05:** §5 item 45 records
Glass bottles/sugar cubes/bombs and sometimes unnamed treat, not universal stock.

**Validation-contract source item 46 — DECIDED 2026-10-05:** §5 records a questionable campfire→Heartflower report, not quantity or original-build proof.

**Validation-contract source item 47 — DECIDED 2026-10-05:** §5 attributes 1–3 nuggets, not all-gem/deposit yields or probabilities.

**Validation-contract source item 48 — DECIDED 2026-10-05:** §5 attributes Iron Cubes/non-common gems only, not counts, stations or cotton-derived costs.

**Validation-contract source item 49 — DECIDED 2026-10-05:** §5 attributes Cotton Yarn/Iron Cube requirements, not the current 2+5 cost or station.

**Validation-contract source item 50 — DECIDED 2026-10-05:** §5 attributes Snowlands-only/no-adult-grouping Baby Mammoth report, not pack counts or Baby Elephant rules.

**Validation-contract source item 51 — DECIDED 2026-10-05:** §5 attributes qualitative rapid swiping when attacking, not ambient timing or inspected audio assets.

**Validation-contract source item 52 — DECIDED 2026-10-05:** §5 attributes reported Steam absence, not a census, first Alpha appearance or hybrid Wolf removal.

**Validation-contract source item 53 — DECIDED 2026-10-05:** §5 attributes arrow-direction/out-of-combat firing and Bows/Crossbows reaching further than Boomerangs, not numerical ranges, free M2, edition or first appearance.

**Validation-contract source item 54 — DECIDED 2026-10-05:** §5 attributes the exact NPC dungeon warning with Conceptualized Content/preview placement, not conceptual-only classification, shipped speaker/trigger, edition, release chronology or dialogue delivery.

**Validation-contract source item 55 — DECIDED 2026-10-05 under standing sourcing approval:**
§5 attributes the exact historical Steam UI/minimap key directions, not new controls, patch dates
or whole-guide ancestry. D17's hybrid F3 debug-menu stands; independent recording review found
no issues and parent recording checks passed (`todo_decide.md §E`).

**Validation-contract source item 56 — DECIDED 2026-10-09 under standing sourcing approval:**
§5 attributes Alpha R / Steam E Interact and Alpha Ctrl / Steam E Climb with stamina cost;
Alpha pickup R versus `keybinds.json#pick-up.A` E remains unresolved. D13 stands; independent
review found no issues and parent recording checks passed; item commit pending (`todo_decide.md §E`).

| topic | still undecided / incomplete |
|---|---|
| Validation-contract source research/attribution | items 1–55 stand; item 56 recorded under standing sourcing-only approval, independently reviewed with no issues and parent recording-verified (`todo_decide.md §E`). Item commit pending; selection retained in pending queue; no unanswered ballot. Current status: HANDOFF; no publication authority. Unsupported food/mixed-container histories, daily quantities and sleep units stay research, not topic completion. No guessed labels, reopened mechanics or implementation; enforcement deferred |
| Remaining uncertain facts | swamp-lands identity, Lion tameability, resistance meaning and the gear-HP roll formula |

D13 already defines size-class hitboxes, D14 defines current spawn/chase numbers, and D15 defines
the hybrid subtractive armor rule and floor; they are not open numeric gaps. Optional/null fields
are not automatically unknown facts. Equipment-model implementation (item 3) and validator
implementation (item 9) remain explicitly deferred even where their policies are approved.

### Reference uncertainties, not new hybrid defaults

Historical rare-zone rarity, the alpha `mana-cubes` field, species-specific chase observations,
source stat-display comparisons and Omega engine/status reports remain research uncertainties.
They neither override designed hybrid rules nor enable cut/Omega content. Other `?` annotations
stay attached to their source records; any unresolved implication for active hybrid behavior
must be decided before implementation, not inferred from a historical flag or loader fallback.

### Historical D/F record

- **D1 Ruleset — DECIDED 2026-09-07: hybrid** (see §1).
- **D2 Engine — DECIDED: Godot 4 + GDScript**; toolchain pinned to Godot 4.7.2 through
  `nix develop`. Typed model and validator: `model.gd`.
- **D3 Cut content — DECIDED: not in v1.** Every `X` item is a follow-up in
  `docs/ROADMAP/*.md` (one file per theme, <100 lines, with online documentation links).
- **D4 Omega — DECIDED: roadmap only** (`docs/ROADMAP/omega-*.md`). Separately, **regional gear
  power loss is permanently excluded**, not roadmapped: never propose or implement it, even
  for cloning fidelity (owner reaffirmed 2026-09-15). Gear never loses power while travelling.
- **D5 Multiplayer — DECIDED 2026-09-07: dedicated server**, alpha style, IP/DNS join, seed in
  server config. **D7** cap configurable, default 4. **D8** skin colour is a creation option.
  **D9** first-person zoom kept. **D10** 3 alpha columns + 1 `ultimate` column (see `skill-tree`,
  including the subsequently approved Assassin single-skill exception).
- **D6 Numeric gaps — DECIDED 2026-09-07**, all tunables in `generators.json#design`: 5 %/point
  uncapped; crit ×2 with chance overflow; alpha item curve only; buy = base×level×rarity, sell 25 %;
  artifacts +5 % ×0.9 floor 1 % on one traversal stat and on attack/HP; no stack cap; enemy HP =
  cuwo formula × family multiplier; Circle of Power +10 % attack/HP; recipes 5 cubes × size class.
  Artifact accumulation values above are historical: the 2026-09-28 artifact approvals (§3.4)
  supersede that rule; the remaining D6 decisions and D11 land counts stand.
- **F1 — DECIDED**: heroic shout = taunt + heal; toughness +25 %; battle fury 13 % per hit; shadow
  shooter 30 s; bubbles 6; shuriken toss 25 stamina; R cooldowns per skill.
- **F2 — DECIDED**: per-page, not rideable (the table was the 1.0.0-1 bug).
- **F3 — MOOT for pixlnd (D4)**: `+` items' adjacent-land/kingdom scope and 100 % lore drops
  remain historical reference, not open gameplay choices.
- **F4 — DECIDED (owner override)**: party-level band + per-land danger tier; distance from
  spawn no longer drives level (`generators.json#design.enemy-level`).
- **F5** — split into D7/D8/D9, all decided.
- **F6 — DECIDED**: one land = one region cell; water level and noise are our own.
- **F8/F9/F10/F11 — DECIDED**: spirit bell 30 s; life potion anywhere; panther/spectrino/rune
  giant/duckbill/ancient guardians tagged `S` with alpha id reserved; banana mash obtainable.
- **D11 Hybrid gaps — DECIDED 2026-09-08**, in `generators.json#design`: block gives MP; regeneration
  = stamina only; 1–3 artifacts per land; `/pvp` dropped, PvP is a `server.cfg` flag (default off).
- **D12 World numbers — DECIDED 2026-09-08**: zone 64², land 256² zones, 1 block = 1 m, sea level 96,
  fBm heightfield, climate rules, land-name syllables → `generators.json#design.terrain|climate|names`;
  per-landscape relief/base/palette → `landscapes.json#<id>.gen`.
- **D13 Player movement, camera, keys — DECIDED 2026-09-08**: walk 6 blocks/s, sprint ×1.8, swim ×0.5,
  jump 1.5/3 blocks tap/hold, gravity 32, auto step-up 1 block, hitbox by size-class, stamina 100;
  orbit camera 0–12 blocks (0 = first person); hybrid key column → `generators.json#design.movement|camera`,
  `keybinds.json#hybrid`.
- **D14 Open-world spawns — DECIDED 2026-09-08**: 0–2 groups per zone from the landscape roster, group
  sizes from `creatures.json`, hostility `V` = 50/50, NPC HP = base-hp × 200 × 2^(power-base/4) with
  power-base ∈ [−1.5, 1.25], wander/chase FSM numbers → `generators.json#design.spawns|enemy-hp`.
  Land danger tier (F4) rolled per land from `design.enemy-level.tier-weights`.
- **D15 Combat multipliers — DECIDED 2026-09-08**: attack = curve × k × 10, NPC damage = base-hp × 12 ×
  2^(power-base/4), armor floor 10 %, combo +2 %/hit, swing 0.5 s, respawn at spawn point →
  `generators.json#design.combat`; class `hp-mult` in `classes.json`.
- **D16 Simulation radius — DECIDED 2026-09-08**: only creatures within 80 blocks of the player run AI and
  physics; the rest stand still. Measured cause of 4 FPS: ~95 bodies on trimesh zones → 40 ms physics
  ticks → 8 catch-up steps per frame. → `generators.json#design.spawns.ai.sim-radius`, `c-sim-radius`.
- **D17 Runtime profiling and frame budget — DECIDED 2026-09-08**: players profile in-game with the Godot
  Debug Menu add-on (`hud-element` debug-menu, `keybinds.json#hybrid.debug-menu` = F3, like Minecraft F3;
  MIT, Asset Library "Debug Menu", works in release exports); dev-only `monitors/` stay for CI. Physics
  catch-up capped → `generators.json#design.frame-budget`, `c-frame-budget`.
- **D18 Items, loot, inventory — DECIDED 2026-09-09**: per non-friendly kill: coins 60 % (1 + 2·level), one
  gear piece 20 % (weapon 4 : chest 2 : gloves 2 : boots 2 : shoulders 2; class rolled uniformly, its
  material), one consumable 15 %, species drop 50 %; rarity weights 60/25/10/4/1, item level = creature
  level ±1; ground items live ≈ 1 game week, pickup radius 2, coins auto. Stacks: no cap, only consumable/
  ingredient/coin/formula/block stack. Start: class weapon + 5 life potions. → `generators.json#design.loot|stack-cap|starting-inventory`,
  `c-loot-config`, `c-stack-rule`, `c-slot-accepts`. Gear stats this build: damage + armor only (hp/regen/tempo/crit `?`,
  the stats.json hp roll term `2 − 8r` goes negative as written).
- **D19 XP and level-up — DECIDED 2026-09-09**: XP per kill = `xp-to-next(creature level)` × kill-fraction 0.2 ×
  gap multiplier clamp(1 + 0.1·(creature level − player level), 0, 2), so ~5 even-level kills level you up and
  a creature 10+ levels below is worth nothing; overflow carries, several level-ups per kill; level-up refills HP
  and recomputes max HP; +2 skill points per level are banked (spending waits for the skill-tree UI + trainer).
  → `generators.json#design.progression`, `c-xp-config`, `c-level-up`.
- **D20 Skill tree — DECIDED 2026-09-09**: spend rules (one point per click, prerequisite = `needs` points in the previous
  node of the column, roots 0 — the five rank-1 rows said 1 and were corrected), X opens the screen, class nodes on keys 1–4;
  every class active is one self-centred strike (weapon damage ×2, radius 3, cooldown = the ability's positive listed cooldown or 10 s)
  scaled per point by `design.skill-point` until movesets land; swimming points raise swim speed; the other shared skills wait
  for their runtimes (pet, mount, climb, glider, boat); respec at the class trainer with settlements.
  → `generators.json#design.abilities`, `keybinds.json#hybrid.skills-window`, `ui.json#screens.skills`, `c-tree-shape`, `c-skill-spend`.
- **D21 Class abilities — DECIDED 2026-09-10**: the placeholder strike is gone; each of the 23 class-column / ultimate
  nodes runs one of five runtimes (dash, channel, burst, buff, heal) with designed numbers: Smash leaps 6 blocks to the nearest
  enemy within 8 and strikes ×2 with stun (100 stamina, 10 s); Cyclone channels 5 s, ×0.5 every 0.25 s within 3, 25 stamina
  + 25/s (30 s); War Frenzy / Bulwark / Mana Shield / Swiftness / Aim / Sneak / Camouflage / Ninjutsu / Shadow Shooter are timed
  self-buffs; Rock Fist / Intercept / Teleport / Retreat / Shuriken are dashes; Kick / Fire Explosion / Heroic Shout / Fire
  Missiles / Bubbles / Quicksand are bursts; Healing Stream casts 1.5 s then heals 50 %. Costs use the sources' S numbers where
  given, cooldowns the S values (rock-fist 20, heroic-shout 30, camouflage 40, ninjutsu 60, shadow-shooter 60, quicksand 40,
  fire-missiles 40, bubbles 30), else 10/12/15/20/25 designed, cyclone 30 (A said ~60). MP: non-mages +8 per landed basic hit,
  mages +5/s; M2 special attack charges MP at 50/s (rogue instant), damage up to ×2.5, stun chance up to 60 %. Statuses the
  engine applies: stun 2 s (knockdown = 1.5 s stun), knockback 8, burning 4 s at 10 % of the hit per 0.5 s, slow ×0.3 for 15 s;
  stealth and taunt are ignored until their runtimes exist. Per point: strike damage, heal, buff duration (D6). Projectile
  ultimates (fire-missiles, bubbles, shuriken) and the clone / zone ones are self-centred bursts or buffs for now.
  → `generators.json#design.abilities|resources|special-attack|status-effects`, `c-ability-runtime`.
- **D22 Settlements and spawn rule — DECIDED 2026-09-10**: one village per land (alpha count), placed from the land seed on the first
  ring candidate ≥ 4 blocks above sea, the terrain flattened within 24 blocks and blended over 8; ten box buildings (inn, weapon /
  armor / item shop, one class trainer, five houses) on a 15-block ring, coloured by settlement-style from the landscape; one NPC
  per service building at its door, E within 3 blocks talks. Vendors: 8 items rolled once from (seed, village, shop) at the
  land's creature level band around the player level, rarity ≤ rare until gnomes exist, prices `design.prices` (buy) × 0.25 (sell),
  worn gear unsellable; the item shop sells the loot consumable pool. Trainer respec refunds every spent point for 5 × level copper;
  the inn heals fully and moves the respawn point there, free. `world.spawn-rule` = the square of the land (0,0) village. Wild
  spawns skip groups within 40 blocks of the square. Not yet: districts, procedural rooms / roofs, villagers and schedules, inn
  time skip, restock, spec change, sewers / dens, flight master. Several villages per land (S) are not
  a hybrid target (settlements item 1, approved 2026-09-27).
  → `generators.json#design.settlement`, `ui.json#screens.npc-service`, `c-settlement-config`.
- **D23 Defence — DECIDED 2026-09-11**: dodge (M3 while moving, 25 stamina, 4 blocks in 0.4 s, hits ignored for 0.4 s, no fall damage on
  that landing; Ninja +25 MP via elusiveness, Assassin +0.5 stealth via way-of-the-shadows), block (M2 held with a shield / any weapon
  as guardian / during cyclone: front-cone hits × 0.2, 25 block-power per hit out of 100 (guardian 200), +8 MP per block, regen 20/s while
  not blocking, ×2 during cyclone), the stealth bar (sneak 0.25/s, aim 0.3/s, ×2 standing still, camouflage pins it full; decay 0.15/s;
  at full +20 % attack, +50 % crit, ×2 MP per hit, aggro range × 0.1; a landed hit empties it unless pinned), and creature hits rolling
  stun 5 % / knockback 15 % on the player (blocked or dodged hits roll nothing). Not yet: poison through dodges, the ninja crit window,
  counter-strike, hit-series, projectiles, stun stars / buff icons beyond HUD text, darkness / lamps.
  → `generators.json#design.defence`, `design.abilities.<id>.stealth-per-s|stealth-full`, `c-defence-config`.
- **D24 Weapon movesets and projectiles — DECIDED 2026-09-11**: every class weapon-type gets an M1 / M2 runtime in `design.movesets`: warrior
  one-handers spin around the player on M2, great weapons swing slow and wide with a knockdown finisher every 3rd hit, dagger M2 stuns
  and poisons (5 × the hit over 5 s), fist M2 knocks down, longsword M2 lunges 4 blocks and stuns; bow arrows arc (30 blocks/s, gravity
  10) and M2 volleys 4 with a 2-block splash, crossbow bolts fly flat and fast, boomerangs pierce, tick every 0.25 s and return, staff
  bursts where the aim lands within 20 blocks, wand is a hitscan beam of 25 blocks, bracelet bolts have no gravity and M2 is a splash
  ball that knocks down. Ultimates: fire-missiles = 4 splash fireballs, bubbles = 6 slow splash shots + the heal, shuriken-attack throws
  5 shuriken before the backflip. A whole attack that lands nothing resets the combo. Not yet: animations, hit timing, boomerang
  steering, wand M2 as a held ray, bow dud shots, arrow pickup, creature projectiles.
  → `generators.json#design.movesets`, `design.abilities.runtimes` + `projectile`, `design.status-effects.poison`, `c-moveset-config`.
- **D25 Game feel — DECIDED 2026-09-11**: every combat event fires a feedback bundle in `design.feel.events` — hit-stop (up to
  0.12 s on a kill, 0.08 s on a crit, none on being hurt or shooting), camera trauma (0..1, squared into shake on the camera's
  h/v offset and roll, decaying 1.5/s), floating damage numbers over the target (white hit, gold crit ×1.5, red hurt, orange
  dot tick, green heal), stun stars over any stunned head, buff icons with a countdown fill on the HUD, a level-up toast that
  pops from ×1.6 to ×1 over 0.4 s, projectile trails (a fading piece every 0.03 s) and impact flashes (0.15 s sphere, splash
  radius when the shot splashed), and sounds synthesised (sine + noise + pitch slide) from `design.feel.sfx` keyed by
  `audio.json#sfx-alpha-ids`. Not yet: real audio assets, particles (spheres stand in), animations / hit timing, a
  reduce-shake / reduce-flash accessibility screen (the design numbers are the only knob today).
  → `generators.json#design.feel, audio.json#sfx-alpha-ids, c-feel-config`.
- **D26 Creature ranged / mage roles — DECIDED 2026-09-11**: every creature's `combat-role` (melee, ranged, mage, any-class,
  none) is parsed from `creatures.json` `role` text, first of any-class / ranged / mage / melee found; no role or no keyword
  = unset, resolved to `design.creature-roles.default` (melee) at spawn, any-class rolled per spawned group from weighted
  `design.creature-roles.any-class`. melee keeps today's reach attack. ranged / mage chase to `range` blocks, back off below
  `keep-away`, need line of sight, wind up `windup-s`, fire a `shot` (speed/gravity/radius/life-s/splash, damage = creature
  damage × `damage-mult` through the target's normal dodge / block / i-frames), wait `cooldown-s`; a landed shot rolls its
  `applies` status ids (poison is never avoided by dodge) and `design.defence.enemy-hit` stun/knockback like any creature hit;
  `sfx` plays from the shooter, `color` tints the shot; `species` overrides any of those keys per creature id (spitter:
  poison, blue; snout-beetle: slower, harder). A creature shot never damages another creature. Not yet: aggro table / group
  aggro, enemy combos, potions, wizard laser / witch ray as a beam instead of a bolt, class / equipment / appearance for
  any-class humanoids, snout-beetle dodge, pathfinding.
  → `generators.json#design.creature-roles, c-creature-roles`.
- **F7** Omega status after mid-2024 (Vulkan vs UE5 reports).
