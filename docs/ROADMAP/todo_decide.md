# TODO — decisions to take before the affected implementation slice

Priority zero. Resume here with any agent. Context: `ontology/domain.md` (§1 scope, §7 open
points), `ontology/instances/*.json`, `docs/ROADMAP/README.md`. Already decided on 2026-09-07:
D1 hybrid ruleset, D2 Godot 4.7 + GDScript, D3/D4 cut + Omega content → roadmap, region lock /
`+` items / worn degradation dropped.

**Status 2026-09-18:** D1–D26 and the original fact conflicts below remain decided. The ontology
reconciliation in §E records approved corrections and additional open questions. Resolve an open
question before its affected slice; do not reopen settled choices. Designed numbers live in
`ontology/instances/generators.json#design`.

## A. Design decisions (owner)

- [x] **D5 Multiplayer target** — dedicated server (alpha style, IP/DNS join, seed in server
  config). Recorded: `rulesets.json#ruleset-hybrid.flags.multiplayer`, `domain.md §3 multiplayer-mode`.
- [x] **D6 Undocumented numbers** — all designed, recorded in `generators.json#design` + the
  file each row names:
  - [x] alpha per-point skill: flat +5 % effect / −5 % cooldown per point, floor 25 %, uncapped
  - [x] crit: ×2.0, chance above 100 % adds to the multiplier → `stats.json#stats.crit`
  - [x] item stat curve: alpha curve only, no 1.0 tier curve → `stats.json`
  - [x] prices: buy = base × level × rarity mult (1/2/4/8/16), sell 25 % → `economy.json#prices`
  - [x] artifacts (historical D6): +5 % first, ×0.9 each next, floor 1 %; one traversal stat
    **and** attack + max HP → `key-items.json#artifact`. Accumulation is superseded by the
    2026-09-28 approvals in §E / `domain.md#artifact`; live-data migration is deferred.
  - [x] inventory stack cap: none → `domain.md §3 inventory`
  - [x] enemy HP/damage: cuwo npc-hp formula × per-family multiplier, white lvl-1 mob = 150–250 HP
  - [x] Circle of Power: +10 % attack, +10 % max HP in the land → `status-effects.json`
  - [x] recipes: cubes = 5 × size class (1/2/4), +1 gem per rarity tier above common → `recipes.json`
- [x] **D7 Alpha player cap** — configurable, default 4. Recorded: `generators.json#network-alpha`.
- [x] **D8 Skin colour at creation** — real option, per-race palette ours. Recorded: `races.json#_creation`.
- [x] **D9 First-person zoom** — kept. Recorded: `ui.json#camera`.
- [x] **D10 Ability merge in hybrid** — 3 alpha class columns (removed skills back at rank 3) +
  1 `ultimate` column holding the steam R skill, unlocked by 5 points in the spec's rank-3 skill.
  Recorded: `abilities.json` `alpha-tree` on R skills, `domain.md §3 skill-tree`; Assassin's
  single-skill exception was approved on 2026-09-28 (§E).
- [x] **D11 Hybrid gaps (2026-09-08)** — block gives MP (the bar specials spend); Regeneration =
  stamina only; artifacts 1–3 per land, seeded; `/pvp` dropped, PvP = `server.cfg` flag default off.
  Recorded: `generators.json#design` (`block-reward`, `regeneration`, `artifacts-per-land`, `pvp`).
- [x] **D12 World numbers (2026-09-08)** — zone 64², land 256² zones, 1 block = 1 m, sea level 96, fBm
  heightfield, climate rules, land names. Recorded: `generators.json#design.terrain|climate|names`,
  `landscapes.json#*.gen`.
- [x] **D13 Player movement, camera, keys (2026-09-08)** — walk/sprint/swim/jump/gravity/step-up/hitbox/stamina,
  orbit camera zoom range, hybrid key column. Recorded: `generators.json#design.movement|camera`, `keybinds.json#hybrid`.
- [x] **D14 Open-world spawns (2026-09-08)** — groups per zone, roster, hostility roll, NPC HP multiplier,
  wander/chase numbers. Recorded: `generators.json#design.spawns|enemy-hp`; wetlands roster fixed (`slimes` → ids).
- [x] **D15 Combat multipliers (2026-09-08)** — attack-power ×10, NPC damage ×12, armor floor 10 %, combo bonus,
  swing/windup/cooldown, respawn. Recorded: `generators.json#design.combat`, `classes.json#*.hp-mult`.
- [x] **D16 Simulation radius (2026-09-08)** — creatures beyond 80 blocks are frozen (fixes the physics catch-up
  spiral, 4 FPS). Recorded: `generators.json#design.spawns.ai.sim-radius`, `c-sim-radius`.
- [x] **D17 Runtime profiling and frame budget (2026-09-08)** — Godot Debug Menu add-on on F3 for players, physics
  catch-up cap. Recorded: `keybinds.json#hybrid.debug-menu`, `ui.json#hud.debug-menu`, `generators.json#design.frame-budget`, `c-frame-budget`.
- [x] **D18 Items, loot, inventory (2026-09-09)** — drop chances, rarity weights, level spread, ground-item lifetime,
  stack rule, starting inventory. Recorded: `generators.json#design.loot|stack-cap|starting-inventory`, `c-loot-config`,
  `c-stack-rule`, `c-slot-accepts`; `domain.md §3.4 inventory` props, relations `holds` / `equips`.
- [x] **D19 XP and level-up (2026-09-09)** — XP per kill (fraction of the creature's xp-to-next, level-gap multiplier),
  overflow carry, heal on level-up, skill points banked. Recorded: `generators.json#design.progression`, `c-xp-config`, `c-level-up`.
- [x] **D20 Skill tree (2026-09-09)** — spend/unlock rules, X screen, keys 1-4 placeholder strike, per-point multipliers (swim speed first).
  Recorded: `generators.json#design.abilities`, `keybinds.json#hybrid.skills-window`, `ui.json#screens.skills`, `abilities.json` rank-1 `needs` 0,
  `c-tree-shape`, `c-skill-spend`.
- [x] **D21 Class abilities (2026-09-10)** — a runtime (dash / channel / burst / buff / heal) with numbers, cost and cooldown for
  every class node and ultimate; MP gain and the M2 special attack; stun / knockdown / knockback / burning / slow numbers.
  Recorded: `generators.json#design.abilities|resources|special-attack|status-effects`, `c-ability-runtime`.
- [x] **D22 Settlements and spawn rule (2026-09-10)** — one village per land, placement / flattening / ring layout numbers, one NPC per
  service building, shop stock + prices in play, trainer respec fee, inn heal + respawn point, spawn on the (0,0) village square.
  Recorded: `generators.json#design.settlement`, `ui.json#screens.npc-service`, `c-settlement-config`.
- [x] **D23 Defence (2026-09-11)** — dodge roll numbers + per-passive rewards, block (shield / guardian / cyclone) with block-power,
  the stealth bar's sources, decay and bonuses, creature hits rolling stun / knockback on the player.
  Recorded: `generators.json#design.defence`, `design.abilities.<id>.stealth-per-s|stealth-full`, `c-defence-config`.
- [x] **D24 Weapon movesets and projectiles (2026-09-11)** — an M1 / M2 runtime per class weapon-type (melee variants, arrows with gravity,
  bolts, returning boomerangs, staff bursts at the cursor, wand beams, bracelet bolts / splash balls), the projectile ultimates, poison ticks.
  Recorded: `generators.json#design.movesets`, `design.abilities` runtime `projectile` + dash `throw`, `design.status-effects.poison`, `c-moveset-config`.
- [x] **D25 Game feel (2026-09-11)** — feedback bundles per combat event: hit-stop, camera trauma / shake, floating damage numbers,
  stun stars, buff icons, level-up toast pop, projectile trails / impact flashes, and sounds synthesised from alpha sound ids.
  Recorded: `generators.json#design.feel`, `audio.json#sfx-alpha-ids`, `c-feel-config`.
- [x] **D26 Creature ranged / mage roles (2026-09-11)** — a `combat-role` (melee, ranged, mage, any-class) parsed from
  `creatures.json` role text; ranged / mage chase to range, back off below keep-away, need line of sight, wind up and fire a
  shot through the target's normal dodge / block / i-frames, applying statuses on a landed hit (poison through dodge);
  any-class humanoids roll a weighted role per spawned group; species overrides (spitter, snout-beetle) per creature id.
  Recorded: `generators.json#design.creature-roles`, `design.feel.sfx.fireball`, `c-creature-roles`.

## B. Conflicting facts (pick a side)

- [x] **F1 Steam ability numbers** — recorded in `abilities.json`, `?` stripped:
  - [x] Heroic Shout: taunt 5 m + 50 % HP over 10 s
  - [x] Guardian Toughness: +25 % max HP
  - [x] Battle Fury trigger: 13 % per hit
  - [x] Shadow Shooter duration: 30 s
  - [x] Bubbles count: **6** (owner pick, guide value)
  - [x] Shuriken Toss cost: 25 stamina
  - [x] R-ultimate cooldowns: per-skill (20/30/40/60 s)
- [x] **F2 Rideable flags** — per-page (no). `pet-food.json` `rideable: false` on all 13.
- [x] **F4 Land difficulty — owner override, not the default.** Enemy level = band from lowest
  party level − X to highest + Y (solo: own level), X/Y in solo settings or `server.cfg`; each land
  rolls a danger tier (safe/normal/dangerous) at generation that fixes where in the band it sits.
  Recorded: `generators.json#design.enemy-level`, `landscapes.json#_shared`, `domain.md §3 land`.
- [x] **F6 Land geometry** — one land = one region cell; our own noise/water/heightmap.
  Recorded: `domain.md §3 land`.
- [x] **F8 Spirit Bell duration** — 30 s. `key-items.json#spirit-bell`.
- [x] **F9 Life Potion station** — anywhere. `consumables.json#life-potion`.
- [x] **F10 Alpha-id creatures "not in alpha"** — tagged `S`, alpha id reserved. `creatures.json`.
- [x] **F11 Warthog food** (banana mash) — obtainable. `pet-food.json`.

## C. Process gaps (do, no decision needed)

- [x] Godot 4.7.2 via `nix develop` (flake.nix); `godot --headless -s ontology/validate.gd` passes
- [x] `git init` the repo — done, first commit b9e0bfd.
- [x] Raw research corpus (740 wiki pages, cuwo clone) — not kept; `ontology/research/*.md` is
  what remains.

## D. Not decisions (info)

- F3 (`+` items / lore) is moot: region lock dropped.
- F5 split into D7/D8/D9 above, all decided.
- F7 Omega status (Vulkan vs UE5, silence since 2024) is roadmap-only.

## E. Ontology reconciliation (2026-09-13)

Derive straightforward corrections from `ontology/`. If it does not determine the answer
unambiguously, record the decision here for later instead of inventing a rule. The approved/open
subsections track decisions; the reconciliation checklist tracks application. Approval alone does
not mean a correction is applied; land it in `ontology/` before changing consumers.
Present all known remaining questions for one topic together, with numbered gamer-facing
recommendations and **"Approval versus Refusing"** consequences. Check answers against settled
rules and one another; clarify refusals, contradictions and newly exposed cases before applying
dependent decisions. Refusal does not approve the opposite rule or immediately break the game.
Commit each reconciled item separately. On explicit handoff, record the next topic or unfinished
items, commit and push, then stop; otherwise do not push (owner workflow change, 2026-09-27).
Approval of an ontology decision is not approval to implement additional gameplay.
The full walkthrough/resumption protocol is in `docs/lessons.md`; the prompt
**"resume walking through items"** means follow it and this checkpoint, not implement a slice.
Never propose or implement regional gear power loss in pixlnd, even for Cube World cloning
fidelity: permanently excluded, not a deferral or alternate mode (owner, 2026-09-15).

**Persistence / authority — all nine documentation decisions recorded (2026-09-28).**
No presented Persistence / authority question remains. Independent review and parent verification
passed; evidence and limits below. Ontology documentation only; gameplay, live JSON, tests and
checker implementation remain unauthorized. Verification record: `7a79913`.

**Current sourcing direction (2026-10-09):** owner latest exact reaffirmation:
**“For all items about accepting/refusing to increase the source precision of informations, auto-accept each of them in subagents”.**
Items **70–74** are selected under this narrow standing sourcing-only approval. **70–72 are
provisionally recorded; independent review and parent acceptance pending. 73–74 await recording.**
Exact original selections, Previously selected status, sources/limits and documentation boundary:
`docs/todo_handle_reconciled_items.md`; all five remain queued.
Use one distinct fresh serial subagent and scoped commit per item; retain each pending entry
until its canonical recording, checks, required independent review and item commit are verified.
No individual numbered owner answers are fabricated; current approval grants no broader authority.

**Previous sourcing batch 57–69:** owner exact standing answer:
**“Auto-accept all items which are about the topic of augmenting the precision of sourcing or not, each in one separate subagent.”**
Supervisor selected 57–69 as proposed; no individual numbered owner answers exist. All thirteen
are handled: separately recorded/committed, independently reviewed with no issues and parent-accepted
after actual-Git/source/diff audit and bounded validator/boot checks. Exact original selections,
canonical pointers and full commit/parent receipts are below; the then-empty pending queue was deleted.
Items 1–56 stand; remaining histories stay research, not topic completion. No mechanics, labels,
live JSON, checker/code/tests, publication or next-topic authority. Protocol: `docs/lessons.md`.
Closure-delta parent review remains separate from completed recording acceptance.

**Historical handoff direction — items 53–54 (2026-10-05):** owner exact answer:
**“53: Approved; 54: Approved; When handled, handoff, commit, push”**. No amendments.
Both recorded in separate item commits (`domain.md §5` / §7), independently reviewed with no
issues and parent recording-verified; exact selections/full receipts below. No unhandled selection
or presented unanswered proposal remains; the empty pending-only queue is deleted.
Final handoff review found no issues; parent final audit, whitespace, validator and boot passed.
Parent owns the separate final handoff commit and authorized normal publication, then STOP.
Actual Git/publication receipts establish completion, not this pre-publication snapshot.
Items 1–52 stand; Silk/Spinning Wheel quantities remain HOLD, not refusal or new 27/36 ballots.
No gameplay, live JSON, tests, checker, labels, schema, compatibility or migration changes.
Handoff/limits: `docs/HANDOFF.md`; per-item evidence and completion receipts below. Stop after this
checkpoint; remaining histories are research, not whole-topic completion or new questions.

**Historical source-research checkpoint (2026-10-05, superseded):** four pages inspected after owner-assisted
Firefox access; two independently reviewed **UNPRESENTED** citation candidates, not approvals or
already-issued ballots. Next unused item number is 53. No pending selected item remains and the
pending-only queue is absent. Details/limits: `docs/HANDOFF.md` current entry point. Candidates:
Bows revision 19306's generic firing/range/ammunition reports, and Dungeon revision 19603's exact
NPC-attributed potion warning with its Conceptualized Content/preview-context caution. Unlimited
arrows and the existing dialogue corpus are not reopened. Silk Armor 12301 and Spinning Wheel
19647 do not resolve quantities or new refining/station rules; hold them, not refusal or opposite
approval. Items 1–52 and all settled hybrid rules stand. No gameplay or canonical recording follows.

Evidence: private `/tmp/pixlnd-reconcile-source-53.VnWRKF/`; use only `article-extracts/` for public
quotations/provenance. Full authenticated DOM/owner save contains account/token initialization and
must never be published. Parent retained originals/hashes privately, generated article-only extracts
with new hashes, and passed a synthetic article-scope privacy check without external requests.
Fresh independent review: managed `source-53/fresh-firefox-source-review.md` under run
`4eb57475-a626-4fd1-83a4-05fcc3332313`. Three HTTP200 captures are DOM snapshots, not raw HTTP
entities; no separately fetched pinned URLs, edit timestamps, images or original-build execution.
The owner selected default Firefox and required privacy windows stay open; verified preservation
and corrected setup/test failures are retained. Exact current lesson/index state: `review-current/`.
Context percentage unavailable: conservative checkpoint before a new approval batch. Final handoff
review found no issues (`checkpoint/handoff-review.md`); parent confirmed reviewed-draft equality
before receipt-only additions and inspected the final delta. Fresh final whitespace, bounded
validator/boot and article-hash checks passed, exit0, under `checkpoint/final-*`; these cover existing
loaded data/startup, not history or new policy enforcement. Synthetic scope validation is not a
comprehensive sanitizer guarantee. Final receipt-only rechecks passed. Actual Git state and
`checkpoint/publication.*` establish whether this prepared checkpoint is committed/published;
this pre-push snapshot does not claim push success. No new questions/research after checkpoint STOP.

**Historical source-attribution direction — items 46–52 (2026-10-05):** all seven approved without
amendments, recorded in separate item commits, independently reviewed and parent-verified
below. No unhandled selection or presented unanswered proposal remains; the empty pending
queue is deleted. Finalize the handoff, commit and normal-push only `fix/ontology-reconciliation`,
verify fresh remote/upstream/local equality and clean worktree, then STOP. No new research,
questions or implementation; this checkpoint is not a publication claim.

**Historical source-attribution direction — item 32 (2026-10-05):** owner answered **“32: Approved;
Once handled, handoff, commit, push”**. The report is recorded below for documentation only;
no presented unanswered proposal remains. Broader histories stay research, not whole-topic
completion. Verify and commit this item separately, then finalize/publish the handoff and STOP.
No new research, proposals or implementation.

**Historical source-attribution direction — items 33–35 (2026-10-04):** all approved, recorded and verified in
three separate documentation commits. Fresh independent source/diff/log review found no issues;
parent actual-commit/diff audit and bounded validator/boot reruns passed (evidence below).
Item 32 was then presented but unanswered, not refused or implementation debt; its later
approval/status is above. That final handoff/publication/STOP checkpoint is historical.

**Historical source-attribution direction — items 29–31 (2026-10-04):** owner approved only 29–31
(“2ç” explicitly read as 29). All three recorded and verified in separate documentation commits.
Fresh independent recording review found no issues; parent actual-diff audit and bounded
validator/boot reruns passed (evidence below). Items 32–35 were then unanswered; current
approvals/status are above.
Parent owns final verified handoff/commit/push, then STOP; no new research, proposals or implementation.

**Historical source-attribution direction — items 26–28 (2026-10-04):** all three approved, recorded
and verified in separate documentation commits. Item 28 covers Golem AND Troll. Fresh independent
source/diff/log review found no issues; parent actual-commit/diff audit and bounded validator/boot
reruns passed (evidence below). No presented unanswered proposal remains; earlier approvals stand.
Final handoff/publication, then STOP; no new research, proposals or implementation.

**Historical source-attribution direction — items 22–25 (2026-10-04):** all four approved, recorded
and verified in separate documentation commits. Items 1–21 and all hybrid approvals stand;
no presented unanswered proposal remains. Fresh independent source/diff/log review found no
issues; parent actual-commit/diff audit and bounded validator/boot reruns passed (evidence below).
Final handoff/publication, then STOP; no new proposals or implementation.

**Historical source-attribution direction — items 16–21 (2026-10-04):** all six approved, recorded
and verified in separate documentation commits. Items 1–15 and settled hybrid rules stand;
no presented unanswered proposal remains. Fresh independent source/diff/log review found no
issues; parent actual-commit audit and bounded validator/boot reruns passed (evidence below).
Final handoff/publication, then STOP; no new proposals or implementation.

**Historical source-attribution direction — items 12–15 (2026-10-04):** all four approved
and recorded for documentation only, item 15 after clarification.
Items 1–11 and settled hybrid rules stand; no presented unanswered proposal remains.
Fresh independent source/log review found no issues; parent actual-diff audit and bounded
validator/boot reruns passed (evidence/limits below). Final handoff/publication, then STOP;
no new proposals or implementation.

**Historical validation-contract mapping direction (2026-09-28):** items 1–4 are recorded below; item 4
adds the detailed mapping and owner correction: undeployed game, no player data to migrate,
require current rules directly. No presented question remains. Resume remaining **Validation-contract
source research/attribution**, not uncertain gameplay facts or implementation. Item 4 is committed
as `25552b5`; fresh independent review and parent verification passed (evidence below).
Final handoff/publication/stop: `docs/HANDOFF.md`. No next-topic proposals.

**Historical world/reset direction (2026-09-28, superseded):** owner answered **“1: Approved; 2: Approved;
3: Approved; 4: Approved”**, then **“When done, handoff, commit, push”**. Items 1–4 are recorded.
No presented world/reset question remains; item 2’s dependency on item 1 is satisfied.
Only five existing Markdown paths changed; runtime, live JSON, tests and checker work remain
unauthorized. Independent review found no issues; parent verified actual commits/diffs and reran
checks successfully (evidence below). Commit this final handoff and push only
`fix/ontology-reconciliation`, verify remote/upstream/local equality and clean status, then stop.
No merge, force-push, history rewrite or next-topic proposals. Next topic, named only:
**Validation-contract mapping** (existing item 9 policy already approved).

**Historical unanswered handoff (superseded):** the former “I'll handle this with the next
agent” direction preserved items 1–4 without answers. Its clean `7a79913` / remote `2ed538d`
checkpoint predates the current approvals and is not a fresh publication claim.

**Persistence owner answer:** “1: Approved; 2: Approved; 3: Approved; 4: Approved; 5: Approved;
6: Approved; 7: Approved; 8: Approved; 9: Approved (I thought that I already approved 9
in the threat topic, otherwise it's fine)”. Item 9 closes Aggro 11's deferred restart case,
not its already-approved running-world retention. Canonical semantics: `domain.md` sections below.

| item | application | canonical section | commit |
|---|---|---|---|
| 1 — Portable heroes | [x] recorded | `save-data` | 01199a214bc1246b869e279978672a16b384bfb9 |
| 2 — World-local personal history | [x] recorded | `save-data` | 4de5271bcadd8681b12d01080c883d88a46f1a2f |
| 3 — Shared terrain exploration | [x] recorded | `world` | bde3bf7bbe22abbff12e57561237ba06d5b6bfde |
| 4 — Shared world changes | [x] recorded | `save-data` | 36e1a6427e597123bf3b86e0de71fc6ef466a952 |
| 5 — Personal permanent-source claims | [x] recorded | `save-data` | da2b35795866a8d82acda786f030136759a1fa90 |
| 6 — Server-authoritative outcomes | [x] recorded | `multiplayer-mode` | a312dc5b866dc515a08d0a61949757a02d718b2b |
| 7 — Trusted-co-op imports | [x] recorded | `multiplayer-mode` | 1817dfd228ca6106d608a5adfaee3b26bbaf530e |
| 8 — Stopped shutdown clock | [x] recorded | `game-clock` | 467500c376f2d77ee1cdcc57230f852f26a04c92 |
| 9 — Restart threat retention | [x] recorded | `ai-behavior` | 6771f3168ceb35b4c3d954f04fc33fcd95ba1dd1 |

**Verification:** each item passed semantic/scope inspection, `/simplify`, ponytail-review,
`git diff --check` and bounded ontology validation before its commit. Fresh independent review
found no issues through source/saved-log inspection, not rerun commands. Parent inspected the
actual nine commits and aggregate diff, independently confirmed exact saved-diff correspondence
and the five-Markdown-path boundary, and reran both checks successfully (exit 0):
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Results: `ontology valid` and normal startup. These cover existing loaded data/startup, not
runtime enforcement of the new policies. No gameplay suite, visual or network checks were run.
Historical D/F text, gameplay, live JSON and checker files are unchanged.

**Session-local evidence:** `/tmp/pixlnd-persistence-reconcile.XsnIBI/` holds the exact
`approval-brief.md`, per-item diffs/review notes/check logs/exits/commit records, `batch.diff`,
`commit-map.md`, `independent-review.md`, and `parent-{audit,validator,boot}.{log,exit}`.
The final verification-record diff received `/simplify` and ponytail-review; final bounded
rechecks and whitespace checks are in `verification-record-*.log/.exit`.

**Fresh handoff verification (2026-09-28):** parent inspected the four-file documentation diff,
preserved the exact unanswered batch, ran `/simplify` then ponytail-review, and reran both
bounded commands above: `ontology valid` and normal startup, exit 0. Expected Nix dirty-tree
warnings only. Diff checks passed; no runtime/data/checker policy was changed. Evidence:
`/tmp/pixlnd-persistence-handoff.UID5vE/` (`handoff-review.md`, `handoff.diff`,
`validator.{log,exit}`, `boot.{log,exit}`, `diff-check.{log,exit}`). These are fresh loaded-data/
startup checks, not gameplay, visual, network or boundary/reset enforcement tests.

**Historical Wand direction (2026-09-28, superseded):** owner answered **“1: Approved; When done, handoff, commit,
push”** for Wand handedness. Documentation-only item 1 is recorded in **`1f5eabc`** and passed
checks and independent review below. Commit the final handoff; publish `fix/ontology-reconciliation`,
verify remote/local HEAD equality and a clean worktree, then stop. No gameplay, live JSON, tests,
model/loader/validator changes, merge or history rewrite. Next topic, named only: **Persistence / authority**.

**Historical Assassin direction (2026-09-28, superseded):** owner answered **“1: Approved; Once item reconciled,
handoff, commit, push”** for Assassin. Item 1 is recorded below: single rank-3 Camouflage on
key 3, no separate fourth node or key-4 ability. Scoped item commit **`b19662b`** passed checks
and independent review below. Commit the final handoff; publish on `fix/ontology-reconciliation`,
verify remote/local HEAD equality and a clean worktree, then stop. No gameplay, live JSON, tests, model/loader/validator changes, merge,
history rewriting or next-topic proposals. Next topic, named only: **Wand handedness**.
Artifacts 1–6, books/formulas 1–3, traversal 1–5, settlements/inn 1–4, family 1–9 and aggro 1–14
remain recorded. Older publication instructions and hashes below are historical checkpoints.

**Prior checkpoint (2026-09-19; references from the earlier rebase):** items 1–2 are applied,
validated and committed in `0a562fc`. Items 3–8 are approved for ontology and their semantic
corrections are committed in `e10836a`; their walkthrough handoff is recorded in `c005f55`. The owner resumed and approved item 9's
validation-contract direction for **ontology documentation only** on 2026-09-17. Its policy is
recorded in `domain.md §5`; validator, loader, generator and gameplay implementation remain
deferred and unauthorized. Exact required paths and unresolved provenance/boundary mappings
still need documentation before enforcement.
Inspect actual Git state on `fix/ontology-reconciliation`.
Item 3's live slot/validator/consumer changes remain deferred, and item 7's
spirit-cube drops remain unimplemented. No live flags, balance or unresolved gameplay choices changed.
Item **10 — Runtime contract violations** has its listed repairs applied: on 2026-09-17 the owner approved
live time for inventory, skill-tree and shop panels in solo and multiplayer, whole-channel combo
miss/reset for damaging channels (including early ends), and combo-neutral zero-damage taunts
(no increase, reset or inactivity-timer refresh). The rules are recorded in `domain.md §3.7/§3.3/§5`
for ontology documentation only. The owner separately authorized **only the poison-tick/dodge
runtime repair and its regression test** on 2026-09-17. Its existing rule and narrow scope are
recorded in `domain.md#status-effect`; the repair is applied with a red-to-green regression and
passing headless suite (evidence below). The owner subsequently authorized **only the
block-exhaustion/same-interval-hit repair and its regression** on 2026-09-17: the final valid
block retains damage/status protection and its MP reward; later hits at zero power receive none
of those block benefits. The repair is applied with red-to-green and full headless-suite evidence
below. The owner then separately authorized **only the two-handed-weapon/shield equip-conflict
repair and its regressions** on 2026-09-17: reject the attempted equip in either order without
changing the bag or worn gear. That repair is applied and tested; existing handedness data,
including the provisional wand classification, is unchanged. All other runtime fixes remain
unauthorized; the broader item-3 equipment-model implementation remains deferred.
The owner resumed on 2026-09-17 and explicitly authorized **only the panel-time runtime repair
and its regression tests**, preserving current gameplay input restrictions, balance and other
menus. Authorization is recorded in `domain.md#hud-element`; the repair is applied with
red-to-green regression, full headless-suite and windowed-check evidence below. Independent
correctness and ponytail reviews found no issues. The owner then separately authorized **only
the class-ability combo runtime repair and its regression tests** on 2026-09-17. Authorization
is recorded in `domain.md#combo-system`; the repair is applied with red-to-green, full-suite
and windowed HUD evidence below; independent correctness and ponytail reviews found no issues.
The completed panel-time changes, balance, inactivity expiry, caps and unrelated runtime
behavior are preserved.
The owner then requested committing the staged repairs before continuing: `44ab0a1` contains
the panel-time and class-combo repairs and their records. The owner approved **artifact/document
cleanup**, now applied, checked and reviewed: stale references/statuses, duplicate
price-description key and an index of remaining questions, with no gameplay or parsed-data-value
changes. At that checkpoint, cleanup approval did not authorize automatic commit or push.
The cleanup was subsequently committed before the authorized semantic rebase onto `20e35d8`;
that checkpoint authorized no push or additional implementation.
**Aggro / group aggro:** damage gain is now maximum-HP-percentage-based, not raw-HP-based
(owner correction, 2026-09-18; exact rule below). Targeting ties are unchanged. On 2026-09-18
the owner rejected no-decay-during-combat and directed continuous fixed-rate decay per mob/player,
with hits adding threat concurrently and target switches preserving remaining threat. These
ontology-only rules are applied in `domain.md#ai-behavior`; the requested relationship model
is explicit in §4/§5 (`threat`, `aggro-points`, `current-target`). The owner subsequently approved
**1 aggro point per second** and **zero-threat behavior** (2026-09-18), documentation only;
exact rules are below. **Player-death aggro clearing and engagement-order reset** were approved
separately and recorded on 2026-09-19 for documentation only. Survivors retain their scores and
engagement order; normal hostile detection and targeting priorities are preserved.
**Zero-threat order clearing (owner correction, 2026-09-19):** retaining the old tie-breaker
position was rejected. When a mob's threat toward a player reaches zero, discard that player's
old position and determine a fresh tie-breaker if needed afterward, without restoring old priority.
**Fresh engagement order (owner approved 2026-09-19):** after zero threat, assign a new position
when that player's aggro toward that mob next rises above zero, behind still-valid positions.
Applied in `domain.md §3.2/§4/§5` for documentation only; prior targeting priorities remain intact.
**Escape (owner approved 2026-09-19):** escape alone preserves remaining positive aggro and
engagement order under normal decay; reaching zero clears the old position. Applied in
`domain.md §3.2/§4/§5` for documentation only, without changing chase limits or other players' state.
**Return-home trigger (owner approved 2026-09-19):** pursuit beyond the existing 30-block home
leash starts return regardless of aggro. Inside it, losing a target first checks other living
positive-threat players, then normal hostile detection before returning. Starting return preserves
aggro/order; aggro still decays normally. Applied in `domain.md §3.2/§4/§5`, documentation only.
Arrival behavior follows the separately approved per-mob rule below.
**Protected return (owner approved 2026-09-19):** attacks do not restart pursuit; return speed
is ×2 normal (currently 6.5 → 13 blocks/s), with 90% damage reduction including poison/burning.
Reaching home alive restores full HP once and ends both bonuses. No revival, status cleansing
or CC immunity. Recorded in `domain.md §3.2/§5`, documentation only; threat reset is separate below.
**Arrival aggro/order reset (owner approved 2026-09-19):** completing return home alive clears
that mob's remaining scores and engagement-order positions toward every player, once alongside
healing. Gains/decay continue until arrival; other mobs are unaffected. Normal detection still
applies, and later damage, including uncleansed DOT ticks, builds fresh threat normally.
**Zero-threat fallback (owner approved 2026-09-19):** without a positive-threat priority or
valid current target, choose the nearest normally detected player. This grants no aggro/order;
retaining a tied current target takes precedence. Recorded in `domain.md §3.2/§5`, documentation only.
Remaining topic items include **exact-distance ties among nearest detected zero-aggro players**,
other resets, taunts (including during return), full-stealth interaction and group behavior.
**Historical publication authorization and stop point (2026-09-19):** the owner approved the fallback,
requested **handoff, commit, push**, and will resume with the next agent. Publish the current
documentation on `fix/ontology-reconciliation`, including the five preceding local commits
(`b4e0ea3`, `8d3c497`, `ac8e0d5`, `06ddadc`, `b8df023`), then stop. No runtime work or next
proposal is authorized now. The next agent starts at `docs/HANDOFF.md` and waits for the owner
to resume the walkthrough before presenting the exact-distance tie question. Follow
`tasks/lessons.md`: one gamer-facing recommendation using **"Approval versus Refusing"**,
one approval question, then wait. Questions are not corrections or rejection. Do not jump to
the gameplay handoff's aggro slice or deferred equipment/validator implementation. Preserve
D1–D26, all walkthrough approvals and remaining open questions.

### Approved in the item-by-item walkthrough

- [x] **Cookie remains deferred (item 1, owner approved A).** Preserve its A/X reference row
  and roadmap entry; remove it from `generators.json#design.loot.consumable-pool` (also used by
  shops). This reconciles D18 content selection with D3, not a new cut-content exception.
- [x] **Relation cardinalities (item 2, owner approved).** `raises-stat` permits multiple stat
  targets; each artifact still raises exactly one traversal stat plus attack and max HP (D6,
  `c-artifact-stat`). `costs` permits zero or multiple resources with amounts scoped by ruleset
  (Steam Intercept uses stamina and MP). Correct `domain.md §4`; preserve existing effects,
  costs and hybrid balance. This approval does not settle family membership or artifact stacking.
- [x] **Equipment model (item 3, owner approved for ontology, 2026-09-15).** Gear has dedicated
  matching positions; the Q consumable is selected independently and never displaces gear.
  Lamps occupy the light slot, a glider or boat the special slot, and taming food the pet slot
  rather than the player's quick-use slot. Keep existing class/hand restrictions and all 13
  stored indices (12 usable positions plus reserved `unknown-0`); no extra slot or stat bonus.
  Record canonical item-type/subtype distinctions. Gameplay implementation is a separate step;
  wand handedness and traversal unlocks are not settled by this approval.
- [x] **World blocks versus combat blocking (item 4, owner approved, 2026-09-15).** Model the
  terrain voxel as `block` and the defensive action as `combat-block`. Reconcile ontology
  references only; preserve terrain behavior, controls, block-power costs, MP rewards, damage
  reduction and existing runtime config/event identifiers. This adds no gameplay mechanic.
- [x] **Boomerang recipe (item 5, owner approved for ontology, 2026-09-15).** A common boomerang
  costs 20 wood cubes at the workbench, following D6's two-handed size class. Preserve rarity
  gem requirements and combat behavior; wand handedness/cost remain separate. Without this
  correction, using the old recipe in a finished crafting system would charge only 10 wood
  cubes (half the intended amount); leaving it unresolved would not override D6.
- [x] **Creature source identities (item 6, owner approved for ontology, 2026-09-15).** Numeric
  source IDs include post-alpha additions; retain stable creature IDs, numeric IDs, version
  tags and existing food pairings (192: Radishling Sprout / Mineral Water; 293: Caterpillar /
  Mixed Salad). Preserve legacy `aid` / `alpha_entity_id` names and null/-1 for unrecorded IDs;
  version provenance is not inferred from a number alone. No taming or loader behavior change.
  Without clarification, existing rows still load, but a future alpha-only range check could
  wrongly exclude these creatures or their bait; that is a risk, not a reproduced gameplay bug.
- [x] **Mission-boss spirit-cube exception (item 7, owner approved for ontology, 2026-09-15).**
  Eligible non-mission bosses drop one spirit cube per kill, with a fixed type/level per boss.
  Mission bosses, including Saurians, do not drop spirit cubes; their normal mission rewards
  remain unchanged. The hybrid retains the recorded alpha exception. Without reconciliation,
  implementing the universal wording could give mission bosses extra weapon-upgrade drops;
  declining the correction would not approve that alternative. No drop runtime is implemented.
- [x] **Reference versus hybrid scope (item 8, owner approved for ontology, 2026-09-15).**
  Hybrid v1 retains alpha progression + approved Steam content; A/S comparisons are historical
  reference, X/cut and Omega-only content remain roadmap material, and current-slice approximations
  are not final rules. No new content inclusion/exclusion or unresolved merge is authorized.
  Non-approval would not change the already-decided game; it would leave ambiguous scope text.
  Owner reaffirmed: **never propose or implement regional gear power loss in pixlnd**, even
  for cloning fidelity. Permanently excluded, not deferred or an alternative mode.
  The requested stop before item 9 was honored; the owner resumed on 2026-09-17.
- [x] **Validation-contract direction (item 9, owner approved for ontology documentation only,
  2026-09-17).** Require data for active hybrid systems, reject missing whole tables/config blocks
  and malformed shapes, and check existing class/spec, skill-tree and upgrade-capacity rules
  without changing balance. Permit source-version inheritance only where explicitly documented,
  never guessed. Validate definitions/config at load time and generated artifacts separately;
  report failure for any accumulated loading/validation error. Recorded in `domain.md §5`.
  Exact path/inheritance/boundary mapping remains preparatory work below, not invented by this
  approval. Once implemented, these checks should catch data regressions before players encounter
  missing choices, broken progression or invalid upgrades. Leaving the contract open
  would not change today's gameplay or approve different rules; it would retain blind spots.
  Validator, loader, generator and gameplay changes require separate authorization.
- [x] **Panel-time policy (item 10, owner approved for ontology documentation only, 2026-09-17).**
  Time keeps running while inventory, skill-tree and shop panels are open, in both solo and
  multiplayer. Enemies, projectiles, damage-over-time effects, cooldowns, buffs and dodge timers
  follow their normal rules; browsing grants no immunity or extended protection. Browsing during
  combat remains risky. Recorded in `domain.md#hud-element`. Leaving this undecided would
  have retained the current partial player freeze, not approved a whole-world pause. This approval
  does not settle other panels/menus, input availability or combo boundaries; gameplay fixes still
  require separate authorization.
- [x] **Damaging-channel miss/reset boundary (item 10, owner approved for ontology documentation
  only, 2026-09-17).** Judge the whole channel, not individual ticks: empty ticks do not reset the
  combo; a channel that lands no hits resets it when it ends, including an early end. Normal
  inactivity expiry, successful-hit combo gains and per-weapon caps remain unchanged. Thus a
  Cyclone that hits and then spins through empty space is not treated as a miss. Leaving this
  undecided would keep the boundary open, not select per-tick resets. Recorded in
  `domain.md#combo-system` / `c-combo-reset`; runtime fixes require separate authorization.
- [x] **Zero-damage taunts and combos (item 10, owner approved for ontology documentation only,
  2026-09-17).** Zero-damage taunts neither increase nor reset combo and do not refresh its
  inactivity timer, whether or not any enemy is affected. Normal inactivity expiry and existing
  taunt/healing effects remain unchanged. Players can use a defensive taunt without a combo
  penalty, but cannot build or sustain a combo by taunting alone. Leaving this undecided would
  not approve rewarding or penalizing taunts. Recorded in `domain.md#combo-system` / `c-combo-reset`;
  threat amounts and targeting rules remain separate, and runtime changes require authorization.
- [x] **Poison ticks during dodge — runtime authorization (item 10, 2026-09-17).** Reproduce and
  fix poison ticks discarded during dodge, with a regression test. This enforces the existing
  D26 rule, not a new poison mechanic. Preserve poison damage/duration/cadence, ordinary dodge
  protection and existing burning behavior. That approval authorized no other deferred runtime
  work; the subsequent block authorization is separate. Application/verification are tracked below.
- [x] **Exhausted block and same-interval hits — runtime authorization (item 10, 2026-09-17).**
  Reproduce and repair blocking after power reaches zero, with a regression. Preserve the final
  valid hit's damage reduction, MP reward and attached-status protection; subsequent hits at zero
  power get no block benefits even before the next defence update. Positive power below one hit's
  cost still permits the existing full block. Preserve all balance, regeneration, Guardian,
  Cyclone and other defences. Deferral would leave the timing loophole, not approve free blocking.
  This enforces D23; that block approval authorized no other deferred runtime work.
- [x] **Two-handed weapon plus shield — runtime authorization (item 10, 2026-09-17).** Reject
  an equip attempt that would create this conflict in either equip order, leaving worn gear and
  the attempted bag item unchanged. Do not auto-unequip, delete or duplicate items. Valid 1H +
  shield, 2H alone and non-conflicting replacements remain available. Use current handedness
  data without settling the provisional wand classification. This authorizes only the conflict
  repair and regressions, not broader slot normalization, class restrictions, dual-wield routing
  or Guardian/Cyclone changes. Deferral would retain the loophole, not approve the invalid loadout.

- [x] **Panel-time — runtime authorization (item 10, 2026-09-17).** Repair the player-only
  timer freeze while inventory, skill-tree and shop panels are open, with regressions. Existing
  DOT ticks, cooldowns, buff and dodge expiry must continue; preserve gameplay input restrictions,
  balance and other menus. Deferral would retain the partial freeze, not authorize a world pause.
  This authorizes no other runtime fixes, commits or pushes. Application is tracked below.

- [x] **Class-ability combos — runtime authorization (item 10, 2026-09-17).** Repair missing
  non-projectile class-strike combo handling and add regressions, using the approved damaging-hit,
  whole-channel miss/reset and combo-neutral zero-damage-taunt rules. Preserve existing gain,
  inactivity and cap behavior, damage, costs, cooldowns and taunt/healing effects. Projectile
  and weapon attacks remain unchanged. This authorizes no other deferred work, commit or push.
  Application and verification are tracked below.

- [x] **Artifact/document cleanup — authorized (2026-09-17).** Correct stale references and
  current-status summaries, remove the duplicate price-description key with its effective value
  preserved, and distinguish implemented, approved/deferred and unresolved work. No gameplay,
  balance, loader/validator behavior or unresolved decision changes. Deferral would leave
  misleading documentation, not change the game. The preceding staged repairs were committed
  as requested; this approval does not automatically authorize a further commit or push.

- [x] **Aggro damage contribution (owner corrected 2026-09-18, ontology documentation only).**
  Gain 1 aggro point per 1% of the mob's maximum HP actually removed, including fractional
  points; reduction/absorption and zero-HP-loss handling are unchanged. This supersedes the
  earlier raw-HP conversion so equivalent percentage damage has equal threat-decay timing
  across progression. Recorded in `domain.md#ai-behavior`; the decay rate was approved separately
  below. Keeping raw-HP gain would make equivalent hits linger longer against higher-HP
  mobs at a fixed decay rate. Current last-attacker targeting is unchanged; no implementation,
  commit or push is authorized.

- [x] **Aggro current-target ties (owner approved 2026-09-18, ontology documentation only).**
  In ordinary threat-based targeting, keep the current target when tied for highest threat;
  another attacker must exceed it to displace it through threat alone. This avoids arbitrary
  switching on equal scores. Recorded in `domain.md#ai-behavior`; this approval does not settle
  other targeting ties or special rules. Deferral would have left this tie unresolved, not approved
  another rule. Current gameplay is unchanged; no implementation, commit or push is authorized.

- [x] **Aggro other-target ties (owner approved 2026-09-18, ontology documentation only).**
  When the current target is not among the highest-threat attackers, select the tied leader
  who engaged that enemy first. This gives a predictable fallback, not latest-hit or random
  selection; higher threat and current-target retention take precedence. Recorded in
  `domain.md#ai-behavior`. Deferral would have left this selection unresolved, not approved a
  different rule. Fight boundaries/reset and special rules are not settled by this approval;
  gameplay is unchanged and no implementation, commit or push is authorized.

- [x] **Aggro continuous decay and retained threat (owner direction/correction, 2026-09-18;
  ontology documentation only).** Each mob/player threat score decays at a constant points-per-second
  rate in and out of combat, while hits continue adding threat. Switching targets does not erase
  other scores: a player with positive remaining threat can become the target again if the
  higher-threat teammate dies, subject to normal targeting priority. This replaces the proposed
  no-decay rule; reduced priority is not being "forgiven". The initial 1-point-per-second example
  and zero-threat behavior were subsequently approved below; resets remain unresolved.
  Recorded in `domain.md#ai-behavior`. Deferral would not select no-decay or clearing on target
  switches. Gameplay is unchanged; no runtime, commit or push is authorized.

- [x] **Aggro decay rate (owner approved 2026-09-18, ontology documentation only).** Subtract
  1 aggro point per elapsed second from each mob/player score, continuously in and out of
  combat. With no further gains or resets, 10 points reach zero in 10 seconds at any progression
  level. Existing concurrent percentage-damage gains and targeting rules are unchanged.
  Deferral would have left the rate open, not selected no decay. Zero-threat behavior was
  subsequently approved below; resets and other open aggro decisions remain unresolved.
  No runtime, commit or push is authorized.

- [x] **Zero-threat behavior (owner approved after clarification, 2026-09-18; ontology only).**
  Aggro floors at zero. No separate memory of past damage sustains pursuit after those points
  expire: a mob stops pursuing that zero-threat player if it no longer detects them. A hostile
  mob that still detects them can keep attacking; zero is not immunity. Other players' scores
  are preserved. Deferral would have left this pursuit boundary open, not approved endless
  pursuit or safety beside a hostile mob. Reset conditions (including engagement order), taunts
  and full-stealth interactions remain separate; no runtime, commit or push is authorized.

- [x] **Player-death aggro clearing (owner approved 2026-09-19, ontology documentation only).**
  Death immediately clears every mob's aggro points toward that player, preserving surviving
  teammates' scores and normal decay. After respawn, the player rebuilds aggro from zero;
  normal hostile detection still applies. Death cannot wipe teammates' ongoing threat, and
  zero aggro grants no immunity. Enemy healing, whole-fight resets and engagement-order resets
  were left open by this approval; the separate death/order approval follows below.
  Deferral would have left carry-over through death unresolved, not approved it.
  The owner requested a commit; no runtime implementation or push is authorized.

- [x] **Engagement order on death (owner approved 2026-09-19, ontology documentation only).**
  Death clears that player's engagement-order position with every mob. Re-engaging gives them
  a fresh position; surviving teammates keep theirs. Higher aggro and current-target retention
  still take precedence. Returning players cannot retain their pre-death fallback tie priority.
  Deferral would have left that priority unresolved, not automatically preserved. Engagement-order
  resets at zero through decay, escape and whole-fight resets were left open by this approval.
  The owner requested a commit; no runtime implementation or push is authorized.

- [x] **Zero-threat tie-breaker memory (owner correction, 2026-09-19, ontology only).** The
  proposal to preserve engagement order at zero was rejected. When a mob's aggro toward a
  player reaches zero, discard that player's old engagement-order position with that mob.
  If needed later, determine a fresh tie-breaker; never restore pre-zero priority. Other players'
  scores/order, normal detection and existing targeting priorities remain unchanged. This removes
  expired historical priority without granting immunity or forcing a target switch. Deferral would
  leave the rule unresolved, not approve retaining old priority. The fresh-order assignment trigger
  was left open here and approved separately below; other resets remain open. Runtime
  implementation remains unauthorized.

- [x] **Fresh engagement-order assignment (owner approved 2026-09-19, ontology only).** After
  zero threat, assign a new position when that player's aggro toward that mob next becomes
  positive, behind players whose positions remain valid. Damage must generate positive aggro;
  proximity, detection and misses do not qualify. Higher threat and current-target tie retention
  take precedence. Players rebuild tie priority rather than recover expired priority. Deferral
  would leave the trigger unresolved, not restore the old position. Fallback selection among
  entirely zero-aggro players, taunts and full-stealth interaction remain open. The owner requested a
  commit, then the next walkthrough item; no runtime work or push is authorized.

- [x] **Escape retains threat and order (owner approved 2026-09-19, ontology only).** Getting
  away or ending pursuit alone does not wipe remaining positive aggro or engagement order.
  Normal decay continues, zero clears the old position, and later positive threat gets a fresh
  one. Other players' state and chase limits are unchanged. Players can retreat to let aggro
  fade, but cannot instantly erase it by crossing a pursuit boundary. Deferral would leave the
  escape-reset rule open, not approve an instant wipe. Enemy healing and whole-fight resets
  remain separate. The owner requested a commit, then the next item; no runtime work or push.

- [x] **Return-home trigger (owner approved 2026-09-19, ontology only).** Crossing the existing
  30-block home leash starts return regardless of aggro. Within it, a dead/disappeared target
  or an undetected zero-threat target prompts selection among other living positive-threat
  players using the approved priorities. Without one, normal hostile detection can sustain
  combat; otherwise return. Starting return preserves aggro/order under normal decay. Players
  cannot extend pursuit beyond the leash, but losing one target does not end an ongoing fight
  with another eligible player. Refusing would reject this selection rule, not approve an
  alternative. Return interruption, whole-fight resets and healing were left open by this approval;
  protected return is approved separately below. The owner requested a commit and the next item;
  no runtime work or push is authorized.

- [x] **Protected return (owner approved 2026-09-19, ontology only).** Attacks do not restart
  pursuit during return. Run at ×2 normal return speed (currently 6.5 → 13 blocks/s), taking 90%
  less damage, including poison/burning ticks. On reaching home alive, restore full HP once and
  end both bonuses; a mob killed on the way stays dead. Existing statuses apply: no cleansing
  or CC immunity. Aggro gains/decay continue normally; arrival threat/order reset was left open
  here and approved separately below. Taunts remain open. This makes repeated retreat damage
  less effective without guaranteeing retreat kills are impossible. Refusing would require revising the protection package, not
  undoing the approved leash/aggro rules. The owner requested a commit and the next item;
  runtime work and push remain unauthorized.

- [x] **Arrival aggro/order reset (owner approved 2026-09-19, ontology only).** When the enemy
  completes return home alive, clear its remaining aggro and engagement-order positions toward
  every player, once alongside the approved healing. Gains/decay continue until arrival; other
  enemies' records remain untouched. Normal detection applies and subsequent damage, including
  ongoing poison/burning ticks, builds fresh aggro/order; no status cleanse or immunity. Players
  start with fresh scores after a completed retreat. Refusing would omit this arrival wipe while
  retaining healing and existing decay unless a different reset were approved. The owner requested
  a commit and the next item; runtime work and push remain unauthorized.

- [x] **Nearest-detected zero-threat fallback (owner approved 2026-09-19, ontology only).**
  When no positive-threat player takes priority and no valid current target exists, choose the
  nearest normally detected player. No aggro or engagement order is granted. Higher threat and
  tied-current-target retention take precedence, so merely moving closer does not steal attention.
  This gives players a predictable initial target choice. Refusing would reject proximity as
  the deciding factor, not choose a different fallback or grant immunity at zero. Exact-distance
  ties, taunts and special stealth interactions remain open. The owner requested handoff,
  commit and push, then a stop until the next walkthrough; no runtime work is authorized.

- [x] **Aggro relationship model (owner requested 2026-09-18, ontology only).** Formalize
  `threat` as a directed mob/player entity relation carrying a numeric `aggro-points` amount;
  `current-target` is a separate, optional single-player relation per mob. Scores belong to
  individual entity pairs, not species or players globally. Recorded in `domain.md §4/§5`;
  existing gains, decay policy and targeting priorities stand. This clarification adds no
  balance choice, runtime implementation, commit or push authorization.

- [x] **Aggro 1 — equal-distance fallback (approved/applied 2026-09-27, documentation only).**
  Equal-chance random choice once among equally nearest detected zero-threat players;
  valid tied-current-target retention wins and prevents repeated random switching.
  Recorded in `domain.md#ai-behavior` / `c-current-target`.

- [x] **Aggro 2 — three-second taunt (approved/applied 2026-09-27, documentation only).**
  Heroic Shout forces targeting for 3 seconds without threat/order gain; gains/decay continue
  and ordinary priorities resume afterward. Radius, healing, cooldown and existing skill scaling
  stay unchanged. `domain.md §3.2/§4/§5`; neutral post-taunt eligibility is settled by follow-up 14 below.

- [x] **Aggro 3 — competing taunts (approved/applied 2026-09-27, documentation only).**
  Latest successful taunt replaces the previous one with its own duration; replaced taunts
  never resume. Simultaneous casts choose one caster randomly once. Winner scope across enemies
  was left open here and is settled by follow-up 13 below (`domain.md §3.2/§5`).

- [x] **Aggro 4 — taunt eligibility and cover (approved/applied 2026-09-27, documentation only).**
  Affect hostile and already-provoked neutral enemies within 5 metres even through walls;
  never provoke peaceful neutrals or affect friendly/passive creatures. `domain.md §3.2/§5`;
  post-taunt neutral eligibility was left separate here and is settled by follow-up 14 below.

- [x] **Aggro 5 — taunt termination and return (approved/applied 2026-09-27, documentation only).**
  Return cancels taunt and rejects new/deferred taunts. Outside return, caster death or
  disappearance ends it early; leaving the casting radius alone does not. The home leash remains
  binding (`domain.md#ai-behavior` / `c-current-target` / `c-return-home`).

- [x] **Aggro 6 — full-stealth threat exception (approved/applied 2026-09-27, documentation only).**
  Check full stealth on landing before hit consumption, separately per DOT tick: no new
  damage threat, no existing-threat wipe or taunt cancellation. Partial stealth only keeps its
  existing detection reduction; Camouflage can sustain the exception. `domain.md §3.2/§3.3/§5`.

- [x] **Aggro 7 — spawned-pack membership (approved/applied 2026-09-27, documentation only).**
  A group is one generated pack of creature individuals, not nearby members of a species
  or faction. Recorded in `domain.md §3.2/§4`; no proximity-based pack merging.

- [x] **Aggro 8 — pack response and neutral aggressors (approved/applied 2026-09-27, documentation only).**
  Hostile detection alerts the pack; damaging a neutral provokes combat-capable packmates
  against that aggressor only. Friendly/passive creatures stay excluded and returning members
  finish their return. `domain.md §3.2` / `c-pack-response`; follow-up 14 settles taunt-only eligibility.

- [x] **Aggro 9 — current sightings, individual threat (approved/applied 2026-09-27, documentation only).**
  Share current sightings only, permitting around-corner reactions while a packmate detects
  the player. Once all lose detection, only each mob's own remaining threat sustains pursuit;
  no copied threat/order or shared target choice. `domain.md §3.2/§4` / `c-pack-response`.

- [x] **Aggro 10 — individual neutral forgiveness (approved/applied 2026-09-27, documentation only).**
  Arrival clears that creature's provocation alongside its threat/order reset. Seeing the
  old aggressor cannot re-provoke it; a new damaging attack can. Other packmates keep their
  state (`domain.md §3.2` / `c-pack-response` / `c-return-home`).

- [x] **Aggro 11 — same-world absence retention (approved/applied 2026-09-27, documentation only).**
  Temporary disconnect/unload grants no extra wipe: logical pair scores/order follow normal
  decay and approved resets. Absent players cannot be targeted; reconnect can restore eligibility.
  Actual mob death/respawn starts fresh. Persistence item 9 now closes the restart case
  (`domain.md §3.2/§4/§5`), without reopening this running-world rule.

- [x] **Aggro 12 — elapsed threat and taunt timers (approved/applied 2026-09-27, documentation only).**
  Threat decay and taunt expiry reflect elapsed gameplay time while distant mobs are frozen.
  Movement/attacks remain frozen; this is not an all-status-timer decision (`domain.md §3.2/§5`).

- [x] **Aggro 13 — independent simultaneous-taunt winners (approved/applied 2026-09-27, documentation only).**
  Each affected enemy randomly chooses once among simultaneous eligible taunters whose
  casts reached it, independently of other enemies. The pack may split; no shared winner is
  guaranteed. Settles item 3's former open scope (`domain.md#ai-behavior` / `c-current-target`).

- [x] **Aggro 14 — no lasting neutral eligibility from taunt alone (approved/applied 2026-09-27, documentation only).**
  A previously uninvolved caster is forced as target only for the taunt, not made an ordinary
  eligible aggressor afterward. On expiry reconsider legitimate aggressors or return; caster
  damage still provokes under item 8. Settles the former open boundary (`domain.md §3.2/§4/§5`).

### Open — decide before the named slice

Traversal items 1–5 are recorded (item 4 corrected) and reviewed; evidence below.
Books/formulas items 1–3, artifact items 1–6, Assassin item 1 and Wand item 1 are recorded below,
not open questions. Persistence items 1–9 are recorded and reviewed above.
World bounds / resets items 1–4 are recorded below; no presented question remains.
Validation-contract mapping/source items 1–28 are historically recorded and verified below;
approved 29–31 are recorded and verified, with fresh independent review and parent checks below.
Items 33–35 are recorded and verified below; item 32's later approval is now recorded too.
**Items 36–45 recorded, independently reviewed and parent-verified.** (2026-10-05)
Recorded selections, canonical pointers and item 39's no-bug amendment: the 36–45 section below.
**46–52 recorded, independently reviewed and parent-verified.** Exact selections and receipts
are below; that historical batch left no unhandled selection.
Bows/Dungeon items 53/54 are recorded, independently reviewed and parent recording-verified.
Item 55 is recorded under standing sourcing-only approval, independently reviewed with no issues
and parent recording-verified. Item 56 is now recorded under the standing answer, independently
reviewed with no issues and parent recording-verified; its historical empty queue was deleted.
Current items 57–69 are handled, independently reviewed and parent-accepted; empty queue deleted.
Held Silk/Spinning Wheel findings remain HOLD, not
selections, refusals, new 27/36 ballots, changed game rules or whole-topic completion.
Context: ask by ~60%, handoff by ~85% (earlier with reserve), authorized checkpoint then STOP.
Daily food quantities and original Alpha/Steam
sleep-rate baseline/units (§5 items 10–11) remain research.
- [ ] **Validation-contract source research/attribution (2026-09-17 contract approved):**
  required paths/shapes, bounded source inheritance and check boundaries are recorded in
  `domain.md §5`; recorded source items add bounded evidence, not complete histories. Unsupported
  food release histories (`pet-food`) and remaining mixed-container histories (§5 item 7) are
  research, not guessed labels or new gameplay ballots. No whole-topic completion is claimed;
  direct data correction and enforcement remain separately unauthorized, with no migration or
  obsolete-format compatibility work.
- [ ] **Remaining uncertain facts:** verify or choose explicit hybrid defaults for swamp-lands
  identity, Lion tameability (`null` currently means untameable), resistance meaning and the
  gear-HP roll formula before their respective slices. Sources: `landscapes.json#swamp-lands`,
  `creatures.json#lion`, `stats.json`. D13 hitboxes and D15 armor are already designed, not open.

### Validation-contract source attribution — item 72 (2026-10-09)

**Selection:** auto-accepted under the exact current standing answer above, not a numbered
owner approval. Original proposal / selected option (inventory verbatim):

> Attribute pet joining the player's initial fight, T whistle recall, far-away teleport and short-time nearby return after going down. Approval versus Refusing: accepting adds sourcing to existing pet behavior; refusing declines that attribution only. Both leave pets unchanged.

**Application:** provisionally recorded in `ontology/domain.md §5 item 72` / §7;
independent review and parent acceptance pending. Retain the queue entry until all gates are
verified. No gameplay, labels, live-data change or new implementation debt; pet rules stand.
Writer evidence: `/tmp/pixlnd-source-item-72-N046fs/` (source identity/hashes, self-review,
raw commands/exits and exact unstaged/staged/committed diffs; actual commit/parent after commit).
Writer source/scope audit, simplify → ponytail-review, `git diff --check` and bounded ontology
validator passed (exit 0). Checks cover recording fidelity and existing loaded data, not historical
truth or new enforcement; no boot/gameplay suite needed. No independent review or publication claimed.

### Validation-contract source attribution — item 71 (2026-10-09)

**Selection:** auto-accepted under the exact current standing answer above, not a numbered
owner approval. Original proposal / selected option (inventory verbatim):

> Attribute the guide's left/right arrows centering the map view on previously visited biomes. Approval versus Refusing: accepting sharpens existing map-selector sourcing; refusing omits only this attribution. Neither changes exploration/gameplay.

**Application:** provisionally recorded in `ontology/domain.md §5 item 71` / §7;
independent review and parent acceptance pending. Keep the queue entry until all gates are
verified. No gameplay, labels, live-data change or new implementation debt.
Writer evidence: `/tmp/pixlnd-source-item-71-G3AH0R/` (source identity/hashes, self-review,
raw commands/exits and exact unstaged/staged/committed diffs; actual commit/parent after commit).
Writer source/scope audit, simplify → ponytail-review, `git diff --check` and bounded ontology
validator passed (exit 0). No independent review or publication is claimed. Checks concern
existing loaded data and recording fidelity, not historical truth or new enforcement;
no boot/gameplay suite needed.

### Validation-contract source attribution — item 70 (2026-10-09)

**Selection:** under the exact current standing answer above, not a numbered owner approval.
Original proposal / selected option (inventory verbatim):

> Attribute M-open, wheel-zoom, middle-click marker, right-click pan, left-click rotate and player markers visible on a zoomed-out minimap. Approval versus Refusing: accepting improves sourcing; refusing declines only this attribution. Both leave controls/gameplay unchanged.

**Fidelity clarification:** “player markers” means player-created POIs, not player positions;
retained queue clarification, not a new owner amendment. Canonical report/provenance/limits:
`ontology/domain.md §5 item 70` / §7. No gameplay, labels or live-data change; no new debt.
**Application:** provisionally recorded; independent review and parent acceptance pending.
Keep the queue entry until those gates and the item commit are verified. Writer evidence:
`/tmp/pixlnd-source-item-70-nAbRIi/` (source identity/hashes, self-review, raw checks/exits and exact
unstaged/staged/committed diffs). Actual commit/parent are retained there after commit; no
independent review or publication is claimed. Writer scope/source audit, simplify → ponytail-review,
`git diff --check` and bounded ontology validator passed (exit 0). Validator covers loaded data,
not historical truth; no boot or gameplay suite was needed for this documentation-only change.

### Verified sourcing batch 57–69 — closure receipts (2026-10-09)

All thirteen selections below were accepted **as proposed**, with no amendments or unresolved
dependencies, under the exact standing answer above. No numbered owner approvals are fabricated.
Setup commit `a9bfa1730466b89b759505fcc418a77fb0768771` (parent
`9afc31bb7e5c441e6abf969b95229f4a285a1ffa`) preserved them before canonical recording.
The original selected proposal paragraphs are retained below; their material limits and declaration
pointers remain canonical in the corresponding `ontology/domain.md §5` item, byte-unchanged by closure.
Original source shorthand: **G** = guide 3372/20077; **Q** = Deposit/Cotton `quantity.body`;
**F** = Fists `wiki-five.body`; **W** = Wraith/Wolf `fauna/wiki.body`; **A** = Alpacas/Snout
`fauna/wiki.body.json`. Exact paths, revisions and capture qualifications remain in per-item evidence.

| handled item | canonical pointer | verified item commit | parent |
|---|---|---|---|
| 57 | `ontology/domain.md §5 item 57` / §7 | `733b535515962fcf2f4dcd5ae0c3bed5428cda0a` | `a9bfa1730466b89b759505fcc418a77fb0768771` |
| 58 | `ontology/domain.md §5 item 58` / §7 | `6617f1745f5a97842c8b7ed9db60323d2f5e9eae` | `733b535515962fcf2f4dcd5ae0c3bed5428cda0a` |
| 59 | `ontology/domain.md §5 item 59` / §7 | `8f61059bc87e7331c7aad3a55a2dcfbaa4c59e4e` | `6617f1745f5a97842c8b7ed9db60323d2f5e9eae` |
| 60 | `ontology/domain.md §5 item 60` / §7 | `cb7103f730215f001e298af3b8a4b271b613ef94` | `8f61059bc87e7331c7aad3a55a2dcfbaa4c59e4e` |
| 61 | `ontology/domain.md §5 item 61` / §7 | `fda698c9af5a8107fbd5d005f98a6cca67e8af1f` | `cb7103f730215f001e298af3b8a4b271b613ef94` |
| 62 | `ontology/domain.md §5 item 62` / §7 | `74857fffe8b562327fc749b0913099a583c5020d` | `fda698c9af5a8107fbd5d005f98a6cca67e8af1f` |
| 63 | `ontology/domain.md §5 item 63` / §7 | `fbfe4e1095c59e7f28d05bc1528527e11be7908d` | `74857fffe8b562327fc749b0913099a583c5020d` |
| 64 | `ontology/domain.md §5 item 64` / §7 | `88ec97be2f098ca2b46a3c0979743a209ea79778` | `fbfe4e1095c59e7f28d05bc1528527e11be7908d` |
| 65 | `ontology/domain.md §5 item 65` / §7 | `2103d468c22eb771a9c77b9b7a6cb40b4335a038` | `88ec97be2f098ca2b46a3c0979743a209ea79778` |
| 66 | `ontology/domain.md §5 item 66` / §7 | `2df243dbdbff99f316f34b201e81b111e3b66aef` | `2103d468c22eb771a9c77b9b7a6cb40b4335a038` |
| 67 | `ontology/domain.md §5 item 67` / §7 | `693428c78dbd882f5158abd83a5bd8d897feec2a` | `2df243dbdbff99f316f34b201e81b111e3b66aef` |
| 68 | `ontology/domain.md §5 item 68` / §7 | `4fc9037a3b3be0852745c300dce4444eb29116e0` | `693428c78dbd882f5158abd83a5bd8d897feec2a` |
| 69 | `ontology/domain.md §5 item 69` / §7 | `213e3c2fcedd3df93f8335cf5e4d9e12434fe9a1` | `4fc9037a3b3be0852745c300dce4444eb29116e0` |

**Recording review/acceptance:** fresh independent `source-batch/review.md` under managed run
`bea45c91-48b4-4c06-bcc6-6ee0e5c233d2` found **no issues** (OK with notes). Reviewer inspected
retained public raw sources, complete patches and receipts, but executed no commands/tests/hash
calculations/byte comparisons. Parent accepted all items after its own actual-Git/source/semantic
inspection and fresh scope/preservation/exact-diff audit, whitespace, bounded validator and boot:
`/tmp/pixlnd-sourcing-parent-01a121a6/{audit,diff-check,validator,boot}.log/.exit`, all exit 0.
Parent audit compares each saved full-index binary unstaged/staged/committed diff against actual Git;
`commit-chain.txt` holds the chain. `dispatch-manifest.json` / `dispatch-serial-check.log/.exit`
verify thirteen distinct serial completed item workers; fresh-context requests are parent-attested,
not independently established by the manifest. All item whitespace/validator gates passed; item
writers ran no boot/gameplay/visual/multiplayer checks. Initial diagnostic/tooling failures for
58 (heading index), 60 (hardcoded Git path) and 65 (JSON shape) remain preserved with
supervisor-authorized successful corrections. They are not retroactively initial successes.

**Closure:** parent explicitly accepted before mutation, authorized receipt/status-only closure,
and all handled queue entries are removed; the empty queue is deleted. Original queue remains in
setup/item Git history, not as a second completed ledger. Simplify → ponytail-review and fresh
scope/whitespace/bounded validator/boot gates, exact full-index binary diff/commit correspondence
and final Git receipts: `/tmp/pixlnd-sourcing-closure-01a121a6/`. Parent inspected closure commit
`6272a408cf5733e71af6f9f53b05ccdaf670c416`, confirmed its exact saved/actual diff correspondence
and reran final whitespace/validator/boot successfully (`/tmp/pixlnd-sourcing-parent-01a121a6/final-*`).
This final-delta review is parent review, not a second independent review. The subsequent two-file
receipt update received parent simplify → ponytail-review and fresh `receipt-*` checks there.
Validator/boot concern existing loaded data/startup, not historical truth, Markdown or new enforcement;
no gameplay/visual/multiplayer suite or new repository test. No new source research, private
source/assets/build access, mechanics, JSON, labels, checker/code, publication or next-topic authority.

**Remaining evidence gaps:** original edition/build/release and food/taming/Leaf–Candy histories;
daily units, per-kind yields/odds, refining ratios, noncotton/weapon costs; roster/trait/population/
shipped-route/naming histories; unresolved controls, pet-command/scaling details, other UI/audio/
dialogue and original-sleep activation/healing/baseline/units. Silk/Spinning Wheel remain **HOLD**,
not new 27/36 ballots. All hybrid rules stand, including permanent regional-loss exclusion and
item 39's no-bug instruction. These accepted attributions do not finish the topic or create new
implementation debt. **No push authorized or attempted.**

### Validation-contract source attribution — item 69 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 69` / §7.

**Original proposal / selected:** attribute Cotton Armor 12947's (Q) opening: “Cotton Armor is
used by the Rogue and can be crafted at a Loom.”
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public Cotton Armor revision 12947, pageid 3327, edited 2019-10-01T14:48:24Z;
  `/tmp/pixlnd-reconcile-next.2F5qwV/items/quantity.body` / `quantity.{start,end,exit}` inspected,
  capture start/end 2026-10-05T15:13:10Z, exit0. Timestamps prove no release/build identity;
  edition-unscoped community attribution only. Writer receipts and exact item-commit
  correspondence: `/tmp/pixlnd-source-item-69/`.
- **Limits:** items 1–68 stand; no station, recipe,
  labels, live JSON, checker/code/tests or gameplay changes. Remaining histories stay research;
  regional loss excluded; never implement item 39's bug. No push.

### Validation-contract source attribution — item 68 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 68` / §7.

**Original proposal / selected:** attribute Snout Beetle 19194's (A) infobox `biome = Greenlands,
Hills` and “Snout Beetles are a type of aggressive ranged Beetle”.
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public Snout Beetle revision 19194, pageid 939, edited 2024-08-08T23:50:27Z;
  `/tmp/pixlnd-source-research-36.iKZQy6/fauna/wiki.body.json` / `wiki.{start,result}` inspected,
  capture start 2026-10-05T00:38:29Z, HTTP200/curl and jq exit0, not completion/release proof.
  Writer receipts and exact item-commit correspondence: `/tmp/pixlnd-source-item-68/`.
- **Limits:** items 1–67 stand. No exclusive habitat,
  combat distance, pack size, cadence, family inheritance, A/S dating or taming test inferred;
  no labels, live JSON, checker/code/tests or gameplay changes. Remaining histories and
  Silk/Spinning Wheel HOLD stand; regional loss excluded; never implement item 39's bug. No push.

### Validation-contract source attribution — item 67 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 67` / §7.

**Original proposal / selected:** attribute Alpacas 19894 (A): “Alpacas are passive wooly animals
abundant in the Snowlands, they can be found in all Landscapes except the Lava Lands.” / “Alpacas
are very common and appear in other landscapes such as Greenlands, forests and plains but are
most abundant in the Snowlands.” Preserve family-level/general wording against the dark Alpaca's
existing desert exclusion, not a correction of either individual roster.
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public Alpacas revision 19894, pageid 1351, edited 2024-08-19T19:14:57Z;
  `/tmp/pixlnd-source-research-36.iKZQy6/fauna/wiki.body.json` / `wiki.{start,result}` inspected,
  capture start 2026-10-05T00:38:29Z, HTTP200/curl and jq exit0, not completion/release proof.
  Writer receipts and exact item-commit correspondence: `/tmp/pixlnd-source-item-67/`.
- **Limits:** items 1–66 stand. No per-colour every-land
  guarantee, numerical abundance, new biome or A/S chronology inferred; no labels, live JSON,
  code or gameplay change. Remaining histories and Silk/Spinning Wheel HOLD stand.
  No external/private/assets/original-build action or push.

### Validation-contract source attribution — item 66 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 66` / §7.

**Original proposal / selected:** attribute Wolf 20167's (W) infobox Greenlands / Forests /
Snowlands, body “The Wolf is an untamable aggressive animal”, and Trivia “Apple Pie was
pre-conceptualized to tame a Wolf but never released.” Preserve the source's simultaneous infobox
`mount = ... Yes` / `food = n/a` as an unresolved juxtaposition, not riding permission or
demonstrated taming.
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public Wolf revision 20167, pageid 856, edited 2024-08-24T18:05:46Z;
  `/tmp/pixlnd-reconcile-next.2F5qwV/fauna/wiki.body` / `wiki.{start,result}` inspected,
  capture start 2026-10-05T15:12:55.340355+00:00, HTTP200/exit0, not completion/release proof.
  Writer receipts and exact item-commit correspondence: `/tmp/pixlnd-source-item-66/`.
- **Limits:** items 1–65 stand. No exclusive habitat,
  new biome, demonstrated build history, Alpha availability, successful taming or mount usability
  inferred. No labels, live JSON or code change; remaining histories and Silk/Spinning Wheel HOLD
  stand. No external/private/assets/original-build action or push.

### Validation-contract source attribution — item 65 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 65` / §7.

**Original proposal / selected:** attribute Wraith 20152's (W) infobox Dark Woods / Deadlands
and “The wraith will follow a player longer than other monsters and cannot die.” / “Pets will
not attack Wraiths even if the player attempts to attack them.”
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public Wraith revision 20152, pageid 3842, edited 2024-08-24T17:52:35Z;
  `/tmp/pixlnd-reconcile-next.2F5qwV/fauna/wiki.body` / `wiki.{start,result}` inspected,
  capture start 2026-10-05T15:12:55.340355+00:00, HTTP200/exit0, not completion/release proof.
  Writer receipts: `/tmp/pixlnd-source-item-65/`; initial JSON-shape inspection failure retained,
  supervisor-authorized bounded jq inspection succeeded. No raw normalization/equality claim.
- **Limits:** items 1–64 stand, including item 51.
  No exclusive habitat, quantified pursuit, immunity mechanism, undead inheritance or A/S dating
  inferred; no chase/pet behavior, labels, live JSON or code change. Remaining histories and
  Silk/Spinning Wheel HOLD stand. No external/private/assets/original-build action or push.

### Validation-contract source attribution — item 64 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 64` / §7.

**Original proposal / selected:** attribute Fists 20017 (F): “Fists are a type of one-handed …
Weapon”; “Fists are dual-wield metal weapons used by the … Rogue.”; “Daggers can also be worn
with Fists.”
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public Fists revision 20017, pageid 465, edited 2024-08-21T17:30:36Z;
  `/tmp/pixlnd-source-research-36.iKZQy6/food/wiki-five.body` / `wiki-five.meta` inspected,
  capture 2026-10-05T00:37:32Z–00:37:33Z, HTTP200/curl exit0. Raw quotation/identity checks
  and writer receipts: `/tmp/pixlnd-source-item-64/`. No envelope-equality or release-date claim.
- **Limits:** items 1–63 stand,
  including item 49; no general mixing, class/hand/stat/animation rule, edition/recipe inference,
  equipment implementation, labels, live JSON or code change. Approved equipment model/D6/Wand
  and Silk/Spinning Wheel HOLD stand. No external/private/assets/original-build action or push.

### Validation-contract source attribution — item 63 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 63` / §7.

**Original proposal / selected:** attribute Deposit 19729 (Q): “They are almost exclusively found
in caves and sometimes in underwater caves.” and “Unlike Iron, Silver and Gold, Gems like Emerald,
Sapphire and Ruby do not need refinement for Crafting.”
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public Deposit revision 19729, pageid 1206, edited 2024-08-11T20:49:24Z;
  `/tmp/pixlnd-reconcile-next.2F5qwV/items/quantity.body` and `quantity.{start,end,exit}` inspected,
  capture start/end 2026-10-05T15:13:10Z, exit 0. Raw quotations/identity checks and writer receipts:
  `/tmp/pixlnd-source-item-63/`. No derivative/envelope equality or release-date claim.
- **Limits:** items 1–62 stand,
  including 27/47; no all-gem, quantity or edition inference, deposit/refining rule, labels,
  live JSON or code change. No external/private/assets/original-build inspection or push.
  Remaining histories/quantities and Silk/Spinning Wheel HOLD stand; D6/Wand unchanged.

### Validation-contract source attribution — item 62 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 62` / §7.

**Original proposal / selected:** attribute G Pets and Pet Food: “In Alpha, pets had more features
such as hydration and XP.” / “On Steam pets take stats based on the players equipment rating.”
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public guide revision 20077, pageid 3372, Pets and Pet Food raw lines 98–99;
  `/tmp/pixlnd-source-item-62/` holds source checks and item receipts. Authoritative raw/extracted/TXT
  content agrees; envelopes differ and derived wikitext adds one LF. Documentary dates are not
  release dates; no external retrieval, original-build, image or asset inspection.
- **Limits:** items 1–61 stand; no exact hydration
  drain/refill/display, XP persistence, scaling formula, numerical rating contribution, Steam
  hydration/XP absence or patch-date proof. Generic unique-food wording is not re-recorded;
  F11/shared Bubble Gum and hybrid pet progression/persistence/traversal stand, regional loss
  excluded. No gameplay, labels, live JSON or code change; histories and Silk/Spinning Wheel HOLD stand.

### Validation-contract source attribution — item 61 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 61` / §7.

**Original proposal / selected:** attribute G Gameplay Notes' “On Steam, a few emotes exist such
as /sit, /wave and /dance.” Separately attribute Pets and Pet Food's “You can nickname a pet by
typing /namepet.”
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public guide revision 20077, pageid 3372, Gameplay Notes line 92 and Pets and Pet
  Food line 105; `/tmp/pixlnd-source-item-61/` holds source checks and item receipts. Authoritative
  raw/extracted/TXT content agrees; envelopes differ and derived wikitext adds one LF. Documentary
  dates are not release dates; no external retrieval, original-build, image or asset inspection.
- **Limits:** items 1–60 stand; `/sit` A? and all
  existing tags preserved. No `/pet` or Alpha emote proof, rename edition/argument/active-target/
  name-validation inference, command/chat/naming behavior, live JSON or code change.
  Remaining histories and Silk/Spinning Wheel HOLD stand.

### Validation-contract source attribution — item 60 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 60` / §7.

**Original proposal / selected:** attribute G Gameplay Notes: “On Steam, Healing while drowning
can keep you underwater longer.” and “On Steam, Holding a wall underwater will stop diving
stamina depletion.”
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public guide revision 20077, pageid 3372, Gameplay Notes raw lines 90–91;
  `/tmp/pixlnd-source-item-60/` holds source checks and item receipts. Authoritative raw/extracted/TXT
  content agrees; envelopes differ and derived wikitext adds one LF. Documentary dates are not
  release dates; no external retrieval, original-build, image or asset inspection.
- **Limits:** items 1–59 and swimming/drowning/
  climbing/Spikes rules stand; no refill, infinite survival or quantified movement rule adopted.
  No gameplay, labels, live JSON or code change. Remaining histories and Silk/Spinning Wheel HOLD stand.

### Validation-contract source attribution — item 59 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 59` / §7.

**Original proposal / selected:** attribute G Controls / Steam Version: “R” / “Special Skill” /
“Cast a special move every 30 seconds.” Record the broad 30-second wording as insufficient to
override skill-specific cooldown declarations.
- **Approval versus Refusing:** approval records the citation/limitation; refusal would leave
  it unrecorded, not select the opposite mechanic. Neither changes the approved player experience.
- **Evidence:** public guide revision 20077, pageid 3372, Controls / Steam Version raw line 40;
  `/tmp/pixlnd-source-item-59/` holds source checks and item receipts. Authoritative raw/extracted/TXT
  content agrees; envelopes differ and derived wikitext adds one LF. Dates are documentary,
  not release/introduction dates; no original build, image or asset inspection or external retrieval.
- **Limits:** items 1–58, individual cooldowns,
  hybrid slots and Assassin exception stand; no balance, controls, labels, live JSON or code change.
  Remaining histories and Silk/Spinning Wheel HOLD stand.

### Validation-contract source attribution — item 58 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 58` / §7.

**Original proposal / selected:** attribute both G Controls tables' exact “Mouse Wheel” /
“Dodge” / “Roll out of the way at the cost of stamina.” Preserve its underspecification against
the existing M3-while-moving dodge and wheel zoom declarations rather than remapping scrolling
to dodge.
- **Approval versus Refusing:** approval records the citation/uncertainty; refusal would leave
  it unrecorded, not select opposite controls. Neither changes the approved player experience.
- **Evidence:** public guide revision 20077, pageid 3372, Controls / Steam Version line 42 and
  Alpha Version line 75; `/tmp/pixlnd-source-item-58/` holds source checks and item receipts.
  Initial diagnostic failed on a hardcoded Alpha heading index; supervisor-authorized bounded
  inspection corrected the diagnostic to check section membership, which passed. Original failure
  retained. Authoritative content agrees; envelopes differ and derived wikitext adds one LF.
- **Limits:** no click-versus-scroll resolution,
  moving qualifier, numeric stamina or immunity proof follows. D13/D23 and items 1–57 stand;
  no controls, labels, live JSON or code change. Remaining histories and Silk/Spinning Wheel HOLD stand.

### Validation-contract source attribution — item 57 (2026-10-09)

- [x] **Handled:** original selection under the standing answer; canonical limits: `domain.md §5 item 57` / §7.

**Original proposal / selected:** attribute G's Controls tables for both Alpha and Steam:
`W, S, A, D` Movement (“Move the player with W, S, A, D.”), M World Map (“Open the World Map.”),
C Crafting (“Open crafting window.”), F Lantern (“Toggle your lantern.”), M1 Left-Click Normal
Attack / M2 Right-Click Special Attack (each “Depends on weapon and class.”). Separately attribute
Alpha-only G Special Item (“Toggle the item equipped in Special.”) and X Skills (“Open Skills
window, allocate skill points here.”).
- **Approval versus Refusing:** approval records this citation/uncertainty; refusal would leave
  it unrecorded, not select opposite controls. Neither changes the approved player experience.
- **Evidence:** revision 20077, pageid 3372; retained public guide Controls rows
  20/22/34/38/44/46/61/63/65/69/71/73/77/79. Source identity/content inspection and item receipts:
  `/tmp/pixlnd-source-item-57/`. Authoritative body/extracted/raw-TXT equality only; envelopes differ,
  derived wikitext adds one LF. No external/private/assets/original-build action or release-date proof.
- **Limits:** no controls, labels, live JSON or code change.
  Items 1–56, D13/D17, D20/D24 and Assassin exception stand; Silk/Spinning Wheel remain HOLD.

### Validation-contract source attribution — item 56 (2026-10-09)

**Exact owner standing answer:** “Auto-accept all items which are about the topic of augmenting the precision of sourcing or not.”
**Previously selected:** approve the sourcing-only refinement; no separate owner “56: Approved”
or amendment exists. Revision 20077's Controls tables describe Alpha R / Steam E Interact
(opening chests, talking to NPCs, picking up items) and Alpha Ctrl / Steam E Climb at a stamina
cost. Preserve Alpha pickup R versus `keybinds.json#pick-up.A` E; do not resolve the discrepancy,
hold/grab/Shift qualifiers, first appearance, patch date or demonstrated original-build behavior.
**Approval versus Refusing:** approval records precise sourcing; refusal leaves this refinement
unrecorded, not opposite keys. Neither changes D13's hybrid E interaction/pickup/climbing.
No unresolved dependency; no gameplay, labels, live JSON, checker/code/tests or publication authority.

| item | application | canonical pointer | commit receipt |
|---|---|---|---|
| 56 — Historical interaction/climbing reports | [x] recorded, independently reviewed, parent recording-verified, committed | `domain.md §5 item 56` / §7 | `39530b83d382e1021c49571bfc7d771e31a3979d` (parent `9ff53bbe3cd428f00eacd34e9272e4373e8dec19`) |

**Evidence/limits:** locally inspected only the retained public `dialogue-guide.body`,
`dialogue-guide.extracted.json`, `dialogue-guide.metadata.json` and `raw-revision-content.txt`
under `/tmp/pixlnd-source-precision.MIIiDU/evidence/`. Title/pageid 3372, revision 20077,
edit timestamp and authoritative content matched separately; edit/capture/community-report
limits follow item 55 below. No derived `.wikitext` byte-equality claim, raw normalization,
external fetch, browser/private DOM/assets/original-build action or whole-guide ancestry.
Fresh source/scope/semantic inspection, simplify → ponytail-review, diffs and bounded check
logs/exits: `/tmp/pixlnd-source-precision-56.bUj9em/`. Source/recording audits, `git diff --check`,
bounded validator (`validator.*`: ontology valid) and boot (`boot.*`) passed, all exit 0.
Godot checks cover existing loaded data/startup, not Markdown truth, historical behavior or new
enforcement; no gameplay/visual/multiplayer suite. Fresh independent review found **no issues**:
managed `source-56/review.md`, workflow `36445ecf-5aea-4596-b543-58fb66e0bc6b`, child
`62d3d5e4-1961-4582-b8cd-b67d45f6db07`. Reviewer inspected actual file seams, saved diffs/public
sources and receipts; ran no commands/tests, hashes or byte comparisons, and did not regenerate
Git diff or inspect the staged index. Parent accepted that review, inspected the actual diff and
personally verified scope/preservation, source identity/raw-content equality, whitespace,
bounded validator and boot (`parent-{recording-audit,source-inspection,diff-check,validator,boot}.log/.exit`, all 0).
Parent reviewed the receipt-status delta, ran simplify → ponytail-review and reran audit,
whitespace, bounded validator and boot (`parent-final-*`, all exit 0). Canonical §5 wording
remained exactly the independently reviewed text; this delta review was parent review, not a
second independent review. Exact reviewed/staged/committed diff and queue correspondence,
full hash/parent and clean worktree were then verified (`item56-*`). The item is handled;
selection and full receipt remain here and the empty pending queue is deleted.
Final receipt/queue-deletion delta: parent simplify → ponytail-review and bounded local gates,
retained as `closure-*`. Inspect actual Git for its checkpoint commit, not a publication claim.
No push authorized or attempted; no next topic or implementation.

### Validation-contract source attribution — item 55 (2026-10-05)

**Exact owner standing answer:** “If the items are about accepting or refusing to add more precision to the sourcing of a data, auto-approve it”.
Parent accepted item 55 under that answer; no separate owner “55: Approved” was given.
**Recommended / selected:** precisely attribute revision 20077's Steam F2 UI smaller/F3 bigger
(each not affecting minimap), F4 hide UI, F5 minimap smaller/F6 bigger to the existing historical
keybind cells and §3.7 option descriptions. `ui.json#options` is grouped context, not exact rows.
**Approval versus Refusing:** approval adds precise sourcing; refusal would leave this citation
unrecorded, not choose opposite controls. Neither changes the approved player experience.
No unresolved dependency; D17's hybrid F3 debug-menu and all earlier rules stand.

| item | application | canonical pointer | commit receipt |
|---|---|---|---|
| 55 — Historical Steam UI/minimap controls | [x] recorded, independently reviewed, parent recording-verified | `domain.md §5 item 55` / §7 | `cbe5a877ed5c668f4d7065795008a21c07cc530e` (parent `04548e20de6bf49b3e995c35464d205f8a2c2924`) |

**Evidence/limits:** `/tmp/pixlnd-source-precision.MIIiDU/`; exact proposal `proposed-item-55.md`,
retained public MediaWiki body/metadata and raw revision content under `evidence/`.
[How to play guide revision 20077](https://cubeworld.fandom.com/wiki/How_to_play_guide_for_Cube_World?oldid=20077),
Controls / Steam Version, edited 2024-08-22T18:15:12Z; prior capture request start/response end
2026-10-05T00:38:32Z. Community report, not a first appearance, patch date, demonstrated original
behavior or whole-guide ancestry. No re-fetch, browser control, images or build execution.
Raw JSON/extracted content exactly match; `.wikitext` has one additional terminal LF.
Initial local equality assertion failed (exit 1); parent authorized bounded diagnostic/comparison
(exit 0), retained in `initial-inspection-failure.md` / `local-{diagnostic,byte-diff}.*`, not erased
or called passing. Authority is the unnormalized raw revision content, not sidecar byte equality.

Per-item source/scope/semantic inspection, simplify → ponytail-review, raw diffs and command
logs/exits are saved outside the repo. Bounded validator and boot cover existing loaded data/
startup, not Markdown truth, historical behavior or new enforcement; results: `item-55-*` and
`final-*` receipts. Fresh independent recording review found **no issues**: managed
`precision/review.md` under run `04fed232-93d1-4614-a593-9078d1eb03d9`. Reviewer inspected current
Markdown, saved public source/diffs/receipts and Git refs; ran no commands, tests, hash calculations
or byte comparisons. Parent actual-item audit, bounded validator
and boot passed (`parent-item-{audit,validator,boot}.log/.exit`, all 0); exact acceptance/diagnostic
permissions: `parent-supervisor-receipts.md`.
Finalization independently verified actual branch/HEAD/parent, seven Markdown item paths,
matching actual/staged/committed diffs, source hashes and those receipts
(`finalization-inspection.py/.log/.exit`, 0). Item 55 is handled, reviewed and committed; completed
selection/standing answer/pointers/hash remain here and the empty pending-only queue is deleted.
Final receipt/queue-deletion delta uses simplify → ponytail-review; writer checks/diffs are
retained as `finalization-*`. Parent accepted the independent item review, inspected the actual
final delta and reran scope/preservation audit, whitespace, bounded validator and boot
(`parent-final-{audit,diff-check,validator,boot}.log/.exit`, all 0). This delta review was parent
review, not a second independent review. Parent removed the redundant same-item draft HANDOFF
block, preserving earlier checkpoints; receipt-only closure gates/local commit evidence are
saved as `closure-*`. Inspect actual Git for the final local checkpoint commit. No push was
authorized or attempted; publication requires separate authorization.
No new controls, source labels, gameplay, live JSON, checker/code/tests or unrelated skill/food
claims. Silk/Spinning Wheel remain HOLD; remaining histories stay research, not topic completion.
Finalization writer did not stage, commit, push or rewrite history; parent owns the local checkpoint commit.

### Validation-contract source attribution — items 53–54 (2026-10-05)

**Exact owner answer:** “53: Approved; 54: Approved; When handled, handoff, commit, push”.
Both original proposals selected without amendments; items 1–52 and all settled hybrid rules stand.
**Exact selections:** “53: Approved”; “54: Approved”. No amendments or refusals.
**Approval versus Refusing:** approval adds bounded citations without changing the game;
refusal would leave attribution unrecorded, not select opposite ammunition/range/dialogue rules.

| item | application | canonical pointer | item commit receipt |
|---|---|---|---|
| 53 — Ranger firing and comparative range | [x] recorded, independently reviewed, parent recording-verified | `domain.md §5 item 53` / §7 | `1a4a282204201b7745fa788f56e19f2a19fc9a82` (parent `b1b5bceeb16afaffe326abaef405a4a8503d2c2f`) |
| 54 — NPC-attributed dungeon warning | [x] recorded, independently reviewed, parent recording-verified | `domain.md §5 item 54` / §7 | `553bf7253ef9f3223f31f1d3a9e130c8b71b0c07` (parent `1a4a282204201b7745fa788f56e19f2a19fc9a82`) |

**Selected limits:** 53 attributes arrow-direction/out-of-combat firing and **Bows AND Crossbows
reaching further than Boomerangs**; unlimited arrows corroborate the existing rule, not free M2,
numerical ranges, edition or first appearance. MP costs, tags and D24 movesets remain unchanged;
the direction sentence is not extrapolated to unrelated weapons. 54 selects the exact
**“Dungeons are a dangerous place. Don't forget to take some potions with you.”** / **“-NPCs”**
warning after **Conceptualized Content** and the adjoining early-2019 Instagram-preview sentence.
This placement does not classify the quote itself as conceptual-only or establish inspected preview,
shipped speaker, trigger, edition, release chronology, potion requirement or new quest. The existing
`npc-roles.json#dialogue-corpus.known-lines` already includes it; no dialogue delivery is added.

**Evidence/verification boundary:** `/tmp/pixlnd-reconcile-question-batch-53-54-01a10dd7/recording/`.
Binding brief and exact `presented-batch.md` are beside it. Queue-only parent commit:
`b1b5bceeb16afaffe326abaef405a4a8503d2c2f`; original source baseline:
`66c179bd8186d093daa615512987cc6890b0c9c1`. Per-item source/semantic/scope inspection,
simplify → ponytail-review, raw matching `git diff --binary --full-index` unstaged/staged/committed
diffs, comparisons, command logs/exits and full commit map are external receipts, not history proof.
Checks: `git diff --check`, bounded `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`
and final `timeout 150 nix develop -c godot --headless --quit`; inspect actual logs for outcomes.
Both writer whitespace/scope/staged gates and bounded validators passed, exit 0 (`ontology valid`);
`item-{53,54}-{unstaged,staged,committed}.diff` match via `item-{53,54}-compare-*.log/.exit` (0).
Writer final audit/boot passed (`final-{audit,boot}.log/.exit`, 0). Fresh independent recording review
found **no issues**: managed `recording-53-54/independent-review.md` under run
`34c2739f-548a-4cf2-9992-96e213261913`. Reviewer inspected actual current files, public sources,
actual/saved diffs and execution receipts; ran no commands/tests/hash calculations/byte comparisons.
Parent accepted that verdict, inspected actual aggregate Git diff, personally reran recording audit,
bounded validator and boot, and read full logs: `parent-{audit,validator,boot}.log/.exit`, all 0;
actual-Git evidence: `parent-actual-git/`. All selected entries are handled; completed receipts stay
here and the empty pending-only queue is deleted with parent authorization.
Checks cover existing loaded data/startup and recording fidelity, not prose history, original builds
or new policy enforcement. No broad gameplay/browser, visual or multiplayer tests.
Finalization delta uses simplify → ponytail-review and writer gates (`finalization-*`). Fresh final
handoff review found **no issues** (`recording-53-54/handoff-review.md` under the same managed run);
reviewer inspected current files/actual diffs/receipts, ran no commands/tests/hash/byte comparisons.
Parent confirmed exact reviewed-draft correspondence (`parent-reviewed-handoff-comparison.*`, 0),
inspected the delta and personally reran final scope/receipt audit, whitespace, bounded validator
and boot (`parent-final-{audit,diff-check,validator,boot}.log/.exit`, all 0). Receipt-only final
rechecks: `publication-ready-*`; final commit/push/equality/clean-state evidence: `publication.*`.
This records preparation before final commit/publication after item54; inspect actual Git/receipts,
not this snapshot as push-success proof. No new questions, research or implementation.

Only public-safe `article-extracts/{bows,dungeon}.{txt,json}`, their `.txt.sha256` and `manifest.json`
under `/tmp/pixlnd-reconcile-source-53.VnWRKF/` were authorized for inspection/reproduction.
No original authenticated DOM/owner HTML, tokens, account data or original hashes may be opened or
published. These are rendered-DOM article extracts, not raw HTTP entities; revision pins come
from captured metadata, not separate pinned-URL retrievals. Modification timestamps unavailable;
capture dates are not release dates. No external retrieval, browser or preview/assets/build execution.
Six authorized Markdown paths only; no gameplay/live JSON/checker/test/source-label/schema/
compatibility/migration changes or changelog. Silk/Spinning Wheel quantities stay HOLD, not refusal;
no duplicate 27/36 ballot or station correction. Food/yield/odds/roster/trait/population/route/naming/
other UI/audio/dialogue/original-sleep histories remain research. No new items or topic advancement.
Parent owns final handoff/commit/publication and STOP; child does not push or rewrite history.

### Validation-contract source attribution — items 46–52 (2026-10-05)

**Exact owner answer:** “46: Approved; 47: Approved; 48: Approved; 49: Approved; 50: Approved;
51: Approved; 52: Approved; When handled, handoff, commit, push”. All original proposals selected
without amendments; items 1–45 and all hybrid rules stand. Documentation attribution only:
no gameplay, JSON, tests, checker, research dumps, labels, defaults, balance, schema, migration
or compatibility changes. Parent owns final handoff, receipts and authorized publication.

**Approval versus Refusing:** approval records bounded reports without changing the game;
refusal would leave citations unrecorded, not select opposite mechanics.

| item | application | canonical pointer | item commit |
|---|---|---|---|
| 46 — Questionable Iceflower conversion report | [x] recorded, reviewed, parent-verified | `domain.md §5 item 46` / §7 | `05f1c24e3ca3d6ac0ccbd51758d0f4983d95799a` |
| 47 — Deposit nuggets, not a range for every gem | [x] recorded, reviewed, parent-verified | `domain.md §5 item 47` / §7 | `3898824cbb8d22473acbd66a6954d233c18b030c` |
| 48 — Iron armor ingredients, not quantities | [x] recorded, reviewed, parent-verified | `domain.md §5 item 48` / §7 | `5392ffe91d3ffe3d0e72f014b988fda5194ef2ba` |
| 49 — Fist materials, not a crafting bill | [x] recorded, reviewed, parent-verified | `domain.md §5 item 49` / §7 | `581e2c7b6edb0e97a27396291104a0f28e585816` |
| 50 — Individual Baby Mammoth habitat and grouping report | [x] recorded, reviewed, parent-verified | `domain.md §5 item 50` / §7 | `1d54f93f1318c2e02768eab5061ed1bd34b452d4` |
| 51 — Wraith swiping sound when attacking | [x] recorded, reviewed, parent-verified | `domain.md §5 item 51` / §7 | `66eba3f4ed20aa8c1cfb8f05a6761d4117165c6a` |
| 52 — Reported Wolf absence from Steam | [x] recorded, reviewed, parent-verified | `domain.md §5 item 52` / §7 | `11474ea81ee6d565fcf9dfd7b9db42b48180760f` |

**Verified recording checkpoint:** initial queue commit `fd6e77b4de63aa54cf86974da34d3f3e7d64f84b`;
all seven item commits above verified against saved unstaged/staged/committed binary/full-index
diffs. Fresh independent recording review found no issues (`independent-review.md`); reviewer
inspected actual current files, raw sources, saved diffs/logs and Git refs, but ran no commands,
tests, hash recalculations or byte comparisons. Parent inspected the actual aggregate Git diff
and reran the eight-commit/scope/source/preservation audit (`parent-audit.log/.exit`, exit 0),
confirming all saved diffs exactly match Git and prior rules/approvals remain unchanged. Parent
reran bounded validator and headless boot successfully (`parent-{validator,boot}.log/.exit`, exit 0).
All selected entries are handled; receipts stay here and the empty pending queue is deleted.

**Evidence:** `/tmp/pixlnd-reconcile-next.2F5qwV/recording/`: raw source snapshots/hashes/sidecars,
per-item semantic/scope → local `/simplify` prompt → installed ponytail-review, seven passing
validators, whitespace/scope/staged gates, exact diffs/comparisons and full commit map. Commands:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Checks cover existing loaded data/startup, not historical truth, Markdown or new enforcement.
Research retrieved six wiki pages in two bounded requests; recording/review used saved bodies,
including retained Iron Armor/Fists, without external re-fetch. No audio/images/assets/original-build
execution, gameplay suite, visual or multiplayer checks. Local Nix-path/no-index gate failures and
supervisor-authorized same-protocol corrections remain in `setup-correction.md`; no validator failed.
Final status/queue/HANDOFF changes receive simplify → ponytail-review and bounded rechecks
(`handoff-review.md`, `handoff-{diff-check,validator,boot}.log/.exit`). Normal-push only the authorized
branch, verify fresh remote/upstream/local equality and clean state, then STOP. No new research or
proposals; unsupported histories remain research, not whole-topic completion or implementation.

### Validation-contract source attribution — items 36–45 (2026-10-05)

**Exact owner answers:** “36: Approved; 37: Approved; 38: Approved; 39: Approved (I don't want
a bug implemented); 40: Approved; 41: Approved; 42: Approved; 43: Approved; 44: Approved;
45: Approved”. Selected boundaries are recorded in the canonical sections below.
Items 1–35 and all hybrid rules stand.
Documentation attribution only; no gameplay, JSON, tests, checker, research dumps, labels,
defaults, balance, schema, migration or compatibility changes.

**Approval versus Refusing:** approval records the selected reports/limits without changing the
game; refusal would leave those citations unrecorded, not select opposite mechanics.

| item | application | canonical pointer | item commit |
|---|---|---|---|
| 36 — Cobweb processing at a Spinning Wheel | [x] recorded, reviewed, parent-verified | `domain.md §5 item 36` / §7 | `7d7d8cec99d1abd4dea0337693455918de3ad39c` |
| 37 — Reported Lollipop from an Emerald Deposit | [x] recorded, reviewed, parent-verified | `domain.md §3.4 pet-food` / §7 | `0b1a33c255b3b9045cd01cf0c2d77541f367ac4f` |
| 38 — Six reported shop-food names | [x] recorded, reviewed, parent-verified | `domain.md §3.4 pet-food` / §7 | `4781cf13d387b164ceea503e42d41fbfaa8f7076` |
| 39 — Snout Beetle traits and a visual bug report | [x] recorded, reviewed, parent-verified | `domain.md §5 item 39` / §7 | `86fd41245828e24db658e014edbbea28805c1d58` |
| 40 — Undead villagers versus population speculation | [x] recorded, reviewed, parent-verified | `domain.md §5 item 40` / §7 | `b7d028e82fefc6281c7f4f30e8e05ba8a49b3ef8` |
| 41 — Some mobs bring out lanterns | [x] recorded, reviewed, parent-verified | `domain.md §5 item 41` / §7 | `85fd5cb051f4efba5c568909e867ef4cfdb2847a` |
| 42 — Individual dark-Alpaca habitats | [x] recorded, reviewed, parent-verified | `domain.md §5 item 42` / §7 | `ecda216abc2b5ba6ed12a98768b80766b31a3cd3` |
| 43 — Possessive item-name examples | [x] recorded, reviewed, parent-verified | `domain.md §5 item 43` / §7 | `9684a19bb6f0ed252f278551ce16feddba8b64b7` |
| 44 — Retrieved music catalog, not authenticated shipped soundtrack | [x] recorded, reviewed, parent-verified | `domain.md §5 item 44` / §7 | `a5a660e4b2e2f591ce6a072b6df84228cca29fef` |
| 45 — Additional Item Vendor stock report | [x] recorded, reviewed, parent-verified | `domain.md §5 item 45` / §7 | `7476eb20ecc0817b1b792f970ef44dec65fa4dd7` |

**Final verification checkpoint:** initial protocol/queue commit
`6bb47a1aa603f17c35492d7023f5f10be7d7d96d`; final item HEAD `7476eb20ecc0817b1b792f970ef44dec65fa4dd7`.
All ten selected entries are applied; no approved-but-unhandled item remains. Fresh independent
saved-source/current-file/diff/log review found no issues (`independent-review.md`); reviewer ran
no commands/tests or byte comparisons. Parent inspected actual commits and confirmed all eleven
initial/item commits match saved unstaged/staged/committed binary/full-index diffs exactly
(`parent-audit.log/.exit`, exit 0), including the reviewed three-file draft. The initial parent
quote-count assertion missed Markdown line wrapping; failure retained, semantic assertion fixed,
all Git comparisons unchanged. Writer's prior-canonical/scope/catalog audit also passed.
Parent reran bounded validator and headless boot (exit 0; `parent-{validator,boot}.log/.exit`).
Boot's ignored Nix SQLite-busy warning preceded successful Godot startup. These checks cover
existing loaded data/startup, not historical truth or new enforcement. Final handoff/publication
is authorized only on `fix/ontology-reconciliation`: normal push, verify fresh remote = upstream
= local HEAD and clean worktree, then STOP. This checkpoint is not a publication claim.

**Writer gates/evidence:** `/tmp/pixlnd-source-research-36.iKZQy6/recording/` contains actual
saved-source excerpts/hashes/sidecars, per-item semantic/scope → simplify → ponytail-review notes,
`item-N-{diff-check,validator}.log/.exit`, exact binary/full-index `item-N.diff`,
`item-N-staged.diff`, `item-N-committed.diff`, comparison logs/exits and full `item-N.sha`.
Queue statuses become applied only after checks. Validator covers existing loaded data, not
Markdown, historical truth or new enforcement. No external retrieval, images/audio/original
build execution, gameplay suite, visual or multiplayer checks. Fresh independent recording
review and parent verification passed as recorded above; final publication must be verified.
No new research or proposals.
Local extractor correction was supervisor-approved; failed assumption/reproduction and corrected
raw inspection remain in `extraction-authorization.md`, `source-extraction-failure.log/.exit`
and `raw-wiki-inspection.json`; no external retry or source edits.

### Validation-contract source attribution — item 32 (2026-10-05)

**Exact owner answer:** “32: Approved; Once handled, handoff, commit, push”.
**32 — One pet-food type is not one purchasable unit:** [x] recorded in `domain.md#pet-food`
and §7. Attribute Pet Food revision 20438's daily stocked-type wording, not a quantity limit;
select neither one-unit purchases nor unlimited stock. Existing carrying rules, F11 Banana
Mash and shared Bubble Gum/subtype 19 from Collie stand. Five existing Markdown paths only;
no gameplay, JSON, tests, checker, research, labels, defaults, schema or compatibility changes.

**Approval versus Refusing:** approval documents the type/quantity distinction without changing
stock or purchases; refusal would leave attribution incomplete, not approve a one-unit limit.
Unsupported histories stay research, not whole-topic completion or implementation permission.

**Evidence and gates:** `/tmp/pixlnd-source-item-32.HS00mX/` holds the binding approval brief,
saved-source extraction/hashes and item diff/review/check evidence. Raw Pet Food revision
20438 body/metadata and capture sidecars were inspected, not externally re-fetched, image-inspected
or original-build executed. Edit/capture timestamps do not prove release history.
Semantic/scope inspection, `/simplify` then ponytail-review, `git diff --check` and the bounded
ontology validator passed (exit 0, `ontology valid`; `item-32-{diff-check,validator}.log/.exit`).

**Item-to-commit evidence:** `9453260de4c09fa3dc5d9c07a93f3e9b70c194db` records item 32;
`item-32.sha` stores its full hash; saved/staged/committed diffs match exactly. Parent checked
the actual commit and five-path boundary, then reran headless boot
successfully (exit 0; `parent-boot.log/.exit`). Fresh independent saved-source/diff/log review
found no issues (`independent-review.md`); reviewer ran no commands/tests or byte comparisons.
Parent confirmed the reviewed draft's exact diff correspondence, reran bounded ontology
validation and boot (exit 0; `post-review-{validator,boot}.log/.exit`), then added only completion
receipts to the final record.
Final record received `/simplify`, ponytail-review and bounded diff/validator/boot rechecks
(`handoff-review.md`, `handoff-final-{diff-check,validator,boot}.log/.exit`). Separate handoff
commit/publication/STOP authority and next resume: `docs/HANDOFF.md`; pre-publication live
remote `b7f2d1f` confirmed, not a publication claim. No unanswered proposal or new research.
Checks cover existing loaded data/startup, not prose/history, purchase quantities or new
enforcement. No gameplay suite, visual or multiplayer checks are claimed.

### Historical validation-contract source attribution — items 33–35 (2026-10-04)

**Exact owner answer:** “33: Approved; 34: Approved; 35: Approved; When handled, handoff, commit, psh”.
Parent interprets `psh` as push; writer does not push. **32 remains PRESENTED BUT UNANSWERED**,
verbatim in `docs/HANDOFF.md`, not refused or held implementation. Items 1–31 and hybrid rules stand.
Only approved source reports/limits in five existing Markdown paths; no gameplay, JSON, tests,
checker, research, labels, defaults, schema, compatibility or migration changes.

| item | application | canonical section | commit evidence |
|---|---|---|---|
| 33 — Slime habitat/colour reports | [x] recorded and verified | `domain.md §5` / §7 | d48a3eda9faaac7936b0bb21d30364b839a998ca |
| 34 — Individual Runner habitat reports | [x] recorded and verified | `domain.md §5` / §7 | 7ee7b2044329320edbf3cbdddbc348baad3a2882 |
| 35 — Limited HUD/placement disagreement | [x] recorded and verified | `domain.md §5` / §7 | 6687547d831c69d8a232fde0aaa219a012e4b89f |

**33 — Approval versus Refusing:** approval adds bounded habitat evidence without changing
encounters; refusal would leave it unrecorded, not select snow-only Blue Slimes.

**34 — Approval versus Refusing:** approval makes individual memberships traceable, moving
no species and changing no foods; refusal would leave citations unrecorded, not select other habitats.

**35 — Approval versus Refusing:** approval records descriptions/uncertainty, changing no layout
or controls; refusal would leave attribution unfinished, not choose an alternative layout or limit.

**Writer evidence/gates:** `/tmp/pixlnd-source-resume-32-35.RySLWG/recording/` holds source
extractions (`item-N-source.txt`, raw source paths/hashes in `source-sidecars.log`), semantic/scope
inspection, `/simplify` then ponytail-review (`item-N-review.md`), exact binary/full-index
`item-N.diff`, `item-N-staged.diff`, `item-N-committed.diff`, comparisons, full `item-N.sha`,
`commit-map.md` and aggregate `batch.diff`. Each recorded item is gated before commit by
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`;
actual logs/exits: `item-N-{diff-check,validator}.log/.exit`, not prior batches' proof.
Validator covers existing loaded data, not prose/history or new enforcement. Saved captures
inspected, not externally re-fetched, image-inspected or original-build executed; capture timing
is not response completion or release evidence. No boot, gameplay suite, visual or multiplayer
checks by this writer. Initial extraction exit 5 is preserved in `source-inspection-failure.log/.exit`;
supervisor approved corrected local content/title extraction, not an external retry or missing-UI
inference (`extraction-authorization.md`). All three pre-commit validator runs exited 0 with actual
Godot output and `ontology valid`; saved/staged/committed comparisons also exited 0.

**Fresh independent review / parent verification:** read-only inspection of actual saved source
bodies, diffs and logs found no issues (`independent-review.md`); reviewer ran no commands, tests
or byte comparisons. Parent inspected the actual commits and source passages, confirmed all nine
saved/staged/committed diffs against Git, three-item order and the five-path boundary
(`parent-audit.log/.exit`, `parent-item-N-committed.diff`, `parent-batch.diff`), then reran:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
These cover existing loaded data/startup, not historical truth, prose or new enforcement.

**Final handoff/stop:** this separate verification record follows item `6687547`. Pre-publication
live remote `655d9eb` confirmed (`pre-publication-remote.log/.exit`); inspect actual Git state on
resumption. Final record received `/simplify`, ponytail-review and bounded diff/validator/boot
rechecks (`handoff-review.md`, `handoff.diff`, `handoff-{diff-check,validator,boot}.log/.exit`).
Commit the final handoff, normal-push only `fix/ontology-reconciliation`, verify fresh remote /
upstream / local equality and clean state, then STOP. No amendments, rewrite, merge, force-push,
new research or proposals. Item 32 alone remains the next exact unanswered question; broader
histories remain research, not whole-topic completion or implementation permission.

### Historical validation-contract source attribution — items 29–31 (2026-10-04)

**Exact owner answer:** “2ç: Approved; 30: Approved; 31: Approved; Keep the next items for
next agents (you're already at 86% of context); Once handled, handoff, commit, push.”
Parent explicitly read “2ç” as **29**; no approval extends to **presented but unanswered 32–35**.
Those exact proposals, alternatives/refusal consequences, examples and URLs are preserved in
`docs/HANDOFF.md`. All earlier approvals stand; documentation only, no whole-topic completion.

| item | application | canonical section | commit evidence |
|---|---|---|---|
| 29 — Early sleep instructions/clock estimates | [x] recorded and verified | `domain.md §5` / §7 | 9fee85b22523850f513be0038c9f5329127cf874 |
| 30 — Alpha-focused ten food/pet reports | [x] recorded and verified | `domain.md#pet-food` / §7 | 3df90bf5a76f011973fd662fd70438e7da76680f |
| 31 — Early Kaliptus Leaf availability report | [x] recorded and verified | `domain.md#pet-food` / §7 | fed80c6068705318286fcd9058a4983035cec3a9 |

**29 — Approval versus Refusing:** approval adds traceable sleep evidence, not controls,
healing numbers or a clock mechanic; refusal would leave the report unrecorded, not select
another rate or change approved free recovery/paid consensual inn services.

**30 — Approval versus Refusing:** approval improves attribution without changing obtainable
foods or tameable pets; refusal would leave the citation unrecorded, reject no existing pairing
and select no alternative food. Carrot/Bunny is an Alpha-focused report, not proof of carrot
supply or demonstrated taming in a particular original build.

**31 — Approval versus Refusing:** approval preserves the historical report/limits without making Leaf
playable; refusal would leave it unrecorded. Candy/Koala, cut Leaf and chronology stay unchanged.

**Writer evidence/gates:** `/tmp/pixlnd-source-next.X0mnCh/recording/` holds source inspection,
per-item semantic/scope/source review, `/simplify`, then ponytail-review (`item-N-review.md`),
exact binary/full-index `item-N.diff`, `item-N-staged.diff`, `item-N-committed.diff`, comparison
logs/exits, `item-N-{diff-check,validator}.log/.exit`, full `item-N.sha`, aggregate `batch.diff`
and `commit-map.md`. Per-item commands: `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd`; actual output/exits are
in those logs: all three exited 0, with actual Godot output and `ontology valid`, not old proof.
Validator checks existing loaded data, not prose/history or new
enforcement. Saved source bodies/metadata inspected, not externally re-fetched or original-build
executed; request-start capture times are not response completion. No images, full gameplay
suite, visual or multiplayer checks. Only five existing Markdown paths; no labels, JSON, gameplay,
tests, checker, research, schema/defaults or compatibility changes.

**Fresh independent recording review / parent verification:** read-only source/diff/log review
found no issues (`independent-review.md`); reviewer ran no commands/tests or independent byte
comparisons. Parent inspected actual commits/source passages and confirmed all saved/staged/
committed diffs, aggregate correspondence, exactly three item commits and the five-path boundary
(`parent-audit.log/.exit`, `parent-item-N-committed.diff`, `parent-batch.diff`), then reran:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
These cover existing loaded data/startup, not historical truth, Markdown or new enforcement.
Parent corrected the unanswered handoff copy to the actual chat presentation rather than its
semantically equivalent scratch draft; no recommendation, alternative or approval changed.

**Final handoff/stop:** this separate verification record follows item `fed80c6`. Live remote
`12aea8a` confirmed before publication (`pre-publication-remote.log/.exit`); inspect actual Git
state on resumption. Final record review/rechecks: `/simplify`, ponytail-review and bounded
diff/validator/boot (`handoff-review.md`, `handoff.diff`, `handoff-{diff-check,validator,boot}.log/.exit`).
Commit the final handoff, normal-push only `fix/ontology-reconciliation`, verify fresh remote /
upstream / local equality and clean state, then STOP. No amendments, rewrite, merge, new research
or proposals; next agent resumes unanswered **32–35 in Validation-contract source research/attribution**.

### Historical validation-contract source attribution — items 26–28 (2026-10-04)

**Exact owner answers:** “26: Approved; 27: Approved; 28: Approved”, then
“When handled, handoff, commit, push”. Evidence only; earlier approvals stand.
No presented unanswered proposal remains. Canonical content: `domain.md §5`, compact §7 index.

| item | application | canonical section | commit |
|---|---|---|---|
| 26 — Archived camp-bed sleep report | [x] recorded and verified | `domain.md §5` / §7 | 5383938b1cc0902f84c6e61928629ee94166dfcb |
| 27 — Qualitative refining chains | [x] recorded and verified | `domain.md §5` / §7 | ce0f13fb805f10d7782d57a1480a6ce7caac3aa6 |
| 28 — Golem AND Troll species reports | [x] recorded and verified | `domain.md §5` / §7 | af91552a17798d5ef3d0a203153e33a9301ea4d6 |

**26 — Approval versus Refusing:** approval adds the archived qualitative sleep/time/health
citation only; refusal would leave it unrecorded, not approve opposite sleep mechanics.
Free inn recovery and separate paid/consensual next-07:00 sleep/reset/payment stay unchanged.

**27 — Approval versus Refusing:** approval attributes qualitative refining chains without
quantities, silk-station attribution or release histories; refusal would leave citations
unrecorded, not change recipes or approve different conversions. D6 and approved weapon costs stand.

**28 — Approval versus Refusing:** approval makes named Golem/Troll descriptions traceable
without family/boss-wide traits, attacks, scaling or encounters; refusal would leave reports
unrecorded, not approve opposite creature behavior. Earlier family/species rules stand.

**Writer evidence/gates:** `/tmp/pixlnd-reconcile-source-resume.jldATd/` holds the binding
`approval-brief.md`, presentation, `inspected-sources.md`, `item-N-review.md` (semantic/scope/source,
`/simplify`, then ponytail-review), exact binary/full-index `item-N.diff`, `item-N-staged.diff`,
`item-N-committed.diff`, comparison logs, `item-N-{diff-check,validator}.log/.exit`, full commit
SHAs, `batch.diff` and `commit-map.md`. Each item passed `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` before its commit
(exit 0; Godot actually ran and reported `ontology valid`). Actual output/exits live in those logs.
Validation covers existing loaded data, not prose/history or new enforcement. Source bodies/metadata
inspected, not externally re-fetched or original-build executed; no images, full suite, visual or
multiplayer claim. Five existing Markdown paths only; no labels, live JSON, gameplay, tests,
checker, research, schemas/defaults or compatibility edits.

**Independent review / parent verification:** fresh read-only source/diff/log review found no
issues (`independent-review.md`); the reviewer ran no commands/tests or independent byte/hash
comparisons. Parent inspected actual commits/source passages and confirmed all saved/staged/
committed diffs, aggregate correspondence, three item commits and the five-path boundary
(`parent-audit.log/.exit`, `parent-item-N-committed.diff`, `parent-batch.diff`), then reran:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
The parallel boot logged an ignored Nix eval-cache busy notice; Godot still ran normally.
These checks cover existing loaded data/startup, not historical truth, prose or new enforcement.

**Final handoff/stop:** this separate verification record follows item `af91552`. Pre-publication
live remote `4aaea88` was confirmed (`pre-publication-remote.log/.exit`); inspect actual Git state
on resumption. Final record checks/evidence: `/simplify`, ponytail-review and bounded diff/validator/
boot rechecks (`handoff-review.md`, `handoff.diff`, `handoff-{diff-check,validator,boot}.log/.exit`).
Commit this handoff, push only `fix/ontology-reconciliation`, verify local/upstream/fresh live
remote equality and clean state, then STOP. No amendments, rewrite, merge, new research or proposals.
Remaining research is not an unanswered ballot; next title and unfinished histories:
`docs/HANDOFF.md` — **Validation-contract source research/attribution (remaining research)**.

### Historical validation-contract source attribution — items 22–25 (2026-10-04)

**Exact owner answer:** “22: Approved; 23: Approved; 24: Approved; 25: Approved;
When done, handoff, commit, push”. No presented unanswered proposal remains; evidence only.
Canonical content: `domain.md §5`; all earlier approvals stand.

| item | application | canonical section | commit |
|---|---|---|---|
| 22 — Existing rarity-prefix lists | [x] recorded and verified | `domain.md §5` / §7 | 3fba786f46f7fdaca40017b3d098f6be9f79d501 |
| 23 — Furniture-sleep reports | [x] recorded and verified | `domain.md §5` / §7 | c7e154b351e2fbf48edc34fc3a1a8e279ada7632 |
| 24 — Candle appearance/placement | [x] recorded and verified | `domain.md §5` / §7 | f66a329abf12eb10a21fc88d7abd979f3f7ca1d3 |
| 25 — Campsite furniture | [x] recorded and verified | `domain.md §5` / §7 | 0b5379f2b7fae0521cd61c57aed61611dbb9aaae |

**22 — Approval versus Refusing:** approval attributes existing prefixes without changing the
always-named equipment guarantee; refusal would leave the report unrecorded, not change names
or naming frequency.

**23 — Approval versus Refusing:** approval records furniture-sleep reports and uncertainty,
not controls, healing numbers or mechanics; refusal would leave them unrecorded, not approve
a rate or interpretation. The approved inn service remains unchanged either way.

**24 — Approval versus Refusing:** approval makes existing candle visuals/placement traceable
without lighting or placement changes; refusal would leave attribution unfinished, not remove
candles or select different colors.

**25 — Approval versus Refusing:** approval attributes limited campsite furniture without
requiring every camp to contain every object; refusal would leave the description unrecorded,
not select empty camps or another layout.

**Writer evidence/gates:** `/tmp/pixlnd-source-items-22-25.cMj0dO/` holds the binding
`approval-brief.md`, `inspected-sources.md`, exact binary `item-N.diff`, `item-N-staged.diff`,
`item-N-committed.diff`, `item-N-review.md` (semantic/scope/source inspection, `/simplify`, then
ponytail-review), `item-N-{diff-check,validator}.log/.exit`, comparison logs, full hashes and
`commit-map.md`. Each item passed `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` (exit 0; Godot actually
ran and reported `ontology valid`). Checks cover existing loaded data, not prose, historical
truth or new enforcement. Saved source bodies/metadata were inspected, not externally
re-fetched or original-build executed; images were not inspected. No gameplay suite, visual or
multiplayer tests, labels, JSON, research, checker, schema/default or compatibility changes.

**Independent review / parent verification:** fresh read-only source/diff/log review found
no issues (`independent-review.md`); the reviewer executed no commands/tests or independent
hash comparisons. Parent inspected actual commits/source passages and confirmed each exact
saved/staged/committed diff, aggregate reviewed-diff correspondence and five-path boundary
(`parent-audit.log/.exit`, `parent-item-N-committed.diff`, `parent-batch.diff`). The initial
byte-audit failure was abbreviated versus full-index diff headers, preserved in `parent-initial-*`
and resolved by using explicit `--full-index`; no content changed. Parent reran:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).

**Final handoff/stop:** this separate verification record follows item `0b5379f`. Pre-publication
live remote `dd8e1a5` was confirmed (`pre-publication-remote.log/.exit`); inspect actual Git state
on resumption. Final record checks: `/simplify`, ponytail-review and bounded diff/validator/boot
rechecks (`handoff-review.md`, `handoff.diff`, `handoff-{diff-check,validator,boot}.log/.exit`).
Commit this handoff, push only `fix/ontology-reconciliation`, verify local/upstream/fresh live
remote equality and clean state, then STOP. No amendments, rewrite, merge, new research or
proposals. Remaining research is not an unanswered ballot; next title and unfinished histories:
`docs/HANDOFF.md` — **Validation-contract source research/attribution (remaining research)**.

### Historical validation-contract source attribution — items 16–21 (2026-10-04)

**Exact owner answer:** “16: Approved; 17: Approved; 18: Approved; 19: Approved;
20: Approved; 21: Approved; When handled, handoff, commit, push”. Evidence only;
no presented unanswered proposal remains. Canonical content is in `domain.md`.

| item | application | canonical section | commit |
|---|---|---|---|
| 16 — Archived Koala report | [x] recorded and verified | `domain.md#pet-food` / §7 | b320426ef3354482c64e791790308a222c6d5c26 |
| 17 — Forest/Beetle reports | [x] recorded and verified | `domain.md §5` / §7 | 7d1f048d32f198c3450f0bffad67e948c1081b35 |
| 18 — Cotton quantities | [x] recorded and verified | `domain.md §5` / §7 | 2b36cf22b1993beae9d1a3a8b4dd4aadfa9a9636 |
| 19 — Stock/Leftovers reports | [x] recorded and verified | `domain.md §5` / §7 | 43f91475694a7bae8f3578e7f3d12bc93b8179fd |
| 20 — Population observations | [x] recorded and verified | `domain.md §5` / §7 | 6690c21ec758a9d1281bb5b536b515cdac9863c0 |
| 21 — Isolated NPC observations | [x] recorded and verified | `domain.md §5` / §7 | 5f9dcd04f6f4a812300e9633eccd60ae844cbd47 |

**16 — Approval versus Refusing:** approval records a dated report with no food identity,
without changing Koala's bait or resolving history; refusal would leave it unrecorded,
not approve another bait or history.

**17 — Approval versus Refusing:** approval records specific encounter reports without changing rosters;
refusal would leave attribution unrecorded, not choose an alternate roster.

**18 — Approval versus Refusing:** approval attributes existing cotton quantities without new recipes;
refusal would leave attribution unrecorded, not change crafting costs.

**19 — Approval versus Refusing:** approval records narrow economy reports without changing shops/rewards;
refusal would leave clauses unrecorded, not choose opposite economy rules.

**20 — Approval versus Refusing:** approval distinguishes observations from exhaustive rules without
changing settlements; refusal would approve neither all-human towns nor another population mechanic.

**21 — Approval versus Refusing:** approval records isolated observations and a hypothesis boundary
without schedules/rewards; refusal would approve neither another route nor a hint reward.

**Per-item evidence/checks:** `/tmp/pixlnd-source-reconciliation.j0nQEI/` contains the binding
`approval-brief.md`, inspected-source record, `item-N.diff`, `item-N-review.md` (semantic/scope,
`/simplify`, then ponytail-review), `item-N-{diff-check,validator}.log/.exit`, exact staged/committed
comparisons and `commit-map.md`. Each item passed `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` (exit 0; Godot actually ran
and reported `ontology valid`). Only five existing Markdown paths changed; no gameplay/JSON/
research/tests/checker work, labels, migration or compatibility. Captures were retrieved by source
scouts on 2026-10-04; recording/review inspected saved bodies, not freshly retrieved external
sources or original binaries. Revision/capture dates are not release or introduction dates.

**Independent review / parent verification:** fresh read-only source/diff/log review found no
issues (`independent-review.md`); the reviewer ran no commands or independent byte/hash comparisons.
Parent inspected actual commits and source passages, confirmed each exact saved/committed diff and
aggregate reviewed-diff correspondence with the five-path boundary (`parent-audit.log/.exit`,
`parent-item-N-committed.diff`, `parent-batch.diff`), and reran:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
These check existing loaded data/startup, not historical truth, prose semantics or new enforcement.
Source inspection is not original-binary execution; no gameplay suite, visual or network tests.

**Final handoff/stop:** this separate verification record follows item `5f9dcd0`. Pre-publication
live remote `6897bb1` was confirmed (`pre-publication-remote.log/.exit`); inspect actual Git state
on resumption. Final record receives `/simplify`, ponytail-review and bounded diff/validator/boot
rechecks, saved as `handoff-review.md`, `handoff.diff` and `handoff-{diff-check,validator,boot}.log/.exit`.
Commit this handoff, push only `fix/ontology-reconciliation`, verify local/upstream/fresh live remote
equality and clean state, then STOP. No amendments, rewrite, merge or new proposals.
Remaining research is not a presented ballot; **next resume topic: Validation-contract source
research/attribution (remaining research)** (`docs/HANDOFF.md`).

### Historical validation-contract source attribution — items 12–15 (2026-10-04)

**Exact owner answers:** “12: Approved; 13: Approved; 14: Approved; 15: clarify”, then after
full clarification **“15: Approved; When done, handoff, commit, push”**. All four approved;
clarification was not refusal/correction. No presented unanswered proposal remains.

| item | application | canonical section | commit |
|---|---|---|---|
| 12 — Pinned cuwo food names | [x] recorded and verified | `domain.md#pet-food` / §7 | cf1dfdd6e5556c5c2145037a15863c56a272a8d2 |
| 13 — Conflicting Koala-food reports | [x] recorded and verified | `domain.md#pet-food` / §7 | 9bec6abe4d4447ccaa7683059fec65dfaac25a46 |
| 14 — Ten existing S-food reports | [x] recorded and verified | `domain.md#pet-food` / §7 | f886f61f1275b08aa41b5dac9a9d08a24c0b7f0c |
| 15 — Three dated UI patch reports | [x] recorded and verified | `domain.md §5` / §7 | 39786bd6df451c829ce9bfe1a25f60f671e862fb |

**12 — Approval versus Refusing:** approval strengthens item 6's naming evidence without
changing foods/pets or Bubble Gum's approved pairing; refusal would leave the lead unchanged,
not select different pairings or history.

**13 — Approval versus Refusing:** approval records the Koala-food disagreement without
changing the planned Eucalyptus Candy offer; refusal would leave comparison unrecorded,
neither restore Kaliptus Leaf nor resolve history.

**14 — Approval versus Refusing:** approval makes existing bait choices traceable, including
Banana Mash/Warthog, without a new mechanic; refusal would leave attribution unrecorded
while all choices, F11 and shared Bubble Gum stand.

**15 — Approval versus Refusing:** approval gives existing interface history specific patch
citations, including highlighted teammate levels, without new interface work or restored `+`
equipment; refusal would leave citations unrecorded, not remove features or enable excluded gear.

**Per-item evidence/checks:** `/tmp/pixlnd-reconcile-research.7wbpsE/` holds the binding approval
brief, source checks, `item-N-review.md` (`/simplify`, then ponytail-review), exact binary
`item-N.diff`, `item-N-{diff-check,validator}.log/.exit`, commit SHA records and `commit-map.md`.
Each item passed `git diff --check` and bounded ontology validation (exit 0, Godot actually ran
and reported `ontology valid`). Five existing Markdown paths only; no gameplay/JSON/research/
test/checker changes or new labels. Require current rules, not migration or legacy formats.

**Independent review / parent verification:** fresh read-only source/diff/log review found no
issues (`independent-review.md`); reviewer inspected saved evidence, not independent Git hash
comparisons or rerun tests. Parent inspected actual commits/source passages, confirmed each exact
saved/staged/committed diff match and aggregate reviewed-diff correspondence with the five-path
boundary (`parent-audit.log/.exit`, `parent-item-N-committed.diff`, `parent-batch.diff`), and reran:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
These check existing loaded data/startup, not historical truth, prose consistency or new
enforcement. Source inspection is not original-binary execution; no gameplay suite, visual or
network tests.

**Final handoff/stop:** this separate verification record follows item `39786bd`. Pre-publication
live remote `d9d6d50` was confirmed (`pre-publication-remote.log/.exit`); inspect actual Git state
on resumption. Final record receives `/simplify`, ponytail-review and bounded diff/validator/boot
rechecks, saved as `handoff-review.md`, `handoff.diff` and `handoff-{diff-check,validator,boot}.log/.exit`.
Commit the handoff, push only `fix/ontology-reconciliation`, then verify local/upstream/fresh live
remote equality and clean state and STOP. No amendments, rewrite, merge or new proposals.
Remaining research / next title: `docs/HANDOFF.md` — **Validation-contract source research/attribution (remaining research)**.

### Historical validation-contract source attribution — item 11 (2026-10-04)

**Exact owner answer:** “11: Approved; When done, handoff, commit, push”. The preceding question
about cuwo was clarification, not refusal or correction: it is an open-source Alpha-server
reimplementation consulted as historical evidence, not code added to pixlnd.

**11 — Verified cuwo clock code and limits:** [x] recorded and verified in `domain.md §5` / §7;
commit **`dcb3cd1392fb2cc0ad60bcad7bcb7fe6b8d9a725`**.
Original Alpha/Steam sleeping behavior and item 10's historical units remain unresolved;
the canonical record supplies the revision, links and precise evidence limits.
**Approval versus Refusing:** approval records stronger evidence and its limits without changing
players' inn sleep (23:00 → 07:00); refusing would leave documentation/uncertainty unchanged and
approve neither sleep interpretation. No replacement rate, source labels or gameplay changes follow.

**Scope and evidence:** five existing Markdown paths only; no gameplay, live JSON, research dumps,
tests or checker changes. `/tmp/pixlnd-source-resume.mQxzUP/approval-brief.md` preserves the exact
approval/scope; `parent-source-verification.md` records direct source inspection and research reports.
The code was inspected, not executed; existing validator/boot checks cannot prove original-game
history or new enforcement. **Per-item checks:** semantic/scope inspection, `/simplify`, then
ponytail-review completed; `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (exit 0,
`ontology valid`; expected dirty-tree warning only). Evidence: `item-11-review.md` and
`item-11-{diff-check,validator}.log/.exit` in that scratch directory.

**Independent review / parent verification:** fresh read-only source/diff/log review found no issues
(`independent-review.md`); the reviewer ran no commands/tests or independent Git hash comparisons.
Parent inspected the actual commit, confirmed exact saved/committed diff correspondence and the
five-Markdown-path boundary (`parent-audit.log`, `item-11.diff`, `item-11-committed.diff`), and reran:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
These check existing loaded data/startup, not original-game history or new enforcement. No gameplay
suite, visual or network tests. Fresh external verification was source inspection of the named cuwo
revision only, not original binaries, Steam or execution of that reimplementation.

**Published handoff/stop:** verification/handoff **`eba48ac11c9dc6804c84cfabc64a60432352fe38`**
follows item `dcb3cd1`; both were pushed only to `fix/ontology-reconciliation`. `/simplify`,
ponytail-review and bounded diff/validator/boot checks passed; actual saved/committed diffs matched.
Parent verified local/upstream/fresh live remote equality and clean state. Evidence:
`handoff-review.md`, `handoff{,-committed}.diff`, `handoff-{diff-check,validator,boot}.log/.exit`,
`publication-{push,remote,verified}.log/.exit` under `/tmp/pixlnd-source-resume.mQxzUP/`.
This is a published checkpoint, not proof of future Git state. No merge or history rewrite.

### Historical handoff review only — then-unpresented research (2026-10-04)

**Owner scope:** “Your current objective is to handoff/review handoff. I'll start a new
reconciliation task with a new agent”. Resume/compaction notices had led to additional read-only
research, not authorized application. No question was presented, answered or applied; draft scratch
labels are not reserved ontology item numbers. This session finalizes/reviews the handoff and stops.

**Research leads, not approved claims:**
- Current Steam guide bodies list Eucalyptus Candy/Koala; the current Gamepressure article says
  Kaliptus Leaf/Koala. None establishes replacement/unused status or its chronology; the canonical
  retained notes and current cut status remain unchanged.
- Current Steam guide tables specifically report Banana Mash/Warthog and the nine other existing
  S-food pairings. These could support direct community-report attribution, not first introductions,
  Alpha absence, demonstrated per-food obtainability or successful taming. F11 and source labels stand.
- Fresh wiki revisions corroborate exact affix names and refining chains, but supply no new A/S
  ancestry or numeric 1:1 ratios. No additional question was manufactured from that corroboration.

**Inspect before proposing:** parent review `/tmp/pixlnd-food-source-resume.2AG0Nq/parent-source-review.md`;
food captures `/tmp/pixlnd-food-release.gG2cXa/`; wiki captures `/tmp/pixlnd-refining-affixes.hAwsyB/`.
Full scout reports live under
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/0bd89168-1d76-4027-914c-be2056eebd03/research/`
(`food-release.md`, `refining-affixes.md`). URLs/passages/revisions/HTTP outcomes are recorded there.
Steam guide IDs: `1873333729`, `1865509515`, `1879943518`; Gamepressure path:
`https://www.gamepressure.com/cubeworld/taming-and-locating-pets/zfca65`.
Current retrieved bodies are not archived versions; displayed post/update dates do not date row
additions, and guides need not be independent. Wiki edit timestamps are not release dates; an empty
2013 history response proves no absence. Parent inspected sources, not binaries or executed behavior.
Research-only phase left the repository clean and ran no tests. Fresh independent handoff review
found no issues; parent diff-check, bounded ontology validation and headless boot passed (exit 0).
The reviewer inspected saved evidence, not independent Git/remote state or rerun tests.
Evidence: `/tmp/pixlnd-handoff-scope-review.2nuw18/` (`independent-review.md`, check logs/exits).
No new canonical evidence claim is applied by this note.

**Historical next-agent instruction (superseded):** inspect remaining source gaps and await owner
answers before recording new proposals. At that checkpoint no item 12 or later was approved.
Do not advance to gameplay or Swamp Lands/Lion/resistance/gear HP. No presented unanswered item
remains; food and mixed-container histories, including original sleeping units, remain research.
Next title: **Validation-contract source research/attribution (remaining research)**.

### Historical validation-contract source attribution — items 8–10 (2026-10-04)

**Exact owner answer:** “8: Approved; 9: Why would the five-cube example replace the
twenty-cube wand recipe ?; 10: Approved”. After full clarification, the owner answered:
**“9: Approved; When done, handoff, commit, push, and state me title only of the next topic to
resolve, that a fresh agent might spawn on when running topic reconciliation again”.**
All three are recorded for documentation only, in commit order **8, 10, 9**; no history rewrite.

| item | application | canonical section | commit |
|---|---|---|---|
| 8 — Additional dated patch evidence | [x] recorded and verified | `domain.md §5` / §7 | 9cd1e38a1cb34825e5bf5cd3a882d689ba0efc34 |
| 9 — Encounter, crafting, shop and map reports | [x] recorded after clarification and verified | `domain.md §5` / §7 | b33f3fa2ac3d6463147800c18d4dc9b3c63075f7 |
| 10 — Historical sleep-speed wording | [x] recorded and verified | `domain.md §5`, `game-clock` / `c-time-speed` / §7 | f71f7ad7adc9126b8c732d4c9ecd1abcf754d913 |

**Item 8 — Approval versus Refusing:** approval makes precise patch history traceable,
including music-loop addition versus fix, without changing controls, recipes or audio.
Refusing would leave findings unrecorded, not remove/reject features. Canonical evidence and
limits are in §5; no fresh external verification or whole-topic completion is claimed.

**Item 10 — Approval versus Refusing:** approval prevents ambiguous historical sleep units
from becoming an implementation default; approved inn sleep is unchanged (23:00 → 07:00).
Refusing would leave the ambiguity unresolved, not approve either interpretation. §5 records
uncertainty, not a proven contradiction or replacement number; normal hybrid time remains 10×.

**Item 9 — approved after clarification:** the fully restated proposal was titled
**“9. Document specific historical reports without turning them into gameplay rules”.**
Approved pixlnd rules remain authoritative; historical examples do not override them, and
Omega-only features remain outside v1. §5 records exactly the named reports/sources/limits,
not whole-roster, recipe-table or interface attribution; broader histories remain unresolved.
**Approval versus Refusing:** approval records sources and limits without changing encounters,
costs, shops or map behavior or authorizing a new feature. Refusing would leave additional notes
unrecorded without changing settled gameplay or inferring an opposite rule.

**Historical clarification, now answered:** “Why would the five-cube example replace the
twenty-cube wand recipe ?” Response: “It wouldn’t. The five-cube example is a metal weapon,
while your approved wand recipe uses 20 wood cubes. There is no conflict; my comparison was
unnecessarily confusing.” The owner requested full restatement, then approved it above.
The question was not correction/refusal; no five-cube default or wand conflict is inferred.

**Evidence/gates:** `/tmp/pixlnd-source-record.6o6KXJ/` holds `approval-brief.md`, per-item
`item-N-review.md` (semantic/scope inspection, `/simplify`, then ponytail-review), binary
`item-N.diff`, `item-N-{diff-check,validator}.log/.exit`, commit records and `commit-map.md`.
Commands: `git diff --check`; `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`.
All three validators ran Godot, printed `ontology valid` and exited 0; expected dirty-tree warnings
only. Per-item diff checks passed. Writer reviews and earlier pending-item-9 notes describe their
then-current checkpoints, superseded by the final approval and independent review below.

**Independent review / parent verification:** fresh read-only source/diff/log review found no
issues (`independent-review.md`), without rerun commands or independent Git hash comparisons.
Parent inspected actual commits/source passages, verified each exact saved/committed diff and the
aggregate reviewed-diff match, and confirmed only five permitted Markdown paths changed
(`parent-audit.log/.exit`, `parent-item-N.diff`, `parent-batch.diff`). Parent reran both commands:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
These check existing loaded data/startup, not historical truth, prose semantics or new enforcement.
No gameplay suite, visual or network tests; preceding external cuwo retrieval timed out without a
revision/payload, so no fresh external-source verification is claimed. Gameplay, live JSON,
research dumps, tests and checker files remain unchanged; no migration/compatibility code is needed.

**Final handoff/stop:** this verification record follows item `b33f3fa`. Pre-publication live remote
`9ccffb4` was confirmed with `git ls-remote` (`pre-publication-remote.log/.exit`); inspect actual Git
state on resumption. The final record receives `/simplify`, ponytail-review and bounded rechecks,
saved as `handoff-review.md`, `handoff.diff` and `handoff-{diff-check,validator,boot}.log/.exit`.
Commit the final handoff, push only `fix/ontology-reconciliation`, then verify local/upstream/live
remote equality and clean state and stop. No merge, rewrite or new proposals. Exact remaining
research: `docs/HANDOFF.md`; next title: **Validation-contract source research/attribution (remaining research)**.

### Historical validation-contract source attribution — approved items 5–7 (2026-10-04)

**Exact owner answers:** “5: Approved; 6: Define an evidence and an assumtion quickly, how
they materialise in the ontology, then re-state the question with another example, eventually
quote doclinks; 7: Approved”. After clarification: **“6: Approved; When done, handoff,
commit, push”**. The clarification was not rejection or correction; all three are approved.
Items 1–4 and their 2026-09-28 dates stand.

| item | application | canonical section | commit |
|---|---|---|---|
| 5 — Pet-food count | [x] recorded and verified | `domain.md#pet-food` / §7 | e575f22a4c271d6f77dcc86af77d0d44c3ffd1ff |
| 6 — Food-history evidence and limits | [x] recorded and verified | `domain.md#pet-food` / §7 | 73ae633587d7a6d0c508297b3d3aa1fc585240e1 |
| 7 — Narrow mixed-source subfacts | [x] recorded and verified | `domain.md §5` / §7 | 0531ca460480a7829b9df67caf66323544faa56e |

**Item 5:** corrected the summary to 58 obtainable + five cut. Original JSON count and the
older six-name research lists were inspected directly; Banana Mash is the overlap, not a missing
cut entry. **Approval versus Refusing:** approval aligns documentation with F11; refusal would
leave the count contradiction, not authorize cutting Banana Mash or inventing food.

**Item 6 clarification and approval:** evidence supports a specific traceable claim; an
assumption goes beyond it. Canonical `pet-food` now records sources and limits, not inferred
A/S labels. The example distinguished Banana Mash's reported Steam-era obtainability from
unknown first appearance. Restated question: “May I record these specific evidence findings
and remaining uncertainties, preserving existing labels, availability and taming rules?”
The owner approved. **Approval versus Refusing:** approval records the distinctions without
changing foods/pets; refusal would leave findings unrecorded, not approve assumptions.
The 47-name Alpha lead, Eucalyptus replacement and retained 10 S / five X annotations are
recorded with limits; unsupported food histories remain research, not completed attribution.

**Item 7:** `domain.md §5` records only directly supported mixed-container subfacts, with
pre-release, publication, approximate and example/community limits intact. Landscape release
history does not date all adjacent fauna/habitats; Spirit World music/fog is an S effect report,
not named-track dating. **Approval versus Refusing:** approval improves traceability without
changing encounters, crafting, shops or presentation; refusal would leave attribution unfinished,
not approve alternative gameplay or blanket labels.

**Remaining research (not new proposals):** unsupported food release histories; roster memberships/
traits, exact affix lists, recipe/refining quantities, unscoped shop/loot, population/shipped
schedules, UI/camera details, candles/furniture and audio/dialogue examples (`domain.md §5 item 7`).
The remaining research is not an unanswered owner ballot. No whole-topic completion or next-topic
proposal is claimed; the authorized handoff ends this walkthrough session.

**Evidence and gates:** `/tmp/pixlnd-source-attribution.ADFqBg/` holds the binding
`approval-brief.md`, `food-counts.json`, per-item `item-N-review.md` (semantic/scope inspection,
`/simplify`, then ponytail-review), exact binary `item-N.diff`, `item-N-{diff-check,validator}.log/.exit`,
commit output/hash and `commit-map.md`. Commands for each item: `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd`. Logs/exits record actual
results: all three validators printed `ontology valid` and exited 0, with expected dirty-tree
warnings; all diff checks passed. These check existing loaded data, not prose semantics or new
enforcement. No tests, live data, research dumps or code changed.

**Independent review / parent verification:** fresh read-only source/diff/log review found no
issues (`independent-review.md`); the reviewer ran no commands/tests or independent hash comparisons.
Parent inspected the actual three commits and source citations, confirmed every saved/committed
diff match, commit order and five-Markdown-path scope (`parent-audit.log/.exit`,
`item-N-committed.diff`, `parent-batch.diff`), and independently reran both commands (exit 0):
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
`parent-{validator,boot}.log/.exit` show `ontology valid` and normal hybrid startup. These checks
cover loaded data/startup, not newly documented enforcement. No gameplay suite, visual, network
or fresh external-source/binary verification was performed.

**Final handoff:** this separate verification record follows item `0531ca4`. Pre-publication
remote `ede00f9` was confirmed with `git ls-remote` (`pre-publication-remote.log`); inspect actual
Git state on resumption. The final record receives `/simplify`, ponytail-review and bounded
rechecks, saved as `handoff-review.md`, `handoff.diff` and `handoff-{diff-check,validator,boot}.log/.exit`.
Publish only the authorized branch, verify local/upstream/live remote equality and clean state,
then stop (`docs/HANDOFF.md`). No merge, force-push, history rewrite or new proposals.

### Validation-contract mapping — approved batch (2026-09-28)

| item | application | canonical section | commit |
|---|---|---|---|
| 1 — Hybrid taxonomy/style configuration | [x] recorded | `domain.md §5` | 50e2e82bbf97add642c6bc73c207e9f1e0a46abd |
| 2 — Individual pet-food provenance | [x] recorded | `pet-food` | 645e18a51a05997e9cc655abecbc7625942a39e3 |
| 3 — Qualified source annotations | [x] recorded | §0 / §5 | 8e02ee7a1f9cc90d9f18f8b8c127550337d340a1 |
| 4 — Required inputs, source scopes and check boundaries | [x] recorded and verified | §0 / §5 / §7 | 25552b50e5d41d2a34767e94fba86566cda3a4fe |

Item 1 preserves approved creatures/styles without invented ancestry; the unresolved-classification
alternative was not selected, not a user refusal or automatic content removal. Canonical scope
and historical-fact exclusions are in §5. Item 1 itself approved no inheritance rule; item 4
now supplies the finite source mappings.
Item 2 records per-food evidence with unsupported history unresolved, preserving taming. The
alternative of needing another evidence-backed approach was not selected; neither loader fallback
nor different taming rules became approved. No actual food labels are assigned; source work remains.
Item 3 preserves uncertain reference history without selecting available content. Leaving qualified-tag
handling unresolved was not selected; deleting references or treating them as confirmed was not
approved. Swamp Lands identity remains separate. No presented question remains.

**Item 4 owner answer:** “4: Approved; Mind that the game is not deployed, and that no data
on earth exists to migrate. Don't implement migration code, just require the new one. Once done,
handoff, commit, push”. Recorded in §5 without new balance, labels or schema. The correction
supersedes the proposal's migration terminology: stale checked-in values need direct replacement
only when separately authorized, never migrators/legacy-read support. The initial parent lesson
is preserved with that correction (`tasks/lessons.md`). Refusal was not selected; it would have
left this mapping unfinished, not made old artifact decay/floor acceptable.

**Item 4 evidence:** `/tmp/pixlnd-validation-map.k0hNQx/approval-brief.md`
preserves the exact proposal/correction and names the two read-only source reports. The canonical
mapping was checked against JSON, approved definitions and existing research, not copied as a
parallel spec. `item-4-review.md`, `item-4.diff` and `item-4-{diff-check,validator}.log/.exit`
record writer semantic/scope, `/simplify`, ponytail-review and checks. Writer diff check and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (exit 0,
`ontology valid`; expected dirty-tree warning). These check existing loaded data, not newly
documented enforcement. No tests, live JSON, research or checker changes.
Fresh independent source/log review found no issues (`independent-review.md`); the reviewer did
not execute Git/tests or recompute hashes. Parent inspected the actual diff and confirmed exact
saved-diff correspondence before and after item commit (`parent-audit.log/.exit`,
`parent-precommit.diff`, `item-4-committed.diff`). Only the six authorized Markdown paths changed.
Parent independently reran both bounded commands successfully (exit 0):
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
`parent-{validator,boot}.log/.exit` show `ontology valid` and normal hybrid startup, with expected
dirty-tree warnings. They do not prove new enforcement or prose semantics. No gameplay suite,
visual or network checks were run. Source research remains as listed above, including the existing
six-versus-five cut-food summary discrepancy; preserve F11 and do not invent a sixth entry.
No presented unanswered question or next-topic proposal remains.

**Item 4 handoff:** this separate final verification/handoff follows item `25552b5`. Pre-publication
remote `0f4e954` was confirmed with `git ls-remote` (`pre-publication-remote.log`); inspect actual
Git state on resumption. Final record review/diff/check evidence: `handoff-review.md`, `handoff.diff`,
`handoff-{diff-check,validator,boot}.log/.exit`. Publish only the authorized branch, verify
local/upstream/live remote equality and a clean worktree, then stop (`docs/HANDOFF.md`).

**Historical items 1–3 evidence:** `/tmp/pixlnd-validation-reconcile.zahgTc/approval-brief.md` preserves the exact
numbered proposals and Approval versus Refusing alternatives. `item-N.diff` holds each exact
precommit binary diff; `item-N-review.md` records semantic/scope inspection, `/simplify` then
ponytail-review. Commands: `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd`; results are in
`item-N-{diff-check,validator}.log/.exit`, commits in `item-N-commit.txt` / `commit-map.md`,
aggregate in `batch.diff`. All three item validators printed `ontology valid` and exited 0;
all per-item diff checks passed.

**Historical items 1–3 independent review / parent verification:** no findings from fresh
read-only source/log review (`independent-review.md`); the reviewer did not rerun commands or recompute Git comparisons.
Parent inspected the three actual commits/diffs, verified exact saved-diff correspondence and
five-Markdown-path scope (`parent-audit.log/.exit`), and reran both bounded checks successfully:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Both exited 0: `ontology valid` and normal hybrid startup (`parent-{validator,boot}.log/.exit`).
Validation emitted an explicitly ignored Nix SQLite-cache-busy warning; Godot ran successfully.
These checks cover existing loaded data/startup, not Markdown semantics or policy enforcement.
No gameplay suite, visual or network checks were run. Source, live data, checker and test files
remain unchanged; unfinished mapping/source work is listed above.

**Historical items 1–3 handoff (superseded):** that separate verification/handoff commit follows the three items. Clean item HEAD
`8e02ee7`; live remote `f414c86` confirmed again with `git ls-remote`
(`pre-publication-remote.log`). These are pre-publication checkpoints, not a publication claim.
The final record receives `/simplify`, ponytail-review and fresh sequential bounded rechecks;
evidence: `handoff-review.md`, `handoff.diff`, `handoff-{diff-check,validator,boot}.log/.exit`.
Publish only the authorized branch, verify remote/upstream/local equality and a clean worktree,
then stop. Resumption remains Validation-contract mapping, not new gameplay proposals.

### World bounds / resets — approved batch (2026-09-28)

**Status:** all four proposals approved without amendment or refusal. Item 2 depends on item 1.
Canonical semantics are recorded in `domain.md`; all four items are applied as documentation only.

| item | application | canonical section | commit |
|---|---|---|---|
| 1 — Finite world | [x] recorded | `world`, `c-world-bounds`, `gen-world` | a1269106043f226550009a96b6f7a5f6b615c92b |
| 2 — Outer boundary | [x] recorded | `world`, `c-world-bounds` | 32a8c4948ba28d3bea1fa8a5ec39bf47d2b79ae3 |
| 3 — Cleared-enemy eligibility | [x] recorded | `game-clock`, `c-midnight-reset`, `gen-dungeon`, `gen-missions` | 3f92a32ca1f527cfb48d78abe366e5d67cff1ea1 |
| 4 — Occupied-site refresh | [x] recorded | `game-clock`, `c-midnight-reset`, `c-threat-pair` | 539cc70880e822d77bd328ed2074bf7b08671593 |

**Evidence:** `/tmp/pixlnd-world-reset-reconcile.xc2Nuh/` holds the approval brief, exact
`item-N.diff` pre-commit diffs, `item-N-review.md`, `item-N-{diff-check,validator,commit}.{log,exit}`,
`commit-map.md`, final `batch.diff` and `final-git.log`. Each item passed semantic/scope
inspection, `/simplify`, ponytail-review, `git diff --check` and bounded ontology validation
before its separate commit. All four validators printed `ontology valid` and exited 0.

**Independent review and parent verification:** fresh read-only review found no issues through
source/saved-log inspection, not rerun commands (`independent-review.md`). Parent inspected all
four actual commits/diffs/logs and independently confirmed their exact saved-diff correspondence,
five-Markdown-path scope, preserved proposal text and bound arithmetic (`parent-audit.{log,exit}`).
Parent reran both bounded checks successfully (exit 0; `parent-{validator,boot}.{log,exit}`):
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless --quit
```
Results: `ontology valid` and normal hybrid startup. Checks cover existing loaded data/startup,
not automated Markdown consistency or new boundary/reset enforcement. No gameplay suite, visual
or network checks were run. Live data, gameplay and checker files remain unchanged.

**Handoff checkpoint:** clean item HEAD `539cc70`; live remote `7bff485` confirmed again with
`git ls-remote` (`pre-publication-remote.log`). This separate final handoff commit follows the
four items; these references are pre-publication evidence, not a claim of publication.
The final handoff receives `/simplify`, ponytail-review and fresh bounded rechecks before commit;
evidence: `handoff-review.md`, `handoff.diff`, `handoff-{diff-check,validator,boot}.{log,exit}`.
After the authorized push, verify remote/upstream/local HEAD equality and clean state, then stop.

**Historical presentation (now approved):** the exact proposals and their pre-answer “Settled”
context below are retained for provenance, not as current unanswered questions.

#### 1. A huge but finite world

**Settled:** each land is 16,384 blocks across. The ontology inconsistently describes both an infinite world and a 1,024 × 1,024-land limit.

**Recommend:** retain the finite square: **1,048,576 lands**, roughly **16,777 km per side**, with land coordinates −512 through 511 on each axis.

##### Approval versus Refusing
- **Approval:** an enormous but bounded world; travelling far enough eventually reaches its outer edge.
- **Refusing:** rejects this size limit; it does not automatically select unlimited generation or a wrapping world.

#### 2. A clearly marked outer boundary

**Depends on item 1.** No hybrid edge behavior is settled.

**Recommend:** mark the outer boundary on the map and prevent outward travel, including flight and teleport destinations. Players can turn back; crossing attempts cause no special damage, death or forced teleport.

##### Approval versus Refusing
- **Approval:** predictable limits, but an artificial boundary rather than endlessly generated terrain.
- **Refusing:** another boundary behavior must be selected if the finite world is approved.

#### 3. Which cleared enemies return at midnight?

**Settled:** midnight resets eligible monsters and daily missions. Permanent collectible claims and world improvements survive; cleared dungeon/quest enemy eligibility remains open.

**Recommend:** defeated enemies—including bosses—in ordinary dungeons and repeatable daily encounters return with the daily reset. Enemies belonging to a **completed one-time objective** stay cleared, including its guards and boss. Resetting enemies never renews an artifact or book claim.

Example: tomorrow offers another daily boss fight, but does not recreate the completed supplier-rescue encounter.

##### Approval versus Refusing
- **Approval:** repeatable places remain useful, while completed one-time objectives stay completed.
- **Refusing:** rejects this eligibility split; neither universal respawning nor permanently empty dungeons becomes the default.

#### 4. Don’t reset an occupied encounter around its players

**Settled:** a genuinely respawned mob starts with fresh threat. Midnight’s treatment of an occupied dungeon or quest site is unspecified.

**Recommend:** an occupied dungeon/quest site waits until all players leave before applying its pending daily refresh. Multiple missed midnights produce only one refresh, not stacked waves. The clock change itself never heals or replaces living enemies or erases an ongoing fight.

Example: a dungeon run spanning midnight can finish without its defeated guards suddenly reappearing behind the party.

##### Approval versus Refusing
- **Approval:** uninterrupted runs, at the cost of delaying that site’s refresh while players remain there.
- **Refusing:** the occupied-site reset rule needs an alternative; immediate respawning is not automatically approved.

**Resumption sources:** `ontology/domain.md#land`, `#game-clock`, `#save-data`, `#ai-behavior`,
§5 `c-midnight-reset` and §6 `gen-world`; `ontology/instances/generators.json#world-scales` / `#time`,
`ontology/instances/mission-types.json`, `ontology/instances/dungeon-types.json`; historical references
in `ontology/research/research_world.md` and `ontology/research/research_systems.md §6`.
Current consumers: `game/world/world_gen.gd#land_at` and `game/world/world.gd` stream terrain
without the approved boundary; the world-clock/dungeon/mission/reset systems are unimplemented.
That is deferred implementation, not evidence for or against the proposals.

### Wand handedness — item 1 recorded (2026-09-28)

**Owner answer:** “1: Approved; When done, handoff, commit, push”.

1. [x] **Mechanically two-handed despite a one-hand pose:** recorded in `domain.md#weapon-type`
   / `c-hands`. No other hand item; existing damage, beam attacks and 32-cube upgrade limit stand.
   D6's two-handed recipe costs 20 wood cubes at a workbench for common rarity, keeping rarity gems.
   The one-handed alternative was not selected. No presented Wand question remains.

**Applied versus deferred:** ontology documentation only. Live `weapon-types.json#wand` still
parses as one-handed, and `recipes.json#gear-weapons.wand` still costs 10 wood cubes; neither is
an override. Migration, equipment/crafting/customization enforcement and validation coverage remain
separately unauthorized (`todo_implement.md`). Its historical next topic was **Persistence / authority**;
current approvals and recording status are above.

**Item 1 commit:** `1f5eabc` (`docs(ontology): reconcile two-handed wand equipment and crafting`).
Only four Markdown paths changed: `domain.md`, `ontology/README.md` and the two roadmap ledgers.
Parent inspected semantic fidelity and scope, ran `/simplify` (trimmed repeated checkpoint detail
and a pending-evidence sentence), then ponytail-review (no further cuts). Fresh independent review
found no issues through source/saved-log inspection, not rerun commands. Parent confirmed the
actual commit exactly matches the reviewed diff and the worktree was clean after committing.

**Fresh item checks — all exit 0:** `git diff --check` and these bounded checks:
```
timeout 150 nix develop -c godot --headless -s ontology/validate.gd
timeout 150 nix develop -c godot --headless -s game/items/test_items.gd
timeout 150 nix develop -c godot --headless -s game/combat/test_projectiles.gd
timeout 150 nix develop -c godot --headless --quit
```
Results: `ontology valid`, `items ok`, `test_projectiles: OK`, normal startup. Expected Nix
dirty-tree warnings only. Evidence: `/tmp/pixlnd-wand-reconcile.bNMtmi/` (`approval-brief.md`,
`item-1.diff`, `parent-item-1.diff`, `committed-item-1.diff`, `item-1-review.md`,
`independent-review.md`, `item-1-*.log/.exit`, `item-1-commit.txt`). Checks cover current loaded
data, existing inventory/beam behavior and startup, not enforcement of the newly documented rule.
No full gameplay suite, visual or network checks were run; gameplay/data/checker files are unchanged.

**Final handoff checks:** parent inspected the two-file handoff diff, ran `/simplify` (trimmed
redundant next-topic wording), then ponytail-review (no further cuts), and reran all four bounded
checks above successfully (exit 0; `final-*.log/.exit`, `handoff-review.md`). Final diff checks
passed. Only five Markdown paths differ from starting HEAD `83b318b`; runtime/live data are unchanged.

**Pre-publication checkpoint:** clean item HEAD `1f5eabc`, remote `83b318b` confirmed again with
`git ls-remote`. The separate final handoff follows item 1. Push only the authorized branch without
force or merge, verify remote/local HEAD equality and a clean worktree, then stop. This is not a
publication claim; inspect actual Git state on resumption.

### Assassin ultimate — item 1 recorded (2026-09-28)

**Owner answer:** “1: Approved; Once item reconciled, handoff, commit, push”.

1. [x] **One Camouflage, not two purchases:** `domain.md#skill-tree` / `c-tree-shape` records
   the Assassin-specific D10 exception: one rank-3 skill on key 3, no separate fourth node/key-4
   ability, investment or charge. Existing Camouflage behavior and other specializations stand.
   The canonical rule retains the Sneak prerequisite and normal point spending.

**Applied versus deferred:** ontology documentation only. The current key-3/no-key-4 runtime
already matches; `abilities.json#camouflage.alpha-tree.also-ultimate` remains unchanged.
Metadata clarification and validation coverage remain separately deferred in `todo_implement.md`.
No gameplay, live JSON, tests, loader or validator edits are authorized.
No presented Assassin question remains; the separate-fourth-node alternative was not selected.
Its historical next topic was **Wand handedness**, now reconciled above.

**Item 1 commit:** `b19662b` (`docs(ontology): reconcile Assassin Camouflage as one skill`).
Only four Markdown paths changed: `domain.md`, `ontology/README.md` and the two roadmap ledgers.
Parent inspected approval fidelity and scope, ran `/simplify` (cut three repeated ledger lines),
then ponytail-review (no further cuts). Fresh independent review found no issues through source
and saved-log inspection, not rerun commands. Parent confirmed the reviewed diff matches the
actual worktree before committing; no gameplay, live data, tests or checker files changed.

**Fresh item checks — all exit 0:** `git diff --check`;
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` (`ontology valid`);
`timeout 150 nix develop -c godot --headless -s game/progression/test_skill_tree.gd` (`skill tree ok`);
`timeout 150 nix develop -c godot --headless --quit` (normal startup).
Evidence: `/tmp/pixlnd-assassin-20260928/` (`approval-brief.md`, `item-1.diff`,
`parent-item-1.diff`, `item-1-review.md`, `independent-review.md`, `item-1-*.log/.exit`,
`item-1-commit.txt`). These checks cover loaded data, existing tree behavior (including no
Assassin fourth node/key 4) and startup, not exhaustive Camouflage runtime or deferred threat
implementation. No full gameplay suite, visual or network checks were run.

**Final handoff checks:** parent inspected the two-file handoff diff, applied `/simplify`
(trimmed repeated verification prose), then ponytail-review (no further cuts), and reran all
three bounded checks above successfully (exit 0; `final-*.log/.exit`, `handoff-review.md`).
The committed item diff matches its reviewed diff; only five Markdown paths differ from the
starting HEAD. Final diff checks passed; gameplay/data/checker files remain unchanged.

**Pre-publication checkpoint:** clean item HEAD `b19662b`, remote `0399f15` confirmed again before
publication with `git ls-remote`. The separate final handoff follows the item commit. Push only the
authorized branch without force or merge, verify remote/local HEAD equality and a clean worktree,
then stop. This checkpoint is not a publication claim; inspect actual Git state on resumption.

### Artifacts — approvals and recording (2026-09-28)

**Authority:** item 1's per-stat approach received “Good approach”, with equal-current-share
correction; items 2–3 were approved. Follow-up: “4: Approved; 5: Decrease in total bonus is not
intentional”. Final: **“5: Approved with z=0.1; 6: Approved”**. The normalized logarithmic
proposal supersedes both exponential examples and the initial expression whose z cancelled.
Canonical rules: `domain.md#artifact`; the other D6 decisions and D11 land counts stand.
Documentation only; no live JSON or runtime authorization. Recording order: **1, 2, 3, 4, 6, 5**.

1. [x] **Separate traversal counts / equal current contributions:** recorded; acquisition
   order is irrelevant. No new reduction system for other item kinds. The existing item
   definitions, stat formulas and `game/items/items.gd` / `inventory.gd` show no equivalent
   ordinary-gear item-count diminishing mechanism; level/rarity curves and power gates remain.
2. [x] **Additive contributions:** recorded; `B(x)` is already the fractional total, never
   multiplied by the count again; equal current share is `B(x)/x` for positive counts.
3. [x] **Recalculated artifact-free stat basis:** recorded; compute normal level/equipment/
   skill/buff inputs first, then multiply by `1+B(x)`; no pickup-time snapshot or new stat target.
4. [x] **Attack / maximum HP count all artifacts:** recorded; same recalculation as traversal,
   whose counts remain matching-only. Exactly one existing traversal kind plus attack and maximum
   HP per artifact; no character levels, traversal-gate bypass or new slot.
5. [x] **Normalized logarithmic total, initial z=0.1:** recorded in `domain.md#artifact`;
   zero gives no change, first gives 5%, totals increase without a hard cap and marginal gains
   diminish. Positive z is the sole curve knob; no separate logarithm-base knob.
6. [x] **Remove the old 1% floor:** recorded before item 5's equation; no hidden clamp,
   minimum artifact share or minimum marginal gain. First artifact remains 5%.

Per-item writer evidence: `/tmp/pixlnd-artifacts-20260928/` (`item-N.diff`, `item-N-review.md`,
`item-N-{scope,diff-check,validator}.{log,exit}`, `item-N-commit.{log,txt}`; final `commit-map.md`
and `batch.diff`). Each item received semantic/scope inspection, `/simplify`, then ponytail-review,
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`.
Starting branch: `fix/ontology-reconciliation` at `8135a5010fd673658b447c4e9e6f3639529c0d6d`.
The parent's initial 14-line `tasks/lessons.md` diff is preserved verbatim in item 1.

| item (commit order) | ontology-only commit | scope / diff / validator exits | simplify outcome; subsequent ponytail-review |
|---|---|---|---|
| 1 | `012cd06` | 0 / 0 / 0 | removed duplicate constraint prose; no further cuts |
| 2 | `a27e221` | 0 / 0 / 0 | trimmed repeated deferral prose; no further cuts |
| 3 | `00720ff` | 0 / 0 / 0 | kept one compact deferral; no further cuts |
| 4 | `0ee1027` | 0 / 0 / 0 | separated source history from reward rule; no cuts |
| 6 | `db44551` | 0 / 0 / 0 | kept compact existing pointers; no cuts |
| 5 | `52f171b` | 0 / 0 / 0 | removed rejected equation/repeated check prose; no further cuts |

All six validators reported `ontology valid`; Nix's dirty-tree warning was expected.
Fresh scratch arithmetic passed (exit 0): counts 0..10000 at z=0.1, zero/first, increasing totals,
diminishing marginal gains, decreasing equal shares, sum consistency and no 1% floor.
Command: `timeout 150 nix develop -c jq -n -e -r -f /tmp/pixlnd-artifacts-20260928/parent-curve-check.jq`;
writer output: `writer-curve-check.{log,exit}` in the same directory. This is arithmetic, not gameplay.
**Independent review and parent verification:** fresh read-only review found no issues across
all six items; it inspected source/diffs and saved evidence, not rerun commands. Parent inspected
the actual commits, verified each saved item diff matches its commit and the six-Markdown-file
boundary, and reran `git diff 8135a50 HEAD --check`, bounded ontology validation and headless
boot successfully (exit 0, `ontology valid`, normal startup). Commands:
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd`;
`timeout 150 nix develop -c godot --headless --quit`.
Logs/reports in the evidence directory: `independent-review.md`, `parent-batch.diff`,
`parent-commit-check.{log,exit}`, `parent-validator.{log,exit}`, `parent-boot.{log,exit}`.
The parent's arithmetic check also passed; its initial assertion used the wrong count to
illustrate a share below 1% at z=0.1. Corrected that witness to 1000 without changing the formula;
initial failure and explanation remain in `parent-curve-check-initial.*` / `parent-curve-check-notes.md`.
The final record received `/simplify` (removed temporary writer/review instructions), then
ponytail-review; no policy changes were needed. Final handoff checks are in `final-handoff-*` logs.
Loaded-data/startup checks and arithmetic do not prove artifact gameplay; no gameplay suite,
visual or network checks were run. Gameplay, live JSON, tests and model/loader/validator are unchanged.

**Pre-publication checkpoint:** clean item HEAD `52f171b` on `fix/ontology-reconciliation`, remote
`8135a50` confirmed with `git ls-remote`. The final verification/handoff commit follows these six
commits. Push the authorized branch without force or merge, verify remote/local HEAD equality and
clean worktree, then stop. This is not a publication claim; inspect actual Git state on resumption.
No presented artifact question remains. The historical next topic was **Assassin ultimate**,
now reconciled above. Implementation debt stays in `todo_implement.md`.

### Books/formulas — approvals and recording (2026-09-28)

**Owner answer:** “1: Approved; 2: Approved; 3: Approved; When done, handoff, commit, push”.
Documentation only; both sources remain in hybrid, with no crafting-material or equipment-strength
change. Knowledge and usability are distinct: a known recipe can remain power-locked.

1. [x] **Permanent/global book recipes:** recorded in `domain.md#book-of-crafting`,
   `#player-character`, `#save-data`, `knows-recipe` / `c-book-recipe-persistence`.
   Character knowledge survives lands and sessions; persistence item 1 now records cross-world portability.
2. [x] **Shared recipe collection:** books teach only unknown recipes, without rerolls or
   compensation; an already-known formula stays unconsumed. Canonical rule: `domain.md#recipe`,
   `knows-recipe` / `c-recipe-learning`. Overlap can make later books less rewarding.
3. [x] **Book power gates:** books record immediately; above-power recipes stay visibly
   locked until their requirement is reached. Formula learning retains its existing requirement.
   Known-but-locked recipes follow item 2's duplicate rules without bypassing the crafting gate
   or granting compensation (`domain.md#power-gate`, `c-power-gate` / `c-recipe-learning`).

| item | ontology-only commit |
|---|---|
| 1 — permanent/global book recipes | `9f4262e` |
| 2 — shared knowledge and duplicates | `4ddd76e` |
| 3 — immediate recording, power-locked crafting | `11cc07f` |

**Writer verification:** each item received semantic/scope inspection, `/simplify`, then
ponytail-review; `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (exit 0,
`ontology valid`). Checks confirmed five allowed Markdown paths, unique relation/constraint IDs
and unchanged historical D/F records. The combined review checked known-but-locked duplicates:
no extra knowledge, compensation, consumed formula or power bypass. These are writer checks,
not independent acceptance; validation covers loaded data, not Markdown semantics or gameplay.
No gameplay suite, boot, visual or network checks were run; runtime, live JSON and tests are unchanged.

Evidence: `/tmp/pixlnd-books-20260928/` (`item-{1,2,3}.diff`, `item-N-review.md`,
`item-N-{scope,diff-check,validator}.{log,exit}`, `item-N-commit.{log,txt}`, `commit-map.md`,
`batch.diff`). Item 1's initial scratch scope check failed on a nonexistent `/usr/bin/git`;
a supervisor-approved PATH correction passed (`item-1-scope-retry.{log,exit}`), before validation.
The setup failure/log is preserved, not counted as an ontology validation failure.

**Independent review and parent verification:** fresh read-only review found no issues; it inspected
sources and saved evidence, not rerun tests (`independent-review.md` in the evidence directory).
Parent inspected all three actual commit diffs against the approvals, verified each saved item diff
matches its commit, confirmed five-Markdown-file scope and an empty index, and reran
`git diff e76921a --check`, the bounded ontology validator and
`timeout 150 nix develop -c godot --headless --quit` successfully (exit 0, normal startup).
Logs: `parent-validator.{log,exit}`, `parent-boot.{log,exit}`. The final record received `/simplify`
(removing temporary writer/parent instructions), then ponytail-review; no policy changes were needed.
Validation covers current loaded data/startup, not the new recipe policies' implementation.
No gameplay suite, visuals or network checks were run.

**Historical books pre-publication checkpoint (superseded):** branch `fix/ontology-reconciliation`, item HEAD `11cc07f`, remote
`e76921a` confirmed with `git ls-remote`. The final verification/handoff commit follows the three
items; push without force or merge, verify remote/local HEAD equality and a clean worktree, then stop.
This checkpoint is not a publication claim; inspect actual Git state on resumption.
No presented books question remained. Artifact accumulation was next at that checkpoint;
the artifact approvals above supersede that status and its preserved D6 accumulation values.
Implementation debt remains in `todo_implement.md`.
Those books approvals chose no shared-account knowledge, multiplayer reward allocation,
recipe-generation/identity defaults or cross-world portability; later persistence approvals
are tracked above.

**Sources inspected:** `domain.md#formula`, `#book-of-crafting`, `#power-gate`, `#player-character`,
§4/§5; `instances/recipes.json#recipe-sources`, `key-items.json#books-of-crafting`,
`rulesets.json#ruleset-hybrid.flags`, `research/research_items.md §3.3`.
`game/items/shop.gd` recognizes formula prices, but crafting/learning/save-data remain deferred.
A/S descriptions are historical provenance, not hybrid policy; live data is unchanged.

**Historical unanswered handoff (superseded):** `e76921a` preserved the three exact proposals
and Approval versus Refusing consequences, before these answers. Its pre-publication checkpoint
was clean `93886e0`, remote `d6bbaf7`; it authorized the five traversal commits, verification
commit and that handoff. It does not supply fresh verification for this books recording.

**Historical handoff verification (before books approvals):** exact proposal/consequence comparison (heading depth ignored),
two-file scope and `git diff --check` passed. Fresh bounded ontology validation and headless
boot exited 0 (`ontology valid`, normal main-scene startup). Commands:
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd`;
`timeout 150 nix develop -c godot --headless --quit`. Initial parallel boot logged an ignored
Nix SQLite-cache busy warning, not a Godot failure. Fresh independent read-only review found
no issues; parent inspected the final diff/report/logs. `/simplify` reused the existing ledger
and removed superseded status text; ponytail-review found no further cuts. Parent reran the
final checks sequentially before committing. The reviewer inspected evidence, not rerun tests.
Evidence: `/tmp/pixlnd-books-handoff-20260928/` (`presented-batch.md`, `proposal-check.log`,
`handoff.diff`, `scope.log`, `validator.{log,exit}`, `boot.{log,exit}`, `independent-review.md`,
`parent-review.md`, `final-checks.log`, `final-validator.log`, `final-boot.log`). These are fresh handoff
checks, not reused traversal logs. They cover current loaded data/startup, not new policies'
implementation; no gameplay suite, visuals or network checks were run. The handoff changes
only HANDOFF and this ledger; the six preceding local commits change only Markdown.

### Traversal — approvals and recording (2026-09-28)

**Owner answer:** “1: Approved; 2: Approved; 3: Approved; 4: Correction: Climbing spike reduce
climing stamina consumption by 75% instead of making it disappear”. Later: **“5: Approved”**.
Documentation only; item 5's composition rule is a separate approval, not inferred from item 4.

| item | recording / commit |
|---|---|
| 1 — riding training + Reins | `b4da965` |
| 2 — gliding training + equipped bought glider | `88c54ac` |
| 3 — sailing training + equipped bought boat | `0462e9c` |
| 4 — Spikes reduce climbing consumption by 75% | `54f53fd` |
| 5 — remaining-cost stacking | `e70fb8f` |

Item 1 passed scope inspection, `/simplify`, ponytail-review and `git diff --check` (exit 0).
Its first bounded validator command timed out during Nix downloads (exit 124, before Godot);
a supervisor-authorized exact retry passed (exit 0, `ontology valid`). Logs retain both attempts.
Items 2–5 passed the same reviews, diff checks and bounded validators (exit 0, `ontology valid`).
Command: `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`.
`item-N-review.md`, `item-N-diff-check.{log,exit}` and `item-N-validator.{log,exit}` hold the
per-item evidence (item 1's success is `item-1-validator-retry.{log,exit}`). No gameplay, boot,
visual or network checks were run; no tests, live JSON or runtime files changed.

Fresh independent read-only review found no issues across all five items, including the late
item-5 approval. Parent inspected the actual diff, item/commit mapping, allowed six-Markdown-file
scope and logs, confirmed a clean worktree, and reran the bounded validator (exit 0, `ontology
valid`). Evidence: `/tmp/pixlnd-traversal-20260928/` (`independent-review.md`, `parent-batch.diff`,
`parent-validator.{log,exit}`, per-item logs). The reviewer read saved logs, not rerun tests.
The verification-record diff also received `/simplify`, ponytail-review and fresh diff/validator
checks. Loaded-data validation does not prove Markdown fidelity or gameplay implementation;
runtime/live-data migration remains unauthorized (`todo_implement.md`). No push was performed
at that verification checkpoint (`93886e0`); the later handoff above now authorizes publication.

#### 5. Remaining-cost stacking — approved and recorded

Apply Spikes after Climbing's skill reduction: remaining cost **×0.25**, not an added 75
percentage points. Illustrative only: a skill-adjusted 8 stamina (from 10) becomes **2**, not
0.5. Points retain their benefit with Spikes; Spikes do not turn a positive remaining cost into
zero by themselves. Canonical rule: `domain.md#key-item` / `#skill-tree` / `c-climbing`.
No skill reduction curve/floor or artifact-combination rule is inferred. All five traversal
items are reconciled; subsequent books/formulas approvals are recorded above.

#### Items 1–4 — recorded principles

- [x] **1 — Riding:** 5 Pet Master + ≥1 Riding point, global Reins and a rideable tamed pet;
  further points improve speed (`domain.md#pet`, `c-riding`). No species permission/route/slot added.
- [x] **2 — Gliding:** 5 Climbing + ≥1 Hang Gliding point and a vendor-bought equipped Hang
  Glider; further points improve speed (`domain.md#skill-tree`, `c-gliding`). Buying alone is insufficient.
- [x] **3 — Sailing:** 5 Swimming + ≥1 Sailing point and a vendor-bought equipped Boat;
  further points improve speed (`c-sailing`). Boat/glider share the single special slot, never both.
- [x] **4 — Climbing:** no points/Spikes needed for basic climbing; skill points reduce drain,
  Spikes reduce consumption by 75%; five Climbing points remain the gliding prerequisite
  (`domain.md#key-item`, `#skill-tree`, `c-climbing`).

**Historical presentation (2026-09-27, superseded):** exact proposals/consequences remain in
`d6bbaf7` and the old handoff evidence below. The owner superseded item 4's infinite-endurance
recommendation and “points no longer help” tradeoff, not basic climbing or the gliding prerequisite.

**Source/resumption paths:** `ontology/domain.md#pet`, `#equipment-slot`, `#key-item`,
`#skill-tree`, §5 `c-gear-global`; `instances/abilities.json` shared nodes,
`key-items.json`, `rulesets.json#ruleset-hybrid.flags`; consumers
`game/progression/skill_tree.gd` and `game/entities/player.gd`; research
`research/research_systems.md` movement/progression sections. Skill spending/swimming run;
pet riding, climbing, glider and boat runtimes remain deferred. Existing source-version fields
and flags do not override the recorded hybrid gates. No gameplay implementation is
approved by these decisions; existing deferrals remain in `todo_implement.md`.

**Historical pre-publication checkpoint (2026-09-27, superseded):** clean `fix/ontology-reconciliation` at `fa716ab` before this
handoff; remote `b4ce91e` confirmed with `git ls-remote`. Publish the four settlements/inn
commits listed below, verification commit `fa716ab`, and this separate handoff commit. Verify
remote/local HEAD equality and clean state afterward, then stop; no force-push or merge.

**Historical handoff verification (2026-09-27):** exact proposal-text comparison (heading depth ignored), two-file scope
and diff checks, bounded ontology validation and headless boot passed. `/simplify` removed
redundant settled-rule prose while preserving the verbatim batch; ponytail-review found no further
cuts. Fresh independent read-only review found no issues; parent inspected the final diff,
report and logs. Commands: `git diff --check`;
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd`;
`timeout 150 nix develop -c godot --headless --quit`. All exited 0; validator: `ontology valid`.
Evidence: `/tmp/pixlnd-traversal-handoff-20260927/` (`presented-batch.md`, `scope.log`,
`validator.log`, `boot.log`, `checks.log`, `independent-review.md`, `parent-review.md`).
The handoff changes only HANDOFF and this ledger; publication changes five Markdown files.
These checks cover current loaded data/startup, not new policies' implementation. No gameplay
suite, visuals or network checks were rerun; old batch logs are not fresh handoff evidence.
Verify remote/local final HEAD equality and clean worktree after pushing, then stop.

### Settlements / inn — items 1–4 recorded (2026-09-27)

**Owner answer:** “1: Approved; 2: Approved; 3: Approved; 4: Approved”. Documentation only;
items 3–4 depend on recorded item 2. All four are recorded; traversal status is above.
The separate 2026-09-27 handoff authorized publication then, not new publication now.
Cleared dungeon/quest enemy eligibility was unresolved at that checkpoint; world/reset item 3 now records it.
Current D22 runtime and live JSON are unchanged.

1. [x] **One settlement per land is the final target**, not unfinished multiplicity.
   Canonical rule: `domain.md#settlement`, `c-land-count`, `gen-settlement`.
   Conflicting live flag and exact-count enforcement are deferred in `todo_implement.md`.

2. [x] **Separate paid sleep from free recovery:** free healing/respawn setting at any time;
   10-copper sleep, 18:00–06:00 → next 07:00, without fast-forwarding combat.
   Canonical rule and date examples: `domain.md#game-clock` / `c-inn-hours`.

3. [x] **No extra daily refresh for sleeping:** ordinary midnight resets once only when the
   skip crosses midnight; no additional shop refresh or mission reroll. Canonical rule:
   `domain.md#game-clock` / `c-midnight-reset`. Cleared dungeon/quest enemy eligibility stays open.

4. [x] **Everyone agrees before shared-clock sleep:** all connected players explicitly agree;
   the initiator pays the single 10-copper fee only on success. Refusal blocks the skip without
   charge; free recovery needs no agreement. Canonical rule: `domain.md#game-clock` / `#multiplayer-mode`.

| item | ontology-only commit |
|---|---|
| 1 — final settlement count | `154df56` |
| 2 — separate paid sleep | `0b7c2d4` |
| 3 — midnight-crossing refreshes | `250f964` |
| 4 — agreement and success-only payment | `f207a48` |

**Verification:** each item received diff inspection, `/simplify`, then ponytail-review and
appropriate cuts; `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (exit 0,
`ontology valid`). Fresh independent read-only review found no issues; parent inspected the
actual diff/commits/logs and reran validation successfully. All four commits change only the
five ontology/status Markdown files; live JSON, executable files and tests are unchanged.
Evidence: `/tmp/pixlnd-settlements-20260927/` (`item-{1,2,3,4}-*`, `independent-review.md`,
`parent-final-diff.patch`, `parent-validator.log`). The reviewer checked Markdown semantics and
matched patches to Git; validation checks loaded data, not implementation of these policies.
No gameplay, boot, visual or network checks were rerun for that batch. Its original no-push
boundary is superseded only by the separate handoff/publication authorization above.

Sources inspected: `ontology/domain.md#settlement`, `#game-clock`, `#currency`, `#multiplayer-mode`,
`c-inn-hours`, `c-midnight-reset` and D22; `instances/rulesets.json#ruleset-hybrid.flags`,
`generators.json#time|design.settlement`, `economy.json#shops.inn|rules`, `npc-roles.json#innkeeper`,
`buildings.json`, `research/research_world.md §5/§7`; consumers `game/world/world_gen.gd#village_at`,
`world.gd#_stream_village`, `settlement.gd`, `game/entities/player.gd#rest`. The live build still
has free recovery and no game clock/time skip; conflicting/incomplete flags await migration,
not reinterpretation as alternatives to the approved policies.

**Historical publication checkpoint (superseded):** branch `fix/ontology-reconciliation` at `683fd79` before that handoff;
remote `ef81bd6` confirmed with `git ls-remote`. Publish existing family commits `a4c6206`,
`2f5ad06`, `683fd79` plus this separate two-file handoff commit. No merge, history rewrite or
force-push. After pushing, verify remote/local HEAD equality and clean worktree, then stop.

**Historical handoff verification:** exact proposal-text comparison (heading depth ignored), diff/scope
checks, bounded ontology validation and headless boot passed. `/simplify` kept the question
batch in this ledger without duplicating it in HANDOFF; ponytail-review found no further cuts.
Fresh independent read-only review found no issues; parent inspected the diff, report and logs.
Evidence: `/tmp/pixlnd-settlement-handoff-20260927/` (`presented-batch.md`, `scope.log`,
`parent-review.md`, `independent-review.md`, `validator.log`, `boot.log`, `checks.log`).
Commands: `git diff --check`; `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`;
`timeout 150 nix develop -c godot --headless --quit`. All exited 0; validator: `ontology valid`.
The handoff changes only HANDOFF and this ledger; the publication changes six Markdown files.
These checks cover current loaded data/startup, not new Markdown semantics or implementation.
No gameplay suite, visuals or network tests were rerun; historical logs are not fresh evidence.
Remote equality and clean-state publication checks must follow the push.

### Creature family membership — items 1–9 recorded (2026-09-27)

**Owner answer:** “1: Approved, but make the skeletal dog a (rare if rarity is defineable) dog as
individual family, not a skeleton; 2: Approved; 3: Approved”. Approval covers documentation only;
live data, model/loader/validator and gameplay remain unchanged. The later rarity amendment is
recorded in item 4 below; the owner subsequently approved both follow-ups 5–6.

| item | documentation application | commit |
|---|---|---|
| 1 | Recorded: primary/descriptive distinction and owner amendment; `domain.md §3.2/§4/§5` | `dd5d9f8` |
| 2 | Recorded: authoritative 25-assignment table; `domain.md#creature-family` | `3da743c` |
| 3 | Recorded: unassigned creatures retain ordinary stats with ×1.0 family modifier; `domain.md §3.2/§5` | `b2db99b` |
| 4 | Recorded with amendment: 1% encounter chance relative to dog spawns; `domain.md §3.2/§5` | `c4dd5fe` |
| 5 | Recorded: independent per-individual-dog roll; mixed packs permitted; `domain.md §3.2/§5` | `7d8b86c` |
| 6 | Recorded: wherever dogs already spawn, preserving settlement safety; `domain.md §3.2/§5` | `a730d74` |

**Historical family item 1 verification:** `/simplify` removed superseded question/refusal prose;
writer ponytail-review found no further cuts. `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (`ontology valid`).
Logs: `/tmp/pixlnd-family-record-20260927/item-1-{validator,diff-check,scope,review}.log`.
Validator coverage is current loaded data only, not Markdown semantics or runtime compliance.

**Historical family item 2 verification:** exact 25 IDs/counts checked against the approved list and
current top-level family members/missing fields. `/simplify` removed the duplicate roadmap
table; writer ponytail-review found no further cuts. The same diff check and bounded validator
passed (`ontology valid`); logs use `item-2-*` in the directory above. Follow-up 4 is unchanged.

**Historical family item 3 verification:** `/simplify` removed the temporary policy summary and redundant
status prose; writer ponytail-review found no further cuts. The same diff check and bounded
validator passed (`ontology valid`); logs use `item-3-*` above. Scope checks preserve item 2's
table and follow-up 4; no runtime/live JSON/tests changed across items 1–3.

**Historical proposals 1–3 (superseded by the owner answer):** the earlier handoff received
no answers; the subsequent approval above replaces that checkpoint. In particular, item 1's
original recommendation to keep Skeleton Dog primary `skeletons` is superseded by `dogs`.

Sources: `ontology/instances/creatures.json`, top-level family lists in `creature-families.json`
(not its nested spawn rosters), `generators.json#design.enemy-hp`, `domain.md#creature-family`.
The observed missing fields and overlap remain live-data facts, not evidence of implementation.

#### Follow-up 4 — approved with amendment (2026-09-27)

**Owner clarification:** “A skeletal dog shall have a 1% chance of encounter instead of 10%
amongst dog. Ensure 1% is relative to dogs spawn.” This is approval of dog-relative encounter
rarity with an amended probability/denominator, not blanket approval of the previous proposal.
Canonical rule: `domain.md#creature-family` / `c-skeleton-dog-encounter`. No combat/loot bonus.
The earlier one-tenth ordinary-species weight is superseded, never approved. Item 4 alone did
not decide roll unit or habitat scope (now settled by 5–6); replacement pools remain unchosen.

**Historical item 4 verification:** `/simplify` removed the superseded probability example; ponytail-review
found no further cuts. `git diff --check` and the bounded ontology validator passed (`ontology
valid`, exit 0; `/tmp/pixlnd-family-item4-validator.log`). Only six Markdown files changed;
loaded data and runtime are unchanged. Validation does not prove the documented chance is implemented.

#### Follow-ups 5–6 — approved (2026-09-27)

**Owner answer:** “5: Approved; 6: Approved”. These clarify application of the approved 1%;
they do not reopen the percentage or dog family.
Live data/runtime still select one species per group and retain Skeleton Dog's old habitats
(dungeons, dark woods and deadlands); other dogs also occur in ordinary biomes and settlements.
The live deadlands roster has Skeleton Dog as its only dog candidate. These are migration gaps,
not exceptions to the approved rule.

5. [x] **Independent roll per dog — approved and recorded:** each individual dog has an
   independent 1% chance; a pack may mix ordinary and skeletal dogs. Canonical rule:
   `domain.md#creature-family` / `c-skeleton-dog-encounter`. No per-species weighting or quota.
6. [x] **Habitat scope — approved and recorded:** allow the rare variant wherever dogs already
   spawn, preserving existing settlement safety, rather than only dungeons/dark woods/deadlands.
   Existing skeleton-only rosters must be reconciled before generation; no ordinary-dog
   replacement pool is chosen here.

**Historical handoff boundary before item 7:** all presented questions were answered, but
ordinary-dog roster mapping was unpresented. Item 7 below settles that mapping; no dog-frequency
change or extra unrestricted skeletal spawns is approved. Migration/enforcement remains deferred.

**Fresh item 5 verification:** `/simplify` removed superseded question/refusal prose; writer
ponytail-review found no further cuts. `git diff --check` and the bounded ontology validator
passed (`ontology valid`, exit 0). Evidence: `/tmp/pixlnd-family-handoff-20260927/item-5-*`.
Only permitted Markdown records changed; loaded-data checks do not prove runtime compliance.

**Fresh item 6 verification:** `/simplify` removed repeated primary/category prose and a duplicate
constraint reference; writer ponytail-review found no further cuts. The same diff check and
bounded ontology validator passed (`ontology valid`, exit 0). Evidence: `item-6-*` in the same
directory. Only permitted Markdown records changed; no live roster or runtime migration.

**Pre-publication family handoff checkpoint (2026-09-27):** branch `fix/ontology-reconciliation`;
item 6 commit `a730d74` is followed by a separate handoff commit. `git ls-remote` confirmed the
remote branch at `858f038` before publication. The handoff changes only `docs/HANDOFF.md` and
this §E record. Push this authorized branch without merging or rewriting history, verify remote
HEAD equals local HEAD and the worktree is clean, then stop. Remote:
`git@github.com:M4jor-Tom/pixlnd.game.git`. Inspect actual Git state on resumption.

**Fresh final checks:** `git diff --check`, `git diff 858f038 --check`,
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` (`ontology valid`) and
`timeout 150 nix develop -c godot --headless --quit` (main scene booted), all exit 0.
Logs: `/tmp/pixlnd-family-handoff-20260927/final-{diff-check,aggregate-diff-check,validator,boot}.log`.
Individual item diffs/reviews are in the same directory; reviewed publication draft:
`/tmp/pixlnd-family-handoff-review.diff` (`git diff 858f038`). Parent's final two-file handoff diff:
`parent-final-handoff.diff` in the log directory. The batch includes
historical `tasks/lessons.md` edits from items 1/4; this pass changes only the five permitted records.
Earlier family/aggro/gameplay evidence is historical. No gameplay suite, visuals or networking
checks rerun; validator/boot success does not prove Markdown semantics or deferred runtime rules.
Independent publication review found no issues; parent inspected the six commits and actual diff,
confirmed Markdown-only scope, and reran the bounded validator and boot successfully (logs:
`parent-validator.log`, `parent-boot.log` in the same directory). Review artifact (session-local):
`~/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/b209f9a8-fb63-4990-a897-9edfa4d3bab8/family-handoff-review.md`.
Final `/simplify` removed temporary writer/staging instructions; ponytail-review found no further
cuts. The unresolved roster mapping above is real design work, not a claim of full family
completion or permission to implement the approved rules.

#### Items 7–9 — approved mapping, behavior and taming (2026-09-27)

**Owner answer:** “7: Approved, but make skeletal dog non-aggressive and tameable.”

- [x] **7 — Collie fallback and Skeleton Dog amendment:** recorded in
  `domain.md#creature-family` / `c-skeleton-dog-encounter` / `c-skeleton-dog-taming`.
  Recorded in `a4c6206`; its former open details are answered below.
  Live data, loader/validator, tests and gameplay remain unchanged.

**Owner follow-up:** “8: Skeletal dogs must behave like normal dogs, "skeletal" is just a
different dog race; 9: Approved”.

- [x] **8 — Normal dog behavior (owner correction):** recorded in `domain.md#creature-family`
  / `c-skeleton-dog-taming`. “Skeletal” is a dog breed, not a special behavioral category:
  ordinary encounter/state rules govern aggression, retaliation, pack response and taming.
  The proposed skeleton-only complete passivity/taming-provocation exemption is superseded,
  not approved. Normal pet behavior and existing family/category distinctions remain.
  Commit: `2f5ad06`.
- [x] **9 — Shared Bubble Gum:** recorded in `domain.md#creature-family` / `#pet-food`,
  `tamed-by` and `c-food-id`. Bubble Gum tames Collie and Skeleton Dog, retaining existing
  availability/prices and subtype 19 from Collie without assigning Skeleton Dog that source ID.
  Other pairings remain; no family-wide inheritance or new food/recipe. Live data and shared-food
  model/loader/validator support remain separately unauthorized.
  Commit: `683fd79`.

**Item 9 verification:** checked shared-food cardinality, source identity and preserved pairings.
`/simplify` removed settled questions and temporary recording status; ponytail-review found no
further cuts. Diff/scope checks and the bounded ontology validator passed (exit 0, `ontology valid`);
only five intended Markdown files changed. Evidence: `/tmp/pixlnd-family-items8-9-20260927/item-9-*`.
Fresh independent review of items 8–9 found no issues; report copied to `independent-review.md`
in that directory. Parent inspected both diffs and verification logs. The reviewer ran no tests;
validation covers unchanged loaded data, not new Markdown semantics or runtime compliance.
No gameplay suite, visuals or network checks were run.

**Item 8 verification:** checked the exact correction against normal dog, pack and pet rules.
`/simplify` removed the superseded special-passivity proposal; ponytail-review found no further
cuts. Diff/scope checks and the bounded ontology validator passed (exit 0, `ontology valid`);
only six intended Markdown files changed. Evidence: `/tmp/pixlnd-family-items8-9-20260927/item-8-*`.
The validator checks unchanged loaded data, not Markdown semantics or runtime compliance.
No gameplay suite, visuals or network checks were run.

**Item 7 verification:** inspected the exact approval, canonical rules, dog rosters and taming
contract; `/simplify` removed duplicate ledger semantics and obsolete pool-status prose, then
ponytail-review found no further cuts. `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (exit 0, `ontology valid`).
Only six intended Markdown files changed. Session-local evidence: `/tmp/pixlnd-family-item7-20260927/`.
Validation covers unchanged loaded data, not Markdown semantics or runtime compliance. No
independent review, gameplay suite, visuals or network tests are claimed for this single item.

### Reconciliation work — application checklist

These are the other findings from the 2026-09-13 audit, alongside the open questions above.
Keep references/indices and settled D decisions intact; defer any dependent work whose answer
is still open. Do not mistake a listed proposed correction for an approved new gameplay rule.

- [x] **Apply approved items 1–2 (2026-09-15):** removed Cookie from the active pool and corrected
  `raises-stat` / `costs` cardinalities as recorded above. Historical data, effects, costs and
  balance numbers preserved. Cookie loot/shop regressions failed before the pool correction and
  passed after it (`game/items/test_items.gd`, `game/world/test_settlement.gd`).
- [x] **Equipment model — ontology (item 3, 2026-09-15):** recorded the approved semantics in
  `domain.md §3.4/§4/§5`: 13 stored positions / 12 usable, independent Q selection, matching
  item types and subtype restrictions, pet food in the pet slot during taming. Relation
  cardinalities now count equipped items rather than storage positions and allow an item type
  multiple eligible slots (rings, weapons). Existing indices, stats and gameplay are unchanged.
- [ ] **Equipment implementation — deferred (item 3):** after explicit implementation approval,
  normalize live `equipment-slots.json#accepts` to item-type IDs (`light`, `special`, `weapon`),
  express subtype restrictions and pet-food placement, and align the validator/consumers with
  the approved model. Live slot JSON is deliberately unchanged: current `items.gd#slot_id`
  consumes it directly. Wand handedness and traversal gates are now recorded above; their
  live-data migration/enforcement remains separately deferred.
- [x] **Duplicate `block` identity (item 4, 2026-09-15):** kept the voxel `block` in `domain.md
  §3.1`, renamed only the defensive class to `combat-block` in §3.3, and corrected the heading
  reference in `generators.json#design.defence._doc`. Runtime config/event keys and all terrain,
  block-power, MP and damage-reduction behavior are unchanged.
- [x] **Recipe quantities (item 5, 2026-09-15):** split `recipes.json#gear-weapons.boomerang|wand`
  into a 20-wood-cube `boomerang` recipe and the unchanged provisional 10-cube `wand` recipe.
  Both remain at the workbench. All other recipe data, gem requirements and weapon behavior
  are unchanged. This reconciles the recipe with `generators.json#design.recipes` (D6).
- [x] **Creature source IDs (item 6, 2026-09-15):** clarified `entity.species`, the legacy
  `creature.alpha-entity-id`, `pet-food`, `tamed-by` and `c-food-id` in `domain.md`; aligned
  `Creature` / `PetFood` comments and the creature/food JSON `_doc` fields. Stable and numeric
  IDs, version tags, taming pairs, legacy property names and executable loader/validator logic
  are unchanged. F10's reserved-alpha-ID distinction and unrecorded IDs are preserved.
- [x] **Boss spirit-cube exception (item 7, 2026-09-15):** aligned `domain.md#spirit-cube`,
  `#loot-rule`, `gen-boss`, `generators.json#boss.alpha-spirit-drop` and `economy.json#loot.A-boss`
  with the approved hybrid mission-boss exception. Preserved the source notes on Saurians and
  alpha boss-kill missions, existing mission reward data, spirit effects and level restrictions.
  No executable drop logic, numeric balance or ruleset flags changed.
- [x] **Reference versus hybrid scope (item 8, 2026-09-15):** clarified `domain.md §0/§1/§7`,
  the reference-only `region-lock` entry, `rulesets.json` annotations, `generators.json` annotations
  and `ontology/README.md`. Recorded permanent exclusion of regional gear power loss, not a
  roadmap option. Historical data and all live flags/balance values preserved. Settlement/inn
  and traversal targets are now recorded above; artifact approvals are tracked above, while other unresolved merges remain open. Walkthrough protocol
  and the explicit stop/resume route are recorded in `tasks/lessons.md` and `docs/HANDOFF.md`.
- [x] **Validation contract — ontology (item 9, 2026-09-17):** recorded the approved direction
  in `domain.md §5`, clarified `c-versions-nonempty` and split `c-artifact-stat` between
  definition and generated-instance checks. The roadmap and handoff distinguish applied
  documentation from deferred enforcement.
- [ ] **Validator gaps — implementation deferred (item 9):** after separate authorization and
  the mapping above, add negative checks for missing races and whole moveset blocks, wrong
  root/row shapes, both directions of class/spec references, spec cardinality/start index,
  rootless shared skill columns and handedness-specific cube capacities. Enforce documented
  provenance, separate artifact-definition/generated-instance checks and failure on accumulated
  errors. Currently `Ontology.validate()` checks only whether its pass adds errors; the runner
  separately checks accumulated errors. The approved boolean contract is not implemented.
  `model.gd#Ontology` and `validate.gd` are unchanged; no new checks are implemented.
- [x] **Panel-time policy — ontology (item 10, 2026-09-17):** documented live time for inventory,
  skill-tree and shop panels in solo and multiplayer in `domain.md §3.7`. Gameplay and live
  instance data are unchanged; runtime fixes were not authorized.
- [x] **Damaging-channel miss/reset boundary — ontology (item 10, 2026-09-17):** documented the
  whole-channel rule in `domain.md#combo-system` and `c-combo-reset`, including early ends and
  unchanged inactivity expiry / combo gains / caps. Runtime fixes stay deferred.
- [x] **Zero-damage taunts — ontology (item 10, 2026-09-17):** documented combo neutrality in
  `domain.md#combo-system` and `c-combo-reset`, including no inactivity-timer refresh and no-target
  casts. Taunt/healing effects and threat/targeting decisions are unchanged; runtime fixes stay deferred.
- [x] **Poison ticks during dodge — runtime repair (item 10, 2026-09-17):** retained the source
  status ID in the shared tick slot and passed it through `take_damage`; only poison ticks bypass
  dodge i-frames. Extended `test_creature_roles.gd` with tick damage/cadence/feedback and unchanged
  burning/direct-hit dodge checks. Poison balance, shared-slot replacement and all other runtime
  corrections are unchanged.
- [x] **Block exhaustion — runtime repair (item 10, 2026-09-17):** `blocks_from` now checks
  remaining power per hit. `take_damage` returns that hit's block result so melee, projectile and
  player-strike callers preserve attached-status protection even when the valid block empties
  the bar. No persistent hit cache or new balance/config is added. `test_defence.gd` checks
  consecutive melee/projectile hits without a defence update, with 25 or 1 power remaining:
  final valid block protected, next hit normal, no extra MP, and correct attached statuses.
- [x] **Hand conflict — runtime repair (item 10, 2026-09-17):** `Inventory.equip` checks the
  prospective hand pair before mutating the bag/equipment or emitting `changed`, rejecting a
  loaded two-handed main weapon plus occupied off-hand (currently shields). The regression
  checks greatsword and bow in both equip orders, unchanged bag order/worn gear/coins, no
  change signal and no item loss/duplication; valid swaps work after removing the conflict.
  No slot data, handedness classifications, class checks or other equipment-model work changed.
- [x] **Panel-time — runtime repair (item 10, 2026-09-17):** removed the shared panel early
  return in `player.gd`; existing simulation continues while movement, jump/swim-up, dodge,
  held block, combat and interaction input remain gated. Existing active effects and forced
  movement continue, with no new actions permitted. A lethal DOT stops the frame. Real-panel
  regressions cover inventory, skills and shop, timer expiry/cadence and unchanged input
  restrictions. No balance, instance data, other menus or class-ability combo handling changed.
- [x] **Class-ability combo runtime repair (item 10, 2026-09-17):** damaging class strikes
  reuse `_landed(false)` for combo gain/timer/cap without M1 rewards. Non-channel misses reset;
  channels accumulate hits and settle a miss only on normal or early end (stamina exhaustion
  or runtime reset). Zero-damage taunts/heals stay neutral. `test_class_combos.gd` covers the
  hit/miss/expiry/end cases, existing costs/damage and neutral support/movement skills. The
  old War Frenzy damage test now explicitly starts from zero combo, isolating its buff assertion
  from newly counted earlier class hits. No instance data or projectile/player runtime changed.
- [x] **Artifact/document cleanup (2026-09-17):** corrected the shop reference to
  `economy.json#shops` and the research path; removed the duplicate `prices.formula` description
  without changing its effective value. Reconciled current/open/historical summaries and stale
  dodge, stealth, poison, taunt and visual-check claims across the ontology README, roadmap,
  implementation backlog and handoff. `domain.md §7` now indexes the existing open hybrid
  questions separately from research uncertainties and optional fields; D13 hitboxes, D14
  current chase numbers and D15 armor stay decided. Research dumps, runtime and validator/loader
  code remain untouched. Parsed-data equivalence and targeted runtime checks pass; correctness
  review found no issues and both ponytail prose-reduction suggestions were applied.

- [x] **Aggro damage contribution — ontology (2026-09-18, subsequently corrected):** replaced
  raw-HP gain in `domain.md#ai-behavior` with maximum-HP-percentage gain, preserving fractional
  points. Updated the handoff and correction lesson; that checkpoint was the numeric decay
  rate, since approved below. Runtime, instance data and all other aggro decisions are unchanged.
- [x] **Aggro current-target ties — ontology (2026-09-18):** recorded the retention rule in
  `domain.md#ai-behavior` and narrowed the open list/checkpoint to other target-selection ties.
  Damage conversion, runtime, instance data and other unresolved decisions are unchanged.
- [x] **Aggro other-target ties — ontology (2026-09-18):** recorded the earliest-engagement
  fallback in `domain.md#ai-behavior`, preserved prior targeting priorities and advanced the
  checkpoint to passive threat decay. Runtime, instance data and other open decisions unchanged.
- [x] **Aggro decay policy — ontology (2026-09-18):** recorded constant per-mob/player decay,
  concurrent damage gains and retained threat across target changes; advanced the checkpoint
  to the numeric rate. Recorded the correction in `tasks/lessons.md`. Instance data, runtime
  (including D16 simulation), validator/loader and unresolved boundary rules remain unchanged.
- [x] **Aggro relationship model — ontology (2026-09-18):** added the two relation definitions,
  pair-scoped numeric amount/unit, runtime-layer constraints and illustrative facts; CQ12 now
  references them. The numeric rate was still open at that checkpoint; no executable or live data changes.
- [x] **Aggro decay rate — ontology (2026-09-18):** recorded continuous decay at 1 aggro point/s
  in `domain.md#ai-behavior`, removed the rate from open-question indices and advanced the
  handoff to zero-threat behavior. Runtime, live data and other aggro decisions are unchanged.
- [x] **Zero-threat behavior — ontology (2026-09-18):** recorded the zero floor and normal
  hostile-detection boundary in `domain.md#ai-behavior` and the relation constraints. Updated
  the open-question indices and handoff to reset conditions, starting with player death.
  Runtime, live data, existing targeting priorities and unresolved reset rules are unchanged.
- [x] **Player-death aggro clearing — ontology (2026-09-19):** recorded the approved rule
  in `domain.md#ai-behavior`, aligned §4/§5/§7 and advanced the handoff to engagement-order
  resets. Runtime, live data and all other unresolved decisions are unchanged.
- [x] **Engagement order on death — ontology (2026-09-19):** extended the player-death rule
  in `domain.md#ai-behavior`, aligned §4/§5/§7 and advanced the handoff to engagement order
  when threat decays to zero. Runtime, live data and other unresolved decisions are unchanged.
- [x] **Zero-threat order clearing — ontology (2026-09-19):** recorded the owner's correction
  in `domain.md#ai-behavior`, aligned §4/§5/§7, recorded the lesson and advanced the handoff
  to fresh-order assignment after zero threat. Runtime, live data and other open decisions unchanged.
- [x] **Fresh engagement order — ontology (2026-09-19):** recorded assignment on regaining
  positive threat in `domain.md#ai-behavior`, aligned §4/§5/§7 and advanced the handoff to
  aggro / engagement-order resets on escape. Runtime, live data and other open decisions unchanged.
- [x] **Escape retention — ontology (2026-09-19):** recorded the approved rule in
  `domain.md#ai-behavior`, aligned §4/§5/§7 and advanced the handoff to whole-fight aggro /
  engagement-order reset. Runtime, live data and other open decisions unchanged.
- [x] **Return-home trigger — ontology (2026-09-19):** recorded the approved rule in
  `domain.md#ai-behavior`, added `c-return-home`, aligned §4/§7 and advanced the checkpoint to
  attacks interrupting return. Recorded the owner's presentation correction in `tasks/lessons.md`.
  Runtime, live data and other open decisions unchanged.
- [x] **Protected return — ontology (2026-09-19):** recorded speed, resistance, non-interruption
  and arrival recovery in `domain.md#ai-behavior` / `c-return-home`, aligned §7 and advanced the
  handoff to arrival aggro/order reset. Runtime, live data and other open decisions unchanged.
- [x] **Arrival aggro/order reset — ontology (2026-09-19):** recorded the approved per-mob
  arrival rule in `domain.md#ai-behavior`, aligned §5/§7 and advanced the handoff to zero-aggro
  fallback selection. Runtime, live data and other open decisions unchanged.
- [x] **Nearest-detected zero-threat fallback — ontology (2026-09-19):** recorded the rule in
  `domain.md#ai-behavior` / `c-current-target`, aligned §7 and advanced the handoff to exact-distance
  ties. Recorded the requested publication/stop point. Runtime, live data and other open decisions unchanged.

**Items 1–2 verification (2026-09-15):** `timeout 90 nix develop -c godot --headless -s <script>`
passed for `ontology/validate.gd`, `game/items/test_items.gd` and
`game/world/test_settlement.gd`; all `ontology/instances/*.json` parse as objects with `jq`;
`git diff --check` passed. Before the pool correction, the added regressions failed only for
Cookie (142 drops in the seeded 4,000-kill test; present in shop stock). Relation rows were
reviewed against existing D6 / `c-artifact-stat` and Steam Intercept data; the headless validator
does not validate Markdown cardinalities. These checks do not close the other audit findings.

**Item 3 verification (2026-09-15):** `timeout 90 nix develop -c godot --headless -s
ontology/validate.gd` passed. `jq` confirmed 13 slot entries with indices 0..12, an empty
reserved `unknown-0`, and the separate Q field. Semantic review matched the approved equipment
model to existing item-type definitions; the validator does not check Markdown semantics.
`git diff --check` passed; `game/`, instance JSON and validator code are unchanged. No claim
that the deferred equipment behavior is implemented or tested at runtime.

**Item 4 verification (2026-09-15):** the headless ontology validator and `git diff --check`
passed. Heading inspection confirmed one `block` and one `combat-block`; ontology reference
review found and corrected the generator's §3.3 heading reference. A `jq` comparison against
`HEAD` confirmed the generator change is exclusively that `_doc` wording. Gameplay, validator
code, equipment data, weapon definitions and the still-pending recipe data are unchanged.

**Item 5 verification (2026-09-15):** a targeted `jq` check failed before the correction and
passed after: separate boomerang/wand rows, 20/10 wood cubes respectively, boomerang station
`workbench`, no shared row. A full JSON comparison against `HEAD` confirmed that only this
split and the boomerang quantity changed. The headless ontology validator and
`git diff --check` passed. Gameplay, validator code, weapon definitions, creature/food pairs
and live equipment data are unchanged. No finished crafting UI/runtime is claimed.

**Item 6 verification (2026-09-15):** the headless ontology validator and
`game/entities/test_creature_roles.gd` passed. `jq` checked the two named post-alpha IDs,
version tags and bidirectional food pairings; full JSON comparisons against `HEAD` confirmed
both creature and pet-food files differ only in `_doc`. Diff review confirmed `model.gd`
changes are comments only; `game/` and validator runner are unchanged. `git diff --check`
passed. Source namespace clarification was reviewed against research §2.5 and F10; no
claim that the future taming system is implemented.

**Item 7 verification (2026-09-15):** the headless ontology validator,
`game/items/test_items.gd` and `git diff --check` passed. Semantic review confirmed the
mission-boss exception across the domain's three descriptions and both JSON loot descriptions.
JSON comparisons confirmed all other economy data and generator values unchanged (apart from
the previously approved item 4 `_doc` correction). `game/`, the validator runner, mission
reward data and ruleset flags are unchanged. These checks do not test a spirit-cube drop
runtime; that remains unimplemented.

**Item 8 verification (2026-09-15):** the headless ontology validator,
`game/items/test_items.gd`, `game/world/test_settlement.gd` and `git diff --check` passed.
All instance JSON files parse as objects. Comparisons against the pre-item-8 working files
confirmed only `rulesets.json` annotations (`_doc`, hybrid `_rule`, Omega `_note`) and
`generators.json` root/design `_doc` changed; every other value, including prior approvals,
is unchanged. Hybrid remains default with region-lock, plus-items, worn-rarity and per-land
inventory disabled, and global key items enabled. `game/` and the validator runner are unchanged.
Semantic/simplification review checked the scope distinctions, permanent exclusion and explicit
walkthrough stop/resume route. This is not proof that the validator covers every semantic rule.

**Item 9 verification (2026-09-17):** `timeout 90 nix develop -c godot --headless -s
ontology/validate.gd` and `git diff --check` passed. Scope/checkpoint checks confirmed
documentation-only changes, documentation approved/applied versus enforcement deferred,
and matching next-item pointers in the roadmap/handoff. Semantic and simplification review
preserved the approved policy and left unresolved mappings open. `game/`, instance
JSON, `model.gd` and `validate.gd` are unchanged. The existing validator does not validate this
Markdown or prove the proposed negative checks work; no enforcement fix is claimed.

**Item 10 policy verification (2026-09-17, before the runtime repair):** the headless ontology validator, `git diff --check`
and documentation-only scope checks passed. Semantic, `/simplify` and `ponytail-review` passes
preserved the panel-time and whole-channel rules, including early ends, normal inactivity expiry
and existing damaging-hit gains / caps. Zero-damage taunts are now combo-neutral, with no timer
refresh even when no enemy is affected; threat/targeting decisions remain separate. Next-topic
pointers matched. At that documentation-only stage, only `domain.md`, this roadmap and
`docs/HANDOFF.md` changed; gameplay, instance JSON and validator code were unchanged. The
validator does not check these Markdown policies or prove runtime compliance.

**Item 10 poison runtime verification (2026-09-17):** the new regression first failed with
0 HP lost instead of 10 during dodge, no DOT number and a second discarded poison tick. It
passed after the identity-preserving fix. All 13 `game/*/test_*.gd` scripts, `ontology/validate.gd`
and `godot --headless --quit` passed under `nix develop`, each bounded by `timeout 90`.
The regression also checks tick cadence, one DOT number without a hurt bundle, ordinary-hit
immunity after a poison tick, and burning replacing poison without inheriting its dodge exemption.
Live ontology instance data and balance were unchanged. At the poison-repair checkpoint,
panel-time, combo, block-exhaustion and hand-slot runtime fixes remained deferred; the later
block authorization/application is recorded separately above. `/simplify` retained the existing shared-slot runtime;
independent correctness and `ponytail-review` passes found no issues in the runtime/test diff.
The reviewer inspected the red/green/suite logs rather than rerunning tests.

**Item 10 block-exhaustion verification (2026-09-17):** `test_defence.gd` first failed 14
assertions: the second melee/projectile hit lost only 20 HP rather than 100, awarded a second
8 MP, and incorrectly suppressed statuses. It passed after the per-hit check/result propagation.
The regression preserves the exhausting hit's protection, tests positive power below one hit's
cost, and verifies stun/knockback plus a projectile's additional slow status. All 13 game tests,
`ontology/validate.gd` and headless boot passed under `timeout 90 nix develop -c godot …`.
Logs: `/tmp/pixlnd-block-exhaustion/{red,green,suite}.log` (session-local evidence). Live instance
JSON, balance and validator logic are unchanged. `/simplify` retained the per-hit return value
rather than a persistent hit cache; independent correctness and `ponytail-review` passes found
no issues. Reviewers read the source and red/green/suite logs, not rerun tests. The new projectile
regression invokes the impact callback; player-origin and Cyclone-specific exhaustion were
source-traced, not covered by dedicated new regressions. At that checkpoint, panel-time, combo
and hand-slot fixes remained deferred; the later hand-conflict approval/application is recorded
separately. No commit or push was authorized by the block repair approval.

**Item 10 equipment-conflict verification (2026-09-17):** `test_items.gd` first failed 12
assertions: greatsword/shield and bow/shield were accepted in both equip orders, changed bag/worn
state and emitted `changed`. The test passed after the pre-mutation hand-pair check. It also
checks no loss/duplication or coin changes and successful valid replacements after resolving
the conflict. All 13 game tests, `ontology/validate.gd` and headless boot passed under
`timeout 90 nix develop -c godot …`. Logs: `/tmp/pixlnd-equipment-conflict/{red,green,suite}.log`
(session-local evidence). SHA-256 checks confirmed the earlier uncommitted block runtime/test
files are untouched. Live instance JSON, balance, loader and validator remain unchanged.
`/simplify` retained the prospective-pair guard; independent correctness and `ponytail-review`
passes found no issues. Reviewers inspected source and red/green/suite logs without rerunning
tests. Other weapon classifications, shield-for-shield and non-hand swaps were source-traced,
not individually regression-tested. Panel-time, combo and the broader equipment-model
implementation are still deferred; no commit or push is authorized by this repair approval.

**Item 10 panel-time verification (2026-09-17):** `test_panel_time.gd` first failed 40
assertions, reproducing frozen poison, cooldowns, buffs and dodge expiry in all three real
panels (some failures were downstream of the freeze). It passes after the input/simulation
separation. Its swimming fixture was moved off the floor so collision does not zero sink
velocity. The regression checks poison cadence, ordinary-hit immunity before and vulnerability
after dodge expiry, single-step cooldown progression, normal combo inactivity, gameplay-input
suppression, movement after closing and lethal DOT. All 14 game tests, ontology validation and
headless boot passed under `timeout 90 nix develop -c godot …`. The same regression passed
windowed; a temporary copy captured each native panel for inspection (no browser UI). The
fixture's narrow window clips the wider panels; no UI layout fix is claimed or included.
Logs/captures: `/tmp/pixlnd-panel-time/{red,green,suite,visual}.log` and three panel PNGs
(session-local evidence). `/simplify` retained the existing single simulation flow rather than
adding separate timer machinery. Independent correctness and ponytail reviews found no issues;
reports are `correctness-review.md` and `ponytail-review.md` in the same log directory. Reviewers
inspected source and logs, not rerun tests. Active dash/channel/cast/heal continuation, knockback,
resource regeneration, ultimate input, the abilities-null branch and stored special charges
were source-traced, not individually regression-tested while browsing. The fixture manually
steps player physics, batches gameplay input and opens shops through `_open`, not vendor
interaction; no event-ordering or multiplayer/network claim is made. Live instance JSON,
balance and `abilities.gd` are unchanged. Combo repair, other deferred work, commit and push
remain unauthorized.

**Item 10 class-ability combo verification (2026-09-17):** `test_class_combos.gd` first failed
17 assertions for missing burst/dash hit/miss handling, channel completion and gains/caps.
It passes after the shared strike-result bookkeeping and channel end settlement. Regressions
cover multi-target bursts counting once, dash impact, empty/late/multiple channel hits, normal
duration and early stamina/reset endings, inactivity after a successful channel hit, sword/staff
caps, no M1 MP/finisher reward, unchanged strike damage/costs/cooldowns, Heroic Shout neutrality
with/without targets and unchanged taunt/healing effects, non-attacking buffs/movement/heals,
and a projectile's side heal versus whole-volley miss. The first full suite exposed the existing
War Frenzy fixture's zero-combo assumption; explicitly resetting that fixture's combo preserves
its intended buff-only assertion. All 15 game tests, ontology validation and headless boot then
passed under `timeout 90 nix develop -c godot …`. A temporary windowed copy binds the real HUD,
asserts `combo 5` on the burst hit and an empty combo label on its miss; both PNGs were inspected.
Logs/captures: `/tmp/pixlnd-class-combo/` (`red.log`, `green.log`, initial `suite.log`,
`abilities-green.log`, `suite-green.log`, `visual.log`, `combo-hit.png`, `combo-miss.png`).
The windowed run reported an ignored Nix evaluation-cache busy warning during concurrent Nix
startup; Godot and all assertions completed successfully. No browser or multiplayer test is
claimed. SHA-256 checks confirm the completed panel-time player/test files are unchanged;
live instance JSON, validator and projectile runtime are unchanged. `/simplify` retained one
shared strike path and one channel-end helper used by normal completion and reset. Independent
correctness and ponytail reviews found no issues (`correctness-review.md`, `ponytail-review.md`
in the same directory); reviewers inspected source/logs and HUD captures, not rerun tests.
The fixture manually settles dash impacts and steps ability timers: wall-triggered completion,
death calling reset, multi-target channel counting and successful class-projectile
non-double-counting were source-traced rather than individually asserted by the new regression.
No other deferred work, commit or push is authorized.

**Artifact/document cleanup verification (2026-09-17):** the staged repairs were first committed
as `44ab0a1` (rebased reference) after all 15 game tests, ontology validation and headless boot passed again. Cleanup
changes only six Markdown files and the removal of one duplicate economy description key.
Sorted `jq` output before/after is identical; `prices.formula` occurs once, all instance files
parse as objects, and runtime, validator/loader and research files have no diff. The ontology
validator, item and settlement tests, and headless boot passed again under `timeout 90 nix develop
-c godot …`; `git diff --check` passed. A source review reconciled the specific stale claims;
this does not prove every ontology semantic rule is enforced. The existing open-question list
is unchanged, with an index added to `domain.md §7`; no choice was silently resolved. No new
browser/windowed check is needed for this behavior-preserving documentation change. Evidence:
`/tmp/pixlnd-doc-cleanup/{precommit-suite,checks}.log` and sorted economy snapshots. `/simplify`
kept the open-question index concise and preserved historical D/F records rather than rewriting
them as current implementation. Independent correctness review found no issues; ponytail review
recommended removing duplicated cleanup authorization from §7 and repeated handoff scope/status.
Both suggestions were applied; approval remains in §E and verification links replace repeated
prose. Reviewers inspected source and supplied logs/captures, not rerun tests. Reports are
`correctness-review.md` / `ponytail-review.md` in the same evidence directory; post-adjustment
checks are recorded in `final-checks.log`.
At that verification checkpoint the cleanup diff remained uncommitted; it was subsequently
committed before the authorized rebase. No push or further gameplay implementation is authorized.

**Aggro ontology verification (2026-09-18):** the headless ontology validator
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
scope checks passed after each approval/direction. Only `domain.md`, this roadmap,
`docs/HANDOFF.md` and `tasks/lessons.md` changed; runtime, live instance data and validator/loader
code are unchanged. Structural checks confirm unique relation/constraint IDs, entity-instance
endpoints, the `n→n` / `1→0..1` cardinalities and runtime-layer constraint labels. Semantic,
`/simplify` and ponytail review preserved the approved rules and separate pair-scoped amount /
target selection, while leaving the example decay rate and boundary decisions open. Redundant
explanatory prose was removed; examples remain illustrative, not static data or balance defaults.
The validator does not check these Markdown rules or prove runtime compliance; aggro
implementation remains unauthorized.

**Publication readiness (2026-09-18):** all 15 `game/*/test_*.gd` scripts, ontology validation
and headless boot passed again under `nix develop`, each Godot run bounded by `timeout 90`.
Scope/structural checks passed. Fresh read-only correctness and ponytail reviews found no issues;
they reviewed the patch and sources, not rerun tests. Ready to publish this documentation and
resume the walkthrough at the numeric decay rate, not to implement aggro. Evidence is session-local
in `/tmp/pixlnd-aggro-handoff.yS0KLL/` (`suite.log`, `correctness-review.md`, `ponytail-review.md`).
No visual test was needed for this documentation-only change.

**HP-normalized aggro correction verification (2026-09-18):** percentage-gain arithmetic
checks passed for 20/200 and 2000/20000 HP (10 points each), fractional gains and zero damage.
Stale-rule/scope checks, `git diff --check` and the headless ontology validator passed. Only
`domain.md`, this roadmap, the handoff and lessons changed; runtime/live data remain unchanged.
`/simplify` removed duplicate checkpoint rationale; ponytail review found no further cuts.
The validator does not check this Markdown formula; no runtime aggro test is claimed.

**Aggro decay-rate verification (2026-09-18):** arithmetic checks cover equal-percentage
hits at two HP scales, fractional elapsed time and concurrent gains; rate/checkpoint and
scope checks, `git diff --check` and the headless ontology validator passed. `/simplify` and
ponytail review retained the documentation-only scope; no runtime compliance is claimed.

**Zero-threat verification (2026-09-18):** documentation checks confirm the zero floor,
normal hostile-detection boundary, preserved gain/rate and next checkpoint. Scope checks,
`git diff --check` and headless ontology validation passed. `/simplify` shortened the checkpoint;
ponytail review found no further cuts. No runtime or live-data changes; Markdown checks do not
prove gameplay compliance.

**Normalized-aggro publication readiness (2026-09-18):** all 15 game tests, ontology validation
and headless boot passed, each Godot run bounded by `timeout 90`. Fresh read-only correctness
and ponytail review found no issues; the reviewer inspected documentation, not runtime tests.
The four-file Markdown scope preserves all runtime/live data. The player-death proposal remains
presented but unapproved, and the next agent must start at `docs/HANDOFF.md`. Session-local
suite/review evidence: `/tmp/pixlnd-aggro-publish.TliE3c/`. No visual test was needed; the green
suite does not prove runtime implementation of the new ontology rules.

**Player-death aggro verification (2026-09-19):** `timeout 90 nix develop -c godot --headless
-s ontology/validate.gd`, `git diff --check` and documentation/scope checks passed. Only
`domain.md`, this roadmap and the handoff changed. Checks confirm the approved death rule,
unchanged prior aggro rules, unique relation/constraint IDs and matching next-question pointers.
`/simplify` removed repeated handoff wording; ponytail review found no further cuts. Runtime,
live data and validator code are unchanged; the validator does not check this Markdown rule,
and no runtime implementation or compliance test is claimed.

**Death/engagement-order verification (2026-09-19):** headless ontology validation
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
three-file Markdown scope checks passed. Documentation checks confirm the new death/order
rule, unchanged prior aggro/death rules, unique relation/constraint IDs and matching next-item
pointers. `/simplify` shortened the relation cross-reference; ponytail review found no further
cuts. Runtime, live data and validator code are unchanged. The validator does not check this
Markdown policy; no gameplay implementation or runtime compliance test is claimed.

**Zero-threat order-clearing verification (2026-09-19):** headless ontology validation
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
four-file Markdown scope checks passed. A punctuation-sensitive comparison was corrected;
checks confirm unchanged prior gain/decay/targeting/pursuit/death rules, the new memory-clearing
rule, unique relation IDs, matching checkpoints and the lesson. `/simplify` shortened the decision
record; ponytail review found no further cuts. Runtime, live data, HEAD and index are unchanged.
The validator does not check this Markdown policy; no gameplay compliance test is claimed.

**Walkthrough handoff publication checks (2026-09-19):** headless ontology validation,
`git diff --check` and documentation/scope checks passed again. The complete pending publication,
including the two local death-rule commits, differs from the fetched remote only in four Markdown
files; there was no remote divergence. `/simplify` reused the existing walkthrough protocol;
ponytail review found no further cuts. The next agent must wait for a resume prompt and present
fresh-order assignment without choosing a trigger. No gameplay or runtime enforcement is claimed.

**Fresh-order verification (2026-09-19):** headless ontology validation
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
three-file Markdown scope checks passed. Documentation checks cover the positive-threat trigger,
priority preservation, unchanged gain/decay/pursuit rules, unique relation/constraint IDs and
matching checkpoints. `/simplify` shortened the relation cross-reference; ponytail review found
no further cuts. Runtime and live data are unchanged; the validator does not enforce this Markdown rule.

**Escape-retention verification (2026-09-19):** headless ontology validation
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
three-file Markdown scope checks passed. Documentation checks preserve prior aggro/death rules,
confirm escape retention without new chase/healing rules, check unique relation/constraint IDs
and matching checkpoints, and verify the 8-point decay example. `/simplify` and ponytail review
kept the change documentation-only. Runtime and live data are unchanged; the validator does not
enforce these Markdown rules, and the arithmetic check is not a gameplay test.

**Return-home verification (2026-09-19):** headless ontology validation
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
four-file Markdown scope checks passed. Checks confirm the existing 30-block value, unchanged
prior aggro/targeting rules, the return branches, unique relation/constraint IDs, preserved open
questions, matching checkpoints and the wording correction. `/simplify` shortened the relation
cross-reference; ponytail review found no further cuts. Runtime and live data are unchanged;
the validator does not enforce these Markdown rules, and no gameplay compliance test is claimed.

**Protected-return verification (2026-09-19):** headless ontology validation
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
four-file Markdown scope checks passed. Nix reported an ignored busy eval-cache warning;
Godot completed successfully. Documentation checks preserve prior aggro/return-trigger rules,
verify speed/damage/aggro arithmetic, temporary bonuses, DOT coverage, one-time alive-only
recovery, exclusions, unique relation/constraint IDs and matching checkpoints. The pending
walkthrough clarification is included. `/simplify` removed duplicate handoff wording; ponytail
review found no further cuts. Runtime and live data are unchanged; neither the arithmetic checks
nor the validator prove gameplay implementation of these Markdown rules.

**Arrival-reset verification (2026-09-19):** headless ontology validation
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
three-file Markdown scope checks passed. Documentation checks preserve prior aggro/return and
protection rules, confirm the once-per-arrival, alive-only, per-mob reset and subsequent DOT /
detection behavior, unchanged relation definitions, unique IDs and matching checkpoints.
`/simplify` removed duplicate cross-references; ponytail review found no further cuts. Runtime
and live data are unchanged; the validator does not enforce these Markdown rules, and no
runtime compliance test is claimed.

**Nearest-fallback handoff/publication verification (2026-09-19):** all 15 game test scripts,
ontology validation and headless boot passed under `nix develop`, each Godot process bounded by
`timeout 90`; logs contain no script/runtime errors. `git diff --check` and documentation checks
confirm preserved earlier rules, nearest fallback without aggro/order gains, exact-distance ties
left open, unchanged relation definitions, unique IDs and matching publication/stop checkpoints.
The fetched tracking branch has no divergence; the five prior local commits plus this change
modify only `domain.md`, this roadmap, the handoff and lessons. `/simplify` removed repeated
handoff instructions; ponytail review found no further cuts. Session-local logs are in
`/tmp/pixlnd-nearest-handoff.0EH8bK/`. The next agent must wait for a resume request and present
exact-distance ties without choosing a default. Runtime/live data remain unchanged; the green
suite does not establish implementation of the new ontology policies. No visual test was needed.

**Aggro batch 1–12 verification (2026-09-27):** before each item commit,
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`
passed (`ontology valid`). Scope/structure checks confirmed only the five authorized Markdown
files changed, unique relation/constraint IDs and unchanged historical D/F records. Per-item
semantic review, then `/simplify` and ponytail-review kept canonical rules in `domain.md` and
compact ledger/checkpoint links; these were writer self-reviews, not independent reviews.
Logs/diffs: `/tmp/pixlnd-aggro-record-20260927/item-<1..12>-{validator,diff-check,scope,review}.log`
and `item-<1..12>.diff` (session-local). No runtime/live JSON/test changes or gameplay compliance
claim: the validator does not check Markdown semantics. At that checkpoint questions 13–14
were OPEN; the owner subsequently approved both, with separate application tracked above.

**Aggro follow-ups 13–14 verification (2026-09-27):** each separate documentation commit
passed the same bounded ontology validator, `git diff --check` and scope/structure checks as
items 1–12. Writer semantic review, `/simplify`, then ponytail-review preserved earlier approvals
and replaced only the formerly open boundaries with the subsequent explicit owner decisions.
Evidence: `item-13` / `item-14` logs and diffs in `/tmp/pixlnd-aggro-record-20260927/`.
No runtime/live data/tests changed; no gameplay compliance is claimed. Next: Creature family membership.

**Aggro final acceptance (2026-09-27):** fresh read-only independent review inspected the updated
fourteen-item approval packet, individual/combined diffs, final sources, per-item logs and reflog;
no recording defects or additional unanswered aggro cases were found. `/simplify` and ponytail
review found nothing further to cut. The reviewer did not execute tests; the parent separately
ran the bounded ontology validator and `git diff d59396d..HEAD --check`, inspected all fourteen
commit entries and confirmed the clean worktree. Review artifact (session-local):
`~/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/0c1a31b5-eb56-479b-b6d8-7576cc05dddc/aggro/final-review.md`.
No fresh gameplay, visual or networking tests are claimed. At that historical checkpoint,
publication was requested and the three creature-family proposals were unanswered; their
subsequent approvals and current handoff/publication authorization are recorded above.

**Audit verification baseline (not proof of consistency):** `ontology/validate.gd`,
`game/items/test_items.gd`, `game/combat/test_defence.gd` and
`game/entities/test_creature_roles.gd` passed at `e4f87f5`. Memory-only negative probes still
accepted missing races/movesets, 32-cube one-handed swords, missing pet-food versions, duplicate
spec indices, reversed starting-spec order, rootless shared columns and empty artifact stat kinds.
Runtime probes reproduced the four violations above. Add regressions for these cases; do not
rely on the old green tests or temporary probe files surviving the session.

## Initial scaffold — DONE 2026-09-08 (`project.godot`, `game/`)
The router-derived scaffold loads `instances/` through `ontology/model.gd`. For subsequent
slices, resolve relevant §E questions, sync `ontology/`, then route implementation.
