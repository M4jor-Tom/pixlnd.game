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
  recalculation are in §3.4 `artifact`; checked-in data is corrected, but production enforcement remains deferred.
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
tag, or silently promote it to confirmed history. The model retains exact `source_tags` separately
from confirmed `versions`; qualified
annotations do not enter confirmed enums. `test_provenance.gd` covers this bounded handling,
not historical identity research or hybrid availability.

#### Item 4 — Required inputs, source scopes and check boundaries

Owner approved 2026-09-28, with the undeployed-game clarification in §0. This maps existing
rules, not new content, balance or a serialization schema. Required means dependencies of the
**approved hybrid**, including unimplemented systems, not merely today's consumers. Within a
mixed file, historical A/S alternatives, X/cut and Omega-only rows remain reference; requiring
its active definitions does not activate every row or require generating objects at load time.

The item/crafting/social source envelopes are [`item-types-source`, `materials-source`,
`equipment-slots-source`, `consumables-source`, `ingredients-source`, `recipes-source`,
`crafting-stations-source`, `key-items-source`, `pet-food-source` and `affixes-source`](../schema/items.yaml),
[`economy-source` and `mission-types-source`](../schema/catalog-properties.yaml), and
[`npc-roles-source`](../schema/catalog-crafting-social.yaml).
These are literal source roots, not generated objects or selected save formats.
The dependency and finite inheritance scopes below still determine applicability;
source validity never makes historical/cut data active hybrid content.

<a id="required-inputs"></a>

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
| Rules, controls and presentation (§3.7) | `rulesets.json#ruleset-hybrid` object with `flags` object and default boolean; other rulesets reference only. [controls](controls.md) canonical action catalog and [controller profiles](controller-profiles.md); `controller-profiles.json#android` required selected first-slice constants (0.15 deadzone ratio, 48 dp minimum target, 180 degrees per safe width) and distinct canonical action array; `keybinds.json#hybrid` retained keyboard-adapter binding object (not the action registry); `ui.json#{hud,screens,options,camera}` grouped objects; `audio.json#sfx-alpha-ids` string array (includes descriptive entries, not all asset IDs). `slash-commands.json` command-key→row catalog with separate `cuwo-server-commands` array / `chat-rules` object; only approved commands, never `/pvp`. Historical audio backend/track records are not runtime asset requirements. |

`versions.json#{timeline,alpha-to-steam-delta,reception}` (array/object/object) is history
coverage, not an active gameplay dependency merely because the directory loader visits it.
Reference data still needs structural validity and qualified attribution; no whole-file exemption
or uniform row-shape assumption follows from the active/reference distinction.

`generators.json` and its required design attachment have the explicit source structures
[`generators-source` and `generator-design`](../schema/design-items.yaml). The required groups
and their dependent fields are referenced below; the constraint catalog retains their applicability. Current obsolete values do **not** satisfy
later approvals. In particular, require the approved artifact logarithm directly, not decay/floor
as an accepted alternate format. This chooses no new JSON keys for that rule.

| dependency | exact `design` children and nested shapes |
|---|---|
| World/spawns | [`generator-design-enemy-level`, `generator-design-enemy-hp`, `generator-design-terrain` and its height/heightfield children, `generator-design-climate`, `generator-climate-rule`, `generator-design-names` and its land-suffix entries, `generator-design-spawns` and its ai child](../schema/design-world.yaml). These are the required world/spawn input structures; climate expressions remain source strings. |
| Skills/combat | [`generator-design-skill-point`, `generator-design-abilities`, `generator-ability-entry`, `ability-runtime`, `runtime-cost`, `runtime-strike`, `runtime-projectile`, `generator-design-resources`, `generator-design-special-attack`, `generator-design-status-effects`, `generator-status-entry`, `generator-design-movement`, `generator-design-camera`, `generator-design-combat`, `generator-design-defence`, `generator-design-movesets` and plain/alias/move entries](../schema/design-combat.yaml); [`generator-design-progression` and `generator-progression-gap`](../schema/design-progression.yaml). Required moveset/default/class-weapon coverage and cross-catalog closure still follow the catalog below. |
| Roles/feedback/engine | [`generator-design-creature-roles`, `generator-projectile-role`, `generator-role-override`, `generator-design-feel`, its named event/sound/number children, `generator-rgb-entry` and `generator-design-frame-budget`](../schema/design-combat.yaml). References and merged-role semantics still follow the catalog below. |
| Inventory/settlements | [`generator-design-prices`, `generator-design-stack-cap`, `generator-design-loot` and its coin/weight/ground children, `generator-design-starting-inventory`, `generator-design-settlement` and its footprint/style/service children, `generator-design-initial-encounters` and its named geometry/tier/role/special/spirit/package children](../schema/design-items.yaml); [`gear-hp-design`](../schema/design-progression.yaml). The [encounter contract](encounter-contracts.md) governs generated content and lifecycle, separately from these inputs. |
| Other approved systems | [`artifact-design`, `generator-design-artifacts-per-land`, `generator-design-circle-of-power`](../schema/design-progression.yaml); [`generator-design-recipes`, `generator-design-pvp` and the string-valued `generator-design.item-stat-curve`, `.block-reward`, `.regeneration`](../schema/design-items.yaml). Required definitions do not activate incomplete systems; the artifact formula remains the approved rule, not a newly fixed text spelling. |

Other `generators.json` inputs for §6 have explicit attachments in
[`generators-source`](../schema/design-items.yaml) and the corresponding
[`generator-source-*` owners](../schema/design-world.yaml). They remain mixed historical/approved-system objects:
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
| UI/engine/assets | Canonical action/profile reference closure, binding/UI/sound/format declarations and frame-budget config; no historical control fallback. | Player-name input limits, actual RGB payloads, map/input/HUD/feedback and physics/catch-up behavior; nonexistent generated payloads are not malformed definitions. |

Future regressions must exercise each predicate at its mapped boundary, including item 9's
missing-whole-input cases. Current bounded checks cover required identity catalogs and raw row shapes,
bidirectional class/spec ownership, two distinct ordered spec indices, shared-column roots/links and
the single rank-3 Assassin Camouflage exception (`test_identity_skills.gd`); the required race catalog
(eight playable race IDs, row objects, boolean `playable`, size class); required whole movesets/default/kinds and
class-weapon entries with the existing moveset predicates, district building/class references, and
landscape dungeon/POI references. The mapped heterogeneous required catalogs/configuration,
raw conversion guards, climate-rule parsing, family members and settlement building/service/style
references have bounded checks (`test_required_inputs.gd`). Historical landscape style descriptors
remain raw reference text with finite resolution; runtime style selection stays in
`design.settlement.style-by-landscape`. Forest roster race/family tokens are shape-checked, not
silently reinterpreted as creature IDs. District trainer qualification and landscape notes follow
[the structure definitions](3_Classes.md#district); desert-ruins identity remains unresolved.
Finite source resolution (`source_at`) reports exact tags and their explicit/envelope origin;
`test_provenance.gd` covers the listed envelopes and explicit malformed-tag rejection in selected
content families. Source-table origin is not functional availability; prose qualifiers remain raw.
The 48 untagged obtainable foods have no fabricated A+S fallback. Unmapped histories above remain
unresolved; the existing modded `!goto`/`!tp` row and hybrid UI debug-menu/skills/npc-service annotations
retain their exact context, not new historical tags or wholly resolved ancestry. This does not
complete global `c-versions-nonempty`.
These checks retain earlier load errors and accumulate independent failures. A passing validator
does not prove the rest of this mapping's enforcement; further data correction and
loader/validator/generator/runtime work need separate authority.

### Constraint catalog

| id | rule | layer |
|---|---|---|
| c-control-references | action IDs are unique and resolve in [controls](controls.md); profiles and inert action references resolve there; every binding names its profile and distinct action meaning(s); shared physical inputs/aliases never merge intentions or add a fifth class skill; Assassin has only third-slot Camouflage; unselected mappings remain explicit, without physical defaults in canonical actions | documentation + scoped Android first-slice load checks; broader enforcement deferred |
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
| c-hands | 1H ×2 or 1H + shield or one 2H; either hand may independently be empty, with the other item untouched and still subject to class/subtype/slot/2H legality; a shield alone can block, but weapon attacks require a main-hand weapon (§3.3 weapon-type); bracelets need two for full damage; hybrid wand is mechanically 2H with no other hand item, regardless of pose | runtime |
| c-item-upgrade-count | logical Item.upgrades contains active placed cubes only, at most 32 globally; upgrade-count (u32) equals its list length, including 0 for an empty list; no inactive-slot/native layout is selected and existing stat equations are unchanged (§3.4 item); structure: [`item-upgrades`, `item-upgrade-count`](../schema/items.yaml) | load+runtime |
| c-item-weapon-type | each weapon Item has one scalar logical weapon-type reference agreeing with its existing type/sub-type meaning; nonweapon Items have no applicable weapon-family link; existing type/sub-type ranges remain unchanged, with no numeric-source-code conversion or implicit reference resolution selected (§3.4 item); structure: [`item-weapon-type` and `item.rules`](../schema/items.yaml) | load+runtime |
| c-cube-cap | active placed upgrades ≤ 16 (1H) / 32 (2H, shield), governed by the Item's linked weapon definition (wand 32, shield 32, bracelet 16); wood cubes only on weapons whose concrete Item.material is wood-kind, iron cubes only on weapons whose concrete Item.material is metal-kind; use existing material-kind facts, not unparsed weapon allowed-material alternatives; these implications do not restrict every upgrade to wood/iron, add gold/bracelet exceptions, alter spirit rules or assign capacity/availability to unknown/cut rows; structure: [`item.rules`, `item.all_of` and `item-upgrades`](../schema/items.yaml) | load+runtime |
| c-spirit-level | A / hybrid: weapon.level − 10 ≤ spirit.level ≤ weapon.level; hybrid weapon and spirit `level` are item-power points, not source levels (§3.4 item) | runtime |
| c-power-gate | A reference: item.level ≤ power(player.level) for full strength. Hybrid non-equipment: the same condition remains necessary for full strength; no below-threshold effects are selected. Hybrid equipment: equipping requires item.level ≤ power(player.level); above-power gear may be carried/traded/kept, with normal stats once eligible and equipped, not weakened stats. Equipment-only scope and exclusions follow [power-gate](3_Classes.md#power-gate-a). Formula learning retains its sufficient-power requirement. Hybrid books record recipes immediately, but above-power recipes remain known and visibly locked against crafting until their requirement is reached; duplicate acquisition never removes the lock (§3.5 power-gate) | runtime (new-equipment admission implemented; recipe enforcement deferred) |
| c-book-recipe-persistence | hybrid: book-learned recipes remain known to that character across lands and sessions, with no relearning on travel, including between worlds under persistence item 1 (§3.7 save-data) | runtime+save-data (deferred) |
| c-permanent-source-claim | hybrid: at most one claim per character/saved-world/artifact-or-one-time-book-source; claims remain available to other characters at the source and are not renewed by leaving, restarting, returning or daily enemy resets (§3.7 save-data, item 5; §3.1 world/reset item 3); ordinary ground loot unchanged | runtime+save-data (deferred) |
| c-recipe-learning | hybrid: books/formulas share one known-recipe set per character, including known-but-power-locked recipes; repeated learning grants nothing extra; books teach only unknown recipes without rerolls/compensation; an already-known formula remains unconsumed, without bypassing c-power-gate (§3.4 recipe) | runtime (deferred) |
| c-region-lock | DROPPED (D4). S reference: item.land ≠ current land ∧ ¬plus → worn; key items inert | — |
| c-plus-adjacent | DROPPED (D4). S reference: plus item full stats iff current land adjacent | — |
| c-gear-global | hybrid: an item's stats are identical in every land; key items and artifacts work everywhere once found | runtime |
| c-climbing | hybrid: basic climbing needs neither points nor Spikes; Climbing points reduce stamina drain and global Climbing Spikes reduce consumption by 75%, not eliminate it; 5 Climbing points remain a Hang Gliding prerequisite; item 5 applies Spikes after skill reduction (remaining cost ×0.25), never additive percentage points; no skill curve/floor or artifact-combination rule inferred (§3.4/§3.5) | runtime (deferred) |
| c-rarity-range | rarity ∈ 0..4 for generated items (5 = mythical bug, off by default) | load |
| c-stat-roll | roll = ((attributes<<16)+modifier) mod 21 ∈ 0..20; normalized roll = roll/20, not rarity; hybrid gear HP is fixed under §3.4 item and independent of this roll, with no change to other stat rules | generator |
| c-gear-hp | hybrid fixed item HP and equipped maximum/current-HP transitions follow §3.4 item; require the finite selected [`gear-hp-design`](../schema/design-progression.yaml) configuration, material `hp-bonus` iron=1/cotton=0.75/linen=0.5, and unique required chest/gloves/boots/shoulders/main-hand/off-hand slot rows with `hp-mult` chest=1, others=0.5; missing/malformed/changed selected inputs accumulate errors without coercion or historical HP fallback | load (selected inputs) + generator/runtime |
| c-item-power | hybrid item power and recipe/formula requirements use integer +1…+100 units under [item](3_Classes.md#item): convert source level before existing power-point spread, then clamp; no spread means direct conversion. Preserve producer identities/unit boundaries under [shops](3_Classes.md#shop), [loot](3_Classes.md#loot-rule) and [encounter contracts](encounter-contracts.md); stat/price equations unchanged | generator+runtime+save-data (recipe/formula production deferred) |
| c-loot-config | [`generator-design-loot`, its coin/rarity/gear/ground children and `generator-design-stack-cap`](../schema/design-items.yaml) declare source scalar, weighted-entry, cardinality and nominal reference facets; the selected reward inputs also obey c-encounter-rewards-config. Gear spread is in power points after source conversion (c-item-power). Item-type/consumable references must resolve; structural carriers alone do not establish target existence. | load |
| c-apple-heal | hybrid Apple healing follows [consumable](3_Classes.md#consumable); require `consumables.json#apple` and its loaded definition, with finite numeric `heal-mult` exactly 20 in both raw configuration and loaded raw data, agreeing with the typed coefficient; missing/malformed/changed selected inputs accumulate errors without coercion. Other foods may omit healing coefficients; no general zero-heal rejection policy | load (selected inputs) + runtime |
| c-stack-rule | only `design.stack-cap.stackable` item-types stack (no cap, D6); gear (has a modifier roll) is one item per entry | runtime |
| c-slot-accepts | an item equips only in a usable equipment-slot whose `accepts` lists its item-type and whose subtype restrictions it satisfies (§3.4 equipment-slot); weapon-type `offhand` hands → off-hand only; c-weapon-class and c-hands still apply | load + runtime |
| c-mp-range | mp ∈ [0, 100]; mage regenerates passively, others gain by hits/blocks/stealth/dodges; numbers `design.resources.mp` (D21) | runtime |
| c-attack-defence | hybrid: classify the attack, not merely its attacker, under §3.3 stat; exactly one equipment defence: magical uses Resistance, physical uses existing armor rules, never both; combo armor penetration does not extend to Resistance | runtime |
| c-resistance-mitigation | hybrid: for a magical hit with incoming damage `D ≥ 0` and Resistance `R ≥ 0`, the Resistance-stage result is `max(D - R, 0.1 × D)`; zero stays zero, fractions allowed, no minimum-one rounding; unequipped creatures/NPCs have innate `R = 0` with no automatic level/species/role/family scaling; any equipment contribution is separate; then existing block and damage-reduction multipliers, then absorption shields; not a final HP-loss floor, absorption may prevent all HP loss; preserve existing block eligibility/exhaustion, multiplier values, absorption-pool rules and status protections (§3.3 stat) | runtime |
| c-resistance-dot | hybrid: hit-derived DOT inherits its triggering hit's Resistance reduction once (§3.3 stat, item 4); never subtract Resistance again per tick; independently sourced poison and environmental hazards gain no Resistance protection; existing status identity/application/duration, dodge exceptions, drinks and status protections remain unchanged | runtime |
| c-combat-burning-applications | hybrid combat hit-derived burning applications coexist independently, without replacing or refreshing earlier burns; each lasts 4 s with eight ticks at 0.5, 1, …, 4 s after application, at the existing 10% of triggering-hit coefficient; preserve Resistance, dodge/status protections and aggro rules; environmental hazards and additional DOT buff timing are outside scope (§3.3 status-effect) | load-time (selected design inputs) + runtime |
| c-combat-poison-applications | hybrid combat hit-derived poison applications have independent lifetimes and schedules; a new application neither renews older stacks nor resets their next tick; dagger poison ticks at 1, 2, 3, 4, 5 s after its own application, preserving inherited hit damage/crit and the existing five-times-hit total over 5 s; preserve Resistance, dodge/status protections and aggro rules; environmental hazards and additional DOT buff timing are outside scope (§3.3 status-effect) | load-time (selected design inputs) + runtime |
| c-stun-immunity | cannot re-stun while stars shown | runtime |
| c-threat-pair | at most one `threat` relation per ordered logical mob/player entity pair; each present relation has exactly one non-negative numeric `aggro-points` amount in aggro points, independent of other pairs; changing `current-target` does not clear it; decay/gains (including the full-stealth damage exception), the zero floor, player-death and arrival clearing, and escape/temporary-absence retention follow §3.2; actual mob death/respawn starts fresh, but midnight itself grants no survivor wipe (§3.1 world/reset item 4); decay reflects elapsed gameplay time even outside simulation radius; surviving-mob restart retains threat/order/neutral provocation under persistence item 9 (§3.2), with no downtime decay (§3.1) | runtime+save-data (deferred) |
| c-current-target | at most one present, living player target per mob; ordinary targeting compares that mob's eligible players by highest `aggro-points`, retains a tied current target, otherwise breaks positive-threat ties by earliest engagement; without a positive-threat priority or valid current target, choose the nearest normally detected zero-threat player without granting aggro/order (§3.2); player-death, zero-threat and arrival order resets, escape retention and fresh assignment follow §3.2; at zero, ordinary pursuit requires normal detection and hostility/provocation eligibility; equally nearest fallback ties are chosen randomly once with equal chances, then normal retention applies; Heroic Shout temporarily overrides ordinary targeting without threat/order gain; eligibility, duration, replacement, per-enemy simultaneous arbitration and termination follow §3.2; taunt expiry reflects elapsed gameplay time even outside simulation radius; taunt alone adds no neutral provocation or lasting ordinary caster eligibility (§3.2) | runtime |
| c-pack-response | only the generated pack responds, under the hostile-detection / aggressor-specific neutral-provocation rules in §3.2; friendly/passive creatures are excluded and protected return cannot be interrupted; share current sightings only, never threat/order, and select targets independently; each neutral clears its own provocation on arrival (§3.2) | runtime |
| c-return-home | pursuit beyond the home leash starts return regardless of threat; within it, target loss checks eligible positive-threat players then normal detection of eligible players (§3.2); attacks do not restart pursuit during return; ×2 normal return speed and 90% damage reduction (including DOT) until reaching home alive, then full HP and clear this mob's aggro/order toward every player and its neutral provocation once, ending both bonuses; no revival, cleansing or CC immunity; gains/decay continue until arrival and other mobs' records are unchanged; starting return cancels taunt, and new taunts neither interrupt nor queue for afterward | runtime |
| c-combo-reset | any attack with a hitbox that misses resets combo to 0, subject to the hybrid whole-channel and combo-neutral zero-damage-taunt rules in §3.3 combo-system; cap per weapon-type | runtime |
| c-dodge-cost | dodge costs 25 stamina; requires movement ([dodge](controls.md#dodge)); hybrid numbers `design.defence.dodge` (D23) | runtime |
| c-no-death-penalty | death never removes gold/items/xp; respawn at statue (A) / activated shrine (S) | runtime |
| c-time-speed | clock 10× real while the world runs; hybrid saved worlds start at 07:00 only at creation, existing worlds resume saved time with no shutdown gameplay time or reset catch-up (persistence item 8, §3.1); reference sleep 100× clock-only (baseline/units unresolved, source item 10 above); hybrid inn sleep skips to the next 07:00 without fast-forwarding combat/status effects/cooldowns (§3.1) | runtime (clock/save enforcement deferred) |
| c-midnight-reset | at 0:00 respawn eligible mobs, regen daily missions, deposits, plants; restock shops; hybrid defeated ordinary-dungeon/repeatable-daily enemies including bosses return, completed one-time-objective guards/boss stay cleared, and artifact/book claims never renew; preserve world improvements' existing reset rules; occupied dungeon/quest sites wait until all players leave (occupancy defined in §3.1), coalescing missed midnights into one pending refresh; the clock itself never heals/replaces living enemies or erases a fight, preserving ordinary threat/home-return rules (§3.1 world/reset items 3–4); sleep applies ordinary midnight resets once only if crossing midnight, never extra shop refreshes/mission rerolls merely for sleeping (§3.1) | runtime+save-data (deferred) |
| c-supplier-rescue | hybrid rescue eligibility, immediate talk/automatic last-player-exit completion and once-only shared benefit follow §3.5 gnome-supplier; last-exit completion precedes pending refresh, which must not restore completed designated guards/bosses | runtime+save-data (deferred) |
| <a id="c-inn-hours"></a> c-inn-hours | hybrid: separate 10-copper sleep service only 18:00–06:00 → next 07:00; all connected players explicitly agree, initiator pays the single fee only on success; refusal blocks skip without charge; healing and setting respawn stay free at any time without agreement (§3.1) | runtime |
| c-land-count | hybrid: exactly 1 settlement per land (approved 2026-09-27; structure: [`land-settlements`](../schema/world.yaml)); S per land: gnomes = 4, books = 4, movement items ≤ 4, ticket items ≤ 3, key items ≤ 9, towers ≤ 5, settlements ≥ 1; A per land: settlements = 1, missions = 64 cells | generator |
| c-key-item-need | a key item spawns only if its lock type exists in the land | generator |
| c-connecting-routes | hybrid connecting paths and their leading objects follow existing terrain without flattening, cutting or filling it; site terrain rules remain unchanged; each route repeats its selected destination-themed object family instead of a continuous, visibly delimited road surface, under [connecting routes](3_Classes.md#hybrid-connecting-routes); preserve destination scope and independent site geometry; no external walkability/access gate; optional guidance failure does not suppress terrain/sites/gameplay | generator+runtime |
| c-required-content-solvability | future hybrid dungeon/mission completion objectives and guaranteed rewards each have a lawful noncircular route for a fresh solo character of any class in the same saved world, under [required-content solvability](6_Generators.md#future-required-content-solvability); preserve traversal requirements and initial scope; artifact/book sources follow only with later authorized placement contracts | generator+runtime (deferred) |
| c-initial-encounter-config | `design.initial-encounters` consumes the selected [placement, geometry, population, assignment, local stat, special timing/damage, rubble restoration, spike and furnishing inputs](encounter-contracts.md); authored logical structures are [`encounter-volume`, `encounter-population`, `encounter-assignment`, `boss-special-profile`, `rubble-profile`, `spike-trap-profile`, `furnishing-profile`, `vase-profile`, `table-profile`](../schema/world.yaml); the explicit required source attachments, positional structures and selected finite numeric facets are [`generator-design-initial-encounters` and its named children](../schema/design-items.yaml); errors accumulate, never becoming executable defaults | load |
| c-initial-encounters | initial hybrid families satisfy the [encounter contracts](encounter-contracts.md): complete village/site generation within bounds independently of optional guidance, persistent identities/positions/roles, protected settlement and structure, playable geometry/closed occupancy, populations/tiers/local difficulty, designated clears, boss specials/rubble, traps/furnishings, nonduplicating shared kill/boss/mission rewards and supplier ceiling; corresponding authored structures include [`initial-ruins-assembly`, `initial-camp-assembly`, `initial-rescue-assembly`, `initial-site-placement-profile`](../schema/world.yaml); initial permanent-source exclusion does not replace final coverage; preserve c-midnight-reset, c-supplier-rescue and c-permanent-source-claim | generator+runtime+save-data (deferred) |
| c-boss-size | A: boss size/strength from 1 at lvl 1 to full at lvl 10; S: dungeon boss size capped so it fits inside; initial hybrid bosses use the [local height rule](encounter-contracts.md#local-difficulty-and-boss-size) | generator (hybrid enforcement deferred) |
| c-arena-waves | The bound positional ladder is declared by [`generator-source-boss.arena-waves`](../schema/design-world.yaml); raw source order is retained. | generator |
| c-encounter-rewards-config | [`generator-design-loot` and its selected scalar/keyed/pool/ground facets, `generator-design-initial-encounters-mission-package`, and `generator-design-settlement-shop`](../schema/design-items.yaml) declare the exact selected input structures and values. Ingredient/consumable/spirit/class/gear references must resolve; generated rewards and saved issuance/stock are checked separately. | load + generator/runtime/save-data |
| c-mission-reward | S reward rarity = quest tier + 1 (cap legendary); initial hybrid [shared packages](encounter-contracts.md#shared-mission-packages-and-supplier-shops) govern quantities, class selection, once-only timing and saved undelivered rewards | generator+runtime+save-data (hybrid deferred) |
| c-world-bounds | hybrid: finite 1024×1024 lands, one land = one region, coordinates −512..511 inclusive on each horizontal axis ([`land-coords`](../schema/world.yaml) on [`land`](../schema/world.yaml); `world` bounds remain distinct); 16,384 blocks per land and 16,777,216 blocks per world side; no wrapping; selected `design.terrain` scales conform to the explicit required parent/scale facets in [`generator-design.terrain`](../schema/design-items.yaml) and [`generator-design-terrain`](../schema/design-world.yaml); missing/malformed/changed inputs accumulate validation errors; outer boundary marked on a fixed boundary/player overview (no terrain, exploration or manipulation), outward travel including flight and teleport destinations (current dash integrated by this slice) at any altitude stopped like a wall, with turn-back allowed and no special damage/death/forced teleport; current Teleport costs/cooldowns preserved; map remains live and gates new player requests while open (§3.1 world) | generator+runtime (item 1); runtime (item 2; Android hardware acceptance unverified) |
| c-zone-size | A zone 256² blocks, region 64² zones; S zone 64² blocks; hybrid zone 64², land 256² zones (D12) | engine |
| c-block-rgb | every solid block has its own RGB; (0,0,0) in `.cub` = empty | data |
| c-name-length | player-character name 2..16 ASCII 32–126 (character creation; creature display names are free text) | runtime |
| c-versions-nonempty | every versioned content instance resolves ≥1 source-version tag explicitly or via a documented family/source inheritance rule, never guessed (item 9); source-independent config, qualified annotations and bounded inheritance follow Validation-contract mapping items 1, 3 and 4 above | load |
| c-roster-ids | every id in `creature-families.json#landscape-rosters` is a creature (D14) | load |
| c-rideable-conflict | resolved (F2): every `rideable` is a boolean, per-page value; a `?` here is a load error | load |
| c-hostile-in-city | villagers/animals inside settlements unattackable unless possessed | runtime |
| c-artifact-stat | definition/config and generated/runtime boundaries follow mapping item 4 above; seven traversal kinds, approved logarithmic config only, one kind plus attack/max HP per artifact and §3.4 accumulation; checked-in data corrected, production enforcement deferred | load+generator/runtime (deferred) |
| c-sim-radius | [`generator-design-spawns.ai` and `generator-design-spawns-ai`](../schema/design-world.yaml) declare the simulation-distance relationship, so a creature can still notice you and walk home while you are around (D16). | load |
| c-frame-budget | Timing parameter facets are [`generator-design-frame-budget.physics-hz` and `.max-catch-up-steps`](../schema/design-combat.yaml). A tick slower than its budget slows game time rather than stacking catch-up ticks (D17). | engine |
| c-xp-config | [`generator-design-progression` and the positional `generator-progression-gap`](../schema/design-progression.yaml) declare the kill fraction, gap rate and straddling interval facets (D19). | load |
| c-level-up | level never decreases; after settling, xp < xp-to-next(level); each level gained adds exactly `skill-points-per-level` (D19) | runtime |
| c-tree-shape | for every specialization the tree read from `abilities.json#alpha-tree` has exactly one class node per rank 1..3 and ≤ 1 ultimate; Assassin has Camouflage only at rank 3 after 5 Sneak points and no separate ultimate node (§3.5); rank 1 and shared-column roots have `needs` 0, one root per shared column, every `unlocks-next` names a node of the same column (D20) | load |
| c-skill-spend | a point is spent only from the banked pool, one at a time, on a node whose prerequisite holds `needs` points; points never leave a node outside a trainer respec (D20) | runtime |
| c-ability-runtime | [`generator-design-abilities`, `generator-ability-entry`, `ability-runtime`, `runtime-cost`, `runtime-strike`, `runtime-projectile` and the six status payload variants](../schema/design-combat.yaml) declare kinds, conditional presence and scalar/cardinality/selected-taunt facets. Every class-column/ultimate node of every spec has a configured runtime; numeric stamina costs must not exceed configured movement stamina maximum, with the all-resource alternative retaining its spending rule. Configured status keys resolve to status definitions and an as-target resolves to another configured key. Cyclone directional contacts, clipped active time and inclusive final contact remain §3.3; no defaults/coercion or new runtime is selected (D21/D24). Every configured ability runtime must occur in the actual `design.abilities.runtimes` array; sharing a vocabulary enum alone does not satisfy this join. | load |
| c-settlement-config | [`generator-design-settlement` and its footprint/building/style/NPC/shop children, with the three predicates on `generator-design.settlement`](../schema/design-items.yaml), declare the source count, geometry, scalar and nominal reference facets. Generated geography is checked separately. Every building/service reference must resolve; every generated landscape must select a configured settlement-style with its two colours (D22). | load |
| c-defence-config | [`generator-design-defence` and its dodge/block/stealth/enemy-hit children](../schema/design-combat.yaml), [`generators-source.design`](../schema/design-items.yaml), and `ability-runtime-stealth-per-s` declare the scalar facets and dodge/stamina relationship. Every on-dodge key must resolve to a passive ability, not merely a named ability. Existing activation, block/exhaustion, stealth and hit behavior remain unchanged (D23). | load |
| c-moveset-config | [`generator-design-movesets`, `generator-moveset-entry`, plain/alias entries, `generator-move`, `generator-move-finisher`, `GeneratorMoveKind` and `runtime-projectile`](../schema/design-combat.yaml) declare required class-weapon membership, closed payloads, kinds and scalar/cardinality facets. Every key is a weapon-type or default; aliases resolve to a configured plain entry; move/finisher applies resolve to configured status keys (D24). Every configured m1/m2 kind must occur in the actual `design.movesets.kinds` array; sharing a vocabulary enum alone does not satisfy this join. | load |
| c-feel-config | [`generator-design-feel` and its hit-stop/shake/numbers/RGB/impact/trail/level-up/event/sound children, including the shared `generator-feel-event` payload](../schema/design-combat.yaml), plus the event-duration predicate on [`generator-design.feel`](../schema/design-items.yaml), declare required event membership, scalar/array facets and the configured maximum relationship. The hit colour is the fallback. Each event sound resolves through the qualified audio identifier list to a configured sound entry; typing alone does not establish that closure (D25). | load |
| c-creature-roles | [`generator-design-creature-roles`, `GeneratorRole`, keyed weights, melee/projectile roles, species entries and the closed `generator-role-override`](../schema/design-combat.yaml) declare source shapes, scalar and range/keep-away predicates. Applies resolve to configured statuses; sounds resolve through the qualified audio list and feedback configuration; species keys resolve to creatures. A species shot replaces the whole shot; the merged result must satisfy the role rules. Colours follow c-design-color-syntax (D26). | load |
| c-design-color-syntax | Configuration string-colour lexical facets are [`generator-projectile-role.color` and `generator-role-override.color`](../schema/design-combat.yaml), [`generator-design-terrain.water-color`, `.sand-color`, `.snow-color`](../schema/design-world.yaml), and [`generator-design-settlement-style-colors-entry.value`, `generator-design-settlement-npc.color`](../schema/design-items.yaml). The scope remains exactly `design.creature-roles.{ranged,mage}.color`, `design.creature-roles.species.*.color`, `design.terrain.{water-color,sand-color,snow-color}`, each member of `design.settlement.style-colors.*`, and `design.settlement.npc.color`. Components mean red/green/blue, with alpha last when present. Other colour representations are unchanged. | load |
| c-drowning | S only: breath depletes underwater; empty → HP loss; wall-hold pauses | runtime |
| c-gate-doors | divine doors re-close at 0:00; bell spirit world lasts 30 s (F8) | runtime |

---

