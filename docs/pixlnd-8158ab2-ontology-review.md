# Ontology review — pixlnd at 8158ab2

## Scope and method

Target: `8158ab2735ea5015d08338c104c3ee17f56a0f37`, checked out on `master` with a clean worktree at audit start. Review coverage was divided across four independent read-only reviewers plus parent synthesis: all 75 tracked files in `ontology/`, including all 41 instance JSON files, the complete canonical domain, decision records, model/validator and six ontology tests. Engine consumers were inspected selectively to verify consequences; this is not an exhaustive engine audit, historical-source verification, playtest or release certification.

Comparison guidance: the installed `github.com/gamedev-skills/awesome-gamedev-agent-skills` checkout at `9ca5296b219049c5b68494e1f3c274ead6d727b3`. The router selected relevant Godot data/3D/UI/audio/multiplayer guidance and RPG, procedural-generation, AI, level-design, input, UI/UX, save and feedback disciplines. This evaluates the ontology against those practices; it does not establish which skills its original authors used.

## Verdict

**Keep the ontology. Do not rebuild it to resemble generic skill examples.** It is already a strong, version-aware game specification with an ontology backbone. Its greatest weakness is not missing nouns or content: it is proving that independently detailed rules compose into valid generated worlds, trustworthy executable checks and a satisfying player experience.

The skills are most useful as review lenses and implementation/testing procedures. They should not become a competing source of game rules.

## Findings, in priority order

### 1. Validation failure can become a successful process exit

**Reproduced by the executable reviewer and independently rerun by the parent.** The baseline and all six ontology tests passed, but setting `design.loot` to null in a fresh in-memory model caused a GDScript error, `validate() == false`, and an empty diagnostic collection. A temporary wrapper using the entrypoint's exact output/exit logic printed **`ontology INVALID (0 errors)` and exited 0**.

The actual entrypoint displays validity using both signals but exits using only the error collection (`ontology/validate.gd:10–17`). Loot validation assumes a dictionary and directly indexes required fields (`ontology/model.gd:637–643`). Removing `gear-chance` also aborts validation without a diagnostic. An invalid class weapon reference records one error, then crashes later and suppresses subsequent checks.

This is narrower and more serious than the already documented incomplete-validator coverage: a failed validation execution must not be accepted by automation. Preserve both return/diagnostic evidence and process exit status, and make malformed-input handling accumulate errors rather than abort. The reproduction changed no repository input; it injected invalid data only in memory.

### 2. Generated item level and character power use incompatible progression units

**Confirmed contract-composition issue; not a current equip-rejection bug.**

- Item `level` is described as power `+1..+100`: `ontology/domain/3_Classes.md:985`.
- Character level is unbounded while its power approaches/caps at +100: `ontology/domain/3_Classes.md:1283–1287`.
- The full-strength gate compares item level with character power: `ontology/domain/5_Constraints.md:192`.
- Loot assigns item level directly from creature level ±1: `ontology/instances/generators.json:101`; `game/items/items.gd:155–169`.

At character/creature level 100, character power is 84, while loot is +99..+101. At level 200, power is 91 while loot is +199..+201. This is a dimensional mismatch, not merely an untuned percentage.

The missing runtime gate is already backlog. The additional issue is deciding what the producer's `level` means before composing it with the gate. The contract promises full strength, not necessarily an outright equip ban; claiming all such loot is currently unusable would overstate the evidence. Do not silently invent conversion, capping or weakened-item rules.

### 3. Boss identity is not the same as creature category

**Reproduced current consumer contradiction, using a controlled generation fixture.**

Hell Demon has category `demon` and `boss: true` (`ontology/instances/creatures.json:105`) and appears in the lava-land roster (`ontology/instances/creature-families.json:30`). The canonical boss flag means always-boss independently of category (`ontology/domain/3_Classes.md:390,399`).

The ordinary spawner filters category names, including `boss-species`, rather than the parsed boss flag (`game/world/spawner.gd:20–28`). Consequently Hell Demon remains eligible for an ordinary group/stat plan. The path explicitly defers boss spawning to another slice (`spawner.gd:1–3`).

A bounded `Spawner.plan` probe retained the shipped design and lava roster while supplying flat dry terrain, no village and level 1. At seed 26879 / zone (0,0), it produced an ordinary two-member Hell Demon group with mage role and ordinary generated stats. The parent independently reproduced it. This proves eligibility leakage in the real planning function, not that seed 26879 has an actual lava biome at its origin.

This is not a demand to implement the deferred boss system. The smallest corrective direction is identity-aware eligibility in the ordinary path, not recategorizing every boss as though boss status were a biological category.

### 4. Smaller specification inconsistencies and reference debt

- **Race semantics:** `ontology/domain/3_Classes.md:323–325` says races are purely cosmetic while selecting different collision dimensions and mentioning small races fitting through windows. “No racial stat bonuses” is accurate; “no gameplay consequences” is not. No race-mechanic change is needed to correct this wording.
- **Android status:** `ontology/domain/3_Classes.md:1434–1438` still says selected but unimplemented; the linked profile documents a first-slice runtime and owner hardware test (`ontology/domain/controller-profiles.md:78–87`). Detailed hardware characterization remains unrecorded; do not turn that limitation into either a blanket absence or comprehensive acceptance.
- **Reference closure:** district buildings include `class-trainer-<class>` IDs without matching building records; landscape dungeon lists include `desert-ruins`, `jungle-ruins`, and descriptive strings such as `temple (large islands)` (`ontology/instances/buildings.json:6,20`; `ontology/instances/landscapes.json:6–9`). Broader reference/data enforcement is already documented debt, not a newly discovered project. These are concrete cleanup cases, not evidence that the existing village runtime is broken.

## What is already good

### Rules and provenance are distinct

Alpha/Steam descriptions, approved hybrid choices, excluded content, uncertain historical annotations and runtime coverage are explicitly separated (`ontology/domain/0_Conventions.md`; `1_Scope.md`; `5_Constraints.md`). Generic game-development skills do not provide this level of historical precision.

### State ownership is carefully modeled

Catalog species differ from logical mobs; families differ from generated packs; threat amount differs from target selection and tie priority (`ontology/domain/4_Relations.md:66–95`). Persistence distinguishes portable character state, character/world records, shared world state and personal source claims (`ontology/domain/3_Classes.md:1486–1517`). Equal seeds are not equal saved-world identities.

### Recent combat contracts are precise

Resistance has a defined attack classification and defence order. DOT applications have independent identities, schedules and source retention. Equipped HP recomputes without healing on equip. Artifact bonuses are calculated from current artifact-free stats, not pickup-time snapshots. These already embody the RPG/data-modeling skills' strongest recommendations.

### Controls are semantic rather than key-shaped

The action catalog separates block from special attack, selection from committing a UI operation, and interaction from pickup. Android specifies cancellation and pointer ownership rather than merely drawing touch buttons. Do not discard this to adopt a simpler generic input example.

### Feedback already resembles the game-feel skill

Event bundles distinguish normal hits, crits and kills; trauma decays; hit-stop uses real time; pickups do not cause heavy shake (`ontology/instances/generators.json:128–147`). The missing next step is evidence of readability and comfort, not indiscriminately adding effects.

## Where the gamedev skills add the most value

### A. Capability-aware procedural solvability

`c-key-item-need` ensures that a key is not generated without a matching lock. It does not prove that a necessary key exists, is obtainable before that lock, or that the reward is reachable with the player's available traversal abilities (`ontology/domain/5_Constraints.md:224`; `6_Generators.md:14–16`).

Use **level-design: critical-path gating** and **procedural-gen: validate generated output**. Before shipping dungeon/mission generation, check safe starts, reachable goals, keys outside their own gates, and routes compatible with available climbing/gliding/sailing. This does not enable Omega's coarse-map system or require a general graph framework.

### B. Spatial and reward pacing

At the approved 16,384-block land width and 6-block/s walk speed, an ideal unobstructed land-width walk takes **45.5 real minutes** (`ontology/instances/generators.json:81,84`). This is arithmetic, not a measured play session; terrain, combat and travel abilities change it.

Use **level-design: metrics, pacing, teaching and playtesting** to measure time to discovery, a useful reward and recovery/services on one fixed-seed route. Preserve approved world size and one settlement per land unless the owner chooses otherwise.

The RPG skill also encourages evaluating the entire reward loop. Current open-world values imply roughly one class-matching gear drop per 20 kills in expectation (20% gear chance × one of four classes), or about four even-level-kill levels before slot usefulness. Shops and future crafting/mission rewards alter this. It is a playtest hypothesis, not proof that loot must be increased.

### C. Cross-system balance thresholds

Uncapped skill points increase buff duration while reducing cooldown. Existing Camouflage inputs reach 27 seconds duration versus 26 seconds cooldown at seven points. Continuous recast uptime is therefore a predictable implication of approved choices, not automatically a bug. Test and communicate those build milestones rather than importing generic crit caps, XP curves or arbitrary duration limits.

### D. Persistence integrity and network operations

Ownership is well specified, but a future artifact pickup changes both portable possessions and a character/world claim. Saving those independently can lose a reward or permit it to be reclaimed after interruption. **save-systems** contributes coherent snapshots, crash-safe writes and defensive load tests. Atomic replacement of each file alone does not prove consistency across files.

Likewise server authority is settled, but stale/repeated requests, durable operation identity and disconnect handling remain implementation contracts. Test them when networking is selected. No save/network implementation currently exists, so these are future integration risks, not present corruption or exploit reports.

### E. Large-world precision and reproducibility

The approved world extends roughly ±8.39 million metres, while the current renderer/spawner uses global Godot positions. Existing edge tests check bounds and streaming, not far-origin movement/contact precision. Verify engine precision and coordinate strategy before claiming full-world traversal readiness; this audit reproduced no precision defect.

Preserve coordinate-local RNG streams. Add order-independent zone generation and seed-distribution tests when appropriate. The procedural skill's illustrative single shared RNG should not replace an already useful streaming design. Reproduction evidence should include seed plus code/config revision and relevant dynamic inputs.

## Do not import the skill templates wholesale

- Keep JSON/stable IDs unless Inspector authoring provides a concrete benefit; `.tres` is not a prerequisite for good data-driven architecture.
- Do not add migrations for nonexistent legacy player data.
- Do not pause inventory/skills/shop panels: their live-time behavior is explicit.
- Do not add buffered touch attacks or smooth analog rescaling over Android's selected behavior.
- Do not replace the approved threat lifecycle with an illustrative patrol/chase FSM.
- Do not introduce generic damage floors, caps or progression curves over approved mechanics.

## Recommended order

1. Repair validation's fail-closed exit behavior and the bounded boss-filter inconsistency when authorized.
2. Reconcile item-level/power units before implementing the gate; clean small stale summaries alongside relevant documentation work.
3. Strengthen required-input/reference checks incrementally, using the already-approved validation-boundary mapping rather than creating another competing schema.
4. Apply reachability and fixed-seed pacing tests to the next world/dungeon/mission slice.
5. Specify coherent checkpoints and authoritative request handling when persistence/networking is selected.

**Overall:** the ontology needs stronger composition and player-experience evidence, not more exhaustive historical cataloging or a wholesale architectural rewrite.

## Verification and limitations

Executed under Godot 4.7.2 with bounded timeouts:

- Baseline `ontology/validate.gd`: exit 0, `ontology valid`.
- All six `ontology/test_*.gd` scripts: exit 0 with their expected success messages.
- Parent independently checked all 41 instance JSON files parse as object roots and reproduced the travel/power arithmetic.
- Scratch negative-input cases reproduced known missing-input/reference/provenance gaps and the newly demonstrated fail-open exit behavior. The parent read the probe and logs and independently reran it.
- Scratch Hell Demon plan probe reproduced the eligibility leak; the parent independently reran it.

The initial scratch ingestion probe timed out (124) after its own unguarded access to a missing row following an ingestion error. Its log was retained; a guarded correction terminated normally. This harness failure is not reported as a production-entrypoint hang.

Parent reproduction logs:
- `/tmp/pixlnd-8158ab2-parent-validator-probe.log`
- `/tmp/pixlnd-8158ab2-parent-boss-probe.log`

The checkout remained clean at the target HEAD after both independent reproductions. No browser, windowed playtest, hardware test or fresh historical-source research was performed. No project files were changed.

## Detailed specialist reports

Artifacts under:
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/be1dd129-af53-4641-b17c-5e9f8cedbd20/review/`

- `executable-contract.md`
- `rpg-combat-items.md`
- `world-ai-missions.md`
- `controls-presentation-persistence.md`
