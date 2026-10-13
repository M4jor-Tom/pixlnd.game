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

Unresolved subcases are tracked in §7 / `todo_decide.md`; deferred application is tracked in
`docs/ROADMAP/todo_implement.md`.
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
awaits separate authorization (`docs/ROADMAP/todo_implement.md`). Wand handedness is approved
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

