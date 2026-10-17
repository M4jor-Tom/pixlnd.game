# D21 — Class ability runtimes

Replace the placeholder strike with designed dash, channel, burst,
buff and heal runtimes for the class-column/ultimate skills; [D20 spending rules](../domain/3_Classes.md#skill-tree-a)
remain unchanged. The 23-node design is subject to the later
[single Camouflage investment](../domain/3_Classes.md#skill-tree-a).

- **Smash:** leap 6 blocks to the nearest enemy within 8; strike ×2 with stun;
  100 stamina, 10 s cooldown.
- **Cyclone:** channel 5 s, ×0.5 every 0.25 s within radius 3; 25 stamina + 25/s;
  30 s cooldown.
- **Timed self-buffs:** War Frenzy, Bulwark, Mana Shield, Swiftness, Aim, Sneak,
  Camouflage, Ninjutsu, Shadow Shooter.
- **Dashes:** Rock Fist, Intercept, Teleport, Retreat, Shuriken.
- **Bursts:** Kick, Fire Explosion, Heroic Shout, Quicksand. Projectile ultimates use
  [D24](weapon-movesets.md), replacing their self-centred approximations.
- **Healing Stream:** cast 1.5 s, heal 50%.

Use source S costs where given. Selected cooldowns in seconds: Rock Fist 20,
Heroic Shout 30, Camouflage 40, Ninjutsu 60, Shadow Shooter 60, Quicksand 40,
Fire Missiles 40, Bubbles 30; otherwise designed 10/12/15/20/25, with Cyclone 30.
Exact per-node assignments: [generators.json](../instances/generators.json) `design.abilities`.

Non-mages gain **8 MP per landed basic hit**, mages **5 MP/s**. M2 special attack charges
at **50 MP/s** (Rogue instant), damage up to **×2.5**, stun chance up to **60%**.
Statuses: stun **2 s**, knockdown **1.5 s stun**, knockback **8**; burning **4 s** at
**10% of the hit per 0.5 s**; slow **×0.3 for 15 s**. Per-point scaling affects strike
damage, heal and buff duration ([D6](numeric-design.md)).

[D23](defence.md) governs stealth. Clone/zone effects remain scoped burst/buff approximations,
not final fidelity; taunt semantics follow [canonical AI](../domain/3_Classes.md#ai-behavior)
and [combo neutrality](../domain/3_Classes.md#combo-system), not an instruction to ignore taunt.
Resource/special/status configuration: `design.resources`, `design.special-attack`,
`design.status-effects`; constraint `c-ability-runtime`.
