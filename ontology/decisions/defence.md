# D23 — Dodge, block and stealth

- **Dodge:** M3 while moving, **25 stamina**, **4 blocks in 0.4 s**, ignore hits for **0.4 s**,
  no fall damage on that landing. Ninja elusiveness gives **25 MP**; Assassin
  way-of-the-shadows gives **0.5 stealth**. [Poison](creature-combat-roles.md) is not avoided by dodge.
- **Block:** hold M2 with a shield, any weapon as Guardian, or during Cyclone. Front-cone hits
  deal **×0.2** damage; spend **25 block-power per hit** from **100** (Guardian **200**),
  gain **8 MP per block**. Regenerate **20/s** when not blocking, **×2 during Cyclone**.
  [Canonical exhaustion](../domain/3_Classes.md#combat-block) governs each arriving hit.
- **Stealth:** Sneak fills **0.25/s**, Aim **0.3/s**, **×2 standing still**; Camouflage pins full.
  Decay **0.15/s**. Full gives **+20% attack**, **+50% crit**, **×2 MP per hit**, aggro range **×0.1**.
  A landed hit empties it unless pinned. [Threat rules](../domain/3_Classes.md#stealth) remain distinct
  from this range multiplier: full stealth is not a threat wipe or taunt cancellation.
- Creature hits roll **5% stun / 15% knockback** on the player; blocked or dodged hits roll neither.

Ninja crit window, counter-strike, hit-series and darkness/lamps are outside this slice, not
permanent exclusions. [D24](weapon-movesets.md) and [D25](combat-feedback.md) govern projectiles
and visual feedback; those are not still excluded by this slice's earlier limits.

Configuration: [generators.json](../instances/generators.json) `design.defence`,
`design.abilities.<id>.stealth-per-s` / `stealth-full`; `c-defence-config`.
