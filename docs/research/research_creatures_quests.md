# Cube World — Creatures, NPCs, Enemies, Bosses, Quests, Factions (research dump)

Scope: Alpha 0.1.x (July 2013), Steam 1.0 / "0.9.x beta → 1.0" (Sept 23–30 2019, patches to 0.9.3-0 / 1.0.0-1), Cube World Omega (2023–2025, unreleased).
Version tags used below: **[A]** alpha only, **[S]** Steam 1.0 only, **[A+S]** both, **[Ω]** Omega, **[pre-2019 concept]** shown in tweets/videos 2014-2017 but shipped differently or not at all.

Primary sources (abbreviated in-line):
- **W:Page** = https://cubeworld.fandom.com/wiki/Page (fetched as wikitext via api.php; ~500 pages read)
- **cuwo** = alpha protocol reimplementation, entity/name tables: https://github.com/matpow2/cuwo/blob/master/cuwo/strings.py and constants.py
- **Darkmega** = Steam guide "How to not have a bad time: Darkmega's Ultimate Cubeworld Guide" https://steamcommunity.com/sharedfiles/filedetails/?id=1871398574
- **FaceTheCube** = Steam guide "So you want to face The Cube" https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729
- **HowTo** = Steam guide "Cube World: How to Actually Do Things and Not Die" https://steamcommunity.com/sharedfiles/filedetails/?id=1871883807
- **WB YYYY-MM** = Wollay's original dev blog (picroma.com/blog, 2011–2013, archived copy read locally)
- **wollay.com** = Omega dev blog https://wollay.com/ (posts 2023)
- **Picroma2013** = https://picroma.com/cubeworld (2013 feature page, archived)
- **CWS-tweets** = https://cubeworld-servers.com/blog/17/new-tweets-from-wollay/ (Oct 2015 faction tweets); Siliconera https://www.siliconera.com/cube-world-is-still-alive-gets-demons-ghosts-and-necromancers/ ; Kotaku https://kotaku.com/over-a-year-later-cube-world-finally-has-a-few-new-thi-1736067016
- **Gamepressure** = https://www.gamepressure.com/cubeworld/enemy-types/z15264
- **MageForHire** = https://www.mageforhire.co.uk/articles/cube-world/

---

## 1. Core creature / enemy system

### 1.1 Terminology
- "Mobs"/"Monsters" = every moving entity: animals, creatures, bosses, NPCs (W:Mobs).
- Wiki splits: **Animals** (real-world species: deer, bunny, sheep…), **Creatures** (fantasy: Iceling, Zombie, Flying Eye…), **Pets** (any tameable mob), **Monstrosity** (untameable aggressive), **Bosses**, **NPCs** (humanoid talkers) (W:Animals, W:Monstrosity).
- **Families**: groups sharing a base form — Beetles (4), Runners (4), Slimes (4), Alpacas (2), Dogs (Collie, Scottish Terrier, Shepherd Dog, Terrier) (W:Families, W:Beetle, W:Runner, W:Slime, W:Alpacas, W:Dogs).

### 1.2 Hostility states [A+S]
- Three states (Gamepressure, FaceTheCube): **Hostile** (attacks on sight; monsters or NPCs; only outside cities; red HP bar), **Neutral** (indifferent until attacked; green HP bar), **Friendly** (cannot be attacked, won't attack; blue HP bar; typical in/around cities). Friendly NPCs "wave when you get within chatting distance" and have light-blue names (Darkmega).
- Protocol (cuwo constants.py): `hostile_type` byte: 0 = friendly player, 1 = hostile, 2 = friendly (also 4, 5), 3 = named friendly (NPC), 6 = target; `HOSTILE_FLAG = 1<<5`.
- Same species can spawn either way: Wizards, Witches, Jesters, Gnolls ("depending on their tribe"), Insektoids, Mantis, Spectrino, Vampires, Nomads, Dark Jesters [S], Icelings [S, rarely passive], Snow Gnobolds, Polar Gnolls, Spike Creatures (W pages of each).
- Villagers/animals inside cities are peaceful and cannot be attacked, EXCEPT possessed villagers [S] (W:Mobs).
- Alpha AI (WB 2012-12): "Dungeon enemies are standing together in groups. If one of them sees me, the whole group will attack me." Patrol NPCs (Ogre) walk corner to corner and are stronger than normal enemies. Groups can be "pulled around corners". Some forest guards stand at a campfire, others walk a path "ignoring invisible players" (W:Forest).
- Aggro (WB 2012-01): MMO-style aggro table — attacking increases attacker's aggro; more damage = more aggro; monster attacks highest-aggro target. Tank pets (turtle) generate more aggro, less damage. Darkmega on 1.0: in practice enemies "just come for the first thing that hits them unless someone redirects them with a knockdown and they lose track"; Guardian's Heroic Shout taunts everything within natural aggro range (5 m), taunted enemies tinted red; stealth at full reduces aggro rate to zero.
- Pathfinding (WB 2012-12): A* with climbing and arbitrary bounding boxes; "Enemies use it to follow the player even to the most unreachable locations"; villagers path around street lights to places in the city.
- Enemy potions: NPCs and humanoid monsters (Ogres, Mermaids, Insect Guards) drink potions at low HP (W:Life Potion; WB 2013-01 "Even enemies can drink").
- Enemy classes: any humanoid can be any of the 4 classes (Warrior/Ranger/Mage/Rogue) incl. specialization skills; enemy mages cast beams/rays (Wizards/Witches "devastating ray attack that can quickly kill players"), bracelets fireballs, enemy Rangers, enemy Rogue/Ninja (W:Wizard, W:Witch, W:Hell Demon, W:Insektoid). Patch 0.9.3-0: "Wand damage of enemy mages decreased by 25%" (W:0.9.3-0). Enemy mission NPCs can use doppelganger clones (bug: clone drops boss loot each death) (W:Bugs).
- Stun rules: stunned entity shows stars, immune to re-stun while stars visible (players and enemies alike) (WB 2012-10; HowTo "you can't stun an enemy with stars over their head").
- Wraith: cannot be killed, pursues longer than other monsters, pets refuse to attack it (W:Wraith).
- Night: some mobs/NPCs bring out lanterns at night (Darkmega; bug: they don't put them away until day reset W:Bugs).
- Special moves on bosses: "random special abilities" — WB 2013-01 boss summoned a clone of a player; Darkmega: warrior ground stomps, fire-mage missiles, summoning zombies or weaker copies of themselves, slowing lava traps, channelled explosions; Cyclops charge + cyclone attack; Troll earthquake attack (WB 2013-01).
- Terrain damage: all boss-type monsters can break terrain (W:Troll, W:Yeti, W:Sea Crab, W:Dark Troll).

### 1.3 Strength / scaling
**Alpha [A]** (W:Levels, W:Power Level, WB 2012-10, Picroma2013):
- Each land has a level; all creatures in that land share it; land level rises with distance from start. Player levels via XP (2 skill points/level). Power Level formula `Power = (101*level - 81)/(level + 19)`, max usable +100.
- Boss monsters (trolls, cyclopes) are smaller and weaker at level 1, reach full size/strength at level 10 (WB 2012-10).
- Picroma2013: "For each land, the game generates creatures and dungeons evenly in all power ranges (1-100)".
- "Rare zones: Just like items, zones can have different rarities. Monsters are stronger here and drop better loot." (WB 2012-09).
- Enemies also tagged +1…+4 multiplier ("+4 is the highest") (W:Mobs).
- Map landmark colour vs player: White lower, Blue equal, Red higher (W:World Map). Name-text tiers listed by Gamepressure: White (weaker), Light Blue (equal), Orange (slightly stronger), Red (much stronger). W:Color codes/Tiers adds Purple = boss mobs (often the ones that drop the NPC-hinted item); white mobs "150 to 250 HP".

**Steam [S]** (W:Mob Strength, W:Rarity, W:Armor):
- No XP/levels. Mob strength = rarity colour tied to gear tiers, 1–5 stars: **White** (farm animals; never aggressive), **Green** (weak: brown Alpaca, Plain Runner), **Blue** (Rockling, Insect Guard), **Purple** (dungeon mobs; Lion, Chiling have purple base), **Yellow/Legendary** (only a few base-yellow, e.g. some Collies; all Minotaurs are legendary). Yellow-text enemies wear legendary gear.
- Dungeon monsters spawn higher than region mobs and in groups of 2–4 (W:Dungeon). Enemy size grows with tier; patch 0.9.3-0 limited dungeon enemy size so they don't spawn outside walls.
- Region lock: each region has own regular + legendary enemies so the player re-gears per region (W:Landscape).
- Drops: loot random by enemy strength; usually the tier of the enemy, can be ±1 tier (W:Rarity); world bosses drop one tier higher than themselves (Darkmega). Enemy-specific items only: Parrot Feather, Onion Slice (Onionling), Radish Slice (Radishling), Popcorn (Crawler), coins, Spirit Cubes [A] (W:Mobs, W:Crawler). Sometimes NPCs drop the weapon they wield (W:Formulas). Coins: monsters 1–3, bosses "20 gold" [S] (W:Coin).
- Midnight (0:00) reset respawns monsters (not quest/dungeon mobs already killed that day per Darkmega) and regenerates missions; Inn reset (10 coins, 18:00–6:00) jumps to 7:00 and resets the same (W:Time, W:Inn, Darkmega).

### 1.4 Boss-ification and Possession
- "There is a low chance for any monster to become a boss type" — larger, named, coloured-name version of a regular mob, sometimes with 1–2 special moves; examples: boss Penguin named "Aslan", boss Snow Runner, boss White Cat, boss Alpaca (Lizardman-ridden), boss Biter, boss Zombie, boss Werewolf, boss Ember Golem "enormous", Insektoid Ranger/Rogue bosses, Lizard boss (W:Mobs, W:Bosses, W:Biter, W:Zombie, W:Werewolf, W:Ember Golem, W:Insektoid; Darkmega "procedurally generated world bosses… from a white tier lowly king of seagulls to a gold tier alpha of the alpha dogs").
- Named boss pets: a tamed boss keeps its skills but becomes normal size; on reload it reverts to a normal pet (W:Bosses, W:Pets).
- Alpha: rare/boss creatures drop a Spirit Cube every kill, always the same one (e.g. "Fire Spirit +24"), equipment around the same +level (W:Bosses, WB 2013-01 "A rare ogre. Rare creatures drop a spirit").
- **Possessed [S]**: a Demon Portal in the region randomly possesses friendly and enemy NPCs (incl. villagers, Flight Masters, vendors); "Possessed" appears in the name, they turn big/red, tougher, respawn possessed until the portal is destroyed; destroying the portal cures all. Possessed villagers attack the player and can be attacked by player/other NPCs (W:Demon Portal, W:Mobs, Darkmega).
- HP reset: alpha — player death resets enemy HP; Steam — HP not reset if a revival point is close enough (W:Bosses).

---

## 2. Bestiary

Columns: hostility / biome / tame food (rideable?) / notes. "Untameable" = wiki states no food. Type column from wiki infoboxes: Melee/Ranged/Mage/"any class".

### 2.1 Animals (mostly tameable) [A+S unless noted]
| Creature | Hostility | Biome | Tame food → rideable | Notes |
|---|---|---|---|---|
| Alpaca (light) | passive | Greenlands, Snowlands, plains (all but Lava Lands; most abundant Snowlands) | Vanilla Cupcake (ID 22) → yes | melee |
| Alpaca (dark/Brown) | passive | same | Chocolate Cupcake (23) → yes | green-tier example mob [S] |
| Alpha Dog [S] | passive (dungeon variants attack) | Greenlands, Savannahs, forests, dungeons | untameable | surrounded by Savage Dogs; 2-star/3-star variants seen |
| Baby Elephant [S] | passive | Jungles | Peanut (200) → yes | groups with adult Elephants |
| Baby Mammoth | passive | Snowlands only | Chocolate Ice Cream (201) → yes | does not group with adults |
| Beaver | passive | Greenlands | Buckhorn (156) → wiki page says no, food table says yes (conflict) | |
| Bunny | passive | Greenlands, plains | Carrot (35) → yes | |
| Camel | aggressive | Deserts (and Savannahs) | Date Cookie (99) → yes | |
| Cat (black) | passive | Cities, Greenlands | Candy (30) → yes; only BLACK cat tameable | Brown/White cats exist (cuwo IDs 30/31/32); used as "guardians" by Djinn/Skeletons in Pyramids |
| Chicken | passive | Greenlands, most areas | Cereal Bar (56) → table says yes, page says no (conflict) | very common |
| Collie | passive | Cities, Greenlands, castles/dungeons | Bubble Gum (19) → yes | first pet implemented (Wollay's dog "Joschi", WB 2012-01); patrol-ally Collies untameable; some Collies base-legendary [S]; Ogres patrol dungeons with Collies |
| Cow | passive | Greenlands | none (Liquid Drop planned, cut) | |
| Crow | passive | Greenlands, forests | Licorice Candy (55) → page yes / table no (conflict) | |
| Crocodile | ? | Jungles, Oceans, sometimes Deserts | Apple Ring (75) → yes | |
| Duckbill | ? | rivers | Sugar Candy (74) → yes | beaver/duck mix |
| Elephant (adult) [S] | passive | Jungles | untameable | |
| Flamingo | rare | Jungles, islands | Raspberry Juice (210) → yes | |
| Horse | ? groups 2–5 | Greenlands, Jungles, Snowlands | Candied Apple (98) → yes | white horses used by Order of Light paladins |
| Koala | ? | Jungle, Ocean | Eucalyptus Candy (89) (replaced unused "Kaliptus Leaf") → table yes / page no (conflict) | |
| Lion | hostile | Jungle, Savannahs | untameable (players claim tameable; no food known) | male/female variants; purple base tier |
| Makake [S] | passive | Jungle | untameable | monkey-like |
| Mammoth (adult) | aggressive boss | Snowlands; arena/missions anywhere [S] | untameable | meant to drop Mammoth Hides (0% drop) |
| Mana Deer [S] | passive/neutral | Greenlands, woodlands, plains | untameable | shares forests with Moose |
| Mole | passive | Greenlands, forests | Chocolate Donut (87) → no | [S] respawn endlessly from molehills until molehill destroyed (mission type) |
| Monkey | ? | Jungles, near Oceans | Banana Split (50) → table yes / page no (conflict) | |
| Moose [S] | passive | Forest | untameable | |
| Owl | passive, flying | Greenlands, forests | Lollipop (92) → no | |
| Panther [S] | hostile | Jungle | untameable | chases player |
| Parrot | ? flying | Jungles, islands, (Deserts, Lava Lands per infobox) | Ginger Tartlet (58) → table yes / page no (conflict) | red & green (alpha also "blue"); pet parrots drop Parrot Feathers when defeated; feather → Parrot Armor (unobtainable) |
| Peacock | non-hostile | Greenlands, forests, hills, islands, Jungles | Chocolate Cookie (67) → yes | |
| Penguin | ? | Snowlands | Soft Ice (93) → table yes / page no (conflict) | boss example "Aslan" |
| Pig | passive | Greenlands, cities, forests | Pumpkin Mash (33) → yes | |
| Porcupine | ? | Deserts, Jungles, mountains | Blackberry Marmalade (36) → yes | |
| Raccoon | ? | all but Lava Lands/Deserts; forest dungeons | Chocolate Cake (91) → no | |
| Savage Dog [S] | passive (dungeon variants attack) | woodlands, Greenlands | untameable | small version of Alpha Dog; packs of ~4 |
| Scottish Terrier | passive | Cities, Greenlands | Croissant (27) → yes | |
| Seagull | ? flying | Oceans, islands, Jungles | Salted Caramel (57) → table yes / page no (conflict) | |
| Sheep | passive | Cities, forests, Greenlands | Cotton Candy (34) → yes | |
| Shepherd Dog | passive | Greenlands, near villages | untameable | rarer than Collie/Terrier |
| Snow Leopard [S?] | hostile | Snowlands only | untameable | |
| Snow Lion | aggressive | Snowlands only | untameable | male/female |
| Squirrel | aggressive | forests, Greenlands | Strawberry Cake (90) → table yes / page no (conflict) | |
| Terrier | passive | Cities, Greenlands, forests, plains | Waffle (26) → yes | |
| Turtle | passive | rivers, Greenlands, islands, ponds | Cinnamon Roll (25) → yes | TANK pet: high HP, Spin Attack generates aggro; unique turtle-shell pet cage |
| Warthog [S] | ? | Jungles (uncommon) | none (Banana Mash 170 planned, cut) | |
| Wolf [A only] | aggressive | Greenlands, forests, Snowlands | untameable (Apple Pie planned, cut) | not in Steam version |
| Runners (family) | aggressive | groups 3–5, all but Lava Lands | see below | large two-legged neckless birds; high attack tempo & run speed |
| — Plain Runner | aggressive | Greenlands (green tier) | (Rice) Milk Chocolate Bar (63) → yes | |
| — Leaf Runner | aggressive | Jungles | Mint Chocolate Bar (64) → yes | |
| — Desert Runner | aggressive | Deserts | Caramel Chocolate Bar (66) → yes | |
| — Snow Runner | aggressive | Snowlands | White Chocolate Bar (65) → yes | |

### 2.2 Insects / small creatures
| Creature | Hostility | Biome | Tame food → rideable | Notes |
|---|---|---|---|---|
| Bark Beetle | aggressive | most biomes/Greenlands | Bread (102) → yes | Beetles: groups 3–5, not in Snowlands |
| Lemon Beetle | aggressive | Greenlands, rocks, mountains, forests | Lemon Tart (105) → yes | |
| Snout Beetle | aggressive RANGED | Greenlands, hills | Lolly (104) → yes | only monster that dodges and uses Intuition (Scout passive); charged shot; ranged pet |
| Fire Beetle | aggressive | Lava Lands, Deserts only | Curry (103) → yes | |
| Bumblebee | passive | Greenlands, forests | Biscuit Roll (151) → yes | |
| Hornet | aggressive flying | Greenlands/grasslands | Popcorn (53) → table yes / page no | [S] spawn from Hornet Nests (mission type) |
| Fly | ? | forests, Greenlands, riversides | Fruit Basket (60) → page yes / table no | |
| Midge | aggressive | Deserts, Wetlands, riversides | Melon Ice Cream (61) → no | |
| Mosquito | aggressive, groups 4–5 | river edges, lava lakes, all | Bloodorange Juice (62) → yes | follow Djinn/Skeletons in Pyramids |
| Caterpillar | aggressive small | Greenlands, Jungles, Mountains | Mixed Salad (293) → yes | added beta 2019 |
| Earth Caterpillar | aggressive small | Lava Lands, Deserts, Savannahs, Mountains | Radicchio Salad (294) → yes | |
| Snail [S] | hostile | mountains/unknown | Cabbage Rolls (295) → yes | added 2019 beta |
| Insect Guard | aggressive flying humanoid insect | plains, Greenlands, Wetlands, Deserts | untameable | blue tier example; drinks potions |
| Insektoid | passive or aggressive, melee/ranged, any class | anywhere | untameable | Insect-forest boss; Insektoid Ranger/Rogue bosses |
| Mantis [S] | passive or aggressive, any class | any | untameable | |
| Biter | aggressive | Greenlands, forests, plains, Deserts | Pancake (88) → no | boss variant exists |
| Devourer | aggressive | Lava Lands, Deserts | untameable (Wasabi Sauce planned, cut) | |
| Crawler | hostile | Dungeons, Lava Lands, Deserts | untameable | drops Popcorn |

### 2.3 Aquatic
| Creature | Hostility | Biome | Tame | Notes |
|---|---|---|---|---|
| Crab | ? attacks with claws | near/in lakes, all | Strawberry Cocktail (106) → table yes / page no | |
| Sea Crab | aggressive BOSS | beaches, Oceans, missions | no | armoured; attacks like Crab; breaks terrain |
| Spitter | aggressive | beaches, lakes, Oceans, rivers | Water Ice (86) → no | RANGED + HEALER pet: water magic; tamed spitter's water trails heal its owner (only owner) |
| Frog | passive, any class, no armour | near water, Greenlands, Wetlands, Oceans, islands | no | humanoid frog identical to Frogman race |
| Mermaid / Merman | hostile, any class | beaches, Oceans, Wetlands | no | drink potions |
| Shark | aggressive | Oceans, beaches | no | |
| Piranha [A only] | aggressive, groups | Oceans | no | not in Steam |
| Maw Fish | aggressive | Oceans | no | |
| Lantern Fish | aggressive | Oceans | no | antenna glows at night |
| Blowfish | untameable large fish | Oceans | no | |
| Lemon Fish / Sapphire Fish | untameable "cute little" fish | Oceans | no | |
| Seahorse | passive | Oceans | no | |
| Saurian | BOSS (several giant variants, different shapes/abilities) | all; alpha underwater boss missions; Steam arenas only | no | |
Note: Steam oceans are "theorized to be almost empty because of a spawning problem" (W:Oceans, W:Bugs). Alpha had a consistent ~level-5 ocean enemy set.

### 2.4 Monsters / fantasy creatures (untameable unless noted)
| Creature | Hostility | Biome | Notes |
|---|---|---|---|
| Onionling | aggressive melee | Greenlands, Jungles, woodlands, plains | drops Onion Slices (Mushroom Spit ingredient); cuwo id 71 "Onionling", 69 "PlantCreature", 70 "RadishCreature" |
| Desert Onionling | aggressive | Deserts, Savannahs | no Onion Slice drop |
| Radishling (+ Radishling Sprout) | aggressive | Greenlands, hills, forests | drops Radish Slice; Sprout tameable with Mineral Water (192), not rideable |
| Cormling (+ Cormling Sprout) | aggressive | all / Greenlands | Sprout tameable with Spring Water (193) |
| Chiling | hostile | Greenlands, Savannahs, near volcanoes/lava lakes | purple base tier; unused smaller "Chiling Sprout" |
| Habanero | hostile, groups 3–6 | Deserts, Savannahs | stronger Chiling; spawns with Chilings & Sand Horrors |
| Bloomling [S] | aggressive, flies, groups 2–5 | Greenlands, Wetlands, plains, forests | "strong and rapid melee attacks" |
| Rockling | aggressive | mountains, caves, all | throws boulders (iron-deposit lookalike); blue tier |
| Iceling [S] | aggressive (rarely passive NPC) | Snowlands only | |
| Sand Horror | aggressive, groups 3–5 | Deserts, Savannahs | |
| Slimes (Green/Blue/Pink/Yellow) | aggressive | mountains; any colour any biome; Wetlands, Deadlands; [S] Slime Wells; [A] with Djinn in deserts | Jelly of same colour (37/40/38/39) → all rideable; Green listed Deserts, Yellow Deserts, Blue/Pink "All" |
| Flying Eye | aggressive | Dark Woods, Deadlands, Lava Lands, dungeons | |
| Frightener | hostile ghost, no hands/feet | dungeons, graveyards, Deadlands, Dark Woods, named forests | black eyes/red pupils glow in dark |
| Wraith | aggressive, UNKILLABLE | Dark Woods, Deadlands | follows longer than others; pets ignore it; swiping sounds |
| Zombie | aggressive | graveyards, dungeons, Deadlands, Dark Woods | [A] bite ability (removed in Steam); boss variant |
| Skeleton | hostile, abundant | Deadlands, Dark Woods, dungeons, graveyards, ruins, Pyramids | often captors of Gnome Suppliers; [S] respawn from bone piles until destroyed |
| Skeleton Knight | aggressive | Deadlands, Dark Woods | rides Skull Slater; dismounts when mount dies |
| Skeleton Horse [S] | aggressive | Deadlands, Dark Woods | |
| Skeleton Dog [S] | aggressive | dungeons, Dark Woods, Deadlands | |
| Skull Slater [S] | aggressive, bioluminescent | Deadlands, Dark Woods | mount for Skeleton Knights; unused unmasked variant |
| Skull Bull | aggressive, hard for new players | Greenlands, Snowlands, Dark Woods, Deadlands, Deserts, forests | |
| Monstrosity | aggressive | Deadlands, Dark Woods, graveyards, ruins | often captor in Gnome Supplier missions; pre-2019 concept "animated by Necromancers" |
| Vampire | aggressive or passive NPC (friendly ones don't help in combat) | dungeons, Deadlands, Dark Woods, Lava Lands, Vaults | flies into air, uses class skills (seen with longswords, daggers) |
| Werewolf | aggressive | dungeons, Dark Woods, Deadlands | member of Unholy Pact missions; boss variant |
| Ogre | aggressive, powerful | Greenlands, woodlands, mountains, dungeons (all) | dungeon patrol guard with Collies; drinks potions; "stronger than normal enemies" (WB 2012-12) |
| Troll | BOSS | any, missions, arena [S] | big mace, earthquake attack; gets stuck in trees/caves; first boss ever added (WB 2011-06) |
| Dark Troll | BOSS | Greenlands, plains, missions | faster than Troll, 2 weapons, terrain damage; pre-2019 concept for Undead Lands |
| Yeti | BOSS | Snowlands, arena, missions | Snowlands counterpart of Troll |
| Cyclops | BOSS | Greenlands, plains, mountains, missions | punch, charge attack, cyclone attack (WB 2013-01) |
| Golem / Ember Golem / Snow Golem | BOSS (elemental giants) | all / Lava Lands / Snowlands; [S] anywhere as missions | throw boulders; can be further boss-ified ("enormous") |
| Rune Giant [S] | BOSS | missions, arena | not in alpha (but id 118 exists in alpha tables) |
| Hell Demon / Demon | large aggressive / BOSS, any class, melee+ranged | Lava Lands; [S] missions anywhere | Cyclops/Troll-like; giant hands hide fist weapons |
| Demon Marauder | aggressive, melee + fire magic | dungeons, Deadlands, Dark Woods, Lava Lands | |
| Imp | aggressive lesser demon | Lava Lands; Demon Portals | spawned endlessly by portals; Charred Steak planned tame food (cut) |
| Minotaur | aggressive humanoid, dual-wield always | Lava Lands, dungeons | [S] always legendary tier |
| Djinn | hostile humanoid mage, always bracelets | Deserts, dungeons, Pyramids | summons Green Slimes, Fire Explosions; walks with a Black Cat, followed by Mosquitos |
| Ancient Guardian (Anubis / Horus variants; cuwo ids 77/78) | aggressive humanoid, any class | Pyramids only | Pyramid equivalent of Undead in Catacombs |
| Lich | undead BOSS | dungeons, missions | shoots fireballs ([S] fireball skill broken) |
| Treant | large passive | forests, plains, Dark Woods, Deadlands | allied with Druids of Mana |
| Mana Mech [S] | mission BOSS | Mana Pump centre; arena | piloted by Steel Empire soldier who emerges on defeat; arena version has no mana absorption |
| Spike Creature | passive or aggressive semi-humanoid | all | Jesters resemble them |
| Jester / Dark Jester | passive or aggressive, any class | most landscapes, dungeons / Deadlands, Dark Woods, dungeons | same uniform regardless of class; rare NPC in alpha; Dark Jesters passive NPCs exist [S] |
| Spectrino [S] | passive colourful entity, rarely aggressive, any class | any | arena challengers |
| Seeker | aggressive humanoid, fire magic only | dungeons | "like Necromancers" |
| Witch | female humanoid Mage, groups 2–4, hostile or friendly | all, Greenlands | ray/laser attack (usable with staff, unlike players); [S] Witch boss in "Old Hut" petrifies a whole village (mission) |
| Wizard | Mage NPC, groups up to 4, neutral or aggressive | all | purple hooded cloak, blue eyes, elf ears, one design; staff/wand; laser; Wizard-tower boss |
| Necromancer / Sorcerer [S] | Wizard-tower bosses; Necromancers "dark wizard from the Unholy Pact" | Magic Towers, missions | raise/empower undead (Darkmega) |
| Dark Cultist (Cult of Doom) | aggressive humanoid, any class | Deadlands, Dark Woods, Demon Portals, missions | channel beam into Demon Portal, heal it |
| Gnoll / Polar Gnoll | hyena-headed humanoid; aggressive by tribe / Snowlands passive-or-aggressive | ? / Snowlands | |
| Gnobold / Snow Gnobold | humanoid, groups 2–4 any class / Snowlands | most landscapes | |
| Nomad (male/female) | human NPC, aggressive or passive | Deserts, Savannahs, islands, Lava Lands | guard ruins/settlements |
| Bandit [A] | (cuwo id 44) | ? | no wiki page; alpha hostile humanoid |
| Goblin (enemy) | (also playable race) Greenlands, Jungles, forests | forest-dungeon boss type "Animal (II)" | |
| Lizardman (enemy) | forest-dungeon boss type "Animal (I)"; Lizard boss seen | | |
| Orc (enemy) | orc dungeons/castles ("female Orcs" WB 2012-09); Orc forest with Collies, Terriers, Pigs, Ogres | | |
| Bloodaxe Clan [S] | uncommon race of larger purple orcs, any class | Arena hosts (always), Lava Lands | |
| Steel Empire soldiers [S] | any tier, parachute from airship | roaming groups, Mana Pump, Mana Tree | |
| Obsidian Knights [S] | violent human faction (MageForHire) | missions | no wiki page |
| Old Man [A concept] | unused quest-giver/vendor NPC (cuwo id 18) | — | quests by rarity colour; never shipped |
| Dragon | unused BOSS in data (cuwo id 101) | — | won't work when spawned; "may be confined to special Landscapes" |
| Scarecrow, Dummy, Aim (cuwo 140–142) | static targets | — | |
| Bomb (cuwo 144) | "pet"-like entity with 100 HP that ticks down and explodes | — | |

Plants/deposits as entities (cuwo ids 120–139): Bush, SnowBush, SnowBerryBush, CottonPlant, Scrub, CobwebScrub, FireScrub, Ginseng, Cactus, ThornTree, Gold/Iron/Silver/Sandstone/Emerald/Sapphire/Ruby/Diamond/IceCrystal deposits — harvested by attacking; caves hold Bats and Rocklings (W:Cave).

Biome enemy rosters (W:Landscape pages): Greenlands — Skull Bulls, Ogres, Rocklings, Bark Beetles, Plain Runner, Raccoon, Mole, Squirrel; Deserts — Desert Runner, Camel, Desert Onionling, Chiling, Habanero, Sand Horror, Fire Beetle, Nomad, Djinn, Pyramids; Snowlands — Alpacas, Snow Lion, Snow Leopard, Snow Runner, Penguin, Baby Mammoth, Yeti, Polar Gnoll, Snow Gnobold, Iceling; Jungles — Parrot, Makake, Warthog, Elephants, Leaf Runner, Flamingo, Panther, Lion, Temples; Lava Lands — Minotaur, Devourer, Hell Demon, Ember Golem, Imp, Fire Beetle, "over-run with groups of legendary tier enemies", Citadels; Deadlands/Dark Woods — Skeleton family, Skull Slater, Wraith, Frightener, Zombie, Flying Eye, Vampire, Undead villagers, Unholy Pact, toxic rivers; Wetlands — Mosquito, Fly, Insect Guard, Slime, Mermaid, Frog; Oceans — fish list above; Mountains (landscape) — Snail, Caterpillars, Cyclops, Rockling, Biter, Bat; Savannahs — Sand Horror, Camel, Nomad, Djinn, Lion.

### 2.5 Alpha entity type table (cuwo strings.py ENTITY_NAMES, ids 0–155)
0 ElfMale, 1 ElfFemale, 2 HumanMale, 3 HumanFemale, 4 GoblinMale, 5 GoblinFemale, 6 Bullterrier, 7 LizardmanMale, 8 LizardmanFemale, 9 DwarfMale, 10 DwarfFemale, 11 OrcMale, 12 OrcFemale, 13 FrogmanMale, 14 FrogmanFemale, 15 UndeadMale, 16 UndeadFemale, 17 Skeleton, 18 OldMan, 19 Collie, 20 ShepherdDog, 21 SkullBull, 22 Alpaca, 23 BrownAlpaca, 24 Egg, 25 Turtle, 26 Terrier, 27 ScottishTerrier, 28 Wolf, 29 Panther, 30 Cat, 31 BrownCat, 32 WhiteCat, 33 Pig, 34 Sheep, 35 Bunny, 36 Porcupine, 37 GreenSlime, 38 PinkSlime, 39 YellowSlime, 40 BlueSlime, 41 Frightener, 42 SandHorror, 43 Wizard, 44 Bandit, 45 Witch, 46 Ogre, 47 Rockling, 48 Gnoll, 49 PolarGnoll, 50 Monkey, 51 Gnobold, 52 Insectoid, 53 Hornet, 54 InsectGuard, 55 Crow, 56 Chicken, 57 Seagull, 58 Parrot, 59 Bat, 60 Fly, 61 Midge, 62 Mosquito, 63 PlainRunner, 64 LeafRunner, 65 SnowRunner, 66 DesertRunner, 67 Peacock, 68 Frog, 69 PlantCreature, 70 RadishCreature, 71 Onionling, 72 DesertOnionling, 73 Devourer, 74 Duckbill, 75 Crocodile, 76 SpikeCreature, 77 Anubis, 78 Horus, 79 Jester, 80 Spectrino, 81 Djinn, 82 Minotaur, 83 NomadMale, 84 NomadFemale, 85 Imp, 86 Spitter, 87 Mole, 88 Biter, 89 Koala, 90 Squirrel, 91 Raccoon, 92 Owl, 93 Penguin, 94 Werewolf, 96 Zombie, 97 Vampire, 98 Horse, 99 Camel, 100 Cow, 101 Dragon, 102 BarkBeetle, 103 FireBeetle, 104 SnoutBeetle, 105 LemonBeetle, 106 Crab, 107 SeaCrab, 108 Troll, 109 DarkTroll, 110 HellDemon, 111 Golem, 112 EmberGolem, 113 SnowGolem, 114 Yeti, 115 Cyclops, 116 Mammoth, 117 Lich, 118 RuneGiant, 119 Saurian, 120–130 plants, 131–139 deposits, 140 Scarecrow, 141 Aim, 142 Dummy, 143 Vase, 144 Bomb, 145 SapphireFish, 146 LemonFish, 147 Seahorse, 148 Mermaid, 149 Merman, 150 Shark, 151 Bumblebee, 152 LanternFish, 153 MawFish, 154 Piranha, 155 Blowfish.
Note: pet-food item IDs in W:Pet Food mirror these entity IDs (Collie 19 ↔ Bubble Gum 19, Turtle 25 ↔ Cinnamon Roll 25, Cat 30 ↔ Candy 30, Bumblebee 151 ↔ Biscuit Roll 151…). IDs 156 (Beaver), 170 (Warthog), 192/193 (Sprouts), 200/201 (Baby Elephant/Mammoth), 210 (Flamingo), 293–295 (Caterpillars, Snail) are post-alpha additions.
Steam-only creatures with no alpha id: Alpha Dog, Savage Dog, Bloomling, Iceling, Makake, Moose, Mana Deer, Panther(has id 29 but "not in alpha" per wiki — conflict), Elephant, Warthog, Beaver, Duckbill(id 74 exists), Snail, Caterpillars, Mantis, Spectrino(id 80 exists; wiki says not in alpha — conflict), Skeleton Dog/Horse, Skull Slater, Wraith, Demon Marauder, Seeker, Dark Cultist, Dark Jester, Bloodaxe Clan, Steel Empire, Mana Mech, Rune Giant(id 118 exists; wiki says not in alpha — conflict), Snow Leopard, Snow Lion, Ancient Guardian(ids 77/78 exist).

Alpha materials list hints at planned drops (cuwo MATERIAL_NAMES): Saurian (18), Parrot (19), Mammoth (20), Bone (7), Obsidian (5) — i.e. Saurian/Parrot/Mammoth/Bone armour sets, all unobtainable in practice (W:Mammoth Armor, W:Parrot Armor, W:Bone Armor, W:Obsidian Armor).

### 2.6 Bosses (consolidated)
- **Unique boss species**: Troll, Dark Troll, Yeti, Cyclops, Golem, Ember Golem, Snow Golem, Rune Giant [S], Mammoth, Saurian (several shapes), Sea Crab, Lich, Hell Demon/Demon, Mana Mech [S], Dragon (unused). (W:Bosses & pages)
- **Boss-ified regular mobs**: any mob (see 1.4), incl. named ones (e.g. penguin "Aslan").
- Shared boss traits: named, bigger, coloured name tier, break terrain, random special abilities, guarded by regular mobs, drop Spirit Cube [A] / one-tier-higher loot [S], 20 gold [S], can appear as mission objective, arena finale, dungeon end (Steam: several bosses of rising tier per dungeon; alpha: one per dungeon) (W:Bosses, W:Dungeon, W:Arena).
- Alpha level scaling: bosses shrink/weaken at level 1, full size at level 10 (WB 2012-10). "Huge boss mobs with random body parts" (WB 2012-03).
- Mission "Skull" icon = grand boss encounter (Yeti, Mammoth, Saurian, giant crab) (Darkmega). Dungeon-end bosses guard artifacts [S].
- Circle of Power boss = "Restless Warrior" (ghost of deceased warrior), 5★ legendary, drops Eternal Ember (W:Circle of power, FaceTheCube).
- Magic/Wizard tower boss = Necromancer, Wizard or Sorcerer guarding a Magic Crystal (W:Magic Barrier).
- Mana Pump: 4 Steel Empire bosses at 4 Mana Generators, then Mana Mech + pilot; each drops separate loot (W:Mana Pump).
- Witch boss in an "Old Hut" curses a village to stone (Darkmega; W:Bugs "Witch in the Old Hut often spawns on the roof").
- Arena: 5 waves; wave 1–2 white/green, 3 green/blue, 4 blue/purple, 5 purple or yellow BOSS (any monster type; e.g. Saurian in wave 1, Mammoth, Yeti, Mana Mech, Spectrino pairs); resets daily; hosted by a Bloodaxe Clan orc "arena master"; rewards 18–50 coins + gear (W:Arena, W:Coin, FaceTheCube).

### 2.7 Cut / unused creature content
Dragon; Old Man; Chiling Sprout; Skull Slater unmasked variant; pet foods Apple Pie (Wolf), Charred Steak (Imp), Liquid Drop (Cow), Wasabi Sauce (Devourer), Banana Mash (Warthog), Kaliptus Leaf (Koala); Mammoth Hides / Parrot / Bone / Obsidian / Silver / Gold armours; "Egg" entity (id 24); "Rare Pets" and "Pet Evolution" (planned, W:Pets); Mushroom Lands biome ("giant mushrooms and huge insects"); undead mummies for pyramids (WB 2011-07); throwable metal disks for rangers (WB 2013-01); alpha item/monster database on the homepage (WB 2012-07).

---

## 3. Pets

- Any tameable mob = pet. Tame by equipping the right Pet Food (right-click in Pets tab) and approaching; success automatic; hearts appear while it eats. One pet per food item; only one of each food carried at a time (exploit: equip then pick up a second). Groups: all same-species approach, one is tamed, the rest turn hostile (W:Pets, W:Pet Food).
- Pet food sources: Item Shop sells basic ones (Carrot, Candy, Waffle, Bubblegum; one type per town per day [S]); others drop from monsters and gathering nodes; jellies drop from Bats (W:Jelly). Bug: shop-bought food sometimes fails to tame (W:Cat).
- Pet types: Melee (most), Ranged (Snout Beetle, Spitter), Tank (Turtle), Healer (Spitter), Mount (~29 species; full list W:Mount Pets — Alpacas, Bark/Lemon/Snout Beetle, Bumblebee, Bunny, Camel, Cat, Collie, Runners x4, Duckbill, Horse, Pig, Peacock, Porcupine, Scottish Terrier, Sheep, Snail, Terrier, Turtle, Wolf, Blue/Yellow/Pink Slime, Crocodile). A pet can have several types (Turtle: mount+tank+melee) (W:Pet Types).
- Storage: each pet is a Pet Cage item in the Pets inventory tab; one active pet in the pet slot; no limit on count; turtle has a turtle-shell cage. Unsummon = right-click cage (W:Pet Cage).
- Combat AI: pets never initiate; join when the player attacks; switch target when player does; recall/stop with T (pet whistle); teleport to player if far [S]. No death penalty: dead pet auto-revives beside the player after ~1 minute, or instantly by re-equipping the cage. Pets don't attack Wraiths (W:Pets, Darkmega).
- Alpha [A]: pets have XP/levels and a hydration meter (water droplets under HP; empty = can't ride; refill in any water). Skills: Pet Master (+X% pet max HP/point; 5 points unlock Riding), Riding (+speed/point). Cookies heal pets (WB 2012-01). Ride with R.
- Steam [S]: pets have no XP; stats scale from player's equipment rating incl. plus-gear (patch 0.9.1-4/0.9.3-0). Riding requires the region-locked Reins key item; mount with T; dismount on any attack, dodge, fall damage, shift, or pet defeat (patch 0.9.2-0). Riding speed via artifacts (bugged — Riding/Climbing/Gliding artifact stats reportedly non-functional per Steam forums).
- Naming: `/namepet <name>`.
- Named boss pets revert to normal on reload. Bugs: taming can delete nearby mobs; swapping cages can delete/duplicate pets; "ride anything" exploit (W:Bugs).
- Pet Master NPC? — none; "Pet Master" is a skill. No mercenary/party-companion system in either version; co-op only. Friendly NPC adventurer groups and Gem Traders fight alongside you incidentally; Guardian Heroic Shout heals allies incl. NPCs/pets.

---

## 4. NPCs, villages, schedules, dialogue

- Villages/cities [A+S]: alpha = one village (capital) per region, always visible on map; Steam = several per region, hidden until discovered. Styles by landscape: European framework, medieval stone, North-American wood, log, jungle orange-roof, desert, undead (dark gray, pointed roofs, green lights, undead NPCs), snow (dark brown wood), lava-land, ocean (W:City, W:Undead Lands).
- Districts [A]: Trade District (Armor Shop, Weapon Shop, Item Shop, Identifier's Shop, market square décor), Crafting District (Smithy: Furnace/Anvil/Customization Bench; Clothier: Spinning Wheel/Loom; Workshop/Carpenter: Saw/Workbench), Adventurer District (4 class-trainer buildings) (W:Trade District, W:Adventurer District, W:Crafting Tool).
- Named NPC roles: Armor Vendor, Weapon Vendor, Item Shop vendor, Identifier (magnifying-glass sign, identifies Leftovers for a fee), Innkeeper (18:00–6:00 → 7:00; free [A], 10 coins + dialog [S]; also resets daily missions), Class trainers [A] / Guild Receptionist [S] (spec swap for a small fee), Flight Master [S] (eagle on a perch; buy flight points from 100 coins, scaling with distance; can fly to undiscovered points; drops you with a free temporary glider), Gem Trader [S] (roaming gnome; sells Emerald 100/Sapphire 200/Ruby 400/Diamond 800; buys items; armed, fights nearby enemies), Gnome Supplier [S] (captive; treasure-chest backpack), Carpenter NPCs in Workshops, arena master (Bloodaxe orc), Adapter [A] (crossed-swords icon, adapts gear for Platinum Coins), architect NPCs [concept, WB 2012-01], disenchanter NPC [concept, WB 2012-01] (W:Vendors, W:Inn, W:Flight Master, W:Gem Trader, W:Gnome Supplier, W:Adaptation, W:Workshop, W:City).
- Population: "Humans can be found in cities as majority of the residents" (W:Human); Steam forum observation "all cities are human" except undead villages in Deadlands/Dark Woods (W:Undead, Steam thread 1633040337766628105). Village animals: Collies, Cats (any colour), Sheep, Terriers, Pigs. "The longer you stand in town the more [NPCs] accumulate" (W:City).
- Schedule: NPCs sleep at night in inns (W:Sleep); many wander the market square by day (W:Trade District); NPCs/enemies light lanterns at night (W:Bugs); NPCs and monsters occasionally rest at campsites (W:Campsite); alpha AI demo: villager "Alerick" of "Tririon City" paths between places in the city, visits friends (WB 2012-12). NPCs stop and face the player within interaction range (W:NPCs). NPC adventurer groups roam and fight monsters like players; some are hostile (WB 2013-01).
- Dialogue: limited random banter; speech bubbles (alpha green bubble = mission giver; Steam mission NPCs unmarked); quest text randomly generated from phrase sets in EN/DE (WB 2011-12). Known lines: "Dungeons are a dangerous place. Don't forget to take some potions with you." (W:Dungeon); "PLAY THE DIVINE TUNE TO UNLOCK SEALED AREAS IN THE [region]" (W:Divine Tune); barrier-cleared message after all crystals destroyed (W:Magic Barrier). NPCs hint mission locations, key-item locations ("saw a special item at a location, but didn't need it"), lore; "It's theorized that reading lore helps NPCs tell the player more secret locations" (W:NPCs, W:Side Missions).
- Petrified villagers: whole village turned to stone by a Witch until she is killed; monsters attack petrified villagers endlessly (bug) (W:Bugs, Darkmega).

---

## 5. Playable races / NPC races

Eight playable races, any class (W:Races): Human (most customization; city majority), Elf (pointy ears; common in landscapes, uncommon in dungeons), Dwarf (small; beards/braids; fits through windows; Dwarf forests with Moles, Rocklings), Goblin (small, green; fits through windows), Lizardman/Lizard (reptilian; Lizard bosses), Orc (largest, green; orc castles; Bloodaxe Clan = purple, larger orcs [S]), Undead (bones, glowing eyes; dungeon/castle NPCs, Deadlands villagers), Frogman (no hair; "hair" option changes eyes; identical-looking unplayable "Frog" NPC). Non-playable humanoids: Gnobold, Gnoll, Nomad, Djinn, Ancient Guardian, Jester, Spectrino, Insektoid, Mantis, Mermaid/Merman, Vampire, Werewolf, Minotaur, Hell Demon, Dark Cultist, Witch, Wizard, gnomes (Gem Trader, Supplier), Iceling.
Forest-dungeon roster by race (W:Forest): Insect (Insektoids, Flies, Mosquitoes → Insektoid boss); Animal I (Lizardmen, Crows, Moles, Pigs, Biters → Lizardman boss); Animal II (Goblins, Crows, Moles, Pigs, Biters → Goblin boss); Undead (Undead, Zombies, Skeletons, Frighteners, Vampires, Slimes → Undead boss); Orc (Orcs, Collies, Terriers, Pigs, Ogres → Orc boss); Human (Humans, Minotaurs, Werewolves, Collies, Black Cats, Jesters → Human boss); Beetle (Bark/Lemon/Snout → beetle boss); Dwarf (Dwarves, Moles, Rocklings → Dwarf boss).

---

## 6. Factions (lore + gameplay)

Announced Oct 10–12 2015 tweets (CWS-tweets, Siliconera, Kotaku): "five factions" + "at least one more unrevealed".
| Faction | Alignment | Leader / lore | In-game presence [S] |
|---|---|---|---|
| Order of the Light | good | Aurus, "legendary paladin", sole survivor of three Legendary Paladins in the "Unholy War" | Paladins on white horses; Order of Light soundtrack; missions where paladins fight Unholy Pact legions; pre-2019 quest "find a paladin's horse" |
| Druids of Mana | good | Archdruid Kendu, died long ago fighting Cyphera "however he still is leading" | Frequent Mana Tree; allied Treants; quests "discovering ancient runes and protecting the planet from the Steel Empire"; assaulted by Steel Empire in mission warzones |
| Unholy Pact | evil | Three ghost preachers (black cloaks, white faces, glowing green pupils) made the pact; Necromancers and undead obey them | Dark Cultists?, Werewolves, Necromancers, Skeleton Knights, Monstrosity; pre-2019 quest concepts: find paladin's horse, examine Monstrosity animated by Necromancers, save an NPC being cooked by Skeleton Knights |
| Steel Empire (formerly Steel Legion) | evil | Empress Cyphera, "said to be immortal"; advanced warfare/technology | Airship appears overhead, soldiers parachute in (airship = largest sprite, 1,313 KB; shows on title screen if you quit during event); roaming enemy groups any tier; Mana Pumps / Mana Inductors / Mana Tree; Mana Mech; "Mana absorption" region debuff (slows mana gain) |
| Cult of Doom | evil | Dow "the half demon", "sinister plan" | Dark Cultists channel Demon Portals; Imps; possession of NPCs |
| Bloodaxe Clan | hostile orcs | — | Arena hosts, Lava Lands |
| Obsidian Knights | hostile humans | — | mission enemy group (W:Missions, MageForHire) |
| Thaldania Cult | — | dwarf-composed (MageForHire, procedurally named instance) | lore faction |
Procedural realm names seen (W:NPCs): Kingdoms — Kurlent, Vartarar, Theomida, Cydriaia, Kurnort, Lanmorar; Realms — Arigorar, Gadart, Gekina, Ardaria, Cyrmora, Rimorar, Cydrisia, Ulania, Ledarar, Rokaar; Cults — Annoia, Santara, Markinia, Roionar, Theogora, Thallonar; Tribes — Asionia; also Cyrtara Cult, Tulmida Kingdoms, Wynlurt Realms (Steam forum). Hostile NPCs in a region can be labelled as belonging to a realm (W:Kingdom).

---

## 7. Missions / quests

### 7.1 Alpha [A] (W:Missions, W:Main Missions, Picroma2013, WB)
- Marked as crossed swords on the world map; auto-assigned on approach; 8 mission slots per region (cuwo `MISSIONS_IN_REGION = 8`, `MISSION_SCALE = REGION_SCALE/8`). Objective: kill a boss — in a dungeon (castle, catacomb, temple, pyramid, ruins) or an overworld/terrain "dungeon" (Giant Tree, Giant Rock, Lake, Island, Canyon, Valley, Forest, Mountain, Crater, Peak, Cave, Portal per cuwo LOCATION_NAMES).
- Reward: XP + Platinum Coins (used for Adaptation) + items; multiplayer XP share bug fixed July 23 2013. Missions regenerate each in-game day / on sleep; marker vanishes when done. Mission bosses like Saurian don't drop Spirit Cubes. Villagers with a green chat bubble point to mission locations.
- Pre-alpha quest system (WB 2011-12 → 2013-01): kill quests, "find someone" quests, quest lines planned, then Wollay cut quests in Jan 2013 ("could remove a lot of the freedom… too repetitive") and shipped only missions. Picroma2013 "Planned: Procedural quests … randomly generated tasks with varying story, creatures, and places" + background story/lore.
- Pre-2019 concept (W:Quests, W:Old Man): quest log; rarities by colour; e.g. kill boss → note → find Amulet → return to NPC; Drolu Herbs into a cauldron; Old Man quest giver. Never shipped as such.

### 7.2 Steam 1.0 [S] mission catalogue (W:Missions, W:Side Missions, Darkmega, HowTo, FaceTheCube)
Discovery: talk to villagers/adventurers/read lore → marker appears on world map (may be far away); difficulty hidden (white text) until discovered on foot; icon = type; completed missions get a check mark; most reset daily (Inn reset works); Gnome Suppliers and Books of Crafting are one-time per region. Difficulty colours white→green→blue→purple(→yellow); reward gear usually one rarity above the quest colour, plus coins, 1 healing potion, gem(s) by colour.
| Map icon | Mission | Mechanics |
|---|---|---|
| Crossed swords | Combat encounter / Boss fight ("Invasion" theme) | kill a group + boss; factions fighting each other (paladins vs Unholy Pact, Druids vs Steel Empire); necromancers raising undead; captives; destroy spawn structures (mini demon portals, mana generators); repeatable daily |
| Gnome | Gnome Supplier rescue | 4 per region, difficulty white/green/blue/purple → unlock uncommon/rare/epic/legendary stock in Armor & Weapon (and Item) shops; a nearby boss holds the key ("unlock" prompt), or freed automatically when objective done; drops rewards at your feet |
| Hammer | Book of Crafting | combat/captive encounter rewarding a book (3–4 recipes/tier; 4 books per region) |
| Purple gem | Magic Barrier / Wizard Tower | up to 5 towers; boss (Necromancer/Wizard/Sorcerer) guards Magic Crystal at top; all crystals destroyed → region's blue barriers drop (permanent faded barrier) |
| Cauldron w/ fire | Circle of Power | stonehenge spires; Restless Warrior boss (5★) drops Eternal Ember → light brazier → region power buff (top-left buff); several per region; multiplayer drops one ember per participant |
| Red portal | Demon Portal / Altar | Dark Cultists channel beam to heal portal; kill them, smash portal (imps spawn endlessly); cures all possessed NPCs; big portals spawn at altar centres (patch 0.9.3-0); varying sizes |
| Battery/clipboard | Mana Pump | 4 Mana Generators each with Steel Empire boss → Mana Mech + pilot → smash pump; removes "Mana absorption" debuff; generators give 1–3 coins each; smaller "Mana Inductor" variant without mech |
| — | Mana Tree | kill enough surrounding enemies to summon final boss; Steel Empire inductors sometimes present; Druids of Mana frequent it; replaces alpha Giant Tree |
| Skull | Grand boss encounter | Yeti, Mammoth, Saurian, Sea Crab, Troll, Demon, Golems etc.; respawn daily |
| Skull (arena) | Arena | 5 waves, see 2.6 |
| Glowing/orange circle | Artifact dungeon | region's "ultimate goal"; dungeon with parkour, traps?, enemies green→yellow, multiple bosses; artifact = level-up + traversal stat; may need key items |
| Item pictogram | Special item / key item | Reins, Boat, Hang Glider, Climbing Spikes (movement kit, 4 per region), Divine Harp, Sky Whistle, Spirit Bell (ticket items, 3 per region), Treasure Spirit; no fight required for Reins; "up to 9 key items per region" |
| Hut | Old Hut / Witch | village petrified until witch killed |
| — | Captured NPCs | rescue (patch 0.9.1-5 fixed uncapturable) |
| — | Molehills / Bone piles / Hornet nests / Slime wells | destroy spawner to stop endless Moles / Skeletons / Hornets / Slimes |
| — | Unholy Pact, Dark Cultists, Obsidian Knights, Order of Light, Druids of Mana, Steel Empire soldiers | faction-themed combat encounters |
| — | Camps | map "Camp" locations sometimes hold a boss; campsites have bedroll/campfire |
| — | Vaults (mines/labyrinths) | golden door opened by Divine Tune/Harp; gauntlet of progressively harder rooms; reward artifact and/or treasure |
| — | Sky islands | Sky Whistle at bird statue → birds lift you to floating island with treasure |
| — | Lore locations | stone tablets, menhirs, rocks, ruins, crypts, circles of power |
Region completion (HowTo): unlock Shrines of Life (respawn + fast travel), do white quests (gnomes first), then green, blue, purple; get "+" gear (works in adjacent regions) before leaving.
Warp/spirit mechanics: Spirit Bell → "Spirit World" for 30 s (wiki) / ~45 s (Darkmega): ghostly, pass through metal portcullis gates, spooky music/fog. Divine doors re-close every new day. Revival statues [S] must be activated by playing a flute (auto-owned; not the Sky Whistle); alpha auto-respawned at nearest statue; alpha Portals = teleport stones between discovered portals (removed in Steam; Flight Masters instead).

### 7.3 Lore system [S] (W:NPCs, W:Kingdom, W:Relic, Steam threads, MageForHire)
- Procedurally generated realms/kingdoms/cults/tribes; each has leader (with personality trait, birth year, hometown, tomb location), capital (name, founding year, sometimes destruction date), known magic/technology (Steam thread 1628538644184996001 summary).
- Lore pieces on tablets/rocks/ruins/crypts; reading raises lore % (text colour gray→green); viewable on world map; 100% lore for a realm reveals all its relic/artifact locations across its regions. Example tablet: "a hero who died fighting a Skeleton Horse".
- Relics/Artifacts (Ring of Momuna, Sirazyna Stone, named gems): +1 level each (level = artifact count), permanent bonus to climbing/swimming/diving/riding/gliding/sailing speed or lamp radius; can't be dropped; several per region; found in dungeons, bosses, treasures, vaults.

---

## 8. Dungeon / location types as enemy habitats
Castle/Palace (Greenlands, Snowlands; orcs), Citadel (Lava Lands), Fort (Savannah), Catacomb (dark, Undead), Pyramid (Deserts, Lava Lands; Ancient Guardians, Djinn, Skeletons, Black Cats, Mosquitos, Slimes; entrance at top), Temple (Jungles, islands; spiral stair down), Ruins (Overworld Greco-Roman or damaged castles; "Ancient Ruins of"), Den (in cities), Vaults [S], Magic Towers [S], Lava Lake, Giant Rock [A], Giant Tree [A], Mana Tree [S], Forest dungeons (named "X Forest", campsites, canopy blocks light), Island, Lake, Canyon, Valley (Insectoids, Mosquitos, Flies; boss centred), Cave (Bats, Rocklings, deposits), Graveyards/crypts. Alpha dungeons: linear, spike traps, vases, small chests, loose items; Steam: no traps/vases, one-time chests, multiple tiered bosses, dungeon map that uncovers as you explore (tweet Apr 1 2017), region-bound loot (W:Dungeon, W:Pyramid, W:Forest, W:Valley, CWS-newmap).

---

## 9. Cube World Omega [Ω] (2023–2025)
- Announced May 25 2023 (wollay.com): "in the spirit of Cube World Alpha"; new Vulkan engine; weather (rain, snow), moving clouds, leaves, waves, freezing water/ice; all creatures (players, NPCs, pets) procedurally generated — no hand-modelled parts; facial expressions (neutral, happy/angry, sad, surprised, sleeping, blink); procedural weapons/armor; XP, leveling and skill trees return; new GUI.
- Creature posts: Procedural Undeads (May 26 2023); Zombies with "eat" skill — grab player, immobilise, drain HP while healing (May 31/June 1); Ogres with wood maces and "belly slide" charge (damage + stun) (June 6); Frogmen & Lizardmen complete the 8 playable races (June 13); Slimes "Divide" — below 50% HP split into smaller full-HP copies; Crabs "Claw Boomerang" ranged throw (to be made occasional) (June 26); Hornets "poison sting"; NEW Hedgehog with "spike swirl" radial spikes (Oct 14 2023). Concept: every creature gets "signature abilities".
- World gen post (July 30 2023): coarse regional maps place streets, buildings, rivers, bridges, trees, caves before voxel detail.
- 2024: Feb 1 tweet — trying Unreal Engine 5, "next… small details… and finally creatures"; Apr 18 2024 "Some progress with Cube World Omega in Unreal Engine 5"; shader updates mid-2024; no public updates since ~mid-2024; no release date as of 2025 (x.com/wol_lay/status/1753019613753852220, 1781000511635722461; YouTube news videos).
- No Omega info exists on quests, factions, pets/taming, bosses beyond the above.

---

## 10. Conflicts / uncertainties
- Rideable flags differ between W:Pet Food table and individual pages for Beaver, Chicken, Crow, Koala, Monkey, Parrot, Penguin, Seagull, Squirrel, Crab, Hornet, Fly (table generally "Yes", pages "No"). Note W:Pet Food itself says a 1.0.0-1 bug made all pets rideable — table likely reflects bug.
- Wiki "does not exist in Alpha" claims for Panther, Spectrino, Rune Giant, Duckbill, Ancient Guardian contradict alpha entity IDs in cuwo (ids 29, 80, 118, 74, 77/78) — IDs may be unused/unspawned in 0.1.1.
- Spirit Bell duration: 30 s (W:Spirit Bell) vs ~45 s (Darkmega).
- Alpha Dog / Savage Dog "passive" vs dungeon variants aggressive; Lion tameability disputed.
- Alpha map name-colour tiers (white/blue/orange/red/purple) vs Steam rarity tiers (white/green/blue/purple/yellow) — different systems.
- Bedroll heal "10 HP/s (requires testing)".
- Demon/Hell Demon naming differs between versions.
- Whether 1.0 "Necromancer"/"Sorcerer" are distinct entity models or renamed Wizards is unverified.

## 11. Gaps (not found)
- No HP/damage numbers per creature in either version (only white-mob 150–250 HP, alpha power formula, boss size scaling to lvl 10, coin drops).
- No full 1.0 artifact name list (only Ring of Momuna, Sirazyna Stone).
- No verbatim NPC dialogue corpus beyond 3 lines; no lore-tablet text templates.
- No Steam boss list with per-boss attack sets beyond guide anecdotes; no confirmed list of "special ability" pool.
- Obsidian Knights, Order of Light paladins, Druids of Mana have no dedicated wiki pages; presence attested only via guides/tweets.
- Omega: nothing on quests/pets/factions; development status after mid-2024 unknown.
