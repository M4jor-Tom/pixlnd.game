# D16 — Bound creature simulation

Only creatures within **80 blocks of the player** run AI and physics; the rest stand still.
This avoids excessive creature physics and catch-up spirals.

Configuration: [generators.json](../instances/generators.json) `design.spawns.ai.sim-radius`;
constraint `c-sim-radius`. This is not a replacement for the
[elapsed-gameplay-time threat rules (locator=ai-behavior)](../domain/3_Classes.dsl).
