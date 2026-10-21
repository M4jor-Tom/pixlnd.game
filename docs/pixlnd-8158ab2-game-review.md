# game/ review — parent-verified findings

Reviewed `/home/theta/repos/pixlnd`, `master`, source baseline `8158ab2735ea5015d08338c104c3ee17f56a0f37`.
Final verification found concurrent HEAD `f17738d1788c80a9fcd370048228f34f694c729a`, adding only `docs/pixlnd-8158ab2-ontology-review.md`. The reviewed game, ontology, tests and configuration are byte-identical to the baseline; the checkout is clean. This review made no commits or repository edits.
Scope: implemented behavior and applicable Godot/gamedev practices against current ontology. Missing features, documented implementation deferrals, historical-only A/S rules and tuning preferences are excluded. This is a read-only review, not implementation authority.

## Verdict

**Not fully ontology-conformant.** The data-driven organization is broadly sound, but focused runtime probes reproduced eight defects, grouped into six topics below. These are defects in existing behavior, not requests to finish the game. No architecture rewrite is warranted.

Baseline: ontology validator passed; all **28 existing tests (22 game, six ontology)** and headless main-scene boot passed with no logged errors. The baseline does not cover the reproduced cases. Test evidence: `checks.md`, `/tmp/pixlnd-game-audit-tests-1PGBsB8B/results.tsv`, and full logs in that directory.

## 1. P1 — Creature instances share mutable collision and mesh resources

- Runtime: `game/entities/creature.tscn:5–7,13–16`; `game/entities/creature.gd:44–45`; spawning selects size at `game/world/spawner.gd:85,93`.
- Authority: `ontology/instances/generators.json:86`, `design.spawns.size-by-category` specifies independently sized categories.
- Reproduced: a size-1 creature initially has shape/mesh height 1. After setting up a second creature at size 1.9, the first creature's shape and mesh become approximately 1.9, while its collision-node centre remains 0.5. Shape and mesh identity comparisons are both true.
- Consequence: loading a new group changes existing creatures' appearance and collision dimensions, with stale offsets.
- Minimal correction: make both mutable subresources local to each scene instance (or duplicate before mutation); test two differently sized instances. Existing creature tests instantiate same-sized animals.
- Evidence: `/tmp/pixlnd_world_review_probe.gd` and `.log`, exit 0. The probe uses differing representative sizes to establish aliasing; production config also contains differing category sizes.

## 2. P1 — Stun does not consistently prevent action/movement

### Player input

- Runtime: `game/entities/player.gd:405,410–411,432–436`.
- Authority: `ontology/instances/generators.json:66`, `design.status-effects._doc`: stunned target cannot act.
- Reproduced with mapped native key events and normal physics callbacks: a grounded stunned player jumps (vertical velocity about 13.323; y rises to 0.454); held ascent while stunned produces vertical velocity 3.0.
- Source also shows desktop interaction/Quick Item omitting the stun guard; those two subpaths were not separately exercised in the stun probe.
- Minimal correction: apply the existing stun eligibility to input admission consistently, without freezing timers or implementing deferred committed-ability interruption.

### Creature locomotion

- Runtime: `game/entities/creature.gd:78–80,230–236`; status insertion at `game/entities/entity.gd:49–53`.
- Same authority as above; knockback is a separate effect.
- Reproduced: a chasing wolf given pure stun, without knockback, travels about **3.25 blocks in 0.5 seconds**, retaining 6.5 blocks/s horizontal velocity while still stunned.
- Minimal correction: remove AI-requested locomotion during stun while preserving actual knockback; do not blindly erase all displacement.
- Existing tests mainly assert the stun flag or disable enemy physics, rather than asserting movement/input inhibition.
- Evidence for both: `/tmp/pixlnd_input_stun_review_probe.gd` and `.log`, exit 0.

## 3. P2 — Ordinary arrows behave like area attacks

- Runtime: `game/combat/projectile.gd:89`; `game/entities/player.gd:642–662` loops over every overlapping body.
- Authority: `ontology/instances/generators.json:110`, `design.movesets._doc`: ordinary projectile hits the **first body within radius**, with splash/pierce distinct; basic Bow has radius 0.7 and neither property.
- Reproduced: one ordinary Bow projectile damages two adjacent wolves **40 HP each**, recording two hits.
- Minimal correction: select one eligible target for a non-piercing/non-splash impact while reusing existing defence/status handling. Do not change all AoE strikes.
- Gap: existing ordinary-arrow test uses one nearby target.

## 4. P2 — A fatal landing still processes queued actions

- Runtime: `game/entities/player.gd:429–435`, after synchronous `_fall_damage`; death cleanup is at `:679–688`.
- Authority: player death/respawn lifecycle at `ontology/domain/3_Classes.md:352–354`, `design.combat.death` in `ontology/instances/generators.json:103`; this is an existing lifecycle bug, not a request for deferred shrine/death-screen work.
- Reproduced through the real physics entrypoint: player HP 1, lethal landing and a verified just-pressed Quick Item request results in **dead=true, HP=200, one potion consumed** after death cleanup.
- The probe manually advances the real physics callback with an actual input edge; it does not establish an OS-input timing frequency. The source shows the same tail is reachable when the edge coincides with a real landing.
- Minimal correction: return when death occurs during fall-damage resolution. Existing lethal-DOT handling already does so.
- Gap: lethal DOT is covered; lethal landing plus queued action is not.

## 5. P2 — Ability timers do not respect elapsed-time boundaries

### Cyclone cadence

- Runtime: `game/combat/abilities.gd:138–142` discards overshoot and processes at most one due strike.
- Authority: `ontology/instances/generators.json:37,42`, channel cadence and `design.abilities.cyclone.tick-s=0.25`.
- Reproduced at equal **1.5 seconds**: 15 × 0.1-second updates yield **5 hits / 105 damage**, while six × 0.25 (or 90 × 1/60) yield **6 hits / 126 damage**.
- Minimal correction: retain the timer remainder and handle due strikes within active channel/stamina lifetime. Preserve existing first-tick phase; this review does not choose a new phase.
- This proves update-partition sensitivity, not a measured rendering-performance problem. Normal engine operation has fixed physics ticks; hit-stop changes scaled time steps.

### Healing-over-time expiry

- Runtime: `game/combat/abilities.gd:126–130` applies a whole update before expiring the heal.
- Authority: `ontology/instances/generators.json:46,58`, Heroic Shout/Bubbles healing amount and duration.
- Reproduced for actual Guardian fourth-slot Heroic Shout: one 10-second update heals **140.4375**; updates of 9.9 then 0.2 seconds heal **141.841875**, although the effect lasts only 10 seconds and is expired in both cases.
- Minimal correction: integrate healing over `min(dt, remaining_lifetime)`.
- Gap: tests use exact intervals/intermediate healing and do not compare total effects at terminal boundaries.

## 6. P2 + unresolved value — Available Apples are consumed for no healing

- Runtime: `game/items/items.gd:70–72`; `game/entities/player.gd:344–346`; item-vendor stock/buy at `game/items/shop.gd:38–41,59–65`.
- Authority: `ontology/domain/3_Classes.md:1068–1073`; `ontology/instances/consumables.json:4` describes Apple healing; `generators.json:101` includes Apple in the active consumable pool.
- Reproduced: buy an Apple for **two copper**, set HP to 10, use it; HP remains **10** and the Apple is removed.
- Cause: Apple has no `heal-mult`; the loader defaults it to zero, and use still consumes the item.
- Exact Apple healing amount is **undefined** in the inspected ontology. Do not borrow another food's coefficient or invent one. Resolve the amount in ontology before implementing it; alternatively seek approval for explicit unsupported-use rejection rather than silent consumption.
- This is independent of deferred sitting/eating animations or channel duration.
- Gap: existing tests cover stock membership and Life Potion healing, not Apple's effect.

Evidence for topics 3–6: `/tmp/pixlnd_combat_review_probe.gd` and `.log`, exit 0, no script errors.

## Rejected or unconfirmed leads

- **Shop opens/closes on the same E press:** source review identified cross-loop handlers, but the parent normal-loop mapped-key probe observed exactly one interaction and the shop remained open. **Not accepted as a confirmed finding.** Other event phases/native windowed delivery were not exhaustively exercised.
- **Wild individuals inside 40 blocks of village centre:** observed, but active config excludes group centres, and the actual settlement radius is 24. This is not a demonstrated settlement-safety violation.
- **Retained weapon after unequip:** only test callers invoke unequip; no live inventory UI removal was found. Excluded as a currently unreachable API hypothesis.

## Godot/gamedev assessment and limits

Appropriate existing patterns include scene composition, seeded generation, separation of generated plans from rendering, injected ontology configuration, shared defence/status calculation, and real-time hit-stop restoration. Direct fixes plus focused regressions are preferable to generic new frameworks, a wholesale Resource conversion, dependency additions or broad refactors.

Simplification/ponytail pass: retain those working boundaries; recommendations are local resource ownership, eligibility, target selection and bounded timer/death corrections. No style-only rewrite findings.

No visual/browser/device acceptance was performed; the UI is native Godot, and this task changes no UI. Existing Android tests provide synthetic regression evidence, not new hardware acceptance. No claim of exhaustive verification or complete implementation is made.

## Execution provenance

- Earlier Astra workflow `83a2efcb-edbc-4e26-81d3-0fc6fc0292d4` and same-protocol resume failed with `fetch failed`, before useful output. Preserved as failed evidence.
- Owner approved `openai-codex/gpt-6.1-sol`; successful workflow `934d75ea-2098-492d-a33b-cdef9f757932` delivered one check report and four fresh-context reviews. Child `presentation.md` contains an unconfirmed shop candidate; this synthesis's disposition supersedes that raw candidate.
- All focused probes are outside the repository; only in-memory runtime fixtures were changed. This review changed no canonical data, gameplay source, tests, project docs, branch, commits or remote state. The concurrent documentation-only commit described above was not created by this review.
- Final parent verification reran the bounded ontology validator successfully, scanned all three probe logs without diagnostics, and confirmed the clean checkout and unchanged reviewed source.
