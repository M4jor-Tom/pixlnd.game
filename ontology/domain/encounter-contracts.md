# Initial hybrid encounter contracts

The initial [mission families](3_Classes.md#mission-type) are an ordinary multi-boss ruins
dungeon, a repeatable daily ruined skeleton encampment and one-time world-shared supplier
rescues. Documentation is not runtime coverage or implementation permission.

## Placement and access

Each land has one ruins dungeon, one daily camp and four supplier sites. Site centres are
land-seeded, 192–215 blocks from the village square and at least 192 blocks apart. Their
saved-world locations stay fixed across
visits and daily renewal under [mission-type](3_Classes.md#mission-type).

Each site has a flat floor at `H = max(natural ground height, sea level + 4 blocks)` and an
8-block terrain apron. Access paths are 4 blocks wide, with steps no higher than one block.
Enemy homes and pursuit envelopes stay outside the village's existing protected area
([settlement](3_Classes.md#settlement), `generators.json#design.settlement.no-hostiles-within`).

Ocean lands receive dry islands and boardwalks. Where village generation otherwise fails,
provide a 64×64-block dry village hub containing the required settlement and valid village-square
spawn, not a substitute landing. Validate the village, all six sites and access routes together,
including finite-world bounds. Failure produces a generation diagnostic, never fewer suppliers
or partially populated encounters.

## Geometry and occupancy

All dimensions are in blocks. Ruins have three 24×24 rooms joined by 8×8 corridors, a 24×16
entrance court and 8×8 entrance passage, plus a 12×8 side reward alcove; overall horizontal
bounds are 36×112. Clear ceilings are 6 high and doors 4 wide × 5 high. The ruins contain two
spike traps, six vases and three tables. Corridors retain a 4-wide trap-free lane.

Ruins occupancy is the closed union of the playable rooms, corridors, entrance court, entrance
passage and alcove, each extending from `H − 1` to `H + 12`, not the empty space of the enclosing
rectangle. Daily camp battlefields are 64×64 and rescue battlefields 48×48, extending from
`H − 1` to `H + 16`; both have visible boundaries and two opposite 8-wide exits.
[Closed-volume occupancy](3_Classes.md#game-clock) still counts boundaries as inside and requires
all players outside every component, without extra grace.

## Populations, tiers and clear conditions

Enemies are skeletons (`creatures.json#skeleton`), including at the ruined skeleton encampment;
this does not add skeletons to unrelated ambient biome rosters.

| Site | Designated hostiles | Tier | Clear predicate |
|---|---|---|---|
| Ruins | Three packs of three, plus separate bosses in rooms two and three: 11 | Rooms green → blue → purple; bosses blue and purple | All 11 defeated |
| Daily camp | Two packs of three plus one boss: 7 | Green | All 7 defeated |
| Each supplier rescue | Two packs of three plus one boss: 7; also one friendly captive | Existing white/green/blue/purple site tier | All 7 defeated, then the existing rescue-completion rule |

Per land this is 46 hostiles including seven bosses, and four friendly captives. No
reinforcements are selected for these contracts. Each pack and singleton boss independently
rolls its basic role: 50% melee, 30% ranged, 20% mage. Existing basic attacks and status
protections remain unchanged. Positions and roles persist across unloading, restarting and
daily renewal; renewal does not reroll them.

Leaving while designated enemies survive is not completion. Rescue eligibility and the
conversation/automatic last-player-exit fallback follow [gnome-supplier](3_Classes.md#gnome-supplier-s):
the once-only shared completion/benefit precedes pending refresh. Ordinary-dungeon and daily-camp
enemies retain their daily refresh eligibility; completed one-time rescues stay cleared under
[game-clock](3_Classes.md#game-clock).

## Local difficulty and boss size

Reuse the existing NPC health and damage curves (`stats.json#alpha-character-formulas.npc-hp`,
`generators.json#design.combat.enemy-attack`) with local power-base `p = 2 + t`, where tier index
`t = 0, 1, 2, 3, 4` means white, green, blue, purple, yellow. Preserve the existing party-level
rules (`generators.json#design.enemy-level`); never rescale surviving enemies mid-fight.

At the same level and power, bosses have 4× ordinary health and 1.5× direct damage. Hit-derived
DOT retains its existing once-only inheritance, not a second boss multiplier. Boss height is
`1.7 × [1.25 + 0.75 × (clamp(level, 1, 10) − 1) / 9]` blocks: 2.125 at level 1, reaching 3.4 at
level 10 and staying there. These are encounter-local rules, not global ordinary-creature or
player changes. Specials use the [boss profile below](#boss-specials-and-breakable-rubble),
not unmodified player spell damage.

## Ordinary kill loot

Each ordinary kill in these sites independently rolls 60% coins worth `1 + 2 × enemy level`
copper, 20% one gear item, 15% one consumable, and 50% for each defined species ingredient.
Item level is `max(1, enemy level + offset)`, with equal chances for offsets −1, 0 and +1.
Reuse ordinary rarity weights, gear-kind and consumable pools in `generators.json#design.loot`, shared ground
pickup and kill XP under [loot-rule](3_Classes.md#loot-rule). No extra completion XP is selected.
Unloading or restarting cannot reroll or re-award the same kill.

These ordinary rolls are additional to [guaranteed boss gear and spirits](#guaranteed-boss-gear-and-spirits)
and [mission packages](#shared-mission-packages-and-supplier-shops), not replacements for them.
[Personal source claims](3_Classes.md#save-data) are not blanket all-reward instancing.

## Boss specials and breakable rubble

Each boss independently receives one permanent special: 50% ground stomp, 50% charge.
Use its canonical [current target](3_Classes.md#ai-behavior), including taunts and targeting ties.

- **Stomp:** start with a target within 4 horizontal blocks, feet-height difference ≤2 and
  clear sight. Warn for 1.2 simulation seconds with a 4-radius floor circle, then strike once
  for 1× boss damage. Victim feet must be inside the closed circle and 0–1 block above the
  floor. Walls shield victims; jumping higher avoids impact.
- **Charge:** start at target distance >4 and ≤10 blocks, feet-height difference ≤1 and clear
  sight. Warn for 1.2 simulation seconds along a 2-wide lane, snapshotting direction and
  endpoint. Move at 12 blocks/s without homing, using a swept capsule of radius 1 and the
  [approved boss height](#local-difficulty-and-boss-size). Deal 1.25× boss damage and stop at
  the first player struck, endpoint or unbreakable obstacle.

Both specials are physical even on mage-role bosses. Ordinary armor, dodge, combat-block,
reduction and absorption apply, with existing landed-hit 5% stun / 15% knockback rolls and
protections (`generators.json#design.defence.enemy-hit`). No friendly fire, DOT or extra
special-specific status. Specials have no NPC MP/stamina cost, crit or combo gain; this is
not a global enemy-combo ban.

First readiness is 3 simulation seconds after engagement. Completion or cancellation starts
a 10-second cooldown, whose first 0.8 seconds are recovery. Basic attacks stop during windup,
execution and recovery. Death, invalid target, stun, knockback or home-return cancels the
special; sight loss during windup also cancels. Inactive simulation pauses timers. Normal
unload/restart cancels an ongoing special into cooldown/recovery without replaying hits;
already-waiting timers retain their remainder, with no offline advancement.

Each boss arena has eight breakable one-block stone rubble voxels outside required routes
and safe lanes. Stomp shatters rubble in its impact area; charge shatters intersecting rubble
and continues. These are real breakable stone blocks, not cosmetic particles, and yield no
resource drops. Floors, supporting structure, access, exits, traps and reward sources remain
protected. Rubble returns after 72 world-clock hours, deferred while the site is occupied or
restoration would overlap an actor. [World-clock/save rules](3_Classes.md#game-clock) apply.

## Spike traps and furnishing contents

Each of the two traps covers a closed 2×2 footprint. Only player feet inside and 0–1 block
above its floor trigger it. Warn visibly and audibly for 0.8 simulation seconds, remain active
for 0.25 seconds, then cool down for 2 seconds. Leaving does not cancel the warning. Each
activation hits each player at most once; standing there retriggers after cooldown. Jumping
above one block or using the 4-wide safe lane avoids it. Only players take trap damage.

Each hit deals 30 physical damage: armor with its existing floor, then reduction buffs and
absorption. Dodge i-frames and combat-block do not protect; Resistance does not apply.
No crit, stun, knockback, DOT, combat-resource gain or XP.

Each room has two vases and one table. Vases have 10 HP and tables 20 HP, both with zero armor.
Direct player/boss attacks damage them; DOT and traps do not. Prop hits grant no combo, MP,
XP or enemy-hit status rolls. Each vase releases `1 + 2L` copper on destruction. Each table
owns one glass flask and one common life potion at level `L` per renewal, issued as loose
pickups. Breaking the table never reissues that pair, whether its pickups remain, were taken
or expired. `L` is the saved room guard-pack level, minimum 1, not the boss level.

Props and contents renew only during the ruins' [safe daily refresh](3_Classes.md#game-clock),
once per coalesced renewal. Reloads never refill or reroll them. Trap phase persists through
unload/restart and becomes idle on renewal. Furnishings contain no formulas, books or artifacts.

## Guaranteed boss gear and spirits

The two ruins bosses are non-mission bosses; the camp and four rescue bosses are mission
bosses. All seven independently guarantee one gear item in addition to normal kill-drop rolls.
Its rarity is one above boss tier, capped at legendary; its level is the defeated boss's saved
level, minimum 1, and upgrade count is zero. Reuse `generators.json#design.loot` gear-kind
weights 4:2:2:2:2 for weapon/chest/gloves/boots/shoulders, four classes equally likely, and
legal class materials/weapon choices. New genuine deaths can reroll kind, class, subtype,
modifier and name, not tier-based rarity. Reloads cannot reroll the same death's rewards.

Each ruins boss also drops one spirit cube per death. On its first logical generation,
independently choose `spirit-fire`, `spirit-unholy`, `spirit-ice` or `spirit-wind` with 25%
probability each. Spirit level equals that boss's initial level. The same logical site boss
retains its assigned spirit type and level across daily renewal; guaranteed gear instead
follows the currently defeated boss's saved level. Mission bosses give zero spirits.
All these rewards are shared ground drops, not per-player copies. No regional `+` gear or
travel weakening is added.

Quality means colour grade; level means item level. Spirit cubes are weapon-upgrade ingredients.
Initial implementation is limited to collecting and carrying them. Attaching spirits and their
numerical combat effects remain a separate feature, not globally removed or silently added. Existing [bench restrictions](3_Classes.md#customization-bench) and
[spirit-level restrictions](3_Classes.md#spirit-cube) remain; this selects no effect numbers.

## Shared mission packages and supplier shops

Each camp/rescue completion produces one shared package per completion cycle, not one per
teammate. For site tier `t = 0..3` (white/green/blue/purple), it contains one gear item of rarity
`t + 1`, `20 × (t + 1)` copper, one common life potion and `t + 1` matching-grade gems
(emerald/sapphire/ruby/diamond respectively). Gear and potion use the saved mission-boss level,
minimum 1; gear has zero upgrades. This package is additional to ordinary kill and boss drops.

At the final designated death, snapshot the distinct classes of connected characters inside
the site, alive or awaiting respawn, and choose uniformly among those classes. If none are
inside, use the finishing attacker's class when known. If neither exists, defer gear-class
selection until the first later player enters the cleared site and use their class. Restrict
the [boss gear-generation procedure](#guaranteed-boss-gear-and-spirits) to that class. The one
shared piece fits one selected class, not everyone.

Deliver at camp centre/captive feet, 0.5 block above the floor, at completion: the camp's final
designated death or the rescue's [conversation/last-player-exit completion](3_Classes.md#gnome-supplier-s).
Persist issuance and undelivered payload, including any pending gear-class selection;
conversation or reload cannot duplicate rewards. Ordinary ground pickup/lifetime rules apply;
anyone, including later visitors, can pick up the shared loot. No extra completion XP or
additional currency is included in this initial package; existing kill XP and other future
currency contracts remain unchanged.

The land-local gear-stock ceiling starts common, rises one grade per completed supplier
rescue, and reaches legendary after four. All players in that saved world share that land's
progress. The raised ceiling applies at the next normal stock generation/restock, not an extra
rescue-triggered reroll; existing quantities and prices stay unchanged. This is the best quality
shops may offer, not a guarantee every item has that quality. Equipment keeps its strength
when travelling.

## Initial permanent-source scope

The six initial sites, including their alcove, bosses, props and packages, contain zero artifact
sources and zero one-time book sources. A later dedicated source contract must place those;
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
[implementation backlog](../../docs/ROADMAP/todo_implement.md#initial-encounter-contracts-documentation-only).
