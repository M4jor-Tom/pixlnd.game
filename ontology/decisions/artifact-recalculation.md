# Artifacts item 3 — Recalculate from current ordinary stats

Compute current artifact-free level, equipment, skill and buff inputs first, then multiply
the affected stat by **1+B(x)**. Recalculate as ordinary inputs change; never snapshot at pickup.
This adds no stat target or unrelated effect. [B(x)](artifact-total-curve.md) is the total bonus.
