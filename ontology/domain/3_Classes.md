## 3. Classes

Format per class: **id** — one-line definition. `versions`. Property table. Instances file.
Player intentions and their lifecycle live only in [controls](controls.md); physical bindings
and current adapter coupling live only in [controller profiles](controller-profiles.md).

### 3.1 World

### world
The single playable universe instance. `A S`
Hybrid saved-world identity is distinct from the generation seed (`save-data`, persistence item 2).

**Hybrid world/reset item 1 (owner approved, 2026-09-28):** the world is a finite square of
**1,024 × 1,024 lands (1,048,576 total)**, one land per region. Each land is **16,384 blocks
across** (D12), giving **16,777,216 blocks / roughly 16,777 km per side**. Land coordinates
run **−512 through 511 inclusive on each horizontal axis**. This is enormous but bounded,
not unlimited generation or a wrapping world. Historical “infinite” / “no borders” descriptions
do not override this hybrid limit.

**Hybrid world/reset item 2 (owner approved, 2026-09-28; depends on item 1):** mark the
outer world boundary on a fixed overview showing only the boundary and current player position;
terrain, exploration, pan/zoom, markers and map travel are outside that overview. Prevent outward travel,
including flight and teleport destinations, at any altitude. The edge behaves like a wall
and turn-back is allowed. Preserve current Teleport
costs and cooldowns. Crossing attempts
cause **no special damage, death or forced teleport**. This chooses no edge art, warning UI,
biome or numerical buffer.

Structural definition: [`world`](../schema/world.yaml) (class; `world-seed`, `world-name`, `world-day`, `world-time-ms`, `world-spawn-rule`, `world-origin-poi`, `discovered-zones`). Alpha seed is chosen per world (server default 26879); Steam uses one fixed shared seed without UI. The name is Alpha-only; day is a counter and time is milliseconds within the game day. Steam 0.9.1–3 starts new characters near a village; Alpha uses the (0,0) area, while hybrid uses the square of the (0,0) village. Steam's origin POI is `wollays-house` at block (0,0). Discovery remains world-shared (Alpha visitors; hybrid saved-world visitors) and grants no personal unlocks. Instances: none (runtime). Active scale: `generators.json#design.terrain.lands-per-axis`; `world-scales` retains historical source scales.

**Hybrid persistence item 3 (owner approved, 2026-09-28):** explored terrain belongs to
that saved world and is visible to all its visitors, including later arrivals. Seeing a place
on the shared map grants **no personal shrine activation, flight access or lore knowledge**;
those remain character/world records (`save-data`, item 2). Exploration helps the group, but
newcomers inherit the already-explored map rather than starting with a private blank map.

### zone
Terrain streaming unit (alpha "chunk"). `A S`
Structural definition: [`zone`](../schema/world.yaml) (class; `zone-size-blocks`, `zone-static-entities`, `columns`, `spawns`, `chunk-items`); [`field`](../schema/world.yaml) (`base-z`, `blocks`); [`creature-spawn`](../schema/world.yaml) (entity facets); and [`dropped-item`](../schema/world.yaml) (qualified component facets). A zone has one field per (x,y); size remains A 256×256, S 64×64, hybrid 64 (D12, `generators.json#design.terrain`). Static entities are doors, chests, furniture and stations. Zones unload when unvisited; dropped items disappear after ~1 game week. These remain behavioral rules, not fields of those declarations.

### block
One voxel. `A S`
Structural definition: [`block`](../schema/world.yaml) (`block-type`, `block-rgb`, `block-breakable`); the block-type catalog is [`block-type`](../schema/world-catalog.yaml) and its configured scale/format is [`block-type-catalog`](../schema/structured-world.yaml). Source block-type IDs are 5-bit; RGB remains per-voxel, without a palette. Block scale: 1 block = 65536 native units (16.16 fixed); hybrid: 1 block = 1 m (`generators.json#design.terrain.block-m`). Character ≈ 2 m. Breakability by bombs/boss terrain damage and regeneration after ~3 game days remain behavior.
Initial hybrid arenas use the scoped [breakable rubble and restoration rules](encounter-contracts.md#boss-specials-and-breakable-rubble).

### block-type
Enumeration of voxel kinds; alpha and 1.0 tables differ. `A S` → `instances/block-types.json`.

### land
A named, bordered gameplay region of one `landscape`. What the wiki calls "region"/"land". `A S`
Structural definition: [`land`](../schema/world.yaml) (class; `land-name`, `land-landscape`, `land-level`, `land-danger-tier`, `land-tier-range`, `land-rarity`, `land-realm`, `land-border`, `land-key-items`, `land-gnome-suppliers`, `land-books-of-crafting`, `wizard-towers`, `land-circles-of-power`, `land-artifacts`, `land-settlements`, `land-coords`). Preserve the contextual source facts: names are not unique; A levels rose with distance, while hybrid uses the party-band rule in `generators.json#design.enemy-level`; danger-tier is rolled once at generation. A's 0..4 rarity tier is described as stronger monsters/better loot in the “rare zones” devlog, with uncertain applicability. S tiers run white→yellow, with dungeon enemies above surface tier; realm lore remains S-qualified. The [`land.land-border`](../schema/world.yaml) slot is a logical polygon kind for map only: internal borders are dotted, not physical walls; the outer-world travel boundary is the separate world item 2 rule. S land inventory tabs remain a source description and are not selected as a land property. S counts remain source-qualified: four gnome suppliers, four crafting books, up to nine key items, up to five wizard towers, one or more circles/artifacts, and several settlements; A/hybrid settlement count remains separately qualified. Hybrid coordinates are bounded −512..511 inclusive on each horizontal axis; `seed = hash(world.seed, coords)`, and every land roll derives from that seed. No representation beyond the declarations is implied.
Internal grid: alpha region = 64×64 zones = 16 384 blocks; 8×8 mission cells per region;
world addressable as 1024×1024 regions (finite). One gameplay `land` = one internal region cell
(F6, decided); heightmap, water level and noise are our own.

### landscape
Biome family with climate, palette, flora, fauna and structure rosters. `A S Ω`
→ `instances/landscapes.json` (13: greenlands, snowlands, deserts, jungles, lava-lands, oceans,
savannahs, wetlands, swamp-lands`?`, dark-woods, deadlands, mountains, mushroom-lands `X`).
Logical roster facets belong to [`landscape`](../schema/world.yaml), with [`landscape-flora`, `landscape-fauna`, `landscape-dungeons`, and `landscape-pois`](../schema/world.yaml); source-list text remains in [`landscape-source-row.flora`, `landscape-source-row.dungeons`, and `landscape-source-row.pois`](../schema/structured-world.yaml). `landscape-fauna` is a typed creature reference. A typed reference alone does not establish that the creature exists or is selected for a generated roster.

Raw climate bands are [`landscape-source-row.climate`](../schema/structured-world.yaml) with [`landscape-source-climate.temp` and `landscape-source-climate.humidity`](../schema/structured-world.yaml); these strings are source bands, not converted climate readings. The architectural style roster is [`settlement-style`, `settlement-style-lands`, and `settlement-style-desc`](../schema/catalog-properties.yaml), while each raw landscape's style text is [`landscape-source-row.style`](../schema/structured-world.yaml). A style description is not evidence of hybrid availability. Raw S hazard descriptions are [`landscape-source-row.hazards`](../schema/structured-world.yaml); the S cold-water slow, toxic-river poison and lava-burn examples remain source-qualified behavior.

Generation is [`landscape-gen`](../schema/world.yaml) in `landscape`, with [`landscape-generation`](../schema/world.yaml), exact [`landscape-generation-relief`, `landscape-generation-base`, `landscape-generation-surface`, `landscape-generation-top`, and `landscape-generation-cliff`](../schema/world.yaml), and source [`landscape-source-row.gen`](../schema/structured-world.yaml). `relief` is the height multiplier; `base` is the height offset in blocks. Surface block type and top/cliff RGB meanings remain prose, not duplicated field definitions. Source versions are [`landscape-source-row.versions`](../schema/structured-world.yaml); the raw A/S/Ω/X and uncertainty qualifications do not themselves establish hybrid availability.

Climate bands select biomes (devlog 2012-01). Retain the source sky/lighting examples (green sky in deadlands; lava lands and dark woods dark by day) as source-qualified prose.

Hybrid v1: **Wetlands remains playable; a separate Swamp Lands biome is excluded**.
The historical `swamp-lands` reference remains uncertain, not an alias of Wetlands or a
permanent all-version exclusion. No separate swamp terrain, fauna or reward rules are selected.

### terrain-feature
Natural formation placed inside a land. `A S` → `instances/terrain-features.json`
(mountain, plateau/cliff, valley, canyon+mesa, cave, river+waterfall, lake, lava-lake, volcano,
island, sky-island `S`, forest (generic/birch/pine, dungeon-forest), field, road+bridge+tunnel,
oasis, cloud (no collision), giant-rock `A`, giant-tree `A`, graveyard). The complete source row is [`terrain-feature-source-row`](../schema/structured-world.yaml); uncertain descriptions remain literal source facts.

#### Hybrid connecting routes

A connecting `road` in the hybrid is directional guidance between existing settlements,
dungeons, camps or other destination sites, suggested by scattered **leading objects** rather
than a continuous, visibly delimited road surface. Players find their way by observing those
objects, with natural ground between them, not by following a plain strip or two marked edges.
Guidance never changes terrain: no flattening, cutting, filling or connecting supports.
Connections need not be walkable; players may need to climb or detour around terrain.
Do not enforce connecting width, step, slope or reachability requirements, or reroll destinations
solely to obtain access.

Each route repeats one recognizable object family, chosen for its destination away from the
village. Orientation and condition may vary, but the family does not change along the route.

| Existing destination | Leading object family |
|---|---|
| Ruins (`dungeon-types.json#ruins`, including overworld ruins) | Small weathered masonry stones matching the ruins' stonework, recognizable as broken building pieces rather than ordinary rocks. |
| Camps (`poi-types.json#campsite`, including the initial skeleton camp) | Torches on rough wooden stakes. |
| Supplier-rescue sites (`gnome-supplier`, all four initial sites) | Broken wooden supply crates; the same family for all four routes, without tier-specific marker types. |
| Existing house/hut POIs (`poi-types.json#old-hut`, `poi-types.json#wollays-house`) | Small lanterns on short wooden posts. |

These themes apply to the listed destinations whether implemented or not, without changing
their existing availability or guaranteeing new connections. The house/hut row adds no generic
isolated-house destination or house-building feature. Other destination families receive no
object assignment from this selection.

Leading objects are solid, non-targetable, unbreakable scenery without interaction, loot or
damage; torch flames are harmless. Placement must not trap actors or obstruct site-internal
passages. Terrain generation runs in the background independently of optional guidance.
Guidance may arrive later or be omitted on failure, without suppressing destinations or ending
the game; pending, absent or failed guidance is valid saved-world state. Guidance uses the terrain
worker when measured to be very light, otherwise a separate background worker.
Natural-terrain preservation applies to connecting guidance only: settlement/site platforms,
8-block site aprons, dry ocean islands/hubs, dungeon corridors and battlefield boundaries retain
their existing rules under the [initial contract](encounter-contracts.md#placement-and-access).
Historical road, tunnel, bridge and streetlight descriptions in the instance catalogs remain
reference material, not a requirement for a continuous hybrid road surface.

Leading objects are solid physical obstacles outside the required passage, non-targetable and
unbreakable. They have no interaction, loot or damage behavior. Torch flame/emission is harmless
presentation, not fuel, a hazard or a renewable resource. Decorative spacing, size and condition
may vary without a fixed gameplay spacing or visibility guarantee.

### climate
Continuous fields sampled per position. `A S`
Structural definition: [`climate`](../schema/world.yaml) (`climate-temperature-c`, `climate-humidity-pct`). Values are shown in the HUD; desert references remain approximately 36 °C and 5% humidity. Snow presence and berry/heartflower spawns are S-guide behavior, not fields in this logical reading class.

### flora
Harvestable or decorative plant object; harvested by attacking. `A S` → `instances/flora.json`.
Structural yield definition: [`ingredient-yield`](../schema/associations.yaml) and [`flora-yield-entry`](../schema/structured-world.yaml). Example: bush → 1–3 wood log + plant fiber. Landscapes remain placement context; S daily respawn and shimmer-mushroom blue glow remain behavior, not structural yield fields.

### deposit
Mineral node in caves / underwater caves. `A S` → `instances/deposits.json` (iron, silver, gold,
sandstone, emerald, sapphire, ruby, diamond, ice-crystal). Structural catalog range is [`deposit-yields`](../schema/world-catalog.yaml); the fixed logical 1–3 interval is [`deposit-ingredient-yield`](../schema/world.yaml). Yields remain ingredient-typed; sandstone's unresolved target is not repaired. Respawn at 0:00 and rare boulder placement requiring a bomb remain behavior.

### settlement
<a id="settlement-style"></a>
Village or city. `A S`
Structural definition: [`settlement`](../schema/world.yaml) (`settlement-style`, population races/animals, contextual count, districts, buildings, petrified and possessed state); settlement style details are [`settlement-style`](../schema/catalog-properties.yaml). Historical styles (`european-framework`, `medieval-stone`, `na-wood`, `log`, `desert`, `jungle`, `undead`, `lava`, `ocean`), A district variants (trade, crafting, adventurer/class, pet quarter `X`, portal, palace) and population descriptions remain source-qualified: humans are noted as the majority, with undead villages in deadlands/dark woods. Alpha settlements are always visible on the map; Steam settlements are hidden until discovered. Steam has sewers under some 5★ villages holding an artifact; petrification is a witch curse until the witch is killed, and possession means a demon portal is active in the land. These are source-specific rules, not consequences of the structural reference. Hybrid D22 layout remains a separate rule.

**Hybrid settlements item 1 (owner approved, 2026-09-27):** exactly one settlement per land
is the final target, not a temporary limit pending multiple settlements. Other D22 layout,
services and settlement-safety rules are unchanged. `rulesets.json#ruleset-hybrid.flags`
and `design.settlement.per-land` both select 1.

D22's land-seeded box-building ring and service coverage are slice approximations, not the
final layout: terrain is flattened under `design.settlement.radius`, with one NPC per service
building; districts, procedural rooms/roofs, villagers/schedules, specialization changes,
sewers/dens and the flight master are outside that slice, not permanently banned. Layout, landscape colours,
door NPCs, interaction range and spawn-safety tuning remain in `design.settlement` and
`ui.json#screens.npc-service`.

Hybrid village-curse state is world-shared and persistent under `save-data` item 4.
Settlement-style records are hybrid configuration under §5 Validation-contract mapping item 1.

### district
City quarter. `A` → `instances/buildings.json#districts`. Structural definitions are [`district`](../schema/world.yaml) and [`district-building`](../schema/world.yaml), with `district-quarter-id` and `district-decor` in [`catalog-properties.yaml`](../schema/catalog-properties.yaml). Building references are catalog IDs; the four adventurer-quarter trainers use `{id: "class-trainer", class: <class-id>}` to retain one building per class, not four invented building types. District provenance and the ranger master's aim-target note remain unchanged.

### building
Functional structure in a settlement. `A S` → `instances/buildings.json` (inn, weapon-shop,
armor-shop, item-shop/general-store, identifier/analyst, smithy, clothier, workshop/carpenter,
class-trainer ×4 / guild, adapter `A`, flight-master `S`, den, house, watchtower, well, market
stalls). Structural definition: [`building`](../schema/world.yaml) and its [`building-name`, `building-sign`, `building-map-icon`, `building-roles`, and `building-stations`](../schema/catalog-properties.yaml). Each links to `npc-role`s and `crafting-station`s inside it.

### dungeon-type
Built or natural structure that hosts a mission objective. `A S` → `instances/dungeon-types.json`. Logical catalog facets are [`dungeon-type`](../schema/world-catalog.yaml) with [`dungeon-type-name`, `dungeon-type-naming`, `dungeon-type-lands`, `dungeon-type-entrance`, `dungeon-type-rosters`, `dungeon-type-natural`, and `dungeon-type-boss`](../schema/world-catalog.yaml); the variant slot and its entry shape are [`dungeon-type-variants` and `dungeon-variant-entry`](../schema/structured-world.yaml). Complete literal fields are [`dungeon-source-row`](../schema/structured-world.yaml).

- **Naming:** the authored name/pattern fields are [`dungeon-type-name` and `dungeon-type-naming`](../schema/world-catalog.yaml), with literal [`dungeon-source-row.name` and `dungeon-source-row.naming`](../schema/structured-world.yaml); examples remain “Castle ___”, “Ruins of ___”, “Temple of ___”, “Catacombs of ___” and “Pyramid of ___”.
- **Landscapes:** qualified placement text is [`dungeon-type-lands`](../schema/world-catalog.yaml) and raw [`dungeon-source-row.lands`](../schema/structured-world.yaml); it is not resolved placement relation/FK evidence.
- **Layout:** retain A's linear route plus one reward dead end and S's room gauntlet with several bosses of rising tier as source-specific behavior; no authored facet selects these procedures.
- **Entrance:** descriptive text is [`dungeon-type-entrance`](../schema/world-catalog.yaml) and [`dungeon-source-row.entrance`](../schema/structured-world.yaml), not an access rule. Retain the pyramid-top, temple-near-top/spiral-down and castle-gate-until-nearby-enemies examples.
- **Contents:** literal alternatives are [`dungeon-source-row.contents`](../schema/structured-world.yaml); retain A spike traps/vases/tables, S one-time chests/end artifact, and the X fire/stomp data and S magic-barrier source distinctions. These descriptions do not encode runtime execution.
- **Roster:** qualified text is [`dungeon-type-rosters`](../schema/world-catalog.yaml) and [`dungeon-source-row.rosters`](../schema/structured-world.yaml), not uniformly resolved creature IDs. Retain the forest roster examples (insect, animal-i, animal-ii, undead, orc, human, beetle, dwarf).
Alpha location table (cuwo): Village, Mountain, Forest, Lake, Ruins, Gravesite, Canyon, Valley,
Crater, Cave, Portal, Rock, Tree, Peak, Castle, Catacombs, Palace, Temple, Pyramid, Island.

Landscape dungeon and POI rosters are [`landscape-dungeons` and `landscape-pois`](../schema/world.yaml), referring to [`dungeon-type` and `poi-type`](../schema/world-catalog.yaml); exact qualified source lists are `landscape-source-row.dungeons` / `.pois` in [`landscape-source-row`](../schema/structured-world.yaml). Placement, frequency and variant descriptions remain in each landscape's raw `notes`, not embedded in IDs. Retained
[world evidence](../../docs/research/research_world.md#32-landscape-list) describes jungle ruins
as a variant of overworld ruins, supporting `ruins`; ocean temples are on large islands and arenas
are more common in oceans. Desert ruins are described, but their exact catalog identity remains
unresolved: retain that evidence in notes, not a fabricated alias or a resolved dungeon reference.

### poi-type
Non-dungeon point of interest / event site. `A S` → `instances/poi-types.json` (campsite, arena,
wizard-tower, circle-of-power, demon-portal, mana-pump, mana-inductor, mana-tree, shrine-of-life,
revival-statue `A`, portal `A`, bird-statue, lore-site (menhir/tablet/crypt/henge), molehill,
bone-pile, hornet-nest, slime-well, old-hut, hidden-treasure (log/sky statue/cave), airship,
wollays-house, kingdom-frontier-wall `X`). Logical catalog facets are [`poi-type`](../schema/world-catalog.yaml), with exact raw alpha-location/quarter pairs [`poi-type-alpha-loc` and `poi-type-quarter`](../schema/world-catalog.yaml); full source rows are [`poi-source-row`](../schema/structured-world.yaml).

### static-entity
Interactive or decorative world object with orientation and open/closed/sat state. `A S`
→ `instances/static-entities.json` (78 alpha ids: doors, gates, traps, lever, chests, furniture,
market stands, shelves, corpse, rune stone, artifact pedestal, flower boxes, street lights,
fences, vases, campfire, tent, beach umbrella/towel, sleeping mat, 7 crafting stations). Logical state and cardinal orientation are [`static-entity`](../schema/world.yaml); the complete name/behaviour/config catalog is [`static-entities-source`](../schema/structured-world.yaml). Source-qualified projections are [`cuwo-static-entity-components`, `cuwo-static-header-components`, `cuwo-item-with-header-components`, `cuwo-item-with-header-list-components`, and `cuwo-item-with-header-lists-components`](../schema/world.yaml); source marker collections are [`zone-tile-marker-collection` and `place-keyed-marker-collection`](../schema/structured-world.yaml). They remain distinct projections: Item references are nominal, seven opaque u32 components retain unknown meanings, and marker scopes are not polygon vertices, a canonical polygon, or a selected wire/save representation.
Initial hybrid ruins use the [spike and furnishing contract](encounter-contracts.md#spike-traps-and-furnishing-contents).
Dynamic subset: sit-able {sleeping-mat, stool, bench, bed}; open-able {window, castle-window,
door, big-door, chest}.

### realm
Procedural kingdom / realm / cult / tribe that historically owned several lands. `S`
Structural definition: [`realm`](../schema/world.yaml) and its typed leader/capital components [`realm-leader-birth-year`, `realm-leader-hometown`, `realm-leader-tomb-location`, `realm-capital-founding-year`, `realm-capital-destruction-date`](../schema/associations.yaml). The optional destruction date remains distinct. Kind, procedural names, personality, magic/technology flavor text, lore percentage/site increments and artifact revelation at 100% retain their source-qualified meanings. Hostile NPCs in a land can be labelled with the realm's name.

### game-clock
Time, resets and sleep. `A S`
Structural parameters are [`game-clock`](../schema/world.yaml) (`speed`, `initial-time-ms`, qualified `reference-sleep-speed`) and [`hybrid-inn-sleep-service-parameters`](../schema/world.yaml). Preserve the distinctions: 10× running-world time; 07:00 applies only to fresh saved worlds; historical A/S sleep is described as 100×, with unresolved baseline/units and no faster world simulation; hybrid inn sleep is the separate agreed clock skip. Historical inn references run 18:00–06:00 and set 07:00; Alpha is free, while Steam costs 10 coins and also rerolls daily missions. The historical midnight-reset account includes respawns, daily missions, deposits/plants, shop restock and divine-door closure, with Steam exclusions uncertain. Historical nights are very dark, use lanterns, and increase stealth buildup; A/S weather is absent, while Ω describes rain, snow, moving clouds and freezing water. These historical/source-qualified descriptions, along with hybrid occupancy, recovery and reset behavior, remain prose, not fields asserted by those structural declarations.

**Hybrid world/reset item 3 (owner approved, 2026-09-28):** defeated enemies, **including
bosses**, in **ordinary dungeons and repeatable daily encounters** return with the daily reset.
Enemies belonging to a **completed one-time objective stay cleared**, including its guards
and boss. Enemy resets **never renew an artifact or book claim**: personal source claims and
world-shared improvements retain their approved scopes and reset rules (`save-data`, items 4–5).
Tomorrow may offer another daily boss fight, but never recreate a completed supplier-rescue
encounter. Daily-enemy eligibility does not change other mechanics' resets or reward rules.

**Hybrid world/reset item 4 (owner approved, 2026-09-28):** an **occupied dungeon/quest
site waits until all players leave** before applying its pending daily refresh, using item 3's
eligibility. **Multiple missed midnights produce one refresh**, never stacked waves. The clock
change itself **never heals or replaces living enemies or erases an ongoing fight**; a run
spanning midnight can finish without defeated guards respawning behind the party. Ordinary
threat decay, targeting and home-return rules remain unchanged (`ai-behavior`): genuine mob
death/respawn starts fresh, not a clock-triggered wipe of surviving mobs.
For the [initial encounter families](#mission-type), occupancy uses explicit **closed
three-dimensional playable site volumes**: dungeon rooms, corridors and entrance court;
visibly delimited outdoor battlefields. Boundaries count as inside: every player must be
outside every component before the pending refresh applies. Camera distance, streaming and
simulation range do not define occupancy. [Initial encounter geometry](encounter-contracts.md#geometry-and-occupancy)
defines their dimensions and playable components; storage format remains unselected. No extra
grace delay applies.

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

The hybrid `inn-cost: 10` flag does not distinguish the two services;
`generators.json#time` and A/S inn records are not a complete hybrid service contract.
The S sleep-specific refreshes in `economy.json#rules` / `npc-roles.json#innkeeper` are reference,
not hybrid policy.

**Hybrid persistence item 8 (owner approved, 2026-09-28):** a **shut-down world accumulates
no gameplay time**. Its clock and timed resets resume from saved time, without offline combat
or overnight reset catch-up. A dedicated server that remains running continues normally even
with nobody connected. This preserves D16's frozen distant movement/attacks and the approved
elapsed-gameplay-time threat/taunt timers (`ai-behavior`); it does not require simulating every
creature in an empty world. Approved inn sleep remains its distinct clock-skip rule above.
No character-absent cooldown/status policy, serialization/checkpoint cadence or crash-recovery
policy is chosen.

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
| stats | **no racial stat bonuses**; collision capsule varies by size-class (D13, `generators.json#design.movement.hitbox`) |
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

Hybrid locomotion (D13): base walk speed, sprint/swim multipliers, tap/hold jump heights,
gravity and automatic step-up height use `instances/generators.json#design.movement`.
Control meanings: [move](controls.md#move), [sprint](controls.md#sprint),
[jump](controls.md#jump) and distinct [swimming ascent](controls.md#swim-ascent).

Hybrid death (D15): respawn at the character's current spawn point, initially set by
[world.spawn-rule](#world) and relocated by [inn recovery](#game-clock). This `design.combat.death` selection is scoped to D15;
Alpha respawns the character at the nearest revival statue.

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

Hybrid combat-role mapping (D26): from `creatures.json` `role` text, take the first matching
keyword in priority order **any-class / ranged / mage / melee**. Absent text or no matching
keyword leaves the role unset, distinct from the listed `none` value; spawn resolution follows §6 `gen-spawns`.

A Snout Beetle charged shot's model must **not continuously grow to fill the screen**;
this bug grants no growing damage or new attack behavior. Existing combat and encounters stand;
D26 combat-role species overrides grant no exception.

Hybrid ordinary Lion (`lion`): **untameable**, retaining hostile jungle/savannah encounters.
Snow Lions and other cats are unchanged; this selects no food pairing or riding permission.

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

**Hybrid family item 2 (owner approved, 2026-09-27):** these 25 missing primary assignments
are authoritative. Preserve all other existing assignments except item 1's Skeleton Dog override.
No numerical changes, new family classifications or species-trait inheritance are introduced.

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
| behaviour | never initiates; attacks owner's target; [recall](controls.md#pet-call) / [mount](controls.md#pet-mount); teleports to owner if far (S); revives ~1 min after death or on re-slot; ignores wraiths |
| riding | A reference: pet-master 5 → riding skill; S reference: land's `reins`; hybrid gate below; dismount on attack/dodge/fall/pet death/water; explicit [dismount request](controls.md#pet-dismount) has no selected physical mapping |

**Hybrid traversal item 1 (owner approved, 2026-09-28):** mounting requires **5 Pet Master
points and at least 1 Riding point**, globally acquired **Reins**, and a **rideable tamed pet**.
Further Riding points retain their speed benefit. This grants no new species riding permission,
Reins acquisition route or equipment slot.

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
| simulation | hybrid: beyond `design.spawns.ai.sim-radius`, movement and attacks stay frozen (D16); threat decay and taunt expiry reflect elapsed gameplay time (approved 2026-09-27, below). Distance is to the nearest player (the sole player in solo play). |

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

Remaining source uncertainties are indexed in §7.

Hybrid (D26): `combat-role` mapping is defined under [creature](#creature), with resolution per
spawned group in §6 `gen-spawns`; melee retains its reach attack. Ranged / mage chase to a `range`,
back off below a `keep-away` distance, need line of sight,
then wind up and fire a projectile (`design.creature-roles`, keyed by role and overridable per species — spitter,
snout-beetle) that damages through the target's normal dodge / block / i-frames and rolls its `applies` statuses on a
landed hit, with normal D23 enemy-hit stun/knockback rolls ([status-effect](#status-effect)).
Poison is never avoided by dodge. A creature shot never damages another creature.
`c-creature-roles`.

Aggro tables/group response, enemy combos/potions, Wizard laser/Witch ray beams, any-class humanoid
class/equipment/appearance, Snout Beetle dodge and pathfinding are outside the D26 slice, not final bans;
the approved AI rules above still govern the target.

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

Hybrid **Resistance means magical-damage reduction, not general status immunity**. Resistance
alone does not prevent a magical hit's stun. Hazard-protection drinks keep their separate roles.
Historical conflicting stat descriptions remain reference, not alternate hybrid behavior.

**Hybrid Resistance item 1 (owner approved; recorded 2026-10-16):** subtract **1 damage per
Resistance point**, not a percentage. A 100-damage spell against 30 Resistance becomes **70
damage**, subject to item 2's minimum.

**Hybrid Resistance item 2 (owner approved; recorded 2026-10-16):** Resistance alone cannot
reduce a damaging hit below **10% of its original damage**, matching armor's existing floor.
For an eligible hit with incoming damage `D ≥ 0` and Resistance `R ≥ 0`, the Resistance-stage
result is `max(D - R, 0.1 × D)`. A 100-damage spell against 200 Resistance yields **10 damage**
at this stage. Zero damage stays zero; fractional damage remains possible, with **no minimum-one
rounding**. This is not a final HP-loss floor: later defences may reduce or absorb the remainder.

**Hybrid Resistance item 3 (owner approved; recorded 2026-10-16):** classify the **attack**,
not merely its attacker:
- **Magical:** Mage weapon attacks, damaging Mage spells and enemy mage-role spells.
- **Physical:** weapon blows, bites, arrows, thrown weapons and physical strike skills.

Apply **exactly one equipment defence**: magical attacks use Resistance under items 1–2;
physical attacks use the existing armor rules, never armor followed by Resistance. A mage's
fireball meets Resistance; an ordinary arrow meets armor. This selects no new attack content
or live-data migration and does not extend combo armor penetration to Resistance.

**Hybrid Resistance item 4 (owner approved; recorded 2026-10-16):** damage-over-time calculated
from a triggering hit inherits that hit's Resistance reduction **once**. Never subtract Resistance
again on each tick. If a fire spell falls from 100 to 70 damage, burning worth 10% of that hit
starts at **7 per tick**, not 10 followed by another Resistance subtraction.

Independently sourced poison and environmental hazards gain **no Resistance protection** under
this selection. Preserve existing status identity, application and duration, dodge exceptions,
drinks and status-protection rules. The example selects no new tick coefficient, duration or
cadence; no additional DOT buff timing, stacking/slot model or hazard behavior is selected.

Items 1–3 determine the triggering hit's Resistance reduction; item 5 governs its defence stage.

**Hybrid Resistance item 5 (owner approved; recorded 2026-10-16):** apply Resistance first,
then existing block and damage-reduction multipliers, then absorption shields. The **10% floor
applies only at the Resistance stage**, not to final HP loss; absorption may prevent all HP loss.

Example: **100 → 70** through Resistance → **14** through blocking → **7** during Bulwark.
Separately, a Mage's 50-point absorption shield facing that resisted 70-damage hit leaves
**20 HP damage**.

Items 1–2 define the first stage; item 3 limits its coverage. Preserve existing block
eligibility/exhaustion, multiplier values, absorption-pool rules and status protections.
The examples select no new block/buff strengths or shield capacities.

**Hybrid Resistance item 6 (owner approved):** an unequipped creature or NPC has innate
Resistance `R = 0`. No automatic level, species, role or family scaling applies; any equipped-item
contribution remains separate under the existing equipment rules.

### ability
An active or passive skill. `A S Ω` → `instances/abilities.json` (~65).
| prop | notes |
|---|---|
| kind | active \| passive \| shared-passive (alpha tree) \| movement |
| owner | class \| specialization \| all |
| versions | A / S / both; `removed-in-s`, `added-in-s` |
| _controls | inert references to [canonical actions](controls.md); class/ultimate activation resolves through the current tree, not versioned physical inputs |
| cost | mp / stamina / all-stamina / all-mp / none |
| cooldown-s, duration-s | |
| effect | structured summary + numbers; historical A/S values remain separate from selected hybrid behavior |
| alpha-tree | column, rank-needed (1 to unlock first, 5 in previous), per-point effect (D6: +5 % effect / −5 % cooldown per point, floor 25 %) |
| alpha-ability-id | cuwo id (21 kick, 34 healing-stream, 48 intercept, 49 teleport, 50 retreat, 54 smash, 79 sneak, 86 cyclone, 88 fire-explosion, 96 shuriken, 97 camouflage, 99 aim, 100 swiftness, 101 bulwark, 102 war-frenzy, 103 mana-shield) |
| applies | `status-effect` refs |
Runtime (D21): every class node and ultimate has a `design.abilities` entry naming one of six runtimes (dash, channel,
burst, buff, heal, projectile — D24: shots along the aim; a dash may `throw` shots first) with its numbers, cost (mp / stamina, a number or `all`) and cooldown; strikes apply the ability's
`applies` through `design.status-effects` (`c-ability-runtime`). Shared-column skills have no runtime here (swimming scales
swim speed; pet, mount, climb, glider and boat have separate rules).
Clone/zone effects remain scoped burst/buff approximations, not final fidelity.

**Hybrid Cyclone:** shared by Berserker and Guardian, one clockwise world-top-down revolution
per second from activation facing (`design.abilities.cyclone.turns-per-s: 1`; clockwise decreases
yaw from forward −Z). Only directly-ahead contacts land immediately. Later contacts use
current player/enemy relative positions as the rotating attack reaches their azimuth, at most once
per enemy per activation-referenced revolution. Entering already-swept space waits for the next
pass; leaving reach avoids a pending hit. There are no simultaneous radial pulses. The front seam
belongs to the new revolution and is contacted only once at that boundary.
Startup costs 25 stamina; active drain is 25/s, duration at most 5 s, cooldown 30 s with existing
skill scaling, radius 3, damage multiplier 0.5 and movement multiplier 0.6. Advance only through
affordable active time and remaining duration. A contact exactly at either final boundary counts
once; nothing follows it and the body stops at the actually reached angle, never a completed turn.
Finite positive angular progress and finite nonnegative drain are required before runtime;
zero drain is legal and duration-bounded. Cyclone rotates the body and its attack direction,
**not the camera**. Body yaw remains at the reached stop; movement, blocking, look and subsequent
attacks retain normal camera-based controls. Committed weapon, whole-channel hit/miss and ordinary
inactivity rules remain unchanged; reset/death synchronously stop further channel actions.

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
| m1 / m2 | retained data-channel names for [basic](controls.md#basic-attack) / [special](controls.md#special-attack) moveset summaries, not physical defaults |
| material | wood (workbench) / iron (anvil) / gold-silver (bracelets) |

**Hybrid hand occupancy and empty-handed actions:** either hand slot may independently be
empty, including in a saved character. Removing one hand item leaves the other item untouched
in its existing slot; there is no automatic move, swap, removal or deletion. This is an allowance,
not a requirement to leave a hand empty. Existing class, subtype/slot and two-handed restrictions
still apply: an off-hand-only item must be legal in that slot, and a two-handed weapon still
excludes another hand item. A shield alone retains ordinary shield blocking and its existing
worn HP/defence contribution. Other existing Guardian/Cyclone block eligibility is unchanged.
Without a **main-hand weapon**, new weapon-dependent basic, special and class-skill requests
are unavailable and consume no resources, cooldown or combo state; an off-hand weapon does
not become an attack source. Equipping a main-hand weapon restores those requests. Independent healing, buffs, movement and taunts remain available under their
existing rules. Already-fired projectiles and committed channel/dash effects retain their
existing resolution; unequipping does not cancel them or substitute barehand damage, a default
weapon or stale removed-weapon state for a new request.

**Hybrid Wand item 1 (owner approved, 2026-09-28):** a wand is **mechanically two-handed**,
even if held visually in one hand. Equip one wand with **no other hand item**, including a
second wand or bracelet; the pose grants no off-hand capacity. Preserve its Mage restriction,
existing damage (`damage-k: 8`), beam attacks, combo rules and **32-cube upgrade limit**.
Under D6's existing two-handed size class, a **common wand costs 20 wood cubes at a workbench**
(`5 × 4`), with existing rarity-gem requirements unchanged. This selects a complete two-handed
loadout, not a one-handed pairing or a new damage/upgrade exception.

`weapon-types.json#wand.hands` is `2h`; `recipes.json#gear-weapons.wand` lists 20 wood cubes at a workbench.

Hybrid (D24): `design.movesets.<weapon-type>.m1|m2` gives every class weapon its runtime — melee sphere (swing / radius mults,
spin around the player, lunge, finisher status), projectile (count, spread, speed, gravity, life, hit radius, splash, pierce,
return), beam (instant ray) or at-cursor (sphere where the aim lands); `c-moveset-config`. Data channels `m1`/`m2` mean basic/special attacks, never device bindings.
Crossbow bolts fly flat and fast.
Animations/hit timing, boomerang steering, held-ray Wand special attack, Bow dud shots and arrow pickup
are outside the D24 slice, not final exclusions. Creature projectiles use D26's
`design.creature-roles`, not the player movesets.

Hybrid (D25): `design.feel.events` bundles feedback per combat event (hit-stop, camera trauma, sound, damage number,
impact flash) — hit, crit, kill, hurt, block, dodge, shoot, impact; `c-feel-config`.
Tuning and shake, number, trail and impact behavior live in `generators.json#design.feel`.
Real audio assets, particles beyond sphere stand-ins, animations/hit timing and a reduce-shake /
reduce-flash accessibility screen are outside this slice, not permanent exclusions; design numbers
are tuning knobs, not a prohibition on later accessibility UI.

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

Non-projectile class strikes use the same landed-hit gain, inactivity timer and weapon cap. Preserve damage,
costs, cooldowns, taunt/healing effects and projectile/weapon attack behavior. Empty channel
ticks never reset combo; a wholly missed damaging channel resets on normal or early end.
Zero-damage taunts remain neutral even with no targets.

### special-attack
[Special attack](controls.md#special-attack): Warrior/Ranger/Mage charge; Rogue instant.
The MP bar turns pink for the amount to be spent; more MP means more damage and stun/knockdown
chance. Hybrid charge/release and costs use `generators.json#design.special-attack`; no physical
binding or historical class-cost default is defined here.

### combat-block
Defensive action, distinct from the terrain [block](#block).
[Block](controls.md#block) with shield (Guardian: any weapon; any warrior during Cyclone); drains `block-power`,
regenerates when not blocking (faster during Cyclone); successful block gives MP (D11:
the bar specials spend); Guardian block power ×2. `A S`
Hybrid (D23): numbers `design.defence.block`. Block and special attack are distinct intentions;
the current simultaneous hold coupling belongs to the [keyboard profile](controller-profiles.md#keyboard-and-mouse).

Hybrid exhaustion (walkthrough item 10): judge each hit
using the block-power available when it arrives. An eligible hit with positive power is blocked
normally, even if its cost empties the bar; its attached statuses remain blocked too. Subsequent
hits at zero power receive neither block reduction nor block MP rewards or status protection,
even before the next defence update. Other defences still apply. Preserve all block numbers,
regeneration, Guardian and Cyclone rules.

### dodge
[Dodge](controls.md#dodge) while moving: roll with i-frames (not vs spike traps / dagger poison), costs 25 stamina (25 %),
dismounts, negates fall damage on landing. Ninja gains +25 MP and guaranteed crit; Assassin gains
stealth. `A S`
Hybrid (D23): `design.defence.dodge` (roll 4 blocks in 0.4 s, i-frames 0.4 s).

### stealth
Separate bar: up to +20 % attack power, +50 % crit, faster MP gain, near-zero aggro at full;
decays when not generated; sources: sneak (faster still / in dark, slower in daylight / near
lamps), assassin specials, camouflage (instant full), sniper aim `A` / charging `S`. `A S`
Hybrid (D23): `design.defence.stealth` + `design.abilities.<id>.stealth-per-s|stealth-full`. Darkness and lamp effects above are historical, not selected hybrid parameters.
Hybrid threat behavior (approved 2026-09-27): full stealth means zero new damage-generated
threat, not a threat wipe or taunt cancellation; landing-time checks and DOT follow §3.2 `ai-behavior`.

### status-effect
→ `instances/status-effects.json`: poison, burning, slow/frozen (blue tint), stun (stars),
knockdown, knockback, taunt (red tint), stealth (transparent), possessed `S`, mana-absorption `S`,
petrified `S`, dizzy (glider crash), drowning `S`, injured `X` (2012 devlog death debuff),
buffs: battle-fury, berserker-rage stacks, torrent stacks, hit-series, fire-spark, intuition,
elusiveness-window, elixir ×4, beverage-resistance ×3, circle-of-power, mana-shield `A`, bulwark `A`,
war-frenzy `A`, scouts-swiftness `A`, camouflage, ninjutsu, shadow-shooter clone.

Hybrid (D23): creature hits on the player roll stun and knockback under
`design.defence.enemy-hit`; blocked or dodged hits roll neither.

Hybrid poison (D26; walkthrough item 10):
scheduled poison damage is not prevented by dodge i-frames. Preserve poison's identity through
tick delivery, including when burns coexist. Ordinary burning/direct-hit dodge behavior is unchanged;
independent applications follow the combat DOT rules below.

Hit-derived DOT's Resistance handling follows [stat](#stat), item 4.

**Hybrid combat DOT item 1 (owner approved, 2026-10-17):** each successful combat
hit-derived burning application creates its **own four-second burn**, without replacing or
refreshing earlier burns. Each application ticks every **0.5 seconds**, first at **0.5 seconds**
and last at **four seconds** after its application (eight ticks). Each tick retains D21's
**10% of the triggering hit** coefficient. Burns based on 100- and 50-damage hits therefore
deal **10 and 5 per tick**, respectively, while both remain active; a multi-hit volley may
leave several burns.

**Hybrid combat DOT item 2 (owner approved, 2026-10-17):** every combat hit-derived poison
application has an **independent lifetime and schedule**. Dagger poison delivers its existing
five ticks at **one, two, three, four and five seconds after application**. New applications
neither refresh older stacks nor reset their next tick. Applications two seconds apart finish
at seconds **five and seven**, respectively. Preserve poison stacking, inherited hit damage/crit
and the existing dagger total of **5 × the hit over five seconds**.

These rules select application lifetimes and scheduling, not new damage coefficients, Resistance
handling, dodge/status protections or aggro rules. Environmental hazards and additional DOT
buff timing are outside scope. Each application retains its damage, source, remaining lifetime
and next tick independently, catching up due ticks only within its lifetime. The selected
burning/poison design rows and numeric values are required inputs.

### death
No penalty in A or S (no gold/item/XP loss). A: respawn at nearest revival statue (never far), enemy
HP resets. S: only to an *activated* shrine of life; boss HP resets unless shrine is close.
`X`: 2012 "injured" debuff (reduced max HP, band-aids, cured by eating).

### 3.4 Items

### item
Concrete logical item instance. `A S`
The historical Alpha source description is `ItemData`, 88 bytes, with `upgrades[32]`
and a separate u32 counter; this is not an independently verified binary layout or a
choice of inactive-slot encoding for the logical model.
Logical fields and placed-cube structure are declared by [`item`, `item-upgrade`,
`item-type`, `item-sub-type`, `item-weapon-type`, `item-modifier`, `item-minus-modifier`,
`item-rarity`, `item-material`, `item-flags`, `item-level`, `item-upgrades`,
`item-upgrade-count`, `item-land`, `item-plus` and `item-name`](../schema/items.yaml).
The width declarations are [`uint32`, `u8`, `i16` and `i8`](../schema/identity.yaml),
not a verified binary ABI. Modifier seeds drive stat roll
`roll = ((attributes<<16)+modifier) % 21` and naming; flags include adaptation.
Generated rarity is 0..4 (5+ is the mythical bug), not removal of reference rarities.
A power applies to consumables/formulas too; S hides power and binds origin region.
S `land` and the adjacent-land `+` suffix are inert historical metadata in hybrid.
Display name is derived by `item-name`, not a mandatory stored input.

Weapon items have one logical weapon-type link; nonweapon items have no applicable
weapon-family link. This relation does not replace or narrow the existing type/sub-type
fields, equate logical IDs with Alpha numeric codes, or select a raw-source conversion
algorithm. Declaring the reference is distinct from resolving or enforcing it.
The linked weapon definition governs the existing 1H 16 / 2H-and-shield 32 cube limits
([c-cube-cap](5_Constraints.md#constraint-catalog)). Material compatibility uses the
concrete item's material and existing material-kind facts, not unparsed weapon-material
alternatives. The active-list/count relationship chooses no save or native storage layout;
stat equations remain unchanged, including `n = level + 0.1 × upgrade_count`.

**Hybrid item power:** the `level` field on gear, consumables, formulas and spirit cubes
means integer item power **+1…+100**, not character/creature level. Recipe/formula power
requirements use these same units; this selects no recipe generation, identity or output defaults.
When producing an item from source level `L`, first compute the existing integer
[character power](#level-formula-a), then apply any existing spread in **power points**:
`item power = clamp(power(L) + offset, 1, 100)`. Without spread, use `power(L)` directly.
Source levels 1/10/100/200/1981 give baseline powers 1/32/84/91/100; equal −1/0/+1
spread gives [1,1,2] / [31,32,33] / [83,84,85] / [90,91,92] / [99,100,100].
Starting equipment remains +1. Producer source identities are specified under
[loot](#loot-rule), [shops](#shop) and the [encounter contracts](encounter-contracts.md).
Character/creature levels, XP, coin income and other level-valued domains stay in their
existing units. Stat, healing and price equations are unchanged, including fixed gear HP
and upgrade inputs below; corrected item-power inputs can change their resulting values.
Rarity, cube capacities, quantities, timings and the permanent regional-power-loss exclusion
are unchanged. Producers, already-powered constructor bounds and deterministic save/import
checks must enforce these units together, preserving source-level records.

Hybrid equipment uses item power as an [equip requirement](#power-gate-a), not weakened stats.

D18's damage/armor-only gear stats are slice coverage, not a permanent exclusion of HP,
regeneration, tempo or crit.

**Hybrid gear HP:** otherwise-identical existing HP-bearing gear has a **fixed HP bonus**,
independent of modifier roll:

`HP bonus = curve(n, rarity) × 5 × slot × (2 + materialBonus)`

Use the unchanged [Alpha base curve](6_Generators.md#6-generators), with
`n = level + 0.1 × upgrade_count`; rarity is distinct from the normalized modifier roll.
This applies only to existing HP-bearing weapons, chest, shoulders, gloves and boots:
`slot = 1` for chest, `0.5` for those other pieces. Material bonus is **iron 1, cotton 0.75,
linen 0.5, otherwise 0**. No jewelry HP, random HP allocation or clamp is added.
This new hybrid simplification removes only the disputed HP modifier-roll term, not the
level/rarity/cube curve; it is not a recovered Alpha formula. Historical evidence and all other
item-stat/artifact rules remain unchanged. Active numeric inputs are `generators.json#design.gear-hp` (`curve-mult` 5, `base` 2, `upgrade-step` 0.1),
`materials.json#<id>.hp-bonus` for iron/cotton/linen, and the six HP-bearing
`equipment-slots.json#slots` rows' `hp-mult`. Other materials contribute zero material bonus.
The disputed Alpha HP expression remains historical reference, not the hybrid rule.

**Equipped player HP:** maximum HP is the unchanged class-scaled base
`curve(level, 0) × 2 × 100 × current class HP multiplier`, plus the sum of equipped eligible
item HP bonuses, once per item (including existing off-hand equipment). Do not multiply gear
HP by class again; bag items add nothing. After a successful equipment change, preserve absolute
current HP, capped at the new maximum. Equipping never heals or revives; a dead player's HP
stays zero. Rejected equipment changes leave HP unchanged, and unrelated inventory notifications
must not change HP. Initialization, level-up and respawn/inn recovery retain their existing
full-heal behavior, using the equipped maximum; level-up retains equipment contributions.
Percentage-based heals, shields and fall damage continue to sample maximum HP at their existing
times; no buff-rescaling, artifact or passive redesign is introduced.

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
or stat bonus is added. The [quick consumable](controls.md#quick-item) is separate: selecting it does not displace gear.

Approved hybrid model (reconciliation item 3, 2026-09-15): `accepts` names `item-type` IDs,
with subtype restrictions where needed:
- `lamp` accepts `light` (subtype `lamp`).
- `special` accepts `special` (subtypes `hang-glider` or `boat`), one equipped at a time.
- Hand slots accept `weapon`; shields are weapon subtypes, not a separate item type.
  Existing class and handedness restrictions still apply (`c-weapon-class`, `c-hands`).
- `pet` accepts a `pet-cage` or `pet-food` during taming, without replacing the quick-consumable selection.
- Armor and jewelry retain their matching slots; `unknown-0` accepts nothing.

No new slot follows. Wand handedness is defined under `weapon-type`; traversal
approvals are recorded separately under `skill-tree` / `pet`. Gliding/sailing require the respective Hang
Glider/Boat equipped in `special`, not merely bought (traversal items 2–3, approved 2026-09-28). They share
that single slot; no dual equip or new slot.

Hybrid hand-conflict repair (item 10, authorized 2026-09-17): reject an equip attempt that would
pair a two-handed weapon with a shield, regardless of equip order. Leave existing equipment and
the attempted item in the bag unchanged; do not auto-unequip, delete or duplicate either item.
A Wand counts as two-handed. Valid one-handed-plus-shield setups, two-handed weapons alone, legal
1H pairs and non-conflicting slot replacements remain subject to slot/subtype and class/material rules.
Hand compatibility selects no off-hand attack or damage, bracelet coefficients or change to Guardian/Cyclone blocking.

### consumable
Food (sit, immobile, heal over 15 s), potion (channel while moving), elixir `S` (10 min +20 % stat),
beverage `S` (10 min hazard resistance), bomb (100-HP fuse "pet" entity, breaks boulders, chains,
hurts players; A +1/+5/+10). → `instances/consumables.json` with recipes.
Heal formula A: `item-base-hp(n, rarity) × 200` (life/cactus potion, ginseng soup, snowberry mash,
mushroom spit) or `× 100` (pineapple slice, pumpkin muffin).

**Hybrid Apple:** nominal healing is the existing `item-base-hp(power, rarity) × 20` HP:
20 HP at common power +1, one tenth an equal-power/equal-rarity Life Potion, capped by
missing HP. This is a hybrid balance selection, not a historical formula claim. Other consumables do not
acquire a required healing coefficient or a general zero-heal use rejection rule.

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

### crafting-station
7 stations + campfire + "anywhere". → `instances/crafting-stations.json`.

### formula
`A` recipe scroll (item type 2) with +N level; sold by vendors, dropped by tier, on dungeon tables;
[Learn the formula](controls.md#learn-formula) once power suffices. Historically replaced in S by `book-of-crafting`;
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

Hybrid one-time book-source claims are personal per saved world (`save-data`, persistence item 5).
The [initial-site source exclusion](encounter-contracts.md#initial-permanent-source-scope) defers
source placement, not retained books or recipe knowledge; the S counts above select no hybrid quantities.

### customization-bench
Attach `material-cube`s (wood on wood, iron on metal; +0.1 effective level each; 16/32 cap) and
`spirit-cube`s `A` at 3-D positions on the weapon model: [rotate](controls.md#bench-rotate),
[place](controls.md#bench-place) and [remove](controls.md#bench-remove). Removal destroys the cube.

### spirit-cube
`A` boss drop: one per eligible non-mission boss kill, always the same type/level per boss.
Fire (+fire damage), wind (+attack & move speed per combo hit), ice (slows target, blue), unholy
(life steal on specials scaling with combo). Level must satisfy
`weapon-level − 10 ≤ cube-level ≤ weapon-level`.

Hybrid retains the recorded alpha exception (reconciliation item 7, approved 2026-09-15):
mission bosses, including Saurians, drop no spirit cube; their normal mission rewards are
unchanged. Sources: `creatures.json#saurian`, `mission-types.json#alpha.boss-kill`.
Initial hybrid [boss spirit acquisition](encounter-contracts.md#guaranteed-boss-gear-and-spirits)
fixes type and item power converted from the initial boss level across renewal; the weapon/cube
comparison above uses item-power points. Attaching spirits and numerical effects are outside
that slice, without removing this content or its bench restrictions.

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
→ `instances/pet-food.json` (58 obtainable + 5 cut `X`).

### key-item
`S` land-bound "special" items (A: glider & boat were bought items in the special slot).
→ `instances/key-items.json`: hang-glider, boat, reins, climbing-spikes (movement, 4/land);
divine-harp, sky-whistle, spirit-bell (ticket, 3/land); treasure-spirit, eternal-ember,
iron-lamp (`A` item / `S` innate light ability; [lamp control](controls.md#lamp)), dungeon keys (gold/silver/copper/boss keys), flute
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
target.

**Hybrid traversal item 5 (owner approved separately, 2026-09-28):** apply Spikes **after the
Climbing skill reduction**: `climbing cost with Spikes = skill-adjusted climbing cost × 0.25`.
Do not add 75 percentage points to the skill reduction. Illustrative only, not balance defaults:
if skill reduces a climb's cost from 10 stamina to 8, Spikes reduce 8 to **2**, not 0.5.
Climbing points retain their drain-reduction benefit alongside Spikes; Spikes alone do not turn
a positive skill-adjusted cost into zero. This defines neither the skill reduction curve/floor
nor artifact-combination semantics.

### artifact
Relic collectible from `S`; permanent and works everywhere; hybrid count is 1–3 per land (D11).
Derived naming and realm origin are [`artifact-name` and `artifact-origin-realm`](../schema/items.yaml).
The name form is "<Ring|Stone|…> of <Name>"; found at dungeon ends, vaults, sewers,
sky islands and some mission chests. **S reference only:** each relic granted +1 level;
riding/climbing/gliding bonuses were reportedly non-functional in 1.0 (functional in hybrid, D6).
Static entity id 46 "Artifact" exists in alpha data `X`.

Hybrid artifact-source claims are personal per saved world (`save-data`, persistence item 5).
The [initial-site source exclusion](encounter-contracts.md#initial-permanent-source-scope) does
not satisfy or replace this full-land allocation; later dedicated sources remain required.

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

`generators.json#design.artifact` records the normalized logarithm with
`first: 0.05` and adjustable positive `z`, initially `0.1`, without the obsolete decay/floor keys.
`key-items.json#artifact` separates historical S reports from hybrid rules; the hybrid ruleset
points to the approved curve. No legacy format or migration support is required (§0).

### currency
A: copper/silver/gold (100:1), platinum (adaptation only); S: single coin counter, auto-pickup by
walking. Prices/incomes in `instances/economy.json`.

### shop
Vendor with stock rules. → `instances/economy.json#shops` (weapon, armor, item/general, identifier,
gem-trader `S` roaming, inn, guild, flight-master, adapter `A`). S: stock rarity capped by rescued
gnomes; restock daily; buy-back tab; A: sales final, +1..+100 stock.

Hybrid `design.settlement.shop` selects eight gear offers, power-point spread 1, a common initial
ceiling and daily restocking. For gear, first convert the source level generated by the existing
land-danger/character-level rule, then apply the stock spread and clamp under [item power](#item).
Vendor consumables use the shop's character-level input converted directly, without spread;
they remain unlimited. Buy/sell price equations use item power where they read item `level`,
not source level; coefficients, rarity multipliers and rounding remain unchanged.
Remaining stock/purchases and world-shared supplier progress persist under `save-data`. The hybrid [supplier stock ceiling](encounter-contracts.md#shared-mission-packages-and-supplier-shops)
governs ordinary stock generation/restock, not an immediate rescue reroll or guaranteed top-grade stock.

### inventory
The per-character bag and worn gear. `A S`
Bag structure and slot/item associations are [`inventory`, `inventory-entry`,
`equipment-assignment`, `inventory-entries`, `inventory-equipment`, `inventory-coins`,
`inventory-entry-item`, `inventory-entry-count`, `equipment-assignment-slot` and
`equipment-assignment-item`](../schema/items.yaml); per-character ownership is
[`player-character-inventory`](../schema/entities.yaml).
There is no bag slot limit; count > 1 is allowed only for stackable item-types
(`design.stack-cap`, c-stack-rule). At most one item occupies each usable equipment
slot, subject to the type/subtype restrictions in `equipment-slot` (c-slot-accepts);
the separate Q selection is excluded. Coins are copper (`currency`), auto-picked up
under `design.loot.ground`. This selects no persisted map encoding.

| prop | type | notes |
|---|---|---|
| start | `design.starting-inventory` | D18: starter weapon equipped + 5 life potions |

Stacks have no cap (D6; one of each pet food). Tabs: equipment, special `S`,
items, ingredients, pets, artifacts `S` (A: amulets tab). S: one page per visited land. [Inventory control](controls.md#inventory).
[Quick selection](controls.md#quick-select) and [cycling](controls.md#quick-cycle) choose the
[quick item](controls.md#quick-item); physical inputs belong to profiles.

### loot-rule
Drops random by enemy tier ±1 (bosses +1 `S`); leftovers of player tier from same-colour
enemies; species drops; A eligible non-mission boss: spirit cube + gear of same +N;
mission bosses (including Saurians) drop no spirit cube in A / hybrid, keeping their normal
mission rewards; +4 dungeon chest → mythical `A X`;
S mission reward ≥1 class-fitting piece one rarity above quest colour + coins + 1 potion + gems;
dropped items last ~1 game week; mission NPCs drop rewards once. → `generators.json#loot`.
Open-world numbers (drop chances, rarity weights, level spread, ground lifetime, pickup radius):
`generators.json#design.loot` (D18). The initial encounter families' selected
[ordinary kill rolls](encounter-contracts.md#ordinary-kill-loot),
[guaranteed boss gear/spirits](encounter-contracts.md#guaranteed-boss-gear-and-spirits) and
[shared mission packages](encounter-contracts.md#shared-mission-packages-and-supplier-shops) are
separate rewards; personal permanent-source claims do not instance these shared drops.
Hybrid ordinary gear and consumables convert the defeated creature's level before applying
the existing shared loot spread under [item power](#item). Coin income and kill XP still use
creature level, not converted power. Source/cycle identity and saved reward payloads remain
stable across reloads; conversion does not authorize rerolls or re-awards.

### 3.5 Progression

### ruleset
Feature-flag bundle: playable hybrid uses Alpha progression plus approved Steam content (§1);
Alpha/Steam bundles are historical reference, not additional playable modes. → `instances/rulesets.json`.

### level-formula `A`
`power(lvl) = min(100, int((101·lvl − 81)/(lvl + 19)))` (truncate to integer; +100 at lvl 1981); `xp-to-next(lvl) = int(1050 −
1000/(0.05·(lvl−1)+1))`; `base-hp(lvl) = 2^((1 − 1/(0.05·(lvl−1)+1))·3)`; player HP = base × 2 ×
max-hp-multiplier; class HP multipliers warrior 1.30 (guardian ×1.25 more), ranger 1.10, rogue 1.20,
mage 1.00; 2 banked skill points per level for skill-tree spending; no level cap (int32).
XP per kill: `generators.json#design.progression` (D19). About five even-level kills give a level;
creatures 10+ levels below give zero XP. Carry overflow, allowing multiple level-ups per kill
by subtracting each reached level's XP threshold and retaining the remainder.
Recompute maximum HP for the new level, then refill HP. Hybrid uses the
[equipped maximum](#item), retaining gear contributions.

### skill-tree `A`
11 slots. Shared chains (5 points unlock next): pet-master → riding; climbing → hang-gliding;
swimming → sailing. Class column: skill-1 (1 pt) → skill-2 (5 in skill-1) → skill-3 spec-specific
(5 in skill-2). Points reduce cooldown and scale one effect: +5 % effect and −5 % cooldown per
point, cooldown floor 25 %, uncapped (D6). Respec at class trainer.
Hybrid (D10): retain the shared chains and Alpha class column above; add an `ultimate` column
holding the specialization's selected ultimate ability, unlocked by 5 points in its rank-3 skill.
The six Alpha skills removed in Steam return in their class column.
Assassin's single-skill exception is defined below.
Spending (D20): [spend one banked point](controls.md#spend-skill-point) on the
[skill-tree screen](controls.md#skills-window) (`ui.json#screens.skills`);
a node opens when the previous node of its column holds `alpha-tree.needs` points (roots 0); class ranks 1–3 + ultimate
activate through [class skill slots 1–4](controls.md#class-skill-1) (their runtimes: `design.abilities`, D21); per-point multipliers `design.skill-point`;
respec at the class trainer refunds every point to the bank for a fee (`design.settlement.trainer`, D22).

**Hybrid Assassin item 1 (owner approved, 2026-09-28):** Camouflage's alpha rank-3 skill and
Steam ultimate are **the same ability**, not separately purchased copies. After **5 Sneak
points**, spend at least **1 Camouflage point** to use it through **[third class skill](controls.md#class-skill-3)**. Assassin has **no
separate fourth node or fourth-slot ability**, even after five Camouflage points; `also-ultimate`
denotes the shared source identity, not another unlock. There is one point investment, one
cooldown and one buff, with no extra charge or duplicate purchase. Keep Camouflage's existing
effect, duration, cooldown, per-point scaling and approved stealth/threat rules unchanged.
This is an explicit Assassin exception to D10's separate ultimate node; other specializations
and the remaining D10/D20 rules stand. The player has three distinct class skills rather than
paying twice for the same skill. `also-ultimate: true` is source metadata, not a fourth unlock.

Hybrid traversal item 1 (approved 2026-09-28): the riding chain also requires global Reins
and a rideable tamed pet; training and further-point speed benefits follow `pet` / `c-riding`.

**Hybrid traversal item 2 (owner approved, 2026-09-28):** gliding requires **5 Climbing
points + at least 1 Hang Gliding point** and an **equipped Hang Glider bought from an item
vendor**. Further Hang Gliding points improve glide speed. Buying alone is insufficient;
the glider occupies the existing single `special` slot, not an extra slot.

**Hybrid traversal item 3 (owner approved, 2026-09-28):** sailing requires **5 Swimming
points + at least 1 Sailing point** and an **equipped Boat bought from an item vendor**.
Further Sailing points improve sailing speed. Buying alone is insufficient; equip the boat
instead of the glider in the existing single `special` slot, never both.

**Hybrid traversal item 4 (owner corrected, 2026-09-28):** basic climbing requires **neither
skill points nor Spikes**. Climbing points reduce stamina drain; global Spikes reduce climbing
stamina consumption by **75%**, not an exemption from stamina costs (`key-item`). Five Climbing
points remain the Hang Gliding prerequisite under item 2. This principle does not define the
skill reduction curve/floor. Item 5 separately applies Spikes to the remaining skill-adjusted
cost (×0.25), not additive percentage points (`key-item`).

### power-gate `A`
Alpha reference: item `+N` usable at full strength only if player power ≥ N; formulas learnable likewise.

Hybrid non-equipment items retain the full-strength condition: item `+N` is usable at full
strength only if player power ≥ N. This selects no below-threshold effects.

**Hybrid equipment requirement:** equipment `+N` cannot be equipped until character
[power](#level-formula-a) ≥ N, using the shared [item-power units](#item). Above-power
equipment may still be carried, traded or kept. Once eligible and equipped, its normal
stats apply; no reduced-strength formula is introduced. At +32 power, a +40 sword stays
in the bag until +40. Existing class, material, slot and hand restrictions and equipped
HP/no-healing rules remain unchanged.

This selection is **equipment-only**: it adds no consumable-use restriction or
spirit-attachment player-power gate, and selects no retroactive unequip/eviction or save
migration behavior. Existing formula-learning and book/crafting locks below are unchanged.
Equip eligibility uses character level; structurally legal already-worn gear remains intact on restore.

**Hybrid books/formulas item 3 (owner approved, 2026-09-28):** books record their unknown
recipes **immediately, regardless of current power**. A recipe above the character's power
remains **known but visibly locked against crafting until that power requirement is reached**.
It is a future crafting goal, not immediate crafting access. Formula learning retains its
existing sufficient-power requirement; books do not bypass recipe progression or change item
strength, materials or station requirements.

Known-but-locked recipes count as known for item 2's duplicate rules: another book teaches
nothing extra for them, and an already-known formula remains unconsumed. Neither source removes
the power lock or grants compensation for a duplicate.

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
Their [shared package and land-local shop ceiling](encounter-contracts.md#shared-mission-packages-and-supplier-shops)
follow the initial encounter contract.

Hybrid rescue eligibility requires all designated guards/bosses defeated and the captive
available for the rescue conversation. Talking then completes the rescue immediately, with no
extra key. If nobody talks, complete it automatically when the last player leaves the cleared
site, using [site occupancy](#game-clock). Both paths apply the same world-shared completion and
existing benefit exactly once, without duplicate dialogue or rewards.
Before completion, defeated designated rescue enemies remain daily-refresh eligible under
occupied-site protection. Completed guards/bosses stay cleared. On last-player exit, complete
an eligible rescue **before any pending daily refresh**, so refresh cannot undo permanent completion.

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
The logical [`mission-type.icon`, `.tier`, `.repeat` and `.structures`](../schema/meta.yaml)
facets and [`rewards`](../schema/relations.yaml) declare mission structure;
[`MissionTier`](../schema/meta.yaml) names the five tiers.
Icon means map glyph; white/green/blue/purple/yellow presentation remains hidden
white until visited on foot in S. Repeatability is daily / once per land as the
owning mission specifies; rewards follow [`loot-rule`](#loot-rule), not an inferred
universal package. Structures reference POIs/dungeons without selecting their existence.

**Hybrid initial encounter-contract scope:** an ordinary multi-boss ruins dungeon, a repeatable
daily hostile combat camp and one-time world-shared supplier-rescue sites. These are the first
families covered by the [initial encounter contracts](encounter-contracts.md), not a final content
limit. That contract defines placement, access, geometry, populations, local difficulty, boss
specials/rubble, traps/furnishings, kill/boss/mission rewards, supplier shops and bounded
permanent-source exclusion. Full-land sources and spirit customization remain separate work,
not removed content or requirements for this initial slice.

Within these families, physical sites stay fixed at their saved-world locations; eligible daily
enemies return at those sites. Family-specific repeatability/permanent completion and other
mission generation/reward rules are unchanged.

### arena `S`
5 waves: W/G, W/G, G/B, B/P, P/Y boss; any species (saurian, mammoth, yeti, mana mech, spectrino
pairs); hosted by a Bloodaxe orc; resets daily; 18–50 coins + gear; more common in oceans.

### 3.7 Meta

### multiplayer-mode
Hybrid (D5/D7): dedicated server, alpha style; max players configurable, default 4.
Players join by IP address or DNS name; the world-generation seed is configurable in server configuration.
Shared-clock inn sleep consent/payment follows `game-clock` item 4 (approved 2026-09-27).
Hybrid (D11): PvP is a server-wide `server.cfg` flag `pvp`, default off; `/pvp` is dropped.
A: dedicated `Server.exe`, TCP 12345, seed from `server.cfg`, connect by IP/DNS, 4 players (alpha-era wiki said 10),
client-authoritative, chat + `/connect /disconnect /name /namepet /pvp`, item trading by drop.
S: Steam-friends P2P (J), shared seed, keep own position, meet via free flights to friends,
artifacts lootable by all, ember per participant, other players' level on highlight, emotes
`/sit /wave /dance /pet`; no PvP, no trading UI, no dedicated server.

**Hybrid persistence item 6 (owner approved, 2026-09-28):** clients **request actions**;
the server validates movement, attacks, costs, damage, loot, purchases and progression against
the rules and decides gameplay outcomes. A client cannot simply announce extra money or a
successful hit. Client predictions may need correction to authoritative outcomes.
Alpha's client-authoritative protocol and `generators.json#network-alpha` are historical
reference, not hybrid authority. This chooses no transport/protocol, anti-cheat numeric defaults
or central trust service.

**Hybrid persistence item 7 (owner approved, 2026-09-28; depends on item 1):** accept
**rule-valid portable characters as trusted-co-op imports**, without requiring a central
progression service. Reject an invalid import with an explanation and **leave the original save
untouched**; never silently strip items or levels. A legally shaped edited save can still pass:
item 6's authority over gameplay after joining cannot prove where imported progression was earned
and does not make portable progression cheat-proof. No provenance proof, closed economy or
global concurrency guarantee is promised.

### control-action
A distinct device-independent player intention whose per-action meaning and behavior remain in
[controls](controls.md), not inferred from a shared input. Its common structure is declared by
[`control-action`](../schema/meta.yaml): `control-action-id` (`ControlActionId`),
`control-action-value`, `control-action-lifecycle`, `control-action-context`, and
`control-action-effect-reference`. The action-specific rows remain authoritative for meaning
and behavior.

### controller-profile
Device-specific profiles use [`controller-profile`](../schema/meta.yaml), with its
`bindings` alias attached to the existing `has-input-binding` relation. Each
[`input-binding`](../schema/meta.yaml) record uses a required one-or-more
`input-binding-action` list of `control-action` references, constrained through
`control-action-id` (`ControlActionId`), plus `input-binding-physical-input`,
`input-binding-phases`, `input-binding-contexts`, `input-binding-mapping-status`,
`input-binding-alias-of`, and `input-binding-alias`. `control-action` attaches the existing
`bound-to-input` relation. Android's logical refinement is `android-controller-profile`
with `android-profile-parameters`; the source row is `android-profile-source-row` in
`catalog-meta.yaml`. These declarations encode relation cardinalities, not inverse or
foreign-key consistency or device behavior. [Profiles](controller-profiles.md) own binding choices,
mapping status, aliases and context. Gamepad remains unselected; Android has its own
[touch profile](controller-profiles.md#android).

### input-binding
A physical input/shape in a controller profile referring to one or more distinct control actions.
Several bindings may invoke one action; one input may serve several actions with documented
phases/context, without merging their meanings. The schema record is `input-binding` in
[`meta.yaml`](../schema/meta.yaml), with fields `input-binding-action`,
`input-binding-physical-input`, `input-binding-phases`, `input-binding-contexts`,
`input-binding-mapping-status`, `input-binding-alias-of`, and `input-binding-alias`.
`input-binding-action` is a non-inlined list with minimum cardinality one; its generated
items use the closed `ControlActionId` vocabulary. The original relation cardinalities are
structurally attached, but these schema classes do not validate inverse/foreign-key
consistency. Keyboard physical defaults:
`instances/keybinds.json#hybrid`; its [profile](controller-profiles.md#keyboard-and-mouse)
explains binding groups, contexts and aliases.

### hud-element
→ `instances/ui.json`: portrait+name+level/class+HP+XP (A), coins + key-item bar (S), HP/MP/stamina
bars, hotbar ([basic](controls.md#basic-attack), [special](controls.md#special-attack), class slots and [quick item](controls.md#quick-item)), stealth bar, pet HP/XP/hydration, message log, minimap (3-D,
rotating, scalable), compass, time/temperature/humidity, land caption, buff icons `S`, help widget
`S`, damage numbers, combo counter, stun stars, enemy name colours + stars, chat, world map (3-D
voxel, zoom 1:4..1:256, markers, missions, players, shrines, flight points), overview map `A`,
character sheet (power, HP, armor, resi, crit, haste, reg, weapon/armor rating), skills window `A`,
crafting window, inventory, quick-select wheel, customization bench UI, character creation, world
selection `A`, friends widget `S`. Hybrid (D17): `debug-menu` — the runtime profiling overlay any player
can open without a development environment: FPS, frametime, CPU/GPU graphs, GPU, driver and OS.
The [debug-menu control](controls.md#debug-menu) cycles hidden/compact/full, including in release play.

Hybrid (D25): floating target numbers, stars over stunned heads and buff icons with countdown fill
use `generators.json#design.feel`. The level-up toast pops from `level-up.pop-scale` back to ×1
over `level-up.pop-s`.

Hybrid world-map policy: the map shows only the complete world boundary and current player
position; it does not reveal terrain or exploration and has no pan, zoom, markers or map travel.
Time and world simulation continue, and the player remains vulnerable. While it is open, new
movement, look, combat and interaction requests are blocked; existing committed effects and
movement continue under their ordinary rules. Selected physical mappings are documented in the
[controller profiles](controller-profiles.md#keyboard-and-mouse).

Hybrid panel-time policy (walkthrough item 10, owner approved 2026-09-17): opening the inventory,
skill-tree or shop panel does not pause time, in either solo or multiplayer. The world and player
timers continue together: enemies and projectiles remain active, damage-over-time effects tick,
cooldowns count down, buffs expire and dodge protection ends under their existing rules. Opening
these panels grants no immunity or extension of protection; players remain vulnerable while browsing.
This does not decide new input availability or the behavior of other panels/menus. The world-map separately uses its approved live-time and input-gating policy above.
Keep gameplay input restrictions: live panel time does not admit new movement, combat or interaction requests.

### option
→ `instances/ui.json#options`: FPS limit (default 111), invert Y, camera speed, resolution,
windowed, render distance, AA samples (`options.cfg`), rarity display, music loop `S`, volumes,
UI/minimap presentation options. No physical defaults are defined here; see
[controller profiles](controller-profiles.md).

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
Initial-site identities, special timers, rubble, trap/prop renewal and once-only reward state
follow the [encounter contracts](encounter-contracts.md), without choosing a save format.

**Serialized save contract:** current wire
structures are declared by [`save-data` and `world-state`](../schema/save-world-world-state.yaml),
[`character-state` and `skill-investment`](../schema/save-character-character-state.yaml),
[`saved-item` and `saved-equipment-entry`](../schema/save-character-saved-item.yaml), and
[`character-world-position`](../schema/save-character-character-world-position.yaml).
Permanent geography is declared by [`saved-land-plan` and `saved-village`](../schema/save-geography-saved-village.yaml),
[`saved-site-layout`](../schema/save-geography-saved-site-layout.yaml) and
[`saved-assignment`](../schema/save-geography-saved-assignment.yaml). Shared mutable structures
are [`saved-mob`](../schema/save-combat-saved-mob.yaml),
[`saved-combat`](../schema/save-combat-saved-combat.yaml), [`saved-site`](../schema/save-world-saved-site.yaml),
[`saved-contents` and `saved-reward`](../schema/save-world-saved-contents.yaml), and
[`saved-vendor`](../schema/save-content-saved-vendor.yaml). These wire definitions do not replace
the distinct logical portable progression and per-world persistence policies above.
Invalid input is rejected with diagnostics before replacing the original save;
validation checks current rules, not whether progression was earned. Restoring the hero refills
HP; transient player HP, statuses and cooldowns are not captured. Lifecycle saves cover meaningful
state transitions, unload and graceful shutdown, not a guaranteed crash-checkpoint cadence.
There is no legacy migration or offline time advancement.

### slash-command
→ `instances/slash-commands.json`.

### audio
Composer Wollay. Tracks and SFX ids → `instances/audio.json`. Races have distinct voices.
Hybrid (D25): `generators.json#design.feel.sfx` defines the feedback sound profiles
(frequency, duration, noise and pitch slide), keyed by `audio.json#sfx-alpha-ids`.

### version
→ `instances/versions.json`: dated feature timeline (devlog 2011–2013, alpha patches 2013-07-05 /
07-23, beta 0.9.1-3 … 0.9.3-0, 1.0.0-0/1, Omega posts 2023) and the recurring fan fix-list.

---

