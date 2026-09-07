# Cube World — Meta Systems, Progression, Multiplayer, UI, Tech, Version History

Research dump (Sept 2026). Scope: alpha 0.1.x (July 2013), Steam beta 0.9.x / 1.0 (Sept–Oct 2019), Cube World Omega (2023–).
Confidence tags: **[C]** confirmed by primary/official or code; **[W]** wiki/community, likely right; **[?]** uncertain / conflicting.

Primary local sources used (all in scratchpad): cubeworld.fandom.com wikitext dump (`fandom/*.txt`, `wiki/*`), cuwo repo + wiki (`cuwo/`, `cuwo-wiki/`), Wayback snapshots of wollay.blogspot.com devlog 2011–2013 (`wb/blog_all.txt`), Wayback of picroma.com/cubeworld 2013 feature page (`wb/picroma_cw_2013.html`), alpha-era cubeworldwiki.net (`wb/cwwiki_*.html`), Steam store API, Steam guides (page_1..3), NamuWiki (page_6), PCGamingWiki API dump, wollay.com RSS.

---

## 1. Version history & changelogs

### 1.1 Pre-alpha devlog timeline (wollay.blogspot.com, via Wayback) [C]
Source: http://web.archive.org/web/2014/http://wollay.blogspot.com/YYYY_MM_01_archive.html

| Date | Feature(s) introduced / announced |
|---|---|
| 2011-05-15 | Picroma **Plasma** (vector graphics app) sneak peek — Picroma's first product; Cube World's GUI later built with Plasma graphics (.plx/.pld/.plg) |
| 2011-06-08 | "Started developing a 3D voxel-based game two weeks ago as a fun project" (start ≈ late May / June 2011; wiki says June 8, 2011) |
| 2011-06-09 | **Third-person view added**; "view distance adjusted with mouse wheel; you can still play in first person mode by zooming into the character"; multiplayer gameplay video |
| 2011-06-11/12 | Own **voxel editor** written; new 3D sprites (old man NPC, female char, goblin); GUI speech bubbles for NPCs, questing started |
| 2011-06-13..24 | Clouds & shading tweak; landscape voxel resolution doubled per axis; tree sprites; water, improved animations; **first boss: Troll** with big mace; more vegetation |
| 2011-07-06 | Villages with NPC-inhabited houses; roads with auto tunnels/bridges; walk uphill without jumping; deserts w/ pyramids & oases; planned jungle/snow zones |
| 2011-08-28 | **Engine rewritten** ("new engine is faster and has a cleaner shading") |
| 2011-09-05 | Procedurally generated trees (each unique) |
| 2011-11-19 | **Bows** (ranged, combo-capable); **lock-on targeting**; "basic leveling and experience system" |
| 2011-11-20 | Riding ("Taking a Ride") |
| 2011-11-23 | Extended FAQ: C++ + DirectX (OpenGL for first version); own voxel editor; house building supported; no mining/digging; planned: customization (faces/hair), mage class, races, quests, items, blueprints, weapon/armor upgrading, pets; not free |
| 2011-11-24/26/28 | Dual wielding (faster, less dmg, faster combo build); random-size **castles** with rooms; multiplayer castle video |
| 2011-12-12/17 | Rivers w/ waterfalls; new enemies: crows, berserker dwarves, hornets, lizardmen, plain runners |
| 2011-12-30 | **Quest system** started: random kill quests, generated text (EN+DE), quest region highlighted on minimap, progress under minimap; XP reward |
| 2012-01-18 | **Climate system**: temperature + humidity vary across world → biomes (jungle first; deserts, savannahs, tundras, snowlands planned) |
| 2012-01-19 | **House building** prototype: construction plans (10x10x10 building pieces: wall, corner, window wall, roof) placed with 3D cursor; architect NPCs; "framework house" style; teleport home planned |
| 2012-01-20/24 | Caves; blueprints GUI (collectable cards w/ rotating 3D preview); frogs, moles; **pets** (first pet = Wollay's collie "Joschi"); **aggro system** (WoW-like, highest aggro attacked); tank pets planned; heal pet with cookies; **equipment upgrading**: place up to 10 cubes on weapons/armor (raises item level, changes look); iron cubes from disenchanter NPC |
| 2012-01-30/31 | Combat rework: combo points replaced by **"spirit" (SP)** energy unleashed by finishing move (dual: Swirl, 2H: Smash, shield: Slam); **spirit cubes** attach to weapons/armor (fire = fire dmg, unholy = life drain), glow with SP, boss drops |
| 2012-02-02 | Obsidian armor & swords |
| 2012-02-10 | **Random dungeons**: fire & spike traps, levers, doors, gates, dungeon bosses, treasure chests |
| 2012-02-16 | Weapon movesets: Bow (charged arrow standing still; roll+special = air strike), Dual (Swirl; roll+special = charge & dual-slash), Shield (chance to block when facing; Shield slam; roll+special = charge & slam), 2H (Smash; roll+special = somersault smash) |
| 2012-02-27 | Greatswords & greatmaces; combo system back (subsequent hits more dmg, different anims); improved camera/targeting; **kingdoms** with frontier walls and guards; dungeon-entrance **runestone** (port back after clearing); **ring item menu** for consumables; **coins**: copper/silver/gold |
| 2012-03-05/13 | Dungeon themes (mines, crypts, tombs); huge boss mobs with random body parts → random abilities; combo: faster + more dmg, miss ends chain; **auto-targeting removed** ("fight freely"); ability bar; **stamina** (dodging + abilities) |
| 2012-03-26 | Mountains & clouds |
| 2012-05 | Pixxie (Sarah von Funck) joins (team of two since May 2012); villages with fields & inns; crafting of potions & armor shown |
| 2012-07-07 | Website coded in C++; **separate server application, anyone can host**; Windows-only server but Linux port "no problem" (only Winsock dependency); planned in-game server browser; offline play; **chat window lower-left**; debug `/level` cmd; land-name captions fade in/out; **crouch** (sneak past enemies, climb walls); streetlights; village shops (item/weapon/armor), inns, towers with a **sage who identifies items**; item **rarity levels 0–4**, max only from rare bosses; slimes tameable; "find someone" quests; witches (fire beams harmless, fireballs deadly) |
| 2012-09-18 | **Hang gliders** ("probably with level 10 or higher"; hitting a wall stuns and drops you); **sprinting** (stamina); stun attacks; **rare zones** (zones have rarities; stronger monsters, better loot); castle dungeons; lava lands |
| 2012-10-09 | Class overview: Warrior (Guardian/Berserker), Ranger (Sniper/Scout), **Spirit Mage** (Fire/Water; passively generates spirit; staffs, wands), Rogue (Assassin/Ninja); specializations swappable in villages any time |
| 2012-10-12 | Bosses scale: small/weak at lvl 1, full size/strength at lvl 10; stun-immunity stars over head; potions heal over time, can run but attack/roll cancels; **death: respawn at next spawn point with "injured" debuff (reduced max HP for minutes, band-aids on back) removable by eating**; sit & sleep (characters sleep face-down: can't close eyes); pet taming with favorite food; pet equipped like an item, pet bag |
| 2012-10-16..26 | Rename attempt (candidates: Spirit Hunter, Kyubu, Little Cube Adventure, Lost in Monsterland, Cube Boy, Kami Heroes) — abandoned; **lands**: each land has a level, all creatures share it, level rises with distance from start; each land has a capital; procedurally generated buildings (rooms/sizes/roofs), house themes: European framework, medieval stone, North American wood, log houses (desert/jungle planned) |
| 2012-11-04 | 3D world map "automatically recorded while you explore… big version of the minimap" |
| 2012-12-04 | **AI**: A* pathfinding w/ climbing and arbitrary bounding boxes; villager daily schedules (sleep, park, shops, inn); monsters chase everywhere incl. climbing; rogue stealth faster in shadow, full stealth = invisible, stealth builds spirit; dungeon enemy groups aggro together; ogre patrols stronger |
| 2013-01-28 | **Quests dropped** ("could remove freedom… repetitive") → focus on exploration/fighting/character progress; **overview map** (lands + levels; switch voxel map ↔ overview; blue = ocean, green = your level, red = higher, gray = lower); screens: character selection (unlimited slots), world selection ("each character can enter each world"), character creation (random background), world generation; 3 weapon types per class (Warrior: great / dual / shield+1H; Rogue: daggers/fists/longswords; Spirit Mage: staffs/wands/bracelets; Ranger: bows/crossbows/boomerangs); **NPC adventurer groups** roam & fight (some hostile); city districts + **class trainers**; "specializations won't be available from the beginning; abilities unlocked one after another each level"; sniper Aim = lie down, zoomed view; crafting **formulas**; boss random special abilities (e.g. summon clone); rare ogre drops a spirit; boomerang follows crosshair |
| 2013-05-08 | New gameplay video |
| 2013-06 | New homepage picroma.com; Cube World: Explorers video/music |

### 1.2 Alpha release & patches (2013) [C]
- **2013-07-02** Alpha released on picroma.com, Windows, **€20 / $20** (Eurogamer says $15 USD **[?]**); launcher with Picroma account login; download server DDoS'd at launch; shop closed shortly after; purchases later impossible (Wollay cited EU tax law change, 2015 Kotaku interview) . (Wikipedia; Cube_World wiki page; NamuWiki)
- Version string of the initial alpha: **0.1.0** (neoseeker Version History lists "0.1.0"; fandom alpha manifests just use dates). Initial alpha build shows Alpha 0.1.0 in launcher **[W]**.
- **2013-07-05 patch** (fandom `July_5th,_2013`) — bug fixes: MP could be regenerated with the **'O' key** (debug leftover); selling non-existing items from inventory. Other: **option to invert y-axis**; launcher issues improved.
- **2013-07-23 patch** = widely called **0.1.1** **[?]** (fandom `July_23rd,_2013`; cubeworld-servers.com/blog/3 "New Cube World update") — Ranger 'Scout's Swiftness' no longer crashes multiplayer servers; 'Retreat' no longer increases hang-gliding speed; multiplayer groups got too much mission XP (fixed). Other: **FPS limit option (options menu, default 111 FPS)**; crossbow RMB ability only damages when charged; inn day-reset only 6 PM–6 AM.
- After July 2013: no further alpha patches. Nov 14, 2013 tweet promised a large patch (never shipped). Jun 30 2014 status update; Jul 10 2015 Kotaku email interview ("not dead", quest system redesigned several times, no Steam until beta). SoundCloud drops Oct 4–6 2015 ("Druids of Mana", "The Steel Empire", "Order of the Light") + screenshot of "Queen Cyphera". (NamuWiki, Kotaku)
- Alpha protocol/client version constant = **3** (cuwo `CLIENT_VERSION = 3`) [C].

### 1.3 Steam closed beta → 1.0 (Sept–Oct 2019) [C]
Source: fandom `0.9.1-3`…`0.9.3-0`, `Patch_Notes/Manifests`, Steam thread (pixxie posts patch notes), Steam FAQ thread.
- 2019-09-06/07: Steam page revealed; Wollay's blog letter (DDoS "traumatized me… anxiety and depression ever since"; perfectionism, reworked from scratch several times; "basically Cube World 2.0"). Alpha owners get Steam keys via Picroma "My Games". Blog deleted ~Oct 2 2019.
- **2019-09-23 Closed beta** for alpha buyers (Eurogamer: one-week beta).
- **0.9.1-3 (Sep 24)**: fixes campfire/crafting station crash, Mage float glitch, non-removable ocean markers; **wall-jump costs stamina**; **mini-map scalable separately from HUD**; new characters spawn near villages.
- **0.9.1-4 (Sep 25)**: lands don't change within dungeon; objects can't be used through walls; no rolling through doors after `/sit` (vault glitch); dropped artifacts lootable by all players; known lore no longer 0 after selecting character; pets/shadow shooter stats scale; world map no longer vanishes on alt-tab; **remapped controls now saved**; removed sell price from tooltip; NPCs drop rewards once; artifact quests marked cleared on loot; **option to loop music**. (`cubeworld.exe` +7 KiB)
- **0.9.1-5 (Sep 26)**: invisible dungeon walls removed; dungeon items bound to correct land; quests marked completed in wrong land fixed; captured NPCs rescuable; craft Snow Berry Mash; frozen heart flowers in Snowlands.
- **0.9.1-6 (Sep 27)**: multiplayer widget no longer crashes with 14 friends; **`antiAliasingSamples 8` in options.cfg** configurable; refresh rate reduced when window in background; keys not removed when opening gates; can't drop pet food while using; reduced warrior 'shift right-click spam' exploit.
- **0.9.2-0 (Sep 28)**: Shuriken attack consumes 25 stamina; invisible orc hairstyles removed from creation; bosses spawn in invasion quests; dialog options in speech bubbles; music loop fixed; mages can't teleport through gates; stop riding when pet defeated; distant menhir tablets. (+`dict_en.xml`)
- **0.9.3-0 (Sep 29)**: enemy mage wand dmg −25%; mage teleport distance back to normal; dungeon enemy size limited; **help widget visible by default for new chars; help button in Esc menu**; magic barriers in overlapping dungeons disabled; big demon portals at altar center; item receipt notifications + pet scaling consider plus-equipment; **level of other players displayed when highlighted**. (+`icons.plx` 28 KiB)
- **1.0.0-0 — 2019-09-30 release** (manifest Sep 30, no notes). Steam categories: Single-player, Multi-player, Co-op, Online Co-op, **Partial Controller Support**, Steam Cloud, Family Sharing. Price ~$20 (KRW 20,500). English only (German planned). Windows 7 unsupported (xAudio).
- **1.0.0-1 — 2019-10-01** (manifest 8533078140585826576, 4.7 MB; **no public patch notes found**). No later patches. Nov 2020: a screenshot (via PM, not official) allegedly showed level system/skill tree returning **[?]**.

### 1.4 Cube World Omega (2023–) [C]
Source: https://wollay.com/ (RSS), https://wollay.com/2023/05/25/new-blog-and-new-project-cube-world-omega/, massivelyop.com 2023-05-26, cubeworld-servers.com/blog/22
- **2023-05-25** announcement: "Omega" as counterpart to "Alpha"; "in the spirit of that version, but with a new engine and new features".
  - **New Vulkan-based graphics engine**: moving clouds, jiggling leaves, water waves, **weather: rain, snow**; water freezes in cold areas (slippery ice).
  - **Procedural models**: every creature (players, NPCs, pets) procedurally generated; "no part of a character is hand-modeled, neither hair, face nor hands"; procedural weapons/armor; **facial expressions** (neutral, happy/angry, sad, sleeping, surprised, blink).
  - **New GUI**; bringing back **experience, leveling, skill trees**; cast bars show ability names/durations.
  - Music shared on SoundCloud (wol_lay).
- Devlog posts: 05-26 Procedural Undeads; 05-31 Zombies, code snippets (undead always angry; 10% of male humans bald), **signature abilities** (bat "Vampiric Bite"); 06-01 zombie "Eat" grab (drain HP, armor penetration grows w/ combo); 06-06 Ogres (procedural wood maces, "belly slide" charge+stun); 06-13 **8 playable races complete**: human, elf, dwarf, goblin, lizardman, undead, frogman, orc; procedural warrior equipment; 06-26 Slimes ("Divide" at <50% HP) & Crabs ("Claw Boomerang"); 07-30 **New world generation**: per-region coarse map placing streets, buildings, rivers, bridges, trees, caves "connected in a logical way", then detailed voxels on the fly; butterflies, water lilies, windmills; NPC navigation planned; 10-14 Hornets (poison sting) & Hedgehogs ("spike swirl").
- **Last blog post 2023-10-14.** No 2024–2026 posts in RSS. No release date, price, or "free upgrade vs new game" statement (Steam mods: "No one really does except for Wollay"). A YouTube summary claims 2024 UE5 work **[?] unverified** — contradicts the Vulkan engine statement; treat as rumor.

---

## 2. Progression systems

### 2.1 Alpha (0.1.x) — XP / levels / skill tree [C/W]
- XP from monsters, bosses, missions; level-up auto. **Each level = 2 skill points** (fandom Skill_Points/Levels). Alpha promo: "infinite character progression" — no level cap in design; int32 cap **2,147,483,647** in practice (fandom Levels).
- **Power** (0..~100) is what matters: `Power = (101*level − 81)/(level + 19)` (fandom Power_Level; picroma.com 2013: "power scales tangentially… between 1 and 100; 100 only at infinite level"). Table highlights: L1→P1, L2→5, L3→10, L5→17, L10→32, L20→49, L30→60, L50→72, L100→84, L200→91, L500→96, L1000→98, L1981+→100 (P101 at level 671,088,545 — bug). Items have a **+N power level**; player can only use items ≤ own power ("highest usable equipment power").
- XP to next level (cuwo `get_max_xp`): `int(1050 − 1000/(0.05*(level−1)+1))` → L1: 50 XP, L2: 97, L5: 216, L10: 360, L20: 535, L50: 745, L100: 882 (asymptote 1050).
- Base HP (cuwo `get_base_hp`): `level_health = 2^((1 − 1/(0.05*(level−1)+1))*3)`; player: `level_health*2*max_hp_multiplier`; NPC: `level_health * 2^(power_base*0.25) * mult`; class multipliers: Warrior ×1.30 (Guardian +×1.25), Ranger ×1.10, Rogue ×1.20, Mage ×1.0. Item HP: only types 3–7 (weapons/chest/gloves/boots/shoulder); chest ×1.0, others ×0.5; `base_hp*5*type*mod_mult` with `item_base_hp = 2^((1−1/(0.05*(lvl−1)+1))*3) * 2^(rarity*0.25)`; material bonuses Iron +1.0, Linen +0.5, Cotton +0.75; each upgrade cube = +0.10 item level.
- **Skill tree (X key)**: 11 skill slots in EntityData (`skills[11]`; cuwo SKILL_NAMES): 0 PetTaming (Pet Master), 1 PetRiding, 2 Climbing, 3 HangGliding, 4 Swimming, 5 BoatDriving (Sailing), 6–10 Ability1–5 (class abilities). General tree = 3 chains, each unlocks next at **5 points**: Pet Master (+X% pet max HP) → Riding (+X% mount speed; alpha riding also faster in water); Climbing (−X% stamina drain) → Hang Gliding (1st point enables glider; more = faster); Swimming (+X% swim speed) → Sailing (1st point enables boat; more = faster). No hard cap per skill ("infinite leveling").
- Class abilities are also leveled with points (e.g. Retreat needs 5 points in Kick; points reduce cooldown/increase distance — fandom Retreat). Four class skills bound to keys **1–4**; specializations change the 3rd/4th ability + passives.
- **Specialization** chosen at class trainer in the Adventurer District (stand next to your class master, open X; small coin fee). Alpha class trainers let you "learn new abilities and practice them with aims" (targets). No respec of general skills documented **[?]**.
- **Adaptation** (alpha only): Adapter (crossed-swords icon) changes an item's level to your power for **Platinum Coins** (boss/mission reward); lowering is free.
- **Rarity** (6 tiers): Worn(grey,*) [1.0 region-debuffed], Common (white,*), Uncommon (green,**, Emerald), Rare (blue,***, Sapphire), Epic (purple,****, Ruby), Legendary (yellow,*****, Diamond); stats ≈ double per tier; "Mythical" (alpha-only bug tier from +4 dungeon chests giving +1 tier over legendary; shows as red/common-looking). Affix lists per tier in fandom `Rarity`. Alpha `rarity_cap = 4` (gold) in cuwo anticheat.
- **Formulas** (alpha): recipe scrolls sold/dropped by tier, right-click to learn; must be right level. Removed in 1.0 (Books of Crafting).
- **Spirit cubes** (alpha): Fire (+dmg), Wind (+attack & move speed per combo hit), Ice (slow target), Unholy (life drain per special, scales with combo); 16 cubes max on 1H, 32 on 2H/shield; cube power must be ≤ weapon power and ≥ weapon power −10; removing destroys them; bosses drop one per kill (same cube each respawn). Iron/Wood cubes are +1 and unrestricted. Material IDs 128 Fire, 129 Unholy, 130 Ice, 131 Wind (cuwo).
- Coins (alpha): copper/silver/gold (100:1:… ), platinum for adaptation. Death (alpha): **no penalty** (Kotaku 2013; "injured debuff" from Oct 2012 devlog apparently not in released alpha **[?]**), respawn at nearest revival statue automatically.

### 2.2 Steam 1.0 — region ("land") based progression [C/W]
- **No XP.** Level = number of **artifacts (relics)** collected (50 artifacts → level 50). Artifacts: cannot be dropped; work in all regions; boost only exploration stats: climbing speed, swimming speed, **diving stamina**, riding speed, hang-gliding speed, sailing speed, **lamp radius** (fandom Relic/Diving/Iron_Lamp). Each ≈ +1% **[?]** (gamesline). Named examples: Ring of Momuna, Sirazyna Stone. 1–3 artifacts per region; from dungeons, vaults, bosses, treasures, floating islands.
- **Lore**: each region belongs to a Realm/Kingdom/Cult; talking to NPCs and reading menhir/stone tablets adds ~10% each; at **100% lore** all that realm's artifacts are revealed on the map (spread over several regions) and **"+" loot** starts dropping.
- **Region lock**: weapons, armor, accessories, Leftovers, bombs' loot, and **key items** are bound to the region found in. Outside: gear drops to Worn/grey (e.g. 194.1 dmg staff → 5.4); key items simply stop working. **"+ items"** (name suffix "+") keep full strength in **adjacent** regions only. Each region has its **own inventory page** (arrows at bottom of inventory). Regions shown as white-bordered lands on the map. Gear stars for armor & weapon shown at left of inventory (B).
- Gear tiers via colored **quests**: White → Green → Blue → Purple → Gold; map icons: Hammer = Book of Crafting, Gnome = supplier, Sword = daily repeatable, purple gem = magic tower/barrier, Skull = arena, orange circle = artifact, red portal = demon altar, cauldron w/ fire = Circle of Power, item icon = key-item quest, battery = mana pump, no icon = undiscovered.
- **Gnome Suppliers**: 4 per region; each rescued gnome raises shop stock one rarity; all 4 → legendary gear sold; shops restock daily.
- **Books of Crafting**: 4 per region (Uncommon/Rare/Epic/Legendary), 3–4 recipes each; only recipe source in 1.0.
- **Circle of Power**: kill restless warrior → Eternal Ember → light brazier → power bonus in that region (multiple per region; one ember per participating player).
- **Key items** (up to 9 per region, "Special" inventory tab, shown top-left HUD): Movement (4): Hang Glider, Boat, Reins, Climbing Spikes; Ticket (3): Divine Harp (opens divine doors, reclose daily), Sky Whistle (birds carry you to floating islands), Spirit Bell (spirit world for 30 s, pass sealed gates); plus Treasure Spirit (points to treasure), Eternal Ember, Iron Lamp (F key ability in 1.0, radius via artifacts).
- **Mob strength colors** (replace mob levels): White (farm animals, 150–250 HP), Green, Blue, Purple, Yellow (legendary); alternative community scale White/Blue/Orange/Red/Purple(boss). "Armor: you take no damage if defense > enemy attack" (NamuWiki) — combo counter ignores armor progressively (max ~20–30 hits, turns blue with "!").
- Coins: single currency; monsters 1–3, bosses 20, gems 5/7/10/14, legendary 8–14 (+ 20), arena 18–50, bags 25–59; coins auto-picked by walking over; flights cost ≥100 (Wollay's House at 0,0 ≈ 54,000 km ≈ 1.1M coins).
- **Specialization** swap: Guild Receptionist / class trainer in any village, **free** in 1.0 (Steam thread) / small fee (fandom) **[?]**. All skills unlocked from the start (no skill points).
- Death (1.0): press R → respawn at random nearby **activated** Shrine of Life (activate by playing flute with E); no item/XP loss; boss HP resets unless shrine is close; pets never permanently die (respawn ~1 min or re-equip cage).

---

## 3. Classes / skills quick reference (IDs from cuwo, descriptions from wiki) [C/W]
- Class IDs: Warrior 1, Ranger 2, Mage 3, Rogue 4; specialization 0/1: Berserker/Guardian, Sniper/Scout, Fire/Water, Assassin/Ninja.
- Ability IDs (alpha): 21 RangerKick, 34 HealingStream, 48 Intercept, 49 Teleport, 50 Retreat, 54 Smash, 79 Sneak, 86 Cyclone, 88 FireExplosion, 96 Shuriken, 97 Camouflage, 99 Aim, 100 Swiftness, 101 Bulwark, 102 WarFrenzy, 103 ManaShield. Mage weapon attacks (decompiled strings): Fire Swirl(30)/Fire Vortex(31)/Water Swirl(32)/Water Vortex(33)/Fireball(37)/Firebolt(38–40)/Water Salvo(45)/Fire Salvo(46)/Firebeam(94)/Fireray(95).
- Alpha skills: Warrior Smash, Cyclone (5 s spin), War Frenzy (Berserker, 10 s), Bulwark (Guardian, stun-immune, 10 s); Ranger Kick, Retreat, Aim (Sniper, lie down stealth), Scout's Swiftness (10 s); Mage Fire Explosion (Fire), Healing Stream (Water), Mana Shield (30 s), Teleport (100 MP, ~60 blocks); Rogue Intercept (costs MP), Sneak, Camouflage (Assassin), Shuriken Attack (Ninja).
- 1.0 layout: no skill keys 1–4; **R = one special per specialization** (40 s cd per fandom; F1 says 30 s): Berserker Rock Fist (20 s cd), Guardian Heroic Shout (30 s cd, taunt 5 m + heal 50% over 10 s), Sniper Shadow Shooter, Scout Quicksand Trap, Fire Mage Fire Missiles (4 fireballs), Water Mage Bubbles, Assassin Camouflage (20 s), Ninja Ninjutsu (60 s cd, 20 s). **Shift** = class movement/utility (Cyclone, Sneak, Sprint, Float), **Shift+LMB/RMB** = extra attacks (Fire Explosion, Healing Stream, Shuriken, Intercept), **MMB standing still** = class skill (Smash, Retreat, Kick, Teleport, Poison Vial), MMB moving = dodge. Stealth: +20% dmg, +50% crit at full, MP regen, slower in daylight. Mage MP regen passive, max 100, RMB costs 30. Ninjas lost stealth; Ninjutsu shurikens; Scout sprint ≈ mount speed, high jump ×2 (25 stamina).

---

## 4. Multiplayer

### 4.1 Alpha (2013) [C]
- Dedicated **`Server.exe`** shipped next to `Cube.exe`; run it, players "connect to server" from character screen (lower-right) with IP/DNS or `localhost`; TCP **port 12345** (not configurable); UDP not used by vanilla (PCGamingWiki lists tcp+udp 12345). Server console: type `q` to quit. Default world **seed 26879**; change by writing seed into **`server.cfg`** in the same directory. Server saves nothing per se: characters are client-side.
- Player cap: vanilla server **4 players** (NamuWiki: "up to 4 players due to balance"; cuwo default `max_players = 4`; "Disable Player Limit Mod" exists) — cubeworldwiki.net (Oct 2013) says "maximum of 10" **[?]**; 120-player modded servers existed; cuwo supports 40+.
- Protocol: TCP, 50 Hz server send/update rate (`network_fps = 50`, vanilla), zlib-compressed entity/world updates, client-authoritative movement/hits (hence anticheat scripts). Client sends `ClientVersion` (=3) → server `JoinPacket(entity_id)` + `SeedData(seed)` → client streams `EntityUpdate`; `ServerMismatch`/`ServerFull` on failure. Server relays entity updates, hits, shoots, chunk items, missions (8×8 per region), time (`CurrentTime day,time`, MAX_TIME = 24*60*60*1000 ms).
- Co-op only: shared world, shared mission XP (group XP bug fixed Jul 23 2013), items dropped on ground = trading. **No official PvP**; `/pvp` command listed on fandom as alpha slash cmd **[?]** (works "on some servers", i.e. modded/cuwo pvp script sets HOSTILE_FLAG). Chat: Enter; commands `/connect <addr>`, `/disconnect`, `/name <n>`, `/namepet <n>`; server indexes players (same names allowed). Known: pet levels don't save; high bandwidth.
- Server mods (coremaze): Server Mod Launcher, Chat Overallocation Fix, Ghost Damage Fix, MOTD, Disable Player Limit. Alternative servers: **cuwo** (Python/C++), **Berld** (Rust, tickless PvP alpha server). Server list sites: cubeworld-servers.com, cuwo master server (UDP JSON zlib, 10 s heartbeat).

### 4.2 Steam 1.0 [C]
- **No server executable, no IP join.** Steam-friends P2P: **J** opens multiplayer/friends widget (crashed w/ 14 friends until 0.9.1-6); invite/join friends; host instance. All players share the **same single world seed**, spawn at random positions; joining keeps you where you were → meet via **Flight Master** (free flights to friends; normal flights ≥100 coins). Friend in a third party's instance appears offline. PCGamingWiki: online co-op up to 10 **[?]**; local co-op via Nucleus hack.
- Co-op rules: artifacts lootable by all (0.9.1-4); ember per participant; other players' level shown on highlight (0.9.3-0); land-bound progression → "no difficulty scaling required". Emotes `/sit /wave /dance /pet`, `/namepet`. No PvP, no trading UI.

---

## 5. UI / HUD / controls

### 5.1 HUD (alpha) [W]
- Top-left: character head, name, level & class, HP, XP current/needed. Top-right: time, **temperature, humidity**, **3D rotating minimap** (tiles revealed by exploring; boss heads & quest givers shown), compass. Bottom-center: HP & MP bars, **hot bar** = M1 normal attack, M2 special, skills 1–4, Q quick item. Bottom-right: message log (~9 last item/XP messages). Stamina bar hidden until not full. Stealth bar (rogues/snipers). Pet HP/XP + hydration droplets. Land-name caption fades in on entering a land. Stun stars above heads. Chat window lower-left (multiplayer).
- Menus: Esc icon bar (each has a hotkey), F1 controls chart. Inventory (B/I): tabs Equipment / Items / Ingredients / Pets (+ coins shown in inventory); 13 equipment slots (`equipment[13]` in EntityData: slots 2–7 = shoulder?/chest/gloves/boots… hp-bearing are 2,3,4,5,6,7), consumable slot, 1 pet slot, special slot (glider/boat), lamp slot. Quick Select wheel (Tab; navigate with A/D; shows count). Skills window (X). Crafting (C): tabs Weapon/Armor/Amulet&Ring/Cooking/Alchemy/Ingredients. World map (M): zoomable/rotatable 3D voxel map + overview map (lands & levels colored), landmarks colored white/blue/red by relative power, missions as crossed swords, players as heads, villages always visible (alpha), unexplored = blue. Portals (teleport stones) open the map to click other discovered portals.
- Items: name affix + material + type + "+N" power; tooltip stats: Power, HP, Armor, Resi, Crit, Tempo (alpha)/Haste, Reg, Attack Power, Spell Power, Mana Regen; **sell price on tooltip** (removed 0.9.1-4). Rarity display selectable in Options (stars). Damage numbers float per hit; combo counter near cursor; **no target lock** (crosshair aiming since Mar 2012; lock-on existed Nov 2011 only).

### 5.2 HUD changes in 1.0 [W]
- Coin counter top-left; **key-item bar** top-left; left side: buff/debuff icons (e.g. mana pump debuff); help widget bottom-left (F1, default on for new chars since 0.9.3-0); Esc menu has help button. Inventory tabs: Equipment / Special (regional key items) / Items / Ingredients / Pets / Artifacts; per-region inventory paging; star ratings of armor & weapon at left. Map: full terrain colors visible even unexplored, white flashing border of current land, map markers via MMB (star), travel history, shrines as blue dots (click to teleport), completed missions get check marks. Minimap scalable separately (F5/F6), UI scale F2/F3, hide UI F4. Time-of-day, temp, humidity above map. Enemy name colors + optional stars; hostile adventurers show rarity colors, friendly = light blue name and wave.
- Character creation: 8 races × male/female; face, hair, hair color (Humans most options; Lizardmen scales, Frogmen eyes; invisible orc hairstyles removed 0.9.2-0); class (4); name; alpha also world seed entry/world selection & unlimited character slots; 1.0: no seed (single shared world). Race is cosmetic (Kotaku 2013; tester notes dwarves/goblins smaller hitbox, more knockback **[?]**).

### 5.3 Default keybinds
| Action | Alpha 0.1.x | Steam 1.0 |
|---|---|---|
| Move | WASD (A/D strafe) | WASD |
| Normal / Special attack | M1 / M2 | M1 / M2 |
| Dodge roll / zoom | M3 click (moving) / wheel | M3 (moving) / wheel; M3 standing = class skill |
| Jump | Space | Space (Shift+Space high jump for Scout/Ninja; Space while climbing = wall-flip) |
| Climb | hold **Ctrl** (falls when released) | **E** to grab (Steam guide) / Shift per fandom **[?]**; stays attached |
| Walk / free aim | Shift | Shift = class utility (sprint/sneak/cyclone/float) |
| Pick up / Interact | E pick up, **R** interact | **E** interact+pickup; **R** = special skill |
| Quick item / select | Q / Tab | Q / Tab |
| Special item (glider/boat) | **G** | E (contextual) |
| Lamp | F | F |
| Call/ride pet | T (R to ride) | T |
| Skills window | X | — (removed) |
| Crafting | C | C |
| Inventory | B or I | B |
| World map | M | M |
| Toggle HP bars | V | (option) |
| Friends/multiplayer | — | J |
| Chat | Enter | Enter |
| Menu / help | Esc / F1 | Esc / F1 |
| UI scale / hide / minimap scale | — | F2/F3, F4, F5/F6 |
| Debug MP refill | O (bug, removed Jul 5 2013) | — |
- Alpha: **no key remapping** (Wollay tweeted a rebind UI Nov 2013; never shipped); AutoHotkey suggested. 1.0: rebindable in options (saved since 0.9.1-4). Gamepad: Wollay "just added gamepad support" (Feb 2012 tweet), PCGamingWiki: does not work in alpha; Steam lists Partial Controller Support, FAQ says rebind via Steam Input **[?]**.

### 5.4 Options / graphics [W]
- Alpha options menu: FPS limit (default 111, added Jul 23 2013), invert Y axis (Jul 5 2013), camera speed (mouse sensitivity), resolution/windowed, render distance, rarity display, volume. `options.cfg` in game folder (alpha & Steam): e.g. `antiAliasingSamples 8` (1 to disable), render distance (community suggests 5 for perf), resolution. Steam: view distance, AA, shadows **[?]** (Steam guide title "Improving Shadows, Draw Distance" exists, not fetched), music loop, camera speed, FOV via scroll zoom only, no vsync option, no borderless (PCGamingWiki). Alpha API DirectX 9 / Shader Model 3.0, 32-bit exe; Steam requires DirectX 11, 64-bit Win 8.1/10.

---

## 6. Persistence / save data
- Alpha: saves in game dir `Save\` (PCGamingWiki `{game}\Save`); `characters.db` (SQLite, table `blobs(key TEXT PRIMARY KEY, value BLOB)`, keys "0","1","2"… per slot, binary blob = EntityData-like serialized character) and per-world `world.db` (alpha) / `world.db` (Steam) **[W]**. Game assets in `data1.db`/`data2.db` (SQLite) holding `.cub` models etc.; model mods replace `data1.db`. Character editors (DatZach CharacterEditor, cwmods) edit level/XP/race/gender/class/items.
- Alpha: characters are independent of worlds — any character enters any world (seed-based); world seed entered at world creation; same seed = same world; terrain generated on the fly, no big save files; explored map recorded per world ("regions discovered accounted for by every player that visited that map"). Gear travels across worlds. Steam: one fixed shared seed, random spawn; Steam Cloud listed (status unknown). Old alpha saves incompatible with 1.0.
- cuwo server saves only ban info etc. in `./save`.

---

## 7. Movement, camera, time, weather
- Camera: third person, mouse-wheel zoom; zooming fully in = first-person (2011 devlog; not explicitly documented for 1.0 **[?]**). Sniper Aim zooms the view. Map: rotate LMB, pan RMB.
- Walk (Shift, alpha), run default, **sprint** (Scout/Ninja Shift, stamina). Jump: tap = short hop, hold = max; mid-air steering. Fall damage exists (float/teleport/glider negate; roll avoids). Wall-jump/flip while climbing (costs stamina since 0.9.1-3).
- **Climbing**: any vertical surface, sideways allowed, no overhangs; stamina drains; pause drains nothing (alpha); jump-grab and fall-catch; alpha Ctrl hold; 1.0 Climbing Spikes = infinite stamina climbing. Pets/mages: mage Float (Shift) cancels fall, Shift+Space "super float" ~15 blocks.
- **Hang glider**: special slot item (alpha, bought from item shop, needs Climbing 5 / Hang Gliding point) / regional key item (1.0). G (alpha) / E (1.0) toggles; sinks progressively faster; Space levels off (stamina); cannot redeploy midair; attacking closes it; hitting anything = dizzy + fall. 1.0 hang glider widely called worse ("now sucks" – Kotaku).
- **Swimming**: all classes; alpha no drowning, infinite breath; 1.0 **diving stamina** → HP loss when empty (heal to stay under; hold a wall to stop depletion); cold water slows (Hot Chocolate counters), toxic water poisons (Green Smoothie), lava (Lemonade).
- **Boat**: alpha: shop item, needs Swimming 5 → Sailing; 1.0: regional key item. Deploys only in swim-deep water; rises if underwater.
- **Riding**: alpha: Pet Master 5 → Riding, ride with R, pets keep riding in water, **hydration** meter (droplets under pet HP) drains while riding, refills in any water; 1.0: Reins key item, T to mount, dismount on attack/dodge/fall/water; speed via artifacts. Alpha pets had XP/levels (didn't save in MP).
- **Dodge**: MMB while moving, i-frames, 25% stamina (5 rolls if regen allows), dismounts.
- **Time**: 1 game min ≈ 6 real s (cuwo `NORMAL_TIME_SPEED = 10`): full day = **2 h 24 min** (144 min). Sleep speeds clock (`SLEEP_TIME_SPEED = 100` → ~2 game min/s). Midnight reset: monsters respawn, missions regenerate, deposits respawn; inn (6 PM–6 AM) → 7:00 AM, 10 coins in 1.0 (free alpha). Days counted (`CurrentTime.day`). Nights very dark; lanterns/candles/shimmer mushrooms/fire mage glow.
- **Weather/climate**: temperature & humidity per location determine biome and shown in HUD; 1.0 conditional effects (cold water slow). No rain/snow in alpha/1.0 — added in Omega. Alpha lighting: sky/daylight affects stealth; cloud shadows unknown; moving clouds a mod in alpha, native in Omega.

---

## 8. Audio
- Composer: **Wollay (Wolfram von Funck)** — "Coder, Designer, Composer" (picroma team page); SoundCloud `wol_lay`. Known tracks: "Cube World: Explorers" (2013 video theme, first OST track), "New Lands", "Awakening", "Cube World: Druids of Mana" (2015-10-04, 1:58), "Cube World: The Steel Empire" (2015-10-05), "Cube World: Order of the Light" (2015-10-06), "Bgum" (dungeon track, 2016-08-21 **[?]**), Omega tracks (2023). Gamerip of 2019 build exists (khinsider) — track list not retrieved.
- 1.0: music loop option (0.9.1-4); separate volume sliders; xAudio2 (Win7 incompatible); subtitles yes.
- Alpha SFX ids (cuwo SOUND_NAMES, 0–95+): hit, blade1/2, long-blade1/2, punch1/2, hit-arrow(-critical), smash1, slam-ground, swing(-slow), shield-swing, arrow-destroy, salvo2, block, shield-slam, roll, destroy2, cry, levelup2, missioncomplete, water-splash01, step2, step-water1-3, channel2/hit, fireball, fire-hit, magic02, lich-scream, drink2, pickup, disenchant2, upgrade2, swirl, human-voice01/02, gate, spike-trap, fire-trap, lever, charge2, drop(-coin/-item), race groans (male/female × human/goblin/lizard/dwarf/orc/undead/frogman), monster/troll/mole/slime/zombie groans, Explosion, menu-open2/close2/select/tab/grab-item/drop-item, craft, craft-proc, absorb, manashield, bulwark, bird1/2… Races have different voices.

---

## 9. Tech

### 9.1 Engine / renderer [C]
- Custom **C++** engine; **DirectX** (OpenGL in the very first 2011 version); alpha = DX9, SM 3.0, 32-bit, XP SP2+; min GPU GeForce 7800 / Radeon X1800 / Intel HD 3000, 256 MB VRAM; 150 MB disk (alpha) / 206 MB (Steam wiki) / 500 MB (store). 1.0 = DirectX 11, 64-bit, Win 8.1/10; min GTX 660 / R9 285, 2 GB RAM. Engine rewritten Aug 2011 and again for 2.0 (2013–2019); Omega = new Vulkan engine.
- GUI built from **Plasma** vector graphics (.plx e.g. `icons.plx`, `dict_en.xml` localization). Plasma had a custom VM/obfuscated UI file (coremaze Plasma-Writeup).
- Voxel models: own editor; **.cub format**: header 3×uint32 (x,y,z size) then x*y*z RGB bytes (z-major loop `for z: for y: for x`), black (0,0,0) = empty (cuwo `cub.py`). 2,552 model names in alpha (`MODEL_NAMES`, e.g. body2, head2, goblin-head-m01, troll-*, golem-ember-*). Largest sprite: Steel Empire airship 1,313 KB (1.0). Animation: rigid voxel parts (head/hair/hand/foot/body/tail/shoulder/wing models with per-part scale, offset, pitch/roll/yaw in `AppearanceData`) — skeletal by parts, not per-voxel bones. Characters can't close eyes.
- Terrain: procedural, generated on the fly; alpha block = 5-bit type + flags: 0 empty, 1 solid, 2 water, 3 flat water (walkable), 4 grass, 5 field/cliff, 6 rock/buildings, 7 wood, 8 leaf, 9 sand, 10 snow, 11 solid2, 12 lava floor, 13 solid3, 14 roof, 15 solid4; bit for "breakable by bombs/bosses" (destroyed terrain regenerates ~3 game days). Coordinates: `BLOCK_SCALE = 0x10000` (16.16 fixed), **zone (chunk) = 256 blocks**, **region = 64 zones = 16,384 blocks**, world = **1024×1024 regions** (finite, not infinite; Wollay's House at 0,0), **8×8 missions per region**, `MISSION_SCALE = REGION/8`. Client generates region data in a 3×3 region neighborhood and seeds in 7×7 (cuwo world.py). Static entity types (0–77): Statue, Door, BigDoor, Window, Gate, FireTrap, SpikeTrap, StompTrap, Lever, Chest, tables/stools/bench/bed, market stands, barrels/crates/sacks, shelves, Corpse, RuneStone, **Artifact**(46), flower boxes, street lights, fences, vases, Campfire, Tent, BeachUmbrella/Towel, SleepingMat, Furnace, Anvil, SpinningWheel, Loom, SawBench, Workbench, CustomizationBench. City quarters: Trade, Crafting, Class, Pet; Portal; Palace.
- AI: A* pathfinding with climbing, NPC schedules (2012 devlog). Performance: alpha single-threaded terrain gen (community mod: multithreaded terrain, stutter fix); 1.0 reduces refresh in background.

### 9.2 Netcode / data structures (cuwo reverse-engineering, alpha 0.1.1) [C]
Source: https://github.com/matpow2/cuwo (`cuwo/packet.py`, `entity.pyx`, `constants.py`, `tgen_wrap.pxd`, `tools/tgen.h`); wiki https://github.com/matpow2/cuwo/wiki. Contributors: matpow2 (Mathias Kærlev), Sarcen (protocol), ChrisMiuchiz, Favorlock, Lord_Nightmare (terraingen), UserXXX (block types).
- Packet framing: uint32 packet id then body. **Client→Server**: 0 EntityUpdate (uint64 entity_id + zlib-compressed masked EntityData), 6 InteractPacket (item_data, chunk_x/y int32, item_index int32, interact_type uint8: 2 NPC, 3 normal, 5 pickup, 6 drop, 8 examine), 7 HitPacket (entity_id, target_id, damage float, critical u8, stun_duration, pos, hit_dir, hit_type u8: 0 normal, 1 block, 3 miss, 5 absorb), 8 PassivePacket (entity, target, passive_type), 9 ShootPacket (entity_id, chunk_x/y, pos qvec3, velocity vec3, skill, projectile u32, mana, scale), 10 ClientChatMessage (UTF-16LE), 11 ChunkDiscovered (x,y), 12 SectorDiscovered, 17 ClientVersion (u32). **Server→Client**: 0 EntityUpdate, 1 MultipleEntityUpdate, 2 UpdateFinished, 3 AirshipUpdate (unused but supported), 4 ServerUpdate (zlib: block_actions, player_hits, particles, sound_actions, shoot_actions, static_entities, chunk_items, items_8, pickups, kill_actions, damage_actions, passive_actions, missions), 5 CurrentTime (day, time), 10 ServerChatMessage (entity_id 0 = server), 15 SeedData (u32), 16 JoinPacket (entity_id + EntityData), 17 ServerMismatch, 18 ServerFull.
- **EntityData** (order): pos qvec3(int64), body_roll/pitch/yaw f32, velocity, accel, extra_vel vec3, look_pitch, physics_flags u32, hostile_type u8 (0 friendly player, 1 hostile, 2 friendly, 3 named friendly, 6 target), entity_type u32 (0 ElfMale … 16 UndeadFemale, 17 Skeleton, … 155 Blowfish; 0–16 = the 8 races ×2), current_mode u8, mode_start_time, hit_counter, last_hit_time, **AppearanceData**, flags u16 (bit0 climbing, bit2 attacking, bit4 glider, bit5 hostile, bit9 lantern, bit10 stealth), roll_time, stun_time i32, slowed_time, make_blue_time, speed_up_time, show_patch_time f32, class_type u8, specialization u8, charged_mp f32, 6 unused u32, ray_hit vec3, hp f32, mp f32, block_power f32, max_hp_multiplier (100), shoot_speed, damage_multiplier, armor_multiplier, resi_multiplier, level i32, current_xp i32, parent_owner u64, unknown×2, power_base u8, unknown i32, start_chunk ivec3, super_weird u32, spawn_pos qvec3, not_used19 u8, not_used20 ivec3, consumable ItemData, **equipment ItemData[13]**, **skills u32[11]**, mana_cubes u32, name char[16] ASCII. 48-bit update mask (bits listed in entity.pyx, e.g. 0 pos, 27 hp, 33 level, 34 xp, 44 equipment, 45 name, 46 skill, 47 mana_cubes).
- **ItemData** (88 bytes): type u8, sub_type u8, modifier u32 (seed for stats/name), minus_modifier u32, rarity u8 (0–4/5), material u8 (1 Iron, 2 Wood, 5 Obsidian, 7 Bone, 11 Gold, 12 Silver, 13 Emerald, 14 Sapphire, 15 Ruby, 16 Diamond, 17 Sandstone, 18 Saurian, 19 Parrot, 20 Mammoth, 21 Plant, 22 Ice, 23 Licht, 24 Glass, 25 Silk, 26 Linen, 27 Cotton, 128–131 spirits), flags u8, level i16, **32 ItemUpgrade slots** (x,y,z,material i8 + level i32 = the placed cubes), upgrade_count u32. Item types: 1 consumables (Cookie, LifePotion, CactusPotion, ManaPotion, GinsengSoup, SnowBerryMash, MushroomSpit, Bomb, PineappleSlice, PumpkinMuffin), 2 Formula, 3 weapons (0 Sword,1 Axe,2 Mace,3 Dagger,4 Fist,5 Longsword,6 Bow,7 Crossbow,8 Boomerang,9 Arrow,10 Staff,11 Wand,12 Bracelet,13 Shield,14 Arrows,15 Greatsword,16 Greataxe,17 Greatmace,20 Torch), 4 ChestArmor, 5 Gloves, 6 Boots, 7 ShoulderArmor, 8 Amulet, 9 Ring, 11 materials (Nugget, Log, Feather, Horn, Claw, Fiber, Cobweb, Hair, Crystal, Yarn, Cube, Capsule, Flask, Orb, Spirit, Mushroom, Pumpkin, Pineapple, RadishSlice, ShimmerMushroom, GinsengRoot, OnionSlice, Heartflower, PricklyPear, FrozenHeartflower, Soulflower, WaterFlask, SnowBerry), 12 Coin, 13 PlatinumCoin, 14 Leftovers, 15 Beak, 16 Painting, 18 Candle, 19 Pet, 20 Bait/pet food (~100 subtypes), 21 Amulet1/2, JewelCase, Key, Medicine, Antivenom, BandAid, Crutch, Bandage, Salve, 23 HangGlider/Boat, 24 Lamp, 25 ManaCube.
- **AppearanceData**: hair RGB, flags u16 (0x200 = double scale), scale vec3, head/hair/hand/foot/body/tail/shoulder2/wing model i16, per-part scales (head, body, hand, foot, shoulder2, weapon, tail, shoulder, wing), body/arm/feet/wing/back pitch, arm roll/yaw, per-part offsets.
- **ChunkItemData**: ItemData + pos qvec3 + rotation f32 + scale f32 + drop_time u32. **StaticEntityHeader**: entity_type u32, pos qvec3, orientation u32 (0 S,1 E,2 N,3 W), size vec3, closed u8, time_offset u32, user_id u64 (sitter). Spawn struct (4336 bytes) per zone with hostile_type, entity_type, class, spec, level, power_base, appearance, 13 items, multipliers, name[16].
- Consumable heal: `item_base_hp(level, rarity) * 200`. Chat only displays ASCII 32–126. Name filter regex length 2–16.
- cuwo server: Python 3.6+/Cython, scripts (log, ddos, commands, welcome, ban, console, master, anticheat, pvp, ctf, irc, discord), commands `/player /pm /server /who /whowhere /whereis /login /say /kick /setclock /ban /unban /kill /stun /heal`; anticheat caps level 1000, rarity 4, glider abuse, cooldown, hit distance, air time 10 s; MITM proxy tool; `convertqmo` .cub→Qubicle .qmo; map viewer; `tgen` = wrapped original terrain-generator code from the client executable (runs the game's x86 routines).

### 9.3 Modding scene
- Alpha: **Cube World Mod Launcher** (ChrisMiuchiz/coremaze; DLL mods in `/Mods`, server mods in `/Server_Mods`); mods: building, commands, PvP, multithreaded terrain gen, stutter fix, unlimited stacks, moving clouds, GUID/item-id crash fixes; **cuwo**, Berld servers; model tools **CWME** (Cube World Model Editor), MagicaVoxel + **Vox2Cub**, Cub2Obj, Voxelizer, Plasma; character/item editors; sites cwmods.com, GameBanana (game 5200), paroyer.github.io/ModCatalogue, RhyjtheDragon Cube-World-Alpha archive (Dropbox), archive.org "CubeWorldAlpha" / "cube-world-alpha-nosave-nolauncher". Known bug: `torch-red.cub` referenced as `torch-read.cub`.
- 1.0: no Workshop/mod support, no dedicated server; community DLL mods exist (Steam guide "Modding guide for Cube World (Alpha & Release)", id 2995492020 — not fetched). No CWSRestAPI found.

---

## 10. Reception & criticisms (what fans want fixed)
- Alpha (2013): praised — RPS "compulsion loop", "exquisite landscapes"; Hardcore Gamer; criticism: shallow combat/crafting, random enemy scaling, grind, no fast travel, "starts very hard", DDoS launch, then 6 years silence → vaporware reputation; RPS 2011 "Cube World looks chunky"; Jan 2012 false Mojang-hire report.
- 1.0 (2019): Steam "Mostly Negative"; Metacritic user 2.5/10 (64 ratings), GameStar 48/100 ("half-cooked… less content than six years ago"); Kotaku (Plunkett) "badly in need of a tutorial", "somehow worse than its alpha", levelling gone, region-locked equipment, hang glider "now sucks", basic combat; PC Gamer "shallow, boring, repetitive"; Hardcore Gamer 3.5/5; Steam review guides: "masterclass in aesthetics", OST "absolute joy", but progression "hollow/inconsequential", "punishes winning", ~8–10 h fun per biome then "dreary"; Into the Blue Sky: vertical progression resets at every border (≈1000 HP → <200), + gear RNG-gated, tactics variety lacking, hornets deadlier than color suggests, leading enemies to NPCs is optimal.
- Recurring fix requests: keep gear across borders or make + gear global; artifacts should affect combat stats; bring back XP/levels/skill trees & skill points; return alpha ninja shurikens/stealth, Spirit cubes, Adaptation; hang glider/boat/climbing spikes global; tutorial/help; dedicated servers & IP join; controller support; mod support; alpha-style ocean monsters & infinite breath; lore-hunting tedium; Water Mage overpowered, enemy mages ("hitscan lasers") overtuned, stunlock; region borders punish exploration; inconsistent enemy chase; pets weak. Positives kept: map, exploration, movement, aesthetics, seamless co-op with no scaling needed.

---

## 11. Gaps / not found
- Exact 1.0.0-1 (Oct 1 2019) patch notes; exact version numbers of the two 2013 alpha patches (0.1.0 hotfix vs 0.1.1 assumed).
- Full 1.0 options menu list (shadows/view distance names) and full soundtrack tracklist.
- Steam save path (PCGamingWiki says `{game}\Save`; may be alpha-era info) and world.db schema.
- Alpha per-skill numeric bonuses (X% values), full skill tree screenshot layout, respec rules.
- Omega status 2024–2026 (blog silent since Oct 2023; UE5 rumor unverified); pricing/free-upgrade policy.
- Controller support actual behavior in 1.0; first-person camera in 1.0.

---

## 12. Source URLs
- Wikipedia: https://en.wikipedia.org/wiki/Cube_World
- Fandom wiki (wikitext via api.php): https://cubeworld.fandom.com/wiki/Patch_Notes/Versions , /wiki/0.9.1-3 … /wiki/0.9.3-0 , /wiki/Patch_Notes/Manifests , /wiki/July_5th,_2013 , /wiki/July_23rd,_2013 , /wiki/Controls , /wiki/User_interface , /wiki/Inventory , /wiki/Quick_Select , /wiki/Minimap , /wiki/World_Map , /wiki/Slash_Commands , /wiki/Multiplayer , /wiki/Skills , /wiki/Skill_Points , /wiki/Levels , /wiki/Power_Level , /wiki/Specialization , /wiki/Stats , /wiki/Stamina , /wiki/Mana , /wiki/Rarity , /wiki/Mob_Strength , /wiki/Artifacts , /wiki/Relic , /wiki/Region , /wiki/Time , /wiki/Sleep , /wiki/Diving , /wiki/Swimming , /wiki/Climbing , /wiki/Hang_Gliding , /wiki/Sailing , /wiki/Dodge , /wiki/Riding , /wiki/Abilities , /wiki/Key_Items , /wiki/Portals , /wiki/Flight_Master , /wiki/Resurrection_Statue , /wiki/Shrine , /wiki/Adaptation , /wiki/Spirit_Cube , /wiki/Crafting , /wiki/Coins , /wiki/Gnome_Supplier , /wiki/Book_of_Crafting , /wiki/Circle_of_power , /wiki/Arena , /wiki/Magic_Barrier , /wiki/Demon_Portal , /wiki/Mana_Pump , /wiki/Steel_Empire , /wiki/Cities , /wiki/Races , /wiki/Stealth , /wiki/Wollay's_House , /wiki/Cube_World , /wiki/Picroma , /wiki/Warrior , /wiki/Rogue , /wiki/Ranger , /wiki/Mage , /wiki/How_to_play_guide_for_Cube_World
- Wollay devlog (Wayback): http://web.archive.org/web/2014/http://wollay.blogspot.com/2011_06_01_archive.html (… 2013_05); 2019 letter: https://wollay.blogspot.com/2019/09/dear-cube-world-community-i-think-this.html (snapshot 20190930)
- Picroma feature page 2013 (Wayback): http://web.archive.org/web/2013/http://picroma.com/cubeworld
- Alpha-era wiki (Wayback): http://web.archive.org/web/20180219093342/http://www.cubeworldwiki.net/index.php/Multiplayer ; /index.php/Controls ; Main_Page (2015)
- Wollay's blog (Omega): https://wollay.com/ , https://wollay.com/feed/ , https://wollay.com/2023/05/25/new-blog-and-new-project-cube-world-omega/
- Omega coverage: https://massivelyop.com/2023/05/26/cube-world-creator-emerges-from-hibernation-to-announce-cube-world-omega/ , https://cubeworld-servers.com/blog/22/cube-world-omega/ , https://steamcommunity.com/app/1128000/discussions/0/3843304884851807866/ , https://steamcommunity.com/app/1128000/discussions/0/6393480947854971437/
- cuwo: https://github.com/matpow2/cuwo , https://github.com/matpow2/cuwo/wiki , https://mp2.dk/cuwo/ (files: cuwo/packet.py, cuwo/entity.pyx, cuwo/constants.py, cuwo/strings.py, cuwo/common.py, cuwo/world.py, cuwo/tgen.pyx, cuwo/tgen_wrap.pxd, cuwo/cub.py, tools/tgen.h, config/base.py, config/anticheat.py, scripts/*)
- Steam: store API https://store.steampowered.com/api/appdetails?appids=1128000 ; news API https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=1128000 ; guides https://steamcommunity.com/sharedfiles/filedetails/?id=1871883807 (How to Actually Do Things), ?id=1871398574 (Darkmega Ultimate Guide), ?id=1870746373 (Important Changes from Alpha), ?id=1876780614 (Comprehensive Review), ?id=2995492020 (Modding guide) ; threads: 1628538707070147367 (0.9.3-0 notes by pixxie), 1633040337758299546 (release FAQ), 1626286205712019012 (save files), 1628539187777596022 (Berserker vs Guardian), 1628538707074585623 / 1626286205708293357 / 1628538707074634126 (region lock complaints)
- PCGamingWiki: https://www.pcgamingwiki.com/wiki/Cube_World
- Kotaku: https://kotaku.com/tips-for-playing-the-cube-world-alpha-885739884 , https://kotaku.com/cube-world-wasnt-worth-the-wait-1838609411 , https://kotaku.com/the-current-status-of-cube-world-and-why-fans-are-worr-1449026160
- Eurogamer/RPS (via Steam news feed): eurogamer.net/articles/2019-09-06-…, 2019-09-07-…, 2019-09-17-…, 2019-09-20-…; rockpapershotgun.com/2019/09/23/wait-what-cube-world-is-coming-out/
- Reviews/analysis: https://www.metacritic.com/game/cube-world-2019/ , https://gamesline.net/so-whats-up-with-cube-world/ , https://intothebluesky.com/2019/09/28/square-block-round-hole/ , https://rpgwatch.com/news/cube-world--review-hardcore-gamer-43120.html , https://hardcoregamer.com/previews/wandering-the-land-in-cube-worlds-alpha/52851/
- NamuWiki: https://en.namu.wiki/w/Cube%20World
- Modding: https://paroyer.github.io/ModCatalogue/Alpha.html , https://paroyer.github.io/ModCatalogue/Mods/Models.html , https://github.com/coremaze/Plasma-Writeup , https://github.com/coremaze/Cube-World-Server-Mod-Launcher , https://www.cwmods.com/ , https://github.com/ScottishCyclops/cub-to-obj , https://github.com/RhyjtheDragon/Cube-World-Alpha , https://cubeworld-servers.com/servers/tutorial/
- Other: https://www.gamepressure.com/cubeworld/controls-and-key-bindings/zcca5c , https://screenrant.com/evel-up-fast-cube-world-guide/ , https://www.gamepur.com/guides/cube-world-races , https://www.gameskinny.com/tips/cube-world-running-your-processor-hot-limit-your-fps/ , https://cubeworld-servers.com/blog/3/new-cube-world-update/
