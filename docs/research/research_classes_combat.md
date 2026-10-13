# Cube World — Player Character, Classes, Combat, Stats (research dump)

Scope: Alpha 0.1.x (July 2013), Steam 0.9.x beta → 1.0 (Sept 23–30 2019, 1.0.0 = 30 Sept 2019), Cube World Omega (announced 25 May 2023, in development 2023–2026).
Notation: **[A]** = alpha-only, **[S]** = Steam 1.0-only, **[A+S]** = both, **[Ω]** = Omega. `?` = uncertain / single-source / conflicting.

Primary sources (abbreviated in text):
- FW = cubeworld.fandom.com wiki (page names given; pulled via api.php wikitext)
- CWcom = https://www.cubeworld.com/ (official Picroma feature page, 2019/2020)
- G1 = Steam guide "How to Actually Do Things and Not Die" (freEd, Oct 2019) https://steamcommunity.com/sharedfiles/filedetails/?id=1871883807
- G2 = Steam guide "Darkmega's Ultimate Cubeworld Guide" (2019) https://steamcommunity.com/sharedfiles/filedetails/?id=1871398574
- G3 = Steam guide "Important Changes from Alpha (FOR OLD PLAYERS)" https://steamcommunity.com/sharedfiles/filedetails/?id=1870746373
- SAH = SteamAH "Basic Specialization Guide" https://steamah.com/cube-world-basic-specialization-guide/
- GP = gamepressure Cube World guide (alpha era) https://www.gamepressure.com/cubeworld/ (warrior/zd5260, rogue/z05263, mage/ze5261, ranger/zf5262, class-specific-skills/ze526a, non-class-specific-skills/z65269, races/z1525e, initial-gameplay/z0526c)
- CWC = Cube World Central (alpha, 2013) https://sites.google.com/site/cubeworldcentral/classes/warrior , /rogue
- NAMU = https://en.namu.wiki/w/Cube%20World
- cuwo = open-source alpha server, https://github.com/matpow2/cuwo (cuwo/constants.py, cuwo/entity.pyx, cuwo/strings.py)
- GN = GamersNexus "Everything we know about Cube World" (11 Nov 2012) https://gamersnexus.net/gg/962-everything-about-cube-world
- DSO = dsogaming 31 Jan 2012 combat rework https://www.dsogaming.com/news/new-cube-world-footage-shows-off-the-games-new-combat-system/
- Wollay blog (Omega) https://wollay.com/ ; announcement https://wollay.com/2023/05/25/new-blog-and-new-project-cube-world-omega/
- Steam threads: patch 0.9.3-0 https://steamcommunity.com/app/1128000/discussions/0/1628538707070147367/ ; "Class skills" https://steamcommunity.com/app/1128000/discussions/0/1626286205712090547/ ; "Berseker or Guardian" https://steamcommunity.com/app/1128000/discussions/0/1628539187777596022/ ; "Gear Stat Threshold" https://steamcommunity.com/app/1128000/discussions/0/1628538644183483666/ ; "What the hell happened to ninja" https://steamcommunity.com/app/1128000/discussions/0/1628538707064581348/ ; "Where is skills and levels system?" https://steamcommunity.com/app/1128000/discussions/0/1628539187758982146/
- ITBS = intothebluesky.com review 28 Sep 2019 https://intothebluesky.com/2019/09/28/square-block-round-hole/
- Kotaku alpha tips https://kotaku.com/tips-for-playing-the-cube-world-alpha-885739884
- HCG = hardcoregamer review https://hardcoregamer.com/reviews/review-cube-world/358830/
- Gist "Cube World Alpha – Extras" https://gist.github.com/Oifan/a83b6956f8f6774c1400a6d9001ef70d
- PyroProgression mod README https://github.com/thetrueoneshots/PyroProgression/blob/master/README.md

---

## 1. Races & character creation

### 1.1 The 8 races [A+S+Ω]
Human, Elf, Dwarf, Goblin, Lizardman (wiki: "Lizard"), Orc, Undead (skeleton), Frogman. All 8 can be any class. (FW Races; CWcom; Wollay blog 13 Jun 2023 confirms same 8 for Omega.)
- 2012 pre-alpha: only Human, Orc, Elf, Dwarf announced (GN, Nov 2012). The other four were added before the July 2013 alpha.
- Gender: male/female for every race (FW race pages have Male/Female gallery images; GP races).
- **No racial stats/traits** (GP races: "purely cosmetic"; NAMU: "no racial traits yet"). NAMU anecdote `?`: dwarves/goblins have smaller hitbox but take more knockback; low weapon position limits downward aim for ranged classes (community tester claim, unverified).
- Dwarf & Goblin: small; "can fit through small openings such as windows" (FW Dwarf, Goblin). Orc: physically largest race; Bloodaxe Clan = purple, larger NPC orcs (FW Orc). Frogman: no hair; hair-style selector cycles eye variants instead (FW Frogman). Lizard: "limited customization". Human: most options. Male dwarves always bearded, female dwarves have braids (FW Dwarf). Human males can have optional beards (GP). Female lizards have eyelashes; female orcs larger jaws (GP).
- Steam patch 0.9.2-0 (28 Sep 2019): "Removed invisible orc hairstyles from character creation."

### 1.2 Creation options
Choose: race, gender, class (specialization is not chosen at creation — you spawn as the first spec: Berserker / Sniper / Fire / Assassin per G2), face ("head"), hair style, hair colour, name. Skin colour selectable `?` (cuwo AppearanceData stores hair RGB only; body/head are model ids — skin tone appears to be baked into head/body model choice; not independently confirmed).
- Asset counts from the alpha model table (cuwo/strings.py MODEL_NAMES → counts of `<race>-hair-<m|f>NN` and `<race>-head-<m|f>NN`) — these are the shipped alpha assets and are a good proxy for creation options:

| Race | Hair M | Hair F | Head M | Head F |
|---|---|---|---|---|
| Human | 15 | 7 | 6 | 6 |
| Elf | 10 | 10 | 4 | 6 |
| Dwarf | 3 | 5 | 5 | 5 |
| Goblin | 6 | 6 | 5 | 5 |
| Lizard | 6 | 0 (none listed) | 2 | 5 |
| Orc | 10 | 4 | 4 | 5 |
| Undead | 6 | 6 | 6 | 6 |
| Frogman | 5 ("hair" = eyes) | 4 | 5 | 4 |
| (NPC-only Merman/Mermaid) | 3 | 3 | 3 | 3 |

- Hair colour: free RGB in data (uint8 r,g,b in AppearanceData; cuwo entity.pyx) — in-game UI presents a palette `?` (count unknown).
- Alpha starting kit: class weapons + a Gold Ring and a Silver Ring (FW Ring). Steam starting kit: 3 weapon sets for the class (one of each weapon type) + chest armour + 5 life potions; spawn at a Shrine of Life near a village (G2, GP initial-gameplay, FW 0.9.1-3 "New characters will spawn near villages").
- Alpha character data stored in `characters.db`; editors let you change name, class, level, specialization, race, gender (cwmods Character Editor).
- **[Ω]** All races/NPCs/pets procedurally generated (no hand-modelled parts), variable facial expressions (angry/neutral/sad/sleeping/surprised); Undead still needed custom hairstyles (Wollay blog 26 May & 13 Jun 2023). "Procedural races" and UI overhaul reported May 2026 (evergameday summary, secondary).

---

## 2. Classes overview

| Class | Alpha/Steam armour | Weapons (3 types) | Specializations | cuwo ids |
|---|---|---|---|---|
| Warrior | Iron (heavy) | 1H sword/axe/mace (dual-wield or +shield); 2H greatsword/greataxe/greatmace | Berserker (0), Guardian (1) | class 1 |
| Ranger | Linen (medium) | Bow, Crossbow, Boomerang (all 2H) | Sniper (0), Scout (1) | class 2 |
| Mage | Silk (light) | Staff (2H), Wand (2H, held 1H), Bracelets (1H, dual) | Fire (0), Water (1) | class 3 |
| Rogue | Cotton (medium per CWcom / "light" per GP) | Dagger (1H), Fist (1H), Longsword (2H) | Assassin (0), Ninja (1) | class 4 |

(FW Classes/Warrior/Ranger/Mage/Rogue; CWcom; cuwo constants.py. Mage referred to as "Spirit Mage" in 2012 (GN). A Paladin class was "mentioned as potential future addition" in 2012 (GN) — never shipped.)

- Rings/Amulets: all classes. Silver ring → Tempo, Gold ring → Crit; amulets give Crit + Tempo (FW Ring, Amulet).
- Pets: any class, one active (FW Pets).
- Unarmed: if main hand empty you punch; unarmed special = short roundhouse kick; mage unarmed = weak bracelet-like bolts (G2).
- Resource model (FW Mana; CWcom; G2): every class has HP, **MP** (0–100 `?` — G2 says mage max 100), **Stamina**. Warrior/Ranger/Rogue gain MP by *hitting* with basic attacks (warrior also by blocking; rogue/sniper via stealth; ninja via dodging); Mage regenerates MP passively. Special attack (M2) consumes MP; Warrior/Ranger/Mage *charge* it (hold M2, mana bar turns pink showing the MP that will be spent), Rogue fires instantly. Damage and stun/knockdown chance scale with MP spent.
- Changing specialization: **[A]** Adventurer District of a city, stand next to your class trainer, open skills [X], small coin fee (FW Ranger, Adventurer_District; Kotaku: full respec possible next to trainers). **[S]** talk to Guildmaster / class trainer in any village, free (G3; Steam thread "Berseker or Guardian": "anytime, any village, for free"; HCG). FW Classes says "small fee" `?` (alpha wording).

---

## 3. Alpha skill system [A]

- Levels via XP from monsters/bosses/missions (FW Experience, Levels). **2 skill points per level** (FW Levels, Skill_Points; gist Oifan). Skill window = [X]. Max level technically 2,147,483,647 (int32; FW Levels).
- Multiplayer: groups received too much XP for missions until 23 Jul 2013 patch (FW July_23rd,_2013).
- **Skill tree layout** (per class, FW skill pages + Abilities): three class-skill columns + three shared "ability" pairs. Each class skill: put points to unlock; **5 points in the previous skill unlock the next**; **1 point** in the first skill unlocks it. Points reduce cooldown and scale one effect.
  - Class column: Skill 1 (both specs) → Skill 2 (both specs, needs 5 in Skill 1) → Skill 3 (spec-specific, needs 5 in Skill 2). Gist: "five points to unlock each combat ability; by level 6 you have all basic combat skills" (2 pts/level × 5 levels = 10 pts = 5+5).
  - Shared abilities (FW Abilities, Pet_Master, Climbing, Swimming, Riding, Sailing, Hang_Gliding, GP non-class): **Pet Master** (+X% pet max HP per point) → 5 pts unlock **Riding** (+X% mount speed per point; ride with [R] near pet). **Climbing** (−X% stamina drain per point; climb with Ctrl, release = fall; holding Ctrl with no movement stops drain) → 5 pts unlock **Hang Gliding** (1st point enables Hang Glider item, further points + glide speed). **Swimming** (+X% swim speed) → 5 pts unlock **Sailing** (1st point enables Boat item, further points + boat speed). (GP lists Sailing as needing Climbing 5 — wiki says Swimming 5; FW is the majority.)
  - Hang Glider and Boat are *bought* from item vendors and equipped in the "Special" slot, toggled with [G] (FW Key_Items, Controls). Boat surfaces if deployed underwater. Hang glider: space to level off (costs stamina); putting it away mid-air = fall; attacking closes it; collision = dizzy + fall (FW Hang_Gliding).
  - Alpha hotkeys for class skills: keys **1–4** (FW Controls "1-4 Use Skill"); M1 normal, M2 special, M3 dodge, Ctrl climb, Shift walk/free-aim, Q quick item, Tab quick-select wheel, F lamp, G special item, T call pet, X skills, C crafting, V HP bars, B/I inventory, M map, R interact, E pick up.
- Exact per-point percentages were never published; the wiki uses "-X%"/"+X%" placeholders. `?`

Per-class alpha skills (FW Skills + individual pages; GP class-specific-skills; CWC):

**Warrior**: Smash (1) — jump to targeted spot within limited range, AoE damage + stun; points → cooldown. Cyclone (2) — telegraph then spin **5 s**, AoE damage; "extremely long cooldown, nearly a minute at low levels"; points → cooldown (GP/CWC: duration scales with points `?`). War Frenzy (3, Berserker) — charge special attacks faster for **10 s**, red tint; points → cooldown + charge rate. Bulwark (3, Guardian) — immune to stun + reduced damage for **10 s**, usable while stunned, red tint; points → cooldown + damage reduction. (Trivia: an older build had Intercept as warrior skill 1 and Smash as skill 2.)

**Ranger**: Kick (1) — roundhouse, knockback all melee-range enemies, can stun; points → cooldown + knockback. Retreat (2) — short backward jump (away from *cursor* direction); points → cooldown + distance; bugfix 23 Jul 2013: no longer increased hang-glide speed. Aim (3, Sniper) — lie prone, slowly enter stealth (purple bar); near-full bar = fast MP regen, +damage, +crit; cancelled by movement; crosshair changes; cooldown starts on use; points → cooldown + stealth entry speed (not MP regen). Scout's Swiftness (3, Scout) — +move & attack speed **10 s**, afterimage trail; points → cooldown + magnitude (not duration); multiplayer crash fixed 23 Jul 2013.

**Mage**: Fire Explosion (1, Fire) — self-centred explosion, burns, knocks back, chance to stun, screen shake; points → damage + knockback. Healing Stream (1, Water) — channel then heal large amount (targeted ally or self; "AoE in future" note; alpha M2 variant Shift+RMB heals at cursor); heal scales with weapon level; points → mana cost ↓. Mana Shield (2, both; needs 5 in skill 1) — instant, no animation, absorbs damage = % of player HP, lasts **30 s**; cooldown < duration even at 1 point (can be kept up permanently); fully absorbed hits apply no knockback; points → cooldown + absorb. Teleport (3? both) — short cast, move forward **~60 blocks** (`?` "needs verification"), blocked by solids, lands you safely on ground; **base cost 100 mana**; points → cooldown.

**Rogue**: Intercept (1) — dash to target location and perform your weapon special on nearby enemies; consumes MP (only skill that does). Sneak (2) — hold key: move slower, fill Stealth meter (faster when still; faster in darkness, slower in skylight/near lamps). Camouflage (3, Assassin) — instant full stealth, kept while moving and in combat ("invalidates Sneak"). Shuriken Attack (3, Ninja) — backflip away from cursor while throwing **5 shuriken** at where you aim; points → cooldown + stealth duration.

**Stealth resource** (FW Stealth): separate bar; up to **+20% attack power** and **+50% crit chance** proportional to fill; generates MP faster the fuller it is; decays quickly when not generated; does not itself slow movement. Sources: Sneak (Assassin/Sniper), Assassin dodges/specials (Way of the Shadows), Camouflage (instant max), alpha Aim.

Alpha spec passives (FW Warrior/Ranger/Rogue/Mage, GP): Berserker **Berserker Rage** — attack speed +X per hit, reset on miss (FW Berserker). Guardian **Toughness** +25% HP and **Barricade/"Elusiveness"** — block twice as long and with any weapon (GP). Sniper **Hit Series** — attack speed (and power `?`) up per consecutive hit. Scout **Intuition** — chance per shot to crit and to get a fully-charged power shot for free. Fire **Fire Spark** — chance to make next special instant & free. Water **Torrent** — attack speed up per hit (cap 20-hit streak per FW Mage). Assassin **Way of the Shadows** — each special increases stealth. Ninja **Counter Strike** — dodge everything during a special; **Elusiveness** — each dodged attack +25 MP and next special crits.

Alpha shared systems: dodge roll (M3 while moving, costs 25% stamina, i-frames vs most damage except spike traps and dagger poison; dismounts you; standing still = nothing) (FW Dodge). "Battle Spirit" gauge existed in an earlier pre-alpha build, absorbed into MP (NAMU footnote). Jan 2012 rework: "no more combo points but an energy bar called 'spirit'; each attack generates SP for a finishing move that depends on the weapon" (DSO) — this became MP/special attack.

---

## 4. Steam 1.0 skill kits [S] (all unlocked from the start; no skill points)

Common inputs (G1, G2, SAH, FW): **M1** basic; **M2** charged special (Rogue instant); **M3 while moving** = dodge roll (25 stamina); **M3 standing still** = class skill; **Shift (hold)** = class movement/utility skill; **Shift+M1 / Shift+M2 / Shift+Space** = extra skills; **R** = "Special"/ultimate on cooldown (FW Abilities says 40 s `?`, FW How-to-play says 30 s `?` — actual cooldowns are per skill, see below). **F1** shows the move list. Pressing E climbs (Steam) — you stay attached without holding (FW Abilities).

### Warrior [S]
- Weapons/combos (FW Warrior, G1, G2): 1H dual or 1H+shield = quick **2-hit** alternating combo (G1 says spin on 3rd hit `?`); 2H = slow **3-hit** combo (overhead → jab → uppercut with knockdown chance). Basic hits build MP. Special (M2): 2H "Crush" overhead (Berserker) / Guardian 2H = defensive stance then wide side-swipe; dual 1H = dual-blade spin moving forward, multi-hit; shield+1H = hold to **block** (blocking gains MP and charges the special), release = spin swipe. More MP spent → more damage & knockdown chance (FW Warrior).
- **Battle Fury** (passive, both specs): each hit ~**12–14 %** chance to proc; **8 s**; **50 % life steal** on all attacks, specials charge near-instantly; can refresh (FW Warrior). G2 says also reduces incoming damage `?`; SAH says "on critical hits, 7 s buff, ~50 % lifesteal" `?`; G1 "Rage … 50 % of damage dealt, 8 s".
- **Smash** — M3 standing still: leap to target, AoE, high stun chance; **100 stamina**; no cooldown.
- **Cyclone** — Shift (hold): spin, damage all nearby every **0.25 s** (Haste has no effect); blocks from all directions using Block Power, which *regenerates during Cyclone* (unlike shield block); **25 stamina to start + 25/s**; no cooldown; tap = 1 s channel. **Cyclone Jump** — Space during Cyclone: 25 stamina, launches high, auto-channels 1 s, cannot block during (FW Warrior). Patch 0.9.1-6 "reduced warriors ability to exploit shift right-click spam".
- **Berserker**: passive **Berserker Rage** — attack speed +per hit up to **69 %** (FW). **R = Rock Fist** — charge straight line, knock-up + stun all hit; **no cost, 20 s CD**; cancel with dodge/M2/Smash (FW Warrior, SAH, G2). (Alpha "War Frenzy" removed; Rock Fist had been previewed on Wollay's Twitter/Instagram.)
- **Guardian**: passives **Toughness** (+25 HP flat — "likely bug, should be 25 %" per FW) and **Elusiveness/Barricade** (Block Power doubled; block with any weapon incl. dual/2H). **R = Heroic Shout** — taunt all enemies within **5 m**, regen **50 % max HP over 10 s** to all allies in range incl. self; **no cost, 30 s CD**; taunted enemies tinted red (FW Warrior). SAH/Steam thread describe it as a short "take more damage" debuff `?` (conflict; FW + G1/G2 say heal/taunt).
- Blocking (G2, FW Shields, NAMU): shield users block by holding M2; successful block gives MP (FW Shields) — G2 says beta no longer gives bonus mana but charges special faster `?`; NAMU says Guardian block "fully restores MP" `?`. Block Power = separate depletable gauge (cuwo entity field `block_power`).

### Ranger [S]
- Weapons (G1, G2, GP): Bow M1 arrow (gravity arc); M2 volley of **4–5 arrows** (G1: 5, G2: 4), minor splash, stun chance; **30-hit** combo cap. Crossbow M1 bolt; M2 single heavy bolt (alpha patch 23 Jul 2013: only damages when charged); 30-hit cap. Boomerang M1 steerable by camera, multi-hit ticks (more hits the closer), returns; M2 throws **2** boomerangs, stun chance; **80-hit** combo cap; fastest combo builder, lowest per-hit (FW Boomerang, G2). Ammo unlimited (FW Bows).
- **Sniper**: passives — M2 charging builds Stealth; stealth generates MP, +crit; **Hit Series** attack speed per hit. **Shift = Sneak**. **M3 standing = Retreat** — backflip toward camera, **costs all stamina**, grants **max stealth**. **R = Shadow Shooter** — clone that mimics your shots for **30 s** (SAH; G2 says ~20 s `?`), same HP as you at spawn, deals a % of your damage; **60 s CD**; stats scale correctly since 0.9.1-4.
- **Scout**: passive **Intuition/"Rough Ranger"** — basic hits may proc a **30 s** buff: next M2 charges instantly (consumes all available MP). **Shift = Sprint** (stamina drain); **Shift+Space = High Jump** (~2× height, 25 stamina `?`). **M3 standing = Kick** — spinning kick, knockback, possible KO; **50 stamina**, no CD. **R = Quicksand Trap** — zone **~20 s** (G2: 15–20 s), enemies inside nearly immobilised and *have armor/resistance stripped* ("acts as if you've already built your combo"); **40 s CD** (SAH, G1, G2).
- Alpha Kick/Retreat/Aim/Scout's Swiftness removed as skill-tree skills; Kick and Retreat survive as spec M3 skills.

### Mage [S]
- MP regenerates passively to **100**; M2 costs **30 MP** (G2). All specials have limited range except bracelet bolts (longest). Placed tornados/beams stop if you roll (G2).
- Staff: M1 small swirl at cursor (~1 s charge), M2 big vortex (~2× charge), stun; **50-hit** combo cap; multi-hit. Wand: M1 hitscan beam (½ s), M2 thick continuous ray **10–12 hits**, can be turned slowly; **20-hit** cap; any tick hitting terrain breaks combo. Bracelets: M1 alternating bolts, no gravity, longest range; M2 large ball with splash, half charge time, reliable knockdown; **20-hit** cap; need two bracelets for even damage (FW Mage, G2). Alpha wand was "a spray of projectiles", beta made it a beam (G2).
- **Fire Mage**: passive **Fire Spark** — chance on M1 hit to buff (**30 s**): next M2 instant, 0 MP. **Shift+M1 = Fire Explosion** — spherical knockback around self, minor damage, stun chance, **50 MP**. **R = Fire Missiles** — **4** fireballs at cursor, each ≈**3× Spell Power**, big AoE, knockdowns, **0 MP, 40 s CD**. Fire spells light the area like a 2-star lantern (FW Mage).
- **Water Mage**: passives — every spell heals allies and leaves a blue healing puddle (puddles stack); **Torrent** attack speed per hit up to 20-hit streak. **Shift+M1 = Healing Stream (self/static)**, **Shift+M2 = Healing Stream at cursor**, ~**50 MP** (G1: "about half the MP bar"). **R = Bubbles** — **6–8** bubbles (SAH 8, G2 ~6) trail/stick to enemies, detonate on hit for damage + healing puddles; **30 s CD, 0 MP**; can stick to summoned pets (FW Mage).
- Shared: **Shift (hold) = Float/Hover** — no cost, resets fall damage; **Shift+Space = Super Float** ~**15 blocks** up (FW Mage) — fastest climber; spam Shift to stay airborne (bug). **M3 standing = Teleport** — to cursor, **full MP** (SAH/G2: 100 MP; G1 says "all stamina" `?`); 0.9.3-0 "teleport distance back to normal"; 0.9.2-0 no teleport through gates; 0.9.1-3 fixed float glitch. Alpha Mana Shield removed.

### Rogue [S]
- All weapon specials are instant on M2 and can be prefixed with Intercept. Fists: fastest, **50-hit** combo cap, M2 = roundhouse kick (knockdown + small stun). Daggers: M2 = **Ambush** stab, stun + **poison** (~**5 ticks over 5 s**, stacks; tick = original hit damage; crits carry into ticks); dodge roll does *not* avoid this poison (FW Dodge). Longsword: M2 = **Perforate** lunging stab **4–5 hits** (CWC: 3), wide, stun; **30-hit** cap. Right-hand weapon decides animation/special (G2). MP built by M1 hits (and shuriken).
- **Assassin**: passive **Way of the Shadows** — specials (and dodges) build Stealth; stealth: +damage, +crit, MP regen; full stealth = near-zero aggro. **Shift = Sneak** (stealth builds faster standing still/in shadow). **Shift+M2 = Intercept** — 25 stamina + all MP, dash to cursor then perform M2 (needs some MP). **M3 standing = Poison Vial** — throw arcing vial, green AoE poison; **costs all stamina**. **R = Camouflage** — full stealth **20 s** even while moving/attacking; **40 s CD**.
- **Ninja** (reworked, no stealth in Steam — Steam thread "What happened to ninja"): passives **Elusiveness/"Shadow Force"** — dodging an attack (i-frame roll or M2 counter) gives **+25 MP** and a **30 s** window where next M2 is a guaranteed crit; **Counter Strike/"Shadow Strike"** — you dodge all damage during your M2. **Shift = Ninja Run/Sprint** (stamina drain; ~mount speed). **Shift+Space = High Jump** (**25 stamina**, ~2×, acts as dodge). **Shift+M1 = Shuriken Toss** — **25 stamina** each (0.9.2-0 fix; SAH says 50 `?`), damage scales with weapon, gives MP, arcs. **Shift+M2 = Intercept**. **R = Ninjutsu** — **20 s**: M1 becomes free faster shuriken, M2 becomes Intercept, no stamina cost; **60 s CD** (SAH, G1, G2; Steam thread says 40 s `?`). Alpha Shuriken Attack (backflip + 5 shuriken) removed.
- Alpha glitch: Assassin with Elusiveness active could chain ~5 specials instantly (FW Mana). Alpha dev key "O" refilled MP (removed 5 Jul 2013 patch).

---

## 5. Shared abilities / traversal

| Ability | Alpha [A] | Steam [S] |
|---|---|---|
| Dodge roll | M3 while moving, 25 % stamina, i-frames (not vs spike traps / dagger poison), dismounts (FW Dodge). Up to 5 consecutive rolls if regen allows (FW Stamina). | same key; 25 stamina; "roll to dodge attacks and interrupt enemy combos" (CWcom). NAMU: dodges MP attacks too. |
| Jump | Space, tap = hop, hold = max; no i-frames (FW Jump) | same; wall-jump costs stamina (0.9.1-3) |
| Climbing | Ctrl, stamina drain reduced by skill points; no jumping off; can't pass overhangs | E to grab wall, stays attached; **Climbing Spikes** key item = infinite free climbing; wall-flip trick (G1) |
| Swimming/Diving | swim speed by points; **no drowning**, unlimited breath | swim speed & diving stamina via artifacts; **drowning** damages HP; healing while drowning extends; holding a wall underwater stops drain (FW Diving, How_to_play) |
| Sailing | Boat bought, needs Swimming 5, [G] | Boat key item per region, [E]; evaporates at region border (G2) |
| Hang Gliding | Glider bought, needs Climbing 5, [G]; Space to pull up (stamina) | Glider key item per region, [E]; eagle flight master drops you with a free glider (G2) |
| Riding | needs Pet Master 5; [R] near pet; pet hydration meter (refill in water) limits riding; pets don't dismount in water | **Reins** key item per region; **T** near pet; any attack/dodge/fall/Shift dismounts; pets dismount in water; speed via artifacts |
| Light | Iron Lamp item (rarity = brightness), [F] | built-in lantern on F; radius via artifacts |
| Pets | pet XP & levels, Pet Master HP % | pet strength = player gear rating (+ plus-gear, 0.9.3-0); dead pet revives ~1 min or re-equip |
| Sneak | Rogue skill tree | Assassin/Sniper Shift |
| Sprint | none (Shift = walk) | Scout/Ninja Shift |
| Fast travel | Portals (teleport stones, alpha only) | Shrines of Life (E to activate with flute; teleport between), Flight Master (min 100 coins; free to friends) |
| Respawn | auto to nearest Revival Statue (never far); press R | only to *activated* Shrine of Life (can be very far back); no penalty; boss HP resets unless shrine is close (FW Bosses) |

Fall damage exists in both; roll before landing negates it (Kotaku); mage float negates.

---

## 6. Stats

### 6.1 Stat list
Alpha equipment stats (FW Weapons/Armor): **Hit Points, Attack Power, Spell Power, Armor, Resistance, Critical, Haste, Tempo, Regeneration, Mana Regeneration** — "the only stats available". Steam character sheet (FW Stats): **Power, HP, Armor, Resi(stance), Crit, Haste (=Tempo in alpha), Reg(eneration), Weapon Rating, Armor Rating** (ratings = star tiers of equipped weapon/armor, shown left of inventory; G2).
- HP: health. Attack Power: melee/physical damage. Spell Power: magic damage (mage; Fire Missiles ≈ 3× SP). Armor: physical damage reduction — NAMU: "no damage if armor > enemy attack power" (i.e. subtractive with floor; consistent with G2 "shots doing close to nothing" until combo). Resistance: magic damage reduction (FW Stats) — FW Weapons instead says "immunity to status effects" `?`; NAMU: unknown. Crit: chance for bonus damage (multiplier unknown `?`). Haste: basic attack speed; "Tempo" = alpha name (FW Stats) — FW Weapons lists both Haste and Tempo as separate alpha affixes `?`. Regeneration: stamina regen (FW Stats, NAMU: HP does not regen passively). Mana Regen: MP regen (alpha affix). Block Power: separate gauge for blocking/Cyclone (FW Warrior; cuwo). Dodge/speed are not item stats (movement speed via skills/spirits).
- Weapon/armor stat rolls: random within a min–max per tier; stats roughly **double per rarity tier** (FW Rarity). Rarity tiers: Worn(grey, region-penalised) / Common white 1★ / Uncommon green 2★ / Rare blue 3★ / Epic purple 4★ / Legendary yellow 5★; alpha "Mythical" red = +1 above legendary from +4 dungeon chests (FW Rarity, Leftovers; NAMU).
- Alpha Adaptation: change an item's level to your power level for Platinum Coins (boss drop); lowering is free (FW Adaptation).
- Spirit Cubes [A]: bosses drop one per kill; apply at Customization Bench; **max 32 on 2H/shield, 16 on 1H**; cube power must be ≤ weapon power and within 10 levels below; Fire = +damage/fire; Wind = +attack & move speed per combo hit (resets with combo); Ice = slows target attack/move (turns blue); Unholy = life steal on specials, scaling with combo; removal destroys them (FW Spirit_Cube). Material cubes (iron/wood/silver/gold) add stats (gold only on bracelets per NAMU).
- Elixirs [S] (10 min): Power (+melee power), Toughness (+defense), Life (+HP), Sanity (+MP & magic power). Beverages: Lemonade (lava res.), Hot Chocolate (cold res.), Green Smoothie (poison res.). Food/potions heal over 15 s; potions usable while moving, food immobilises (FW Items, Elixirs, Food).
- **Circle of Power** [S]: light Eternal Ember → "increase your strength throughout the region" (buff icon; magnitude unknown `?`).
- Weather debuffs [S]: cold water = slow; toxic water (Deadlands/Dark Woods) = poison; lava = burn (G3, FW Landscape).

### 6.2 Level → power formulas [A]
- **Power Level = (101·level − 81)/(level + 19)** (FW Power_Level). Table: L1→+1, L2→+5, L3→+10, L5→+17, L10→+32, L20→+49, L30→+60, L50→+72, L100→+84, L200→+91, L500→+97, L1000→+99, L1981→+100 (cap +100; +101 at level 671,088,545). Item power (+1…+100) gates equip/use; Spirit cube power must match.
- cuwo alpha entity fields (entity.pyx): `hp` (float, default 500), `max_hp_multiplier` (default 100 — i.e. percentage), `block_power`, `charged_mp`, `level` (int32), `power_base` (uint8), `skills` (list of uint32 — the 11 skill-point slots), `mana_cubes`, class_type, specialization, appearance (hair RGB + model ids). Exact HP-per-level / damage formulas were never publicly documented; community notes only that "stats can be affected by level, equipped items and skill points" (FW Stats). **Gap**: no reverse-engineered damage formula found.
- Coins scale +1…+100 with item level; monsters L1–30 drop 10 copper–1 silver (FW Coin).
- World difficulty: landscape level rises with distance from spawn (FW Landscape); enemies carry +1…+4 multipliers and boss tier (FW Mobs). PyroProgression mod (fan re-implementation of alpha-like levelling for 1.0) uses region 1 = L1–5, +3 levels per region ring — mod design, not vanilla.

### 6.3 Steam 1.0 progression [S]
- **No XP, no skill points.** Level = number of **artifacts/relics** collected ("50 artifacts = level 50"; FW Artifacts, Relic). Artifacts only raise exploration stats (climbing, swimming, diving duration, riding, hang gliding, sailing, lamp radius); **no combat stats** (G1, FW Relic, Steam threads). Cannot be dropped. Found in dungeons/castles/vaults/catacombs; 100 % **Lore** for a realm reveals all its artifact locations; each lore piece ≈10 % (G3).
- Combat power = gear only: HP, attack, crit, haste, armor, resistance come from items (NAMU; HCG). Example: starting ~170–190 HP; ~1000 HP at end of first region (ITBS). Legendary staff 194.1 dmg → 5.4 dmg outside its region (Steam "Gear Stat Threshold").
- **Region lock**: weapons/armor/key items drop to "Worn" grey when outside their origin region (each region has its own inventory tab). **"+" items** (name suffix +) keep full stats in all *adjacent* regions (~1–4 zones of use); drop as loot, in shops (≈2× price), sometimes craftable; G3 says + loot appears after 100 % lore `?` (G2/FW say it's a rarer roll at any time). Enemy/quest colour tiers = white→green→blue→purple→yellow; fight your tier or one above (CWcom, G2). Gnome Supplier rescues (4 per region) unlock shop rarities; Books of Crafting (4 per region) unlock recipes; Arena 5 waves; Circles of Power.
- Enemy strength colours [S]: White (150–250 HP, farm animals) < Green < Blue < Purple (dungeons, some base) < Yellow (FW Mob_Strength; FW Color_codes gives a different orange/red hover scheme `?`). 0.9.3-0: other players' level displayed on highlight.

---

## 7. Combat mechanics (both versions unless marked)

- **Aiming**: crosshair, no target lock (CWcom). Ranged classes strafe like a shooter (gist).
- **Combo / hit counter**: shown near cursor; each landed hit +1; **ignores a growing share of enemy armor** and adds damage; caps per weapon (fists 50, staff 50, longsword 30, bow/crossbow 30, wand 20, bracelets 20, boomerang 80; "20–30 typical"); counter turns blue with "!" at cap; **any miss (whiffed attack with a hitbox) resets to 0**; expires after ~5 s idle; transfers between targets (G2, CWcom, ITBS). Enemies also build combos against you (ITBS). Wind Spirit [A] adds speed per combo hit.
- **Special/charged attacks**: hold M2 (Warrior/Ranger/Mage) — MP bar turns pink for the amount to be spent; more MP = more damage and higher stun/knockdown chance; releasing early spends less. Rogue M2 is instant. Some builds allow rapid low-charge M2 spam for combo building (bow/crossbow "dud" shots, dual-wield spin) (G2).
- **Stun / knockdown ("KO")**: strong specials, Smash, Kick, Rock Fist, 2H 3rd hit, Fire Explosion etc.; stunned enemy shows stars; cannot be re-stunned while stars show (stun diminishing/immunity, "CDR" per NAMU); knockdown interrupts potions and charged attacks (G1, G2, NAMU). Bulwark [A] grants stun immunity.
- **Knockback**: Kick, Fire Explosion, Rock Fist (knock-up), shield swipe.
- **Block**: shield hold M2 (any weapon for Guardian; Cyclone for any warrior); Block Power gauge depletes, regenerates when not blocking (faster during Cyclone); block gives MP [A+FW] / charges special [S G2]; Guardian block power ×2 (FW) or "twice as long" (GP/NAMU).
- **Dodge**: see §5; Ninja gets MP + guaranteed crit from dodging; Assassin gets stealth.
- **Critical hits**: chance from Crit stat, stealth (+50 % at full), Scout Intuition, Ninja Elusiveness (guaranteed), spirit/gear; multiplier not documented `?`.
- **Life steal**: Battle Fury 50 % [S]; Unholy Spirit [A].
- **Damage numbers**: floating numbers on hits (videos/G2 examples "12 a shot, 50 a charge"); HP bars toggle with V [A].
- **Status effects**: Poison (dagger Ambush, Poison Vial, toxic water; ticks, stacks, ignores dodge); Burning (Fire Explosion "burns", lava, Fire Spirit); Slow/Frozen (Ice Spirit turns target blue; cold water slow; Quicksand Trap immobilise); Stun/KO (stars); Taunt (red tint); Stealth (transparency); Possessed [S] (red, larger, stronger NPCs from Demon Portals); Mana Absorption [S] debuff (Mana Pump slows MP gain from attacks); Petrified towns (witch). Bleeding — not found in any source `?`. Enemy laser beams (Wizard/Witch) are hitscan and lethal (FW Wizard; 0.9.3-0 nerfed enemy wand damage −25 %).
- **Death**: no penalty (no gold/item loss) [A+S]; press R to respawn; alpha → nearest statue; Steam → last activated shrine; HP fully restored (NAMU); bosses reset HP unless shrine near [S]. Steam Workshop "No gold loss penalty" mod implies a respawn fee `?` — contradicted by HCG/G2 ("death doesn't have a drawback"); treat as mod/unverified.
- **Difficulty**: no difficulty setting in either version; colour tiers / +N multipliers only. Alpha bosses "notably much harder" (FW Bosses). Beta enemies mages considered overpowered (Steam threads).
- **Time**: 1 game min ≈ 6 s real; day = 2 h 24 min real (NAMU: 144 min); midnight reset respawns mobs/missions; inn resets to 7:00 (10 coins [S], free [A]) (FW Time).

---

## 8. Alpha vs 1.0 combat/progression delta (summary)

| Topic | Alpha 0.1.x | Steam 1.0 |
|---|---|---|
| XP/levels | XP, 2 skill pts/level, uncapped | none; level = artifact count |
| Skills | 3 class skills (5 pts each) + 6 shared abilities, keys 1–4, X menu | fixed kit: M2, M3-standing, Shift(+M1/M2/Space), R ult; all unlocked |
| Removed skills | War Frenzy, Bulwark, Aim, Scout's Swiftness, Mana Shield, Shuriken Attack (backflip), Ninja stealth | — |
| Added skills | — | Rock Fist, Heroic Shout, Shadow Shooter, Quicksand Trap, Fire Missiles, Bubbles, Poison Vial, Ninjutsu, Shuriken Toss, Sprint/High Jump, Float |
| Stats | 10 item stats; Tempo; item power +1…+100; Adaptation; Spirit cubes | Haste; star ratings; region-locked gear, + gear; artifacts for exploration stats; elixirs |
| Combo | armor ignore + speed | same (core kept) |
| Respawn | nearest statue auto | activated shrine only; flute |
| Spec change | class trainer, small fee | guildmaster, free |
| Riding/gliding/boat | skill points + bought items | key items per region + artifacts |
| Climb key | Ctrl (hold) | E/Shift (sticks) |
| Drowning | none | yes |
| Multiplayer | dedicated server.exe, /connect IP, /pvp | Steam friends only (J), shared map seed |

---

## 9. Cube World Omega [Ω] (2023–2026)
- Announced 25 May 2023: new Vulkan engine (later reports say Unreal Engine 5 `?` — massivelyop/evergameday secondary claims), weather, procedural characters/items, GUI overhaul, and **"plans to bring back experience, leveling and skill trees"** — "in the spirit of Cube World Alpha" (wollay.com 2023/05/25).
- 2023 blog posts: procedural Undead (26 May), Zombies with signature abilities (31 May; "eat" grab-drain, escape via dodge/stun/mobility — 1 Jun), Ogres with "belly slide" charge-stun (6 Jun), all 8 playable races + procedural weapons/armour (13 Jun), Slimes "Divide" <50 % HP & Crabs (26 Jun), new world gen (30 Jul), Hornets "poison sting" & Hedgehogs "spike swirl" (14 Oct).
- Nov 2020 leaked DM screenshot showed a level system/skill tree returning (NAMU) `?`.
- Wollay on X (2026, status 2073003858264002920): "All classes are fully functional now, including some new skills! Next working on skill trees." Reported UI overhaul / crafting stations / procedural races update May 2026 (evergameday, secondary). No release date; no published skill lists or stat formulas.

---

## 10. Gaps / uncertain
- No numeric per-point values for alpha skill ranks (wiki uses X%). No HP/damage/crit/haste formulas for either version (cuwo only exposes fields; no memory RE published). Crit multiplier unknown. Steam R-cooldown "40 s" vs per-skill values (20/30/40/60) — per-skill values from SAH/FW preferred. Heroic Shout heal vs debuff conflict. Guardian Toughness 25 HP vs 25 %. Battle Fury proc trigger (per hit ~12–14 % vs "on crit"). Shadow Shooter 30 s vs 20 s. Bubbles 6 vs 8. Shuriken cost 25 (patched) vs 50. Skin-colour option existence. Exact creation palette counts. Alpha dev blog (wollay.blogspot.com) is deleted; picroma.com blog returns empty; devtrackers/namu/orcz blocked for fetch (namu retrieved via curl).
