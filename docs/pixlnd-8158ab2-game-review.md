# Game review — correction status and unresolved findings

Updated **2026-10-27** from five Sol-6.1 investigations, plan synthesis and independent review.
Runtime probes used `33e262b9e16e033ea5830db3906d7fb1a316759f`; source was rechecked at
`3164c08189ff78b4612a1751e07637b7befe09da`. Gameplay, ontology and engine configuration are
unchanged between those pins. Before correction work, subsequent changes only ignored local plans
and adjusted quality-gate timeouts.

**F6/F7/F9 are deferred in the [implementation backlog](ROADMAP/todo_implement.md), including
selected policies and unresolved precision. F1/F5/F2/F3/F4/F8 passed selected-group and final
integrated review. The supplemental F3 fixture-only resolution also passed independent review;
no material correction or additional combined demonstration remains required.** These concern implemented behavior, not unfinished features.
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
| F1 | Fatal-landing terminal frame boundary — integrated review passed | Standard publication checks |
| F2 | Player stun admission across input/use paths — integrated review passed | Standard publication checks |
| F3 | Creature AI motion versus knockback — integrated review passed | Standard publication checks |
| F4 | Ordinary projectile cardinality/contact settlement — integrated review passed | Standard publication checks |
| F5 | Healing-over-time expiry integration — integrated review passed | Standard publication checks |
| F6 | Directional Cyclone — deferred | Resolve angular/contact precision, then canonical recording |
| F7 | Item-power producers and deterministic save checks — deferred | Compatibility support is none; correction remains unimplemented |
| F8 | Live character-power equip admission — integrated review passed | Standard publication checks |
| F9 | Apple healing — deferred | Healing strength selected; canonical/data correction pending |

## F1 — P2: fatal-landing terminal boundary (group and integration reviews passed)

- **Verified correction:** `_physics_process` now returns immediately after fatal fall damage,
  before the desktop combat/E/Q tail. `game/entities/test_landing_death.gd` first failed against
  the old behavior, then passed with real floor contact and separately verified mapped Q, basic
  attack and learned Smash edges. Nonlethal landing and lethal-DOT controls pass; death emits
  once, items/coins/XP survive and ordinary respawn refills equipped maximum HP.
  `game/combat/test_combat.gd` and `game/entities/test_panel_time.gd` also pass. These are bounded
  headless callback checks, not OS timing-frequency, native/HUD or independent acceptance evidence.
  Earlier touch dispatch, `abilities.after_move`, death listeners and respawn timing are unchanged.
- **Original cause:** `game/entities/player.gd::_physics_process` continues after `_fall_damage`
  synchronously sets `dead` and runs death cleanup. The desktop combat/interaction/Quick Item tail
  remains reachable, unlike the already-guarded lethal-DOT path.
- **Pre-fix reproduction:** HP 1, lethal landing and a verified mapped Q edge yield `dead=true`, HP 200 and
  one Potion consumed. The real callback was manually advanced: reachability, not OS timing frequency.
- **Together:** a post-fall `dead` return and regressions for Potion **and independent attack/skill
  admission**. An F2 item-use guard alone can hide the Potion symptom without fixing the frame tail.
  Preserve nonlethal actions, death listeners, inventory/XP/coins, respawn and touch actions committed
  before impact. Extend combat/panel-time preservation checks.
- **Authority:** [death](../ontology/domain/3_Classes.md#death),
  `generators.json#design.combat.death`; no ontology input/checker change needed.

## F2 — P1: player stun eligibility (group and integration reviews passed)

- **Verified correction:** vertical jump start/sustain and desktop/touch ascent now reject stun;
  shared Talk/Pick Up/Use endpoints reject dead or stunned players before mutation. Quick Item
  propagates Use's boolean result, and desktop E/Q dispatch also checks stun. Selected bag Use
  remains available while inventory is open when alive and unstunned; passive pickup is unchanged.
- **Focused evidence:** `game/entities/test_stun_input.gd` fails 42 admission assertions on the
  pre-fix source, then passes with verified mapped-key edges and normal player physics callbacks,
  synthetic native touch, real ground items, vendor/trainer/inn/captive services and inventory panels.
  Controls cover fresh actions after expiry, no buffered touch triggers, second-stack selected Use,
  first-stack Quick, passive currency, gravity/push and live DOT/HoT/buff/cooldown clocks.
  `test_panel_time.gd`, `test_android_controls.gd` and `test_defence.gd` pass preservation checks.
  Earlier input-fixture attempts are retained failures, not qualifying RED. Desktop synthetic touch
  is not hardware evidence; scoped integrated correction review passed.
- **Historical reproduction:** before correction, stunned desktop Jump rose about 0.454 blocks;
  desktop and native-touch ascent set vertical velocity 3.0. Touch grounded Jump already rejected
  stun. The original investigation only source-confirmed held sustain and interaction/selected-use
  omissions; the new regression above now exercises them.
- **Together:** relevant vertical input consumers, shared requested-action endpoints and rejection
  propagation through Quick Item; test keyboard, touch and selected bag use. Preserve live timers,
  gravity, knockback and committed effects. Do not globally cancel touches, freeze the player,
  block selected Use merely because inventory is open, or gate passive coin pickup in `pick_up`.
  Preserve `test_panel_time.gd`, `test_android_controls.gd` and defence behavior.
- **Authority:** `generators.json#design.status-effects._doc`,
  [controls](../ontology/domain/controls.md), [profiles](../ontology/domain/controller-profiles.md).
  Existing mappings/constants are sufficient; no new input policy or ontology checker is needed.

## F3 — P1: creature stun motion (group and integration reviews passed)

- **Verified correction:** `creature.gd` captures the actual base knockback x/z contribution
  separately from AI motion. Stun moves only that residual, retaining collision-adjusted velocity;
  ordinary non-stunned AI/special ownership retires it. Gravity and the base vertical impulse remain
  unchanged. Active specials cancel before new knockback insertion; no damping or persistent
  unstunned impulse system was added. `entity.gd` and `boss_special.gd` are unchanged.
- **Focused evidence:** `test_stun_motion.gd` runs normal physics for CHASE/WANDER/protected RETURN
  pure stun, both mixed-status orders, head-on walls/sliding and wall removal, expiry/resumption,
  later pure stun, simulation-radius freeze and death. Its final regression fails 21 behavioral
  assertions on pre-fix runtime, then passes. Return damage reduction, gravity and clocks persist.
  The extended `test_boss_special.gd` now reproduces the previously source-only cancellation hazard:
  knockback-before-stun loses its push in active stomp/charge warnings and charge execution (15
  assertions fail before correction). Both orders pass afterward, including walls, cooldown/recovery
  and actual post-cancellation physics. Creature-AI contract and creature-role preservation pass.
  Scoped re-review corrected inherited test-fixture push: an assertion-only check first exposed it,
  then clearing the residual in the test's reset helper passed exact single-impulse checks. Those
  amended assertions are not attributed to the earlier 15-failure gameplay RED.
- **Historical evidence and limits:** the original chasing-wolf probe drifted about 3.25 blocks in
  0.5 seconds; boss cancellation was source-only at that time, not a historical runtime reproduction.
  Initial fixture/parse attempts and a late wall-contact sampling mistake are retained separately,
  not qualifying acceptance evidence. Tests observe contact while sliding, then verify the blocked
  component stays consumed after wall removal. Integrated correction review passed; these fixtures
  do not resolve the parked translated-coordinate collision issue.
- **Supplemental native discrepancy resolved and independently reviewed:** the visual fixture spawned
  the wolf at the disabled player's old physics pose immediately after teleporting that player to
  z=6. Public callback/contact logs show recovery onto the player, then z=360 platform velocity
  carrying the wolf to z=6. Pure-stun horizontal intent remained zero; sliding off the player's
  capsule displaced it, and that same player consumed the subsequent genuine knockback. One added
  `await frames(2)` after the teleport, before spawning, removes all three failures without runtime,
  geometry or physics-default changes. The exact one-line counterfactual and original failures are
  preserved. Native verification records 29 pure-stun callbacks with unchanged x/z, seven push
  callbacks moving x=0.65 to -0.283537, then expiry and resumed +X chase. Before/during/after captures
  were inspected (the recovery view is explicitly reframed); both `test_stun_motion.gd` and
  `test_boss_special.gd` pass headless and windowed. This explains the fixture failure, not the
  separately parked translated-coordinate collision issue. Evidence is under
  `continuations/f3-resolution-20261027/` beside the integration store below.
- **Authority:** existing stun/knockback separation and
  [boss cancellation](../ontology/domain/encounter-contracts.md#boss-specials-and-breakable-rubble).

## F4 — P2: ordinary projectile contact (group and integration reviews passed)

- **Verified correction:** ordinary shots request one eligible target from both shooter adapters,
  capped before damage/crit/status effects without changing their existing candidate order. Contact
  is captured before synchronous death/removal and retires the shot independently of combat rewards.
  Other callers retain unlimited selection; damage, defence and whole-volley settlement are unchanged.
- **Focused evidence:** extended `test_projectiles.gd` fails 30 pre-fix assertions, including Bow
  hits=2/total damage=80, then passes Bow/Crossbow/Bracelet and each Shuriken contact, guaranteed
  crit/status, armor/Resistance/return reduction, lethal status rejection and in-flight unequip.
  Splash volleys, Fire Missiles/Bubbles, outbound/returning Boomerang, beam/cursor/melee and ability
  AoE controls pass. `test_creature_roles.gd` fails eight pre-fix assertions then passes two-player
  ordinary shots, blocked/dodged/lethal first contacts, guaranteed effects and multi-player splash.
  `test_encounter_contents.gd` fails four pre-fix assertions then passes nonlethal/lethal overlapping
  prop sphere contacts before a solid ray: no spill, combat hit, combo/MP reward or XP.
  The existing Resistance check also passes. Initial Boomerang crossing/tick fixture attempts and
  a Nix cache-contention notice are retained separately, not qualifying RED evidence; corrected
  controls pass on unchanged pre-fix runtime. Selected-group and integrated correction reviews passed;
  the visual qualifications below remain.
- **Original cause:** the ordinary branch of `game/combat/projectile.gd::_physics_process` invokes the same
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

## F5 — P2: healing-over-time expiry (group and integration reviews passed)

- **Verified correction:** `game/combat/abilities.gd::tick` integrates each entry over only
  `min(dt, remaining_lifetime)`, retaining the HP cap and independent expiry. Extended
  `game/combat/test_abilities.gd` first failed on crossing/large updates and staggered lifetimes,
  then passed for real Heroic Shout and Bubbles uses, exact expiry, post-expiry ticks, full-duration
  HP cap, reset and actual death clearing. Bubbles shots are retired explicitly to isolate its
  once-on-use side heal; healing remains combo-neutral. `test_class_combos.gd` and
  `test_unarmed.gd` pass unchanged. Channel/cast scheduling is untouched; selected-group independent
  and integrated correction reviews passed.
- **Original cause:** the runner applied `per-s * dt` before expiring each HoT entry.
- **Pre-fix investigation:** Heroic Shout heals 140.4375 over 10s, but 141.841875 over 9.9+0.2s;
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
- **Deferred correction:** the [selected directional-spin requirement](ROADMAP/todo_implement.md#game-review-f6)
  supersedes a cadence-only repair. Resolve angular/contact precision and land the canonical rule
  before implementation. Retain active-time/fuel clipping, safe zero-drain handling, synchronous
  reset/death interruption, loop-progress validation and regressions; preserve committed weapon and
  whole-channel miss/combo behavior. The old 0.25s radial tick does not select a revolution period.
  Do not merely replace `if` with `while` or import DOT's distinct final-tick rule.

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
- **Deferred deployment:** [compatibility support is none](worlds_retrocompatibility_state.md).
  Changed replay may reject old receipts/stock, even when delivered; saved integers do not reliably
  identify old source provenance. No implicit migration, wipe, reroll or receipt deletion. The
  [producer/checker correction](ROADMAP/todo_implement.md#game-review-f7) remains unimplemented;
  recipe/formula production and learning retain their separate deferrals.

## F8 — live equip power admission (group and integration reviews passed)

- **Verified correction:** shared pre-mutation admission now compares item power with the existing
  character-power function through a required live-level provider. Every constructor caller was
  adapted; `class_allowed`, producers and save restoration remain structural/unchanged.
  `test_equipment.gd` failed 21 pre-fix assertions, then passed +2 rejection at level1, +32/+33
  boundaries at level10, retained +40 eligibility through real progression, atomic bag/worn/HP/
  weapon/charge/coin/signal preservation and starter/hand/ring/trade/consumable/spirit controls.
  `test_save_data.gd` failed two new-admission assertions, then passed full disk roundtrip with
  worn +40 retention/refill at level10, later re-equip rejection and restored +32 admission.
  `test_gear_hp.gd` failed two above-power HP assertions then passed; its eligible +1 chest with
  ten upgrades preserves the original literal HP expectations. The off-hand fixture now uses
  +1/rarity1. Items, independent hands, equipment config and encounter rewards also pass.
  Earlier test-only parse and JSON numeric-type comparison failures are retained separately,
  not qualifying RED evidence. Selected-group and integrated correction reviews passed.
- **Original cause:** `game/items/inventory.gd::equip` / `_item_allowed` validate identity, slot, class/material
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

## F9 — Apple is consumed with zero healing; healing correction deferred

- **Cause:** `ontology/instances/consumables.json#apple` lacks `heal-mult`; `model.gd` defaults it
  to 0, `Items.heal` returns 0 and `player.gd::use_item` removes a unit. `use_quick` reports success.
- **Reproduced:** buy an Apple for 2 copper; selected use leaves HP 10 and removes it. Quick Item
  also consumes without healing. Existing Android selected-row testing even expects Apple depletion
  without checking its effect. The [consumable contract](../ontology/domain/3_Classes.md#consumable)
  supplies no exact Apple coefficient; the zero fallback is not an approved value.
- **Deferred remedy:** healing and its strength are selected in the
  [implementation backlog](ROADMAP/todo_implement.md#game-review-f9). Land canonical/data/raw+loaded
  checker agreement and selected/Quick/Android effect regressions when authorized. Preserve
  selected-versus-first-stack coverage; no unsupported-use rejection policy is selected.
- Preserve stock/loot membership, prices, stack targeting and existing instant-use approximation.
  Food sitting/channel behavior remains deferred. F9 is independent of F2's stun gate and F7/F8.

## Integration checkpoint — accepted corrections

The current checkout passed the full pre-push quality gate (65 Godot invocations, including all
three new regressions) and a separate isolated real-main boot. Ten affected regression scripts also
passed windowed on X11/Vulkan Forward+ with NVIDIA; successful logs are diagnostic-clean.
Five inspected real-main viewport/HUD captures cover mapped stun Jump/Q rejection, expiry/fresh
Potion use and native inventory power rejection followed by admission after progression.
Mapped keys and Android touch checks are synthetic, not physical-device acceptance.

The historical external F1/F3/F4/F5 visual fixture remains a **failed run**, preserved unchanged with
its earlier errors and timed-out observation. The newly authorized F3-only continuation reproduced
and explained all three motion failures, then verified a one-line fixture synchronization correction
(see F3 above). No production defect or engine repair was required. Its passing F3 evidence does not
retroactively clear that combined run: F1/F4/F5 frames remain partial visual observations. Final
integrated reassessment found their scoped real-callback regressions, passing windowed executions
and native observations sufficient alongside the independently verified F3 correction. Occluded
projectile targets and manually advanced healing limit what the images alone prove; they are not
remaining material defects or a requirement for another all-in-one demonstration. The six selected
corrections passed integrated review with no findings. Normal committed-checkout pre-push checks
and remote/CI verification remain publication gates.

Full commands, source hashes, accepted group reviews, failed attempts and captures are retained under
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/artifacts/game-review-fixes-astra-20261027/integration/`.
Original workflow `04aa5fd3-3383-4aa1-92ea-b2f65a25e0ec` still **FAILED at F1 review delivery**;
its recovered changes-requested review and later accepted continuation remain distinct evidence.
F6/F7/F9 remain deferred, not completed or waived. Collision diagnostics remain parked. Acceptance
of these corrections does not certify OS input timing, Android hardware coverage or performance.

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

In the original pre-correction investigation, thirteen final investigator logs were diagnostic-clean;
the equip and conditional Apple-rejection RED checks deliberately exited 1. Five existing scripts
(`test_class_combos`, `test_items`, `test_equipment`, `test_gear_hp`, `test_android_controls`)
passed despite the uncovered cases. The original review-document update reran **no gameplay tests**
and established no corrected-code GREEN. Subsequent F1/F5/F2/F3/F4/F8 RED/GREEN and preservation checks are
recorded in their sections above. The integration checkpoint above supersedes their earlier
full-suite/native test status; new Android hardware and performance acceptance remain unestablished.
Earlier source-only interaction/boss observations are historical where subsequent runtime checks now
supply evidence; saved-character/receipt probes are not full cold-world tests.

During the current authorized correction work: re-pin source, follow the repository authority/precision
gate, land necessary ontology/checker alignment first, then run focused RED/GREEN and preservation checks.
F1/F2 and F5/F6 are independent despite shared files; F4's shooter interfaces, F6's safe scheduling,
F7's producer/save units and F8's constructor callers must change coherently. Serialize shared-file
writers and obtain fresh review. Use the current [quality gate's calibrated deadlines](quality-checks.md#run-manually);
isolate saves and inspect logs as well as exit codes.
No C# migration, new dependencies or [parked native collision investigation](HANDOFF.md) is part of
these fixes or authorized by this review.
