# D20 — Skill spending

Spend **one point per click**; a node requires `needs` points in the previous node of its
column, with **0 for roots**. **X** opens the screen. Class nodes use keys **1–4**, subject to
the [Assassin exception](assassin-camouflage.md).
Swimming points raise swim speed; [D6](numeric-design.md) governs per-point scaling.
Respec at the [class trainer](../domain/3_Classes.md#skill-tree-a).

[D21](class-abilities.md) replaces the universal placeholder strike, not the spending rules.
Pet/mount/climb/glider/boat runtimes are outside this slice; their approved gates remain in
[the canonical skill tree](../domain/3_Classes.md#skill-tree-a).

Configuration: [generators.json](../instances/generators.json) `design.abilities`,
[keybinds.json](../instances/keybinds.json) hybrid skills-window,
[ui.json](../instances/ui.json) screens.skills; `c-tree-shape`, `c-skill-spend`.
