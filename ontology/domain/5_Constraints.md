## 5. Constraints

### Validation contract (item 9, owner approved 2026-09-17)

This is the required validation behavior, **not a claim that the current checker implements it**.
Approval covers ontology documentation only; loader, validator, generator and gameplay changes
remain separately authorized work (`docs/ROADMAP/todo_implement.md`).

- **Required data:** tables and config blocks needed by active, approved hybrid systems must
  be present and have the documented root/row shapes. Missing data must fail validation, not
  silently skip its checks; this includes the race catalog and the whole `design.movesets`
  block. Derive required paths from the approved domain and dependencies, not from whichever
  files happen to load. Reference/roadmap coverage does not by itself enable a hybrid system
  or require its runtime implementation.
- **Existing rules:** validate class/spec references in both directions, two specs per class
  with distinct indices 0/1 and index 0 first, shared skill-column roots and weapon upgrade
  capacities according to their approved definitions. Preserve the approved Assassin single-node
  exception (§3.5) and the approved two-handed wand (§3.3); do not settle open choices through
  a validator default.
- **Provenance:** versioned content must resolve at least one source-version tag, explicitly
  or through an inheritance rule documented for that family and its source. Missing tags
  are not permission to assume A/S, infer provenance from a numeric ID, or enable content.
  Item 9 alone established no per-family inheritance rules; item 4 below records the bounded
  mappings now approved. Unscoped histories remain research. Metadata/config containers are
  not automatically content instances.
  Taxonomy/style config, pet-food evidence and qualified reference annotations follow the
  Validation-contract mapping below.
- **Definitions versus generated instances:** load-time checks validate available definitions
  and generator configuration, not nonexistent generated objects. For artifacts, check the
  definition's seven approved traversal stat kinds and approved bonus configuration at load time;
  generator/runtime checks separately verify each generated artifact has exactly one of
  those traversal bonuses plus attack and max HP. The approved accumulation curve, counts and
  recalculation are in §3.4 `artifact`; direct data correction and enforcement remain deferred.
  Passing definition checks is not evidence that generated rewards or runtime behavior work.
- **Result:** validation succeeds only when the accumulated load/validation error collection
  is empty. Earlier load errors remain failures even if a validation pass adds no new errors.
  Malformed data must produce an error rather than be silently discarded or treated as valid.

The required paths, permitted source inheritance and check boundaries are mapped below.
Resolve remaining source attribution from evidence before its affected checks; ask the owner
only where approved rules leave a genuine choice, never fill gaps by guessing.
Negative regressions must cover missing whole inputs as well as invalid entries. No balance,
content selection or live data changes are authorized by this contract.

### Validation-contract mapping (owner approved, 2026-09-28)

**Item 1 — Hybrid taxonomy/configuration:** the 12 top-level families in
`creature-families.json` (`beetles`, `runners`, `slimes`, `alpacas`, `dogs`, `cats`, `golems`,
`trolls`, `skeletons`, `sprouts`, `guardians`, `fish`) and `buildings.json#settlement-styles`
are source-independent hybrid taxonomy/style configuration. Validate their stable IDs, shapes
and references; do not manufacture A/S ancestry or derive it from member-version unions.
This is not a whole-file exemption: separately sourced historical facts, including embedded
trait descriptions, retain their provenance; nested spawn rosters and versioned buildings/districts
are outside this classification. Existing family assignments, creature behavior, encounters and
settlement styles stand; no species-trait inheritance or numerical family modifier is introduced.

**Item 2 — Individual pet-food provenance:** evidence and unresolved claims follow §3.4
`pet-food`, independently of approved taming pairings and numeric source identity.

**Item 3 — Qualified source annotations:** retain `S?` and `A?` as uncertainty-qualified
source annotations for reference records, not confirmed S/A history. These annotations do not
independently establish hybrid availability; explicit hybrid decisions still govern it (§1).
An uncertain Swamp Lands reference remains useful for research without deciding its identity or
adding a distinct shipping biome. Do not delete or reject a reference merely for its qualified
tag, or silently promote it to confirmed history. This chooses no runtime schema/type or parser
behavior: the current parser strips `?`; preserving the qualification in model/loader/validator
handling remains deferred and unauthorized.

#### Item 4 — Required inputs, source scopes and check boundaries

Owner approved 2026-09-28, with the undeployed-game clarification in §0. This maps existing
rules, not new content, balance or a serialization schema. Required means dependencies of the
**approved hybrid**, including unimplemented systems, not merely today's consumers. Within a
mixed file, historical A/S alternatives, X/cut and Omega-only rows remain reference; requiring
its active definitions does not activate every row or require generating objects at load time.

**Required paths and shapes.** Paths below are relative to `ontology/instances/`; each file
root is an object. Braces enumerate exact sibling paths, not arbitrary keys. A catalog is an
ID→row-object map unless noted. Metadata (`$schema`, `_doc`, source notes, examples and negative
research) is not a content row; neither silently discard malformed catalog rows nor flatten
legitimate arrays/scalars/config into invented instances. The §3 definitions and constraint
catalog govern row fields and numeric/reference rules; the inventory locates their inputs.

| dependency | required definition/config paths and heterogeneous shapes |
|---|---|
| Identity and skills (§3.2/§3.5) | `races.json`, `classes.json`, `specializations.json`, `abilities.json` catalogs; `abilities.json#<id>.alpha-tree` is a per-ability object, not a root table. |
| Combat and item types (§3.3/§3.4) | `weapon-types.json`, `materials.json`, `item-types.json`, `rarities.json`, `status-effects.json` catalogs. Rarity comparison maps `mob-strength-tiers-s` / `alpha-relative-colors` are separate reference config; `status-effects.json#ability-buffs` is a definition-reference object and `#not-found` a negative-research array, not effects to instantiate. |
| Stats and slots (§3.3–5) | `stats.json#{resources,stats}` catalogs and `#{alpha-item-stat-formulas,alpha-character-formulas}` mixed formula objects (strings, numbers, tables); `equipment-slots.json#slots` an array of rows with `id`/index, `#extra` an object of separate quick-use/taming descriptions, `#rules` a string array. Current slot acceptance text must conform to §3.4, not redefine it. |
| Creatures and pets (§3.2/§3.4) | `creatures.json` catalog; the 12 `creature-families.json` config objects listed in item 1; `#landscape-rosters` maps to creature-ID arrays; `#forest-dungeon-rosters` maps to objects with `members` arrays and `boss` strings, including race/family tokens, not uniformly creature IDs. `pet-food.json#foods` catalog; `#rules` / `#shop-set` arrays; `#cut` a separate reference catalog. |
| World and encounters (§3.1/§3.6) | `landscapes.json`, `terrain-features.json`, `flora.json`, `deposits.json`, `dungeon-types.json`, `poi-types.json`, `factions.json` catalogs (realm-name examples are not factions); `landscapes.json#<id>.gen` objects for generated hybrid landscapes. `mission-types.json#{alpha,steam}` nested catalogs, with `_shared` config and `steam.region-completion-order` guide array distinct from mission rows. |
| Blocks and structures (§3.1) | `block-types.json#alpha` numeric-key→row objects plus `flags`, `#steam` numeric-key→strings plus `note`, `#{scale,cub-format}` config objects; `static-entities.json#by-id` numeric-key→name strings, `#behaviour` a mixed description map, `#s-additions` string array, `#candles` config object. Numeric table presence is not content availability. |
| Crafting and traversal (§3.4/§3.5) | `consumables.json`, `ingredients.json`, `crafting-stations.json`, `key-items.json` catalogs with separate summary/config objects (`consumables#rules`, `key-items#counts-per-land-s` and cut `#special-accessories-x`). `recipes.json#{gear-armor-quantities,gear-weapons,refining,recipe-sources,customization}` mixed rule/recipe objects; `#{cooking,alchemy}` objects referring to consumables; `#crafting-tabs-a` string array. `key-items.json#artifact.stat-kinds` is the seven-kind definition array, not generated rewards. |
| Settlements and economy (§3.1/§3.4) | `buildings.json#{districts,buildings}` catalogs, `#{settlement-styles,population,map-visibility}` config objects; `npc-roles.json` catalog (dialogue corpus separate); `economy.json#{currency,incomes,prices,shops,rules,loot}` mixed source/config objects. Approved hybrid services, prices and resets govern, not historical alternatives. |
| Names (gen-name) | `affixes.json#{common,uncommon,rare,epic,legendary,name-forms}` string arrays; examples are reference and `#plus-suffix` is an excluded S mechanic, not hybrid naming. |
| Rules, controls and presentation (§3.7) | `rulesets.json#ruleset-hybrid` object with `flags` object and default boolean; other rulesets reference only. `keybinds.json#hybrid` binding object; `ui.json#{hud,screens,options,camera}` grouped objects; `audio.json#sfx-alpha-ids` string array (includes descriptive entries, not all asset IDs). `slash-commands.json` command-key→row catalog with separate `cuwo-server-commands` array / `chat-rules` object; only approved commands, never `/pvp`. Historical audio backend/track records are not runtime asset requirements. |

`versions.json#{timeline,alpha-to-steam-delta,reception}` (array/object/object) is history
coverage, not an active gameplay dependency merely because the directory loader visits it.
Reference data still needs structural validity and qualified attribution; no whole-file exemption
or uniform row-shape assumption follows from the active/reference distinction.

`generators.json#design` is required as an object. Its required children are grouped below;
existing config constraints specify dependent fields. Current obsolete values do **not** satisfy
later approvals. In particular, require the approved artifact logarithm directly, not decay/floor
as an accepted alternate format. This chooses no new JSON keys for that rule.

| dependency | exact `design` children and nested shapes |
|---|---|
| World/spawns | `{enemy-level,enemy-hp,terrain,climate,names,spawns}` objects; `terrain.{height,heightfield}` and `spawns.ai` objects, `climate.rules` array of `[landscape-id, expression-string]`, `names.syllables` string array / `names.land-suffix` map of string arrays. |
| Skills/combat | `{skill-point,abilities,resources,special-attack,status-effects,progression,crit,movement,camera,combat,defence,movesets}` objects; `abilities.runtimes` / `movesets.kinds` arrays, ability/moveset entries objects (including documented aliases); `resources.mp`, `movement.stamina`, `defence.{dodge,block,stealth,enemy-hit}` objects. Whole `movesets`, `default` and required class-weapon entries cannot be skipped when absent. |
| Roles/feedback/engine | `{creature-roles,feel,frame-budget}` objects; `creature-roles.{any-class,melee,ranged,mage,species}` objects and `default` string; `feel.{hit-stop,shake,numbers,impact,trail,level-up,events,sfx}` objects with event/sound references and colour arrays per the catalog. |
| Inventory/settlements | `{prices,stack-cap,loot,starting-inventory,settlement}` objects; `stack-cap.stackable` / `loot.consumable-pool` arrays; `loot.{coins,rarity-weights,gear-kinds,ground}` objects; `settlement.buildings` array, `settlement.npc.roles` / `settlement.style-by-landscape` maps, `settlement.style-colors` map of two-colour arrays, `settlement.{shop,inn,trainer}` objects. |
| Other approved systems | `{artifact,artifacts-per-land,circle-of-power,recipes,pvp}` objects, regardless of incomplete consumers. `{item-stat-curve,block-reward,regeneration}` are **strings**, not object blocks. |

Other `generators.json` inputs for §6 are mixed historical/approved-system objects:
`{world-scales,seed,time,climate,land,terrain,settlement,dungeon,spawns,boss,names,item,realm,npc-appearance,schedule,key-items-s}`;
`loot` and `level-formulas-alpha` are string references. Check approved dependencies within these
containers, not every source-specific alternative as hybrid config. `coarse-map-omega` and
`network-alpha` are reference-only objects; no borders, sleep-fast-forward and client authority
in older source descriptions cannot override the approved bounds, inn skip and server authority.
There is no current save-schema file or generated-object catalog to invent as a required input.

**Permitted source inheritance.** This is a finite mapping of explicit source envelopes, not
an A+S default. Apply only to the stated table facts or subfacts without their own annotation;
retain explicit row-level X, `A?`/`S?`, uncertainty and narrower exceptions. Source-table origin
proves neither shipped source functionality nor hybrid availability. Item 1's taxonomy/style
configuration and owner-authored `design` / hybrid bindings need no invented historical ancestry.

| source envelope | inherited historical scope and evidence boundary |
|---|---|
| `block-types.json#{alpha,steam}` | A / S table facts respectively (`research/research_world.md §2.3`); flags/notes remain metadata, not block instances. |
| `item-types.json` alpha type/subtype table | A table origin from `_doc` (cuwo ItemData), corroborated by `research/research_systems.md §9.2`; retain explicit X rows and nested cut qualifiers. `_s-additions` supplies S subfacts only. Type 20 does not date individual foods. |
| `static-entities.json#by-id` / `#s-additions` | A STATIC_NAMES / S additions (`_doc`, `research/research_systems.md §9.1`). Do not extend to mixed `behaviour` or unscoped `candles`; explicit fire/stomp X and alpha artifact ID 46 never establish working alpha artifact gameplay. |
| `mission-types.json#{alpha,steam}` | A / S catalog scopes (`research/research_creatures_quests.md §7.1–2`); `alpha.quests-cut` stays X. `_shared` and completion-order are source rules/guide metadata, not missions. |
| `rarities.json#{mob-strength-tiers-s,alpha-relative-colors}` | S / A comparison facts only; do not propagate through rarity references. |
| `stats.json#{alpha-item-stat-formulas,alpha-character-formulas}` | A formula sources explicitly identify coremaze 0.1.1 reverse engineering / cuwo; this does not resolve uncertain formula correctness. |
| `audio.json#sfx-alpha-ids` | A identifier-list origin (`research/research_systems.md §8`), not asset availability or dates for tracks. |
| `equipment-slots.json#slots` and `#extra.consumable` | A storage-table / separate consumable-field origin (`research/research_systems.md §5.1/§9.2`); preserve partly inferred indices and row/subfact annotations. Approved hybrid slot rules remain independent. No A+S blanket on equip rules. |
| `keybinds.json` action-row `A` / `S` cells | That cell's source only (`research/research_systems.md §5.3`); em dash records absence, not a binding. Mixed `map-controls` and `hybrid` receive no inherited A+S tags. |
| Explicit source subfacts in mixed containers | `economy.json#{currency,incomes,prices}.{A,S}`, `#shops.weapon-shop.stock.{A,S}`, `#shops.item-shop.sells.{A,S}`, `#rules.buy-back.{A,S}`, `#loot.{A-boss,A-dungeon,S-mission,S-dungeon}`; `recipes.json#crafting-tabs-a`, `#recipe-sources.{A,S}`, `#customization.{spirit-cubes-a,fully-modded-legendary-plus-s}`; `buildings.json#map-visibility.{A,S}`, `audio.json#ambient.{S,Ω}`, `key-items.json#counts-per-land-s`: only the explicitly named source subfact, never the whole mixed parent. Excluded regional mechanics remain reference. |
| Explicit generator source sections | `generators.json#world-scales.{alpha,steam}`, `#seed.{alpha-default,alpha-source,steam}`, `#land.{alpha-level,alpha-rarity,steam-tiers,steam-per-land,alpha-per-land}`, `#settlement.{alpha-count,steam-count,districts-alpha,inn.A,inn.S}`, `#dungeon.{alpha-layout,steam-layout,traps-alpha,traps-data-x,boss.A,boss.S,artifact-s,size-cap-s}`, `#boss.{alpha-size-scaling,alpha-spirit-drop,steam-loot,coins-s}`, `#npc-appearance.omega`, `#{coarse-map-omega,key-items-s,level-formulas-alpha,network-alpha}`: A/S/X/Ω only as explicitly identified there; preserve local hybrid overrides, never tag all generators A+S. |

Untagged histories outside these scopes remain **source research/attribution**, not guessed
labels or new gameplay ballots: individual foods; roster and embedded family traits; affix
prefixes; mixed recipe/shop/population/UI facts; unscoped audio, static behavior/candles and
dialogue/example claims. The mixed food table in `research/research_items.md §5` supplies
pairings, not per-food A+S history; preserve existing sourced S/X food facts and F11 Banana Mash.
Neither referenced species nor numeric IDs lend tags. `status-effects.json#ability-buffs` points
to existing definitions; `#not-found` creates none. `versions.json` keeps its history schema
(dates and scalar release identifiers, not content-tag arrays); cuwo command lists keep their
modded-server context, not stock-command or hybrid approval. No new labels or parser schema
are selected for these remaining cases. Subsequent bounded findings and unresolved scope are
recorded in item 6 (§3.4 `pet-food`) and item 7 below, not whole-container attribution.

**Check boundaries.** Load checks concern the above definitions/config, including required
presence before iteration, valid references/shapes and cumulative errors under item 9. Numeric
predicates remain in the constraint catalog; no duplicate balance table is introduced here.

| rules | definition/config load | generated objects, runtime and save/import checks |
|---|---|---|
| Class/spec/tree | Both reference directions, two specs with distinct indices 0/1 and index 0 first, shared roots/links, Assassin exception and ability config coverage. | Starting spec; spend/prerequisite/bank/respec, costs/cooldowns and actual effects. |
| Items/stats/recipes | Types, materials, slots, wand hands/recipe, capacities, formula/ingredient/station references and approved configuration. | Generated rarity/roll/stats/names; actual upgrades and equip class/slot/hand/power limits, stacks, transactions and recipe knowledge/duplicates/locks. Generated-rarity checks do not remove mythical/worn reference definitions. |
| Families/pets | Primary/descriptive references, roster IDs, food pairings/source identity and rideability. | Primary-only scaling, per-dog 1% generation/Collie fallback, normal dog behavior, taming/one-active-pet and training/item/equip traversal gates. Provenance is not inferred from these relations. |
| Artifacts (`c-artifact-stat`, §3.4) | Seven-kind `key-items.json#artifact.stat-kinds` definition and `generators.json#design.artifact` conforming to the approved normalized logarithm (5% first, positive adjustable z, initial z=0.1, no decay/1% floor). Old decay/floor cannot pass as an alternate. | Generation: exactly one approved traversal kind plus attack and max HP. Runtime: matching contributors per traversal stat, all artifacts for attack/HP, equal additive shares of the logarithmic total, recalculated from current artifact-free stats. No levels or gate bypass; personal source claims follow §3.7. |
| World/settlement/mission (§6) | Bounds/scales, climate rule shapes and parseability, rosters/styles/buildings/roles, sites/rewards and generator config. | Seeded geography, finite bounds, exact-one settlement, placement/count/lock/wave/boss-fit/loot invariants; map/travel boundary, protected settlements, clock/inn/reset/occupied-site rules and nonrenewing permanent claims. No generated-world census at load time. |
| AI/combat | Ability/status/moveset/projectile/role references and numeric config, including simulation-radius relationship. | Threat pairs/order/target eligibility, pack response, home return, actual hit/damage/status/dodge/block/combo behavior and live panel time. Valid config alone proves none of these effects. |
| Persistence/authority (§3.7) | Available rule/config definitions only; no invented save format or transport. | Server-validated actions/outcomes; portable versus character/world versus shared-world ownership; source claims, no downtime catch-up and surviving-mob retention. Validate imports against current rules; reject invalid imports with explanation and original save untouched, not conversion or a claim of earned-progression proof. |
| UI/engine/assets | Binding/UI/sound/format declarations and frame-budget config. | Player-name input limits, actual RGB payloads, map/input/HUD/feedback and physics/catch-up behavior; nonexistent generated payloads are not malformed definitions. |

Future regressions must exercise each predicate at its mapped boundary, including item 9's
missing-whole-input cases. A passing current validator does not prove this mapping's enforcement;
direct data correction and loader/validator/generator/runtime work remain unauthorized.

### Constraint catalog

| id | rule | layer |
|---|---|---|
| c-race-class | any race × any class × either gender is valid | type |
| c-spec-of-class | specialization.class == character.class; player starts as spec index 0 | load |
| c-one-active-pet | at most one pet summoned; one of each pet-food carried | runtime |
| c-riding | hybrid: mounting requires 5 Pet Master points, ≥1 Riding point, globally acquired Reins and a rideable tamed pet; further Riding points improve speed; no new species riding permission, Reins route or slot (§3.2 pet) | runtime (deferred) |
| c-gliding | hybrid: gliding requires 5 Climbing points, ≥1 Hang Gliding point and a Hang Glider bought from an item vendor and equipped in the single special slot; buying alone is insufficient; further Hang Gliding points improve speed (§3.5) | runtime (deferred) |
| c-sailing | hybrid: sailing requires 5 Swimming points, ≥1 Sailing point and a Boat bought from an item vendor and equipped in the single special slot; buying alone is insufficient; further Sailing points improve speed; boat and glider cannot be equipped together (§3.5) | runtime (deferred) |
| c-creature-family | primary and descriptive references name defined creature families; at most one primary per creature, consistent with §3.2 approved assignments; without a primary, the family modifier is ×1.0 and other ordinary stat calculations remain; descriptive memberships never supply or stack family stat modifiers, nor imply species-trait inheritance | load+runtime (deferred) |
| c-skeleton-dog-encounter | Skeleton Dog has an independent 1% chance per individual dog spawn, not per pack, all creatures or a relative species weight; mixed packs are permitted and no quota is guaranteed; applies wherever dogs already spawn, preserving settlement safety; existing skeleton-only dog encounters use Collie for ordinary outcomes, preserving dog frequency/pack sizes and other existing ordinary selections, not extra unrestricted skeletal spawns (§3.2) | generator (deferred) |
| c-skeleton-dog-taming | Skeleton Dogs follow normal dog behavior for the same encounter/state, including retaliation, pack response and taming reactions, with no skeleton-only passivity exception (§3.2 item 8); Bubble Gum tames them under general eligibility restrictions and settlement protection (§3.2 item 9) | runtime+data (deferred) |
| c-food-id | pet-food.tames names defined creatures by stable ID and agrees with each creature's tame-food; normally the food subtype matches its species' known source entity ID (alpha or post-alpha, no alpha-range clamp); the sole approved shared-food exception is Bubble Gum → Collie and Skeleton Dog, retaining subtype 19 from Collie without assigning it to Skeleton Dog; other pairings/IDs are unchanged (§3.4) | load (shared-food support deferred) |
| c-weapon-class | equipping weapon-type/armor material requires matching class (red name otherwise) | runtime |
| c-hands | 1H ×2 or 1H + shield or one 2H; bracelets need two for full damage; hybrid wand is mechanically 2H with no other hand item, regardless of pose (§3.3 weapon-type; wand enforcement deferred) | runtime |
| c-cube-cap | upgrades ≤ 16 (1H) / 32 (2H, shield); wood cubes only on wood weapons, iron on metal | load+runtime |
| c-spirit-level | A: weapon.level − 10 ≤ spirit.level ≤ weapon.level | runtime |
| c-power-gate | A / hybrid: item.level ≤ power(player.level) for full strength; formula learning retains its sufficient-power requirement. Hybrid books record recipes immediately, but above-power recipes remain known and visibly locked against crafting until their requirement is reached; duplicate acquisition never removes the lock (§3.5 power-gate) | runtime (recipe enforcement deferred) |
| c-book-recipe-persistence | hybrid: book-learned recipes remain known to that character across lands and sessions, with no relearning on travel, including between worlds under persistence item 1 (§3.7 save-data) | runtime+save-data (deferred) |
| c-permanent-source-claim | hybrid: at most one claim per character/saved-world/artifact-or-one-time-book-source; claims remain available to other characters at the source and are not renewed by leaving, restarting, returning or daily enemy resets (§3.7 save-data, item 5; §3.1 world/reset item 3); ordinary ground loot unchanged | runtime+save-data (deferred) |
| c-recipe-learning | hybrid: books/formulas share one known-recipe set per character, including known-but-power-locked recipes; repeated learning grants nothing extra; books teach only unknown recipes without rerolls/compensation; an already-known formula remains unconsumed, without bypassing c-power-gate (§3.4 recipe) | runtime (deferred) |
| c-region-lock | DROPPED (D4). S reference: item.land ≠ current land ∧ ¬plus → worn; key items inert | — |
| c-plus-adjacent | DROPPED (D4). S reference: plus item full stats iff current land adjacent | — |
| c-gear-global | hybrid: an item's stats are identical in every land; key items and artifacts work everywhere once found | runtime |
| c-climbing | hybrid: basic climbing needs neither points nor Spikes; Climbing points reduce stamina drain and global Climbing Spikes reduce consumption by 75%, not eliminate it; 5 Climbing points remain a Hang Gliding prerequisite; item 5 applies Spikes after skill reduction (remaining cost ×0.25), never additive percentage points; no skill curve/floor or artifact-combination rule inferred (§3.4/§3.5) | runtime (deferred) |
| c-rarity-range | rarity ∈ 0..4 for generated items (5 = mythical bug, off by default) | load |
| c-stat-roll | roll = ((attributes<<16)+modifier) mod 21 ∈ 0..20 | generator |
| c-loot-config | `design.loot`: every chance ∈ [0,1]; rarity-weights keys are rarities ≤ legendary with a positive sum; level-spread ≥ 0; gear-kinds and stack-cap.stackable name item-types; consumable-pool names consumables | load |
| c-stack-rule | only `design.stack-cap.stackable` item-types stack (no cap, D6); gear (has a modifier roll) is one item per entry | runtime |
| c-slot-accepts | an item equips only in a usable equipment-slot whose `accepts` lists its item-type and whose subtype restrictions it satisfies (§3.4 equipment-slot); weapon-type `offhand` hands → off-hand only; c-weapon-class and c-hands still apply | runtime |
| c-mp-range | mp ∈ [0, 100]; mage regenerates passively, others gain by hits/blocks/stealth/dodges; numbers `design.resources.mp` (D21) | runtime |
| c-stun-immunity | cannot re-stun while stars shown | runtime |
| c-threat-pair | at most one `threat` relation per ordered logical mob/player entity pair; each present relation has exactly one non-negative numeric `aggro-points` amount in aggro points, independent of other pairs; changing `current-target` does not clear it; decay/gains (including the full-stealth damage exception), the zero floor, player-death and arrival clearing, and escape/temporary-absence retention follow §3.2; actual mob death/respawn starts fresh, but midnight itself grants no survivor wipe (§3.1 world/reset item 4); decay reflects elapsed gameplay time even outside simulation radius; surviving-mob restart retains threat/order/neutral provocation under persistence item 9 (§3.2), with no downtime decay (§3.1) | runtime+save-data (deferred) |
| c-current-target | at most one present, living player target per mob; ordinary targeting compares that mob's eligible players by highest `aggro-points`, retains a tied current target, otherwise breaks positive-threat ties by earliest engagement; without a positive-threat priority or valid current target, choose the nearest normally detected zero-threat player without granting aggro/order (§3.2); player-death, zero-threat and arrival order resets, escape retention and fresh assignment follow §3.2; at zero, ordinary pursuit requires normal detection and hostility/provocation eligibility; equally nearest fallback ties are chosen randomly once with equal chances, then normal retention applies; Heroic Shout temporarily overrides ordinary targeting without threat/order gain; eligibility, duration, replacement, per-enemy simultaneous arbitration and termination follow §3.2; taunt expiry reflects elapsed gameplay time even outside simulation radius; taunt alone adds no neutral provocation or lasting ordinary caster eligibility (§3.2) | runtime |
| c-pack-response | only the generated pack responds, under the hostile-detection / aggressor-specific neutral-provocation rules in §3.2; friendly/passive creatures are excluded and protected return cannot be interrupted; share current sightings only, never threat/order, and select targets independently; each neutral clears its own provocation on arrival (§3.2) | runtime |
| c-return-home | pursuit beyond the home leash starts return regardless of threat; within it, target loss checks eligible positive-threat players then normal detection of eligible players (§3.2); attacks do not restart pursuit during return; ×2 normal return speed and 90% damage reduction (including DOT) until reaching home alive, then full HP and clear this mob's aggro/order toward every player and its neutral provocation once, ending both bonuses; no revival, cleansing or CC immunity; gains/decay continue until arrival and other mobs' records are unchanged; starting return cancels taunt, and new taunts neither interrupt nor queue for afterward | runtime |
| c-combo-reset | any attack with a hitbox that misses resets combo to 0, subject to the hybrid whole-channel and combo-neutral zero-damage-taunt rules in §3.3 combo-system; cap per weapon-type | runtime |
| c-dodge-cost | dodge costs 25 stamina; requires movement; standing still M3 = class skill (S); hybrid numbers `design.defence.dodge` (D23) | runtime |
| c-no-death-penalty | death never removes gold/items/xp; respawn at statue (A) / activated shrine (S) | runtime |
| c-time-speed | clock 10× real while the world runs; hybrid shutdown adds no gameplay time or reset catch-up (persistence item 8, §3.1); reference sleep 100× clock-only (baseline/units unresolved, source item 10 above); hybrid inn sleep skips to the next 07:00 without fast-forwarding combat/status effects/cooldowns (§3.1) | runtime (clock/save enforcement deferred) |
| c-midnight-reset | at 0:00 respawn eligible mobs, regen daily missions, deposits, plants; restock shops; hybrid defeated ordinary-dungeon/repeatable-daily enemies including bosses return, completed one-time-objective guards/boss stay cleared, and artifact/book claims never renew; preserve world improvements' existing reset rules; occupied dungeon/quest sites wait until all players leave, coalescing missed midnights into one pending refresh; the clock itself never heals/replaces living enemies or erases a fight, preserving ordinary threat/home-return rules (§3.1 world/reset items 3–4); sleep applies ordinary midnight resets once only if crossing midnight, never extra shop refreshes/mission rerolls merely for sleeping (§3.1) | runtime+save-data (deferred) |
| c-inn-hours | hybrid: separate 10-copper sleep service only 18:00–06:00 → next 07:00; all connected players explicitly agree, initiator pays the single fee only on success; refusal blocks skip without charge; healing and setting respawn stay free at any time without agreement (§3.1) | runtime |
| c-land-count | hybrid: exactly 1 settlement per land (approved 2026-09-27); S per land: gnomes = 4, books = 4, movement items ≤ 4, ticket items ≤ 3, key items ≤ 9, towers ≤ 5, settlements ≥ 1; A per land: settlements = 1, missions = 64 cells | generator |
| c-key-item-need | a key item spawns only if its lock type exists in the land | generator |
| c-boss-size | A: boss size/strength from 1 at lvl 1 to full at lvl 10; S: dungeon boss size capped so it fits inside | generator |
| c-arena-waves | exactly 5 waves with tier ladder W/G, W/G, G/B, B/P, P/Y | generator |
| c-mission-reward | S reward rarity = quest tier + 1 (cap legendary) | generator |
| c-world-bounds | hybrid: finite 1024×1024 lands, one land = one region, coordinates −512..511 inclusive on each horizontal axis; 16,384 blocks per land and 16,777,216 blocks per world side; no wrapping; outer boundary marked on map, outward travel including flight/teleport destinations prevented, with turn-back allowed and no special damage/death/forced teleport (§3.1 world) | generator+runtime/UI (deferred) |
| c-zone-size | A zone 256² blocks, region 64² zones; S zone 64² blocks; hybrid zone 64², land 256² zones (D12) | engine |
| c-block-rgb | every solid block has its own RGB; (0,0,0) in `.cub` = empty | data |
| c-name-length | player-character name 2..16 ASCII 32–126 (character creation; creature display names are free text) | runtime |
| c-versions-nonempty | every versioned content instance resolves ≥1 source-version tag explicitly or via a documented family/source inheritance rule, never guessed (item 9); source-independent config, qualified annotations and bounded inheritance follow Validation-contract mapping items 1, 3 and 4 above | load |
| c-roster-ids | every id in `creature-families.json#landscape-rosters` is a creature (D14) | load |
| c-rideable-conflict | resolved (F2): every `rideable` is a boolean, per-page value; a `?` here is a load error | load |
| c-hostile-in-city | villagers/animals inside settlements unattackable unless possessed | runtime |
| c-artifact-stat | definition/config and generated/runtime boundaries follow mapping item 4 above; seven traversal kinds, approved logarithmic config only, one kind plus attack/max HP per artifact and §3.4 accumulation; direct data correction/enforcement deferred | load+generator/runtime (deferred) |
| c-sim-radius | `design.spawns.ai.sim-radius` ≥ `aggro-range` + `leash`, so a creature can still notice you and walk home while you are around (D16) | load |
| c-frame-budget | physics 60 Hz; a tick slower than its budget slows game time instead of stacking catch-up ticks: `Engine.max_physics_steps_per_frame` = `design.frame-budget.max-catch-up-steps` (D17) | engine |
| c-xp-config | `design.progression`: kill-fraction ∈ (0,1]; gap-mult-range = [lo, hi] with 0 ≤ lo ≤ 1 ≤ hi; gap-per-level ≥ 0 (D19) | load |
| c-level-up | level never decreases; after settling, xp < xp-to-next(level); each level gained adds exactly `skill-points-per-level` (D19) | runtime |
| c-tree-shape | for every specialization the tree read from `abilities.json#alpha-tree` has exactly one class node per rank 1..3 and ≤ 1 ultimate; Assassin has Camouflage only at rank 3 and no separate ultimate node (§3.5, exception enforcement deferred); rank 1 and shared-column roots have `needs` 0, one root per shared column, every `unlocks-next` names a node of the same column (D20) | load |
| c-skill-spend | a point is spent only from the banked pool, one at a time, on a node whose prerequisite holds `needs` points; points never leave a node outside a trainer respec (D20) | runtime |
| c-ability-runtime | every class-column and ultimate node of every spec tree has a `design.abilities` entry whose `runtime` is in `runtimes`; cost mp ≤ 100, stamina ≤ `design.movement.stamina.max` or `all`; cooldown-s > 0; dash distance > 0, strike / burst / channel radius > 0, buff / channel duration-s > 0, heal cast-s ≥ 0, projectile / dash `throw` shots as c-moveset-config (D24); `design.status-effects` keys are status-effect ids and an `as` names another key (D21) | load |
| c-settlement-config | `design.settlement`: per-land = 1 (exact-count enforcement deferred), radius > blend ≥ 0, ring-radius < radius, every `buildings` entry is a `buildings.json#buildings` id, every service role is an `npc-roles.json` id, every landscape with a `gen` block has a `style-by-landscape` entry naming a `buildings.json#settlement-styles` id with two `style-colors`, `shop.rarity-cap` is a rarity ≤ legendary, `no-hostiles-within` ≥ radius (D22) | load |
| c-defence-config | `design.defence`: dodge stamina ∈ (0, stamina max], distance / duration-s > 0, iframe-s ≥ 0, every on-dodge key is a passive ability; block max / power-per-hit > 0, damage-reduction ∈ [0,1], front-dot ∈ [−1,1], regen-per-s ≥ 0, guardian-mult ≥ 1; stealth decay-per-s ≥ 0, still-mult ≥ 1, aggro-cut ∈ [0,1]; enemy-hit chances ∈ [0,1]; every `design.abilities` stealth-per-s ≥ 0 (D23) | load |
| c-moveset-config | `design.movesets`: every key is a weapon-type or `default`, an `as` names a plain entry; m1 / m2 `kind` ∈ `kinds`; `applies` (and finisher applies) are `design.status-effects` keys; damage-mult > 0; melee swing-mult / radius-mult > 0, lunge ≥ 0, finisher every ≥ 2 with chance ∈ [0,1]; projectile speed / radius / life-s > 0, count ≥ 1, spread / gravity / splash ≥ 0, pierce needs tick-s > 0; beam / at-cursor range / radius > 0; every non-offhand class weapon-type has an entry (D24) | load |
| c-feel-config | `design.feel`: hit-stop.time-scale ∈ (0,1), max-s ∈ (0,1], every `events.*.hit-stop-s` ∈ [0, max-s]; every `events.*.trauma` ∈ [0,1]; shake.decay-per-s > 0, max-offset ≥ 0, max-roll-deg ≥ 0, shake-mult ≥ 0; every `events.*.sfx` names an `audio.json#sfx-alpha-ids` id with a `design.feel.sfx` entry; every sfx hz > 0, len-s ∈ (0,1], noise ∈ [0,1] and has a `slide`; numbers.life-s > 0, crit-scale ≥ 1, rise-blocks > 0, font-size > 0, every colour a 3-array in [0,1] and a `hit` colour present (the fallback); impact.impact-s / impact-radius > 0, trail.trail-s / trail-every-s > 0, level-up.pop-s > 0, pop-scale ≥ 1, text non-empty; the required event ids `hit crit kill hurt block dodge shoot impact level-up pickup coin` all present (D25) | load |
| c-creature-roles | `design.creature-roles`: `default` ∈ {melee, ranged, mage}; every `any-class` key ∈ {melee, ranged, mage}, every weight ≥ 0, sum > 0; `melee.kind == "melee"`; `ranged` / `mage` `kind == "projectile"` with range > keep-away ≥ 0, windup-s ≥ 0, cooldown-s > 0, damage-mult > 0, `shot` passing the moveset shot checks (speed / radius / life-s > 0 …), every `applies` id a `design.status-effects` key, `sfx` an `audio.json#sfx-alpha-ids` id with a `design.feel.sfx` entry, `color` a valid html colour; every `species` key is a `creatures.json` id, every override key one of `range keep-away windup-s cooldown-s damage-mult shot applies sfx color`, and the merged result (species `shot` replaces the whole shot dict) obeys the same rules (D26) | load |
| c-drowning | S only: breath depletes underwater; empty → HP loss; wall-hold pauses | runtime |
| c-gate-doors | divine doors re-close at 0:00; bell spirit world lasts 30 s (F8) | runtime |

---

