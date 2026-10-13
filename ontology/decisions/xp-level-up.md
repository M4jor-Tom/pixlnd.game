# D19 — XP and level-up

XP per kill = **xp-to-next(creature level) × 0.2 × clamp(1 + 0.1·(creature level − player level), 0, 2)**.
About five even-level kills give a level; a creature **10+ levels below** gives zero XP.
Carry overflow and allow multiple level-ups per kill. Recompute maximum HP and refill HP;
bank **2 skill points per level** for [spending](skill-spending.md).

Configuration: [generators.json](../instances/generators.json) `design.progression`;
constraints `c-xp-config`, `c-level-up`; [level formulas](../domain/3_Classes.md#level-formula-a).
