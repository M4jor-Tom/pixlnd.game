# House building & blueprints (X → follow-up)

**Status:** prototyped by Wollay Jan 2012, never shipped in alpha or 1.0. FAQ (Nov 2011): "House
building is supported. I'm not planning to add mining or digging."

## What existed (devlog 2012-01-19 / 2012-01-24)
- **Construction plans**: modular building pieces of **10×10×10 voxels** — wall, corner, window
  wall, roof — placed with a 3-D cursor; snapped on a grid; a "framework house" style shown.
- **Blueprints GUI**: collectable cards with a rotating 3-D preview of the piece.
- **Architect NPC** in villages sells/gives blueprints.
- **Teleport home** planned so the player can return to the built house.
- Player houses were meant to coexist with procedural villages (2012-10: house themes European
  framework, medieval stone, North-American wood, log; desert/jungle planned).
- Related cut NPC: **Disenchanter** (iron cubes from gear) — same devlog batch.

## Ontology hooks to add when picked up
- `building-piece` class (id, size 10³, category wall/corner/window/roof/door/stairs, style,
  material cost) → `instances/building-pieces.json`.
- `blueprint` item type (new `item-type`, subtype = piece id) sold by `npc-role: architect`.
- `player-structure` (owner, land, pieces[] with grid pos + rotation) persisted in `save-data`.
- Constraint: pieces snap to a 10-block grid; must sit on solid ground or another piece; cannot
  overlap procedural buildings, dungeons or roads.
- Generator hook: `gen-settlement` reserves a free lot per village for player builds.
- Key item / ability: `teleport-home` (cooldown, only from outside dungeons).

## Design notes
- Keep it additive: pieces are static entities (like `static-entity`), not terrain edits, so no
  digging/mining is implied.
- Multiplayer: ownership per player; friends may enter, not edit (D5 pending).
- Style should follow `buildings.json#settlement-styles` of the land it is built in.

## Online documentation
- Devlog Jan 2012 (Wayback): http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_01_01_archive.html
- FAQ Nov 2011 (building supported, no mining): http://web.archive.org/web/2014/http://wollay.blogspot.com/2011_11_01_archive.html
- House themes devlog Oct 2012: http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_10_01_archive.html
- Wiki FAQ mirror: https://cubeworld.fandom.com/wiki/Cube_World
- GamersNexus 2012 feature round-up: https://gamersnexus.net/gg/962-everything-about-cube-world
