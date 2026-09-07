# Omega: per-species signature abilities (Ω → follow-up)

**Status:** design principle stated in the 2023 devlog: "every creature gets signature abilities".
v1 creatures use the alpha/1.0 behaviour set (generic melee/ranged/mage moves, a few bespoke boss
moves in `generators.json#boss.special-pool`, and `creatures.json#abilities`).

## Announced signature abilities
| species | ability | mechanics shown | post |
|---|---|---|---|
| Zombie | **Eat** | grabs the player, immobilises, drains HP while healing itself; armour penetration grows with its combo; escape by dodge, stun or mobility skill | 2023-05-31, 2023-06-01 |
| Bat | **Vampiric Bite** | life drain | 2023-05-31 |
| Ogre | **Belly Slide** | charge on the belly: damage + stun on hit | 2023-06-06 |
| Slime | **Divide** | below 50 % HP splits into smaller copies at full HP | 2023-06-26 |
| Crab | **Claw Boomerang** | throws a claw as a ranged returning projectile (to be made occasional) | 2023-06-26 |
| Hornet | **Poison Sting** | applies poison | 2023-10-14 |
| Hedgehog (new species) | **Spike Swirl** | radial spike burst | 2023-10-14 |
Also mentioned: enemy combo points progressively penetrate armour (same rule players have).

## Ontology hooks when picked up
- `creature.signature-ability` → `ability` ref with `owner: creature:<id>`; abilities.json already
  holds `_omega-signature` stubs — promote them to full entries (kind active, cost none, cooldown,
  telegraph time, effect, `applies` status effects).
- New status effect `grabbed` (immobilised + drain; broken by dodge/stun/mobility skill).
- `gen-spawns` invariant: a divided slime's children inherit tier/colour, count capped (e.g. ≤ 4
  per original) to avoid runaway splitting.
- Boss-ification (`gen-boss`) should prefer the species' signature ability over the generic pool.
- Add `hedgehog` to `creatures.json` (currently `v: ["Ω"]`, no lands) with a greenlands/forest
  roster slot and a pet food (new subtype ≥ 300).

## Design notes
- Give every existing species at least one signature move over time; start with the seven above
  plus the already-known alpha/1.0 moves (troll earthquake, cyclops charge/cyclone, djinn summon,
  snout beetle charged shot, rockling boulder, witch/wizard ray, skeleton knight mount).
- Telegraph every signature move (cast bar — see omega-ui-progression.md) so stun/dodge counters
  stay readable.

## Online documentation
- https://wollay.com/2023/05/31/ (zombies, vampiric bite) · https://wollay.com/2023/06/01/ (eat)
- https://wollay.com/2023/06/06/oh-no-ogres/ (belly slide)
- https://wollay.com/2023/06/26/ (slimes divide, crabs claw boomerang)
- https://wollay.com/2023/10/14/ (hornets, hedgehogs)
- Feed: https://wollay.com/feed/
- Existing boss/enemy AI notes: https://cubeworld.fandom.com/wiki/Bosses , http://web.archive.org/web/2014/http://wollay.blogspot.com/2013_01_01_archive.html
