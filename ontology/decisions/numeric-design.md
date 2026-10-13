# D6 — Numeric design bundle

- Skill effects: **5% per point, uncapped**; critical damage **×2**, with chance overflow.
- Use the Alpha item curve only.
- Buy price = **base × level × rarity**; sell for **25%**. Stacks have no cap.
- Enemy HP uses the cuwo formula × primary family multiplier; [D14](open-world-spawns.md)
  supplies the calibration and [unassigned families](unassigned-creature-family.md) the fallback.
- Circle of Power gives **+10% attack and maximum HP**.
- Recipes cost **5 cubes × size class**.

Tunables: [generators.json](../instances/generators.json), `design`.
The [artifact logarithm](artifact-total-curve.md) and [floor removal](artifact-no-floor.md)
supersede only D6's artifact accumulation/decay/floor, not this bundle or
[D11's artifact count](hybrid-gaps.md). Existing item curves and power gates still apply.
