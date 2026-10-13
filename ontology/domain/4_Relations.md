## 4. Relations

One row per fact type. Cardinality as `domain → range`.

| id | domain | range | card. | meaning |
|---|---|---|---|---|
| has-specialization | character-class | specialization | 1→2 | |
| uses-weapon | character-class | weapon-type | 1→3 families | |
| wears-material | character-class | material | 1→1 | iron/linen/silk/cotton |
| grants-ability | specialization ∪ character-class | ability | 1→n | versioned |
| unlocks-next | ability | ability | 1→0..1 | alpha tree: 5 points |
| bound-to-input | ability | input-binding | 1→1 per version | |
| costs | ability | resource | 1→0..n | amount per resource, scoped by ruleset |
| applies | ability ∪ weapon-type ∪ hazard | status-effect | n→n | |
| has-moveset | weapon-type | ability (m1, m2) | 1→2 | |
| knows-recipe | player-character | recipe | n→n | one known fact per character/recipe, shared by books and formulas (`known-recipes`), even while power-locked; knowledge alone does not grant crafting usability; recipes persist across lands/sessions/worlds (§3.7 save-data), not shared-account knowledge |
| crafted-at | recipe | crafting-station | 1→1 | |
| consumes | recipe | ingredient ∪ material | 1→n | with counts |
| produces | recipe | item-type ∪ consumable | 1→1 | |
| refines-to | ingredient | ingredient | 1→1 | nugget→cube, fiber→yarn, log→wood cube |
| yields | flora ∪ deposit ∪ creature | ingredient | 1→n | count range |
| spawns-in | creature ∪ flora ∪ deposit | landscape ∪ terrain-feature ∪ dungeon-type ∪ poi-type | n→n | |
| placed-in | dungeon-type ∪ poi-type ∪ settlement | landscape | n→n | |
| tamed-by | creature | pet-food | 1→0..1 | stable ID pairing; one food may serve multiple explicitly approved species (Bubble Gum: Collie and Skeleton Dog); numeric identity follows c-food-id, not family inheritance |
| member-of-family | creature | creature-family | 1→0..1 | optional primary balancing family (`creature.family`); sole source of family stat modifiers |
| descriptive-member-of-family | creature | creature-family | 1→0..n | descriptive memberships only (`creature.descriptive-families`); never supply or stack stat modifiers |
| belongs-to-faction | creature ∪ npc-role | faction | n→n | |
| hosts | dungeon-type ∪ poi-type | mission-type | n→n | |
| rewards | mission-type ∪ arena ∪ poi-type | item-type ∪ key-item ∪ artifact ∪ currency ∪ book-of-crafting | n→n | |
| guards | creature (boss) | artifact ∪ key-item ∪ gnome-supplier ∪ magic-crystal | n→n | |
| drops | creature | item ∪ spirit-cube ∪ leftovers ∪ currency | n→n | random by tier + species list |
| holds | inventory | item | 1→n | count per entry; c-stack-rule |
| equips | entity | item | 1→0..12 | at most one per usable equipment-slot; reserved index 0 and separate Q selection excluded; c-slot-accepts |
| threat | entity (mob) | entity (player-character) | n→n | hybrid mob/player combat state, retained across temporary absence and surviving-mob restart (§3.2); optional per ordered pair, with one numeric `aggro-points` amount; c-threat-pair |
| current-target | entity (mob) | entity (player-character) | 1→0..1 | hybrid mob/player target selection, separate from threat amounts; multiple mobs may select the same player; c-current-target |
| requires-key-item | poi-type ∪ dungeon-type ∪ ability | key-item | n→n | divine door→harp, crypt gate→bell, bird statue→whistle; hybrid riding→reins (acquired, c-riding), hang-gliding→hang-glider and sailing→boat (equipped, c-gliding/c-sailing); global scope |
| located-in | settlement ∪ dungeon ∪ poi | land | n→1 | |
| owned-by-realm | land | realm | n→1 | S |
| reveals | realm (lore 100 %) | artifact | 1→n | S |
| bound-to-land | item ∪ key-item ∪ leftovers | land | n→1 | S region lock |
| works-in-adjacent | item(plus) | land | n→n | S |
| raises-stock | gnome-supplier | shop | 1→n | one rarity per rescue |
| sells | shop | item-type ∪ pet-food ∪ formula ∪ key-item | n→n | versioned |
| offers-service | building | npc-role | 1→n | |
| contains-station | building | crafting-station | 1→n | |
| in-district | building | district | n→1 | A |
| styled-by | settlement | landscape | n→1 | architecture theme |
| equips-in | item-type | equipment-slot | n→n | permitted slots, not simultaneous copies of an item; rings and weapons have multiple eligible positions, subject to c-slot-accepts |
| restricted-to-class | weapon-type ∪ material | character-class | n→0..1 | |
| has-hazard | landscape ∪ terrain-feature | status-effect | n→n | cold-water, toxic, lava |
| countered-by | status-effect | consumable | n→n | hot chocolate, green smoothie, lemonade |
| raises-stat | artifact ∪ ability ∪ spirit-cube ∪ elixir | stat | n→n | hybrid artifacts: exactly one traversal stat plus attack and max HP; per-stat counting and recalculation follow §3.4 artifact / c-artifact-stat |
| mounts | player-character | pet | 1→0..1 | hybrid training + global Reins + rideable tamed pet: c-riding; A skill-only / S land Reins are reference |
| owns | player-character | pet | 1→n | cages |
| possesses | poi-type(demon-portal) | npc-role ∪ creature | 1→n | S |
| petrifies | creature(witch boss) | settlement | 1→1 | S |
| scales-with | pet | stat(weapon-rating, armor-rating) | 1→2 | S |
| adjacent-to | land | land | n→n | derived from grid |
| enabled-by | ability ∪ item-type ∪ mechanic | ruleset | n→n | feature flags |

### Threat and current target (hybrid)

Owner-requested clarification (2026-09-18), documentation only. These relations describe the
approved mob/player scope. A **mob** is an individual non-player combat `entity`, not the shared
`creature` species definition; the player endpoint identifies an individual `player-character`.
For threat/order retention, these are logical mob/player identities, not only currently spawned
nodes. Temporary absence and surviving-mob restart preserve the approved remaining state under
§3.2; `current-target` still requires a present, living player entity. Restart retention promises
no restored target node, chooses no storage strategy and adds no combat pairings.

**Threat** is the directed mob → player relationship, not a separate global player stat.
Its numeric property **`aggro-points`** measures the relationship's strength, in **aggro points**
(also called threat points). Each mob can track zero or more players and each player can have
incoming threat relations from zero or more mobs, independently. **`current-target`** identifies
at most one player that a mob is currently targeting; changing it does not erase other threat
relations. Ordinary selection uses that mob's own scores and the rules in §3.2 `ai-behavior`.
Heroic Shout temporarily overrides `current-target`, not `threat`: it grants neither aggro
points nor engagement order, and taunt alone adds no neutral provocation or lasting eligibility.
When it ends, ordinary targeting resumes unless protected return applies (§3.2).

Illustrative runtime facts, not static instance data or balance defaults:
```text
mob-a --threat {aggro-points: 20}--> player-you
mob-a --threat {aggro-points: 30}--> player-teammate
mob-a --current-target-----------> player-teammate
mob-b --threat {aggro-points: 40}--> player-you
mob-b --current-target-----------> player-you
```

Pack membership is the generated grouping of mob individuals (§3.2), not `member-of-family`
or `belongs-to-faction`. Shared current sightings do not copy `threat`, engagement order or
`current-target`; each mob selects independently under §3.2. Open questions are in §7.

---

