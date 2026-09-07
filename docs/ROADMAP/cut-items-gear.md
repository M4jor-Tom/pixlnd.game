# Cut / unobtainable items & gear (X → follow-up)

Entries tagged `X` in `materials.json`, `item-types.json`, `consumables.json`, `rarities.json`.

## Armour sets that exist in data but cannot be obtained
| material | id | intended source | why unobtainable | source |
|---|---|---|---|---|
| Bone | 7 | zombie/skeleton bones | bones never drop | wiki:Bone_Armor |
| Saurian | 18 | Saurian boss hide | no drop | wiki:Saurian |
| Mammoth | 20 | Mammoth Hides | 0 % drop rate | wiki:Mammoth_Armor, wiki:Mammoth_Hides |
| Parrot | 19 | Parrot Feathers (do drop) | recipe never appears in menu | wiki:Parrot_Armor |
| Obsidian | 5 | 2012 obsidian armour & swords | removed; cheat-only | wiki:Obsidian_Armor |
| Silver / Gold armour | 12 / 11 | — | only rings/amulets/bracelets use them | wiki:Silver_Armor, wiki:Gold_Armor |
All were "medium armour, any class" — a class-agnostic armour tier the shipped game lacks.
Alpha stat multipliers already known (saurian armour 0.8, parrot 0.85 armor / 0.85 resi).

## Unused weapon subtypes
Arrow (9), Arrows (14), Fork (18, 2H damage k = 8), Pickaxe (19), Torch (20). Fork could become a
Frogman/fisher weapon; Pickaxe conflicts with "no mining" — keep cut.

## Consumables
- **Mana Potion** (type 1 subtype 3): in data, never craftable. Hybrid ruleset has MP as a real
  resource, so a recipe (water flask + manaorchid?) is a cheap add.
- **Cookie** (1/0): 2012 pet-heal item; unused.
- **Potion rarities** (Pixxie 2015): uncommon/rare/epic life potions with distinct colour ramps —
  never shipped; consumables already carry `rarity` and heal scales with it (`× 2^(0.25·r)`).
- **Flowers with rarities** (pix_xie 2015-10-14).

## Quest accessories (item type 21)
amulet1, amulet2, jewel-case, key, medicine, antivenom, band-aid, crutch, bandage, salve — tied to
procedural-quests.md and the cut "injured" debuff (cut-world-mechanics.md).

## Mythical rarity (alpha bug)
+4 dungeon chests rolled rarity 5 (one above legendary): red text in the Leftovers list, otherwise
rendered as common. Could become a real 6th tier ("Mythical", red, ★★★★★★) with its own affix
list and gem; currently `rarities.json#mythical` and `generators.json#item.mythical-bug=false`.

## Data-only item types
Beak (15), Painting (16), Vase (17), Block (10) — decorative/inventory oddities; candidates for
house-building.md furnishing.

## Ontology hooks when picked up
- Set `materials.json` `obtainable: true`, add `raw`/`refined` chains and drop sources on the
  matching creatures (`creature.drops`), add recipe rows to `recipes.json#gear-armor-quantities`
  (medium armour uses hide/feather/bone units instead of yarn/cubes).
- Add `class: any` armour weight "medium" to `classes.json` armour rules and `c-weapon-class`.
- Mana potion recipe in `consumables.json`; potion rarity affects heal only (already modelled).

## Online documentation
- https://cubeworld.fandom.com/wiki/Bone_Armor , /Mammoth_Armor , /Mammoth_Hides , /Parrot_Armor , /Obsidian_Armor , /Saurian , /Silver_Armor , /Gold_Armor
- https://cubeworld.fandom.com/wiki/Potions , /Rarity , /Leftovers , /Items
- Alpha item tables: https://github.com/matpow2/cuwo/blob/master/cuwo/strings.py ; stat RE: https://github.com/coremaze/Cube-World-Weapon-Stats/blob/master/Stats.py
- Obsidian devlog Feb 2012: http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_02_01_archive.html
