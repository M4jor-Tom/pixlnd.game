# Omega: weather & ambient life (Ω → follow-up)

**Status:** announced 2023-05-25 for Cube World Omega (new Vulkan engine); shown in videos; no
release. Alpha and 1.0 have **no weather** at all ("not that there is any wind or other weather
system" — clouds are static voxel structures without collision; grass sway is pure animation).

## Announced features
- **Rain** and **snow** as weather states.
- **Moving clouds** (vs static alpha clouds), **jiggling leaves**, **water waves**.
- **Freezing water** in cold areas: frozen surface becomes walkable with **slippery ice physics**.
- Ambient life (world-gen post 2023-07-30): butterflies near flowers, moths around street
  lights at night, water lilies bobbing with waves, chimney smoke, turning windmill wheels.
- Time-of-day already existed; Omega adds cast-shadow/lighting work (secondary reports).

## Ontology hooks when picked up
- `weather-state` class: id (clear, rain, snow, fog?), intensity, allowed climate bands
  (`climate.temperature`/`humidity`), transition rules, duration range; per `land` current state.
- `game-clock.weather` property replaces the "none" note; `generators.json#time` gains a
  weather schedule seeded per land per day.
- Effects: rain → puddles/wet blocks (1.0 already has block type 3 "wet"), snow → snow cover
  accumulating on grass/leaves (block types 10/11), freezing → water columns become walkable
  ice with a `slippery` movement modifier (new `status-effect: on-ice`).
- `terrain-feature: cloud` gets `moving: true` and a drift vector.
- `ambient-emitter` static entity kind: flowers → butterflies, street lights → moths (night),
  chimneys → smoke, water → lilies. Purely cosmetic; no gameplay.
- Stealth already depends on light; rain/fog could reduce enemy perception radius (design).

## Constraints / invariants
- Weather never blocks traversal except ice slipperiness; no damage from weather (hazards stay
  cold-water / toxic / lava).
- Snow presence today is tied to temperature (`landscapes.json`); weather must not contradict
  a land's base climate (no snow in lava lands).

## Online documentation
- Announcement: https://wollay.com/2023/05/25/new-blog-and-new-project-cube-world-omega/
- World generation & ambient video: https://wollay.com/2023/07/30/
- Blog feed (all Omega posts): https://wollay.com/feed/
- MassivelyOP summary: https://massivelyop.com/2023/05/26/cube-world-creator-emerges-from-hibernation-to-announce-cube-world-omega/
- Alpha clouds (no weather): https://cubeworld.fandom.com/wiki/Cloud
- Moving-clouds alpha mod (prior art): https://paroyer.github.io/ModCatalogue/Alpha.html
