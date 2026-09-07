# Cut / unused creatures & pet content (X → follow-up)

Everything here has an entry in `ontology/instances/creatures.json` or `pet-food.json` tagged `X`.

## Creatures present in data, never functional
| id | alpha entity id | facts | source |
|---|---|---|---|
| dragon | 101 | boss species; "won't work when spawned"; wiki: "may be confined to special landscapes" | wiki:Dragon |
| egg | 24 | entity with no behaviour | cuwo strings.py |
| bullterrier | 6 | dog variant, no wiki page | cuwo strings.py |
| old-man | 18 | quest giver (see procedural-quests.md) | wiki:Old_Man |
| chiling-sprout | — | unused smaller Chiling | wiki:Chiling |
| skull-slater (unmasked) | — | unused variant | wiki:Skull_Slater |
| undead mummies for pyramids | — | devlog 2011-07 idea | devlog |

## Cut pet foods (tames were designed, foods never obtainable)
| food | tames | source |
|---|---|---|
| apple-pie | wolf (alpha-only creature) | wiki:Apple_Pie |
| liquid-drop | cow | wiki:Liquid_Drop |
| charred-steak | imp | wiki:Charred_Steak |
| wasabi-sauce | devourer | wiki:Wasabi_Sauce |
| kaliptus-leaf | koala (replaced by eucalyptus candy) | wiki:Kaliptus_Leaf |
| banana-mash | warthog (1.0 guides say obtainable; wiki says cut — verify) | wiki:Pet_Food |

## Cut pet systems
- **Rare pets** and **pet evolution** (wiki:Pets "planned").
- Alpha pet XP/levels never persisted in multiplayer (bug, not cut) — fix in v1.
- Pixxie 2015 tweet: potions/flowers with rarities (see cut-items-gear.md).

## Species with version conflicts to resolve before adding
Panther (29), Spectrino (80), Rune Giant (118), Duckbill (74), Ancient Guardians (77/78): ids exist
in alpha tables but the wiki says "not in alpha". Treat as S creatures with alpha ids reserved.

## Ontology hooks when picked up
- Flip `versions` from `X` to the shipping tag; give dragon a `boss` moveset in
  `generators.json#boss.special-pool` (fly, fire breath, landing stomp) and a landscape roster
  (lava-lands, mountains).
- Add the six foods to `pet-food.json#foods` with new subtype ids ≥ 300 (avoid alpha collisions).
- `pet.evolution` (stage, xp thresholds, model swap) and `creature.rare-variant` (palette + stat
  multiplier, low spawn chance) as new properties; rare pets drop from rare zones (`land.rarity`).

## Online documentation
- Wiki bestiary index: https://cubeworld.fandom.com/wiki/Mobs , https://cubeworld.fandom.com/wiki/Pets , https://cubeworld.fandom.com/wiki/Pet_Food
- Pages: https://cubeworld.fandom.com/wiki/Dragon , https://cubeworld.fandom.com/wiki/Old_Man , https://cubeworld.fandom.com/wiki/Apple_Pie , https://cubeworld.fandom.com/wiki/Liquid_Drop , https://cubeworld.fandom.com/wiki/Charred_Steak , https://cubeworld.fandom.com/wiki/Wasabi_Sauce , https://cubeworld.fandom.com/wiki/Kaliptus_Leaf , https://cubeworld.fandom.com/wiki/Chiling , https://cubeworld.fandom.com/wiki/Skull_Slater
- Alpha entity/name tables: https://github.com/matpow2/cuwo/blob/master/cuwo/strings.py
- Steam pet guide: https://steamcommunity.com/sharedfiles/filedetails/?id=1873333729
