# D14 — Open-world spawns

Spawn **0–2 groups per zone** from its landscape roster, using [creatures.json](../instances/creatures.json)
group sizes. Variable hostility `V` is **50/50**.

NPC HP = **base-hp × 200 × 2^(power-base/4)**, with power-base in **[−1.5, 1.25]**.
Wander/chase FSM values are in [generators.json](../instances/generators.json)
`design.spawns` / `design.enemy-hp`. Roll [F4](enemy-level-band.md)'s danger tier per land
from `design.enemy-level.tier-weights`.

[Dog-variant choices](skeleton-dog-rarity.md) amend dog selection without changing general group frequency.
