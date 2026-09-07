# Cut world features & mechanics (X → follow-up)

## Mushroom Lands (landscape)
Planned 2013 ("giant mushrooms and huge insects"), never shipped. Hooks: `landscapes.json`
entry exists; needs climate band, palette, giant-mushroom flora (new `flora` with block type
leaves/trunk), insect roster (beetles, hornets, mantis, bloomlings scaled up), a dungeon type.
Doc: https://cubeworld.fandom.com/wiki/Mushroom_Lands , https://cubeworld.fandom.com/wiki/Landscape

## Kingdom frontier walls with guards
Devlog 2012-02-27: lands ("kingdoms") separated by walls with gated guard posts. Alpha only
showed a visible frontier line; 1.0 has dotted map borders. Hooks: `poi-type: kingdom-wall`,
`gen-terrain` road gates, `npc-role: guard` schedule; hostility toward players of a rival realm
could tie into `realm` lore. Doc: http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_02_01_archive.html

## Dungeon rune stone (port back after clearing)
Static entity 45 `RuneStone` at dungeon entrances (devlog 2012-02-27) to teleport back out once
the boss is dead. Hook: `static-entity` behaviour + `dungeon-type.entrance` flag; cheap to add.
Doc: same devlog; https://cubeworld.fandom.com/wiki/Portals (alpha portals for comparison)

## Fire trap & stomp trap
Static entities 6 and 8 exist; only spike traps (7) shipped. Devlog 2012-02-10 shows fire jets
and levers (9). Hooks: `status-effect: burning` source, `gen-dungeon` trap table, lever→gate
puzzles. Doc: http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_02_01_archive.html

## "Injured" death debuff
Devlog 2012-10-12: respawn with reduced max HP for several minutes, band-aids on the back,
cured by eating. Released alpha and 1.0 have **no** death penalty. Hook: `status-effect: injured`
already listed (X); needs duration, HP %, and `consumable` cure tag; pairs with quest accessories
band-aid/bandage/salve/medicine. Doc: http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_10_01_archive.html

## Pet Quarter (city district)
Quarter id (1,4) "Pet Quarter" in alpha name tables, never generated. Hook: `buildings.json#districts.pet`
with a pet master NPC (rename/heal/store pets, sell pet food). Doc: https://github.com/matpow2/cuwo/blob/master/cuwo/strings.py

## Paladin class
Mentioned as a possible future class in 2012; Order of the Light paladins exist as NPCs in 1.0.
Hook: fifth `character-class` (weapon set? mace + shield / greatmace; armour iron; specs e.g.
Crusader / Templar), skill-tree column, `npc-role` reuse. Doc: https://gamersnexus.net/gg/962-everything-about-cube-world , https://www.siliconera.com/cube-world-is-still-alive-gets-demons-ghosts-and-necromancers/

## Throwable metal disks for rangers
Devlog 2013-01: a fourth ranger weapon idea. Hook: `weapon-types.json` new subtype (2H, boomerang
moveset variant). Doc: http://web.archive.org/web/2014/http://wollay.blogspot.com/2013_01_01_archive.html

## Lock-on targeting
Existed Nov 2011, removed Mar 2012 ("fight freely"). Hook: optional accessibility toggle in
`ui.json#options`. Doc: http://web.archive.org/web/2014/http://wollay.blogspot.com/2011_11_01_archive.html

## Alpha portals (teleport rune stones)
Removed in 1.0 (flight masters instead). Hybrid ruleset **keeps** them (`flags.portals = true`),
so this is v1, listed here only for the 1.0 delta. Doc: https://cubeworld.fandom.com/wiki/Portals

## Homepage item/monster database
Devlog 2012-07: planned online database of items and monsters. Hook: export `ontology/instances`
to a static site. Doc: http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_07_01_archive.html
