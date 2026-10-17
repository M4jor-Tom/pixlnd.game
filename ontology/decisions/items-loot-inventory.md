# D18 — Items, loot and inventory

Per non-friendly kill:
- Coins: **60%**, amount **1 + 2·level**.
- One gear piece: **20%**; weights weapon **4**, chest/gloves/boots/shoulders **2** each.
  Roll class uniformly and use its material.
- One consumable: **15%**; species drop: **50%**.

Rarity weights are **60/25/10/4/1**; item level is creature level **±1**.
Ground items last approximately **one game week**, pickup radius **2**, coins automatic.
Only consumables, ingredients, coins, formulas and blocks stack, with [the uncapped inventory rule](../domain/3_Classes.md#inventory).
Start with a class weapon and **5 life potions**.

This slice's gear stats are **damage and armor only**, not a permanent exclusion of HP,
regeneration, tempo or crit. Their unresolved rolls are not settled here (the written HP term
`2 − 8r` can be negative).
[Fixed hybrid equipment HP](fixed-gear-hp.md) later settles HP only; the slice's coverage
and other stat rules are unchanged.

Configuration: [generators.json](../instances/generators.json) `design.loot`, `design.stack-cap`,
`design.starting-inventory`; constraints `c-loot-config`, `c-stack-rule`, `c-slot-accepts`.
[Canonical equipment rules](../domain/3_Classes.md#equipment-slot) still govern slot/hand acceptance;
[panel-time rules](../domain/3_Classes.md#hud-element) govern browsing without pausing the world.
