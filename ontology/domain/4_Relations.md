## 4. Relations

One row per fact type. Cardinality as `domain → range`.

| id | domain | range | card. | meaning |
|---|---|---|---|---|
| [has-specialization](../schema/identity-character-class.yaml) | | | |  |
| [uses-weapon](../schema/identity-character-class.yaml) | | | | Three weapon families; this does not impose a three-subtype-ID list limit. |
| [wears-material](../schema/identity-character-class.yaml) | | | | Class material alternatives remain iron/linen/silk/cotton. |
| [grants-ability](../schema/relations-abilities-crafting.yaml) | | | | versioned |
| [unlocks-next](../schema/combat-ability.yaml) | | | | alpha tree: 5 points |
| [invoked-by-control](../schema/relations-abilities-crafting.yaml) | | | | active ability activation refers to [controls](controls.md), directly or through the current class slot/tree; passive effects need no binding |
| [bound-to-input](../schema/relations-abilities-crafting.yaml) | | | | each binding belongs to a controller profile; aliases/shared phases and context are profile-owned, not versioned ability identity |
| [has-input-binding](../schema/relations-abilities-crafting.yaml) | | | | [profiles](controller-profiles.md) own physical mappings and distinguish unselected defaults |
| [costs](../schema/relations-abilities-crafting.yaml) | | | | amount per resource, scoped by ruleset |
| [applies](../schema/combat-ability.yaml) | | | |  |
| [has-moveset](../schema/relations-abilities-crafting.yaml) | | | | Basic and special attack channels, not physical bindings. |
| [knows-recipe](../schema/entities.yaml) | | | | One known fact per character/recipe, shared by books and formulas (`known-recipes`), even while power-locked; knowledge alone does not grant crafting usability. Recipes persist across lands/sessions/worlds (§3.7), not shared-account knowledge. |
| [crafted-at](../schema/relations.yaml) | | | | Recipes use one crafting station; station availability and usability remain source-qualified. |
| [consumes](../schema/relations.yaml) | | | | `recipe-consumption` associates each ingredient/material input with its count; raw symbolic recipe configuration remains distinct. |
| [produces](../schema/relations.yaml) | | | | One output item-type or consumable per recipe; the raw symbolic configuration does not invent generated output defaults. |
| [refines-to](../schema/relations.yaml) | | | | Nugget→cube, fiber→yarn, log→wood cube; compact source processes remain exact text, not parsed recipes. |
| [yields](../schema/relations.yaml) | | | | `ingredient-yield` associates the logical ingredient and count range; source catalog values may remain qualified. |
| [spawns-in](../schema/relations.yaml) | | | | Applicability and source roster qualification remain in the owning domain entries. |
| [placed-in](../schema/relations.yaml) | | | | Placement meaning remains distinct from source descriptive text. |
| [tamed-by](../schema/identity-creature-ecology.yaml) | | | | stable ID pairing; one food may serve multiple explicitly approved species (Bubble Gum: Collie and Skeleton Dog); numeric identity follows c-food-id, not family inheritance |
| [member-of-family](../schema/identity-creature-ecology.yaml) | | | | optional primary balancing family (`creature.family`); sole source of family stat modifiers |
| [descriptive-member-of-family](../schema/identity-creature-ecology.yaml) | | | | descriptive memberships only (`creature.descriptive-families`); never supply or stack stat modifiers |
| [belongs-to-faction](../schema/relations-placement.yaml) | | | |  |
| [hosts](../schema/relations.yaml) | | | | Mission hosting applicability remains source/ruleset-qualified. |
| [rewards](../schema/relations.yaml) | | | | Hybrid shared packages and personal source claims retain their separate rules. |
| [guards](../schema/relations.yaml) | | | | Source qualification is `creature (boss)`; the schema endpoint remains generic `creature`. Encounter-specific eligibility remains in the linked encounter contract. |
| [drops](../schema/relations.yaml) | | | | Random by tier + species list; initial hybrid [boss guarantees](encounter-contracts.md#guaranteed-boss-gear-and-spirits) are additional shared drops, not personal copies. |
| [holds](../schema/relations.yaml) | | | | `inventory-entry` associates item and count; c-stack-rule remains a behavioral eligibility condition. |
| [equips](../schema/relations.yaml) | | | | At most one item per usable equipment-slot; reserved index 0 and separate quick-consumable selection excluded; c-slot-accepts remains applicable. |
| [threat](../schema/relations-combat-equipment.yaml) | | | | hybrid mob/player combat state, retained across temporary absence and surviving-mob restart (§3.2); optional per ordered pair, with one numeric `aggro-points` amount; c-threat-pair |
| [current-target](../schema/relations-combat-equipment.yaml) | | | | hybrid mob/player target selection, separate from threat amounts; multiple mobs may select the same player; c-current-target |
| [requires-key-item](../schema/relations.yaml) | | | | Divine door→harp, crypt gate→bell, bird statue→whistle; hybrid riding→reins (acquired, c-riding), hang-gliding→hang-glider and sailing→boat (equipped, c-gliding/c-sailing); global scope. |
| [located-in](../schema/relations.yaml) | | | | A typed logical location does not assert reference existence. |
| [owned-by-realm](../schema/relations.yaml) | | | | S-qualified; applicability follows realm lore scope. |
| [reveals](../schema/relations.yaml) | | | | S-qualified; lore thresholds remain a rule, not a native relation predicate. |
| [bound-to-land](../schema/relations.yaml) | | | | S region lock; applicability remains source-qualified. |
| [works-in-adjacent](../schema/relations.yaml) | | | | S-qualified plus-item adjacency. |
| [raises-stock](../schema/relations.yaml) | | | | Hybrid [land-shared ceiling](encounter-contracts.md#shared-mission-packages-and-supplier-shops), applied at ordinary stock generation/restock, not a rescue-triggered reroll. |
| [sells](../schema/relations.yaml) | | | | Versioned; source-specific stock remains qualified. |
| [offers-service](../schema/relations.yaml) | | | | |
| [contains-station](../schema/relations.yaml) | | | | |
| [in-district](../schema/relations.yaml) | | | | A-qualified district membership. |
| [styled-by](../schema/relations.yaml) | | | | Architecture theme; selected hybrid style configuration remains separate. |
| [equips-in](../schema/relations-combat-equipment.yaml) | | | | permitted slots, not simultaneous copies of an item; rings and weapons have multiple eligible positions, subject to c-slot-accepts |
| [restricted-to-class](../schema/relations-combat-equipment.yaml) | | | |  |
| [has-hazard](../schema/relations.yaml) | | | | Cold-water, toxic and lava examples remain distinct from structural endpoint typing. |
| [countered-by](../schema/relations-combat-equipment.yaml) | | | | hot chocolate, green smoothie, lemonade |
| [raises-stat](../schema/relations-combat-equipment.yaml) | | | | hybrid artifacts: exactly one traversal stat plus attack and max HP; per-stat counting and recalculation follow §3.4 artifact / c-artifact-stat |
| [mounts](../schema/relations-economy-ownership.yaml) | | | | hybrid training + global Reins + rideable tamed pet: c-riding; A skill-only / S land Reins are reference |
| [owns](../schema/relations-economy-ownership.yaml) | | | | cages |
| [possesses](../schema/relations.yaml) | | | | S-qualified. |
| [petrifies](../schema/relations.yaml) | | | | S-qualified witch-boss relationship. |
| [scales-with](../schema/relations-economy-ownership.yaml) | | | | S |
| [adjacent-to](../schema/relations.yaml) | | | | Derived from the land grid; no separately selected adjacency storage. |
| [enabled-by](../schema/relations-economy-ownership.yaml) | | | | feature flags |

### Threat and current target (hybrid)

Owner-requested clarification (2026-09-18), documentation only. These relations describe the
approved mob/player scope. A **mob** is an individual non-player combat `entity`, not the shared
`creature` species definition; the player endpoint identifies an individual `player-character`.
For threat/order retention, these are logical mob/player identities, not only currently spawned
nodes. Temporary absence and surviving-mob restart preserve the approved remaining state under
§3.2; `current-target` still requires a present, living player entity. Restart retention promises
no restored target node, chooses no storage strategy and adds no combat pairings.

**Threat** is the directed mob → player relationship, not a separate global player stat.
Its association is [`threat-pair`](../schema/relation-types-nominal.yaml), with
[`threat-mob`, `threat-player` and `aggro-points`](../schema/relations-combat-equipment.yaml).
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

