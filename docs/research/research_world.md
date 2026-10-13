# Cube World — WORLD / TERRAIN / GENERATION / LOCATIONS research

Scope: Alpha 0.1.x (July 2013), Steam 1.0 (beta 23 Sep 2019, release 30 Sep 2019), Cube World Omega (announced 25 May 2023). Facts are tagged **[Alpha]**, **[1.0]**, **[Omega]**, **[Devlog YYYY-MM]**, **[RE]** (reverse-engineered by modders/cuwo). `?` = uncertain / single unverified source. Conflicts noted inline.

Primary sources (all fetched):
- Fandom wiki (via MediaWiki API): https://cubeworld.fandom.com/wiki/<Page> — pages: Landscape, World_Map, Minimap, Greenlands, Wetlands, Savannahs, Deserts, Oceans, Jungles, Dark_Woods, Deadlands, Undead_Lands, Snowlands, Lava_Lands, Mountain, Mountains, Mushroom_Lands, Swamp_Lands, Forest, Canyon, Valley, Lake, Lava_lake, Island, Cave, Dungeon, Castle, Catacomb, Temple, Pyramid, Ruins, Vaults, Fort, Citadel, Den, Campsite, Arena, City, Trade_District, Adventurer_District, Crafting_District, Inn, Item_Shop, Armor_Shop, Weapon_Shop, Identifier's_Shop, Smithy, Workshop, Crafting_Station, Flight_Master, Gnome_Supplier, Gem_Trader, Shrine_of_Life, Resurrection_Statue, Portals, Wollay's_House, Demon_Portal, Giant_Tree, Giant_Rock, Mana_Tree, Mana_Pump, Circle_of_power, Magic_Barrier, Plants, Cactus, Bush, Scrub, Thorn_Tree, Mushroom, Cloud, Time, Sleep, Hang_Glider, Climbing, Boat, Sailing, Swimming, Diving, Key_Items, Movement_Items, Sky_Whistle, Divine_Harp, Spirit_Bell, Reins, Climbing_Spikes, Eternal_Ember, Treasure_Spirit, Artifacts, Relic, Realm, Missions, Main_Missions, Side_Missions, Quests, Mob_Strength, Power_Level, Levels, Bosses, Steel_Empire, Bloodaxe_Clan, Deposit, Iron_Deposit, Cube_World, Picroma, Multiplayer, Controls, User_interface, Slash_Commands, Book_of_Crafting, Adaptation, Teleport.
- Wollay's devlog (deleted; Wayback copies of http://wollay.blogspot.com/YYYY_MM_01_archive.html for 2011-05 … 2013-06).
- Picroma site 2013 (Wayback of http://picroma.com/cubeworld, "WORLD"/"ADVENTURE"/"CLASSES" sections).
- Wollay's new blog: https://wollay.com/ (Omega posts 2023-05-25 … 2023-10-14).
- cuwo (open server, MIT-ish GPL) https://github.com/matpow2/cuwo — `cuwo/constants.py`, `cuwo/tgen.pyx`, `cuwo/cub.py`, `cuwo/world.py`, `config/base.py`, `terraingen/tgen2/src/tgendef.h`, `tgen.h`.
- CWSDK (1.0 modding SDK) https://github.com/ChrisMiuchiz/CWSDK — `cube/constants.h`, `cube/Zone.h/.cpp`, `cube/World.h/.cpp`, `cube/Field.h`, `cube/BlockProperties.h`, `cube/WorldMap.h`, README.
- Steam: store page https://store.steampowered.com/app/1128000/ ; guides 1876780614 (Comprehensive Review), 1878288929 (Exploring with the map), 1871883807 (How to Actually Do Things), 1873333729 (So you want to face The Cube), 1871398574 (Darkmega's guide); discussions 1628538707065629300, 1628538707074634126, 1628538707056632011, 1626286205711209356, 1626286205709193054, 1626286205707338821, 1628538707060723582, 1628538644184996001.
- Press: Wikipedia "Cube World"; RPS "Some Time With: Cube World (Alpha)" 2013-07-15; Kotaku "Tips for playing the Cube World alpha" 2013-07-23; Polygon 2019-10-03; MassivelyOP 2023-05-26; cubeworld-servers.com blog (2017 tweets).

---

## 1. Version / timeline (world-relevant)

| Date | Event | Source |
|---|---|---|
| 2011-05-25 (≈) | Wollay starts "3D voxel-based game … two weeks ago" (first post 2011-06-08). Wiki says dev start June 8 2011. | Devlog 2011-06-08; fandom Cube_World |
| 2011-06-15 | Landscape voxel resolution doubled in each dimension ("still good framerates") | Devlog |
| 2011-07-06 | Villages, roads (auto tunnels through mountains + bridges over canyons), deserts w/ pyramids & oases; planned jungle, snow | Devlog |
| 2011-08-28 | Engine completely rewritten (faster, cleaner shading) | Devlog |
| 2011-09-05 | Procedural trees (each tree unique) | Devlog |
| 2011-11-26 | Castles (random size and rooms) | Devlog |
| 2011-12-12 | Rivers with little waterfalls; improved trees/forests | Devlog |
| 2012-01-18 | Climate system: temperature × humidity → biome; jungle shown; deserts, savannahs, tundras, snowlands "coming soon" | Devlog |
| 2012-01-20 | Caves added | Devlog |
| 2012-02-10 | Random dungeons: fire & spike traps, levers, doors, gates, bosses, chests | Devlog |
| 2012-02-27 | Kingdoms with frontier walls + guards; dungeon entrance runestone (port back after clearing) | Devlog |
| 2012-03-05 | Dungeon themes: mines, crypts, tombs (entrances) | Devlog |
| 2012-03-26 | Mountains and clouds added | Devlog |
| 2012-05 | Sarah "Pixxie" von Funck joins; villages with fields and inns | Devlog 2012-05-11 |
| 2012-07-07 | Land-name captions fade in on entering a land; streets with streetlights lead to villages; villages have shops, inns, towers (sage identifies) | Devlog |
| 2012-09-18 | Hang gliders (≈lvl 10+); "Rare zones" (zone rarity like items); castle dungeons; lava lands being added | Devlog |
| 2012-10-26 | World divided into lands, each with a level (all creatures same level; level grows with distance from start); each land has a capital city; buildings randomly generated; house themes (European framework, medieval stone, N-American wood, log; desert & jungle planned) | Devlog |
| 2012-11-04 | Landscape generator + renderer improved; 3D world map auto-recorded while exploring ("big version of the minimap") | Devlog |
| 2012-12-04 | A* pathfinding (climbing-aware); example NPC "Alerick" in "Tririon City" | Devlog |
| 2013-01-28 | Overview map of lands + levels (blue=ocean, green=own level, red=higher, gray=lower); world selection/generation screens; cities have districts + class trainers; NPC adventurer groups | Devlog |
| 2013-06-08 | picroma.com launched with feature pages | Devlog |
| 2013-07-02 | Alpha 0.1.0 released (Windows); DDoS; sales stopped | Wikipedia |
| 2013-07-05, 07-23 | Alpha patches (0.1.1?): inn reset only 18:00–06:00 | fandom patch notes |
| 2014-06-30 | Last official video before silence | gamelust via search |
| 2017-04-01 | Tweets: new 64-bit engine, new world map, new ocean music; new snow shading, new rivers; dungeon map that uncovers as you explore | cubeworld-servers.com/blog/20 |
| 2019-09-23 | Steam closed beta (0.9.1-3 … 0.9.1-6, 0.9.2-0, 0.9.3-0) | fandom Patch_Notes |
| 2019-09-30 | Steam 1.0 release (206 MB) | fandom Cube_World |
| 2023-05-25 | Cube World Omega announced (Vulkan engine) | wollay.com |
| 2023-07-30 | Omega "New World Generation" post | wollay.com |

---

## 2. World structure & engine (coordinates, zones, regions)

### 2.1 Infinite procedural world / seed
- "Nearly endless" world: no borders to reach; "you can literally reach each cube the world is made of". **[Alpha, picroma.com 2013]**
- World defined by one number, the **Game Seed**; same seed → identical world; terrain generated on the fly, "neither long precomputations nor huge save files". **[Alpha]**
- Alpha world-creation UI: character selection → world selection → world generation screen (enter seed). Characters are persistent across worlds (any character can enter any world). **[Alpha; Devlog 2013-01; Kotaku 2013]**
- Alpha dedicated server default seed **26879**, changed via `server.cfg` containing the seed; server port **12345** (TCP). **[Alpha, fandom Multiplayer; cuwo constants]**
- **[1.0]** No custom seeds: "every map is the same shared seed"; players start at a **random position** with coordinates typically > 5,000,000 / < −5,000,000 (blocks?) from origin; multiplayer via Steam friends (J key), join friend's world but keep your own location; friends can be ~100,000 km apart. Wollay's House Easter egg at coordinates (0,0); flight there from a typical start (≈54,000 km) costs ≈1.1 million coins. **[fandom Artifacts, Wollay's_House; Steam thread 1626286205709193054]**
- **[1.0]** Two places can share a name (e.g., two "Marnis Mountains", two "Akar Village") — names are procedural and non-unique.

### 2.2 Units and grid **[RE]**
- Native position unit: 1 block = **0x10000 = 65536** "dots" (`BLOCK_SCALE`, `DOTS_PER_BLOCK`). Positions are 64-bit ints. `FULL_MASK = 0x0000FFFFFFFFFFFF`.
- **Alpha**: zone ("chunk") = **256 × 256 blocks** (`ZONE_SCALE = BLOCK_SCALE*256`); region ("sector") = **64 × 64 zones = 16,384 × 16,384 blocks**; `MAX_POS = REGION_SCALE * 1024` → world addressable as 1024 × 1024 regions = 16,777,216 blocks per axis; `MISSION_SCALE = REGION_SCALE/8`, `MISSIONS_IN_REGION = 8` (8×8 = 64 mission cells per region; `Region.missions[64]`; `Region.zones[4096]`). Region struct 88,104 bytes; Zone struct 200 bytes (alpha 32-bit). (cuwo `constants.py`, `tgendef.h`, `tgen.h`)
- **Alpha**: Cube World generates region data in a **3×3 region neighborhood** around the player, and region *seeds* in a **7×7** neighborhood (cuwo `world.py` comment). `tgen_generate_chunk(x,y)`, `tgen_destroy_chunk`, `tgen_destroy_reg_seed` are the game's internal calls.
- **1.0** (CWSDK `constants.h`): `BLOCKS_PER_ZONE = 64`, `BLOCKS_PER_MAP_CHUNK = 20`, `DOTS_PER_BLOCK = 65536`. `cube::Zone` holds `Field fields[4096]` (64×64 columns); each `Field` = column with `base_z` + `std::vector<Block>` (vertical run starting at base_z; blocks below base_z are "interpolated" for the renderer). `Block` = 6 bytes: r,g,b, field_3, type, breakable. `cube::World` has `seed` (int), `world_name`, `WorldState{day, time}`, `world_db_database` (sqlite), `unordered_map<IntVector2, Zone*> zones`. Two `cube::World` objects exist at runtime (Game and Game::Host). Mod hooks: `OnZoneGenerated`, `OnZoneDestroy`, `OnChunkRemesh(ed)`.
- **Alpha** zone column storage (cuwo `tgen.pyx`): per-XY `Field` (32 B) with `a` = base z, `data` → array of `Color{r,g,b,a}`; the `a` byte packs: 5 bits block type, 1 bit "breakable by bombs/bosses", 1 bit mesh/cave darkness flag, 1 bit unknown. Iterates `256*256` columns per zone.
- cuwo `chunk_retire_time = 15 s` (server-side unload when unvisited) — server implementation detail, not the client's.

### 2.3 Block types **[RE]**
Alpha (cuwo, "found by static analysis"): 0 Empty; 1 Unknown solid; 2 Water (non-solid, no color); 3 Flat Water (walkable; sides colored, top looks like water); 4 Grass; 5 "Fields near cities and cliffs (border of plateaus in normal lands) except in lava lands"; 6 Rocks / Buildings (cities, quest buildings e.g. castles) / cliffs in lava lands; 7 Tree trunks & limbs; 8 Leaves (incl. snow on leaves in snowlands); 9 Sand; 10 Snow; 11 Unknown; 12 Floor in lava lands; 13 Unknown; 14 Roofs of normal houses (special buildings use 6); 15 Unknown.
1.0 (CWSDK `BlockProperties.h`): Air=0, Solid=1, Water=2, Wet=3, Grass=4, Ground=5, Building=6, Tree=7, Leaves=8, Snow=10, SnowLeaves=11, Path=13, **Lava=17, Cave=18, Poison=19** (poison = toxic rivers in Deadlands/Dark Woods).
Every block carries its own RGB (per-voxel colors; "more varied terrain coloring" Devlog 2011-11-24). Alpha materials table (cuwo): Iron 1, Wood 2, Obsidian 5, Bone 7, Gold 11, Silver 12, Emerald 13, Sapphire 14, Ruby 15, Diamond 16, Sandstone 17, Saurian 18, Parrot 19, Mammoth 20, Plant 21, Ice 22, Licht 23, Glass 24, Silk 25, Linen 26, Cotton 27, Fire 128, Unholy 129, Ice 130, Wind 131.

### 2.4 Rendering/engine facts
- Alpha: C++ + DirectX (first prototype OpenGL); own voxel editor for sprites; "Plasma" is Picroma's vector-graphics app/engine family. **[FAQ 2011-11-23]**
- Landscape voxel resolution doubled in each dimension in June 2011 (i.e., terrain voxels are half the size of the original prototype; character ≈ 2 m tall ≈ ? blocks — not documented). **[Devlog]**
- Alpha: chunks load around the player; travelling too fast (boat/glider) outruns loading → "blue fog" then "Please wait" screen. **[RPS comments 2013]**
- Alpha: clouds are voxel structures high in the sky with **no collision** (players pass through); no wind/weather system in alpha; grass sways (pure animation). **[fandom Cloud]**
- 2017: engine ported to **64-bit**, new world map, new snow shading, new rivers. **[tweets 2017-04-01]**
- 1.0: uses D3D11 (`plasma::D3D11Engine` in `cube::WorldMap`) **[CWSDK]**; save data in sqlite (`cube::Database`); the 1.0 install is 206 MB.
- Wollay: "I'm not planning to add mining or digging. House building is supported." (building system never shipped). **[FAQ 2011]**

### 2.5 .cub voxel model format **[RE, cuwo cub.py]**
- Header: 3 × uint32 little-endian: `x_size, y_size, z_size`; then `x_size*y_size*z_size` voxels as 3 bytes RGB each, iterated z-major, then y, then x (`for z: for y: for x`). RGB (0,0,0) = empty voxel. No palette, no compression.
- Models live in alpha's `data1.db` sqlite (encrypted/obfuscated; tools: CWME, Vox2Cub, cub-to-obj, cuwo `convertqmo.py` .cub↔.qmo Qubicle). Largest 1.0 sprite: Steel Empire airship, 1,313 KB.

---

## 3. Biomes / landscapes

### 3.1 Generation model
- **Climate model [Devlog 2012-01-18]**: two continuous variables, **temperature** and **humidity**, varying randomly across the world; high temp + high humidity → jungle; other combos → desert, savannah, tundra, snowland. Alpha HUD shows **time, temperature, humidity**, minimap, compass (top-right). Desert example: ≈36 °C, ≈5 % humidity **[fandom Deserts]**. 1.0 guide: "Temperature and Humidity play a factor in the spawning of snow, berries, heartflowers".
- World is "made up of roughly equal sized regions", each region = one landscape/biome type; bordered by dotted lines on the map; "borders are merely conceptual … not present in the game world"; no invisible walls. **[fandom Landscape, World_Map]**
- "Each landscape exhibits a variety of random terrain features, there can be a volcano in the snow and an enchanted forest in the desert." Forests can appear in deserts.
- **[Alpha]** Zone/land **rarity**: "Just like items, zones can have different rarities. Monsters are stronger here and drop better loot." **[Devlog 2012-09-18]**; "rare creatures drop a spirit".
- **[Alpha]** Land **level**: every land has a level; all creatures in that land share it; level rises with distance from world start; boss monsters scale in size/strength from level 1 to full size at level 10. **[Devlog 2012-10]** Wiki: "landscape levels increase the further they are from the initial character starting position". (Picroma 2013 says instead "for each land, the game generates creatures and dungeons evenly in all power ranges (1-100)" — **conflict**: the shipped alpha used land-level bands + per-land mob variety; press noted "impossibly dangerous squirrel next to easy orcs".)
- **[1.0]** Difficulty per region uses **Mob Strength tiers** (White < Green < Blue < Purple < Yellow) rather than levels; each region has its own regular and legendary enemies.

### 3.2 Landscape list
Alpha shipped (picroma.com 2013): **Greenlands, Snowlands, Deserts, Jungles, Lava Lands, Oceans**. Planned in 2013: **Savannahs, Undead Lands, Swamp Lands, Mushroom Lands**.
1.0 shipped list (fandom Landscape nav): Greenlands, Wetlands, Savannahs, Deserts, Oceans, Jungles, Dark Woods, Deadlands, Undead Lands (=renamed Deadlands), Snowlands, Lava Lands, Mountain(s), Mushroom Lands (**unused/never shipped**). Swamp Lands page exists ("abundant rivers for boats") — ? whether distinct from Wetlands in 1.0.

| Landscape | Description / terrain | Flora | Fauna (examples) | Structures / notes | Ver |
|---|---|---|---|---|---|
| Greenlands | lush grass hills, forests, caves, plains, mountains | mushrooms, ginseng, dragon root (1.0 only), bushes, birch/pine/normal forests | Skull Bull, Ogre, Rockling, Bark Beetle, Plain Runner, raccoon, mole, squirrel; Mana Deer & Moose 1.0 only | castles common | A+1.0 |
| Snowlands | cold, snow; high mountains; cold water debuff (1.0: −speed 15 s, boat doesn't protect; Hot Chocolate counters) | Snowberry bush, Iceflower (thaw at campfire → Heartflower), white snow bush variant, snow-on-leaves | Snow Lion, Snow Leopard, Snow Runner, Penguin, Alpaca, Yeti, Mammoth, Polar Gnoll, Snow Gnobold, Snow Golem | castles common; log/wood villages | A+1.0 |
| Deserts | hot/dry (≈36 °C / 5 %), sandy dunes, sand color varies red/orange/yellow, pyramids, lava lakes, occasional oasis & forest; rivers rare (oasis/village well only water) | Cactus (1–3 Prickly Pear), Fire Shrub (=bush variant), Habanero, Chiling | Desert Runner, Camel (desert+savannah only), Desert Onionling, Sand Horror, Fire Beetle, Nomad guards, Djinn | Pyramids (unique), desert ruins, desert-style villages | A+1.0 |
| Jungles | hot, high humidity, dense large trees | cocoa beans, bananas (jungle-only) | Parrot, Makake (1.0), Warthog, Elephant + Baby Elephant, Leaf Runner, Flamingo | Temples, ruins (jungle variant of overworld ruins), orange-roofed villages | A+1.0 |
| Lava Lands | magma-covered, hostile; lava rivers impair travel; extremely dark at night (charred terrain); Lemonade counters lava (1.0) | Fire Shrub, Thorn Tree (no drops; near volcanoes/lava lakes) | demons: Minotaur, Devourer, Hell Demon, Ember Golem, Imp; legendary groups | Citadels (castle equivalent), pyramids can spawn | A+1.0 |
| Oceans | water, islands (generic small + Named large "___ Island"), underwater caves, sea animals; swim speed ≈½ walk speed; 1.0 oceans "theoretically empty" of mobs (spawn bug), alpha had many level-≈5 sea mobs; alpha infinite breath, 1.0 drowning | — | Piranha, Maw Fish, Shark, Seahorse, Mermaid/Merman, Sea Crab, Lantern Fish, Sapphire Fish | temples on large islands, ocean cities on islands, arenas more common | A+1.0 |
| Savannahs | warm/dry, dried grass, few acacia trees, more vegetation than desert | Fire Shrub, acacia | Lion (not tamable), Camel, Nomad, Djinn, Sand Horror | Forts (wooden walls, black spire peaks) | 1.0 (planned 2013) |
| Wetlands | scattered ponds and land chunks | — | Mosquito, Fly, Insect Guard, Slime, Frog, Mermaid | lava lake reported in wetlands | 1.0 |
| Swamp Lands | wetlands with many forests and large rivers; rivers for boats | — | — | — | planned 2013; 1.0 ? |
| Dark Woods | dark forest, purple/blue bioluminescent foliage; toxic rivers (poison); dark even by day | bioluminescent plants | Skull Slater (glows), Wraith (unkillable pursuer), Frightener, Zombie, Flying Eye, Vampire, Unholy Pact NPCs | undead villages | 1.0 |
| Deadlands (alpha concept "Undead Lands") | contaminated, bioluminescent vegetation, toxic rivers, **green sky**; dark houses w/ green lights, undead NPC villages; Green Smoothie counters toxin (1.0) | Drolu Herb (concept only) | Skeleton, Skeleton Knight, Skeleton Horse, Skeleton Dog, Wraith, Skull Slater, Dark Troll | — | 1.0 |
| Mountain(s) | a whole region "deemed a mountain area", resembles Greenlands; named e.g. "Marnis Mountains" | — | Snail, Caterpillar, Earth Caterpillar, Cyclops, Rockling, Biter, Bat | — | 1.0 |
| Mushroom Lands | giant mushrooms, huge insects | — | — | never shipped | concept |

Village architecture themes **[Devlog 2012-10-26 + fandom City galleries]**: European framework houses, medieval stone houses, North-American wood houses, log houses (snow), desert style, jungle style (orange roofs), undead (dark gray, pointed roofs, green lights), lava-land city, ocean city.

### 3.3 Terrain features (any biome)
- **Mountains**: rocky formations in any biome; "some mountains can get really high"; part of Valleys/Canyons. Plateaus with cliff borders (block type 5/6). Added 2012-03.
- **Valley**: low-lying basin surrounded by mountains, smoother floor, lower rims; boss at center (insectoids, mosquitoes, flies). Named landmark/dungeon type.
- **Canyon**: depressed area surrounded by mountains with large **mesas** in the basin and larger mesas on the rim. Named landmark.
- **Caves**: added 2012-01; contain ore deposits (iron, silver, gold, emerald, sapphire, ruby, diamond; 1–3 nuggets each; deposits rarely inside boulders needing bombs), Shimmer Mushrooms (blue light), bats, rocklings; underwater caves in oceans; 1.0 block type `Cave=18`. Deposits respawn at 0:00.
- **Rivers**: added 2011-12 with small **waterfalls**; rivers can tunnel through Giant Rocks ("river cave"); rivers of lava in Lava Lands; toxic rivers in Deadlands/Dark Woods; new rivers 2017. Roads form "underground passages through mountains and bridges over canyons" (2011-07).
- **Lakes**: named landmarks "Lake ___"/"___ Lake", often river-connected; Divine Harp can be "hidden in a lake".
- **Lava lake**: large above-ground pool (area similar to a Mana Pump), dry biomes + lava lands (+ one wetlands sighting); may have a building/"floating island" in center reachable only by glider.
- **Volcano**: named landmark ("Volcano" gallery, 1.0 guides: "big ass volcano", craters) — can appear in snow.
- **Clouds**: voxel clouds, no collision, static (alpha). Omega: moving clouds.
- **Floating/sky islands [1.0]**: small islands in the sky holding 1 item/treasure; reached via **Sky Whistle** played at a **bird (eagle) statue** ("little structure of a bird surrounded by pillars") → flock of blue birds lifts you; or glider+climbing from higher terrain; Treasure Spirit may point at them. (No alpha sky islands — alpha had none documented; the "sky islands" idea appears only in 1.0.)
- **Giant Tree [Alpha]** (mission landmark; tallest structure; boss at top) → replaced in 1.0 by **Mana Tree** (smaller; kill surrounding enemies to summon boss; Steel Empire may place Mana Inductors; Druids of Mana). **Giant Rock [Alpha]**: massive hard-to-climb rock with small top and boss at center; smaller if on a river.
- **Forests**: generic (Birch=lime leaves / Pine / Normal, purely aesthetic, appear on map as color clusters) vs **Dungeon Forests** (named "Duragar Forest", "Vardara Forest"; canopies connect blocking light; many campsites; typed by mobs: Insect, Animal I/II, Undead, Orc, Human, Beetle, Dwarf each with a boss). Planned: "Woods" naming ("Galan Wood"), Enchanted Forests, Giant Forest biome, Giant Tree at center. 1.0 map shows "dark forests, enchanted forests (lighter grove inside dark forest), graveyards".
- **Fields/farms**: fields around villages (2012-05), green dots on the map; Omega: fenced wheat fields, windmills.
- **Roads/streets**: lead to villages/points of interest, streetlights sometimes; kingdoms had **frontier walls with guards** (2012-02) — in alpha release "frontier between two lands" visible (screens 2013-01); 1.0 borders are just map lines.

---

## 4. Flora (world-placed objects)
- Heartflower (red heart flower → Life Potion), Iceflower (snowlands; thaw at campfire → 1–3 heartflowers), Ginseng (greenlands; 1–3 roots → Ginseng Soup at campfire), Cotton Plant (1–3 Cotton Capsule), Mushroom (purple w/ yellow spots; all lands except deserts/underwater), Shimmer Mushroom (blue, glows, rocks & caves; alpha decorative light, 1.0 Elixir of Sanity ingredient), Scrub (2-branch sapling with spider web → 1–3 Cobweb → Silk), Bush (1–3 Wood Log + Plant Fiber; white snow variant), Fire Shrub (= bush in hot biomes), Cactus (1–3 Prickly Pear), Thorn Tree (lava lands, no drops), Snowberry Bush, Dragon Root (1.0), Habanero/Chiling/Onionling/Radishling/Cormling "sprout" plant-creatures, Manaorchid, Kaliptus, apple trees (free healing), lemons. Tweet (pix_xie 2015-10-14): flowers with rarities. Wilderness plants respawn at 0:00 (1.0).
- Trees: procedural (2011-09), tree types by forest (birch/pine/normal; acacia in savannah; large jungle trees; palms?), leaves carry snow in snowlands; 1.0 key items sometimes placed "on top of trees".

---

## 5. Time, day/night, weather, seasons
- Clock: ≈1 game minute per 6 real seconds → full 24 h cycle ≈ **2 h 24 min** real time (fandom Time; cuwo: `MAX_TIME = 24*60*60*1000 ms`, `NORMAL_TIME_SPEED = 10.0`, `SLEEP_TIME_SPEED = 100.0` — note cuwo's 10× vs wiki's 10×: 6 s/min = 10×, consistent). Sleeping ≈ 2 game min/s (wiki) — cuwo 100× ≈ 1.67 game-min/s ✓.
- 1.0 guide: "1 day from 7:00–18:00 is about an hour real time".
- **Midnight reset (0:00)**: monsters respawn, missions regenerate, deposits respawn, shops restock (1.0 shops also restock on inn sleep).
- Inn: talk to innkeeper 18:00–06:00 → time set to 07:00 (alpha free/instant; 1.0 costs 10 coins and also re-rolls daily mission locations).
- Nights very dark (esp. lava lands, dark woods/deadlands dark even by day); lamps (Iron Lamp item alpha / F-key ability 1.0, radius via artifacts); stealth builds faster in darkness.
- Weather: **none in Alpha/1.0** ("not that there is any wind or other weather system") — Omega adds rain, snow, moving clouds, water waves, frozen water/ice physics. No seasons in any version. Snow presence tied to temperature.
- Sky color per biome: green sky in Deadlands.

---

## 6. Lands / regions / progression geography

### 6.1 Alpha
- Land = region of one biome with a **level**; higher level further from world spawn; land name captions appear when crossing; **only one village per land/region**; each land has a "capital city" (2012 devlog) and a portal/teleport stone network; Revival Statues auto-used on death (respawn at nearest, never far).
- Overview map colors: blue oceans, green = your level, red = higher, gray = lower. Landmark name colors: White lower / Blue equal / Red higher level than player.
- Alpha "kingdoms" with frontier walls (2012 devlog) — shipped form ?: screenshots show "the frontier between two lands".

### 6.2 Steam 1.0 — regions, kingdoms/realms, region lock
- **Region** = bordered, named area on the map (white flashing outline for the current one; dotted borders elsewhere); the whole map is visible/colored from the start at any zoom (alpha hid undiscovered areas in blue). Name shown top-right; bottom-left region selector arrows cycle regions visited.
- Region naming: `<Name> Plains / Hills / Mountains / Village / City / Road / Forest …` — seen: "Coria Plains", "Lanno Plains", "Sanion Hills", "Marnis Mountains", "Arris City", "Akar Village", "Caion Road", "Temple of Arno", "Benkal" (pirate faction), "Tririon City" (2012).
- **Region lock**: all armor/weapons/key items found or crafted in a region work only inside it; leaving → gear "goes to starter", non-+ gear greyed out, key items (glider, boat, reins, harp, whistle, bell, spikes) disappear (boat evaporates at the border, riders thrown off at the border). Each region has its own inventory tab (arrows at bottom of bag). **"+" items** ("Plus" suffix) keep full strength in **adjacent regions** (guide: "1–4 more zones"); Steam thread: + gear is "tied to kingdoms instead of regions" (?). Leftovers are region-bound. Gold, crafting mats, artifacts, pets carry over.
- **Artifacts/Relics** (permanent): found in dungeons (castles always hold one; catacombs/vaults/sewer dungeons under some villages; "orange circle" map icon); each = +1 level and a secondary stat (climbing/swimming/diving/riding/gliding/sailing speed, lamp radius); level = artifact count; multiple per region. Named e.g. "Ring of Momuna", "Sirazyna Stone".
- **Realms/Kingdoms/Cults** ("Realm"): lore locations (stone tablets, small crypts, ruins, stone circles/henges) each give lore about the realm that used to occupy the area; NPC factions labeled by realm; reaching **100 % lore for a kingdom reveals all that kingdom's artifact locations on the map, across its several regions** (even unvisited ones). Hover the speech-bubble icon to see lore % for the discovered kingdom.
- Per region (1.0): up to **9 unique key items**; **4 movement items** (Boat, Climbing Spikes, Hang Glider, Reins); **4 Gnome Suppliers** (rescue all 4 → shops sell up to 5-star/legendary); **4 Books of Crafting** (3–4 recipes each; no other recipe source); **up to 5 Wizard/Magic Towers** whose crystals hold a **Magic Barrier**; multiple **Circles of Power**; **Demon Portals**; **Mana Pump** (4 generators + central pump, Mana Mech boss; regional "mana absorption" debuff) / smaller **Mana Inductor** events; Arenas; sewers under some villages. Not every region has every item ("if the generation did not spawn any doors locked by a Bell or Harp, it should not spawn the item").
- Wollay's rationale (now-deleted blog, quoted by players): infinite-loop progression; shared-world co-op where nobody is overpowered; alpha "EXP leveling and procedural gameplay don't mix well long-term". Mods (CubeMegaMod, "Region unlock" mod) remove the lock.

---

## 7. Cities / villages
- Alpha: one village per land; 1.0: many villages per region, spawn near one; villages **not** on the map until discovered (alpha: always shown). Village on map = cluster of building blocks with green farm dots; zoom in to see inn/shop/portal icons (shop signs: chest plate = armor, sword = weapon; anvil = smithy, saw = workshop, crown = class changer 1.0).
- Districts (alpha, 2013-01): **Adventurer District** (4 class trainer buildings: Ranger, Warrior, Rogue, Mage; ranger master has aim targets), **Crafting District** (Smithy: Furnace, Anvil, Customization Bench; Clothier: Spinning Wheel, Loom; Carpenter/Workshop: Saw, Workbench), **Trade District** (market square of stalls/crates/barrels — decorative; Armor Shop, Weapon Shop, Item Shop, Identifier's Shop (sage in a tower identifies Leftovers)). Center place holds all shops (2012-10). Inns (alpha several per village, 1.0 exactly one), Adapter (alpha; crossed-swords icon; re-levels items for platinum coins), Pet Master?, Guild Master/Guild Receptionist (1.0 spec change), Flight Master with giant eagle perch (1.0), Analyst (1.0 identifier), General Store (1.0 name of item shop; sells flasks, bombs, sugar cubes, 1 pet food).
- Decor: lamps/street lights, benches, boxes, barrels, park; NPCs follow daily schedules (sleep at home, park, shops, inn) via A*; NPC count grows the longer you stand in town; alpha small chests in houses (empty).
- Alpha item shop sells Iron Lamps, Hang Gliders, Boats, pet food, Formulas (+1…+100); shops restock daily; sold items gone (alpha) / buy-back tab (1.0).
- Villages can be "petrified" by a Witch (1.0 witch icon mission) or possessed via Demon Portal.

---

## 8. Dungeons, landmarks, structures (named locations)
Dungeon = event/mission location, "built structures or natural terrain", integrated seamlessly into the world; alpha: linear route with one dead end holding main rewards, spike traps (only trap type shipped), breakable vases, small loot chests, loose items on furniture, one boss; 1.0: no vases/small chests/spike traps, multiple bosses of rising tier, chests one-time. Dungeon mobs spawn higher level than the land, in groups of 2–4, Ogre+Collie patrols. Runestone at entrance to port back (2012 concept). 1.0: dungeon map uncovers as you explore (2017 tweet); castle gate locked until nearby enemies defeated ("Old Iron Slides").

| Type | Naming scheme | Where | Notes |
|---|---|---|---|
| Castle | "Castle ___", "Palace ___", "___ Castle" | Greenlands, Snowlands mostly | random size/rooms (2011-11); 1.0 always contains an Artifact; front gate only entrance |
| Fort | "Fort ___" | Savannah | wooden walls, black spire peaks |
| Citadel | "___ Citadel" | Lava Lands | imposing angular spires |
| Ruins | "Ruins of ___", "Ancient Ruins of ___" | any; jungle variant | Dungeon Ruins = damaged castles; Overworld Ruins = scattered white Greco-Roman buildings, no interior |
| Temple | "Temple of ___", "___ Temple" | Jungles, large ocean islands | entrance near top → spiral staircase down |
| Pyramid | "Pyramid of ___", "___ Pyramid" | Deserts (+Lava Lands) | entrance at top; Ancient Guardians (Horus/Anubis variants), Djinn (summon green slimes, fire explosions), Skeletons, black cats, mosquitoes |
| Catacomb | "Catacombs of ___" | below ground via small surface chamber/graveyard | dark, no windows; 1.0 "super dungeon" with artifact |
| Vault (mine/labyrinth) | — | 1.0 | golden door opened by Divine Tune/Harp; room-by-room gauntlet → artifact/treasure; /sit roll exploit patched 25 Sep 2019 |
| Den | "___ Den" | inside cities | little-known, supports missions |
| Lake / Island / Valley / Canyon / Forest / Mountain / Giant Rock / Giant Tree | "Lake ___", "___ Island", … | natural-terrain dungeons | boss at center |
| Overworld dungeon | — | any | freeform disconnected buildings/ruins, boss near center (2013) |
| Camp / Campsite | "Camp" on 1.0 map | every landscape | bedroll (sleep/heal), campfire (cooking, thaw iceflower), chairs, tents, wagons, barrels; boss sometimes present (1.0); NPC/monster rest |
| Arena | — | any (more in oceans); 1.0 only | 5 waves (W/G, W/G, G/B, B/P, P/Y boss), hosted by Bloodaxe Clan orc, resets daily; skull icon |
| Wizard/Magic Tower | — | 1.0 | boss Necromancer/Wizard/Sorcerer; Magic Crystal at top; ≤5 per region; all crystals → Magic Barrier (blueish transparent wall) removed permanently |
| Circle of Power | "Stonehenge"-like ring of spire rocks | 1.0 | restless-warrior boss + lore tablet; Eternal Ember lights brazier → regional power buff; multiple per region |
| Demon Portal | red portal icon | 1.0 | Dark Cultists beam + Imps; possesses NPCs region-wide until destroyed; varying sizes |
| Mana Pump / Inductor | clipboard/battery icon | 1.0 | Steel Empire (airship paradrops); 4 generators + Mana Mech |
| Shrine of Life | small white cube w/ door on map | 1.0 (alpha: Revival Statue) | angel holding purple cube; activate w/ flute (E) → respawn + fast travel (blue dot) |
| Portal (teleport rune stone) | — | Alpha only | magic rune stones; teleport between discovered portals (press R, click name on map) |
| Loot/golden tower, old hut, crypt, graveyard, tomb, molehills, bone piles, hornet nests, sewers | — | 1.0 | small mission/loot sites |
| Wollay's House | — | 1.0 | coordinates 0,0; Wollay & Pixxie NPCs |
| Airship | — | 1.0 | Steel Empire spawn vehicle; cannot land on it |

---

## 9. Missions / quests on the map
- Alpha: NPCs with green speech bubble give locations; **missions regenerate every game day** (sleep/inn triggers new ones) so "a player can stay forever in a land doing daily missions"; crossed-swords icon on map; completing = boss kill → platinum coins + XP; icon disappears when done; mission locations move daily; 8×8 mission grid per region **[RE]**. Quests (procedural text in EN/DE, quest regions highlighted on minimap, 2011-12) were cut before alpha (2013-01 post) — "quests could restrict the player".
- 1.0 mission icons (guide 1871883807): Hammer = Book of Crafting; Gnome head = captured Gnome Supplier; Sword = repeatable daily boss fight; Purple gem = Wizard tower/Magic Barrier; Skull = arena/big boss; Orange circle = artifact; Red portal = demon altar; Cauldron w/ fire = Circle of Power; item/slime picture = find that key item; clipboard/battery = Mana Pump; witch = petrified village; speech bubble = lore (hover: kingdom lore %); flag = crafting book?; no graphic = undiscovered objective; completed missions get check marks. Mission name color = difficulty tier; hidden white until visited on foot. Mission types list: Gnome Supplier, Book of Crafting, Mana Tree, Magic Barrier, Steel Empire soldiers, Mana Pump, Molehills, Bone piles, Hornet Nests, Dungeons, Arena, Boss Fight, Old Hut, Old Man, Unholy Pact, Dark Cultists, Obsidian Knights, Captured NPCs, Demon Portals, Order of Light, Druids of Mana, Circle of Power, Invasions, (alpha: Giant Tree, Giant Rock).
- 1.0 side-mission tiers White/Green/Blue/Purple unlock Uncommon/Rare/Epic/Legendary shop stock via gnomes.

---

## 10. Map UI
- **World Map (M)**: zoomable, rotatable **3D voxel map**; near zoom shows actual terrain in miniature (so structures like castles/ruins are visible directly as voxels + names, no icons), far zoom for landmarks; player heads, quest crossed swords; mini-map (top-right, rotates with camera, tiles revealed as explored) mirrors last zoom; character keeps moving while map open. Alpha: undiscovered = uniform blue shade per region (borders visible as elevation/shade change); explored trail lighter blue; discovered regions shared by all players who visited the server world. 1.0: full terrain colors everywhere at any zoom; zoom scale **1:4 … 1:256** (guide says use 1:8 to scan, 1:4 to verify); coordinates shown; middle-click to place a **star marker** (also shown on minimap); pan RMB, rotate LMB; landmark names hidden until discovered; item icon floats over key-item locations after NPC hint; Flight Master mode shows flight points as "+" (WorldMap has `flightmaster_mode` flag **[CWSDK]**).
- Alpha "overview map" (2013-01): schematic lands + levels toggle. 1.0 removed levels; shows kingdom borders.
- Named Landmarks colored White/Blue/Red vs player power (alpha).

---

## 11. Travel / traversal
- Climbing (Ctrl; stamina; can't pass overhangs; 1.0 Climbing Spikes = free climbing; flip trick), Swimming (≈½ walk speed; alpha no drowning, 1.0 drowning + Diving artifacts), Sailing (boat, G key alpha / E 1.0; rises to surface if deployed underwater; alpha bought in shops + skill points, 1.0 region key item), Hang Gliding (alpha shop item ~lvl 10, 1.0 key item; stamina to level off; crash = dizzy fall; eagle drop-off gives a free temporary glider), Riding (alpha Pet Master 5 → Riding; 1.0 Reins key item; T to mount/whistle), Mage Teleport (60 blocks, 100 mana), Mage float, Ninja sprint/flip.
- Fast travel: Alpha **Portals** only; 1.0 **Shrines of Life** (free, click blue dot) + **Flight Master** eagles in every village (flight points, min 100 coins, cost scales with distance, permanent once bought, can target undiscovered locations and friends anywhere for free; 5–30 s flight).

---

## 12. Cube World Omega (2023–) world facts
- Announced 2023-05-25: new **Vulkan** engine; moving clouds, jiggling leaves, water waves; **weather: rain, snow**; frozen water surfaces with ice physics in cold regions; all creatures/NPCs/players procedurally generated; procedural weapons/armor; new GUI; XP/levels/skill trees return; races: human, elf, dwarf, goblin, lizardman, undead, frogman, orc.
- **2023-07-30 "New World Generation"**: for each **region** a **coarse map** is generated first in which "all streets, buildings, rivers, bridges, trees, caves etc. are placed and connected in a logical way"; detailed voxel terrain is then generated from it as players explore. Video shows: cave entrances/exits, rural areas with fields, windmills (turning wheels), farms, paths connecting structures to main roads, fenced wheat fields, river crossing with bridge, village with watchtowers, walls, iron fences, stone roads, street lights; ambient: butterflies near flowers, water lilies moving with waves, moths around street lights, chimney smoke. Planned: region map used for NPC navigation (villagers travel to distant places) and quest design.
- Later posts (2023-10-14 hornets/hedgehogs) have no world info; no wollay.com posts found for 2024–2025 (archive pages returned the same 2023 list). Status per Wikipedia: still in development as of 2025. Gap: no Omega chunk/biome/terrain numbers published.

---

## 13. Modding / technical odds and ends
- Alpha mod loader: coremaze "Cube-World-Mod-Launcher" (server mods: chat overallocation fix, ghost damage fix, MOTD, disable player limit). 1.0: ChrisMiuchiz **CubeModLoader.fip** (+ `Mods/*.dll` next to `cubeworld.exe`) and **CWSDK**; mods on cwmods.com / Nexus. BetterBiomes (Nexus mod #3): re-groups regions into **continents and small islands** instead of "infinite sprawling land mazes" (implies vanilla 1.0 places ocean regions as ordinary region-cells among land regions, forming land mazes). CubeMegaMod / region-unlock mods: remove region lock, scale enemies/gear.
- cuwo (alpha server) runs the game's own terrain generator (`terraingen/tgen2`: loads the client's generator code from the exe via pe-parse, x86 only) → the alpha generator has never been rewritten in the open; only its data layout is known. cuwo `config/base.py`: `seed = 26879`, `time_modifier = 1.0`, mission visibility distance default = one region.
- Alpha name generators: static names, entity names, item names, **location names**, **quarter names** (city districts), skill/ability names are red-black-tree maps read from the exe (`get_location_names`, `get_quarter_names`).
- Alpha data files: `data1.db`, `data2.db` (sqlite, obfuscated) hold models/strings; saves per character; server world on host. 1.0: `world_db_database` sqlite per world; Steam cloud?.

---

## 14. Uncertain / conflicting points
- Alpha zone = 256 blocks (cuwo) vs 1.0 zone = 64 blocks (CWSDK) — both **[RE]** from different versions; treat as version change, not conflict.
- "Region" in 1.0 gameplay (named biome area) ≠ alpha internal "region" (64×64 zones = 16,384 blocks). Whether 1.0 gameplay regions are exactly one internal region-cell is unverified (BetterBiomes' "grouping regions" suggests region-cell = biome).
- Alpha difficulty: land levels by distance (devlog/wiki) vs Picroma 2013 "creatures of all power ranges in every land" — press reports mixed-level mobs per land, so both partially true.
- "+ gear works in adjacent regions" (wiki) vs "tied to kingdoms" (Steam thread) — unresolved.
- Mushroom Lands / Swamp Lands: wiki lists Swamp Lands as a landscape but only Wetlands has any content; Mushroom Lands confirmed never shipped.
- Sky islands: no evidence in alpha; 1.0 only. Cube World "ships": only Steel Empire airship and "Benkal Pirate" NPCs — no sailable/enterable ship dungeon documented.
- Overhangs: block columns are vertical runs from `base_z` (1.0 Field) — implies heightmap-plus-run storage, but caves (type 18) and overhang cliffs exist; exact representation of multiple air gaps per column not documented (alpha `Field.a`/`size` suggests single run per column with air blocks inside the run).
- Water level: no global sea-level number found; oceans are region-type, lakes/rivers carved per region (Omega: rivers in coarse map).
