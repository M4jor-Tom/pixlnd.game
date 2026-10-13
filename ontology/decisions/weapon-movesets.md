# D24 — Weapon movesets and projectiles

Every class weapon type has an M1/M2 runtime:
- Warrior one-handers spin around the player on M2; great weapons swing slowly and widely,
  with a knockdown finisher **every third hit**.
- Dagger M2 stuns and poisons (**5 × the hit over 5 s**); Fist M2 knocks down;
  Longsword M2 lunges **4 blocks** and stuns.
- Bow arrows arc (**30 blocks/s**, gravity **10**); M2 volleys **4** with **2-block splash**.
  Crossbow bolts fly flat and fast. Boomerangs pierce, tick every **0.25 s**, and return.
- Staff bursts where aim lands within **20 blocks**. Wand is a **25-block hitscan beam**;
  [its two-handed rule](wand-handedness.md) changes no attacks. Bracelet bolts have no gravity;
  M2 is a knockdown splash ball.
- Fire Missiles: **4** splash fireballs. Bubbles: **6** slow splash shots plus heal.
  Shuriken Attack throws **5** shuriken before the backflip.

A whole attack landing nothing resets combo; [canonical damaging-channel and taunt rules](../domain/3_Classes.md#combo-system)
define that boundary without changing ordinary successful gains, caps or inactivity expiry.

Animations/hit timing, boomerang steering, held-ray Wand M2, Bow dud shots and arrow pickup
are outside this slice, not final exclusions. [D26](creature-combat-roles.md) supplies creature projectiles.
Configuration: [generators.json](../instances/generators.json) `design.movesets`,
`design.abilities` projectile runtime / dash throw, `design.status-effects.poison`; `c-moveset-config`.
