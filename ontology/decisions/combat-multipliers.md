# D15 — Combat multipliers

Attack = **curve × k × 10**; NPC damage = **base-hp × 12 × 2^(power-base/4)**.
Use subtractive armor with a **10% damage floor**, combo **+2% per hit**, swing **0.5 s**.
Respawn at the spawn point, including [D22](settlements.md)'s initial village and inn relocation.

Configuration: [generators.json](../instances/generators.json) `design.combat` and
[classes.json](../instances/classes.json) `hp-mult`; [canonical stats](../domain/3_Classes.md#stat).
[Whole-attack combo rules](weapon-movesets.md) and the
[canonical channel/taunt boundaries](../domain/3_Classes.md#combo-system) apply.
