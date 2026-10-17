# D26 — Creature ranged and mage roles

Parse `combat-role` from [creatures.json](../instances/creatures.json) `role` text, taking the
first of **any-class / ranged / mage / melee** found. Roles include melee, ranged, mage,
any-class and none; absent/no keyword leaves it unset, resolved at spawn to
`design.creature-roles.default` (**melee**). Roll any-class **per spawned group** from
weighted `design.creature-roles.any-class`.

Melee retains its reach attack. Ranged/mage chase to `range`, back off below `keep-away`,
require line of sight, wind up `windup-s`, fire a `shot` (speed/gravity/radius/life-s/splash),
then wait `cooldown-s`. Damage = **creature damage × damage-mult**, through normal dodge,
block and i-frames. A landed shot rolls its `applies` statuses and normal
[D23 enemy-hit stun/knockback](../domain/3_Classes.md#status-effect). **Poison is never avoided by dodge**;
[canonical poison delivery](../domain/3_Classes.md#status-effect) preserves burning/direct-hit behavior.

Play `sfx` from the shooter and tint by `color`; `species` may override keys per creature ID
(Spitter: poison/blue; Snout Beetle: slower/harder). **Creature shots never damage other creatures.**
The [Snout Beetle growing-shot bug](snout-beetle-shot-growth-prohibition.md) remains forbidden.

Aggro table/group aggro, enemy combos/potions, Wizard laser/Witch ray as beams, any-class humanoid
class/equipment/appearance, Snout Beetle dodge and pathfinding are outside this slice, not final
bans; approved [AI rules](../domain/3_Classes.md#ai-behavior) still govern the target.
Configuration: [generators.json](../instances/generators.json) `design.creature-roles`; `c-creature-roles`.
