# Pending selected reconciliations — Resistance in combat

## Authority and application boundary

Owner's exact answer to the five numbered proposals:

> 1: Approved; 2: Approved; 3: Approved; 4: Approved; 5: Approved; Handoff, wait for me to tell you to commit

All five recommended options below are **Previously selected**, with no amendments.
Approval is established; canonical recording, consistency review, validation and the separately
scoped item commits are **pending for every item**. No gameplay, behavior-changing JSON,
loader/validator, tests, labels or source research is authorized by these approvals.
The subsequent owner instruction **“commit, push”** authorizes publication of this handoff
and queue only. The walkthrough remains stopped; canonical application awaits resumption.
This queue is not canonical ontology; remove entries only after their required recording,
checks, review and item commits are verified. Delete the file when no pending entry remains.

The settled meaning remains [magical-damage reduction, not status immunity](../ontology/decisions/resistance-meaning.md).
Existing statements that numerical rules are unapproved predate this answer: update them during
authorized canonical recording, rather than asking the owner to approve these same choices again.
Current entry points: [stat and status effects](../ontology/domain/3_Classes.md#stat),
[constraints](../ontology/domain/5_Constraints.md), [generators](../ontology/domain/6_Generators.md),
[combat deferrals](ROADMAP/todo_implement.md#combat-33-slices-457c947--d21--d23),
[ontology overview](../ontology/README.md) and [open-point status](../ontology/domain/7_Open_points_for_validation.md).

## 1. How much damage does each Resistance point prevent?

**Previously selected:** approve the recommended option. Exact answer: **“1: Approved”**.

Original proposal:

> Subtract **1 damage per Resistance point**, rather than treating it as a percentage.
>
> A 100-damage spell against 30 Resistance becomes **70 damage**, subject to item 2.
> This makes Resistance stronger against repeated small hits than against huge bursts.

Dependencies: item 2 supplies the minimum; item 3 selects eligible attacks; item 5 supplies
its position among other defences. Do not infer a different coefficient or percentage curve.

## 2. Can Resistance completely negate a spell?

**Previously selected:** approve the recommended option. Exact answer: **“2: Approved”**.

Original proposal:

> Resistance alone cannot reduce a damaging hit below **10% of its original damage**,
> matching armor’s existing floor.
>
> A 100-damage spell against 200 Resistance still deals **10 damage**. Zero damage stays zero;
> fractional damage remains possible.

Dependencies: combine with item 1 as `max(D - R, 0.1 × D)` for eligible non-negative incoming
damage `D` and Resistance `R`. Under item 5 this is a Resistance-stage floor, not a final HP-loss
floor: later defences can reduce or absorb the remainder. No minimum-one rounding rule is selected.

## 3. Which attacks use Resistance instead of armor?

**Previously selected:** approve the recommended option. Exact answer: **“3: Approved”**.

Original proposal:

> Classify the **attack**, not merely its attacker:
> - **Magical:** Mage weapon attacks, damaging Mage spells and enemy mage-role spells.
> - **Physical:** weapon blows, bites, arrows, thrown weapons and physical strike skills.
>
> Apply **one equipment defence**, not armor followed by Resistance. A mage’s fireball meets
> Resistance; an ordinary arrow meets armor.

Dependencies: items 1–2 define magical mitigation; existing physical armor rules remain.
Item 4 separately covers hit-derived damage-over-time and environmental scope. This selects no
new attack content or live-data migration, and does not extend combo armor penetration to Resistance.

## 4. What happens to burning and poison ticks?

**Previously selected:** approve the recommended option. Exact answer: **“4: Approved”**.

Original proposal:

> Damage-over-time calculated from a triggering hit inherits that hit’s Resistance reduction
> **once**. Do not subtract Resistance again on every tick.
>
> If a fire spell falls from 100 to 70 damage, burning worth 10% of that hit starts at **7 per
> tick**, not 10 followed by another Resistance subtraction. Independently sourced poison and
> environmental hazards gain no Resistance protection under this proposal. Status application
> and duration remain unchanged.

Dependencies: items 1–3 determine the triggering hit’s Resistance reduction; item 5 governs
its defence stage. Preserve existing status identity, dodge exceptions, drinks and status
protection rules. The example does not approve a new tick coefficient, duration or cadence.
No additional DOT buff timing, stacking/slot model or hazard behavior is selected.

## 5. How does Resistance combine with blocking and shields?

**Previously selected:** approve the recommended option. Exact answer: **“5: Approved”**.

Original proposal:

> Apply Resistance first, then existing block and damage-reduction multipliers, then absorption
> shields. The 10% floor applies only at the Resistance stage.
>
> Example: **100 → 70** through Resistance → **14** through blocking → **7** during Bulwark.
> Separately, a Mage’s 50-point absorption shield facing that resisted 70-damage hit leaves
> **20 HP damage**.

Dependencies: items 1–2 define the first stage; item 3 limits its coverage. Preserve existing
block eligibility/exhaustion, multiplier values, absorption-pool rules and status protections.
Examples select no new buff strengths or shield capacities; absorption may prevent HP loss entirely.
