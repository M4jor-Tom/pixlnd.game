# D12 — World generation numbers

Zones are **64² blocks**, lands **256² zones**; **1 block = 1 m**, sea level **96**.
Use an fBm heightfield, climate rules and land-name syllables from
[generators.json](../instances/generators.json) `design.terrain`, `design.climate`, `design.names`.
Per-landscape relief, base and palette come from [landscapes.json](../instances/landscapes.json) `<id>.gen`.

[Own-design region boundary](land-region-generation.md) and [finite world](finite-world.md) apply.
