# Game review — current unresolved findings

Updated **2026-10-27** from five Sol-6.1 investigations, plan synthesis and independent review.
Runtime probes used `33e262b9e16e033ea5830db3906d7fb1a316759f`; source was rechecked at
`3164c08189ff78b4612a1751e07637b7befe09da`. Gameplay, ontology and engine configuration are
unchanged between those pins. Subsequent changes only ignore local plans and adjust quality-gate timeouts.

**Nine correction groups remain.** These concern implemented behavior, not unfinished features.
This review records evidence and proposed correction boundaries; it grants no implementation,
new design, migration or publication authority. The original `8158ab2` audit remains in Git history.

**Resolved and removed from active work:** creature collision/mesh sharing was fixed in `6730708`.
`game/entities/creature.gd::setup` duplicates both resources before sizing. New two-size,
factory/boss and saved-survivor rematerialization probes passed. Retain that boundary; do not add
redundant scene-local duplication. A focused checked-in ownership regression is optional hardening.
Rejected shop-toggle/village-distance leads are not correction tasks.

## Fix groups and prerequisites

The F labels match the local correction plan. Each group includes its regression and accurate
check/status documentation; “together” means one coherent landing, not all findings in one patch.

| Group | Fix | Additional prerequisite |
|---|---|---|
| F1 | Fatal-landing terminal frame boundary | None |
| F2 | Player stun admission across input/use paths | None |
| F3 | Creature AI motion versus knockback | None; characterize special-cancellation preservation |
| F4 | Ordinary projectile cardinality/contact settlement | None |
| F5 | Healing-over-time expiry integration | None |
| F6 | Cyclone scheduling, active-time clipping and progress validation | Select exact terminal/zero-fuel convention |
| F7 | Item-power producers and deterministic save checks | Select existing-save disposition |
| F8 | Live character-power equip admission | None |
| F9 | Apple healing or unsupported-use rejection | Select value/precision or rejection policy |

“None” means no additional design choice was identified, **not** permission to implement.
F1/F5 are small independent starts; F2/F3/F4/F8 need not wait for F6/F7/F9 decisions.

## F1 — P2: fatal landing still admits queued actions

- **Cause:** `game/entities/player.gd::_physics_process` continues after `_fall_damage`
  synchronously sets `dead` and runs death cleanup. The desktop combat/interaction/Quick Item tail
  remains reachable, unlike the already-guarded lethal-DOT path.
- **Reproduced:** HP 1, lethal landing and a verified mapped Q edge yield `dead=true`, HP 200 and
  one Potion consumed. The real callback was manually advanced: reachability, not OS timing frequency.
- **Together:** a post-fall `dead` return and regressions for Potion **and independent attack/skill
  admission**. An F2 item-use guard alone can hide the Potion symptom without fixing the frame tail.
  Preserve nonlethal actions, death listeners, inventory/XP/coins, respawn and touch actions committed
  before impact. Extend combat/panel-time preservation checks.
- **Authority:** [death](../ontology/domain/3_Classes.md#death),
  `generators.json#design.combat.death`; no ontology input/checker change needed.

## F2 — P1: player stun eligibility is incomplete

- **Cause:** `player.gd::_physics_process` gates horizontal/request input but misses desktop Jump,
  held Jump sustain and desktop/touch Swim Ascent. `talk_nearest`, `pick_up_nearest`, `use_item`
  and desktop E/Q dispatch lack shared alive/stun admission; inventory selected Use calls `use_item` directly.
- **Reproduced:** stunned desktop Jump rises about 0.454 blocks; desktop **and native-touch** ascent
  set vertical velocity 3.0. Touch grounded Jump is already rejected. Held sustain and stunned
  interaction/selected-use omissions are source-confirmed, not separately runtime-probed here.
- **Together:** relevant vertical input consumers, shared requested-action endpoints and rejection
  propagation through Quick Item; test keyboard, touch and selected bag use. Preserve live timers,
  gravity, knockback and committed effects. Do not globally cancel touches, freeze the player,
  block selected Use merely because inventory is open, or gate passive coin pickup in `pick_up`.
  Preserve `test_panel_time.gd`, `test_android_controls.gd` and defence behavior.
- **Authority:** `generators.json#design.status-effects._doc`,
  [controls](../ontology/domain/controls.md), [profiles](../ontology/domain/controller-profiles.md).
  Existing mappings/constants are sufficient; no new input policy or ontology checker is needed.

## F3 — P1: stunned creatures retain AI-requested velocity

- **Cause:** `game/entities/creature.gd::_physics_process` skips `_tick` while stunned but calls
  `move_and_slide` with old x/z from `_move`. `entity.gd::apply_status` inserts actual knockback
  into that same velocity; indiscriminate zeroing would erase a separate legitimate effect.
- **Reproduced:** a pure-stunned chasing wolf travels about 3.25 blocks in 0.5s at 6.5 blocks/s.
  A separate mixed-effect control confirms real knockback must continue moving the creature.
- **Together:** distinguish requested locomotion from external horizontal impulse, with pure-stun,
  both status-order, collision and expiry regressions. Preserve gravity, cooldowns, targeting,
  protected return and simulation-radius rules; do not invent damping or persistent unstunned impulses.
- **Coupled preservation risk, source-only:** `creature.gd::apply_status` calls base application
  before `boss_special.gd` cancellation can zero horizontal motion. Characterize active warning/charge
  plus knockback/stun before accepting cancellation-order changes. Extend `test_boss_special.gd`
  alongside creature-AI/role checks; do not claim this boss path was runtime-reproduced.
- **Authority:** existing stun/knockback separation and
  [boss cancellation](../ontology/domain/encounter-contracts.md#boss-specials-and-breakable-rubble).

## F4 — P2: ordinary projectiles hit multiple bodies

- **Cause:** the ordinary branch of `game/combat/projectile.gd::_physics_process` invokes the same
  area `_strike` used by splash/pierce. Both `player.gd::_strike` and `creature.gd::_strike` loop candidates.
- **Reproduced:** one ordinary Bow shot damages two adjacent wolves 40 HP each, including through
  actual stepped flight. Existing once-per-volley MP/combo settlement already works.
- **Together:** ordinary dispatch, compatible target-selection limits in **both** shooter adapters,
  and contact-versus-combat-hit settlement. Select one eligible body **before** damage/statuses;
  retain current ordering and damage/defence logic. A prop consumes contact without combat rewards;
  blocked/dodged actors retain existing counted-hit behavior. Neither spills to a second target.
- **Regression boundary:** overlapping actors/props, blocked/lethal first contact, both shooters,
  statuses and in-flight weapon commitment. Keep splash, pierce/return, melee, beam/cursor and
  ability AoE unlimited. Extend projectile, creature-role, encounter-content and Resistance checks.
- **Authority:** `generators.json#design.movesets._doc` first-body rule and
  [furnishing direct damage](../ontology/domain/encounter-contracts.md#spike-traps-and-furnishing-contents).
  No new ontology value/checker is required.

## F5 — P2: healing integrates past expiry

- **Cause:** `game/combat/abilities.gd::tick` applies `per-s * dt` before expiring each HoT entry.
- **Reproduced:** Heroic Shout heals 140.4375 over 10s, but 141.841875 over 9.9+0.2s;
  Bubbles heals 69.5625 over 5s, but 70.95375 over 4.9+0.2s. Both expire in each comparison.
- **Together:** integrate only `min(dt, remaining_lifetime)` and test both effects at exact/crossing
  expiry, large updates, staggered entries, HP cap and reset/death. Preserve percentages, cast timing,
  neutral combo and Bubbles' once-on-use healing. Extend ability checks; retain class-combo/unarmed checks.
- **Authority:** `generators.json#design.abilities` selected healing amounts/durations.
  No ontology change is needed. This fix is independent of F6 despite sharing the runner/test files.

## F6 — P2: Cyclone loses cadence and overruns active time

- **Cause:** `abilities.gd::tick` discards remainder, strikes at most once and deducts whole-update
  duration/stamina before ending. Initial `tick=0` means the first positive update strikes immediately.
- **Reproduced:** equal 1.5s yields 5/6/6/1 strikes for 15×0.1, 6×0.25, 90×1/60 and 1×1.5.
  A channel with 0.4s remaining drains 25 stamina over a 1s update instead of 10. Fuel-crossing partitions
  can add a late strike. These are arithmetic defects, not a measured rendering-performance problem.
- **Safety dependency:** `ontology/model.gd` currently accepts channel `tick-s=0` and `-0.25`
  (in-memory validator probes). A catch-up loop needs required finite `tick-s>0` and finite
  `drain-per-s>=0` validation, including missing/raw-malformed inputs, **before** runtime adoption.
- **Together:** remainder/catch-up, duration/fuel clipping, safe zero-drain handling, synchronous
  reset/death interruption, loop-progress validation and regressions. Preserve committed weapon,
  whole-channel miss/combo behavior and first-update phase; do not merely replace `if` with `while`.
  Update bounded [constraints](../ontology/domain/5_Constraints.md#constraint-catalog) first;
  selected cadence 0.25s, duration 5s and costs remain unchanged.
- **Decision gate:** specify event inclusion exactly at interval/lifetime/fuel boundaries and whether
  the first update strikes when the entry cost leaves zero stamina. Current quarter-step results and
  the observed zero-post-cost first strike inform a least-change proposal; they are not owner-selected
  universal semantics. Off-grid regressions already establish the unconditional defect. Do not import
  DOT's distinct final-tick rule or block F5 while resolving this precision.

## F7 — item-power production and save verification use source-level units

**Authority:** [hybrid item power](../ontology/domain/3_Classes.md#item) requires
`clamp(power(source_level) + offset, 1, 100)`, converting **before** power-point spread.
Use existing `Model.power_for_level`; preserve stat/heal/price equations, +1 starters, XP/coins,
quantities, RNG draws and source-level records. This is now runtime-probed, not only source-derived.

| Implemented producer | Correct source and coupled checker |
|---|---|
| `game/items/items.gd::roll_loot` | Defeated level → power → existing shared gear/consumable offset; coins retain source level. |
| `game/items/encounter_rewards.gd::kill_payload` | Guaranteed gear uses current boss level; spirits use initial boss level, separately converted. |
| `encounter_rewards.gd::package_payload` | Mission gear/Potion use saved boss level, without spread; pending class/source records stay source-valued. |
| `game/items/shop.gd::stock` | Gear converts the actual `gen.creature_level` result before the separate stock offset; consumables convert character level. Purchased copies are not reconverted. |
| `game/world/world.gd::stage_tables` | Convert room level for Potions; keep room/receipt levels and vase coins unchanged. `save_data.gd` reconstructs table Potions independently. |
| `game/world/save_data.gd` | Kill/mission/vendor expectations reuse producers; all must agree, including historical delivered receipts and remaining vendor subsets. |

- **Reproduced:** ordinary L10 outputs 9/10/11 instead of 31/32/33; boss gear 10/spirit 3 instead
  of 32/10; mission and vendor Potions 10 instead of 32; room 1981 Potion 1981 instead of 100.
  Targeted save validation accepts an old-unit delivered kill receipt but rejects its canonical-power
  counterpart. Constructor and item validation also accept power 101.
- **Constructor distinction:** `Items.generate` takes **already-powered** input. Bound it to 1…100;
  do not convert source level there or in generic `Item.stack`. That would double-convert fixed-power
  callers. Reject invalid serialized powered gear/consumables/spirits rather than silently clamping
  imports; do not clamp the upgraded stat curve's derived `power + 0.1*upgrades`.
- **Checker correction:** `generators.json` loot/settlement prose has obsolete unit descriptions.
  Existing `model.gd` numeric spread checks correctly require 1; no incorrect power equation was found
  there. Keep those numbers/schema, align prose, and add independent generated-output assertions.
- **Together:** all implemented producers, item bounds, deterministic save expectations, stale input
  descriptions and affected tests. Never deploy mixed units. Cover literal anchors/clamps, non-power
  RNG signatures, boss current/initial identity, purchased stock, pending/delivered rewards and cold
  roundtrip/original-file protection. Extend item/reward, settlement/content/supplier and save checks.
- **Deployment gate:** choose treatment of existing generated saves. Changed replay rejects old
  receipts/stock, even when already delivered; saved integers do not reliably identify old source
  provenance. No implicit migration, wipe, reroll or receipt deletion. Confirm current-only rejection
  is acceptable or separately authorize compatibility work. Recipe/formula production and learning
  remain [deferred](ROADMAP/todo_implement.md#items-34-slice-abaded3), not part of this correction.

## F8 — shared equip admission ignores character power

- **Cause:** `game/items/inventory.gd::equip` / `_item_allowed` validate identity, slot, class/material
  and hands without comparing item power to live character power; panel/touch routes share this method.
- **Reproduced:** real level 10/power 32 character equips a +40 sword, mutating bag/worn state and stats.
- **Together:** shared pre-mutation power check, live level injection (including progression/restore),
  every changed constructor caller and fixture/regression updates. Keep `class_allowed` structural:
  saves and class coloring also use it. Test rejection without notifications, HP/weapon/state changes,
  threshold acceptance and all existing class/hand restrictions with otherwise eligible items.
- **Fixture dependency:** `test_items.gd` standalone +5 equip needs eligible character power;
  `test_gear_hp.gd` has a +2-at-level-1 HP fixture; `test_independent_hands.gd` has +2-at-level-1
  shield/axe fixtures. Make these legitimately eligible, not bypassed. For the latter, +1/rarity 1
  preserves its hand-lifecycle purpose and dynamically derived stat expectations.
- **Authority/scope:** [equipment-only requirement](../ontology/domain/3_Classes.md#power-gate-a).
  Carry/trade, consumable use and carried spirits stay allowed. Preserve structurally legal existing
  worn gear on restore; no retroactive eviction/save migration. Unequip then re-equip is a **new**
  admission attempt. F8 consumes item power, never converts it again, and is independent of F7.

## F9 — Apple is consumed with zero healing; remedy unselected

- **Cause:** `ontology/instances/consumables.json#apple` lacks `heal-mult`; `model.gd` defaults it
  to 0, `Items.heal` returns 0 and `player.gd::use_item` removes a unit. `use_quick` reports success.
- **Reproduced:** buy an Apple for 2 copper; selected use leaves HP 10 and removes it. Quick Item
  also consumes without healing. Existing Android selected-row testing even expects Apple depletion
  without checking its effect. The [consumable contract](../ontology/domain/3_Classes.md#consumable)
  supplies no exact Apple coefficient; the zero fallback is not an approved value.
- **Decision gate — choose one, not both:**
  - **Healing:** approve exact hybrid coefficient/precision, then land canonical/data/raw+loaded
    checker agreement and selected/Quick/Android effect regressions. Integer selection may need no
    production runtime change; fractional selection cannot be silently truncated by the current loader.
  - **Rejection:** explicitly approve unsupported-use policy/scope, then land canonical exception,
    shared no-consume rejection/notice and truthful Quick return together. Update the conflicting Android
    fixture while retaining selected-versus-first-stack coverage. Do not silently broaden Apple-only
    approval to all zero-heal items; do not reject supported Potions merely because HP is full.
- Preserve stock/loot membership, prices, stack targeting and existing instant-use approximation.
  Food sitting/channel behavior remains deferred. F9 is independent of F2's stun gate and F7/F8.

## Evidence, continuation and limits

The seven-child Sol-6.1 workflow `0eac8375-2dba-49dc-9ec3-99f814847af5` completed five investigations,
plan synthesis and independent review. Reports with exact commands, source traces, raw log paths,
expected-RED cases and proposed regression details are in this machine-local directory:

```text
/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/0eac8375-2dba-49dc-9ec3-99f814847af5/
```

- `investigations/resource-ownership.md`: resolved ownership and control probes.
- `investigations/action-lifecycle.md`: F1–F3.
- `investigations/combat-boundaries.md`: F4–F6.
- `investigations/item-power-producers.md`: F7.
- `investigations/item-use-admission.md`: F8–F9.
- `review/grouped-fix-plan-review.md`: independent review; its missing off-hand fixture correction is included above.

The detailed local plan is `docs/superpowers/plans/2026-10-27-game-review-fixes.md`.
**That directory is Git-ignored**; this tracked review retains the correction groups/gates without
requiring it. Preserve external evidence before moving machines. Original audit history is not
fresh acceptance and need not be replayed just to recover an old defect count.

Thirteen final investigator logs were diagnostic-clean; the equip and conditional Apple-rejection
RED checks deliberately exited 1. Five existing scripts (`test_class_combos`, `test_items`,
`test_equipment`, `test_gear_hp`, `test_android_controls`) passed despite the uncovered cases.
This document update reran **no gameplay tests**. No corrected-code GREEN, full-suite, native visual,
new Android hardware or performance acceptance is claimed. Some interaction/boss preservation
paths above are explicitly source-only; saved-character/receipt probes are not full cold-world tests.

On a later authorized implementation: re-pin source, follow the repository authority/precision gate,
land necessary ontology/checker alignment first, then run focused RED/GREEN and preservation checks.
F1/F2 and F5/F6 are independent despite shared files; F4's shooter interfaces, F6's safe scheduling,
F7's producer/save units and F8's constructor callers must change coherently. Serialize shared-file
writers and obtain fresh review. Use the current [quality gate's calibrated deadlines](quality-checks.md#run-manually);
isolate saves and inspect logs as well as exit codes.
No C# migration, new dependencies or [parked native collision investigation](HANDOFF.md) is part of
these fixes or authorized by this review.
