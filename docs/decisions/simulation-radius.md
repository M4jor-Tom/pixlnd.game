# D16 — Bound creature simulation

Bound native AI and physics work by the configured creature simulation radius.
This avoids excessive creature physics and catch-up spirals.

Configuration: [generators.json](../../ontology/instances/generators.json) `design.spawns.ai.sim-radius`;
constraint `c-sim-radius`. This is not a replacement for the
[elapsed-gameplay-time threat rules](../../ontology/domain/3_Classes.md#ai-behavior).
