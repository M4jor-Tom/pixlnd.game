# D22 — Settlements and spawn rule

Exactly **one village per land** is the final target, not a temporary limit before multiple
Steam settlements (settlements item 1). From the land seed, choose the first ring candidate
**≥4 blocks above sea**, flatten within **24 blocks**, blend over **8**.

Place **ten box buildings** on a **15-block ring**: inn, weapon/armor/item shops, one class
trainer and five houses. Colour by landscape settlement-style. One NPC per service building
stands at its door; interact with **E within 3 blocks**.

Vendors' slice stock is **8 items**, rolled from `(seed, village, shop)` at the land's creature-level
band around player level; rarity **≤rare until gnomes exist**. Use [D6 prices](numeric-design.md);
worn gear is unsellable. The item shop uses the loot consumable pool. The trainer refunds every
spent point for **5 × level copper**. Inn services follow [free recovery versus paid sleep](inn-services.md).

Initial spawn is the village square in land **(0,0)**. Wild groups skip within **40 blocks**
of the square. Districts, procedural rooms/roofs, villagers/schedules, spec change, sewers/dens
and flight master are outside this slice, not permanent bans. Initial once-rolled stock does not
supersede [daily resets](../domain/3_Classes.md#game-clock) or
[world-shared supplier improvements](../domain/3_Classes.md#save-data).

Configuration: [generators.json](../instances/generators.json) `design.settlement`,
[ui.json](../instances/ui.json) screens.npc-service; `c-settlement-config`.
