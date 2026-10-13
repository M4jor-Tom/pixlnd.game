# Artifacts item 1 — Per-stat contributors

Count contributors separately for each traversal stat. Acquisition order is irrelevant:
contributors to the same stat share its current contribution equally, never preserving earlier,
larger grants. Collecting a different traversal kind does not reduce this stat's rate.

This introduces no item-count reduction system for ordinary gear; existing level/rarity curves
and power gates remain. [Additive shares](artifact-additive-shares.md) use the final
[logarithmic total](artifact-total-curve.md), not earlier exponential proposals.
