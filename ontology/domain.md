# Cube World Rebuild — Domain Ontology (canonical layer)

Source of truth for the rebuild of **Cube World** (Picroma / Wollay). Code, data and content are
derived from this file and `instances/`. Nothing downstream may drift ahead of it.

## 0. Conventions

- Every class, relation, generator and instance has a **stable kebab-case ID**. IDs never change
  once referenced; rename the `name`, not the `id`.
- **Version tags** mark where a fact comes from. A feature may exist in several versions.
  - `A`  Alpha 0.1.0 / 0.1.1 (July 2013)
  - `S`  Steam 0.9.x beta → 1.0.0-1 (Sept 23 – Oct 1 2019)
  - `Ω`  Cube World Omega (announced 2023-05-25, unreleased; only announced facts)
  - `X`  present in shipped data / devlog but cut, unused or never functional
- `?` after a value = single-source, conflicting or unverified. Listed in §7.
- Properties are split **intrinsic** (belong to the thing) vs **extrinsic** (references to other IDs).
- Runtime-generated content (terrain, dungeons, names, loot rolls, bosses) is **not** enumerated;
  its **generator** is a class (§6) and its config lives in `instances/generators.json`.
- Numeric formulas are written in plain infix. `lvl` = character level, `n` = item level.

Research dumps behind this file: `research_*.md` (classes/combat, items, world, creatures/quests,
systems). Primary sources: cubeworld.fandom.com, cuwo (alpha server reimplementation, exact data
layouts), CWSDK (1.0 modding SDK), coremaze stat reverse-engineering, Wollay's 2011–2013 devlog
(Wayback), picroma.com 2013, wollay.com (Omega), Steam patch notes and guides.

---

## 1. Scope

**Domain:** a seed-driven, infinite, voxel, third-person action RPG with 8 races × 4 classes × 2
specializations, procedurally generated lands (biomes, dungeons, settlements, missions), a
tame-anything pet system, crafting, and drop-in co-op. Two shipped rule sets exist and are
**mutually exclusive in progression**:

| Ruleset | Progression | Gear scope | Traversal unlocks | Fast travel |
|---|---|---|---|---|
| `ruleset-alpha` (A) | XP → levels → 2 skill points/level, skill tree, item power +1..+100 | global, Adaptation re-levels gear | skill tree + bought glider/boat | portals (rune stones), revival statues |
| `ruleset-steam` (S) | no XP; level = artifacts found; gear is the only combat power | **region-locked**; `+` items work in adjacent regions | per-region key items + artifacts | shrines of life, flight masters |
| **`ruleset-hybrid` (chosen)** | alpha XP/levels/skill tree | global, never degrades | skill tree + key items (global once found) + artifacts | portals, shrines, flight masters |

Everything else (world, creatures, weapons, combat feel, crafting stations, pets, settlements) is
shared with version-specific deltas.

**Decision D1 (owner, 2026-09-07): ship `ruleset-hybrid`.** Alpha progression (XP → levels →
skill points, skill tree, item power, adaptation, spirit cubes, formulas) **plus** all Steam
content (key items, artifacts, lore, arenas, factions and events, shrines, flight masters, elixirs,
gnome suppliers, books of crafting). **Region lock is dropped** (D4): equipment never loses power
when the character travels; there are no `+` items, no `worn` degradation, no per-land inventory
pages, and key items work everywhere once found. Artifacts stay as permanent traversal-stat
collectibles but no longer define level. Flags in `instances/rulesets.json#ruleset-hybrid`.
Alpha/steam rulesets remain documented for reference only.

**In scope:** all of the above, including cut content flagged `X` so it can be re-enabled.
**Out of scope:** Picroma's engine internals (Plasma GUI runtime, DX11 renderer), the exact
network byte layout of the 2013 protocol (kept as reference only), Steam platform integration,
Omega content beyond what was publicly announced.
**Later (v2):** Omega-only systems (weather, procedural body parts, signature abilities per
species, coarse-map-first generation) are modeled as `Ω` so they can be turned on later.

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
| CQ12 | How do NPCs / enemies behave? (hostility, aggro, groups, patrols, schedules, potions) | `hostility`, `ai-behavior`, `creature` fields |
| CQ13 | What status effects exist and what applies them? | `status-effect`, relation `applies` |
| CQ14 | What is the day/night cycle, what resets, how does sleep work? | `game-clock` |
| CQ15 | What persists between sessions and across worlds? | `save-data`, `world`, `player-character` |
| CQ16 | How does multiplayer work in each version? | `multiplayer-mode`, `slash-command` |
| CQ17 | What is on screen and which key does what? | `hud-element`, `input-binding`, `option` |
| CQ18 | What was in which version, and what did fans ask to fix? | `ruleset` feature flags, `instances/versions.json` |
| CQ19 | What did Omega announce that the rebuild should leave room for? | `Ω`-tagged classes/fields |

---

## 3. Classes

Format per class: **id** — one-line definition. `versions`. Property table. Instances file.

### 3.1 World

### world
The single playable universe instance. `A S`
| prop | type | i/e | notes |
|---|---|---|---|
| seed | uint32 | i | A: chosen per world at creation (server default 26879); S: one fixed shared seed, no UI |
| name | string | i | A only (world list) |
| day | int | i | day counter |
| time-ms | int 0..86_400_000 | i | ms of game day |
| spawn-rule | enum `near-village` | i | S 0.9.1-3: new chars spawn near a village; A: world spawn (0,0 area) |
| discovered-zones | set<zone-coord> | i | per world; shared by all visitors of a server world (A) |
| origin-poi | `poi-type` ref | e | S: `wollays-house` at block (0,0) |
Instances: none (runtime). Config: `generators.json#world-scales`.

### zone
Terrain streaming unit (alpha "chunk"). `A S`
| prop | type | notes |
|---|---|---|
| size-blocks | int | A: 256×256; S: 64×64 (`BLOCKS_PER_ZONE = 64`) |
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
| level | int | i | A: all creatures share it; rises with distance from spawn |
| tier-range | `mob-strength-tier`[] | i | S: regions host white→yellow enemies, dungeons above surface |
| rarity | int 0..4 | i | A devlog "rare zones": stronger monsters, better loot `?` |
| realm | `realm` ref | e | S: the kingdom/cult/tribe whose lore covers it |
| border | polygon (map only) | i | dotted line on map, no physical wall (A devlog kingdoms had walls `X`) |
| inventory-page | — | — | S: each land owns an inventory tab (see `inventory`) |
| key-items | `key-item`[] ≤ 9 | e | S: up to 4 movement + 3 ticket + treasure spirit + ember |
| gnome-suppliers | 4 | e | S |
| books-of-crafting | 4 | e | S |
| wizard-towers | ≤ 5 | e | S |
| circles-of-power | 1..n | e | S |
| artifacts | 1..n | e | S |
| settlements | A: exactly 1; S: several | e | |
Internal grid: alpha region = 64×64 zones = 16 384 blocks; 8×8 mission cells per region;
world addressable as 1024×1024 regions (finite). Whether one gameplay `land` == one internal
region cell is unverified `?`.

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
| count-per-land | A: 1; S: several |
| sewer | S: dungeon under some 5★ villages holding an artifact |
| petrified | bool, S: witch curse until witch killed |
| possessed | bool, S: demon portal active in land |

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
| sleep-speed | 100× (clock only, world does not simulate faster) |
| midnight-reset | 0:00: respawn monsters (not already-cleared quest/dungeon mobs `S?`), regenerate missions, respawn deposits and wilderness plants, restock shops, re-close divine doors |
| inn-reset | innkeeper 18:00–06:00 → set 07:00; A free; S 10 coins, also re-rolls daily missions |
| night | very dark; lanterns; stealth builds faster in darkness |
| weather | none in A/S; Ω: rain, snow, moving clouds, freezing water |

### 3.2 Entities

### entity
Anything with a position, HP and appearance. Base of player, NPC, creature, pet, bomb. `A S`
| prop | type | notes |
|---|---|---|
| pos, velocity, accel, roll/pitch/yaw | vectors | pos as int64 native units |
| hostility | `hostility` enum | friendly-player 0, hostile 1, friendly 2/4/5, named-friendly 3, target 6 |
| species | `race` or `creature` ref | alpha entity-type id 0..155 |
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
| stats | **none** (purely cosmetic) `?` (tester claim: small races smaller hitbox, more knockback) |
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
| artifacts | S (level = count) |
| inventory, equipment, coins, platinum `A` | |
| known-recipes | A formulas learned; S books per land |
| lore-known | S per realm |
| discovered lands/portals/shrines/flight-points | |
| pets (cages), active pet, pet slot | |
| world-independent | A: any character enters any world; S: one world |
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
| alpha-entity-id | int? | 0..155 or null (post-alpha) |
| family | `creature-family` ref? | beetles, runners, slimes, alpacas, dogs, skeletons, golems, sprouts |
| category | animal \| insect \| aquatic \| plant-creature \| monster \| undead \| demon \| elemental \| humanoid \| boss-species \| static-target \| unused |
| hostility-default | hostile \| neutral \| passive \| friendly \| variable (by tribe) |
| landscapes | refs | |
| habitats | caves, rivers, dungeons, graveyards, pyramids… |
| group-size | range | e.g. runners 3–5 |
| combat-role | melee \| ranged \| mage \| any-class \| none | humanoids may be any class |
| tame-food | `pet-food` ref? | null = untameable |
| rideable | bool `?` | many conflicts (1.0.0-1 bug made all rideable) |
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

### creature-family
Shared base form. → `instances/creature-families.json`.

### pet
A tamed creature owned by a player. `A S`
| prop | notes |
|---|---|
| species | `creature` ref |
| name | via `/namepet` |
| cage | `item` of type pet (turtle cage = shell) |
| level, xp | A (did not persist in multiplayer) |
| hydration | A: droplets under HP; drains while riding; refill in water |
| scaling | S: from owner's weapon/armor rating incl. `+` gear |
| boss-origin | tamed boss keeps skills, normal size; reverts to normal on reload |
| behaviour | never initiates; attacks owner's target; recall/ride key; teleports to owner if far (S); revives ~1 min after death or on re-slot; ignores wraiths |
| riding | A: needs pet-master 5 → riding skill; S: needs land's `reins`; dismount on attack/dodge/fall/shift/pet death/water |

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
| perception | group aggro: if one member sees you all attack; pull around corners |
| pathfinding | A* with climbing and arbitrary bounding boxes; chases "to the most unreachable locations" |
| patrol | ogre + collie patrols in dungeons, stronger than static guards; forest guards at campfires; some paths ignore stealthed players |
| stun | stars over head; immune to re-stun while stars visible (players too) |
| potions | humanoids drink at low HP |
| combo | enemies build combos against players (armor pierce) |
| chase | wraith pursues longer; most drop chase eventually `?` |
| clones | some bosses/NPC mages summon doppelgangers |
| possession | S: demon portal randomly possesses NPCs in the land (bigger, red, tougher, respawn possessed) |

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
spell-power, armor, resistance, crit, haste (alpha "tempo"), regeneration (stamina `S` / HP `A?`),
mana-regeneration `A`, block-power, weapon-rating & armor-rating `S` (average star tier),
power-level `A`, movement speeds (climb, swim, dive, ride, glide, sail), light-radius.
Rules: armor is subtractive with floor ("no damage if armor > attack") `?`; combo counter
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
| alpha-tree | column, rank-needed (1 to unlock first, 5 in previous), per-point effect (values unpublished `?`) |
| alpha-ability-id | cuwo id (21 kick, 34 healing-stream, 48 intercept, 49 teleport, 50 retreat, 54 smash, 79 sneak, 86 cyclone, 88 fire-explosion, 96 shuriken, 97 camouflage, 99 aim, 100 swiftness, 101 bulwark, 102 war-frenzy, 103 mana-shield) |
| applies | `status-effect` refs |

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

### combo-system
Hit counter near cursor; +1 per landed hit; ignores growing share of armor and adds damage; any
whiffed attack resets; expires ~5 s idle; transfers between targets; per-weapon cap (turns blue with
"!"); enemies do the same. `A S`

### special-attack
M2. Warrior/Ranger/Mage hold to charge (MP bar turns pink for the amount to be spent; more MP =
more damage and stun/knockdown chance); Rogue instant. Mage M2 costs 30 MP (S). `A S`

### block
Hold M2 with shield (Guardian: any weapon; any warrior during Cyclone); drains `block-power`,
regenerates when not blocking (faster during Cyclone); successful block gives MP `A` / charges
special `S?`; Guardian block power ×2. `A S`

### dodge
M3 while moving: roll with i-frames (not vs spike traps / dagger poison), costs 25 stamina (25 %),
dismounts, negates fall damage on landing. Ninja gains +25 MP and guaranteed crit; Assassin gains
stealth. `A S`

### stealth
Separate bar: up to +20 % attack power, +50 % crit, faster MP gain, near-zero aggro at full;
decays when not generated; sources: sneak (faster still / in dark, slower in daylight / near
lamps), assassin specials, camouflage (instant full), sniper aim `A` / charging `S`. `A S`

### status-effect
→ `instances/status-effects.json`: poison, burning, slow/frozen (blue tint), stun (stars),
knockdown, knockback, taunt (red tint), stealth (transparent), possessed `S`, mana-absorption `S`,
petrified `S`, dizzy (glider crash), drowning `S`, injured `X` (2012 devlog death debuff),
buffs: battle-fury, berserker-rage stacks, torrent stacks, hit-series, fire-spark, intuition,
elusiveness-window, elixir ×4, beverage-resistance ×3, circle-of-power, mana-shield `A`, bulwark `A`,
war-frenzy `A`, scouts-swiftness `A`, camouflage, ninjutsu, shadow-shooter clone.

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
13 entity slots: main-hand (M1), off-hand (M2), chest, shoulders, gloves, boots, amulet, ring-l,
ring-r, pet, special (glider/boat `A`), lamp `A`, consumable (Q). → `instances/equipment-slots.json`.

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

### crafting-station
7 stations + campfire + "anywhere". → `instances/crafting-stations.json`.

### formula
`A` recipe scroll (item type 2) with +N level; sold by vendors, dropped by tier, on dungeon tables;
right-click to learn once power suffices. Replaced in S by `book-of-crafting`.

### book-of-crafting
`S` 4 per land (uncommon/rare/epic/legendary), 3–4 recipes each, from hammer-icon missions; only
recipe source; recipes land-scoped.

### customization-bench
Attach `material-cube`s (wood on wood, iron on metal; +0.1 effective level each; 16/32 cap) and
`spirit-cube`s `A` at 3-D positions on the weapon model (rotate with M3, drag cubes). Removal
destroys the cube.

### spirit-cube
`A` boss drop (one per kill, always same type/level per boss): fire (+fire damage), wind (+attack
& move speed per combo hit), ice (slows target, blue), unholy (life steal on specials scaling with
combo). Level must satisfy `weapon-level − 10 ≤ cube-level ≤ weapon-level`.

### leftovers
Unidentified gear drop (type 14) with tier colour and +N; identified for a fee at the identifier
(A) / analyst (S); may roll one tier higher; land-bound `S`. `A S`

### adaptation
`A` adapter re-levels an item to the player's power for `platinum-coin`s (boss/mission reward);
lowering is free. Removed in S.

### pet-food
Item type 20; subtype id == creature id it tames; one of each carried at a time. → `instances/pet-food.json` (58 obtainable + 6 cut `X`).

### key-item
`S` land-bound "special" items (A: glider & boat were bought items in the special slot).
→ `instances/key-items.json`: hang-glider, boat, reins, climbing-spikes (movement, 4/land);
divine-harp, sky-whistle, spirit-bell (ticket, 3/land); treasure-spirit, eternal-ember,
iron-lamp (`A` item / `S` innate F ability), dungeon keys (gold/silver/copper/boss keys), flute
(auto-owned, activates shrines), alpha special-accessory data `X` (key, jewel case, medicine,
antivenom, band-aid, crutch, bandage, salve).

### artifact
`S` relic; +1 level each; permanent; works everywhere; raises exactly one of 7 traversal stats
(climb speed, swim speed, diving, ride speed, glide speed, sail speed, light radius), diminishing;
riding/climbing/gliding bonuses reportedly non-functional `?`; named "<Ring|Stone|…> of <Name>"
bound to a realm; found at dungeon ends, vaults, sewers, sky islands, some mission chests.
Static entity id 46 "Artifact" exists in alpha data `X`.

### currency
A: copper/silver/gold (100:1), platinum (adaptation only); S: single coin counter, auto-pickup by
walking. Prices/incomes in `instances/economy.json`.

### shop
Vendor with stock rules. → `instances/shops.json` (weapon, armor, item/general, identifier,
gem-trader `S` roaming, inn, guild, flight-master, adapter `A`). S: stock rarity capped by rescued
gnomes; restock daily; buy-back tab; A: sales final, +1..+100 stock.

### inventory
No slot limit; stacks (cap undocumented `?`; one of each pet food). Tabs: equipment, special `S`,
items, ingredients, pets, artifacts `S` (A: amulets tab). S: one page per visited land. Key: B (or I `A`).
Quick-select wheel (Tab, A/D) chooses the Q item.

### loot-rule
Drops random by enemy tier ±1 (bosses +1 `S`); leftovers of player tier from same-colour
enemies; species drops; A boss: spirit cube + gear of same +N; +4 dungeon chest → mythical `A X`;
S mission reward ≥1 class-fitting piece one rarity above quest colour + coins + 1 potion + gems;
dropped items last ~1 game week; mission NPCs drop rewards once. → `generators.json#loot`.

### 3.5 Progression

### ruleset
Feature-flag bundle selecting alpha or steam progression. → `instances/rulesets.json`.

### level-formula `A`
`power(lvl) = (101·lvl − 81)/(lvl + 19)` (cap +100 at lvl 1981); `xp-to-next(lvl) = int(1050 −
1000/(0.05·(lvl−1)+1))`; `base-hp(lvl) = 2^((1 − 1/(0.05·(lvl−1)+1))·3)`; player HP = base × 2 ×
max-hp-multiplier; class HP multipliers warrior 1.30 (guardian ×1.25 more), ranger 1.10, rogue 1.20,
mage 1.00; 2 skill points per level; no level cap (int32).

### skill-tree `A`
11 slots. Shared chains (5 points unlock next): pet-master → riding; climbing → hang-gliding;
swimming → sailing. Class column: skill-1 (1 pt) → skill-2 (5 in skill-1) → skill-3 spec-specific
(5 in skill-2). Points reduce cooldown and scale one effect (values unpublished `?`). Respec at
class trainer.

### power-gate `A`
Item `+N` usable at full strength only if player power ≥ N; formulas learnable likewise.

### region-lock `S` — **DROPPED (D4)**
Reference only. In 1.0 gear, leftovers, bombs' loot and key items were bound to origin `land`;
outside they became worn/grey (e.g. 194.1 → 5.4 dmg) or stopped working; `+` items kept full stats
in adjacent lands. The hybrid ruleset removes all of it: `item.land`, `item.plus`, `rarity.worn`,
`land.inventory-page` and constraints `c-region-lock` / `c-plus-adjacent` are inert.

### lore `S`
Per realm; lore sites ≈ +10 % each; 100 % reveals all its artifacts on the map (all its lands);
`+` loot from 100 % is disputed `?`.

### gnome-supplier `S`
4 captives per land at white/green/blue/purple missions; each rescue raises shop stock one rarity.

### circle-of-power `S`
Kill restless warrior (5★) → eternal ember → light brazier → land-wide power buff (magnitude `?`);
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
A: dedicated `Server.exe`, TCP 12345, seed from `server.cfg`, connect by IP/DNS, 4 players (10 `?`),
client-authoritative, chat + `/connect /disconnect /name /namepet /pvp?`, item trading by drop.
S: Steam-friends P2P (J), shared seed, keep own position, meet via free flights to friends,
artifacts lootable by all, ember per participant, other players' level on highlight, emotes
`/sit /wave /dance /pet`; no PvP, no trading UI, no dedicated server.

### input-binding
Default keys per version. → `instances/keybinds.json`. A: no remapping; S: remappable, saved.

### hud-element
→ `instances/ui.json`: portrait+name+level/class+HP+XP (A), coins + key-item bar (S), HP/MP/stamina
bars, hotbar (M1, M2, 1–4 `A`, Q), stealth bar, pet HP/XP/hydration, message log, minimap (3-D,
rotating, scalable), compass, time/temperature/humidity, land caption, buff icons `S`, help widget
`S`, damage numbers, combo counter, stun stars, enemy name colours + stars, chat, world map (3-D
voxel, zoom 1:4..1:256, markers, missions, players, shrines, flight points), overview map `A`,
character sheet (power, HP, armor, resi, crit, haste, reg, weapon/armor rating), skills window `A`,
crafting window, inventory, quick-select wheel, customization bench UI, character creation, world
selection `A`, friends widget `S`.

### option
→ `instances/ui.json#options`: FPS limit (default 111), invert Y, camera speed, resolution,
windowed, render distance, AA samples (`options.cfg`), rarity display, music loop `S`, volumes,
UI scale F2/F3, hide UI F4, minimap scale F5/F6.

### save-data
A: `Save/characters.db` (sqlite `blobs(key,value)`; character blob ≈ EntityData), per-world
`world.db` (discovered map); assets `data1.db`/`data2.db`; characters world-independent.
S: per-world sqlite (`world_db_database`), Steam Cloud listed. Pets' XP didn't persist in
multiplayer `A`.

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
| costs | ability | resource | 1→0..1 | with amount |
| applies | ability ∪ weapon-type ∪ hazard | status-effect | n→n | |
| has-moveset | weapon-type | ability (m1, m2) | 1→2 | |
| crafted-at | recipe | crafting-station | 1→1 | |
| consumes | recipe | ingredient ∪ material | 1→n | with counts |
| produces | recipe | item-type ∪ consumable | 1→1 | |
| refines-to | ingredient | ingredient | 1→1 | nugget→cube, fiber→yarn, log→wood cube |
| yields | flora ∪ deposit ∪ creature | ingredient | 1→n | count range |
| spawns-in | creature ∪ flora ∪ deposit | landscape ∪ terrain-feature ∪ dungeon-type ∪ poi-type | n→n | |
| placed-in | dungeon-type ∪ poi-type ∪ settlement | landscape | n→n | |
| tamed-by | creature | pet-food | 1→0..1 | food subtype == creature id |
| member-of-family | creature | creature-family | n→1 | |
| belongs-to-faction | creature ∪ npc-role | faction | n→n | |
| hosts | dungeon-type ∪ poi-type | mission-type | n→n | |
| rewards | mission-type ∪ arena ∪ poi-type | item-type ∪ key-item ∪ artifact ∪ currency ∪ book-of-crafting | n→n | |
| guards | creature (boss) | artifact ∪ key-item ∪ gnome-supplier ∪ magic-crystal | n→n | |
| drops | creature | item ∪ spirit-cube ∪ leftovers ∪ currency | n→n | random by tier + species list |
| requires-key-item | poi-type ∪ dungeon-type | key-item | n→n | harp→divine door, bell→crypt gate, whistle→bird statue, reins→riding |
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
| equips-in | item-type | equipment-slot | n→1 | |
| restricted-to-class | weapon-type ∪ material | character-class | n→0..1 | |
| has-hazard | landscape ∪ terrain-feature | status-effect | n→n | cold-water, toxic, lava |
| countered-by | status-effect | consumable | n→n | hot chocolate, green smoothie, lemonade |
| raises-stat | artifact ∪ ability ∪ spirit-cube ∪ elixir | stat | n→1 | |
| mounts | player-character | pet | 1→0..1 | needs riding skill `A` / reins `S` |
| owns | player-character | pet | 1→n | cages |
| possesses | poi-type(demon-portal) | npc-role ∪ creature | 1→n | S |
| petrifies | creature(witch boss) | settlement | 1→1 | S |
| scales-with | pet | stat(weapon-rating, armor-rating) | 1→2 | S |
| adjacent-to | land | land | n→n | derived from grid |
| enabled-by | ability ∪ item-type ∪ mechanic | ruleset | n→n | feature flags |

---

## 5. Constraints

| id | rule | layer |
|---|---|---|
| c-race-class | any race × any class × either gender is valid | type |
| c-spec-of-class | specialization.class == character.class; player starts as spec index 0 | load |
| c-one-active-pet | at most one pet summoned; one of each pet-food carried | runtime |
| c-food-id | pet-food.subtype == creature.alpha-entity-id (or post-alpha id) | load |
| c-weapon-class | equipping weapon-type/armor material requires matching class (red name otherwise) | runtime |
| c-hands | 1H ×2 or 1H + shield or one 2H; bracelets need two for full damage | runtime |
| c-cube-cap | upgrades ≤ 16 (1H) / 32 (2H, shield); wood cubes only on wood weapons, iron on metal | load+runtime |
| c-spirit-level | A: weapon.level − 10 ≤ spirit.level ≤ weapon.level | runtime |
| c-power-gate | A: item.level ≤ power(player.level) for full strength; formula learn likewise | runtime |
| c-region-lock | DROPPED (D4). S reference: item.land ≠ current land ∧ ¬plus → worn; key items inert | — |
| c-plus-adjacent | DROPPED (D4). S reference: plus item full stats iff current land adjacent | — |
| c-gear-global | hybrid: an item's stats are identical in every land; key items and artifacts work everywhere once found | runtime |
| c-rarity-range | rarity ∈ 0..4 for generated items (5 = mythical bug, off by default) | load |
| c-stat-roll | roll = ((attributes<<16)+modifier) mod 21 ∈ 0..20 | load |
| c-mp-range | mp ∈ [0, 100]; mage regenerates passively, others gain by hits/blocks/stealth/dodges | runtime |
| c-stun-immunity | cannot re-stun while stars shown | runtime |
| c-combo-reset | any attack with a hitbox that misses resets combo to 0; cap per weapon-type | runtime |
| c-dodge-cost | dodge costs 25 stamina; requires movement; standing still M3 = class skill (S) | runtime |
| c-no-death-penalty | death never removes gold/items/xp; respawn at statue (A) / activated shrine (S) | runtime |
| c-time-speed | clock 10× real; sleep 100× clock-only | runtime |
| c-midnight-reset | at 0:00 respawn mobs, regen missions, deposits, plants; restock shops | runtime |
| c-inn-hours | inn reset only 18:00–06:00 → 07:00 | runtime |
| c-land-count | S per land: gnomes = 4, books = 4, movement items ≤ 4, ticket items ≤ 3, key items ≤ 9, towers ≤ 5, settlements ≥ 1; A per land: settlements = 1, missions = 64 cells | generator |
| c-key-item-need | a key item spawns only if its lock type exists in the land | generator |
| c-boss-size | A: boss size/strength from 1 at lvl 1 to full at lvl 10; S: dungeon boss size capped so it fits inside | generator |
| c-arena-waves | exactly 5 waves with tier ladder W/G, W/G, G/B, B/P, P/Y | generator |
| c-mission-reward | S reward rarity = quest tier + 1 (cap legendary) | generator |
| c-zone-size | A zone 256² blocks, region 64² zones; S zone 64² blocks | engine |
| c-block-rgb | every solid block has its own RGB; (0,0,0) in `.cub` = empty | data |
| c-name-length | entity name 2..16 ASCII 32–126 | load |
| c-versions-nonempty | every instance lists ≥1 version tag | load |
| c-rideable-conflict | if `rideable` is `?`, default to the per-page (stricter) value | load |
| c-hostile-in-city | villagers/animals inside settlements unattackable unless possessed | runtime |
| c-artifact-stat | each artifact raises exactly one of the 7 traversal stats; never combat stats | load |
| c-drowning | S only: breath depletes underwater; empty → HP loss; wall-hold pauses | runtime |
| c-gate-doors | divine doors re-close at 0:00; bell spirit world lasts 30 s (45 `?`) | runtime |

---

## 6. Generators

Procedural systems. Config + invariants in `instances/generators.json`. Seeds make output
reproducible; each generator lists invariants that a test can assert.

| id | input | output | invariants |
|---|---|---|---|
| gen-world | seed | infinite grid of internal regions → lands; region data generated 3×3 around player, region seeds 7×7 | same seed = same world; no borders; finite 1024² regions |
| gen-climate | seed, x, y | temperature, humidity → landscape choice | equal-sized lands; features can appear off-biome (volcano in snow) |
| gen-terrain | land, zone coords | heightfield columns, caves, rivers+waterfalls, lakes, mountains/plateaus, mesas, overhangs; per-voxel RGB by block type & landscape palette | walkable roads with tunnels/bridges; water at rivers/lakes/oceans |
| gen-coarse-map `Ω` | land seed | coarse map placing streets, buildings, rivers, bridges, trees, caves logically before voxel detail | every structure reachable by road |
| gen-flora | landscape, zone | trees (procedural, unique), bushes, scrubs, cacti, flowers, mushrooms, fields | per-landscape rosters |
| gen-settlement | land | 1 (A) / n (S) settlements: districts, procedural buildings (rooms, sizes, roofs), styles, NPC population + schedules, shops, inn, trainers, flight master (S) | ≥1 inn (A several, S exactly 1); shops per district |
| gen-dungeon | land, dungeon-type, tier | layout (A linear + dead end; S room gauntlet), traps `A`, chests, spawns in groups 2–4, boss(es), artifact `S`, locks needing key items | entrance rules per type; at least one boss; artifact at end (S castles always) |
| gen-poi | land | campsites, arenas, towers ≤5, circles, portals, pumps, trees, shrines, lore sites, spawner nests, hidden treasure, sky islands | counts in `c-land-count` |
| gen-missions | land, day | A: 8×8 cell boss missions; S: typed missions with icons and tiers, daily regeneration | tier ladder white→yellow present; gnomes/books once per land |
| gen-spawns | zone, land level/tier | creature spawns: species by landscape roster, group sizes, hostility, humanoid class/spec, `+1..+4` multipliers (A), boss-ification chance | dungeon mobs above surface tier; farm animals white |
| gen-boss | spawn | named, enlarged, coloured-tier variant with 1–2 random special moves; always-boss species; fixed spirit cube per boss (A) | size scaling rule; terrain breaking |
| gen-name | seed, kind | land names (`<Name> Plains…`), dungeon names ("Castle ___"), realm/leader/capital names, item names (affix + material + type + of-name), boss names, NPC names, quarter names | epic/legendary items always named |
| gen-item | tier/level, rarity roll, type, material, land (S) | `item` with modifier roll; stats via `gen-item-stats` | rarity ≤ legendary except mythical bug |
| gen-item-stats `A` | item | damage/HP/armor/resi/regen/tempo/crit from coremaze curves: `curve(n,r) = 2^((1 − 1/((n−1)·0.05+1))·3) · 2^(r·0.25)`, `curve2 = curve/8`, `n = level + 0.1·cubes`; per-type k and material multipliers | monotone in level and rarity; roll ∈ 0..20 |
| gen-loot | killer tier, source | drops per `loot-rule` | ±1 tier; species items; bosses +1 (S) |
| gen-realm `S` | region cluster seed | realm kind, names, leader bio, capital, lore sites, artifact set | 100 % lore ⇒ all artifacts revealed |
| gen-npc-appearance | race, gender, seed | head/hair model ids, hair RGB, part scales (Ω: fully procedural bodies, expressions) | asset counts in `races.json` |
| gen-schedule | settlement | daily A* paths for villagers; lantern at night; campsite rests | sleep at night |
| gen-key-items `S` | land | subset of the 9 key items consistent with locks present | `c-key-item-need` |

---

## 7. Open points for validation

Decisions only the owner can make (D) and facts research could not settle (F).

- **D1 Ruleset — DECIDED 2026-09-07: hybrid** (see §1).
- **D2 Engine — DECIDED: Godot 4 + GDScript**, conditional on a maintenance check of the
  engine (agent dispatched). `model.gd` follows.
- **D3 Cut content — DECIDED: not in v1.** Every `X` item is a follow-up in
  `docs/ROADMAP/*.md` (one file per theme, <100 lines, with online documentation links).
- **D4 Omega — DECIDED: roadmap only** (`docs/ROADMAP/omega-*.md`). Also: **region lock
  dropped** (gear never loses power while travelling).
- **D5 Multiplayer target**: dedicated server (alpha style) vs P2P vs both. Still open;
  hybrid default assumes alpha-style dedicated server (`flags.multiplayer`).
- **D6 Numeric gaps to design ourselves**: alpha per-point skill percentages, crit multiplier,
  1.0 stat curve, buy/sell price formula, artifact percentages, stack caps, enemy HP/damage per
  species, Circle of Power magnitude, vendor recipe quantities per weapon.
- **F1** Steam ability numbers with conflicts: heroic shout (heal/taunt vs debuff), toughness
  (+25 HP vs +25 %), battle fury trigger (per-hit ~12–14 % vs on-crit), shadow shooter 30 vs 20 s,
  bubbles 6 vs 8, shuriken 25 vs 50 stamina, R cooldown blanket 40/30 s vs per-skill.
- **F2** Rideable flags for ~12 species (table vs page; 1.0.0-1 all-rideable bug).
- **F3** `+` items: adjacent lands vs kingdom-bound; `+` from 100 % lore.
- **F4** Alpha land difficulty: level-by-distance vs "all power ranges per land".
- **F5** Alpha player cap 4 vs 10; skin-colour option existence; first-person zoom in 1.0.
- **F6** Whether 1.0 gameplay land == one internal 64×64-zone region cell; water level; noise
  parameters (the alpha generator exists only as x86 code wrapped by cuwo).
- **F7** Omega status after mid-2024 (Vulkan vs UE5 reports).
