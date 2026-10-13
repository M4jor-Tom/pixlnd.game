# D13 — Player movement, camera and keys

Walk **6 blocks/s**, sprint **×1.8**, swim **×0.5**; tap/hold jump **1.5/3 blocks**,
gravity **32**, automatic step-up **1 block**. Hitboxes follow size class; stamina is **100**.
Orbit camera range is **0–12 blocks**, with **0 = first person**.

Use [generators.json](../instances/generators.json) `design.movement` / `design.camera`
and the hybrid column of [keybinds.json](../instances/keybinds.json).
Hitbox dimensions are specified choices, not open numeric gaps.
