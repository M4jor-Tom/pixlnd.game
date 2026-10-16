# Resistance — magical-damage reduction

Status: accepted. Owner decision: 2026-10-16. Exact answer: **“3: Approved”**.

Resistance means **magical-damage reduction**, not general immunity to status effects.
Hazard-protection drinks retain their separate roles. This original choice selected the
meaning only; the later numerical selections are below.

Context: historical descriptions disagree between magic reduction and status immunity.
The hybrid choice separates surviving magical damage from preventing a status: a magical
hit hurts less, but Resistance alone does not prevent its stun. The tradeoff is no blanket
status protection from this stat; drinks are not replaced. General status immunity was not
chosen. Further owner reasoning was not supplied.

## Subtractive mitigation — item 1

Status: approved; item 1 recorded 2026-10-16. Numerical approval date not separately supplied.
The owner's later exact answer to the five Resistance combat proposals, with no amendments:

> 1: Approved; 2: Approved; 3: Approved; 4: Approved; 5: Approved; Handoff, wait for me to tell you to commit

Selected original proposal:

> Subtract **1 damage per Resistance point**, rather than treating it as a percentage.
>
> A 100-damage spell against 30 Resistance becomes **70 damage**, subject to item 2.
> This makes Resistance stronger against repeated small hits than against huge bursts.

This replaces the earlier absence of a numerical selection, not the accepted meaning or status
rules. Further owner reasoning was not supplied.

Dependencies: item 2 supplies the minimum (recorded below), item 3 the eligible attacks and
item 5 the position among other defences. Item 1 is not a complete damage pipeline; it selects
no different coefficient, percentage curve or additional status/hazard interaction.

## Ten-percent stage floor — item 2

Status: approved; item 2 recorded 2026-10-16. Exact answer: **“2: Approved”**, with no amendments.

Selected original proposal:

> Resistance alone cannot reduce a damaging hit below **10% of its original damage**,
> matching armor’s existing floor.
>
> A 100-damage spell against 200 Resistance still deals **10 damage**. Zero damage stays zero;
> fractional damage remains possible.

Combined with item 1, this selects `max(D - R, 0.1 × D)` for eligible incoming damage `D ≥ 0`
and Resistance `R ≥ 0`, with no minimum-one rounding. It is a Resistance-stage floor, not a
final HP-loss floor: later defences can reduce or absorb the remainder. Further owner reasoning
was not supplied.

Dependencies: eligible attacks (item 3), hit-derived DOT handling (item 4) and defence order
(item 5) are recorded below. Items 1–2 alone are not a complete mitigation pipeline.

## Attack classification — item 3

Status: approved; item 3 recorded 2026-10-16. Exact answer: **“3: Approved”**, with no amendments.

Selected original proposal:

> Classify the **attack**, not merely its attacker:
> - **Magical:** Mage weapon attacks, damaging Mage spells and enemy mage-role spells.
> - **Physical:** weapon blows, bites, arrows, thrown weapons and physical strike skills.
>
> Apply **one equipment defence**, not armor followed by Resistance. A mage’s fireball meets
> Resistance; an ordinary arrow meets armor.

Dependencies: items 1–2 define magical mitigation; existing physical armor rules remain.
Item 4 below covers hit-derived damage-over-time and environmental scope; item 5 below governs
defence order. This selects no new attack content or live-data migration and does not extend
combo armor penetration to Resistance. Further owner reasoning was not supplied.

## Hit-derived damage over time — item 4

Status: approved; item 4 recorded 2026-10-16. Exact answer: **“4: Approved”**, with no amendments.

Selected original proposal:

> Damage-over-time calculated from a triggering hit inherits that hit’s Resistance reduction
> **once**. Do not subtract Resistance again on every tick.
>
> If a fire spell falls from 100 to 70 damage, burning worth 10% of that hit starts at **7 per
> tick**, not 10 followed by another Resistance subtraction. Independently sourced poison and
> environmental hazards gain no Resistance protection under this proposal. Status application
> and duration remain unchanged.

Dependencies: items 1–3 above determine the triggering hit's Resistance reduction; item 5 below
governs its defence stage. Preserve existing status identity, dodge exceptions, drinks and status
protection rules. The example does not approve a new tick coefficient, duration or cadence. No
additional DOT buff timing, stacking/slot model or hazard behavior is selected. Further owner
reasoning was not supplied.

## Defence order — item 5

Status: approved; item 5 recorded 2026-10-16. Exact answer: **“5: Approved”**, with no amendments.

Selected original proposal:

> Apply Resistance first, then existing block and damage-reduction multipliers, then absorption
> shields. The 10% floor applies only at the Resistance stage.
>
> Example: **100 → 70** through Resistance → **14** through blocking → **7** during Bulwark.
> Separately, a Mage’s 50-point absorption shield facing that resisted 70-damage hit leaves
> **20 HP damage**.

Dependencies: items 1–2 define the first stage; item 3 limits its coverage. Preserve existing
block eligibility/exhaustion, multiplier values, absorption-pool rules and status protections.
Examples select no new block/buff strengths or shield capacities; absorption may prevent HP loss
entirely. Further owner reasoning was not supplied.

Canonical: [stat](../domain/3_Classes.md#stat) and
[mitigation constraint](../domain/5_Constraints.md#constraint-catalog); separate
[status effects](../domain/3_Classes.md#status-effect) and
[consumables](../domain/3_Classes.md#consumable) remain unchanged.
Historical evidence and live JSON remain unchanged; runtime/checker work is unauthorized.
