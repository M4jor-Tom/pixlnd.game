# Omega: coarse-map-first world generation (Ω → follow-up)

**Status:** described and shown in the 2023-07-30 devlog post "New World Generation". v1 keeps the
alpha/1.0 approach: terrain, structures and roads generated per zone on the fly from noise + land
seeds (`generators.json#world-scales`, `gen-terrain`, `gen-settlement`, `gen-dungeon`).

## Announced approach
1. For each **region** a **coarse map** is generated first, in which "all streets, buildings,
   rivers, bridges, trees, caves etc. are placed and **connected in a logical way**".
2. Detailed voxel terrain is generated from that map as players explore (still on the fly).
3. Shown in video: cave entrances/exits, rural areas with fields, windmills, farms, paths from
   every structure to a main road, fenced wheat fields, river crossing with bridge, village with
   watchtowers, walls, iron fences, stone roads, street lights.
4. Planned uses: the region map drives **NPC navigation** (villagers travel to distant places)
   and **quest design** (procedural-quests.md).

## Why it matters
- Fixes 1.0's "infinite sprawling land mazes" (BetterBiomes mod complaint) and disconnected POIs.
- Guarantees reachability: every dungeon/POI is on a road; rivers always have a crossing.
- Enables realm-level lore consistency (capital, tombs, ruins placed with intent).

## Ontology hooks when picked up
- New generator `gen-coarse-map` (already stubbed in `domain.md §6` and
  `generators.json#coarse-map-omega`): input land seed → graph of nodes (settlement, dungeon,
  poi, cave mouth, bridge, field, windmill) and edges (road, river, path), each with a coarse cell
  position. Output feeds `gen-terrain` (carve rivers/roads first), `gen-settlement`, `gen-poi`.
- `land` gains `coarse-map` (serialisable, seed-reproducible) and `road-graph`.
- `npc-role.schedule` may reference nodes in other settlements (travelling merchants, pilgrims).
- Invariants to test: graph connected; every structure has a path to a main road; no road
  crosses water without a bridge node; caves have ≥ 1 entrance and ≥ 1 exit; field/windmill
  nodes only near settlements; region borders stitch (roads continue into neighbours).
- Static entities to add: windmill (animated wheel), fence-iron, watchtower, wall segment,
  bridge (already implied by 2011 road generator).

## Design notes
- Coarse cell ≈ one alpha zone (256 blocks) or 4×4 steam zones is a reasonable first resolution;
  the 8×8 mission grid per region (`MISSIONS_IN_REGION`) already hints at a coarse lattice.
- Keep `gen-terrain` noise for micro-detail; the coarse map only dictates macro placement.

## Online documentation
- New world generation post + video: https://wollay.com/2023/07/30/
- Feed: https://wollay.com/feed/
- 2011 road generator (tunnels/bridges): http://web.archive.org/web/2014/http://wollay.blogspot.com/2011_07_01_archive.html
- 2012 lands/capitals devlog: http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_10_01_archive.html
- Alpha region/zone scales: https://github.com/matpow2/cuwo/blob/master/cuwo/constants.py
- 1.0 zone layout (CWSDK): https://github.com/ChrisMiuchiz/CWSDK
- BetterBiomes mod (continent grouping): https://www.nexusmods.com/cubeworld/mods/3
