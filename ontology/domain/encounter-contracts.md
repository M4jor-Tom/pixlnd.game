# Initial hybrid encounter contracts

The initial [mission families](3_Classes.md#mission-type) are an ordinary multi-boss ruins
dungeon, a repeatable daily ruined skeleton encampment and one-time world-shared supplier
rescues. Documentation is not runtime coverage or implementation permission.

## Placement and access

The corresponding required source inputs are [`generator-design-initial-encounters (distance/separation/apron/dry/hub fields), generator-design-settlement.no-hostiles-within`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

Each land has one ruins dungeon, one daily camp and four supplier sites. Site centres are
land-seeded; [`initial-site-placement-profile`](../schema/world.yaml) declares the inclusive
village-distance thresholds and minimum separation (`minimum-village-distance-blocks`,
`maximum-village-distance-blocks`, `minimum-site-separation-blocks`). The contract is covered by
`test_initial_site_placement_{contracts,values,mutations}`. Their saved-world locations stay fixed
across visits and daily renewal under [mission-type](3_Classes.md#mission-type).

Each site has a flat floor at `H = max(natural ground height, sea level + clearance)`, where
[`initial-site-placement-profile.sea-level-floor-clearance-blocks`](../schema/world.yaml) is the clearance in blocks. The configured `terrain-apron-blocks` remains in that same profile. Optional terrain-following
[leading objects](3_Classes.md#hybrid-connecting-routes) suggest destinations without guaranteeing
walkable connections. No connecting width, step, slope or reachability test gates placement or
publication; climbing or detours may be necessary. Guidance never reshapes terrain or adds
supports/crossings. Internal doors, corridors and trap-free lanes retain their dimensions.
Enemy homes and pursuit envelopes stay outside the village's existing protected area
([settlement](3_Classes.md#settlement), `generators.json#design.settlement.no-hostiles-within`).

Ocean lands retain dry site islands. Where village generation otherwise fails, provide a dry
village hub with the configured `fallback-village-hub-width-blocks` and
`fallback-village-hub-depth-blocks` in [`initial-site-placement-profile`](../schema/world.yaml),
containing the required settlement and valid village-square spawn, not a substitute landing. Validate the village and all six sites together, including
finite-world bounds, independently of optional guidance. The complete logical land/site association is
[`initial-populated-land`](../schema/world.yaml), covered by `test_initial_populated_land_contracts`,
`test_initial_populated_land_owner_binding`, and `test_initial_populated_land_mutations` in
`test_ontology_schema_world_populated_land.py`; it does not claim physical placement or runtime occupancy.
Required geography failure produces
a generation diagnostic, never fewer suppliers or partially populated encounters. Guidance
failure only omits guidance, retaining terrain, village, sites and gameplay.

## Geometry and occupancy

The corresponding required source inputs are [`generator-design-initial-encounters-ruins, generator-design-initial-encounters-camp, generator-design-initial-encounters-supplier`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

All dimensions are in blocks. Ruins' structural layout, exact component dimensions/counts,
overall bounds, ceiling/door sizes and trap-free lane are declared by
[`initial-ruins-assembly`, `ruins-room-volume`, `ruins-corridor-volume`, `ruins-court-volume`,
`ruins-passage-volume`, and `ruins-alcove-volume`](../schema/world.yaml).
`test_initial_site_assembly_contracts` and `test_initial_site_assembly_values` cover the assembly;
`test_encounter_geometry_and_population` covers volume dimensions. Trap and furnishing counts
are in [`spike-trap-profile.count-per-ruins-site`, `vase-profile.count-per-ruins-room`,
`vase-profile.full-health`,
`table-profile.count-per-ruins-room`, and `table-profile.full-health`](../schema/world.yaml),
covered by `test_rubble_trap_profiles` and `test_furnishing_profiles`.

Ruins occupancy is the closed union of the playable rooms, corridors, entrance court, entrance
passage and alcove, not the empty space of the enclosing rectangle; the component vertical extents
are declared in the named volume classes above. Camp and rescue battlefield dimensions and vertical
extents are [`camp-battlefield-volume` and `rescue-battlefield-volume`](../schema/world.yaml),
covered by `test_encounter_geometry_and_population`. Outdoor geometry is assembled by
[`initial-camp-assembly` and `initial-rescue-assembly`](../schema/world.yaml); both have two opposite
[`initial-battlefield-exit`](../schema/world.yaml) occurrences (each with an [`initial-battlefield-exit.width-blocks`](../schema/world.yaml) member), associated by
[`initial-opposite-exits`](../schema/world.yaml). `test_initial_site_assembly_contracts` and
`test_initial_site_assembly_values` cover assembly and exit declarations. Both battlefields have visible boundaries
and opposite exits. [Closed-volume occupancy](3_Classes.md#game-clock) still counts boundaries as
inside and requires all players outside every component, without extra grace.

## Populations, tiers and clear conditions

The corresponding required source inputs are [`generator-design-initial-encounters.species, .pack-size, .role-weights and the ruins/camp/supplier tier fields`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

Enemies are skeletons (`creatures.json#skeleton`), including at the ruined skeleton encampment;
this does not add skeletons to unrelated ambient biome rosters. Site identity/allocation and the
clear rules below remain separate from the population shapes linked in the table.

| Site | Population declaration | Tier | Clear predicate |
|---|---|---|---|
| Ruins | [`ruins-population`, `ruins-population.packs`, `ruins-population.pack-size`, `ruins-population.bosses`, `ruins-population.hostiles`, and `ruins-population.captives`](../schema/world.yaml); [`initial-populated-ruins-room` and `initial-populated-ruins-assembly`](../schema/world.yaml) | Rooms green → blue → purple; bosses blue and purple | All designated hostiles defeated |
| Daily camp | [`camp-population`, `camp-population.packs`, `camp-population.pack-size`, `camp-population.bosses`, `camp-population.hostiles`, and `camp-population.captives`](../schema/world.yaml); [`initial-populated-camp-assembly`](../schema/world.yaml) | Green | All designated hostiles defeated |
| Each supplier rescue | [`rescue-population`, `rescue-population.packs`, `rescue-population.pack-size`, `rescue-population.bosses`, `rescue-population.hostiles`, and `rescue-population.captives`](../schema/world.yaml); [`initial-populated-rescue-assembly`](../schema/world.yaml) | Existing white/green/blue/purple site tier | All designated hostiles defeated, then the existing rescue-completion rule |

`initial-populated-ruins-room` and `initial-populated-ruins-assembly` retain the three
contained room occurrences in green/blue/purple order: each room has one three-guard pack;
room one has no separate boss, while rooms two and three each have a separate non-mission
boss. The ruins room/assembly declarations are covered by `test_initial_ruins_population_contracts`,
`test_initial_ruins_population_order_binding`, `test_initial_ruins_population_values`, and
`test_initial_ruins_population_native_mutations` in `test_ontology_schema_world_ruins_population.py`
and `test_ontology_schema_world_ruins_population_values.py`.
`initial-populated-camp-assembly` and `initial-populated-rescue-assembly` link each outdoor
geometry occurrence to its designated population and permanent pack/boss assignments; existing
coverage is `test_initial_outdoor_population_contracts`, `test_initial_outdoor_population_values`,
and `test_initial_outdoor_population_native_mutations` in `test_ontology_schema_world_outdoor_population.py`.
These are designated logical associations, not current survival/spawn state or placement/execution.
The population declarations above, covered by `test_encounter_geometry_and_population`, hold the exact
pack, boss, hostile and captive counts. No reinforcements are selected for these contracts. Each
pack and singleton boss independently rolls its basic role with the declared 50/30/20 distribution
in [`initial-site-hostile-profile`](../schema/world.yaml), covered by `test_initial_site_hostile_profile_contracts`; role assignment per individual is [`encounter-assignment`](../schema/world.yaml), covered by `test_encounter_assignments_and_shared_reward_contract`. Existing basic attacks and status
protections remain unchanged. Positions and roles persist across unloading, restarting and
daily renewal; renewal does not reroll them.

Leaving while designated enemies survive is not completion. Rescue eligibility and the
conversation/automatic last-player-exit fallback follow [gnome-supplier](3_Classes.md#gnome-supplier-s):
the once-only shared completion/benefit precedes pending refresh. Ordinary-dungeon and daily-camp
enemies retain their daily refresh eligibility; completed one-time rescues stay cleared under
[game-clock](3_Classes.md#game-clock).

## Local difficulty and boss size

The corresponding required source inputs are [`generator-design-initial-encounters.power-base-offset, .boss-hp-mult, .boss-damage-mult, .boss-height`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

The fixed local difficulty and spawn facets are [`initial-site-local-difficulty-profile`,
`initial-site-hostile-spawn`, and `initial-site-boss-spawn`](../schema/world.yaml), covered by
`test_initial_site_local_difficulty_contracts`, `test_initial_site_local_difficulty_values`, and
`test_initial_site_local_difficulty_mutations` in `test_ontology_schema_world_local_difficulty.py`.
Reuse the existing NPC health and damage curves (`stats.json#alpha-character-formulas.npc-hp`,
`generators.json#design.combat.enemy-attack`) with local power-base formula
`p = power-base-offset + t`, where [`initial-site-local-difficulty-profile.power-base-offset`](../schema/world.yaml)
is the offset and tier index `t = 0, 1, 2, 3, 4` means white, green, blue, purple, yellow. Preserve the existing party-level
rules (`generators.json#design.enemy-level`); never rescale surviving enemies mid-fight.

At the same level and power, boss health uses [`initial-site-local-difficulty-profile.boss-hp-multiplier`](../schema/world.yaml) and
boss direct damage uses [`initial-site-local-difficulty-profile.boss-direct-damage-multiplier`](../schema/world.yaml). Hit-derived DOT
retains its existing once-only inheritance, not a second boss multiplier. Boss height uses
[`initial-site-local-difficulty-profile.height-base-blocks`, `initial-site-local-difficulty-profile.height-minimum-multiplier`, `initial-site-local-difficulty-profile.height-linear-growth`, and `initial-site-local-difficulty-profile.height-maximum-level`](../schema/world.yaml)
in `height-base-blocks × (height-minimum-multiplier + height-linear-growth × (clamp(level, 1, height-maximum-level) − 1) / (height-maximum-level − 1))`
blocks: 2.125 at level 1, reaching 3.4 at level 10 and staying there. These are encounter-local
rules, not global ordinary-creature or player changes. Specials use the [boss profile below](#boss-specials-and-breakable-rubble),
not unmodified player spell damage.

## Ordinary kill loot

The corresponding required source inputs are [`generator-design-loot and its coins, rarity-weights, gear-kinds, consumable-pool and ground children`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

The structural roll facets are [`ordinary-site-kill-loot-profile`](../schema/world.yaml), covered
by `test_gear_loot_profiles` in `test_ontology_schema_world_rewards.py`.
Each ordinary kill independently rolls for coins, gear, consumables, and each defined species
ingredient using [`ordinary-site-kill-loot-profile.coin-probability`, `ordinary-site-kill-loot-profile.gear-probability`, `ordinary-site-kill-loot-profile.consumable-probability`, and
`ordinary-site-kill-loot-profile.each-species-ingredient-probability`](../schema/world.yaml). Copper is [`ordinary-site-kill-loot-profile.copper-base`](../schema/world.yaml)
plus [`ordinary-site-kill-loot-profile.copper-per-enemy-level`](../schema/world.yaml) times enemy level. A successful gear or
consumable roll yields the quantity in [`ordinary-site-kill-loot-profile.gear-count-per-success` or
`ordinary-site-kill-loot-profile.consumable-count-per-success`](../schema/world.yaml). Gear and consumable item power first converts
enemy level under [item power](3_Classes.md#item), then applies an equal-weight choice among
[`ordinary-site-kill-loot-profile.power-offset-low`, `ordinary-site-kill-loot-profile.power-offset-zero`, and `ordinary-site-kill-loot-profile.power-offset-high`](../schema/world.yaml), with
weights [`ordinary-site-kill-loot-profile.power-offset-low-relative-weight`, `ordinary-site-kill-loot-profile.power-offset-zero-relative-weight`, and
`ordinary-site-kill-loot-profile.power-offset-high-relative-weight`](../schema/world.yaml), and clamps to
[`ordinary-site-kill-loot-profile.minimum-item-power` and `ordinary-site-kill-loot-profile.maximum-item-power`](../schema/world.yaml). Coin income and kill XP still use enemy level.
Reuse ordinary rarity weights, gear-kind and consumable pools in `generators.json#design.loot`, shared ground
pickup and kill XP under [loot-rule](3_Classes.md#loot-rule). No extra completion XP is selected.
Unloading or restarting cannot reroll or re-award the same kill.

These ordinary rolls are additional to [guaranteed boss gear and spirits](#guaranteed-boss-gear-and-spirits)
and [mission packages](#shared-mission-packages-and-supplier-shops), not replacements for them.
[Personal source claims](3_Classes.md#save-data) are not blanket all-reward instancing.

## Boss specials and breakable rubble

The corresponding required source inputs are [`generator-design-initial-encounters-boss-specials, generator-design-initial-encounters-special-profile and its stomp/charge children, generator-design-initial-encounters-rubble`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

Each boss independently receives one permanent special according to [`boss-special-profile.assignment-probability`](../schema/world.yaml): ground stomp or charge. Fixed
parameter shapes are [`boss-special-profile`, `boss-stomp-profile`, and `boss-charge-profile`](../schema/world.yaml),
covered by `test_boss_special_profiles`; assignment scope is [`encounter-assignment`](../schema/world.yaml).
These declarations do not encode the selection procedure or execute behavior. Use its canonical
[current target](3_Classes.md#ai-behavior), including taunts and targeting ties.

- **Stomp:** [`boss-stomp-profile.start-max-horizontal-distance-blocks`, `boss-stomp-profile.start-max-feet-height-difference-blocks`, `boss-stomp-profile.warning-seconds`, `boss-stomp-profile.strike-radius-blocks`, `boss-stomp-profile.direct-damage-multiplier`, `boss-stomp-profile.victim-min-feet-above-floor-blocks`, and `boss-stomp-profile.victim-max-feet-above-floor-blocks`](../schema/world.yaml) define its start range, warning, strike radius, damage multiplier and victim-height interval.
  The start also requires clear sight; strike once, with victim feet inside the closed circle.
  Walls shield victims and jumping higher avoids impact.
- **Charge:** [`boss-charge-profile.start-exclusive-min-horizontal-distance-blocks`, `boss-charge-profile.start-max-horizontal-distance-blocks`, `boss-charge-profile.start-max-feet-height-difference-blocks`, `boss-special-profile.warning-seconds`, `boss-charge-profile.warning-lane-width-blocks`, `boss-charge-profile.speed-blocks-per-second`, `boss-charge-profile.swept-capsule-radius-blocks`, and `boss-charge-profile.direct-damage-multiplier`](../schema/world.yaml) define its start range, warning lane, speed, swept capsule and damage multiplier.
  The start also requires clear sight. Snapshot direction and endpoint, do not home, use the
  [approved boss height](#local-difficulty-and-boss-size), and stop at the first player struck,
  endpoint or unbreakable obstacle.

Both specials are physical even on mage-role bosses. Ordinary armor, dodge, combat-block,
reduction and absorption apply, with existing landed-hit 5% stun / 15% knockback rolls and
protections (`generators.json#design.defence.enemy-hit`). No friendly fire, DOT or extra
special-specific status. Specials have no NPC MP/stamina cost, crit or combo gain; this is
not a global enemy-combo ban.

First readiness, cooldown and its included recovery duration use `first-ready-after-engagement-seconds`,
`cooldown-after-completion-or-cancellation-seconds`, and `recovery-within-cooldown-seconds` in
[`boss-special-profile`, `boss-special-profile.first-ready-after-engagement-seconds`, `boss-special-profile.cooldown-after-completion-or-cancellation-seconds`, and `boss-special-profile.recovery-within-cooldown-seconds`](../schema/world.yaml); `test_boss_special_profiles` checks their fixed
values. Basic attacks stop during windup, execution and recovery. Death, invalid target, stun,
knockback or home-return cancels the special; sight loss during windup also cancels. Inactive
simulation pauses timers. Normal unload/restart cancels an ongoing special into cooldown/recovery
without replaying hits; already-waiting timers retain their remainder, with no offline advancement.

Each boss arena's count, cube edge, logical stone material and restoration delay are declared by
[`rubble-profile`, `rubble-profile.count-per-boss-arena`, `rubble-profile.cube-edge-blocks`, `rubble-profile.material`, and
`rubble-profile.restoration-delay-world-hours`](../schema/world.yaml), covered by `test_rubble_trap_profiles`. Rubble remains
breakable and outside required routes/safe lanes. Stomp shatters rubble in its impact area; charge
shatters intersecting rubble and continues. These are real breakable stone blocks, not cosmetic
particles, and yield no resource drops. Floors, supporting structure, access, exits, traps and
reward sources remain protected. Restoration is deferred while the site is occupied or would
overlap an actor. [World-clock/save rules](3_Classes.md#game-clock) apply.

## Spike traps and furnishing contents

The corresponding required source inputs are [`generator-design-initial-encounters-spikes and generator-design-initial-encounters-furnishings with vase/table children`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

The trap count, closed footprint, inclusive player-feet trigger interval, phase durations and
physical damage are declared by [`spike-trap-profile`, `spike-trap-profile.count-per-ruins-site`, `spike-trap-profile.footprint-width-blocks`,
`spike-trap-profile.footprint-depth-blocks`, `spike-trap-profile.trigger-min-feet-above-floor-blocks`, `spike-trap-profile.trigger-max-feet-above-floor-blocks`,
`spike-trap-profile.warning-seconds`, `spike-trap-profile.active-seconds`, `spike-trap-profile.cooldown-seconds`, and `spike-trap-profile.physical-damage`](../schema/world.yaml), covered by
`test_rubble_trap_profiles`; its effect/defence behavior remains below. Leaving does not cancel the warning. Each activation hits each player
at most once; standing there retriggers after cooldown. Jumping above the trigger interval or using
the safe lane avoids it. Only players take trap damage. Armor with its existing floor, then
reduction buffs and absorption apply. Dodge i-frames and combat-block do not protect; Resistance
does not apply.
No crit, stun, knockback, DOT, combat-resource gain or XP.

Per-room vase/table counts, initial health, armor, the vase copper coefficients and table-owned
per-renewal quantities/rarity/spread are declared by [`vase-profile.count-per-ruins-room`,
`vase-profile.full-health`, `furnishing-profile.armor`,
`furnishing-profile.minimum-room-guard-level`, `vase-profile`, `vase-profile.copper-base`,
`vase-profile.copper-per-room-guard-level`, `table-profile.count-per-ruins-room`,
`table-profile.full-health`, `table-profile.glass-flask-count-per-renewal`,
`table-profile.life-potion-count-per-renewal`, `table-profile.life-potion-rarity-index`, and
`table-profile.life-potion-power-spread`](../schema/world.yaml), covered by
`test_furnishing_profiles`. Direct player/boss
attacks damage props; DOT and traps do not. Prop hits grant no combo, MP, XP or enemy-hit status
rolls. Vase payout on destruction is `copper-base + copper-per-room-guard-level × L` using the named `vase-profile` facets above; table contents are issued as loose pickups.
Breaking a table never reissues its pair, whether the pickups remain, were taken or expired. `L`
is the saved room guard-pack level (`minimum-room-guard-level`), not the boss level.
Each of the three rooms rolls and saves one shared level at creation and at every actual safe
daily renewal, using the existing party-level and land-danger rules. Newly spawned or replacement
guards use that level and renewed potions convert it under [item power](3_Classes.md#item);
flasks and vase coin income are unchanged. Surviving guards keep their previous levels
and state. Partial renewal may therefore leave mixed-level guards. Unloading or restarting never
rerolls the saved room level.

Props and contents renew only during the ruins' [safe daily refresh](3_Classes.md#game-clock),
once per coalesced renewal. Reloads never refill or reroll them. Trap phase persists through
unload/restart and becomes idle on renewal. Furnishings contain no formulas, books or artifacts.

## Guaranteed boss gear and spirits

The corresponding required source inputs are [`generator-design-loot-gear-kinds, generator-design-initial-encounters-spirits`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

The fixed reward structures are [`guaranteed-boss-gear-profile` and `initial-spirit-profile`](../schema/world.yaml),
covered by `test_gear_loot_profiles` in `test_ontology_schema_world_rewards.py` and
`test_spirit_scope_fixed_profile` in `test_ontology_schema_world_progress.py`, respectively.
The two ruins bosses are non-mission bosses; the camp and four rescue bosses are mission
bosses. Each independently guarantees the quantity in [`guaranteed-boss-gear-profile.additional-gear-count-per-boss`](../schema/world.yaml)
in addition to normal kill-drop rolls. Rarity uses [`guaranteed-boss-gear-profile.rarity-tier-increment`](../schema/world.yaml)
above boss tier, capped at [`guaranteed-boss-gear-profile.maximum-rarity-index`](../schema/world.yaml). Item power is `power(L)`
for the defeated boss's current saved level `L`, with source level at least
[`guaranteed-boss-gear-profile.minimum-current-defeated-boss-level`](../schema/world.yaml), then bounded by
[`guaranteed-boss-gear-profile.minimum-item-power` and `guaranteed-boss-gear-profile.maximum-item-power`](../schema/world.yaml); spread is
[`guaranteed-boss-gear-profile.power-spread`](../schema/world.yaml), and upgrades are [`guaranteed-boss-gear-profile.upgrades`](../schema/world.yaml).
Reuse `generators.json#design.loot` gear-kind relative weights [`guaranteed-boss-gear-profile.weapon-relative-weight`,
`guaranteed-boss-gear-profile.chest-relative-weight`, `guaranteed-boss-gear-profile.gloves-relative-weight`, `guaranteed-boss-gear-profile.boots-relative-weight`, and
`guaranteed-boss-gear-profile.shoulders-relative-weight`](../schema/world.yaml), and the equal class weights
[`guaranteed-boss-gear-profile.warrior-class-relative-weight`, `guaranteed-boss-gear-profile.ranger-class-relative-weight`, `guaranteed-boss-gear-profile.mage-class-relative-weight`,
and `guaranteed-boss-gear-profile.rogue-class-relative-weight`](../schema/world.yaml), together with legal class materials/weapon
choices. New genuine deaths can reroll kind, class, subtype, modifier and name, not tier-based
rarity. Reloads cannot reroll the same death's rewards.

Each ruins boss drops the quantity in [`initial-spirit-profile.ruins-boss-count-per-death`](../schema/world.yaml) per death;
mission bosses drop the quantity in [`initial-spirit-profile.mission-boss-count-per-death`](../schema/world.yaml). On its
first logical generation, independently choose `spirit-fire`, `spirit-unholy`, `spirit-ice` or
`spirit-wind` according to [`initial-spirit-profile.spirit-fire-probability`, `initial-spirit-profile.spirit-unholy-probability`,
`initial-spirit-profile.spirit-ice-probability`, and `initial-spirit-profile.spirit-wind-probability`](../schema/world.yaml). Spirit item power is
`power(L)` for that boss's initial level `L`, with source level at least
[`initial-spirit-profile.minimum-initial-boss-level`](../schema/world.yaml) and spread [`initial-spirit-profile.power-spread`](../schema/world.yaml).
The same logical site boss retains its assigned spirit type and initial-level-derived power
across daily renewal; guaranteed gear instead converts the currently defeated boss's saved level.
All these rewards are shared ground drops, not per-player copies. No regional `+` gear or
travel weakening is added.

Quality means colour grade; item level means bounded [item power](3_Classes.md#item), not boss level. Spirit cubes are weapon-upgrade ingredients.
Initial implementation is limited to collecting and carrying them. Attaching spirits and their
numerical combat effects remain a separate feature, not globally removed or silently added. Existing [bench restrictions](3_Classes.md#customization-bench) and
[spirit-level restrictions](3_Classes.md#spirit-cube) remain; this selects no effect numbers.

## Shared mission packages and supplier shops

The corresponding required source inputs are [`generator-design-initial-encounters-mission-package, generator-design-settlement-shop`](../schema/design-items.yaml).
These input structures do not replace the logical occurrences or the procedures below.

The shared package and completion declarations are [`encounter-shared-package` and
`shared-mission-completion-profile`](../schema/world.yaml), covered by
`test_encounter_assignments_and_shared_reward_contract` in `test_ontology_schema_world_rewards.py`
and `test_progress_exclusion_profiles` in `test_ontology_schema_world_progress.py`, respectively.
The supplier ceiling is [`supplier-gear-stock-ceiling-profile`](../schema/world.yaml), also covered
by `test_progress_exclusion_profiles`.
Each camp/rescue completion produces one shared package per completion cycle, not one per
teammate. For the four site tiers (white, green, blue and purple), the package fields are [`encounter-shared-package.tier`, `encounter-shared-package.gear-count`,
`encounter-shared-package.gear-rarity-index`, `encounter-shared-package.gear-upgrades`,
`encounter-shared-package.copper`, `encounter-shared-package.life-potion-count`,
`encounter-shared-package.life-potion-rarity-index`, `encounter-shared-package.gem-count`,
`encounter-shared-package.gem`, `encounter-shared-package.source-level`, and
`encounter-shared-package.selected-class`](../schema/world.yaml).
Its four conditional class rules use `tier` to set `gear-rarity-index`, `copper`, `gem-count`,
and `gem`; `test_encounter_assignments_and_shared_reward_contract` checks the exact postconditions
for each tier and four positive tier cases. The fixed gear/potion counts, gear upgrades and common potion rarity are
[`encounter-shared-package.gear-count`, `encounter-shared-package.life-potion-count`,
`encounter-shared-package.life-potion-rarity-index`, and `encounter-shared-package.gear-upgrades`](../schema/world.yaml).
Gear and potion use `power(L)` for the saved mission-boss source level `L`, without spread; this
source level is not item power. The package is additional to ordinary kill and boss drops.

At the final designated death, snapshot the distinct classes of connected characters inside
the site, alive or awaiting respawn, and choose uniformly among those classes. If none are
inside, use the finishing attacker's class when known. If neither exists, defer gear-class
selection until the first later player enters the cleared site and use their class. Restrict
the [boss gear-generation procedure](#guaranteed-boss-gear-and-spirits) to that class. The one
shared piece fits one selected class, not everyone.

Deliver at camp centre/captive feet, using [`shared-mission-completion-profile.delivery-height-above-floor-blocks`](../schema/world.yaml), at completion: the camp's final
designated death or the rescue's [conversation/last-player-exit completion](3_Classes.md#gnome-supplier-s).
Persist issuance and undelivered payload, including any pending gear-class selection;
conversation or reload cannot duplicate rewards. Ordinary ground pickup/lifetime rules apply;
anyone, including later visitors, can pick up the shared loot. [`shared-mission-completion-profile.extra-completion-xp`](../schema/world.yaml) is zero; no additional currency is included in this initial package. Existing kill XP and other future currency contracts remain unchanged.

The land-local gear-stock ceiling uses [`supplier-gear-stock-ceiling-profile.initial-rarity-index`, `supplier-gear-stock-ceiling-profile.rarity-increment-per-completed-rescue`,
and `supplier-gear-stock-ceiling-profile.maximum-rarity-index`](../schema/world.yaml). All players in that saved world share that land's
progress. The raised ceiling applies at the next normal stock generation/restock, not an extra
rescue-triggered reroll; existing quantities and prices stay unchanged. This is the best quality
shops may offer, not a guarantee every item has that quality. Equipment keeps its strength
when travelling.

## Initial permanent-source scope

The [`initial-permanent-source-profile`](../schema/world.yaml) is covered by
`test_progress_exclusion_profiles` in `test_ontology_schema_world_progress.py`.
The six initial sites, including their alcove, bosses, props and packages, have source counts in
[`initial-permanent-source-profile.artifact-source-count` and `initial-permanent-source-profile.one-time-book-source-count`](../schema/world.yaml): both are zero.
A later dedicated source contract must place those;
this initial scope does not satisfy full-land permanent-content coverage or remove retained
game content. [Personal claims](3_Classes.md#save-data) and the existing
[artifact allocation](3_Classes.md#artifact) remain unchanged. Historical Steam book counts and
recipe quantities are not hybrid selections.

Full-land permanent sources and spirit customization are deferred outside the initial playable
slice, not implementation prerequisites for this bounded contract or permanently deleted content.

## Implementation boundary

These rules are documentation only. Runtime, instance/config, checker, generator and save
changes require separate authority; a passing current validator does not enforce this contract.
Implementation dependencies include canonical targeting/defence, site generation/occupancy,
world-clock/renewal, shared rewards/shops and saved logical identities. Deferred work is in the
[implementation backlog](../../docs/ROADMAP/todo_implement.md#initial-encounter-contracts).
