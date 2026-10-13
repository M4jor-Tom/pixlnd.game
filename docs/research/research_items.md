# Cube World — Items, Equipment, Crafting, Economy (research dump)

Scope: Alpha 0.1.1 (2013), Steam 1.0 (beta 23 Sep 2019, release 30 Sep 2019), Cube World Omega (2023–).
Conventions: **[A]** = Alpha only, **[S]** = Steam 1.0 only, **[A+S]** = both. **(?)** = uncertain / conflicting.
Primary sources: cubeworld.fandom.com (wikitext pulled via MediaWiki API; page names given as `wiki:Page`), cuwo (alpha server reimplementation, https://github.com/matpow2/cuwo), coremaze/Cube-World-Weapon-Stats (reverse-engineered alpha item stat code), Steam community guides/discussions, wollay.com.

---

## 0. Item data model (from reverse engineering — ground truth for the alpha binary)

Source: cuwo `cuwo/entity.pyx` (ItemData struct, network format) and `cuwo/strings.py` (ITEM_NAMES), coremaze `Stats.py`.

### 0.1 ItemData struct (alpha 0.1.1 network/save layout)
| field | type | meaning |
|---|---|---|
| type | u8 | main item category (table below) |
| sub_type | u8 | subtype within category (e.g. weapon kind, consumable kind) |
| modifier | u32 | random seed-ish "modifier"; combined with `attributes` (`(attributes<<16)+modifier`) it selects the stat roll (mod % 0x15 → 21 possible rolls) |
| minus_modifier | u32 | second modifier word |
| rarity | u8 | 0..5 (0 common … 4 legendary, 5+ = "mythical"/overflow) |
| material | u8 | material id (table below) |
| flags | u8 | bit flags (adapted, etc.) |
| level | i16 | item power level ("+N", 1..100+) |
| items[32] | ItemUpgrade | up to **32 upgrade cubes** (x,y,z i8, material i8, level i32) — the Customization Bench cubes/spirits |
| upgrade_count | u32 | how many of the 32 slots are used |

`ItemUpgrade` = {x:i8, y:i8, z:i8, material:i8, level:i32} → each attached cube has a 3D position on the weapon model, a material (Wood/Iron/Fire/Unholy/Ice/Wind…) and a level.

### 0.2 Item main-type IDs (cuwo/strings.py ITEM_NAMES; coremaze enums)
| id | category | subtypes |
|---|---|---|
| 0 | None | |
| 1 | Consumable ("USEABLE_ITEMS") | 0 Cookie, 1 LifePotion, 2 CactusPotion, 3 ManaPotion, 4 GinsengSoup, 5 SnowBerryMash, 6 MushroomSpit, 7 Bomb, 8 PineappleSlice, 9 PumpkinMuffin |
| 2 | Formula (recipe scroll) | 0 |
| 3 | Weapon | 0 Sword, 1 Axe, 2 Mace, 3 Dagger, 4 Fist, 5 Longsword, 6 Bow, 7 Crossbow, 8 Boomerang, 9 Arrow, 10 Staff, 11 Wand, 12 Bracelet, 13 Shield, 14 Arrows, 15 Greatsword, 16 Greataxe, 17 Greatmace, 18 Fork (unused), 19 Pickaxe (unused), 20 Torch |
| 4 | Chest armor | 0 |
| 5 | Gloves (Hands) | 0 |
| 6 | Boots (Feet) | 0 |
| 7 | Shoulder armor | 0 |
| 8 | Amulet (Neck) | 0 |
| 9 | Ring | 0 |
| 10 | Block | (world cube) |
| 11 | Items / ingredients | 0 Nugget, 1 Log, 2 Feather, 3 Horn, 4 Claw, 5 Fiber, 6 Cobweb, 7 Hair, 8 Crystal, 9 Yarn, 10 Cube, 11 Capsule, 12 Flask, 13 Orb, 14 Spirit, 15 Mushroom, 16 Pumpkin, 17 Pineapple, 18 RadishSlice, 19 ShimmerMushroom, 20 GinsengRoot, 21 OnionSlice, 22 Heartflower, 23 PricklyPear, 24 FrozenHeartflower (Iceflower), 25 Soulflower (unused), 26 WaterFlask, 27 SnowBerry |
| 12 | Coin | 0 |
| 13 | Platinum Coin ("ORES" in coremaze naming) | 0 |
| 14 | Leftovers (unidentified gear) | 0 |
| 15 | Beak | 0 |
| 16 | Painting | 0 |
| 17 | Vase | |
| 18 | Candle | 0, 1 |
| 19 | Pet (pet cage) | 0 (pet species stored elsewhere) |
| 20 | Pet food ("Bait") | 0..155; named ones: 19 BubbleGum, 22 VanillaCupcake, 23 ChocolateCupcake, 25 CinnamonRoll, 26 Waffle, 27 Croissant, 30 Candy, 33 PumpkinMash, 34 CottonCandy, 35 Carrot, 36 BlackberryMarmelade, 37 GreenJelly, 38 PinkJelly, 39 YellowJelly, 40 BlueJelly, 50 BananaSplit, 53 Popcorn, 55 LicoriceCandy, 56 CerealBar, 57 SaltedCaramel, 58 GingerTartlet, 59 MangoJuice, 60 FruitBasket, 61 MelonIceCream, 62 BloodOrangeJuice, 63 MilkChocolateBar, 64 MintChocolateBar, 65 WhiteChocolateBar, 66 CaramelChocolateBar, 67 ChocolateCookie, 74 SugarCandy, 75 AppleRing, 86 WaterIce, 87 ChocolateDonut, 88 Pancakes, 90 StrawberryCake, 91 ChocolateCake, 92 Lollipop, 93 Softice, 98 CandiedApple, 99 DateCookie, 102 Bread, 103 Curry, 104 Lolly, 105 LemonTart, 106 StrawberryCocktail, 151 BiscuitRoll. (The pet-food subtype id == the pet/creature id it tames; the wiki "ID No." column matches.) |
| 21 | Special accessories (quest items, unused) | 0 Amulet1, 1 Amulet2, 2 JewelCase, 3 Key, 4 Medicine, 5 Antivenom, 6 BandAid, 7 Crutch, 8 Bandage, 9 Salve |
| 23 | Specials (key items) | 0 HangGlider, 1 Boat |
| 24 | Light | 0 Lamp |
| 25 | Cubes | 0 ManaCube |

### 0.3 Material IDs (cuwo constants.py MATERIAL_NAMES; coremaze)
| id | material | notes |
|---|---|---|
| 1 | Iron | warrior armor, metal weapons, fists |
| 2 | Wood | bows, crossbows, boomerangs, staves, wands, wooden maces |
| 5 | Obsidian | unused armor set (cheat-only) |
| 7 | Bone | medium armor (unobtainable: bones never drop) |
| 10 | Copper | (coremaze list; coins) |
| 11 | Gold | rings, amulets, bracelets |
| 12 | Silver | rings, amulets |
| 13 | Emerald | 2★ crafting gem |
| 14 | Sapphire | 3★ crafting gem |
| 15 | Ruby | 4★ crafting gem |
| 16 | Diamond | 5★ crafting gem |
| 17 | Sandstone | |
| 18 | Saurian | medium armor (unobtainable) |
| 19 | Parrot | medium armor from Parrot Feathers (recipe not in menu) |
| 20 | Mammoth | medium armor from Mammoth Hides (0% drop) |
| 21 | Plant | |
| 22 | Ice | |
| 23 | Licht (light) | |
| 24 | Glass | flasks |
| 25 | Silk | mage cloth |
| 26 | Linen | ranger cloth |
| 27 | Cotton | rogue cloth |
| 128 | Fire (spirit) | spirit cube |
| 129 | Unholy (spirit) | spirit cube |
| 130 | Ice (spirit) | spirit cube |
| 131 | Wind (spirit) | spirit cube |

Sources: https://github.com/matpow2/cuwo/blob/master/cuwo/constants.py , https://github.com/matpow2/cuwo/blob/master/cuwo/strings.py , https://github.com/coremaze/Cube-World-Weapon-Stats/blob/master/Stats.py

### 0.4 Alpha item stat formulas (coremaze/Cube-World-Weapon-Stats, reverse engineered from 0.1.1)
```
curve(n, rarity) = 2^( (1 - 1/((n-1)*0.05 + 1)) * 3 ) * 2^(rarity*0.25)
curve2(n, rarity) = curve(n, rarity) / 8
n = level + 0.1 * number_of_spirits          (each attached cube ≈ +0.1 level)
roll = ((attributes<<16)+modifier) % 0x15   (0..20)  -> roll/20 in [0,1]
```
- **Damage (weapons only)**: `curve(n,r) * k` with k = 2 for Dagger, Fist, Shield; 4 for one-handed (Sword/Axe/Mace/Bracelet) ; 8 for two-handed (Greatsword, Greataxe, Greatmace, Longsword, Staff, Wand, Fork, Boomerang, Bow, Crossbow).
- **HP** (weapons, chest, shoulder, hands, feet): `curve(n,r) * 5 * slot * (2 - 8*roll/20 + matBonus)`; slot = 1.0 chest, 0.5 others; matBonus Iron +1, Cotton +0.75, Linen +0.5.
- **Armor** (armor slots): `curve(n,r) * slot * matMult`; slot 1 chest / 0.5 others; matMult Saurian 0.8, Parrot/Linen/Cotton 0.85, Licht/Silk 0.75, Iron 1.0.
- **Resistance** (armor slots): `curve(n,r) * slot * m`; m Iron/Parrot 0.85, Linen/Cotton 0.75, (Silk 1.0).
- **Regeneration** (weapons + armor): `curve(n,r) * (0.2 chest | 0.1 other) * (8*roll/20 + Linen 0.5 | Cotton 1.0)`.
- **Tempo/Haste** (neck, ring, weapons, armor): `curve2(level,r) * (0.2 two-handed & chest | 0.1 other) * (roll/20 + Silver +1)`. → Silver rings = tempo.
- **Crit** (neck, ring, weapons, armor): `curve2(level,r) * (0.1 two-handed & chest | 0.05 other) * (1 - roll/20 + Gold +1)`. → Gold rings = crit.
- **Healing (consumables)**: LifePotion/CactusPotion/GinsengSoup/SnowberryMash/MushroomSpit `curve(level,r)*200`; PineappleSlice/PumpkinMuffin `curve(level,r)*100`. Consumables therefore also have a level and rarity.
- Rarity multiplier: each rarity tier ×2^0.25 ≈ ×1.19 in the raw curve (wiki claims "roughly doubled per tier" for displayed values — conflicting **(?)**; the ×1.19 is the reverse-engineered base curve, final displayed numbers may compound).
Source: https://github.com/coremaze/Cube-World-Weapon-Stats/blob/master/Stats.py

### 0.5 Power level vs character level [A]
`Power = (101*level − 81) / (level + 19)`, max usable +100 (level 1981+); +101 at level 671,088,545. Item "+N" must be ≤ player power to be used at full strength. Table: lvl1→+1, 2→+5, 3→+10, 5→+17, 10→+32, 20→+49, 30→+60, 50→+72, 100→+84, 200→+91, 500→+97, 1000→+99. Source: wiki:Power_Level.

---

## 1. Item categories

### 1.1 Weapons — class restriction and handedness [A+S]
| weapon | class | hands | notes |
|---|---|---|---|
| Sword | Warrior | 1H, dual-wield or +shield | |
| Axe | Warrior | 1H, dual or +shield | |
| Mace | Warrior | 1H, dual or +shield | |
| Shield | Warrior | off-hand | blocks; successful block gives MP; dmg k=2; max 32 spirit cubes (counted as 2H) |
| Greatsword | Warrior | 2H | slower 3-hit combo, 3rd hit knockdown chance |
| Greataxe | Warrior | 2H | |
| Greatmace | Warrior | 2H | wooden or iron variants exist |
| Dagger | Rogue | 1H, dual | can pair with Fist |
| Fist | Rogue | 1H, dual | crafted from Cotton Yarn + Iron Cubes |
| Longsword | Rogue | 2H | |
| Bow | Ranger | 2H | unlimited arrows, longer range than boomerang |
| Crossbow | Ranger | 2H | |
| Boomerang | Ranger | 2H | multi-hit per throw, low dmg/hit, very fast combo build; camera steers it [S] |
| Staff | Mage | 2H | multi-hit per attack |
| Wand | Mage | 1H | needs aim; player laser only with wand |
| Bracelet | Mage | 1H, dual (needs two) | alternates hands, lower dmg, faster |
| Torch | any | 1H (subtype 20) | light source item in alpha data; superseded by Lamp |
| Arrow/Arrows, Fork, Pickaxe | — | unused subtypes |

Wiki class summary: Mage = Bracelets, Staves, Wands; Ranger = Boomerang, Bows, Crossbows (+Shuriken skill "throwables"); Rogue = Daggers, Fists, Longswords; Warrior = Axes, Greataxes, Greatmaces, Greatswords, Maces, Swords, Shields. Equipping: M1 → right hand slot, M2 → left hand slot [S guide]. Red item name = not your class (can't equip; sell/drop) [S].
Sources: wiki:Weapons, wiki:Swords/Axes/Maces/Daggers/Fists/Longswords/Greatswords/Greataxes/Greatmaces/Bows/Crossbows/Boomerang/Staves/Wands/Bracelets/Shields/Throwables, https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729

Named examples seen on wiki (name pattern `<affix> <material> <type> [of <Name>]`, Epic/Legendary always get a name): Plain Iron Sword ★, Worn Iron Mace ★, Worn Iron Dagger ★, Shabby Iron Greatsword ★, Fair Iron Fist ★★, Battle Tested Iron (Great)mace ★★, Handmade Wood Bow ★★, Undamaged Wood Boomerang ★★, Unique Wood Wand ★★★, Extraordinary Iron Greataxe ★★★, Decorated/Superb Wood Bow ★★★★, Extraordinary Iron Longsword of Wolfman ★★★★, Exquisite Gold Bracelet ★★★★, Exceptional/Extraordinary Wood Staff ★★★★, Glorious Iron Axe of Ziri ★★★★★, Brilliant Iron Shield (Driric's) ★★★★★, Legendary Wood Staff ★★★★★, Pompous Wood Wand (Azyna's) ★★★★★. 1.0 plus items: "Drakzic's Brilliant Iron Dagger+", "Izaira's Brilliant Wood Boomerang+", "Lorax's Exceptional Cotton Gloves+" (https://steamcommunity.com/app/1128000/discussions/0/1735507058422798015/).

### 1.2 Armor slots and materials per class
Slots: **Chest, Shoulders, Gloves, Boots** (+ Amulet ×1, Ring ×2 as accessories). Source wiki:Armor, wiki:Inventory.
| class | armor material | crafting station | raw → refined |
|---|---|---|---|
| Warrior | Iron ("heavy") | Anvil (Smithy) | Iron Nugget (Iron Deposit, caves) → Furnace → Iron Cube |
| Rogue | Cotton | Loom (Clothier) | Cotton Capsule (Cotton Plant) → Spinning Wheel → Cotton Yarn |
| Ranger | Linen | Loom | Plant Fiber (Bush) → Spinning Wheel → Linen Yarn |
| Mage | Silk (aka "Flannell" in some item names) | Loom | Cobweb (Scrub) → Spinning Wheel → Silk Yarn |
| any ("Medium armor", unobtainable) | Parrot (Parrot Feathers), Bone (zombie bones, 0 drop), Mammoth (Mammoth Hides, 0 drop), Saurian, Silver, Gold, Obsidian (removed) | Anvil | |
Steam guide table: Archer=Linen+Wood (bushes); Warrior=Iron (iron deposits); Mage=Silk+Wood (scrubs, bushes); Rogue=Cotton+Iron (cotton plants, iron deposits). Gold and Silver used by every class for amulets/rings/some weapons.
Sources: wiki:Iron_Armor, wiki:Cotton_Armor, wiki:Silk_Armor, wiki:Obsidian_Armor, wiki:Parrot_Armor, wiki:Bone_Armor, wiki:Mammoth_Armor, wiki:Mammoth_Hides, https://steamcommunity.com/sharedfiles/filedetails/?id=1871883807

Named armor examples: Common Linen Chest Armor ★ (Ranger), Plain/Scratched Silk Chest Armor ★ (Mage), Balanced Iron Chest Armor ★★, Clean Cotton Chest Armor ★★, Fair Silk Gloves ★★, Decorated Iron Chest Armor ★★★, Extraordinary Silk Chest/Shoulder Armor ★★★, Superb Silk Gloves ★★★, Exceptional/Exquisite Silk Chest Armor ★★★★, Magic Flannell Chest Armor of Zira ★★★★, Decorated Silk Shoulder Armor ★★★★, Kurlia's Superb Flannell Boots ★★★★, Legendary Cotton Chest Armor ★★★★★, Splendid Linen Shoulder Armor ★★★★★, Siralaya's Brilliant Silk Boots ★★★★★, Legendary Bronze Boots of Kurzy ★★★★★ (Warrior; "Bronze" naming exists).

### 1.3 Accessories
- **Amulet** — 1 slot; gives Crit + Tempo (Haste). Materials Silver/Gold. Examples: Plain Silver Amulet ★, Exquisite Gold Amulet ★★★, Magnificent Gold Amulet of Gedor ★★★★★. Crafted from Gold/Silver Cubes **without an anvil** (Amulet & Ring crafting tab).
- **Ring** — 2 slots (Left Ring, Right Ring); Gold ring → Crit focus, Silver ring → Tempo focus (matches formulas §0.4). Alpha start: character gets a Gold Ring and a Silver Ring. Examples: Battered Silver Ring ★, Unwieldy Gold Ring ★, Undamaged Silver Ring ★★, Flawless/Neat Gold Ring ★★, Exquisite Silver Ring ★★★, Aleny's Superb Silver Ring ★★★★, Exquisite Gold Ring of Grunhild ★★★★, Lesreas's Handsome Silver Ring ★★★★, Grand Gold Ring of Zelrax ★★★★, Glorious Silver Ring of Barthos ★★★★★, Liri's Splendid Silver Ring ★★★★★, Famous Gold Ring of Drakira ★★★★★, Fabulous Gold Ring of Liana ★★★★★, Legendary Gold Ring ★★★★★. Trivia: a legendary ring recipe may require Rubies instead of Diamonds. Rings don't render on the character. [S] all 4 gnomes must be rescued for item shop to sell legendary rings/amulets.
Sources: wiki:Amulet, wiki:Ring, wiki:Item_Shop.

### 1.4 Materials / ingredients (full list from wiki:Items + cuwo)
Gatherables: Apple (under trees; eat = heal), Lemon, Prickly Pear (Cactus), Snowberry (Snowberry Bush), Ginseng Root, Dewdrop (gathering nodes), Banana & Cocoa Bean (jungle trees), Kale, Pineapple, Pumpkin (farms/villages), Mushroom (under trees), Onion Slice (Onionling drop), Radish Slice (Radishling drop), Shimmer Mushroom (caves; glows blue), Ice Cube (Snowlands water), Sugar Cube (vendor), Dragon Root (under trees), Manaorchid (grass/forest), Heartflower (most biomes except Deserts/Snowlands; sell 1), Iceflower/Frozen Heartflower (Snowlands; sell 69 (?)); thaw at campfire → 1–3 Heartflowers), Parrot Feather (Parrot drop), Plant Fiber (Bush), Wood Log (Bush), Cotton Capsule (Cotton Plant), Cobweb (Scrub), Glass Flask (vendor 1 coin [S]; drops; dungeon tables), Water Flask (craft from Glass Flask while standing in water), Bomb.
Refined: Linen/Cotton/Silk Yarn (Spinning Wheel), Wood Cube (Saw), Iron/Silver/Gold Cube (Furnace from nuggets), Gems (Emerald/Sapphire/Ruby/Diamond — no refinement).
Deposits (caves, underwater caves): Iron, Silver, Gold, Emerald, Sapphire, Ruby, Diamond; each yields 1–3 nuggets/gems; respawn at midnight reset.
Sources: wiki:Items, wiki:Deposit, wiki:Nugget, wiki:Gems, wiki:Heartflower, wiki:Iceflower.

---

## 2. Rarity, stars, affixes, item level, "+"

### 2.1 Tiers (wiki:Rarity — 6 tiers)
| tier | color | stars | gem to craft | notes |
|---|---|---|---|---|
| Worn | Grey | ★ | – | [S] doesn't drop; any gear becomes Worn outside its region (except + items). Vendors sell only Worn until gnomes rescued. |
| Common | White | ★ | – | starting gear |
| Uncommon ("magic" on some pages) | Green | ★★ | Emerald (×2 small piece / ×4 chest) | |
| Rare | Blue | ★★★ | Sapphire | |
| Epic | Purple | ★★★★ | Ruby | always named ("of X") |
| Legendary | Yellow/Gold | ★★★★★ | Diamond | always named |
| Mythical [A] | red text in Leftovers list; otherwise renders like common | – | – | bug: +4 dungeon chests roll +1 rarity above legendary |
"Equipment stats are roughly doubled with each increasing tier" (wiki; vs ×1.19 base curve, see §0.4 **(?)**). Buy/sell prices depend on rarity. Enemy name color uses the same scale (White<Green<Blue<Purple<Yellow), and 1.0 mission markers too. Steam 1.0 also shows "Weapon Level = average of weapon tiers, Armor Level = average of armor tiers" in the character panel; pets scale with these.
Rarity display can be changed in Options.

### 2.2 Name affixes (prefix from tier list; Epic/Legendary add "of <name>" or "<Name>'s")
- Common: Artless, Battered, Common, Dusty, Plain, Scratched, Shabby, Unwieldy, Used, Worn
- Uncommon: Adjusted, Balanced, Battle-tested, Clean, Fair, Flawless, Good, Handmade, Neat, Undamaged
- Rare & Epic (shared list): Decorated, Exceptional, Exquisite, Extraordinary, Grand, Handsome, Magic, Polished, Superb, Unique
- Legendary: Brilliant, Extraordinary, Fabulous, Famous, Glorious, Legendary, Magnificent, Pompous, Splendid, Shining, Sublime
- [S] plus items append "+" (e.g. "Shabby Iron Dagger+").

### 2.3 Item level [A] vs region [S]
- [A] every item has "+N" power level 1–100(+). Vendors sell items +1..+100; formulas also +1..+100. Bombs come as Bomb +1/+5/+10. Spirit cubes have levels too. Boss drops equipment ≈ same +N as its spirit cube. Player must have Power ≥ item level to wield at full strength ("Players cannot learn recipes until they are the right level").
- [A] **Adaptation**: Adapter tower (crossed-swords icon) re-levels a weapon/armor to your current power; raising costs **Platinum Coins** (boss / mission rewards), lowering is free. (Community mod "Adaption-Rebalance" notes costs were "insane".)
- [S] no XP levels; items have no visible +N. Each item is bound to the **region** (white-bordered land on map) where it dropped/was crafted/bought; outside it drops to Worn (community: "legendary staff 194.1 dmg → 5.4 dmg in another region"; some say "halved" — wiki says Worn **(?)**). Inventory has one tab per region visited (arrows to switch); foreign-region items are greyed.
- [S] **Plus (+) items**: keep full stats in the origin region **and adjacent regions** (degrade 2–3 regions away). Obtained: random drops, crafting list may contain one, shop after gnomes/books, quest rewards; ~1–2 per fully cleared region (community). "100% lore makes gear +" claim is disputed (wiki-adjacent guide says yes; multiple players say hoax **(?)**). Plus items exist at all rarities (seen up to purple/yellow, even the starting white club can be +). Patch 0.9.3-0: "Item receipt notifications now consider plus-equipment; pet scaling considers plus-equipment".
- [S] Bombs are also region-bound: a bomb's loot comes from the region it was found/bought in.
Sources: wiki:Rarity, wiki:Adaptation, wiki:Coin, wiki:Bomb, wiki:Inventory, https://steamcommunity.com/sharedfiles/filedetails/?id=1870746373 , https://steamcommunity.com/app/1128000/discussions/0/1628539187770170456/ , https://steamcommunity.com/app/1128000/discussions/0/1628538644183483666/ , https://steamcommunity.com/app/1128000/discussions/0/1626286205708600896/

---

## 3. Crafting

### 3.1 Stations (all in a city's Crafting District; zoom map to see icons)
| building | tools | use |
|---|---|---|
| Smithy / Blacksmith | **Furnace** (nuggets→cubes), **Anvil** (metal weapons + iron armor), **Customization Bench** (attach cubes/spirits to weapons) | |
| Clothier | **Spinning Wheel** (fiber/capsule/cobweb→yarn), **Loom** (cloth armor; also bows/crossbows use yarn) | |
| Workshop / Carpenter | **Saw** (log→Wood Cube), **Workbench** (wood weapons: staves, wands, bows, crossbows, boomerangs; +12 wood cubes upgrade [A]) | |
| Campfire (campsites) | cooking + alchemy that needs fire; thaw Iceflower | standing in fire = no damage |
| anywhere | Water Flask (stand in water), Pineapple Slice, Snowberry Mash, potions/elixirs not marked campfire, rings & amulets | |
Crafting menu key **C**. Recipe shows required materials count and station (e.g. "5 iron cubes and an anvil" [S]).
Sources: wiki:Crafting, wiki:Crafting_Tool, wiki:Anvil, wiki:Loom, wiki:Furnace, wiki:Saw, wiki:Spinning_Wheel, wiki:Workbench, wiki:Campfire, wiki:Smithy, wiki:Clothier.

### 3.2 Crafting tabs [A]
Weapon (own class only), Armor (own class only), Amulet & Ring (all classes), Cooking (food; must sit to eat), Alchemy (potions; can move while drinking), Ingredients (refining). Gamepressure lists 6 branches: Weapon, Armor, Amulet, Cooking, Alchemy, Formulas(=Ingredients).

### 3.3 Recipe acquisition
- [A] **Formulas** (item type 2): scrolls sold by vendors (+1..+100), dropped by monsters (random recipe of the monster's tier), found on dungeon tables/chests. Right-click to learn; can't learn until the right level; duplicates not relearned. Without formulas no new gear recipes unlock (base recipes appear as power increases).
- [S] **Books of Crafting**: Magic (2★), Rare (3★), Epic (4★), Legendary (5★) — one of each per region, from missions (hammer icon); each unlocks 3–4 recipes; once all 4 obtained no more recipes for that region. Recipes region-scoped.
- [S] **Gnome Suppliers** (4 per region, trapped, often need a boss key): each rescued gnome raises shop stock one rarity (white mission→Uncommon, green→Rare, blue→Epic, purple→Legendary). Shops restock daily.
Sources: wiki:Formulas, wiki:Book_of_Crafting, wiki:Gnome_Supplier, wiki:Side_Missions.

### 3.4 Gear recipe quantities — Cotton armor (wiki:Cotton_Armor; assumed same pattern for Linen/Silk/Iron with their cube/yarn)
| rarity | Chest | Shoulder | Gloves | Boots | gem |
|---|---|---|---|---|---|
| Common | 10 yarn | 6 | 5 | 5 | – |
| Uncommon | 20 + 4 Emerald | 12 + 2 | 10 + 2 | 10 + 2 | Emerald |
| Rare | 30 + 4 Sapphire | 18 + 2 | 15 + 2 | 15 + 2 | Sapphire |
| Epic | 40 + 4 Ruby | 24 + 2 | 20 + 2 | 20 + 2 | Ruby |
| Legendary | 50 + 4 Diamond | 30 + 2 | 25 + 2 | 25 + 2 | Diamond |
Weapons: e.g. common metal weapon "5 iron cubes + anvil" [S]; Fists = Cotton Yarn + Iron Cubes; Bows/Crossbows = Wood Cubes (+ yarn). Exact per-weapon counts not documented **(gap)**.
Gem trader prices [S]: Emerald 100, Sapphire 200, Ruby 400, Diamond 800 coins (wiki:Gems).

### 3.5 Customization Bench (cube upgrading) [A] (bench exists in [S] but no spirits)
- Attach **Material Cubes** to a weapon of matching material: Wood Cubes on wooden weapons, Iron Cubes on metal weapons (never cross). Bench interface: rotate weapon with M3; drag cubes onto the voxel model (each upgrade stored with x,y,z). Dragging a cube out of the window **destroys** it.
- Capacity: **16 cubes on one-handed weapons, 32 on two-handed weapons and shields** (= ItemData.items[32]).
- Effect: each cube adds ≈ +0.1 to effective item level in the stat curve (§0.4); community: fully modding two legendary+ weapons in 1.0 added 58–67 damage each. Wood/Iron cubes are always "+1" and can go on weapons of any level; "Wooden Cube and Iron Cube upgrades do not affect Spirit Cube upgrades".
- **Spirit Cubes** [A]: Fire (extra fire damage), Wind (attack+move speed per combo hit, resets with combo), Ice (slows target attack/move), Unholy (special attacks drain HP scaling with combo). Boss-only drop, 1 per kill; a given boss always drops the same spirit type and level (e.g. Fire Spirit +24). Not from mission bosses like Saurian. Spirit level must be ≤ weapon level and ≥ weapon level − 10 (e.g. +11 weapon accepts +1..+11; +46 weapon rejects +1/+10). Special attack hits cause colored explosion. Also "Wood Spirit"/"Iron Spirit" = plain cubes.
- [S]: Spirit cubes, Adaptation, Platinum coins removed; bench still upgrades with material cubes.
Sources: wiki:Customization_Bench, wiki:Spirit_Cube, wiki:Iron_Cube, wiki:Wood_Cube, wiki:Workbench, wiki:Cube, https://steamcommunity.com/app/1128000/discussions/0/1628538707067544353/

### 3.6 Cooking (food — sit to eat, immobile; heal over 15 s; campfire where noted)
| food | recipe | effect |
|---|---|---|
| Apple | pickup only | heal 15 s |
| Pineapple Slice | 1 Pineapple | heal 15 s (100× curve) |
| Snowberry Mash | 1 Snowberry (craftable since 0.9.1-5) | heal 15 s |
| Pumpkin Muffin | 1 Pumpkin @campfire | heal 15 s (100× curve) |
| Ginseng Soup | 4 Ginseng Root @campfire | heal 15 s (200× curve) |
| Mushroom Spit | 1 Mushroom + 1 Onion Slice @campfire | heal 15 s (200× curve) |
| Cookie | (alpha item id 1/0, unused/rare) | |
Beverages [S]: Lemonade = 1 Water Flask + 2 Sugar Cube + 2 Ice Cube + 3 Lemon → lava resistance 10 min; Hot Chocolate = 1 Water Flask + 1 Sugar Cube + 3 Cocoa Bean @campfire → cold resistance 10 min (needed for Snowlands cold water slow); Green Smoothie = 1 Water Flask + 2 Banana + 2 Kale → poison resistance 10 min (toxic rivers in Deadlands/Dark Woods). Heartflower = 1 Iceflower @campfire (bonus yield 2–3).
Bug: eating while sitting in a chair consumes food without healing.

### 3.7 Alchemy (potions — drink while moving; hotkey Q)
| potion | recipe | effect |
|---|---|---|
| Life Potion | 1 Heartflower + 1 Water Flask (wiki also says @campfire **(?)**) | heal over 15 s (200× curve) |
| Cactus Potion | 1 Prickly Pear + 1 **Glass** Flask (no water needed) | heal over 15 s |
| Mana Potion | alpha item id (1,3); not craftable/documented **(?)** | |
| Elixir of Power [S] | 1 Water Flask + 2 Dragon Root + 5 Mushroom | +20% Attack Power, 10 min |
| Elixir of Toughness [S] | 1 Water Flask + 2 Dewdrop + 5 Mushroom | +20% Armor, 10 min |
| Elixir of Life [S] | 1 Water Flask + 1 Ginseng Root + 5 Heartflower | +20% Health, 10 min |
| Elixir of Sanity [S] | 1 Water Flask + 1–2 Manaorchid + 5 Shimmer Mushroom | +20% Resistance, 10 min |
New character [S] starts with 5 potions (guide). Potions have rarity in data; Pixxie (2015) showed Uncommon/Rare/Epic life potion colors (green-yellow-red, blue-purple-red, purple-red) — never shipped. NPCs and humanoid monsters (Ogre, Mermaid, Insect Guard) drink potions when low. Spamming hotkey wastes potions.
Sources: wiki:Items, wiki:Crafting, wiki:Food, wiki:Potions, wiki:Elixirs, wiki:Glass_Flask, wiki:Water_Flask, wiki:Life_Potion.

---

## 4. Consumables & misc items
- **Bomb**: 100 HP fuse that ticks down then explodes; hit it to detonate early (chains nearby bombs); destroys boulders / cracked dirt in caves; hitting a bomb can pop loot instead; hurts players. [A] rated +1/+5/+10; [S] all same strength, region-bound loot. Sold by item vendor, dropped, found on tables. Used via Q quick slot or right-click. In alpha data a bomb creates a "pet" entity that loses HP until 0.
- **Candles**: decorative light; red, pink, green; small/tall/large forked; red+pink in dungeons/palaces/castles (yellow light), green in ruins/catacombs (green light). Item tab.
- **Leftovers** (item type 14): unidentified gear dropped by animals/monsters of your tier; has power level (+27) and rarity color (green/blue/pink(purple)/yellow; red = mythical); Identifier's shop (magnifying glass sign; "Analyst" in 1.0) reveals a weapon/armor for a fee based on level & quality; chance to yield one tier higher.
- **Paintings, Vase, Beak** — data-only item types.
- **Iron Lamp** [A]: equippable Light item, toggled with **F**; every alpha item shop stocks ≥1; radius/brightness scale with rarity; colors vary; not craftable. [S] lamp is an innate F ability, radius grown by artifacts.
- **Pet Cage** (type 19): one pet per cage; Turtle's cage is a turtle shell. Right-click cage in slot to unsummon. Bug [S]: swapping cages can delete a pet.
- **Coins/Platinum Coins** see §7.
Sources: wiki:Bomb, wiki:Candle, wiki:Leftovers, wiki:Identifier's_Shop, wiki:Iron_Lamp, wiki:Pet_Cage.

---

## 5. Pets & pet food (taming)
Mechanics: equip food from Pets tab (right-click) → approach creature → auto-success, hearts appear; only one of each pet food may be carried (can hold >1 of same pet); one pet per food; group members not fed turn hostile; named bosses can be tamed (keep boss skills, lose boss status on reload); quest-bound pets cannot be tamed. Pets never initiate combat; follow target switching; call/ride key **T** [S] (R [A]); dead pet revives ~1 min or instantly by re-slotting cage. `/namepet <name>`. [A] pets gain XP/levels; Pet Master skill +X% pet max HP; Riding unlocked at Pet Master 5 (speed +X%/point); pets have a **hydration** meter (refill in any water) limiting riding. [S] no pet XP: pets scale with Weapon/Armor Level (and plus gear); riding needs region **Reins**; artifacts add riding speed; no hydration. Dismount on any attack, dodge, fall damage, or shift. Item shop sells 1 pet food type per day; purchasable set: Candy, Carrot, Bubble Gum, Chocolate Donut, Waffle, Cotton Candy (+Sugar Cube etc.); others drop from monsters, chests, deposits (e.g. Lollipop from an Emerald Deposit).
Pet types: Melee (most), Ranged (Snout Beetle, Spitter), Tank (Turtle; also Baby Mammoth, Bark Beetle per 1.0 guide), Healer (Spitter — its water magic trails heal owner), Mount.

| food (id) | pet | rideable (wiki / 1.0 guide) | biomes |
|---|---|---|---|
| Apple Ring (75) | Crocodile | Yes | Jungles, Oceans |
| Banana Mash (170) | Warthog [S] | Yes / No (?) | Jungles |
| Banana Split (50) | Monkey | Yes(wiki) / No(guides) (?) | Jungles, Oceans |
| Biscuit Roll (151) | Bumblebee | Yes / No (?) | Greenlands |
| Blackberry Marmalade (36) | Porcupine | Yes | Deserts, Jungles, Mountains |
| Bloodorange Juice (62) | Mosquito | Yes | Deserts, Jungles, Lava Lands |
| Buckhorn (156) | Beaver | Yes / No (?) | Greenlands |
| Bubble Gum (19) | Collie | Yes | Cities, Greenlands, Dungeons |
| Blue Jelly (40) | Blue Slime | Yes | All |
| Bread (102) | Bark Beetle | Yes | most biomes |
| Cabbage Rolls (295) | Snail [S] | Yes | Greenlands |
| Candied Apple (98) | Horse | Yes | Greenlands, Jungles, Snowlands |
| Candy (30) | Cat (black only) | Yes | Cities, Greenlands |
| Caramel Chocolate Bar (66) | Desert Runner | Yes | Deserts |
| Carrot (35) | Bunny | Yes | Forest, Plains, Greenlands |
| Cereal Bar (56) | Chicken | Yes / No (?) | Greenlands |
| Cinnamon Roll (25) | Turtle | Yes | Rivers, Greenlands, Islands |
| Chocolate Cake (91) | Raccoon | No | Greenlands, Hills, Forests, Islands |
| Chocolate Cookie (67) | Peacock | Yes | Greenlands, Forests, Hills, Islands, Jungles |
| Chocolate Cupcake (23) | Brown/Dark Alpaca | Yes | all except Deserts, Lava Lands |
| Chocolate Donut (87) | Mole | No | Greenlands, Forests |
| Chocolate Ice Cream (201) | Baby Mammoth [S] | Yes | Snowlands |
| Cotton Candy (34) | Sheep | Yes | Cities, Forests, Greenlands |
| Croissant (27) | Scottish Terrier | Yes | Cities, Greenlands |
| Curry (103) | Fire Beetle | Yes | Lava Lands, Deserts |
| Date Cookie (99) | Camel | Yes | Deserts |
| Eucalyptus Candy (89) | Koala (replaced unused "Kaliptus Leaf") | Yes(wiki) / No(?) | Jungles, Oceans |
| Fruit Basket (60) | Fly | No | Forests, Greenlands |
| Ginger Tartlet (58) | Parrot | Yes(wiki) / No(guides) (?) | Jungles, Deserts, Forests, Lava Lands |
| Green Jelly (37) | Green Slime | Yes | Deserts |
| Lemon Tart (105) | Lemon Beetle | Yes | Greenlands, Rocks, Mountains, Forests |
| Licorice Candy (55) | Crow | No(wiki) / Yes(guide) (?) | Greenlands, Forests |
| Lollipop (92) | Owl | No | Greenlands, Forests |
| Lolly (104) | Snout Beetle | Yes | Greenlands, Hills |
| Mango Juice (59) | Bat | No | Caves |
| Melon Ice Cream (61) | Midge (Seagull per gamepressure (?)) | No | Deserts, Wetlands |
| Mineral Water (192) | Radishling Sprout [S] | No / Yes (?) | |
| Mint Chocolate Bar (64) | Leaf Runner | Yes | Jungles |
| Mixed Salad (293) | Caterpillar [S] | Yes | Greenlands, Jungles |
| Pancake (88) | Biter | No | Hills, Mountains, Forests |
| Peanut (200) | Baby Elephant [S] | Yes | Jungles |
| Pink Jelly (38) | Pink Slime | Yes | All |
| Popcorn (53) | Hornet | Yes / No (?) | Greenlands |
| Pumpkin Mash (33) | Pig | Yes | Greenlands, Cities, Forests |
| Radicchio Salad (294) | Earth Caterpillar [S] | Yes | Lava Lands, Deserts, Savannahs |
| Raspberry Juice (210) | Flamingo [S] | Yes | Jungles, islands |
| (Rice) Milk Chocolate Bar (63) | Plain Runner | Yes | Greenlands |
| Salted Caramel (57) | Seagull | Yes / No (?) | Oceans, Islands, Jungles |
| Soft Ice (93) | Penguin | Yes / No (?) | Snowlands |
| Spring Water (193) | Cormling Sprout [S] | No / Yes (?) | |
| Strawberry Cake (90) | Squirrel | Yes / No (?) | Forests, Greenlands |
| Strawberry Cocktail (106) | Crab | Yes / No (?) | All |
| Sugar Candy (74) | Duckbill | Yes | Rivers |
| Vanilla Cupcake (22) | Alpaca (light) | Yes | all except Lava Lands |
| Waffle (26) | Terrier | Yes | Cities, Greenlands, Forests, Plains |
| Water Ice (86) | Spitter | No | Oceans, Rivers, Lakes |
| White Chocolate Bar (65) | Snow Runner | Yes | Snowlands |
| Yellow Jelly (39) | Yellow Slime | Yes | Deserts |
Unreleased/unobtainable foods: Apple Pie (Wolf), Liquid Drop (Cow), Charred Steak (Imp), Wasabi Sauce (Devourer), Kaliptus Leaf (Koala, replaced), Banana Mash (Warthog; listed obtainable by 1.0 guides). Untameable notable: Wolf (alpha only), Cow, Shark, Shepherd Dog, Skeleton Horse, Lantern Fish. Bug: in 1.0.0-1 all pets were rideable (fixed later) — explains rideability conflicts above.
Sources: wiki:Pets, wiki:Pet_Food, wiki:Mount_Pets/Melee_Pets/Ranged_Pets/Tank_Pets/Healer_Pets, wiki:Riding, wiki:Pet_Master, wiki:Reins, per-pet wiki pages (Infobox pet), https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729 , https://steamcommunity.com/sharedfiles/filedetails/?id=1865509515 , https://steamcommunity.com/sharedfiles/filedetails/?id=1879943518 , https://www.gamepressure.com/cubeworld/taming-and-locating-pets/zfca65

---

## 6. Special / key items, artifacts, quest items

### 6.1 Key Items ("Specials", Special inventory tab)
| item | [A] | [S] |
|---|---|---|
| Hang Glider | bought from item vendor; needs Climbing 5; speed via Hang Gliding skill points; key **E** to deploy; space = level off (costs stamina); attacking/crash puts it away; can't redeploy midair | found per region via NPC-hinted quest; region-locked; speed via artifacts (bugged, see 6.2) |
| Boat | bought; needs Swimming 5; Sailing skill = speed; key **G** [A] / E [S]; surfaces if deployed underwater | per region (ocean regions always have one); artifacts add sailing speed |
| Reins | n/a (Pet Master 5 unlocks riding) | per region; required to mount; T to ride |
| Climbing Spikes | (skill Climbing reduces stamina drain) | per region from a 1★ mission; infinite climbing without stamina |
| Divine Harp ("Divine Tune") | – | opens golden "iris" doors / Vaults; doors re-close each new day |
| Sky Whistle | – | play at bird statue → birds carry you to a floating island |
| Spirit Bell | – | enter Spirit World 30 s; pass through crypt gates |
| Treasure Spirit | – | bonus item; hovers toward nearby treasure (money bags / equipment) |
| Eternal Ember | – | dropped by restless warrior at a Circle of Power; light brazier → power boost region-wide; several per region; multiplayer drops one per participant |
| Iron Lamp | equippable item (see §4) | innate F ability |
| Books of Crafting (Magic/Rare/Epic/Legendary) | – | listed as Specials by guides |
Groupings [S]: "Movement Items" = Boat, Climbing Spikes, Hang Glider, Reins (4 per region); "Ticket Items" = Divine Harp, Sky Whistle, Spirit Bell (3 per region); wiki: "up to 9 unique Key Items per region"; not every region spawns every item (depends on region type/size). Key items show in top-left HUD when collected. Alpha special-accessory data also lists Key, Jewel Case, Medicine, Antivenom, Band-Aid, Crutch, Bandage, Salve (planned quest items, unused). 1.0 also has region **keys** (Gold/Silver/Copper keys for locked dungeons/mansions; boss keys for gnome cages; patch 0.9.1-6 "keys no longer removed from inventory when opening gates").
Sources: wiki:Key_Items, wiki:Hang_Gliding, wiki:Boat, wiki:Reins, wiki:Climbing_Spikes, wiki:Divine_Harp, wiki:Divine_Tune, wiki:Vaults, wiki:Sky_Whistle, wiki:Spirit_Bell, wiki:Treasure_Spirit, wiki:Eternal_Ember, wiki:Circle_of_power, wiki:Movement_Items, wiki:Ticket_Items, wiki:Skill_Points, https://steamcommunity.com/app/1128000/discussions/0/1628538707071528179/

### 6.2 Artifacts [S] (Artifacts tab; work in ALL regions)
- Replace XP: **each artifact found = +1 character level** ("Level = how many artifacts you have found"). They are the region's "main objective" (Wollay tweet). Each region has a set number of artifacts; reaching 100% lore reveals all of them on the map (orange circle marker).
- Each artifact increases ONE of exactly 7 non-combat stats: **Climbing Speed, Swimming Speed, Diving Skill (stamina/HP loss underwater), Riding Speed, Hang Gliding Speed, Sailing Speed, Light (lamp) Radius**. Never combat stats.
- Tooltip format: "RING OF MOMUNA — Realm of Vakaa — Increases hang gliding speed." (image, wiki:Ring_of_Momuna). Names are generated: `<Ring|Stone|…> of <Name>` tied to a lore Realm/Kingdom (e.g. Ring of Momuna, Sirazyna Stone). Wiki calls them "Relics" of the realm.
- Magnitude: **diminishing** per artifact; players report tiny values e.g. "−0.4 stamina loss underwater", "~2% swimming speed", "about 5% of current value" (community; no official numbers **(?)**).
- Bugs: Swimming, Sailing, Diving, Light Radius work; Riding, Climbing, Hang Gliding bonuses reportedly do nothing (never fixed).
- Sources: found at end of dungeons/castles/vaults, sewers under 5★ villages, some mission chests; "Dropped artifacts can be looted by all players" (0.9.1-4); artifact quests marked cleared on loot.
- Community mod Cubegression-Light maps each artifact type to a combat stat (+10 HP / +1 armor / +1 dmg / +0.075 haste / +0.25 regen / +0.75 crit / +1 resistance) — not vanilla.
Sources: wiki:Artifacts, wiki:Relic, wiki:Ring_of_Momuna, wiki:Sirazyna_Stone, wiki:Kingdom, wiki:Diving, wiki:Iron_Lamp, https://steamcommunity.com/app/1128000/discussions/0/1693843461192230315/ , https://steamcommunity.com/app/1128000/discussions/0/1628538644182949548/ , https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729 , https://github.com/LockManipulator/Cubegression-Light , https://devtrackers.gg/cube-world/p/d7ef558d-tweets-by-wol-lay-on-12-oct

### 6.3 Alpha skill tree items-adjacent [A]
2 skill points per level (Levels page) — gamepressure says 1 **(?)**; passive skills: Pet Master (+X% pet HP) → Riding (5 pts); Swimming (+X% swim) → Sailing (5 pts; boat speed); Climbing (−X% stamina drain) → Hang Gliding (5 pts; glide speed). Dodge costs 25% stamina. Respec at class trainers in town.

---

## 7. Economy

### 7.1 Currency
- [A] Copper / Silver / Gold: 100 copper = 1 silver, 100 silver = 1 gold; displayed in inventory; pick up with R. **Platinum Coins** from bosses/active missions → Adaptation only.
- [S] single "Coins" counter top-left; auto-collect by walking over; items still need E. Bosses ≈ 20 gold; monsters 1–3; mana generators 1–3; gems sell 5/7/10/14 (Emerald/Sapphire/Ruby/Diamond); legendary equipment sells 8–14, legendary+ 20; Arena 18–50; Bag of Gold (sky statues, chests, hidden) 25–59. Alpha: monsters lvl1–30 drop 10 copper–1 silver; equipment +1..+100 sells 20 copper–1 silver 50 copper.
- [S] costs: Inn sleep 10 coins; Flight Master min 100 (scales with distance; free to friends); gem trader 100/200/400/800; Glass Flask 1 coin; Legendary weapon (+) ~1800 coins at vendor; identification fee scales with level/quality; guild specialization swap small fee/free.
- Patch 0.9.1-4 removed sell price from tooltips. [S] shops have a buy-back tab; [A] sales are final. Off-class drops considered near-worthless to sell (community). Money described as abundant in 1.0.
Sources: wiki:Coin, wiki:Platinum_Coins, wiki:Inn, wiki:Flightmaster, wiki:Gems, wiki:Shop, wiki:Item_Shop, 0.9.1-4 notes.

### 7.2 Shops (Trade District; signs on map)
| shop | sells | notes |
|---|---|---|
| Weapon Shop / Weapon Vendor (sword sign) | weapons [A] +1..+100 any class; [S] Worn until gnomes rescued | buys anything |
| Armor Shop / Armor Vendor (chestplate sign) | armor | buys anything |
| Item Shop / General store / Item Vendor | [A] materials, Pet Food, Formulas, Iron Lamps, Hang Gliders, Boats, Sugar Cubes, Glass Flasks; [S] Glass Flasks, Bombs, Sugar Cubes, 1 pet food/day, legendary rings/amulets after 4 gnomes | |
| Identifier's Shop (magnifying glass) / Analyst [S] | identifies Leftovers only; does not buy | |
| Gem Trader [S] | roaming gnome; sells gems, buys anything on the go; fights nearby enemies | |
| Inn / Tavern | sleep 18:00–06:00 to advance to 7:00 (10 coins [S]); beds heal | |
| Guild Master / Receptionist | specialization swap | |
| Flight Master [S] | fast travel | |
| Adapter [A] | adaptation | |
Stock resets daily (alpha: identical stock, must travel; 1.0: new stock each day). Gnome supplier rescue count → stock rarity. Interaction key E [S] / R [A].
Sources: wiki:Shop, wiki:Trade_District, wiki:Weapon_Shop, wiki:Armor_Shop, wiki:Item_Shop, wiki:Armor_Vendor, wiki:Weapon_Vendor, wiki:Identifier's_Shop, wiki:Gem_Trader, wiki:Inn.

### 7.3 Loot / drop rules
- Drops are random by enemy tier/strength — no fixed tables except species items (Parrot Feather, Onion Slice, Radish Slice, Coins, Spirit Cubes). NPCs sometimes drop what they wield. Same-color enemies drop Leftovers of your tier. Boss [A]: guaranteed Spirit Cube each kill + gear of same +N. Enemies/objectives drop rarity ≈ their tier, can be ±1.
- Dungeons [A]: spike traps, breakable vases, small chests, items on tables; chest in +4 dungeon may roll +1 rarity ("mythical"). [S]: no vases/tables; chests one-time; multiple bosses of rising tier; artifact at end.
- Missions [S] (Side Missions): reward ≥1 class-fitting piece usually one rarity above quest color, coins, 1 healing potion, gems by color; sword-icon missions repeatable daily; arenas (5 waves, final purple/yellow boss) daily.
- Dropped items on ground last ~1 in-game week then reset; drop via middle-click in inventory (used for trading between players/characters).
- Hidden treasure: logs, sky statues, hidden caves; Treasure Spirit points to it; treasure counter per region.
Sources: wiki:Formulas (Loot Drops), wiki:Bosses, wiki:Dungeon, wiki:Side_Missions, wiki:Arena, wiki:Items, https://steamcommunity.com/sharedfiles/filedetails/?id=2899669576

---

## 8. Inventory & UI
- Open **B** (or ESC → backpack). Tabs: **Equipment** (weapons, shields, chest, gloves, shoes, neck, 2 rings, pet slot), **Special** [S] (region key items, Eternal Ember, Treasure Spirit), **Items** (formulas, leftovers, candles), **Ingredients**, **Pets** (pet cages + pet food; pet/food equipped here), **Artifacts** [S]. Alpha had Amulets tab for rings. Left/right-click auto-equips into the correct slot (class check). [S] one inventory page per visited region (bottom arrows).
- Capacity: **no fixed slot limit** — "You don't have any set inventory space and the items stack" [S guide]; items stack (a 1.0 mod exists to "remove limits on all item stacks", so vanilla stacks are capped — cap value undocumented **(?)**, "only one of each pet food" is the documented hard cap).
- Quick slot bar: M1 normal attack, M2 special, keys 1–4 abilities [A], **Q** quick item (potion/food/bomb) chosen via Quick Select wheel (A/D to cycle; count shown); alpha Q defaults to first inventory item — order potions first. **E** special item (glider/boat) [S], G boat [A], **F** lamp, **T** call/ride pet [S] (R [A]), X skills [A], C crafting, M map.
Sources: wiki:Inventory, wiki:Quick_Select, wiki:User_interface, wiki:Items, https://steamcommunity.com/sharedfiles/filedetails/?id=1871883807 , https://kotaku.com/tips-for-playing-the-cube-world-alpha-885739884

---

## 9. Version deltas (alpha → 1.0) relevant to items
Removed in 1.0: XP/levels/skill points, item power level display, Adaptation & Platinum Coins, Spirit Cubes, Formulas, copper/silver coins, vendor-sold gliders/boats/lamps, pet XP & hydration, dungeon vases/tables/spike traps, breath-forever swimming.
Added in 1.0: region lock + plus items, Artifacts (7 travel stats, leveling), Key Items per region (Harp, Whistle, Bell, Reins, Spikes, Treasure Spirit, Eternal Ember), Books of Crafting, Gnome Suppliers, Gem Traders, Elixirs & Beverages, Leftover identification "Analyst", buy-back tab, Diving (drowning), Arena, Flight Master, gear-scaled pets, Mob Strength colors, Bag of Gold, region-bound bombs.
Beta patch notes (Sep 24–29 2019) item-relevant: snowberry mash craftable; frozen heartflowers spawn in snowlands; dungeon items bound to correct land; keys kept after opening gates; can't drop pet food while using it; harp usable in water; plus-equipment counted for notifications and pet scaling; sell price removed from tooltip. Sources: wiki:0.9.1-3 … 0.9.3-0.

## 10. Cube World Omega (2023–2025)
- Announced 25 May 2023 (wollay.com): new Vulkan engine, weather, GUI revamp; "planning to bring back experience, leveling and skill trees"; **all models procedural** — players, NPCs, pets **and equipment (weapons & armor)** uniquely generated by algorithm. 13 Jun 2023 post shows "first basic procedurally generated equipment for warriors"; 6 Jun 2023 ogres carry procedurally generated wood maces; armor mechanic teased: enemy combo points progressively penetrate armor (zombie post). Later posts (Jun–Oct 2023): slimes/crabs/hornets/hedgehogs with signature abilities, new world gen. 2024: Wollay tests Unreal Engine 5 (Feb 2024), progress clips Apr–Jun 2024; last public update ~7 Jun 2024; no release date, unknown if free update or new game (as of Jan 2025 MassivelyOP). No item/crafting/economy specifics published.
Sources: https://wollay.com/2023/05/25/new-blog-and-new-project-cube-world-omega/ , https://wollay.com/2023/06/13/frogmen-lizardmen-playable-races-procedural-weapons-armor/ , https://wollay.com/2023/06/06/oh-no-ogres/ , https://wollay.com/feed/ , https://x.com/wol_lay/status/1753019613753852220 , https://x.com/wol_lay/status/1781000511635722461 , https://massivelyop.com/2025/01/06/whatever-happened-to-multiplayer-voxel-rpg-cube-world-and-its-successor-cube-world-omega/

## 11. Known gaps / unresolved
- Exact vendor buy/sell price formula per rarity/level (only anecdotes: 1800 for legendary+ weapon, 8–20 sell).
- Exact alpha weapon recipe quantities per weapon type (only "5 iron cubes" and cotton armor table).
- 1.0 stat formula (coremaze code is alpha 0.1.1; 1.0 changed to tier-based scaling — unverified whether same curve).
- Vanilla stack size cap; exact artifact percentage values; exact number of artifacts per region.
- Whether Life Potion needs campfire (wiki tables disagree).
- Mana Potion existence in-game (only in data enum).
