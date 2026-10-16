# Resistance — magical-damage reduction

Status: accepted. Owner decision: 2026-10-16. Exact answer: **“3: Approved”**.

Resistance means **magical-damage reduction**, not general immunity to status effects.
Hazard-protection drinks retain their separate roles. This selects the meaning, not an
unapproved numerical mitigation formula.

Context: historical descriptions disagree between magic reduction and status immunity.
The hybrid choice separates surviving magical damage from preventing a status: a magical
hit hurts less, but Resistance alone does not prevent its stun. The tradeoff is no blanket
status protection from this stat; drinks are not replaced. General status immunity was not
chosen. Further owner reasoning was not supplied.

No numerical mitigation formula, DOT/damage-type classification, stacking or new status/hazard
interaction is selected. A later implementation must obtain approval for numerical mitigation,
not invent a coefficient or borrow the armor formula.

Canonical: [stat](../domain/3_Classes.md#stat); separate
[status effects](../domain/3_Classes.md#status-effect) and
[consumables](../domain/3_Classes.md#consumable) remain unchanged.
Historical evidence and live JSON remain unchanged; runtime/checker work is unauthorized.
