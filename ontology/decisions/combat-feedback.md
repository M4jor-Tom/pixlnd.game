# D25 — Combat feedback

Combat events fire bundles from [generators.json](../instances/generators.json) `design.feel.events`:
- Hit-stop up to **0.12 s on kill**, **0.08 s on crit**, none on hurt/shoot.
- Camera trauma **0..1**, squared into horizontal/vertical offset and roll shake, decaying **1.5/s**.
- Floating target numbers: white hit, gold crit **×1.5**, red hurt, orange DOT, green heal.
- Stars over stunned heads; HUD buff icons with countdown fill.
- Level-up toast scales **×1.6 → ×1 over 0.4 s**.
- Projectile trail piece every **0.03 s**; impact sphere flash **0.15 s**, using splash radius if splashed.
- Synthesised sound: sine + noise + pitch slide, from `design.feel.sfx`, keyed by
  [audio.json](../instances/audio.json) `sfx-alpha-ids`.

Real audio assets, particles beyond sphere stand-ins, animations/hit timing and a reduce-shake /
reduce-flash accessibility screen are outside this slice; design numbers are its tuning knobs,
not a prohibition on later accessibility UI. Constraint: `c-feel-config`.
