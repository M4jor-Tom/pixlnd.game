# Fixed hybrid equipment HP

Status: accepted. Owner decision: 2026-10-16. Exact answer: **“4: Approved”**.

Use **fixed HP bonuses for otherwise-identical gear**, preserving the existing level/rarity/cube
curve, slot weights and material bonuses:

`HP bonus = curve(n, rarity) × 5 × slot × (2 + materialBonus)`

`n = level + 0.1 × upgrade_count`; rarity is not the normalized modifier roll. Only existing
HP-bearing weapons/chest/shoulders/gloves/boots are covered: chest slot **1**, others **0.5**;
material bonus **iron 1, cotton 0.75, linen 0.5, otherwise 0**.

Context: the written historical HP-roll expression is disputed; gear HP is not currently
applied, so this is not a live negative-HP bug. Removing its modifier-roll term gives equal
HP to otherwise-identical gear, sacrificing HP-roll variety rather than guessing a historical
correction. This is a **new hybrid simplification, not a recovered Alpha formula**. Further
owner reasoning was not supplied.

Only the hybrid HP-roll rule is replaced. Preserve [the Alpha base-curve choice](numeric-design.md),
all other stat rules and downstream character/artifact rules. No jewelry extension, random HP
allocation, clamp or extra constants are selected. Historical evidence is unchanged.

Canonical: [item HP](../domain/3_Classes.md#item),
[generator boundary and base curve](../domain/6_Generators.md#6-generators),
[stat-roll constraint](../domain/5_Constraints.md#5-constraints).
This later rule settles only HP left open by [the items slice](items-loot-inventory.md), not
its current damage/armor-only coverage. Live JSON correction, HP application and checker work
remain separately unauthorized.
