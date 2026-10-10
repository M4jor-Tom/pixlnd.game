# ontology/ — Cube World rebuild

Source of truth for the game. Read `domain.md` first.

```
ontology/
├── domain.md        canonical semantic layer: scope, competency questions, classes, relations,
│                    constraints, generators, open validation points (§7)
├── instances/       enumerable content, one JSON per family, entries keyed by stable ID
├── research/        the five sourced research dumps the ontology was built from (read-only)
├── model.gd         typed GDScript model (Godot 4.7): enums, Resource classes, loader + validator
└── validate.gd      headless check: `nix develop -c godot --headless -s ontology/validate.gd`
```

## Current scope and decisions (2026-10-05)

Hybrid v1 is alpha progression + approved Steam content; A/S source descriptions are historical
reference, and X/cut or Omega-only content is roadmap coverage, not launch availability (item 8).
Regional gear power loss is **permanently excluded**: never propose or implement it, even for
Cube World cloning fidelity. It is not deferred or an alternative mode.
D1–D26 and subsequent approvals stand. `domain.md §7` indexes the remaining hybrid questions;
`docs/ROADMAP/todo_decide.md §E` tracks their decisions and application status. Equipment-model
and validation-contract policies are approved, but their broader implementation is deferred.
Dated build notes below include superseded placeholders, not proof of current coverage. For
"resume walking through items", follow `docs/lessons.md` and that checkpoint, not the gameplay
slice loop. A green validator proves only its implemented checks, not full ontology consistency.

**Current source-attribution item 75 (2026-10-09):** Flight Master map points, repeat access and
community drop-off glider report recorded in `domain.md §5` / §7 under standing sourcing approval.
No price, persistence or hybrid gliding-gate change; no new implementation debt. Selection/checks:
`todo_decide.md §E`; queued pending independent review and parent acceptance.

**Previous source-attribution checkpoint (2026-10-09):** items 70–74 recorded in `domain.md §5` / §7
under standing sourcing-only approval: map/POI, pet behavior/riding and qualitative crafting-book
encounter reward/recipe-unlock attribution only. Independent recording review and parent acceptance
complete; the one stale checkpoint label was corrected. Exact selections, item commits, checks and
limits: `todo_decide.md §E`; local checkpoint: `docs/HANDOFF.md`. All five handled; empty pending
queue deleted. No new implementation debt or publication authority; prior rules and HOLDs stand.
Remaining histories stay research, not whole-topic completion.

**Previous source-attribution checkpoint (2026-10-09):** items 57–69 recorded in `domain.md §5` / §7
under standing sourcing-only approval, independently reviewed with no issues and parent-accepted
following actual-Git/source/diff audit and bounded validator/boot checks (`todo_decide.md §E`).
Historical utility/attack-key descriptions, ambiguous Mouse Wheel dodge wording and Steam R's
non-universal 30-second report, plus two bounded Steam underwater-survival reports only;
controls, individual cooldowns and swimming/drowning/climbing/Spikes rules unchanged.
Steam emote examples and separately unscoped `/namepet` add no command/naming behavior or tags.
Alpha hydration/XP and Steam pet-scaling reports add no formula, absence or persistence proof;
hybrid pet rules stand. Qualitative Deposit habitats and named unrefined gems add no mining/
refining rule or all-gem/edition proof. Fist handedness/Dagger pairing attribution adds no general
mixing or equipment rule; two-handed Wand stands. Named Wraith habitat/pursuit/pet-avoidance
attribution adds no chase or immunity mechanism; hybrid aggro/home-return rules stand.
Wolf habitat/taming attribution leaves mount/food juxtaposition unresolved; hybrid Wolf, null
tame-food, cut Apple Pie and F2 stand. General Alpaca-family habitat wording adds no per-colour
inheritance or roster correction; dark-Alpaca Desert exclusion stands. Individual Snout Beetle
habitat/ranged-hostility wording adds no landscape, combat parameters or family inheritance;
habitats/role stand and item 39's bug remains prohibited. Cotton/Rogue/Loom attribution adds no
Linen/Silk station or recipe inference; item 18's quantities stand. All selections handled;
empty pending queue deleted. Closure-delta parent review remains separate, not independently reviewed.
Items 1–56 and hybrid defaults stand.
Exact selection/evidence: `todo_decide.md §E`; current status: `docs/HANDOFF.md`.
No gameplay, labels, live-data/checker changes or publication authority. Remaining histories and
Silk/Spinning Wheel HOLD stand.

**Historical source-attribution checkpoint 55 (2026-10-05):** item 55 recorded in `domain.md §5` / §7
under owner standing sourcing-only approval; exact quotation/selection: `todo_decide.md §E`.
Historical Steam UI/minimap key directions only; D17's hybrid F3 debug-menu stands. Independent
recording review found no issues; parent recording audit/validator/boot passed. No unhandled
selection or unanswered ballot remains; empty pending queue deleted. No live-data, labels,
checker or gameplay change. Items 1–54 stand; Silk/Spinning Wheel remain HOLD.
Remaining histories stay research, not topic completion. Parent reviewed the final receipt/
queue-deletion delta and reran audit/validator/boot successfully; local checkpoint: `docs/HANDOFF.md`.
No push authorized or attempted; publication needs separate authorization.

**Historical source-attribution checkpoint 53–54 (2026-10-05):** approved items 53/54 recorded in
`domain.md §5 items 53–54` / §7, independently reviewed with no issues; parent recording audit,
validator and boot passed. Exact selections/full item receipts and limits: `todo_decide.md §E`.
No unhandled selection or presented unanswered proposal remains; the empty pending queue is deleted.
Current pre-publication handoff: `docs/HANDOFF.md`; final handoff review found no issues and parent
final gates passed. Establish commit/push completion from actual Git/publication receipts. Items 1–52 and settled rules stand; Silk/Spinning Wheel quantities stay HOLD, not refusal.
No gameplay, live-data or source-label changes; histories stay research, not whole-topic completion.
Parent owns final publication, then STOP; no new research, questions or implementation.

**Historical source-attribution items 46–52 (2026-10-05):** recorded, independently reviewed and parent-verified.
Canonical: `domain.md §5` / §7; exact selections/commit receipts: `todo_decide.md §E`.
No unhandled selection or unanswered proposal remains; the empty pending queue is deleted.
No gameplay or live changes; remaining histories stay research. Evidence/limits and authorized
handoff/publication/STOP: `docs/HANDOFF.md` / §E. No new research or proposals.

**Historical source-attribution items 36–45 (2026-10-05):** recorded, independently reviewed and parent-verified; that batch left no unhandled approval.
Canonical: `domain.md#pet-food` / §5 / §7; completed selections/receipts: `todo_decide.md §E`.
Pending-only queue: `./docs/todo_handle_reconciled_items.md`, absent when no unhandled item remains.
No gameplay, labels or live changes; item 39's reported visual bug must not be implemented.
Items 1–35 and hybrid rules stand; remaining histories stay research. Evidence/check limits and
final authorized handoff/publication/STOP: `docs/HANDOFF.md` / §E. No new research or proposals.

**Historical source-attribution item 32 recorded (2026-10-05):** `domain.md#pet-food` attributes
“one type of pet food per day”, not one purchasable unit or a selected quantity. No stock,
purchases, labels or live-data changes; earlier rules stand. No presented unanswered proposal
remains; broader histories stay research, not whole-topic completion. Verification, final
handoff/publication and STOP: `todo_decide.md §E` / `docs/HANDOFF.md`.

**Historical source-attribution items 33–35 recorded and verified (2026-10-04):** all approved in three
separate documentation commits. Canonical reports/limits: `domain.md §5` / §7; no encounters,
layout, controls, labels or live-data change. Fresh independent source/diff/log review found no
issues; parent verified actual commits/diffs and reran bounded validator/boot checks.
Item 32 was then unanswered; its later approval/status is above.
Evidence/deferrals: `todo_decide.md §E` / `todo_implement.md`; historical handoff/publication and STOP:
`docs/HANDOFF.md`. No new research or proposals.

**Historical source-attribution items 29–31 recorded and verified (2026-10-04):** all three approved,
separate documentation commits. Canonical evidence: `domain.md §5` / `#pet-food`; no game rules,
labels or live data change. Fresh independent recording review found no issues; parent verified
actual commits/diffs and reran bounded validator/boot checks at that historical checkpoint.
Items 32–35 were then unanswered; current approvals/status are above. Evidence/deferrals: `todo_decide.md §E` /
`todo_implement.md`. Parent owns final handoff/publication, then STOP; no new research or proposals.

**Historical source-attribution items 26–28 recorded and verified (2026-10-04):** all three approved,
including Golem AND Troll in item 28. Canonical evidence: `domain.md §5`. Fresh independent
source/diff/log review found no issues; parent verified actual commits/diffs and reran bounded
validator/boot checks. No labels, live data or gameplay changes; earlier approvals stand and
histories remain research. Evidence/limits: `todo_decide.md §E`; final handoff/publication/STOP:
`docs/HANDOFF.md`.

**Historical source-attribution items 22–25 recorded and verified (2026-10-04):** all four approved;
canonical evidence in `domain.md §5`. Fresh independent source/diff/log review found no issues;
parent verified actual commits/diffs and reran bounded validator/boot checks. No labels,
live data or gameplay changes; earlier rules stand and histories remain research.
Evidence/limits: `todo_decide.md §E`; final handoff/publication/STOP: `docs/HANDOFF.md`.

**Historical source-attribution items 16–21 recorded and verified (2026-10-04):** all six approved;
no presented unanswered proposal remains. Canonical evidence: `domain.md#pet-food` / §5.
Fresh independent source/diff/log review found no issues; parent verified actual diffs and reran
bounded validator/boot checks. No game rules, labels or live data change; histories stay research.
Evidence/limits: `todo_decide.md §E`; final handoff/publication/STOP: `docs/HANDOFF.md`.

**Historical source-attribution items 12–15 recorded and verified (2026-10-04):** all approved, 15 after
clarification; no presented unanswered proposal remains. Canonical findings: `domain.md#pet-food`
/ §5. Fresh independent source/log review found no issues; parent verified actual diffs and reran
bounded validator/boot checks. No game rules, labels or live data change; remaining histories stay
research. Evidence/limits: `todo_decide.md §E`; final handoff/publication/STOP: `docs/HANDOFF.md`.

**Historical source-attribution item 11 recorded and verified (2026-10-04):** `domain.md §5` adds freshly inspected,
revision-pinned cuwo normal-clock code and the sleep constant's definition-only occurrence, not original
Alpha/Steam sleeping behavior. Historical sleep units and other source research remain unresolved;
no gameplay/live-data/checker work authorized. Fresh independent source/log review found no issues;
parent verified actual diffs and reran bounded validator/boot checks. Evidence/limits and final
handoff/publication/stop: `todo_decide.md §E` / `docs/HANDOFF.md`.

**Historical source-attribution items 8–10 recorded and verified (2026-10-04):** bounded historical evidence
and unresolved sleep-speed units in `domain.md §5`; no gameplay change or unanswered presented proposal.
Fresh independent source/log review found no issues; parent verified actual diffs and reran bounded
validator/boot checks. Remaining research, evidence limits and final publication/stop:
`todo_decide.md §E` / `docs/HANDOFF.md`. No data/code/checker work authorized.

**Historical source-attribution items 5–7 recorded (2026-10-04):** corrected food count, food-history
evidence/limits and bounded mixed-source subfacts (`domain.md#pet-food` / §5), preserving F11
and existing annotations. No blanket fauna ancestry or completed-history claim. Fresh independent
review found no issues; parent verified actual diffs and reran bounded validator/boot checks.
Remaining research and evidence limits: `todo_decide.md §E`. Data/code/checker work remains
unauthorized; final handoff/publication/stop: `docs/HANDOFF.md`.

**Historical validation-contract mapping items 1–4 recorded (2026-09-28):** `domain.md §5` now maps
required heterogeneous paths/shapes, bounded source inheritance and definition/generator/runtime
checks; items 1–3 stand. The game is undeployed, with no player data to migrate: require current
rules directly, not legacy compatibility (§0). Per-food and unscoped mixed-container history
remain source research/attribution, not whole-topic completion or unanswered gameplay proposals.
Item 4 is committed as `25552b5`; independent review found no issues and parent diff/validator/boot
verification passed. Evidence/limits: `docs/ROADMAP/todo_decide.md §E`. No data/code/checker work
authorized; final handoff/publication/stop: `docs/HANDOFF.md`.

**Persistence / authority — all nine documentation decisions recorded (2026-09-28).**
No presented Persistence / authority question remains. Independent review and parent verification
passed; item mapping, evidence and limits: `docs/ROADMAP/todo_decide.md §E`.
Ontology documentation only; gameplay, live JSON, tests and checker implementation remain
unauthorized.

**World bounds / resets items 1–4 recorded (2026-09-28):** `domain.md#world` / `#game-clock`
/ §5–6: finite 1024×1024 lands with a map-marked outer boundary; eligible daily enemies return
without renewing permanent claims or completed one-time objectives; occupied sites wait for
all players to leave, with one pending refresh and no clock-triggered survivor/fight reset.
No presented world/reset question remains. Independent review and parent verification passed;
evidence and limits: §E. Runtime, live-data and checker changes remain unauthorized. Publication/
stop direction at that historical checkpoint: `docs/HANDOFF.md`. Validation-contract mapping
recording status is above.

**Aggro batch applied: 1–14/14.** The original twelve and follow-ups 13–14 were approved and
recorded on 2026-09-27; their former open boundaries are settled.
**Creature family items 1–9 recorded (2026-09-27):** `domain.md §3.2/§4/§5`;
**independent 1% per individual dog wherever dogs already spawn**, preserving settlement safety.
Collie supplies skeleton-only encounters' ordinary outcomes. Skeleton Dog is a tameable dog
breed with normal dog behavior, not a special passivity rule, and shares Bubble Gum with Collie.
No unanswered family proposal remains. Live data, shared-food model/loader/validator support
and runtime enforcement remain deferred.
**Settlements/inn items 1–4 recorded (2026-09-27):** one settlement per land is final;
free recovery is separate from paid sleep, with ordinary midnight resets only and unanimous
connected-player agreement / success-only initiator payment (`domain.md#game-clock`).
**Traversal items 1–5 recorded (2026-09-28):** riding gates; training + equipped bought glider/boat;
Spikes reduce climbing stamina consumption by 75%, applied to the skill-adjusted remaining cost
(×0.25), not infinite endurance or additive percentage points. Independent review and parent
verification passed (`todo_decide.md §E`). Artifact approvals are tracked below.
Direct data correction and enforcement remain deferred; world/reset item 3 now records cleared
dungeon/quest enemy reset eligibility (`domain.md#game-clock`).
**Books/formulas items 1–3 recorded (2026-09-28):** permanent/global book recipes, shared
knowledge without duplicate rewards/rerolls or consuming known formulas, and immediate book
recording with visibly power-locked crafting (`domain.md#recipe` / `#book-of-crafting` / `#power-gate`).
No presented books question remains; duplicate knowledge never bypasses power requirements.
Independent review and parent verification passed (`todo_decide.md §E`); persistence item 1 now records cross-world portability.
**Artifacts items 1–6 recorded (2026-09-28):** `domain.md#artifact` defines the normalized
logarithmic total (initial **z=0.1**), equal additive shares and recalculated artifact-free stat basis.
Traversal counts matching artifacts; attack and maximum HP count all. D6's decay/1% floor is
superseded, not its rewards or other decisions; no levels or gate bypass. No presented artifact
question remains. Independent review and parent verification passed (`todo_decide.md §E`).
Direct data correction, model/loader/validator support and runtime implementation remain deferred.
**Assassin item 1 recorded (2026-09-28):** Camouflage is one rank-3 skill on key 3, with no
separate fourth node, key-4 ability, investment or charge (`domain.md#skill-tree`). This is the
explicit Assassin exception to D10; other specializations and existing Camouflage behavior stand.
No presented Assassin question remains. Live metadata clarification and validation coverage
remain deferred; current key-3/no-key-4 runtime already matches.
**Wand item 1 recorded (2026-09-28):** mechanically two-handed despite a one-hand pose, with
no other hand item; existing damage/attacks and 32-cube limit stand; common recipe follows D6
at 20 wood cubes (`domain.md#weapon-type`). No presented Wand question remains. Live handedness
and recipe data, enforcement and validation coverage remain deferred.
Gameplay and live JSON remain unchanged; current persistence recording status is above.

## Decision and build history (from 2026-09-07)

- Research complete; `domain.md` + 40 instance files + `model.gd` written.
- Owner decisions applied: **hybrid ruleset** (alpha progression + steam content), **Godot 4 +
  GDScript** (engine maintenance verified: 4.7.2 stable 2026-08-18), **region lock dropped**,
  all cut/Omega content deferred to `docs/ROADMAP/`.
- 2026-09-07 (later): initial owner decisions and fact conflicts recorded in
  `docs/ROADMAP/todo_decide.md`; designed tunables live in `instances/generators.json#design`.
  Toolchain pinned in `flake.nix` (Godot 4.7.2, node, jq); `validate.gd` first passed with 0 errors.
  Later reconciliation identified additional questions; see the current §7/§E indices.
- 2026-09-08: stale `?` (water level, artifact traversal bonus) cleared; D11 settles the four hybrid
  gaps (block reward, regeneration, artifacts per land, `/pvp`) in `generators.json#design`.
- 2026-09-09: `stats.json` xp-to-next table corrected to what its own formula gives (L20 537, L50 760, L100 881).
- 2026-09-09: D19 XP per kill + level-up rules (`design.progression`, `c-xp-config`, `c-level-up`) for `game/progression/`;
  three table rows that a D16/D17 edit had prepended above the `domain.md` title moved back into §3.2 ai-behavior and §5.
- 2026-09-09: D20 skill tree spend rules (`design.abilities`, `keybinds.json#hybrid.skills-window` = X, hybrid `screens.skills`,
  `c-tree-shape`, `c-skill-spend`); the five rank-1 class nodes had `needs` 1, now 0 like every other tree root.
- 2026-09-10: D21 class ability runtimes (`design.abilities` per node, `design.resources.mp`, `design.special-attack`,
  `design.status-effects`, `c-ability-runtime`) for `game/combat/abilities.gd`; the D20 placeholder strike is retired.
- 2026-09-10: D22 settlements + spawn rule (`design.settlement`, `ui.json#screens.npc-service`, `c-settlement-config`) for `game/world/settlement.gd`,
  `game/items/shop.gd`; `world.spawn-rule` hybrid = the (0,0) village square.
- 2026-09-11: D23 defence (`design.defence`, sneak / aim / camouflage `stealth-per-s|stealth-full`, `c-defence-config`) for dodge / block /
  stealth in `game/entities/player.gd`; §5 `c-stat-roll` and `c-name-length` relabelled (nothing loadable carries them).
- 2026-09-11: D24 weapon movesets + projectiles (`design.movesets`, `design.abilities` runtime `projectile` / dash `throw`, `design.status-effects.poison`,
  `c-moveset-config`) for `game/combat/projectile.gd` and the M1 / M2 paths in `game/entities/player.gd`.
- 2026-09-11: D25 game feel (`design.feel` event bundles: hit-stop / camera trauma / synthesised sfx keyed by `audio.json#sfx-alpha-ids` /
  damage numbers / impact + trail / stun stars / buff icons / level-up pop, `c-feel-config`) for `game/combat/feel.gd`.
- 2026-09-11: D26 creature ranged / mage roles (`design.creature-roles`: combat-role parsed from `creatures.json`, any-class weighted roll,
  projectile chase/keep-away/LOS/windup/cooldown, species overrides, `design.feel.sfx.fireball`, `c-creature-roles`) for `game/entities/creature.gd`.
- 2026-09-09: D18 items, loot, inventory numbers + `c-loot-config` / `c-stack-rule` / `c-slot-accepts` for `game/items/`.
- 2026-09-08: D17 runtime profiling overlay (Godot Debug Menu, F3) + `design.frame-budget` / `c-frame-budget`.
- 2026-09-08: D16 simulation radius + `c-sim-radius` (creatures frozen beyond 80 blocks; the 4 FPS fix).
- 2026-09-08: D15 combat multipliers + class `hp-mult` for `game/combat/`.
- 2026-09-08: D14 spawn numbers + `c-roster-ids` (wetlands roster fixed) for creatures in `game/entities/`.
- 2026-09-08: D13 player numbers (movement, camera, hybrid keys) for `game/entities/` + `game/meta/`.
- 2026-09-08: D12 world numbers (zone/land size, heightfield, climate rules, palettes, land names)
  landed for the first gameplay slice, `game/world/`.
- 2026-09-08: router step done — `project.godot` + `game/` scaffold; `OntologyDB` autoload loads
  `instances/` through `model.gd` and aborts on reported loader/validator errors, not every
  possible §5 violation (coverage gaps remain). Layout: `game/README.md`.
- 2026-09-15: reconciliation items 1–8 applied as recorded in `todo_decide.md §E`; equipment
  semantics are documented, but the broader live slot/validator/consumer changes remain deferred.
- 2026-09-17: item 9 validation-contract direction documented; path/provenance/boundary mapping
  and enforcement remain separate. Item 10's authorized poison/dodge, block-exhaustion, hand-conflict,
  panel-time and class-combo repairs are applied; latest two repairs committed in `44ab0a1` (rebased reference).
- 2026-09-17: owner authorized documentation/data-description cleanup without gameplay changes:
  current/open/historical summaries reconciled, shop reference corrected, duplicate price-description
  key removed without changing its parsed value. Verification is tracked in `todo_decide.md §E`.

## Instance files

| file | contents |
|---|---|
| rulesets.json | chosen hybrid flags; alpha / Steam historical reference; Omega announced roadmap |
| races.json, classes.json, specializations.json | player identity |
| abilities.json | ~65 skills, passives, movement abilities, alpha tree positions, steam inputs |
| weapon-types.json, equipment-slots.json, materials.json, rarities.json, affixes.json, item-types.json | item model |
| stats.json | resources, stats, alpha formulas (items + character) |
| status-effects.json | debuffs, buffs, hazards |
| consumables.json, ingredients.json, recipes.json, crafting-stations.json | crafting |
| key-items.json, pet-food.json | specials, artifacts, taming |
| creatures.json, creature-families.json, factions.json, npc-roles.json | living things |
| landscapes.json, terrain-features.json, flora.json, deposits.json, block-types.json | world |
| dungeon-types.json, poi-types.json, static-entities.json, buildings.json | structures |
| economy.json, mission-types.json | loops |
| keybinds.json, ui.json, slash-commands.json, audio.json | presentation |
| versions.json | timeline, alpha→steam delta, reception, fan fix-list |
| generators.json | numeric configs + invariants for every procedural system |

## Conventions

Version tags `A` (alpha 0.1.x), `S` (Steam 1.0), `Ω` (Omega, announced), `X` (cut / data-only).
`?` on a source value marks uncertainty; `domain.md §7` separates active hybrid questions from
reference-only gaps. In type notation it means optional/nullable, not a missing design decision.

## Validate JSON

```sh
for f in ontology/instances/*.json; do jq -e 'type == "object"' "$f" >/dev/null || exit 1; done
```
