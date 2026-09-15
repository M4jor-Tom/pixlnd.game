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

**Current completion authority/status (2026-10-11):** latest exact owner instruction:
**“Finish approving item 111 from handoff, then handoff, commit, push”.**
This supersedes the historical owner STOP/NO PUSH checkpoints only for finite 108–111
completion, verified status/handoff maintenance and normal publication of the current
`fix/ontology-reconciliation` branch after prerequisites and parent acceptance/native
acknowledgment. Only the final publisher may access remote Git/push; this status writer does
neither. Source approval itself is not publication authority. Source items **1–111 handled**;
finite **108–111 complete locally**; pending queue absent after verified 111 canonical recording.
Current §7 status/authority references now match; older per-item source-choice restrictions
remain dated original permission, not the later separate explicit publication grant.
This is a **prepublication checkpoint**: independent review of the exact status/handoff diff,
fresh separate gates, then the exact scoped maintenance commit with actual hash/parent/scope/
full-diff verification. A fresh finite committed-state audit bound to that maintenance HEAD
must follow, then explicit parent native acceptance/acknowledgment, then the conditional
publisher for normal publication of that same HEAD on `fix/ontology-reconciliation` only.
External native publication receipt/live Git, not this checkpoint, establishes the actual
result. Verify fresh clean local HEAD/configured upstream/remote-tracking/live remote exact
equality, then stop; no merge, force-push or history rewrite.
No further research/inventory/items or new debt; all earlier choices, HOLDs/gaps and UNAPPROVED
leads stand. Queue exhaustion is not universal source exhaustion. Item90 delivery limitation/
recovered review and item97 authorized POSTcanonical validator timing remain unchanged.

Verified local canonical/separate receipt pairs (actual immutable Git history; per-item
review/gate chronology and limits remain in the receipts below):

| item | canonical commit | separate receipt commit |
|---|---|---|
| 108 | `1516db4503e426684eddab9c0923f7738cd205ff` | `9ed525c1df4611c6beb6de02eefee7e2020a9919` |
| 109 | `ce3ea42dfdb8bab6682ed24c73c00c55ed5ffeeb` | `8f73213d2ae0aa9aabd0edb9c3458f20e8000c7e` |
| 110 | `3ab368988920d887ed2885767cfb7cf347c1673d` | `c6c5a92ed7d7900ec4eafd8d294032eee9a5541d` |
| 111 | `162fadfee9437eb2c30e24cd39eb07bdd8188df8` | `90200efc2a61aba637bc9bda2fa380b15cf7e85b` |

Item111 receipt parent is `162fadfee9437eb2c30e24cd39eb07bdd8188df8`; its full four-path
26987-byte diff SHA-256 is `6310862b1603df23b377bd50901ea778516c9815ae3a5a6c3035c4a0484b04c0`.
It changes HANDOFF, this §E, README and deletes only the exhausted pending queue; domain
is byte-identical across that receipt. Bound finalizer report/evidence:
`2b746b7b-b469-4768-b52b-07a7c1e59625/receipts/item111.json` / `item111-evidence/`
under the managed output root below. Separate fresh receipt whitespace/validator both
passed **before** receipt commit: 17:06:44.337335Z–17:06:44.355152Z and
17:06:48.714117Z–17:06:56.916488Z respectively (2026-10-11, exit0); commit verified
17:07:22.664313Z. These are inherited finalizer checks, not this status writer's gates.
A green validator proves loaded data only, not prose truth or runtime compliance.

### Item 111 — Qualitative death/travel-time attribution receipt (2026-10-11)

- [x] `candidate-darkmega-death-drawback-attribution` handled locally in `domain.md §5
  item 111` / §7. Canonical commit `162fadfee9437eb2c30e24cd39eb07bdd8188df8`, parent
  `af84c9983110f273f3e88321901308d81cc97ee1`; only `ontology/domain.md` and
  `ontology/README.md`. Complete committed diff exactly equals the independently reviewed
  **5056-byte** SHA-256 `27ce75ca9ace021165cbc5f2b127541e699e3036c4834a0d003687aa5928408c`.
  Canonical hash/parent/scope/full-byte equality verified BEFORE removing ONLY 111;
  the pending-only queue then had no selected entries and was deleted. Queue exhaustion
  is not universal source exhaustion; unapproved leads remain in the original packet.
- **Authority:** Previously selected under standing exact owner answer
  **“For all items about accepting/refusing to increase the source precision of informations, auto-accept each of them in subagents”**,
  prior **“If the items are about accepting or refusing to add more precision to the sourcing of a data, auto-approve it”**
  and new-pass **“Yes”**. No invented per-item Yes. Approval origin
  `44de233c-75ec-41b0-9f72-52deddbff70a`, original `ad9dec62/approval/packet.json`,
  39646 bytes, SHA-256 `0bcdd5d49a8348521efac986fd3bef35c6ca36f2090e6a9d0842f8545ba243e3`.
- **Exact proposal:** Darkmega's retained Steam guide, Starting Out / Lightsouls, states that death doesn't have a drawback apart from travel time and joking references to pride/frustration. This is named qualitative corroboration of the existing no-death-penalty description, not an independently verified inventory/XP/gold-loss audit, a numeric travel penalty, a respawn-selection rule or a boss-health-reset report. It proves no original Alpha build behavior and does not change the activated-shrine rule, approved aggro clearing, world-reset persistence or the separate cut injured-debuff history. No runtime, source-label or implementation debt follows.
- **Exact selection:** Attribute the guide's qualitative death/travel-time statement, without overreading enumerated losses or respawn details.
- **Exact qualifiers:** “qualitative community statement”; “joking pride/salt language is not a debuff or currency-loss assertion”;
  “Attribution only; not developer authority, release/introduction history, original-build demonstration or Alpha proof.”;
  “All prior items 1–107 and D1–D26 remain handled and unchanged; documentation selection does not authorize runtime or new implementation debt.”;
  “Steam title [updated 4/10] remains distinct from displayed Updated 3 Oct, 2019 @ 10:14am, timezone unspecified; captured 2026-10-04T21:01:17Z; no immutable Steam revision.”
  Dependencies: item 78, approved player-death aggro clearing, existing no-death-penalty rule.
  No new loss/penalty mechanics, respawn routing/boss HP semantics, cut injured implementation
  or live JSON/code/tests/assets/research edits. **Approval versus Refusing:** Approval:
  Players keep the approved no-loss death rules; their qualitative historical comparison gains named sourcing.
  Refusing: Players retain those same rules; no new death penalty is approved.
- Finalizer personally inspected actual raw `guide.body:1054–1056`, derivative
  `guide.text:2196–2197`, title/byline/profile/displayed dates and all identity sidecars at
  `/tmp/pixlnd-presentation-world.I1sm3d/`; all SIX original hashes freshly matched.
  Raw SHA-256 `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`;
  separate derivative SHA-256 `a605a2e3ec320177cc58d951300d0285894f115a4ccdff9e96e4db6e4ef10a90`,
  not raw-equal. Public guide 1871398574, Darkmega; Posted 25 Sep, 2019 @ 2:24am,
  Updated 3 Oct, 2019 @ 10:14am (timezone unspecified), title [updated 4/10] and
  HTTP 200 capture 2026-10-04T21:01:17Z remain distinct; no immutable revision/build/Alpha proof.
- Fresh independent read-only review `1bed7b22-ee9d-4a95-945a-7b230c78f25b`,
  `2b746b7b/reviews/item111-0.json`, 19649 bytes, SHA-256
  `1ef737428e98d1ba5491d4d6edd89e87e25614e02d8aebd66a9dcfd27e29e88c`, no findings,
  explicitly bound to af84c998 and exact candidate. Reviewer source/prose inspection is
  independent; its machine evidence is parent-executed, not reviewer shell/hash execution.
  Original writer `bde5059f-4e32-458e-8b0d-740ac913823a`, historical base c6c5a92,
  `ad9dec62/items/item-111-record.json`, 14091 bytes, SHA-256
  `ca3c6697e4291d9d669add8cb6f86b8e56e6f88763473af8a47c3359fa448967` remains unchanged.
  HANDOFF-only af84c998 did not alter candidate bytes; stopped ad9dec62 review/cancelled
  request are NOT completed approval. Owner-stop af84c998 gates are NOT finalizer111 gates.
- Finalizer personally matched ENTIRE bound review/writer/approval bytes to actual complete
  native Summary prefixes FIRST, then verified only their exact reference-matched residual
  footers. Actual wrappers reviewer:/worker:/delegate:; review own terminal LF false and
  two-LF footer, writer/approval own terminal LF true and one-LF footers. Complete originals,
  native hashes/paths/footer bytes and separately timestamped fresh checks: `binding.json`.
  No trims, normalization, pointer-only reports or reconstructed native payloads.
- Fresh separately invoked pre-canonical `git diff --check`: exit 0,
  **2026-10-11T17:03:34.929742Z–17:03:34.944018Z**; bounded
  `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`: exit 0,
  **17:03:39.456746Z–17:03:47.173578Z**, Godot 4.7.2, “ontology valid”.
  Fresh native/source/Git/index/full-diff/protected-byte-kind-mode gate passed afterward
  at **17:03:59.390513Z**, before staging/commit. Literal mode120000 symlink target bytes
  checked against Git blob, never dereferenced. Actual commit object/full diff and verified
  timing retained. Validator proves loaded-data validity only, not prose truth/runtime.
- Simplify then ponytail found no supported cuts to required attribution/qualifications.
  Receipt/status receives its own separate fresh gates and scoped verified commit;
  logs/statuses/full exact receipt diff/commit proof are in this finalizer evidence root.
  §7 old current topic-status row remains deliberately untouched for separately reviewed
  finite maintenance. All old source paragraphs/decisions preserved.
- Historical failures/recovery remain historical: unsupported model before research;
  genuine inventory followed by parent footer-parser failure; byte-identical recovery;
  item111 outputs[0] KeyError and guessed two-LF assertion failed pre-mutation, then
  supervised measured recovery passed before draft. Approval-era 13:29:27.622362 belongs
  to specialist44de233c, NOT this finalizer. No failure retroactively becomes a pass.
  Item90 original delivery limitation/recovered review and item97 authorized POSTcanonical
  validator exception stand. Original STOP/incomplete-review chronology below is preserved.
  No new debt/gameplay/source labels, no retrieval or remote Git/push. Silk/Spinning Wheel
  quantity HOLDs, unanswered Swamp-lands/Lion/resistance/gear-HP mechanics, food chronology/
  daily quantities/original-sleep units gaps, regional-loss exclusion and item39 prohibition stand.

Managed finalizer root:
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/2b746b7b-b469-4768-b52b-07a7c1e59625/receipts/item111-evidence/`.
Complete exact selection/dependencies: `approved-selection.json`; complete preserved pending
snapshot: `queue-before-removal.md`; full source/protected-path records and unfiltered canonical/
receipt diffs, actual commit objects, command outputs/exits/times and proof: stage JSON/log files.

**Historical new-pass authority/queue snapshot before 111 completion (2026-10-11):** owner invoked
`/ontology-auto-approve-data-source-precision-increase` and answered exactly **“Yes”**
to starting a new precision-only sourcing pass. Standing exact answer remains
**“For all items about accepting/refusing to increase the source precision of informations, auto-accept each of them in subagents”.**
Previous session skill creation/publication completed at initial clean baseline
`c29d0c06f7a976874aaa1cafc822b1710d34594a`; the former current 94–107 snapshot
below is historical. Previous “After all that, push” was fulfilled, **not new push authority**.
Fresh approval run `44de233c-75ec-41b0-9f72-52deddbff70a` plus parent finite freeze
approved exactly **108–111**; **108–110 are handled locally** (receipts below), while
**111 remains UNHANDLED** in `docs/todo_handle_reconciled_items.md`.
That pending-only queue preserves exact sibling proposals/selections, qualifiers,
dependencies, standing/latest answers and procedural clarifications; no gameplay amendment.
Items 1–107, D1–D26, later choices, HOLDs/gaps and permanent exclusions stand.
Only this four-item packet may be recorded; additional retained leads stay UNAPPROVED
for later, not exhausted. No runtime/source-label/live-data/checker/tests/research edits,
new debt or publication. Required distinct item writers/reviews/fresh separate gates/
scoped canonical and verified receipt/queue-removal commits remain required for 111.
Recovery chronology and original receipt/report paths are retained in HANDOFF:
unsupported-model workflow 97f167ae failed before research; workflow 4526f397 had a
real inventory but footer parsing failed. Recovery ad9dec62 retains its original bytes,
origin/digest/time without repeated research, retroactive acceptance or review waiver.
Queue writer personally verified complete approval/native footer-only byte equality;
Furnace/Saw header-plus-one-LF correction and failed assertion remain transparent,
not raw/derived equality or a source mismatch. Managed evidence:
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/ad9dec62-82b5-4f73-b14f-f876fe916a9f/queue/persist-evidence/`.

### Item 110 — Historical Climbing Spikes attribution receipt (2026-10-11)

- [x] `candidate-darkmega-climbing-spikes-attribution` documentation recorded and canonical
  commit verified: `3ab368988920d887ed2885767cfb7cf347c1673d`, parent
  `8f73213d2ae0aa9aabd0edb9c3458f20e8000c7e`; only `ontology/domain.md` and minimal
  `ontology/README.md`. Pointers: `domain.md §5 item 110` / §7 item 110.
  Full canonical diff byte-equals independently reviewed SHA-256
  `4bb7d62f376344468ab09a5b4fdcd0d5bc5db72efb39dba17d650a4f5ab574a3`.
- **Authority:** `docs/lessons.md:18–44`, exact standing answers above and new-pass
  owner exactly **“Yes”**. Approval origin `44de233c-75ec-41b0-9f72-52deddbff70a`,
  `approval/packet.json`, SHA-256
  `0bcdd5d49a8348521efac986fd3bef35c6ca36f2090e6a9d0842f8545ba243e3`.
  Sourcing-only auto-approval; no per-item owner answer fabricated or new push authority.
- **Exact proposal:** Darkmega's retained Steam guide, Key items and You / Traversal Kit / Climbing Spikes, says the item allows players to nullify all costs to climbing around on surfaces. This attributes the already-documented historical Steam free-climbing report, not an original-build verification or hybrid target. The hybrid's globally acquired Spikes still reduce the skill-adjusted climbing stamina cost by 75% (remaining cost ×0.25), never eliminate a positive cost; basic climbing requires neither points nor Spikes, and the approved training prerequisites remain. No controls, climbing floor/curve, artifact-combination rule, source label, availability or implementation debt is selected.
- **Exact selection:** Name the historical cost-nullification source while explicitly preserving the different approved hybrid reduction.
- **Exact qualifiers:** “historical author report”; “no independent original-build or Alpha proof”;
  “Attribution only; not developer authority, release/introduction history, original-build demonstration or Alpha proof.”;
  “All prior items 1–107 and D1–D26 remain handled and unchanged; documentation selection does not authorize runtime or new implementation debt.”;
  “Steam title [updated 4/10] remains distinct from displayed Updated 3 Oct, 2019 @ 10:14am, timezone unspecified; captured 2026-10-04T21:01:17Z; no immutable Steam revision.”
- Dependencies: hybrid traversal items 4–5, item 56, item 107 and D1/D4 global key-item
  policy. No zero-cost hybrid climbing, reduction/multiplication-order revision,
  controls/equipment change, live JSON/code/tests/assets/research or new debt.
  **Approval versus Refusing:** Approval: Players still spend the approved reduced climbing stamina; documentation identifies a different historical Steam report.
  Refusing: Players keep that same approved reduction; refusal does not select historical free climbing.
  Prior decisions, HOLDs, unanswered gaps and permanent exclusions stand.
- Actual retained source: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1118–1120`,
  205335 bytes, raw SHA-256 `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`;
  derivative `guide.text:2814–2817`, 108553 bytes, separately hashed SHA-256
  `a605a2e3ec320177cc58d951300d0285894f115a4ccdff9e96e4db6e4ef10a90`, not byte-equal raw.
  Exact quote/identity/duplicate-screen selection: `receipts/item-110-evidence/approved-selection.json`.
  Finalizer personally inspected raw title/byline/profile/dates at 610–614 / 820–847,
  quote and derivative, actual URL/capture/status/headers; all six hashes freshly match.
  Darkmega, guide 1871398574; Posted 25 Sep, 2019 @ 2:24am, Updated 3 Oct, 2019 @ 10:14am,
  timezone unspecified; title [updated 4/10] distinct. HTTP 200 capture 2026-10-04T21:01:17Z
  establishes no immutable revision or original-build/Alpha proof. Originals unchanged; no fetch.
- Complete independent actual-source/full-diff approval: run
  `f33f88a6-f3f7-4bf3-ac3d-5e7993457ace`, `reviews/item-110-0.json`, 15144 bytes,
  SHA-256 `f737fbd747ab6d75b385c92ffe7ecc09028e01624e6904a8e91a4003eea88b44`;
  native SHA-256 `84583224da327ecee832f00876aa50af46f9417bce71c92ef976fa48a9291554`.
  No findings; approval limited to base/digest. Reviewer personally read sources/full diff;
  its machine assertions were executed by parent, not reviewer. Writer origin
  `51583cd0-c7f3-40f9-bf67-a34acd818bc3`, `items/item-110-record.json`, 19422 bytes,
  SHA-256 `63dfacde64bfb9a0b47274e571af884de8df34bbbccac2af7e91dacc18a5957b`;
  native SHA-256 `d35170f9e9a392e0949617c235c4946dec8e960ebd18be3ca5c1ea934fc6126f`.
  Finalizer compared ENTIRE saved/native Summary bytes before checking independently
  observed exact reference-matched two-LF footers. Actual wrappers reviewer: / worker:;
  no trimming, normalization or reconstructed review. Full reports/native origins/session
  paths and exact footer bytes retained in `binding.json` and copied complete dependencies.
- Fresh finalizer separate whitespace: **exit 0**, 2026-10-11T15:54:54.187443Z–15:54:54.223174Z;
  bounded `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`:
  **exit 0**, 15:55:02.446561Z–15:55:09.908506Z, Godot 4.7.2, “ontology valid”.
  Source/native/Git/index/kind/mode/byte/full-diff gate passed afterward at 15:55:31.194923Z;
  canonical commit verified at 15:55:31.590169Z BEFORE removing ONLY item 110.
  Exact sibling 111 preserved. Validator checks loaded data, not prose truth/runtime compliance.
  Receipt/status simplify → ponytail and separate fresh gates are retained below;
  independent committed-state audit and parent acceptance remain separate.
- **Failed helpers and authorized recovery:** before mutation, native binding helper exited 1
  on nonexistent writer: wrapper; supervisor authorized only actual observed worker:.
  Recovery-state helper then exited 1 on dereferenced `CLAUDE.md` symlink/blob comparison;
  HEAD/branch/index/status/diff passed, but entire recovery gate had not completed.
  Supervisor authorized mode-aware literal symlink target comparison, not skipping the file.
  Both failures/output/exit and native invocation times remain distinct; complete fresh
  recovery gate passed 15:54:11.512614Z, native/source/Git preflight 15:54:36.391146Z.
  No retroactive acceptance or waiver. Workflow 97f167ae failed before research;
  4526f397 produced genuine inventory before footer transport failure; recovery retained
  original bytes/origin/digest at 2026-10-11T13:20:38Z. Inherited 13:29:27 verification
  belongs to approval specialist 44de233c, not this finalizer. Originals preserved (HANDOFF).
- Older §7 status-table snapshot remains reserved for separately reviewed finite maintenance.
  Item 111 remains unapplied; additional leads remain UNAPPROVED, no research/exhaustion/push.

Managed root: `/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/ad9dec62-82b5-4f73-b14f-f876fe916a9f/`.
Item evidence: `receipts/item-110-evidence/` (complete binding/dependencies, selection,
failed/recovery helpers, source/Git/full diffs/commit objects, separate gates and verified commits).

### Item 109 — Qualified general Combo Counter attribution receipt (2026-10-11)

- [x] `candidate-darkmega-combo-basics-attribution` documentation recorded and canonical
  commit verified: `ce3ea42dfdb8bab6682ed24c73c00c55ed5ffeeb`, parent
  `9ed525c1df4611c6beb6de02eefee7e2020a9919`; only `ontology/domain.md` and minimal
  `ontology/README.md`. Canonical pointers: `domain.md §5 item 109` / §7 item 109.
  Complete canonical diff byte-equals independently reviewed SHA-256
  `e2935c17aea4bce0443706b4fb34ab0fc5617d9a31ab52a8b2ef458a5fc06328`.
- **Authority:** `docs/lessons.md:18–44`, standing sourcing-only answers above and latest
  new-pass owner exactly **“Yes”**. Fresh approval origin `44de233c-75ec-41b0-9f72-52deddbff70a`,
  `approval/packet.json`, SHA-256
  `0bcdd5d49a8348521efac986fd3bef35c6ca36f2090e6a9d0842f8545ba243e3`.
  No per-item owner answer fabricated; no new publication authority.
- **Exact proposal:** Darkmega's retained Steam guide, Weapons and You / Basics / Combo Counter, reports a hit-chain counter near the cursor, an exclamation mark and bright-blue appearance at full charge, transfer between targets while hits continue, immediate zeroing on a clearly missed hitbox attack, and expiry after what feels like 5 seconds. Its description of armor ignore is explicitly an impression (feels like), and its usually around 20–30 depending on class is an approximate overview, not a universal cap. This named community report corroborates the existing combo-system description; it does not authenticate an armor formula, change per-weapon caps or overwrite the approved whole-channel miss boundary, neutral-taunt policy, D15 or D24. Retained capture/identity dates establish no immutable Steam revision or original-build/Alpha proof. No hybrid behavior, balance, UI or implementation debt follows.
- **Exact selection:** Attribute the general Combo Counter passage separately from handled weapon-specific movesets.
- **Exact qualifiers:** “usually”; “around”; “feels like”; “what feels like”;
  “Attribution only; not developer authority, release/introduction history, original-build demonstration or Alpha proof.”;
  “All prior items 1–107 and D1–D26 remain handled and unchanged; documentation selection does not authorize runtime or new implementation debt.”;
  “Steam title [updated 4/10] remains distinct from displayed Updated 3 Oct, 2019 @ 10:14am, timezone unspecified; captured 2026-10-04T21:01:17Z; no immutable Steam revision.”
- Dependencies: items 98–101, approved walkthrough item 10 combo policy, D15 and D24.
  No formula/cap/timer, per-tick miss policy, UI-color implementation, unarmed moveset,
  live JSON/code/tests/assets/research or new implementation-debt change. All HOLDs,
  unanswered gaps and permanent exclusions stand; all prior canonical bytes remain intact.
  **Approval versus Refusing:** Approval: Players retain approved combo behavior; its historical visual/transfer/expiry descriptions gain named, qualified sourcing.
  Refusing: Players retain the same combo rules; no opposite behavior is approved.
- Actual retained source: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1062–1064`,
  205335 bytes, raw SHA-256 `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`;
  derivative `guide.text:2241–2252`, 108553 bytes, separately hashed SHA-256
  `a605a2e3ec320177cc58d951300d0285894f115a4ccdff9e96e4db6e4ef10a90`, not byte-equal raw.
  Raw title/byline/profile/displayed dates at 610–614 / 820–847 and actual URL/capture/status/
  headers inspected. Darkmega, guide 1871398574; Posted 25 Sep, 2019 @ 2:24am;
  Updated 3 Oct, 2019 @ 10:14am, timezone unspecified; title [updated 4/10] distinct.
  HTTP 200 capture 2026-10-04T21:01:17Z proves no immutable revision or original build.
  Original source bytes unchanged; no external retrieval. Complete exact handled selection,
  quotes and duplicate-screen context: `receipts/item-109-evidence/approved-selection.json`.
- Complete independent actual-source/full-diff approval: run
  `e5955361-f108-4d9c-ac5d-3d73df3e64d7`, `reviews/item-109-1.json`, 13134 bytes,
  SHA-256 `2d21e118bc16a906301a92c80cb3ff954eb891c85d9e345c3cf3b48567cd1388`;
  native log SHA-256 `852d7e3cd8c845638e50f07a221775883c6a3028e1dc742a66aaad803cdb44fa`.
  No findings; both prior findings resolved. Reviewer personally inspected source/canonical/
  full diff; machine assertions were executed by parent, not reviewer. Approval is limited
  to the named base/digest, not publication. Full native origin, session/artifact paths,
  original payload and exact observed wrapper/reference-matched two-LF footer are retained.
- Adjustment writer origin: `4251fe28-7dd2-444f-9a9a-9cea0c46e4cd`,
  `items/item-109-adjust.json`, 17624 bytes, SHA-256
  `6e34cc2f860cd2fe9ceafe22781d82bfc1178073a5de2be5ff072a53f79e46fd`;
  native SHA-256 `e6cad661d76a2dddd1cc4e50f3a4ef283096fb173065e6962bea5ff8c1d4282f`.
  Finalizer verified entire actual bound bytes against native Summary prefix FIRST,
  independently measured remaining reference-matched footer (one LF; report has its own
  terminal LF). No trimming/normalizing or reconstructed review. Earlier P1 review,
  writer footer failure and supervisor-authorized exact suffix correction remain original.
- Fresh finalizer separate `rtk proxy git diff --check`: **exit 0**, 2026-10-11T15:18:25.634368Z–15:18:25.673642Z;
  bounded `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`:
  **exit 0**, 15:18:30.093126Z–15:18:38.785631Z, “ontology valid”, Godot 4.7.2.
  Actual source/native/Git/index/all-tracked-byte/full-diff gate passed afterward at
  15:19:12.350252Z; canonical commit verified at 15:19:12.699695Z before ONLY item 109
  removal. Exact sibling blocks 110–111 preserved. Validator checks loaded data only,
  not prose truth or runtime compliance. Receipt/status simplify → ponytail self-review
  and separate fresh gates/timing/limits are captured in the evidence directory below;
  independent committed-state audit/parent acceptance remain separate.
- Recovery chronology remains in HANDOFF and complete bound reviewer/writer reports:
  workflow 97f167ae failed before inventory research; workflow 4526f397 had genuine saved
  inventory before transport-footer failure; recovery retained original bytes/origin/digest
  at 2026-10-11T13:20:38Z. Inherited 13:29:27.622362Z verification belongs to approval
  specialist 44de233c, not this finalizer. Current preflight is 15:18:11.727414Z.
  No finalizer assertion failure, retroactive acceptance or gate waiver; originals preserved.
- **Reserved metadata follow-up:** older §7 attribution-status table is unchanged, expressly
  outside this receipt. Separately captured full-diff review and verified final finite
  status commit must close stale candidate/queue references before overall completion.
  Additional leads remain UNAPPROVED for later; no new research or exhaustion claim.

Managed root: `/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/ad9dec62-82b5-4f73-b14f-f876fe916a9f/`.
Item evidence: `receipts/item-109-evidence/` (complete native/bound dependencies, selection,
source/sidecar hashes, preflight, full diffs/commit objects, separate gates and verified commits).

### Item 108 — Furnace/Saw location attribution receipt (2026-10-11)

- [x] `candidate-refining-station-location-attribution` documentation recorded and canonical
  commit verified: `1516db4503e426684eddab9c0923f7738cd205ff`, parent
  `2b384c2b993f074dd3eb0df1993a7a12892c479d`; only `ontology/domain.md` and minimal
  `ontology/README.md`. Canonical pointers: `domain.md §5 item 108` / §7 item 108.
  Full canonical diff byte-equals independently reviewed SHA-256
  `390912e2731fbb1c1a17a041bec975c5f1bab51e670b9d56868f842e47a5926c`.
- **Authority:** `docs/lessons.md:18–44` and standing sourcing-only approval above;
  latest owner new-pass answer exactly **“Yes”**. No per-item owner answer fabricated.
- **Exact proposal:** The retained community Furnace revision 19644 (edited 2024-08-11T18:55:41Z) reports a furnace at a Smithy in the Crafting District and says it is often paired with an Anvil and Customization Bench nearby. Saw revision 19638 (edited 2024-08-11T18:50:27Z) places the Saw at a Workshop in a City's Crafting District together with the Workbench. These individually attributed location reports supplement item 27's conversion passages; they do not authenticate original Alpha/Steam layouts or impose universal hybrid settlement contents. Both are current-body captures from 2026-10-04T17:17:32Z, not historical release captures. Preserve D22 and the approved exactly-one-settlement policy; no station, recipe, yield, quantity, source-label or runtime change follows.
- **Exact selection:** Attribute retained Furnace/Saw location passages only; do not alter station placement or recipes.
- **Exact qualifiers:** “often”; “source's any is a report, not a hybrid guarantee”;
  “community location report, not version authentication”;
  “Attribution only; not developer authority, release/introduction history, original-build demonstration or Alpha proof.”;
  “All prior items 1–107 and D1–D26 remain handled and unchanged; documentation selection does not authorize runtime or new implementation debt.”;
  “Often remains qualitative; the source any Smithy statement is a reported location claim, not a universal hybrid population requirement.”
- Dependencies: item 27, D22, settlements item 1. No station/building population, recipes,
  ratios, Silk/Spinning Wheel quantities, source-label, live JSON/code/tests/assets/research
  change; all HOLDs/gaps and exclusions stand. Approval versus Refusing: players retain
  exactly the same approved crafting/village rules either way; approval adds named sourcing only.
- Complete exact handled selection/source/identity/duplicate-screen context is retained at
  `receipts/item-108-evidence/approved-selection.json` under the managed root below;
  raw Furnace/Saw bodies and derivatives separately hashed and inspected, all sidecars checked.
  Current-body titles-API capture, not oldid historical fetch; header plus exactly one terminal LF
  removal equals raw main slot. Originals unchanged; no external retrieval.
- Independent approval origin: run `c0a12b2f-46f0-4903-82c8-13017664e105`,
  `reviews/item-108-1.json`, 12606 bytes, SHA-256
  `2e546ac2798eeda866ac35530709f02ad48866b1a0bef5ae8d13261a1697e988`;
  complete saved JSON equals complete actual native Summary after only exact observed wrapper
  and reference-matched two-LF footer removal. No findings; actual-source/full-diff approval
  limited to base/digest, not publication. Native log SHA-256
  `d5ba337f16df272ce79c572fb5f6237f868415ad20246da691a6c800d942214b`.
  Writer run `5ef53e7c-da95-429b-b168-a79c75c681db`, `items/item-108-adjust.json`,
  SHA-256 `bac9160c28d45c7aa866a5685907b8cc414c1d69a4779348f9cd2b256ec13845`;
  complete native/bound binding verified separately. Original P1 review and adjustment retained.
- Finalizer fresh separate `rtk proxy git diff --check`: **exit 0**, 2026-10-11T14:33:12Z;
  bounded `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`:
  **exit 0**, 14:33:18Z–14:33:25Z, “ontology valid”. Actual source/Git/index/full-diff
  reverified afterward; canonical commit began 14:33:43Z and hash/parent/scope/bytes verified
  before removal of ONLY item 108. Sibling blocks 109–111 remain exact and unapplied.
  Validator checks loaded data, not prose truth or runtime compliance. Receipt/status
  simplify → ponytail and separate fresh whitespace/bounded-validator logs/status/timing are
  `receipt-{whitespace,validator}.{log,exit,started,ended}` in the evidence directory below.
- Recovery: initial finalizer one-LF footer assertion **failed (exit 1) before mutation**;
  supervisor authorized only correction to actual two-LF suffix. Failed helper/assertion,
  recovery-state capture and successful complete retry remain distinct. Earlier unsupported-model
  pre-research failure and genuine-inventory/footer transport failure remain in HANDOFF above;
  no retroactive acceptance or gate waiver. No publication authority.
- **Outstanding status-only follow-up:** `domain.md §7` attribution-status row (line 4800)
  remains its precommit candidate snapshot, with transient queue references, by supervisor
  instruction. Later per-item recording may update the row within independently reviewed scope;
  final finite handoff MUST close stale current-row references through separately captured
  full-diff review and verified status commit before overall completion. No source-block change.

Managed root: `/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/ad9dec62-82b5-4f73-b14f-f876fe916a9f/`.
Item evidence: `receipts/item-108-evidence/` (complete native/bound reports, exact selection,
raw/derived/sidecars, preflight, full diffs/commit objects, separate gates, verified commits).

**Historical prepublication finite session frontier (2026-10-10):** only the fourteen inventory-3 selections,
items 94–107 (4/4/3/3 approval packets), were authorized as this session's last items. All are
recorded/reviewed/committed; pending queue absent. **STOP** new research, inventories and proposals.
After independently reviewed/parent-verified handoff, parent creates
`/ontology-auto-approve-data-source-precision-increase` in harness project memory, then separately
delegates conditional publication of `fix/ontology-reconciliation` and verifies fresh local/
upstream/remote equality and clean state. Skill/publication not yet done; not pushed. Exact owner
instructions below stand; conditional permission is not absent. Historical leaf-only limits are
not current aggregate authority. Remaining/withdrawn leads are unapproved research, not source
exhaustion. Complete independent audit of waves 80–107 and three metadata/provenance corrections:
HANDOFF; current maintenance evidence run `8c4cf499-adc2-4361-acad-29dcce40dc80`,
`handoff/record-evidence/`. Final handoff review and parent verification remain required.

**Previous source precision (2026-10-10):** `candidate-darkmega-glider-boat` documentation
recorded in `ontology/domain.md §5 item 107` / §7 under previously selected auto-approved authority.
Named historical qualitative forward/Space stamina and continuing boat-direction instructions;
no hybrid controls, steering/autopilot or balance defaults. Item 75's free glider waives no gates;
D1/D4 exclude regional disappearance. Training/equipped-item gates, global use, outer-world
bounds and settled stamina rules stand. Local raw/sidecars and duplicate-screen through item 106
checked. Independent source/scope review approved with no findings; exact native result/origin
retained distinctly and checked against real saved JSON. Finalizer fresh gates passed before
canonical commit `49e6f362d141a8835827f5518a5bb0f89bbf4967`; hash/parent/paths/content
match the reviewed diff. Last selection removed after verification; empty queue deleted, verbatim
research boundaries retained below/HANDOFF; §7 stale queue/index status corrected as maintenance.
No gameplay/live-data/checker/tests/assets, new debt or push. Exact selections/review/receipt below;
queue exhaustion does not establish broader source exhaustion.

**Previous source precision (2026-10-10):** `candidate-darkmega-artifact-dungeons` documentation
recorded in `ontology/domain.md §5 item 106` / §7 under previously selected auto-approved authority.
Named qualified icon, discover-before-reveal, key-access and multiple-relic reports; “normally”,
“sometimes” and “Usually” retained. No orange-circle authentication or exact count; source
leveling/qualitative stacking remain historical Steam comparison. D1/D6, logarithmic rewards,
1–3 per land, traversal gates and personal lore/nonrenewing artifact claims stand. Local raw/
sidecars and items 1–105 duplicate-screen checked. Independent source/scope review approved
with no findings; exact native result/origin retained distinctly and checked against real saved JSON.
Finalizer fresh gates passed before canonical commit `564daa26181ede0611e9554dc53d770a16f30392`;
hash/parent/paths/content match the reviewed diff. Only artifact-dungeon removed; glider/boat
unchanged and pending. No gameplay/live-data/checker/tests, new debt or push. Exact saved
selections/review/receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-faction-encounters` documentation
recorded in `ontology/domain.md §5 item 105` / §7 under previously selected auto-approved authority.
Named qualitative necromancer/undead, paladin/unholy-pact, druid/steel and conditional spawning-
structure examples preserve author labels and “in some cases”; no catalog identity equivalence
or universal allegiance/hostility inferred. Items 74/79/83–87 and settled rules stand. Local raw/
sidecars and items 1–104 duplicate-screen checked. Independent source/scope review approved with
no findings; exact native result/origin retained distinctly and checked against real saved JSON.
Finalizer fresh gates passed before canonical commit `a1c83918d44304332074c48bb2dd666175831830`;
hash/parent/paths/content match the reviewed diff. Only faction removed; two unchanged siblings
pending. No gameplay/live-data/checker/tests, new debt or push. Exact saved selections/review/
receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-ingredient-attribution` documentation
recorded in `ontology/domain.md §5 item 104` / §7 under previously selected auto-approved authority.
“Apparently”, “feel like” speculation, “some” / “occasionally” and explicit sugar/lemon reports
remain distinct named community claims, not authentication of catalog locations or A/S tags.
Items 45/92 and settled rules stand. Local raw/sidecars and items 1–103 duplicate-screen checked.
Independent source/scope review approved with no findings; exact native result/origin retained
distinctly and checked against real saved JSON. Finalizer fresh gates passed before canonical
commit `c4f328dc7c71242219a4cec721abf0fe37db4fb3`; hash/parent/paths/content match the reviewed
diff. Only ingredient removed; three unchanged siblings pending. No gameplay/live-data/checker/
tests, new debt or push. Exact saved selections/review/receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-arena-attribution` documentation
recorded in `ontology/domain.md §5 item 103` / §7 under previously selected auto-approved authority.
Named qualitative boss-rush/loot and qualified final-boss/respawn reports; three preliminary rounds
explicitly disagree with, but do not replace, the exactly-five-wave ladder. “Usually” / “I think”,
rewards and hybrid reset/permanent-claim policy stand. Local raw/sidecars and items 1–102
duplicate-screen checked. Independent source/scope review approved with no findings; exact
native result/origin retained distinctly and checked against real saved JSON. Finalizer fresh gates
passed before canonical commit `d7c89560bf02489c31cb8c1868417bfc8808f57a`; hash/parent/paths/
content match the reviewed diff. Only arena removed; four unchanged siblings pending. No gameplay/
live-data/checker/tests, new debt or push. Exact saved selections/review/receipt below; owner
frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-lore-attribution` documentation
recorded in `ontology/domain.md §5 item 102` / §7 under previously selected auto-approved authority.
Named qualitative tablets/crypts/ruins and artifact-reveal report; both “usually” qualifications
and “potential” sites retained. ≈10 % / 100 %, per-character/saved-world lore, shared terrain and
D1/D6 stand. Local raw/sidecars and duplicate-screen checked. Independent source/scope review
approved with no findings; exact native result/origin retained distinctly and checked against real
saved JSON. Finalizer fresh gates passed before canonical commit
`251cb4bc628ed7c3b00430890376735efe9d0faf`; hash/parent/paths/content match the reviewed diff.
Only lore removed; five unchanged siblings pending. Documentation only, no gameplay/live-data/
checker/tests, new debt or push. Exact saved selections/review/receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-mage-weapons` documentation
recorded in `ontology/domain.md §5 item 101` / §7 under previously selected auto-approved authority.
Named qualified fixed-location Staff tornado, finite hitscan Wand and gravity-free Bracelet reports;
estimates, terrain/combo/cancellation and qualitative comparisons remain historical, not defaults.
Approved Wand item 1, current whole-channel combo policy and D24 stand; item 97 is distinct.
Local raw/sidecars and canonical duplicate-screen checked. Independent source/scope review approved
with no findings; exact native result/origin retained distinctly and checked against real saved JSON.
Finalizer fresh gates passed before canonical commit `e6b1b5139ca884c58c949e9224f47c2370c80858`;
hash/parent/paths/content match the reviewed diff. Only Mage weapons removed; six unchanged siblings
pending. Documentation only, no gameplay/live-data/checker/tests, new debt or push. Exact saved
selections/review/receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-ranger-weapons` documentation
recorded in `ontology/domain.md §5 item 100` / §7 under previously selected auto-approved authority.
Named qualified Bow arc/four-arrow volley, charged Crossbow bolt and cursor-following Boomerang/
dual-toss reports. Random-loot and untested-Sniper qualifiers preserved; counts, qualitative range/
timer/tick, dud-shot and knockdown accounts remain reports, not defaults. Consolidated 4–5,
items 53/95, MP costs and D24 stand. Local raw/sidecars and canonical duplicate-screen checked.
Independent source/scope review approved with no findings; exact native result/origin retained
distinctly and checked against real saved JSON. Finalizer fresh gates passed before canonical commit
`e4a60f47d2f0f1738882913ccd12191471838b38`; hash/parent/paths/content match the reviewed diff.
Only Ranger removed, seven unchanged siblings pending. Documentation only, no gameplay/live-data/
checker/tests, new debt or push. Exact selection/review/receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-rogue-weapons` documentation
recorded in `ontology/domain.md §5 item 99` / §7 under previously selected auto-approved authority.
Named qualified roundhouse, Dagger poison and multi-hit-lunge reports; minor testing stays tentative,
counts/stacking/crit observations historical. Repeated-right pairing text is not repaired into policy;
items 49/64, D24/D26, poison/dodge, combo and equipment rules stand. Local raw/sidecars and
canonical duplicate-screen checked. Independent source/scope review approved with no findings;
exact native result/origin retained distinctly. Finalizer fresh gates passed before canonical commit
`05a18f13d9e0c8fdd3ddc063e4426adcaf3af75b`; hash/parent/paths/content match the reviewed diff.
Only Rogue removed; eight unchanged siblings pending. Documentation only, no gameplay/live-data/
checker/tests, new debt or push. Exact wording/review/receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-warrior-weapons` documentation
recorded in `ontology/domain.md §5 item 98` / §7 under previously selected auto-approved authority.
Named qualitative great-weapon sequence, overhead/defensive sweep, dual spin and shield
block/charged-swipe corroboration; favorites/proc impressions remain reports. Charge is not a
dash; item 96's block-mana disagreement and D11/D23/D24 stand. Raw/sidecars and duplicate-screen
checked locally; independent source/scope review approved with no findings, exact native result/origin
retained distinctly. Finalizer fresh gates passed; canonical commit
`24a94c5a40d2361a9ddcf55515f73a5626df8359` hash/parent/paths/content verified.
Only this handled selection removed, nine unchanged siblings pending. No gameplay/live-data/
checker/test change, new debt or push. Exact selection/review/receipt below; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-mage-abilities` documentation
recorded in `ontology/domain.md §5 item 97` / §7 under previously selected auto-approved authority.
Named qualified Fire/Water Mage reports; hover seems-free/reapplication, puddle stacking and
approximate bubbles remain historical, not formulas. F1's six bubbles and D21/D24 stand.
Local raw/sidecars and duplicate screen checked; independent review approved with no findings.
Canonical commit `67c3cd489d686cb760d4fcfc857700078bd93818` hash/parent/paths/content verified.
Finalizer whitespace passed precommit; bounded validator passed postcommit under explicit supervisor
retention authority after a shell-sequencing error (timing exception below). Only Mage removed;
ten siblings unchanged/pending. No gameplay/live-data/checker/test changes, new debt or push.
Exact selection/evidence/check limits below; owner session/publication frontier remains unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-warrior-abilities` documentation
recorded in `ontology/domain.md §5 item 96` / §7 under previously selected auto-approved authority.
Qualified Berserker/Defender corroboration; Fury impressions and internal block-mana disagreement
remain explicit. F1/D11/D21/D23 and settled taunt/healing stand. Raw/sidecars and duplicate screen
checked locally; independent source/scope review approved with no findings. Exact native review
and origin/delivery provenance retained distinctly; finalizer fresh gates passed. Canonical commit
`a53c005f09aac94baaa91b827a5efb9649b2a602` hash/parent/paths/content verified.
Only this handled selection removed; eleven unchanged siblings pending. No gameplay/live-data/
checker/test changes, new debt or push. Exact selection/review/receipt and check limits below;
owner session/publication frontier below remains unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-ranger-abilities` documentation
recorded in `ontology/domain.md §5 item 95` / §7 under previously selected auto-approved authority.
Named qualified Sniper/Scout corroboration; approximate clone/trap reports and speculative aggro
remain report-only. F1/D21's 30-second Shadow Shooter, settled targeting and cooldowns stand.
Independent source/scope review approved with no findings; finalizer fresh gates passed.
Canonical commit `2ce579e699e4260ddfa9742d339ffe36de71cf69` hash/parent/paths/content
verified; only this handled selection removed, twelve unchanged siblings pending. No gameplay/
live-data/checker/test changes, new debt or push. Exact selection/native review/commit receipt
and source/check limits below; current owner session/publication frontier below remains unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-rogue-abilities` documentation
recorded in `ontology/domain.md §5 item 94` / §7 under standing auto-approval. Named qualified
Assassin/Ninja corroboration; aggro-reset/interruption uncertainty and report-only values retained.
Full-stealth threat policy and Assassin key-3 exception stand. Independent source/scope review
approved with no findings; finalizer fresh gates passed. Canonical commit
`0c7bf74d8348ec13d022940b2472230fb0142eba` hash/parent/paths/content verified; only this selection
removed, thirteen unchanged siblings pending. No gameplay/live-data/checker/test changes or push;
exact selection, native review provenance and commit/check receipt below.
Latest owner session frontier: handle only fourteen queued inventory-3 candidates in fixed
4/4/3/3 packets, then verified local handoff; no further selections or broader source exhaustion
claim. Parent creates `/ontology-auto-approve-data-source-precision-increase` in harness project
memory only after handoff. Remaining leads stay research; exact scope retained in HANDOFF.
Latest “After all that, push” supersedes absent-publication-permission summaries: publication of
`fix/ontology-reconciliation` is conditional on completing this workflow, verified local handoff
and skill creation first. Parent delegates publication separately and verifies clean state plus
fresh local/upstream/remote equality. No leaf push now, merge, force-push or history rewrite.

**Previous source precision (2026-10-10):** `candidate-darkmega-world-boss-attribution`
documentation recorded in `ontology/domain.md §5 item 93` / §7 under auto-approved precision
authority. Named Darkmega qualitative boss/move/loot corroboration only; “sometimes”, “usually”
and equivalent-at-gold retained. Hybrid resets/occupied-site rules and permanent claims stand.
Retained local evidence checked; no immutable revision or original-build proof. Fresh whitespace
and bounded-validator checks passed. Independent content review approved with no findings;
empty bound report recovered under supervisor authority, not a gate waiver. Finalizer fresh
source/Git/index/diff/queue and whitespace/bounded-validator gates passed; canonical commit
`474ec28621be8e4527e98941e0bdf57ad02eafec` content/hash/parent verified. Last selected entry
handled; pending-only queue deleted, non-selection research boundaries retained in HANDOFF/§E.
No gameplay/live-data/checker/test change, new debt or push; further scoped screening required,
no exhaustion claim. Exact selection/source/check/recovery limits below.

**Previous source precision (2026-10-10):** `candidate-environment-drinks-attribution`
documentation recorded in `ontology/domain.md §5 item 92` / §7 under auto-approved precision
authority. Named Darkmega lemonade/lava and hot-chocolate/cold-water reports; Green Smoothie
protection remains untested speculation with the author's never-entered-dark-forest disclaimer.
Existing environmental-consumable rules stand; no new behavior or implementation debt.
Independent content review approved with no findings; empty bound report recovered under
supervisor authority, not a gate waiver. Finalizer source/Git/index/diff/queue and fresh gates
passed; canonical commit `35e833b69bc073f32421409d16e5ba6d74834037` content/hash/parent
verified. Only this item removed; world-boss sibling unchanged/pending. Retained local evidence
and source/recovery/check limits below; no push or exhaustion claim.

**Previous source precision (2026-10-10):** `candidate-treasure-spirit-attribution` documentation
recorded in `ontology/domain.md §5 item 91` / §7 under auto-approved precision authority. Named
Darkmega qualitative nearby-hovering compass/direction and hidden-gold/equipment corroboration
only; no numeric range or universal absence of NPC hints. Global key-item policy and items 21/82
stand; no spawn, loot-adaptation or class-selection change or new debt. Independent content review
approved with no findings; empty bound report recovered under supervisor authority, not a gate
waiver. Finalizer fresh gates and canonical commit verified; only this item removed, two siblings
unchanged/pending. Retained local source/recovery/commit/check limits below; no push or exhaustion claim.

**Previous source precision (2026-10-10):** `candidate-spirit-bell-attribution` documentation
recorded in `ontology/domain.md §5 item 90` / §7; independent review confirms source fidelity
and preservation of F8, no findings. Finalizer fresh gates and canonical commit verified;
only this item removed, three siblings pending. Named Darkmega portcullis/transparent-realm
and atmosphere reports only; approximate 45 seconds does not replace settled F8 30 seconds. Night visibility remains
hearsay, not a demonstrated benefit. No controls, realm or audiovisual behavior change, new debt
or push. Retained local evidence and source/check limits below; no topic-exhaustion claim.

**Previous source precision (2026-10-10):** `candidate-divine-harp-attribution` documentation
recorded in `ontology/domain.md §5 item 89` / §7 under auto-approved precision authority. Named
Darkmega qualitative golden-door/loot-tower and approach/prompt/tune corroboration only;
“Usually” retained, no layout or shipped audiovisual proof. Global key-item and midnight
re-closing policies stand. Independent content review approved with no findings; finalizer fresh
gates and canonical commit verified, only this item removed and four siblings pending.
No gameplay/live-data/checker/test change, new debt or push. Source/check limits below.

**Previous source precision (2026-10-10):** `candidate-sky-flute-attribution` documentation recorded
in `ontology/domain.md §5 item 88` / §7. Named Darkmega bird/pillar activation and blue-bird lift
only; source “Sky flute” does not rename Sky Whistle. Global key-item policy and settled choices
stand. Independent content review approved with no findings; bound-report recovery and fresh
finalizer gates verified. Canonical commit `5bd6e15be2c786d95b48c6fef522915b99eb6d35` verified;
only this item removed, five siblings remain pending. Exact receipt and source/check limits below.
No gameplay/live-data/checker/test change, new debt or push; source/check limits below.

**Previous source precision (2026-10-10):** `candidate-mana-pump` documentation recorded in
`ontology/domain.md §5 item 87` / §7 under auto-approved precision authority. Named Darkmega
qualitative absorption and inducer/officer/pump sequence only; no reduction value, stacking,
guaranteed four-arm layout, officer/mech identity or numeric combat behavior. Settled hybrid
choices stand; no new implementation debt. Independent content review approved; empty bound
report recovered under supervisor authority. Finalizer source/Git/diff/queue and fresh gates passed;
canonical commit `a212a74cfbe9c4961a4460d093da60bcc60b694f` content/hash verified. Only this item
removed; empty pending queue deleted. This is not research exhaustion; all-topic screening next. Retained permitted local evidence only, no immutable revision/original-build proof.
No gameplay/live-data/checker/test change or push. Selection/source/check limits below.

**Previous source precision (2026-10-10):** `candidate-petrified-village` documentation recorded
in `ontology/domain.md §5 item 86` / §7 under auto-approved precision authority. Named Darkmega
qualitative witch-curse/restoration corroboration only; no universal NPC-service lock, witch
placement guarantee or reset rule. World-shared resolved curses and existing resets stand.
Independent content review approved; empty bound artifact recovered under supervisor authority.
Finalizer source/Git/diff/queue and fresh whitespace/bounded-validator checks passed.
Canonical commit `ce536ec6f2a47bcd87421c72ff0d046d03cc3935` content/hash verified;
only this item removed, mana-pump queued/unapplied. No gameplay/live-data/checker/test change,
new debt or push. Pre-existing unrelated queue edits preserved; evidence/limits below.

**Previous source precision (2026-10-10):** `candidate-possession` documentation recorded in
`ontology/domain.md §5 item 85` / §7 under auto-approved precision authority. Qualified Darkmega
big/red/stronger possessed-mob and hostile-villager respawn/until-portal-destruction reports only;
portal healing remains speculative. Curse persistence/resets and hostility exceptions stand.
Independent content review approved; empty bound artifact recovered under supervisor authority.
Finalizer source/Git/diff/queue and fresh whitespace/bounded-validator checks passed.
Canonical commit `03cd92ab4c339053da7b893910bfbe73ac8d8220` content/hash verified;
only this item removed, two siblings queued/unapplied. No gameplay/live-data/checker/test change,
new debt or push. Selection/recovery/limits below.

**Previous source precision (2026-10-10):** `candidate-circle-power` documentation recorded in
`ontology/domain.md §5 item 84` / §7 under auto-approved precision authority. Named Darkmega
ember/brazier and top-left buff-bar report only; its uncertain effect neither substantiates nor
reopens D6's +10 % attack / +10 % max HP. No new magnitude, persistence, UI behavior or debt.
Independent content review approved with no findings; empty writer/review artifacts recovered
under supervisor authority. Finalizer verified source/Git/diff/queue and fresh whitespace/bounded
validator gates. Canonical commit `cad81bbfbd48bc43fbc4a08a89e1aeb8bb491b5c` content/hash verified;
only this item removed, three siblings queued/unapplied. Exact selection/recovery/check limits below.
No gameplay/live-data/checker/test change; not pushed.

**Previous source precision (2026-10-10):** `candidate-mage-tower-barrier` documentation recorded
in `ontology/domain.md §5 item 83` / §7 under auto-approved precision authority. Named Darkmega
mage/crystal-tower, all-crystal blue-forcefield clearing and qualitative boss/crystal loot
corroboration only; no population, loot counts, reset or difficulty mapping. World-shared
persistence and hybrid policy stand. Independent content review approved with no findings;
empty bound artifact recovered under supervisor authority. Canonical commit
`8ddea40b9138c1e07b3aaef75c3ff9df5c929ea3` verified; fresh finalizer gates passed.
Only this item removed; four siblings remain unapplied. Exact selection/recovery/check limits below.
No gameplay/live-data/checker/test change or new debt; no push.

**Previous source precision (2026-10-10):** `candidate-npc-location-dialogue` is handled in
`ontology/domain.md §5 item 82` / §7; verified canonical commit
`391716e2fd93975d4e7b8bf863f4d9aad98c1c95`. Independent content review approved; empty bound
artifact recovered separately under supervisor authority; fresh finalizer checks passed.
Only this item removed, five siblings remain unapplied. Qualitative town/adventurer hint attribution
only; items 21/54 and hybrid policy stand. No gameplay/live-data/checker/test change or new debt.
Exact selection, recovery provenance and evidence limits below. Not pushed.

**Previous source precision (2026-10-10):** `candidate-friendly-npc-presentation` is handled in
`ontology/domain.md §5 item 81` / §7; canonical commit verified, independent content review
approved and fresh finalizer gates passed. Empty bound review recovered separately under
supervisor authority. Only this entry removed; six siblings remain unapplied in the pending queue
for separate workers. Item 80 stands. Exact selections, receipts and check limits below. Not pushed.

**Previous sourcing batch (2026-10-10):** owner standing request:
**“For each item which implies approving/refusing to increase source-precision, auto-approve it in a subagent.”**
Items **75–79 are handled** after independent recording review and parent source/diff/Git/check
acceptance; the review's new-batch date correction is applied. Exact selections and full receipts
are below; empty pending-only queue deleted. Remaining research: `docs/HANDOFF.md`; next scout
must contact parent before expanding or selecting. No gameplay or publication authority.

**Previous sourcing batch 70–74:** owner exact standing answer:
**“For all items about accepting/refusing to increase the source precision of informations, auto-accept each of them in subagents”.**
Items **70–74 are handled** under this narrow standing sourcing-only approval: each has a distinct
fresh subagent, scoped item commit, independent recording review and parent source/diff/Git/check
verification. Exact original selections and full receipts are below; empty pending-only queue deleted.
No individual numbered owner answers are fabricated; approval grants no mechanics, labels, live-data,
code/checker/test or publication authority. Remaining histories stay research, not topic completion.

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
Items 57–79 are handled, independently reviewed and parent-accepted; empty queue deleted.
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

### Validation-contract source attribution — candidate-darkmega-glider-boat / item 107 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, renewed ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's glider forward/space stamina and directional boat instructions.

**Original scout proposal (verbatim):** New scout selection: attribute Darkmega's qualitative glider forward/space stamina and boat directional-sailing instructions.

**Previously selected precision option (task inventory verbatim):** Named historical qualitative controls; distinguish already-recorded flight-master glider and excluded regional disappearance.

**Original scout precision detail (verbatim; same narrow selection):** Named historical community corroboration of traversal controls; distinguish free flight-master glider already recorded in item 75 and permanently excluded regional disappearance.

**Approval versus Refusing:** approval improves named attribution within existing policy;
refusal would decline that precision only, not approve an opposite mechanic. Neither changes
the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 107` / §7 after local raw
inspection and canonical duplicate-screen through item 106. Independent source/scope review
approved with no findings; canonical commit hash/parent/paths/content verified against the reviewed
diff before removing the last handled selection and deleting the empty queue. Non-selection
research boundaries retained below/HANDOFF; no broader source-exhaustion claim.
**Dependencies (queue verbatim):** Item 70 provenance; Items 56/57/73/75; D1/D4 and settled traversal stamina.
**Queued documentation / implementation boundary (verbatim):** Documentation only; no controls, speed, stamina, regional loss, riding or temporary-glider policy change.
**Selected boundary:** qualitative instructions only; no deployment key, quantified speed/stamina/
interval or steering/autopilot algorithm. Item 75 already attributes the free temporary glider;
no hybrid training/vendor-bought equipped-item gate exception. D1/D4 exclude regional disappearance;
global use, shared special slot, outer-world bounds and settled stamina rules stand. Historical
research deployment-key conflicts remain unresolved; adjacent Reins/Spikes reports not selected.
No source-label, live JSON, gameplay/checker/tests, assets or new implementation debt.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`,
**Key items and You → Traversal Kit → Hang glider / Boat**; exact raw instructions checked.
`guide.text:2795–2802` agrees as derivative inspection text, not raw-byte equality. Raw SHA-256
freshly matches `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture and title/author/displayed dates independently checked: guide 1871398574,
Darkmega; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**, timezone
unspecified; title **updated 4/10** distinct. HTTP 200 capture **2026-10-04T21:01:17Z**;
item 70 limits apply. No immutable revision, original-build/Alpha proof or introduction chronology;
no external retrieval or asset inspection. Scoped GDScript searches found no glider/boat runtime
consumer; catalog loading is not enforcement. Approval origin `e660230f-d402-4cb4-8853-7d1bd2c3338a`
real native JSON matched its bound report; copies/provenance retained distinctly, originals untouched.
**Checks/evidence:** managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`items/r0-g3-i2-evidence/`: source/Git/index/full-diff/queue/scope snapshots. Installed simplify
then ponytail-review completed; fresh `git diff --check` and `timeout 150 nix develop -c godot
--headless -s ontology/validate.gd` both exit 0 (ontology valid). Validator covers loaded data
only, not prose truth or runtime behavior; no gameplay tests added/run. Context percentage
unavailable; no broader exhaustion or publication claim. Writer did not stage, commit or push.
**Independent review:** origin `5f37f3a3-d718-460e-a289-637399365491`, approved, no findings;
full supplied native result checked against original saved structured JSON. Writer origin
`544a0e8b-4103-48dc-b661-dfaad52fe504` likewise verified; original delivery receipts untouched,
exact native results/origins retained in distinct managed evidence. No empty-bound-file wait,
review waiver or self-review substitution.
**Verified canonical commit:** `49e6f362d141a8835827f5518a5bb0f89bbf4967`, parent
`397a4f5c0425fafd5b7c8d55aa5a0fe3733c26ce`; exactly `ontology/domain.md`,
`ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md` and the existing pending
queue. Full-index diff SHA-256
`bba3e0c1e877092463a3b439e5574fec40000e764a8a2cd918ab829d2afe2965` equals the independently
reviewed writer diff. Fresh finalizer raw/Git/index/diff/scope checks, installed simplify then
ponytail-review, whitespace and bounded validator gates passed before commit; both gate exits 0.
Actual hash/parent/paths/content verified before queue removal; canonical content unchanged by
receipt maintenance. Last selection handled; queue deleted. No gameplay/live-data/checker/tests,
assets, new debt or push. Evidence: managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`receipts/r0-g3-i2-evidence/`; validator proves loaded data only, not prose/runtime behavior.

**Archived exact queue authority (no new approval or amendment):**
> For each item which implies approving/refusing to increase source-precision, auto-approve it in a subagent. Do not perform any other action than handing off yourself. Only orchestrate and handoff. To review, also use subagents. Stop only when no source-precision item remain, regardless of limitation of the skill. Ensure using low context only by delegating tasks to subagents.

**Retained non-selection boundaries (verbatim from removed queue; historical queue-only scope):**

These are research/status context, not approvals or additional pending selections:

- Swamp-lands/Lion/resistance/gear-HP unresolved gameplay portions remain unanswered.
- Silk/Spinning Wheel quantities HOLD; food chronology/daily quantities/original-sleep units remain evidence gaps.
- Handled items 1–93 remain settled; deferred runtime is not a precision ballot.
- `ontology/domain.md:4052` has a stale pending-queue pointer and incomplete current receipt index: maintenance contradiction, not a new source ballot. No maintenance change authorized in this step.
- No gameplay scripts/tests, loader/validator modifications, behavior-changing instance/design JSON, dependencies, merges, rebases, force pushes or history rewrites. Future precision recording stays within canonical documentation and existing ledgers/HANDOFF; immutable evidence only where the existing source protocol permits it. Scratch remains outside the repository.

**Current maintenance status:** the stale §7 queue pointer/receipt index above is now corrected
under this finalizer's explicit receipt/queue authority, not a new precision ballot or design
approval. Items 1–107 remain recorded. The fourteen-selection inventory is exhausted; broader
source exhaustion is not established. Remaining research leads stay in HANDOFF/§E, not a second
specification or completed-history queue. Not pushed; no publication authority.

### Validation-contract source attribution — candidate-darkmega-artifact-dungeons / item 106 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, renewed ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim; original scout proposal identical):** New scout selection: attribute Darkmega's artifact-dungeon icon, discover-before-reveal, key-access and multiple-relic reports.

**Previously selected precision option (task inventory verbatim):** Named qualified corroboration; level-up/traversal rewards remain historical Steam comparison.

**Original scout precision detail (verbatim; same narrow selection):** Qualified named community corroboration of existing dungeon/artifact access; source level-up/traversal reward remains historical Steam comparison, not hybrid progression.

**Approval versus Refusing:** approval improves named attribution within existing policy;
refusal would decline that precision only, not approve an opposite mechanic. Neither changes
the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 106` / §7 after local raw
inspection and canonical items 1–105 duplicate-screen. Independent source/scope review approved
with no findings; scoped canonical commit verified before removal of only this handled selection.
Glider/boat block remains byte-identical and pending.
**Dependencies (queue verbatim):** Item 70 provenance; D1/D6 and settled artifact accumulation; Persistence permanent claims.
**Queued documentation / implementation boundary (verbatim):** Documentation only; no artifact levels, quantity, loot tier, rewards or reveal mechanics change.
**Selected boundary:** retain “normally”, “sometimes” and “Usually”; no orange-circle image
identity, exact relic count, universal key requirement, reveal trigger/threshold, literal lore,
loot tier or reward formula inferred. Historical Steam levels/qualitative stacking do not replace
hybrid XP, logarithmic rewards, 1–3-per-land or traversal gates. Lore stays character/world-local;
personal artifact claims never renew. Items 82/102 and 88–90 remain distinct. No source-label,
live JSON, gameplay/checker/tests, assets or new implementation debt; settled rules stand.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1128`,
**A questing we shall go! / Cue up your favorite dungeon diving music.**; exact selected paragraph
checked in raw. `guide.text:2924–2930` agrees as derivative inspection text, not raw-byte equality.
Raw SHA-256 freshly matches `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture and title/author/displayed dates independently checked: guide 1871398574,
Darkmega; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**, timezone
unspecified; title **updated 4/10** distinct. HTTP 200 capture **2026-10-04T21:01:17Z**;
item 70 limits apply. No immutable revision, original-build/Alpha proof or introduction chronology;
no external retrieval or linked-image inspection. Catalog/research context is not stronger raw
evidence; scoped GDScript searches found no relevant runtime dungeon/artifact consumer.
**Checks/evidence:** managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`items/r0-g3-i1-evidence/`: source/Git/index/full-diff/queue snapshots. Installed simplify then
ponytail-review completed; fresh `git diff --check` and `timeout 150 nix develop -c godot
--headless -s ontology/validate.gd` both exit 0 (ontology valid). Validator covers loaded data
only, not prose truth or runtime behavior; no gameplay tests added/run. Context percentage
unavailable; no broader exhaustion or publication claim. Writer did not stage, commit or push.

**Independent review / local receipt (2026-10-10):** reviewer origin
`c57fabde-9ae0-4d76-9bcc-52e0ba485af2` returned **approved**, no findings, for the exact writer
origin `f2ad099b-e185-4802-9c50-2be943bd606b` diff at
`a8a232d0b1553871e96e1e1ccf59ef8ebdce455b`. Full-index diff SHA-256
`d418e9473b357bfc6393fbde3bd02a282105dbc804fd3e0abc6d1b1ddae2b72b` matched actual Git and
writer evidence byte-for-byte. Exact forwarded native payloads/origins checked against REAL
saved structured JSON; distinct copies/provenance retained in managed
`receipts/r0-g3-i1-evidence/`, originals untouched, including the empty reviewer bound report.
Writer bound report's `value` wrapper matched its native payload. No empty-file wait, review
waiver or self-review substitution. Finalizer freshly inspected raw passage/identity/dates,
branch/HEAD/upstream/index/full diff/queue and applied installed simplify then ponytail-review;
no warranted cuts. Fresh whitespace and bounded validator gates passed before canonical commit
`564daa26181ede0611e9554dc53d770a16f30392`, parent
`a8a232d0b1553871e96e1e1ccf59ef8ebdce455b`. Exactly five permitted Markdown paths:
`ontology/domain.md`, `ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md`,
`docs/todo_handle_reconciled_items.md` (reviewed application status only; selection retained).
Hash/parent/paths/content verified byte-for-byte against the independently reviewed diff before
removing only artifact-dungeon from the queue. Exact selection/amendments above retained;
glider/boat sibling block and non-selection tail byte-identical and pending. Separate receipt/
queue maintenance follows, without changing §5 item 106's source content. No gameplay/live
JSON/checker/tests/assets, new debt, push or broader exhaustion claim. Validator proves loaded
data only, not prose truth or runtime behavior; context percentage unavailable.

### Validation-contract source attribution — candidate-darkmega-faction-encounters / item 105 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, renewed ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's faction combat/invasion and spawning-structure examples.

**Original scout proposal (verbatim):** New scout selection: attribute Darkmega's qualitative faction combat/invasion and spawning-structure encounter examples.

**Previously selected precision option (task inventory verbatim):** Named qualitative examples; preserve author's labels without inventing faction identity equivalence.

**Original scout precision detail (verbatim; same narrow selection):** Named examples of undead/necromancers, paladin/unholy-pact and druid/steel conflict; author's labels preserved rather than silently establishing faction identity equivalence.

**Approval versus Refusing:** approval improves named attribution within existing policy;
refusal would decline that precision only, not approve an opposite mechanic. Neither changes
the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 105` / §7 after local raw
inspection and canonical items 1–104 duplicate-screen. Independent source/scope review approved
with no findings; scoped canonical commit verified before removal of only this handled selection.
Two sibling blocks remain byte-identical and pending. Items 74/79/83–87 and settled rules stand.
**Dependencies (queue verbatim):** Item 70 provenance; Items 74,79,83-87 duplicate boundaries.
**Queued documentation / implementation boundary (verbatim):** Documentation only; no faction roster, allegiance, spawn structure rule or mission reward changes.
**Selected boundary:** preserve “in some cases”, example framing and author labels; no frequency,
spawn parameters, faction-membership equivalence, universal allegiance/hostility contract, reward,
repeatability or reset rule inferred. Mini structures do not absorb items 83–87's larger mechanics.
No gameplay/live JSON/checker/tests, assets or new implementation debt. Settled rules stand.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1128`,
**A questing we shall go! / Combat encounter**; exact necromancer/undead, paladin/unholy-pact,
druid/steel and conditional mini-portal/mana-generator examples checked in raw.
`guide.text:2862–2864` agrees as derivative inspection text, not raw-byte equality.
Raw SHA-256 freshly matches `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture and title/author/displayed dates independently checked: guide 1871398574,
Darkmega; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**, timezone
unspecified; title **updated 4/10** distinct. HTTP 200 capture **2026-10-04T21:01:17Z**;
item 70 limits apply. No immutable revision, original-build/Alpha proof or introduction chronology;
no external retrieval or linked-image inspection. Catalog/research context is not stronger raw
evidence; scoped GDScript searches found no relevant runtime faction/mission consumer.
**Checks/evidence:** managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`items/r0-g3-i0-evidence/`: source/Git/index/full-diff/queue snapshots. Installed simplify then
ponytail-review completed; fresh `git diff --check` and `timeout 150 nix develop -c godot
--headless -s ontology/validate.gd` both exit 0 (ontology valid). Validator covers loaded data
only, not prose truth or runtime behavior; no gameplay tests added/run. Context percentage
unavailable; no broader exhaustion or publication claim. Writer did not stage, commit or push.

**Independent review / local receipt (2026-10-10):** reviewer origin
`cbf1d4f0-5f9b-4a7d-97e5-0763f75f5fe1` returned **approved**, no findings, for the exact writer
origin `6d54bf4a-799e-4d5c-9fc0-3773061c02be` diff at
`4d78f857fc4dce0a21bbc25c5dbbf52325f8f445`. Full-index diff SHA-256
`1d56c393e4498b8abb5d53e0a73dc0e4f2ce7c056faae75b496bb1bfa0a81996` matched actual Git and
writer evidence byte-for-byte. Exact forwarded native payloads/origins checked against REAL
saved structured JSON; distinct copies/provenance retained in managed
`receipts/r0-g3-i0-evidence/`, originals untouched, including the empty reviewer bound report.
No empty-file wait, review waiver or self-review substitution. Finalizer freshly inspected raw
passage/identity/dates, branch/HEAD/upstream/index/full diff/queue and applied installed simplify
then ponytail-review; no warranted cuts. Fresh whitespace and bounded validator gates passed
before canonical commit `a1c83918d44304332074c48bb2dd666175831830`, parent
`4d78f857fc4dce0a21bbc25c5dbbf52325f8f445`. Exactly four canonical Markdown paths:
`ontology/domain.md`, `ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md`;
hash/parent/paths/content verified byte-for-byte against the independently reviewed canonical
diff before removing only faction from the queue. Exact selection/amendments above retained;
artifact-dungeon and glider/boat sibling blocks byte-identical and pending. Separate receipt/
queue maintenance follows, without changing §5 item 105's source content. No gameplay/live
JSON/checker/tests/assets, new debt, push or broader exhaustion claim. Validator proves loaded
data only, not prose truth or runtime behavior; context percentage unavailable.

### Validation-contract source attribution — candidate-darkmega-ingredient-attribution / item 104 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, renewed ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: classify Darkmega's ice-cube, cocoa/banana, kale, sugar and fallen-lemon sourcing claims by certainty.

**Original scout proposal (verbatim):** New scout selection: classify Darkmega's ice-cube, cocoa/banana, kale, sugar and fallen-lemon sourcing reports by their actual certainty.

**Previously selected precision option (task inventory verbatim):** Preserve apparently, feel-like speculation, occasionally and explicit reports as distinct named community claims.

**Original scout precision detail (verbatim; same narrow selection):** Ice cubes apparently, cocoa/banana feel-like speculation, kale occasionally, and explicit sugar/lemon reports remain distinct named community claims; no guessed certainty or edition chronology.

**Approval versus Refusing:** approval improves named attribution within existing policy;
refusal would decline that precision only, not approve an opposite mechanic. Neither changes
the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 104` / §7 after local raw
inspection and canonical items 1–103 duplicate-screen. Independent source/scope review approved
with no findings; scoped canonical commit verified before removal of only this handled selection.
Three sibling blocks remain byte-identical and pending. Items 45/92 and settled rules stand.
**Dependencies (queue verbatim):** Item 70 provenance; Item 92 intentionally excludes ingredient-location inference; Duplicate-screen items 27,36,46,47,63,69.
Item 45's other-guide sugar report is not reselected; Silk/Spinning Wheel quantities remain HOLD.
**Queued documentation / implementation boundary (verbatim):** Documentation only; no biome placement, recipes, drop quantity, drink effects or availability changes.
**Previously selected boundary (verbatim):** Documentation only; no biome placement, recipes, drop quantity, drink effects or availability changes. Preserve apparently, feel-like and some/occasionally verbatim; explicit sugar/lemon claims remain community reports, not authenticated mechanics. No guaranteed stock, prices, respawn/yield, tree identity, source-version reassignment or edition/chronology proof, gameplay/live-JSON/checker/tests or new implementation debt. Approval versus Refusing: only attribution precision differs; neither changes the approved player experience or approves an opposite mechanic.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1136`,
**Volcano Panic, Icy Blues and Toxic Greens**, after the environmental-drink speculation.
Ice Cube “apparently”; Cocoa Bean/Banana “feel like” speculation; Kale “some” / “occasionally”;
explicit sugar-store/fallen-lemon reports stay community claims. Catalog locations/A/S tags remain
unchanged declarations, not authenticated by this passage. `guide.text:2962–2966` is derivative
corroboration, not raw-byte equality. Raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars and title/author (610/825), displayed dates (846–847) checked separately:
Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**,
timezone unspecified; title **updated 4/10** distinct. HTTP 200, capture **2026-10-04T21:01:17Z**;
item 70 limits apply. No immutable revision, original-build/Alpha proof or introduction chronology;
no external retrieval. Catalog loading, ingredient-name lookup and species-drop membership checks
are not source-location or certainty verification; consumers untouched.
**Checks/evidence:** managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`items/r0-g2-i2-evidence/`: source/Git/index/full-diff/queue snapshots; installed simplify then
ponytail-review completed, no warranted cuts. Fresh `git diff --check` and `timeout 150 nix develop
-c godot --headless -s ontology/validate.gd` both exit 0 (ontology valid).
Validator checks loaded data only, not prose truth or runtime behavior; no gameplay tests added/run.
Context percentage unavailable; no broader exhaustion or publication claim. Writer did not stage,
commit or push; finalizer recording/receipt follows. Local only, not pushed.

**Independent review / recording receipt (2026-10-10):** exact supplied native writer result
(origin `94f39048-c525-43c3-ba40-eaa5ff91872c`) and approved independent review with no findings
(origin `55caf0f0-9ee4-4309-be5e-d3a3739e9444`) inspected against actual Git/index/full diff,
selected queue and raw source; real saved structured JSON verified and copied only into distinct
managed evidence with original delivery origins. Reviewer bound report was empty and untouched;
no empty-file wait, review waiver or self-review substitution. Actual full-index diff matched
writer/reviewer SHA-256 `9d3adc40c637a9502502a93bb92f02013eaca7cfa435ef00b3b41589453801a9`
byte-for-byte. Finalizer separately verified raw hash/exact quotes and identity/date/capture limits,
then applied installed simplify followed by ponytail-review (no warranted cuts) and freshly ran
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`,
both exit 0 before committing. Canonical commit `c4f328dc7c71242219a4cec721abf0fe37db4fb3`,
parent `92ed0b7eedcde69d458814e8370de1610753552a`: exact five intended Markdown paths,
full diff and content verified against independently reviewed snapshots; clean index/worktree
before receipt maintenance. Only afterward removed ingredient; three sibling selections remain
byte-identical/unapplied/pending. Exact decision/amendments/dependencies/boundaries above retained.
Receipt maintenance is separate from the canonical item commit. No gameplay/live-data/checker/
tests, new debt or push. Evidence: managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`receipts/r0-g2-i2-evidence/` (native payload/origin copies, source/Git/index/full-diff/queue snapshots,
fresh checks and verified commit). Validator checks loaded data only, not prose/runtime behavior;
context percentage unavailable. Next: faction encounters, then the other two queued selections;
no broader precision-exhaustion or publication claim.

### Validation-contract source attribution — candidate-darkmega-arena-attribution / item 103 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, renewed ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's escalating boss-rush/loot and qualified final-boss/respawn observations.

**Original scout proposal (verbatim):** New scout selection: attribute Darkmega's escalating arena boss-rush/loot report and explicitly qualified final-boss/respawn observations.

**Previously selected precision option (task inventory verbatim):** Named qualitative community report; three preliminary rounds and I-think respawn do not replace canonical five waves/reset rules.

**Original scout precision detail (verbatim; same narrow selection):** Named qualitative community corroboration; source's three preliminary rounds and I-think respawn are historical reports, not authority to replace canonical five waves or reset policy.

**Approval versus Refusing:** approval improves named attribution within existing policy;
refusal would decline that precision only, not approve an opposite mechanic. Neither changes
the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 103` / §7 after local raw
inspection and canonical items 1–102 duplicate-screen. Item 93's world-boss appearance/moves/loot
and separate next-day claim are distinct, not reselected. Independent source/scope review
approved with no findings; canonical commit verified before removing only this handled selection.
Four sibling blocks remain byte-identical and pending. Exact decisions and boundaries retained.
**Dependencies:** Item 70 provenance; Item 93; Approved clock/reset/occupied-site policy.
Preserve `c-arena-waves`' exactly-five-wave ladder, existing rewards and `c-permanent-source-claim`.
**Queued documentation / implementation boundary (verbatim):** Documentation only; no wave count, reward, reset or arena balance changes.
**Previously selected boundary (verbatim):** Documentation only; no wave count, reward, reset or arena balance changes. No inferred four-wave replacement, numeric difficulty/rewards, guaranteed species/host/location, clock-triggered survivor reset or renewing permanent claims. Preserve explicit source/canonical disagreement and tentative respawn wording. No source labels, gameplay/live-JSON/checker/tests or new implementation debt. Approval versus Refusing: only attribution precision differs; neither changes the approved player experience or approves an opposite mechanic.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1112,1128`,
**Cartography Quicky** / **A questing we shall go!**. Escalation and loot are qualitative;
three preliminary rounds conflict with canonical five waves, not a correction. “Usually” and
“I think” retained in broader Skull-icon/boss context; no universal arena respawn guarantee.
No images/assets inspected. `guide.text:2740,2918–2922` corroborates as derivative text, not
raw-byte equality. Raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars and title/author (610/825), displayed dates (846–847) checked separately:
Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**,
timezone unspecified; title **updated 4/10** distinct. HTTP 200, capture **2026-10-04T21:01:17Z**;
item 70 limits apply. No immutable revision, original-build/Alpha proof or introduction chronology;
no external retrieval. Generic catalog loading is not arena enforcement; no arena runtime consumer
found in inspected GDScript.
**Checks/evidence:** writer source/Git/index/full-diff/queue checks, installed simplify then
ponytail-review, fresh `git diff --check` and `timeout 150 nix develop -c godot --headless -s
ontology/validate.gd` both exit 0 (ontology valid): managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`items/r0-g2-i1-evidence/`. Validator checks loaded data only, not prose truth or runtime behavior;
no gameplay tests added/run. Context percentage unavailable; no broader exhaustion or publication
claim. Writer did not stage, commit or push.
**Independent review:** approved with no findings, origin run
`3e35b5a2-99bf-4f63-a0ba-f5357c37a150`; substantive native payload forwarded directly and
verified against its real saved structured JSON. Writer origin
`24e5fa4a-a558-434b-b5b9-5d1f290ab84b` likewise verified. Exact payloads/origins retained in
DISTINCT managed evidence; original delivery artifacts untouched, including the empty reviewer
bound file. No empty-file wait, review waiver or self-review substitution. Reviewed full-index
diff SHA-256 `50937c84c1d02c0e43a47bbb9e674c9895afec6950764fc5acf4fedc6baf83b6` matches
actual precommit diff and verified canonical commit content.
**Canonical commit receipt:** `d7c89560bf02489c31cb8c1868417bfc8808f57a`, parent
`2717e249aaf8ac6d64ad3ee2f0d630f713dbbb87`; exactly `ontology/domain.md`, `ontology/README.md`,
`docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md`, `docs/todo_handle_reconciled_items.md`.
Hash/parent/paths/content verified before queue removal; only arena removed, four siblings unchanged.
Finalizer independently checked raw identity/hash/quotes/dates/sidecars, actual branch/ref/index/
worktree/upstream/full diff and exact selection scope; installed simplify then ponytail-review
found no warranted cuts. Fresh precommit `git diff --check` and `timeout 150 nix develop -c godot
--headless -s ontology/validate.gd` exit 0. Evidence:
managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `receipts/r0-g2-i1-evidence/`.
Validator proves loaded-data checks only, not prose truth or runtime behavior. Local only; not pushed.

### Validation-contract source attribution — candidate-darkmega-lore-attribution / item 102 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, renewed ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's tablets/crypts/ruins lore-location and artifact-reveal report.

**Previously selected precision option (task inventory verbatim):** Named qualitative corroboration retaining usually/potential qualifiers, no inferred percentages.

**Original scout precision detail (verbatim; same narrow selection):** Named qualitative community corroboration; retain usually/potential site qualifications, without supplying lore percentages or canonical story text.

**Approval versus Refusing:** approval improves named attribution within existing policy;
refusal would decline that precision only, not approve an opposite mechanic. Neither changes
the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 102` / §7 after local raw
inspection and canonical items 1–101 duplicate-screen. Items 21/82 concern NPC hints and the
unverified lore-hint hypothesis, not this report. Independent source/scope review approved with
no findings; canonical commit verified before removing only this handled selection. Five sibling
blocks remain byte-identical and pending. Exact decision and boundaries below retained unchanged.
**Dependencies:** item 70 provenance; Persistence item 3; Items 21/82. Preserve §3.7 item 2's
per-character/per-saved-world lore records; shared explored terrain grants no personal lore
knowledge. D1/D6 and settled artifact progression stand.
**Previously selected boundary (verbatim):** Documentation only; no map reveal threshold, shared lore knowledge or artifact-level changes. Preserve settled approximately-10%/100% descriptions without claiming this passage verifies their numbers. No guaranteed sites, visual identification rule, literal story/corpus, chronology, source-version reassignment, gameplay/live-JSON/checker/tests or new implementation debt. Approval versus Refusing: only attribution precision differs; neither changes the approved player experience or approves an opposite mechanic.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1096`,
**Picking up the pace / Hunt lore Pieces**; both “usually” qualifications and “all potential spots”
retained. Artifact-reveal statement is qualitative; artifact-based leveling is historical Steam
comparison only. `guide.text:2587–2588` corroborates as derivative text, not raw-byte equality.
Raw SHA-256 freshly matches `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars and title/author (610/825), displayed dates (846–847) checked separately:
Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**,
timezone unspecified; title **updated 4/10** distinct. HTTP 200, capture **2026-10-04T21:01:17Z**;
item 70 limits apply. No immutable revision, original-build/Alpha proof or introduction chronology;
no external retrieval. Generic catalog loading is not lore enforcement; no lore runtime consumer
found in inspected GDScript.
**Independent review:** run `6a8c7531-c323-4328-a0ad-c4232eabb95a`, approved with no findings;
substantive native result and actual source/Git/index/full diff inspected. Exact forwarded result/origin
retained distinctly and matched against real saved structured JSON from that exact run. Writer origin
`545c63e5-dc10-4300-8783-71554f81c66c` likewise retained/verified. Original bound reports and
delivery receipts untouched; no empty-file wait, review waiver or self-review substitution.
**Canonical commit receipt:** `251cb4bc628ed7c3b00430890376735efe9d0faf`, parent
`8cdfa6c71cf4c500dfc5c6f3ded223af5850218a`; paths exactly `ontology/domain.md`,
`ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md` and
`docs/todo_handle_reconciled_items.md`. Committed full-index diff SHA-256
`e885c9f2be78c637f3ad5719ceb79f6eb93beb35f1b7d883d047ccf1c2d4b3a7` exactly matches the
independently reviewed diff. Hash/parent/paths/content and clean postcommit index/worktree verified
before queue removal. Only lore removed afterward; five sibling blocks unchanged/pending.
**Checks/evidence:** finalizer locally rechecked retained raw/provenance/qualifiers, exact selections,
actual Git/index/full diff and sibling scope; installed simplify then ponytail-review found nothing
worth removing. Fresh precommit `git diff --check` and `timeout 150 nix develop -c godot
--headless -s ontology/validate.gd` both exit 0 (ontology valid); writer/reviewer gates remain separate.
Source/scope, native provenance, full-index diff, queue/Git snapshots and commit receipt: managed run
`71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g2-i0-evidence/` and
`receipts/r0-g2-i0-evidence/`. Validator checks loaded data only, not prose truth or runtime behavior;
no gameplay tests added/run. Context percentage unavailable; no source-precision exhaustion or
publication claim. Local commits only; not pushed.

### Validation-contract source attribution — candidate-darkmega-mage-weapons / item 101 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, renewed ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's staff, wand and bracelet attack/cancellation descriptions.

**Previously selected precision option (task inventory verbatim):** Named qualified reports of stationary tornado, finite hitscan beam and gravity-free bolts; estimates/cancellation remain historical observations.

**Original scout precision detail (verbatim; same narrow selection):** Named community corroboration of fixed-location tornado, finite-range hitscan wand and gravity-free bracelet bolts; estimated beam ticks and terrain/combo/cancel observations remain historical reports, not correctness proof.

**Approval versus Refusing:** approval improves named attribution within existing policy;
refusal would decline that precision only, not approve an opposite mechanic. Neither changes
the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 101` / §7 after local raw
inspection and canonical items 1–100 duplicate-screen. Consolidated G2 movesets are not independent
testing or a separate named attribution; item 97's Mage ability/MP report is distinct. Independent
source/scope review approved with no findings; verified canonical item commit and finalizer fresh
gates completed before removing only Mage weapons. Six sibling blocks remain byte-identical,
unapplied and queued.
**Dependencies/boundary:** item 70 provenance; Approved Wand item 1; D24. Documentation only;
preserve mechanically two-handed Wand/no other hand item, approved recipes and current combo policy.
Retain estimates, cancellation and terrain/combo accounts explicitly as source reports, not correctness
proof or permission to replace whole-channel miss handling. No hands/recipe/cap change, new controls/
MP behavior, animation, ray/channel/projectile implementation, source-label/live-JSON/checker/test
change or new debt. Approval concerns documentation precision only; refusal approves no opposite.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1086-1088`,
**Weapons and You, cont [Mages]**; raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars, title/author (610/825) and displayed dates (846–847) checked separately:
Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**,
timezone unspecified; title **updated 4/10** distinct. HTTP 200, capture **2026-10-04T21:01:17Z**;
item 70 limits apply. No immutable revision, original-build/Alpha proof or introduction dating;
wand spray/since-beta wording is the author's chronology claim only. Inspection text is derivative,
not byte-equal raw HTML; no external retrieval. Current configured beam/at-cursor/projectile
consumers do not demonstrate historical channel behavior or animation. Stale live Wand handedness/
recipe values do not override item 1 and remain separately deferred, not newly authorized debt.
**Checks/evidence:** installed `/simplify` then ponytail-review and fresh `git diff --check` /
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` results retained in managed
run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g1-i3-evidence/`, with raw source/scope,
full-index diff and queue/Git snapshots. Validator checks loaded data only, not prose truth or
runtime behavior; no gameplay tests added/run. Context percentage unavailable; no exhaustion claim.
**Independent review:** exact forwarded native result from origin
`dddfaba2-0046-4b52-81d3-75caab5a8847`, approved, no findings/blockers; real saved structured JSON
from that exact origin inspected and retained distinctly with original delivery provenance. Writer
origin `082f23a1-ad3f-485f-aada-aabd660f7a18` likewise verified against saved JSON. Original bound
reports and saved outputs untouched; no empty-file wait, review waiver or self-review substitution.
**Verified canonical receipt:** `e6b1b5139ca884c58c949e9224f47c2370c80858`, parent
`b1c241ccd45e6eda0daf120fc1c27c04b149393f`; paths only `ontology/domain.md`,
`ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md` and
`docs/todo_handle_reconciled_items.md`. Complete commit diff byte-matches independent-reviewed
full-index diff SHA-256 `c7d6a7c4d3ae8388c85195ce717e45a1067e953a96cc7c2d70ceff46d5bcee50`;
hash/parent/paths/content and clean index/worktree verified before queue removal. Finalizer fresh
source/Git/diff assertions, installed `/simplify` then ponytail-review, `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed before canonical
commit. No gameplay tests or new debt; validator checks loaded data only, not prose/runtime behavior.
Only this handled selection removed; six unchanged sibling blocks pending, lore attribution next.
Receipt/status/queue maintenance is separate from canonical recording. Distinct finalizer raw/native-
provenance/Git/diff/gate/commit/queue evidence: managed run
`71edbb08-9210-4b6b-ad27-5eda9476b261`, `receipts/r0-g1-i3-evidence/`. Not pushed; owner
session/publication frontier unchanged; context percentage unavailable, no exhaustion claim.

### Validation-contract source attribution — candidate-darkmega-ranger-weapons / item 100 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, new ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's bow, crossbow and boomerang trajectory/special descriptions.

**Original scout proposal (verbatim):** New scout selection: attribute Darkmega's bow, crossbow and boomerang trajectory and special-attack descriptions.

**Previously selected precision option (task inventory verbatim):** Named qualified reports, preserving random-loot and untested Sniper caveats.

**Original scout precision detail (verbatim; same narrow selection):** Named community corroboration of arrow arc/volley, charged crossbow bolt, cursor-following boomerang and dual toss; preserve random-loot and untested Sniper caveats. Numeric caps/qualitative ranges remain source reports.

**Approval versus Refusing:** approval improves bounded attribution; refusal declines only that
refinement, not an opposite mechanic. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 100` / §7 after local raw
inspection and canonical items 1–99 duplicate-screen. Consolidated movesets/G2 citations are not
independent testing or separate named attribution of the selected passage; item 95's Ranger
abilities remain distinct. Independent source/scope review approved with no findings; verified
canonical item commit and finalizer fresh gates completed before removing only Ranger. Seven
sibling blocks remain byte-identical/unapplied and queued.
**Dependencies/boundary:** item 70 provenance; item 53; D24. Documentation only; no volley count,
splash, range, timer, trap reduction or damage change. Preserve the source's four-arrow report
separately from consolidated 4–5 wording, random-loot/untested-Sniper qualifiers, item 53's
Bows AND Crossbows versus Boomerangs comparison and unlimited arrows, item 95 and D24.
No dud-shot, steering, animation or knockdown implementation; no source-label/live-JSON/checker/
test change or new debt. Approval changes attribution precision only, not approved gameplay;
refusal would not approve an opposite rule.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1078-1080`,
**Weapons and you, cont. [Rangers]**; raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars, title/author (610/825) and displayed dates (846–847) checked separately:
Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**,
timezone unspecified; title **updated 4/10** distinct. Retained HTTP 200, capture
**2026-10-04T21:01:17Z**; item 70 limits apply. No immutable revision, original-build/Alpha proof
or introduction dating. Inspection text is derivative, not byte-equal raw HTML; no external
retrieval. Configured projectile/count/gravity/splash/return/tick values and current consumers
are not matched-original-behavior proof.
**Checks/evidence:** installed `/simplify` then ponytail-review and fresh `git diff --check` /
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` results retained in managed
run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g1-i2-evidence/`, with raw source/scope,
full-index diff and queue/Git snapshots. Validator checks loaded data only, not prose truth or
runtime behavior; no gameplay tests added/run or exhaustion claim. Context percentage unavailable.
**Independent review:** exact forwarded native result from origin
`be2ea5bd-5f92-4324-bf1e-01f30579b5ca`, approved, no findings/blockers. Original bound file was
empty during enclosing workflow; real saved structured JSON from that exact origin inspected and
retained distinctly, together with forwarded payload and original delivery provenance. Writer origin
`ac06ff06-6262-4577-a0dc-31c5d418ff16` likewise verified against saved JSON/nonempty bound report.
No originals overwritten, empty-file wait, review waiver or self-review substitution.
**Verified canonical receipt:** `e4a60f47d2f0f1738882913ccd12191471838b38`, parent
`27b79e81e728fbb72c2861394f3b645fff9fd3c5`; paths only `ontology/domain.md`,
`ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md` and
`docs/todo_handle_reconciled_items.md`. Complete commit diff byte-matches independent-reviewed
full-index diff SHA-256 `1e21da036be24d617fc19a72850bda43c3f6bb087ab6c927f7a7bf6c0e34f779`;
hash/parent/paths/content and then clean index/worktree verified before queue removal.
Finalizer fresh source/Git/diff assertions, installed `/simplify` then ponytail-review,
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`
passed **before** canonical commit. No gameplay tests or new debt; validator checks loaded data only.
Only this handled selection removed; seven unchanged sibling blocks remain pending, Mage weapons
next. Receipt/status/queue maintenance is separate from canonical recording. Distinct finalizer
raw/native-provenance/Git/diff/gate/commit/queue evidence: managed run
`71edbb08-9210-4b6b-ad27-5eda9476b261`, `receipts/r0-g1-i2-evidence/`. Not pushed; owner
session/publication frontier unchanged; context percentage unavailable, no exhaustion claim.

### Validation-contract source attribution — candidate-darkmega-rogue-weapons / item 99 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, new ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's fist, dagger and longsword movesets and minor-tested poison observations.

**Original scout proposal (verbatim):** New scout selection: attribute Darkmega's fist, dagger and longsword moveset reports, including explicitly minor-tested poison observations.

**Previously selected precision option (task inventory verbatim):** Named qualified community reports; poison testing remains tentative and tick/lunge counts historical. Do not reselect item 64 handedness.

**Original scout precision detail (verbatim; same narrow selection):** Named community report of roundhouse, dagger poison and multi-hit lunge; minor testing remains tentative, around five ticks/five seconds and four-five lunge hits remain report-only. Do not repeat item 64 handedness as a new decision.

**Approval versus Refusing:** approval improves bounded attribution; refusal declines only that
refinement, not an opposite mechanic. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 99` / §7 after local raw
inspection and canonical items 1–98 duplicate-screen. Consolidated movesets/G2 citations are not
independent testing or separate named attribution of the selected reports. Items 49/64 and item 94's
Rogue ability report stay settled. Independent source/scope review approved with no findings;
canonical commit `05a18f13d9e0c8fdd3ddc063e4426adcaf3af75b` verified before removing only this
handled selection. Eight sibling blocks remain unchanged/pending.
**Dependencies/boundary:** item 70 provenance; item 64 duplicate boundary; D24/D26. Documentation
only; preserve tentative minor testing, historical tick/lunge counts and stacking/crit reports,
existing poison/dodge and combo policies, approved equipment and items 49/64. Do not reinterpret
source pairing typo or preferences as equipment/damage defaults. This passage does not establish
poison bypassing dodge; the research's FW Dodge citation is separate. No poison stacking/formula/
timing or main-hand policy change, runtime/live JSON/checker/tests, source-label reassignment or
new implementation debt. Approval concerns attribution only; refusal would not approve the opposite.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1070-1072`,
**Weapons and you, cont [Rogue] / Rogue weapon analysis**; raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars, title/author (610–611/825) and displayed dates (846–847) checked
separately: Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated
**3 Oct, 2019 @ 10:14am**, timezone unspecified; title **updated 4/10** distinct. Retained
HTTP 200, capture **2026-10-04T21:01:17Z**; item 70 limits apply. No immutable revision,
original-build/Alpha proof or introduction dating. Inspection text is derivative, not byte-equal
raw HTML; no external retrieval. Current main-hand consumers and configured poison's shared
burning slot are not historical hand-priority or stacking proof.
**Checks/evidence:** installed `/simplify` then ponytail-review and fresh `git diff --check` /
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` results retained in managed
run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g1-i1-evidence/`, with raw source/scope,
full-index diff and queue/Git snapshots. Validator checks loaded data only, not prose truth or
runtime behavior; no gameplay tests added/run or exhaustion claim. Context percentage unavailable.
**Review/finalizer receipt:** supplied complete native writer result from origin
`a8eb5a71-d13a-461a-a38e-798cd8a53978` and independent approved review from origin
`37ecd828-f64e-4f1d-8a53-a6936880fd1f` inspected with actual raw/Git/index/full-diff/queue scope.
Exact native payloads and original delivery origins retained in DISTINCT managed receipt evidence;
verified against real saved structured JSON, with nonempty bound reports copied separately.
No empty-file wait, review waiver or self-review substitute. Actual reviewed five-file full-index
diff SHA-256 `48821963ac4d249f15983ae6d0fe04783d8bdcd9ff1c481407d21ee5d078c3e5` matched
before staging. Finalizer applied installed `/simplify`, then ponytail-review: no warranted cuts;
fresh whitespace and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed
(exit 0) BEFORE canonical commit. Commit parent
`d7513fa84a305f8c712104a7c08e98630233713b`, exact intended five Markdown paths and content
verified against the reviewed diff; index/worktree clean at that boundary. Exact four saved wording
lines above retained without amendments; only Rogue removed after verified recording/review/commit,
eight siblings byte-identical. Separate receipt/queue maintenance retains these facts.
Managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `receipts/r0-g1-i1-evidence/`:
original-native/delivery verification, local raw/sidecars, source/scope check, Git/diff snapshots,
canonical commit verification and fresh gate logs/exits. Validator proves loaded-data checks only,
not prose truth/runtime behavior. Context percentage unavailable; no exhaustion claim. Local only,
not pushed; no gameplay/live-data/checker/tests, source-label change or new implementation debt.

### Validation-contract source attribution — candidate-darkmega-warrior-weapons / item 98 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, new ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's great-weapon, dual-one-hander and shield moveset descriptions.

**Previously selected precision option (task inventory verbatim):** Named qualitative community corroboration; subjective favorites/proc impressions are not mechanics authority.

**Original scout precision detail (verbatim; same narrow selection):** Named qualitative community corroboration of three-hit sequence, overhead versus defensive sweep, dual spin and shield charge; subjective favorites and proc impressions are not mechanics authority.

**Approval versus Refusing:** approval improves bounded attribution; refusal declines only that
refinement, not an opposite mechanic. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 98` / §7 after local raw
inspection and duplicate-screening canonical items 1–97. Consolidated Warrior descriptions/G2
citations are corroboration, not separate named attribution of these movesets. Item 96 already
records the block-mana disagreement and is not reselected. Independent source/scope review
approved with no findings; exact native result and origin `ca1214cc-afa3-4211-a7cb-98cc4bd660c2`
verified against real saved structured JSON and retained distinctly with original delivery provenance.
No empty-bound-file wait or review waiver. Canonical commit
`24a94c5a40d2361a9ddcf55515f73a5626df8359`, parent
`630465d91c97edb49751bfbafe2abd19447edc14`, contains only `ontology/domain.md`,
`ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md`; content exactly matches
those paths in the independently reviewed diff. Only this handled selection removed after verified
recording/review/checks/commit; all nine sibling queue blocks byte-identical and pending.
**Dependencies/boundary:** item 70 provenance; D24/D23; preserve item 96's block-mana disagreement
and D11/D23 block MP reward. Favorites, comparative damage/speed, Fury procurement and
knockdown reliability remain qualified personal reports, not proc rates or mechanics authority.
Shield charge means charging the special, not a dash; Defender is the author's label, not a
Guardian rename. No Basics/unarmed expansion, animation, attack range, knockdown, combo or
block change, source-version reassignment, runtime/live JSON/checker/tests or new debt. No push.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1062-1064`,
**Weapons and you. [Basics and Warrior] / Warrior Weapon Analysis**; raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars, title/author (610–611/825) and displayed dates (846–847) checked
separately: Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated
**3 Oct, 2019 @ 10:14am**, timezone unspecified; title **updated 4/10** distinct. Retained
HTTP 200, capture **2026-10-04T21:01:17Z**; item 70 limits apply. No immutable revision,
original-build/Alpha proof or introduction dating. Inspection text is derivative, not byte-equal
raw HTML; no external retrieval. Current configured movesets/consumers are not animation proof.
**Checks/evidence:** installed `/simplify` then ponytail-review and fresh `git diff --check` /
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` results retained in managed
run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g1-i0-evidence/`, with raw source/scope,
full-index diff and queue/Git snapshots. Validator checks loaded data only, not prose truth or
runtime behavior; no gameplay tests added/run or exhaustion claim. Context percentage unavailable.
**Finalizer receipt:** fresh actual source/Git/index/full-diff inspection matched reviewed SHA-256
`f2564cd6c2432df8dc9ecd4cfa64a7ce7571e5b0f6ece49b67daae2a9a9f65cd`. Installed `/simplify`
then ponytail-review applied; fresh whitespace and `timeout 150 nix develop -c godot --headless
-s ontology/validate.gd` both passed before the canonical commit. Hash/parent/paths/content
verified before queue removal; exact original/forwarded native reports and delivery provenance,
raw/sidecars, queue/scope assertions, full diffs, commit receipts and fresh maintenance gates retained
in managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `receipts/r0-g1-i0-evidence/`.
Local only, not pushed; nine remaining selections pending.

### Validation-contract source attribution — candidate-darkmega-mage-abilities / item 97 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, new ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's Fire/Water Mage mana, hover, teleport, particle, missile, healing-puddle and bubble descriptions.

**Original scout proposal (verbatim):** New scout selection: attribute Darkmega's Fire/Water Mage mana, hover, teleport, fire-particle, missile, healing-puddle and bubble descriptions.

**Previously selected precision option (task inventory verbatim):** Named community reports; stacking/hover observations and approximate counts are historical, not formulas.

**Original scout precision detail (verbatim; same narrow selection):** Named community corroboration, separating observed effects and approximate counts from authoritative formulas; stacking and hover exploits are historical reports only.

**Approval versus Refusing:** approval improves bounded attribution; refusal declines only that
refinement, not an opposite mechanic. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 97` / §7 after local raw
inspection and duplicate-screening items 1–96. Generic definitions, research G2 citations and
items 57–59/70 or earlier teleport patch attribution do not already attribute this Mage passage.
Independent source/scope review approved with no findings; exact native result and origin
`ff4d0f13-4e82-48d1-a82c-87e4ccf3bb9c` verified against its real saved structured JSON and retained
in distinct managed evidence with original delivery provenance. No empty-bound-file wait or review
waiver. Canonical commit `67c3cd489d686cb760d4fcfc857700078bd93818`, parent
`b0e83f966bf25d72b4b1024402423f82c7c32b17`, contains only `ontology/domain.md`,
`ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md`; content exactly matches
those paths in the independently reviewed diff. Only this handled selection removed after checks
and verification; all ten sibling queue blocks byte-identical.
**Dependencies/boundary:** item 70 provenance; items 57–59; D21/D24. Hover seems-free/reapplication
and puddle-stacking observations remain historical, not formulas, upgrade permission or correctness
proof. Four missiles and around-six bubbles stay separately attributed; F1's six bubbles stands.
Jump-then-Shift does not prove the separate Super Float height/input; Water Mage Alpha comparison
is not build evidence. Configured healing/projectiles/MP and consumers are not original-build
proof. No unlimited movement, healing stacking, projectile count, mana or source-label change;
no live JSON, gameplay, checker/tests or new implementation debt. No push.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1046-1048`,
**Choose your Character! [Mages]**; raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars, title/author (610–611/825) and displayed dates (846–847) checked
separately: Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated
**3 Oct, 2019 @ 10:14am**, timezone unspecified; title **updated 4/10** distinct. Retained
HTTP 200, capture **2026-10-04T21:01:17Z**; item 70 limits apply. No immutable revision,
original-build/Alpha proof or release/introduction dating. Parser text is derivative, not byte-equal
raw; no external retrieval or embedded video inspection.
**Checks/evidence:** installed `/simplify` then ponytail-review and fresh `git diff --check` /
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` results retained in managed
run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g0-i3-evidence/`, with source/scope checks,
full-index diff and queue/Git snapshots. Validator proves loaded-data checks only, not prose truth
or runtime compliance. No gameplay tests added/run or exhaustion claim; context percentage unavailable.
**Finalizer timing exception/receipt:** fresh whitespace passed precommit, but a top-level brace-group
`exit` terminated that shell before the finalizer validator; no precommit validator execution is claimed.
Original partial gate log preserved; earlier writer/reviewer checks remain separate. Supervisor explicitly
authorized retaining the reviewed scoped commit without history rewrite, conditional on fresh postcommit
validation and source/Git/commit-scope verification before queue removal. Those checks passed:
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exit 0, ontology valid.
Subsequent gates run separately with captured statuses; fresh maintenance checks retained. Exact native
review/origin, source/Git/diff/queue, supervisor timing authority, canonical hash/parent/paths/content and
fresh gate receipts: managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`receipts/r0-g0-i3-evidence/`. Local only, not pushed; ten remaining selections pending.

### Validation-contract source attribution — candidate-darkmega-warrior-abilities / item 96 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, new ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's Berserker/Defender spin, smash, Rock Fist, Battle Fury and Heroic Shout reports.

**Previously selected precision option (task inventory verbatim):** Named qualified community corroboration; preserve uncertain proc/duration impressions and internal block-mana disagreement.

**Original scout precision detail (verbatim; same narrow selection):** Qualified named community corroboration; retain uncertain Fury duration/attack-speed and proc-rate impressions. Preserve source's internal block-mana disagreement rather than selecting a rule.

**Approval versus Refusing:** approval improves bounded attribution; refusal declines only
that refinement, not an opposite mechanic. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 96` / §7 after local raw
inspection and duplicate-screening items 1–95. Generic definitions, research G2 citations and
items 57–59/70 do not already attribute this Warrior passage or its internal mana disagreement.
Independent source/scope review approved with no findings; finalizer fresh gates passed.
Canonical commit `a53c005f09aac94baaa91b827a5efb9649b2a602` verified against parent
`580c6cd033c2e39ec79f3809523ad2f7b49ea4ef`: exactly the four intended canonical/ledger/status/
HANDOFF Markdown paths and staged content; index empty afterward. Only this handled selection
removed; all eleven sibling entries byte-identical and pending. Receipt/queue maintenance is
separate from the canonical item commit. No push.
**Dependencies/boundary:** item 70 provenance; items 57–59; D21/D23 and settled taunt/aggro.
All source effects, controls, costs, times and proc impressions stay reports. Defender is the
author's label, not a Guardian rename. Preserve class-paragraph qualified no-bonus-mana impression
and same-guide weapon-section mana-on-block accounts without selecting either as a rule. F1's
13% per-hit Fury, D11/D23 successful-block MP and approved 5-metre/3-second taunt plus
50%-max-HP-over-10-seconds healing stand; consumer/config inspected, not original-build proof.
No healing, mana, blocking, cost, duration, resistance or source-label change; no live JSON,
gameplay, checker/test changes or new implementation debt.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1038-1040,1064`,
**Choose your Character! [Warriors]** and **Warrior Weapon Analysis**; raw SHA-256 freshly matches
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars, title/author (610–611/825) and displayed dates (846–847) checked
separately: Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated
**3 Oct, 2019 @ 10:14am**, timezone unspecified; title **updated 4/10** distinct. Retained
HTTP 200, capture **2026-10-04T21:01:17Z**; item 70 limits apply. No immutable revision,
original-build/Alpha proof or release/introduction dating. Parser text is derivative, not
byte-equal raw; no external retrieval or embedded video inspection.
**Checks/evidence:** installed `/simplify` then ponytail-review and fresh `git diff --check` /
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` results retained in managed
run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g0-i2-evidence/`, with source/scope checks,
full-index diff and queue/Git snapshots. Independent reviewer origin
`b9d32d15-32b2-4c84-8a0b-25585d95645e` approved with no findings; exact forwarded native payload
matched its real saved structured JSON. Original output, acceptance report, status and delivery
receipt copied into DISTINCT managed `receipts/r0-g0-i2-evidence/`; original/bound files untouched.
Writer origin `ee59e4bd-07b6-4ae4-81ca-ab4a9c2b5f84` likewise verified/copied. Actual reviewed diff
SHA-256 `7a83bb6b115affe2e3dbe610d596424088c09642b752a89bcf704cf3ea5007ac` matched both reports.
Finalizer fresh raw/source/queue/Git/index/full-diff inspection, installed simplify then ponytail-review,
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed;
canonical hash/parent/paths/content and sibling preservation verified. Fresh maintenance gates and
commit verification retained there separately. Validator proves loaded-data checks only, not prose
truth or runtime compliance. No gameplay tests added/run, push or exhaustion claim. Context
percentage unavailable.

### Validation-contract source attribution — candidate-darkmega-ranger-abilities / item 95 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, new ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's Sniper/Scout ability descriptions.

**Original scout proposal (verbatim):** New scout selection: attribute Darkmega's Sniper/Scout ability descriptions, retaining approximate trap/clone observations.

**Previously selected precision option (task inventory verbatim):** Named qualified community corroboration; approximate trap/clone timings and speculative aggro remain report-only.

**Original scout precision detail (verbatim; same narrow selection):** Named community descriptions of stealth, attack-speed ramp, retreat, shadow clone, sprint/flip, kick, quicksand and instant-charge particles; approximate timings and author's aggro speculation remain report-only.

**Approval versus Refusing:** approval improves bounded attribution; refusal declines only
that refinement, not an opposite mechanic. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 95` / §7 after local
raw inspection and duplicate-screening items 1–94. Generic definitions/research G2 citations,
items 53/57–59 and item 70 do not already attribute this Ranger passage. Independent source/scope
review approved with no findings (origin `08e0490e-207f-4c23-954b-8860bfbcc810`); supplied native
payload inspected directly and real saved structured JSON verified/copied distinctly with original
delivery provenance, not an empty-bound-file wait or review waiver. Canonical commit
`2ce579e699e4260ddfa9742d339ffe36de71cf69`, parent
`29bc586fa85f1c0aa558415ce486651c965ca088`, hash/paths/full content verified against reviewed diff.
Paths: `ontology/domain.md`, `ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md`.
Only this handled selection removed after verified review/checks/commit; twelve siblings remain
unchanged/pending. Exact selected wording above retained with no amendment.
**Dependencies/boundary:** item 70 provenance; items 53/57–59 range/input/cooldown limits;
settled targeting/full-stealth/taunt and F1/D21 inspected with ability declarations and actual
runtime consumer. All source effects, controls, costs, approximate times and proc impressions
are reports, not defaults. No first-hit priority, knockdown redirection, clone targeting, trap
defense formula/timer or new cooldown; around-20-second clone does not replace F1/D21's 30 seconds.
No source-label, live JSON, gameplay, checker/test change or new implementation debt.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1030-1032`,
**Choose your Character! [Rangers]**; raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611` freshly verified.
URL/status/capture sidecars, title/author (610–611/825) and displayed dates (846–847) checked separately:
Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**,
timezone unspecified; title **updated 4/10** distinct. Retained HTTP 200, capture
**2026-10-04T21:01:17Z**; item 70 limits apply. No immutable revision, original-build/Alpha proof
or release/introduction dating. Parser text is derivative, not byte-equal raw; no external retrieval
or embedded video inspection. The Scout paragraph's proc wording calls it “the Ranger”; retained
without inventing a rate or broadening it to all Rangers.
**Checks/evidence:** installed `/simplify` then ponytail-review and fresh `git diff --check` /
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` results retained in managed
run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `items/r0-g0-i1-evidence/`, with raw checks,
duplicate/scope review, full-index diff and queue/Git snapshots. Finalizer fresh raw identity/date/
capture and actual branch/HEAD/index/full-diff/queue checks passed; full-index diff SHA-256
`42067020de3da6aa0d20e1a72950af4ea9a6905bfc37a4eae3d65ae174b0934d` matches writer and independent
review. Installed `/simplify` then ponytail-review reapplied; fresh `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0. Canonical commit
hash/parent/paths/full content verified before queue removal. Distinct exact original native
writer/review JSON, origin IDs, SHA-256 delivery receipts, full diffs, queue snapshots, commit and
fresh logs: managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `receipts/r0-g0-i1-evidence/`.
Writer origin: `e74f1396-c29f-4849-a215-ab2fe7c48f0d`; reviewer origin above. Original saved structured
JSON used directly; zero-byte bound files not awaited or overwritten. Validator checks loaded
data only, not prose truth or runtime compliance. Not pushed; context percentage unavailable;
twelve queued selections remain, no broader source-exhaustion claim.

### Validation-contract source attribution — candidate-darkmega-rogue-abilities / item 94 (2026-10-10)

**Selection:** Previously selected, auto-approved under the exact standing directive in the
pending queue; no individual owner answer, new ballot or amendment. Exact saved wording:

**Original proposal (task inventory verbatim):** New scout selection: attribute Darkmega's Assassin/Ninja ability descriptions and uncertain interruption/aggro observations.

**Original scout proposal (verbatim):** New scout selection, not a historical ballot: attribute Darkmega's Assassin/Ninja ability descriptions and separate uncertain interruption/aggro observations.

**Previously selected precision option (task inventory verbatim):** Named qualified Steam community corroboration; uncertain observations remain uncertain, numeric values report-only.

**Original scout precision detail (verbatim; same narrow selection):** Named Steam community corroboration of stealth, intercept, camouflage, poison vial, sprint/flip, shurikens and Ninjutsu; preserve may-or-may-not and unsure qualifications. Source values are reports, not hybrid defaults.

**Approval versus Refusing:** approval improves bounded attribution; refusal declines only
that refinement, not an opposite mechanic. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 94` / §7 after local
raw inspection and duplicate-screening items 1–93. Generic definitions/research G2 citations,
items 57–59 and item 70 do not already attribute this Rogue passage. Independent source/scope
review approved with no findings (origin `12f314ea-d014-4330-9a1d-47a9bbf39d55`); supplied native
payload inspected directly and original saved structured JSON verified/copied distinctly, not
an empty-bound-file wait or review waiver. Canonical commit
`0c7bf74d8348ec13d022940b2472230fb0142eba`, parent
`d842d556555a3c133df6f1289d1b10ce30feba2d`, hash/paths/full content verified against reviewed diff.
Paths: `ontology/domain.md`, `ontology/README.md`, `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md`.
Only this handled selection removed after verified review/checks/commit; thirteen siblings remain
unchanged/pending. Exact selected wording above is retained with no amendment.
**Dependencies/boundary:** item 70 provenance, items 57–59 control/cooldown limits, Assassin
item 1, settled full-stealth threat/resource/tree/runtime rules inspected with actual consumers.
No threat wipe, interruption proc, new costs/times/controls or tree rules; all source numbers
report-only. No source-label, live JSON, gameplay, checker/test change or new implementation debt.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1022-1024`,
**Choose your Character! [Rogue]**; raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611` freshly verified.
URL/status/capture sidecars, title/author (610/825) and displayed dates (846–847) checked separately:
Darkmega, guide 1871398574; Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019 @ 10:14am**,
timezone unspecified; title **updated 4/10** distinct. Retained HTTP 200, capture
**2026-10-04T21:01:17Z**; item 70 limits apply. No immutable revision, original-build/Alpha proof
or release/introduction dating. Parser text is derivative, not byte-equal raw; no external retrieval.
**Checks/evidence:** installed `/simplify` then ponytail-review, fresh whitespace/bounded validator
results retained in managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`,
`items/r0-g0-i0-evidence/`, alongside Git/queue snapshots, raw checks, duplicate screen and full-index
diff. Finalizer fresh raw hash/identity/dates/capture, actual branch/HEAD/index/full diff and
queue checks passed. Installed `/simplify` then ponytail-review reapplied; fresh `git diff --check`
and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0. Commit
hash/parent/paths/content verified before queue removal. Distinct exact original writer/review
JSON, origin run IDs, SHA256 delivery receipts, full diffs, queue snapshots and fresh logs:
managed run `71edbb08-9210-4b6b-ad27-5eda9476b261`, `receipts/r0-g0-i0-evidence/`.
Writer origin: `95d936e5-6608-4071-894c-74cb6d194772`; reviewer origin above. Initial short-index
comparison differed only in hash display width; full-index comparison byte-matched reviewed diff.
Validator checks loaded data only, not prose truth or runtime compliance. Not pushed; context
percentage unavailable; thirteen queued selections remain, no broader source-exhaustion claim.

### Validation-contract source attribution — candidate-darkmega-world-boss-attribution / item 93 (2026-10-10)

**Selection:** AUTO-APPROVED under the exact standing directive retained below from the deleted
pending queue; no invented per-item owner answer/amendment. Supplied inventory proposal / selected option (verbatim):

> New selection: attribute larger colored/named world bosses, random special moves and qualified higher-tier loot observations.

> Named qualitative corroboration retaining usually/equivalent-at-gold; historical respawn report cannot overturn reset rules.

**Approval versus Refusing:** approval permits this bounded attribution; refusal rejects only
that refinement, not its opposite. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 93` / §7 after retained
raw inspection and duplicate-screening items 1–92. Item 4 already bounds explicit boss source
sections/checks; item 19 concerns Leftovers, item 28 named Golem/Troll traits and item 85 possession,
not this world-boss passage. Independent content review approved with no findings; empty bound
report recovered under supervisor authority, not a gate waiver. Finalizer fresh source/Git/index/
diff/queue and whitespace/bounded-validator gates passed; canonical item commit verified below.
Only this selected item removed; last entry handled and pending-only queue deleted.
**Dependencies/boundary:** boss/roster sourcing and world/reset approvals inspected; settled
reset eligibility, occupied-site deferral, surviving fights and permanent claims stand. No move
pool, tier odds, generation, loot count, loot or reset behavior change, source labels, live JSON,
gameplay/checker/tests or new implementation debt.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1096`, **Picking up
the pace → Those who bear their name**; raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611` verified locally.
URL/status/capture sidecars inspected. Identity separately checked at 610/825: Darkmega, guide
1871398574, item 70's exact title. Posted **25 Sep, 2019 @ 2:24am** / Updated **3 Oct, 2019
@ 10:14am** at 846–847, timezone unspecified; title **updated 4/10** remains distinct. Capture
**2026-10-04T21:01:17Z**, retained HTTP 200. No immutable revision, release/introduction dating
or original-build proof; item 70 limits apply. Parser excerpt is derivative, not byte-equal raw
HTML. Earlier failed assertions and documented derivative-only differences remain unchanged.
`research_creatures_quests.md §2.6` consolidates existing boss traits; this guide supplies named
qualified corroboration, not authentication of every wiki-derived trait or source edition.
No external retrieval or primary-developer proof.
**Checks:** installed `/simplify` reused item 70's shared provenance; ponytail-review retained
necessary qualifications and pending-review status without new scaffolding. Fresh `git diff --check`
exited 0; `timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0,
**ontology valid**. Validator checks loaded data, not prose truth or runtime compliance. No staged
files, commit or push; context percentage unavailable, no exhaustion claim. Managed run
`9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`, `items/b2-i5-evidence/` retains baseline Git/queue,
source inspection, duplicate screen, simplification/review and fresh check logs.
**Review recovery:** native reviewer `6346b314-e030-4d2c-be59-a2ab979a2fa1` saved complete
approved JSON at `/tmp/pi-subagents-uid-1000/async-subagent-runs/6346b314-e030-4d2c-be59-a2ab979a2fa1/structured-output/pi-subagent-structured-6Tyr2V/output.json`.
Original `reviews/b2-i5-0.json` remains empty; distinct byte-equal recovered JSON and provenance
are in managed `receipts/b2-i5-evidence/`. SHA-256
`133fd6f3e55980be28182d37b1b7b346a56c11918f306683fcd2198562289685` verified.
Reviewer approved source fidelity and settled-policy/queue boundaries with no findings; it did
not execute fresh live Git/index/full-diff or gates. Finalizer independently checked actual
expected branch/HEAD/upstream, complete diff, empty index and retained source/scope assertions.
**Verified canonical receipt:** `474ec28621be8e4527e98941e0bdf57ad02eafec`, parent
`9cd10d63bf6dca52d71cbcb678264918f846407f`, subject
`docs(ontology): attribute qualified world-boss source report`. Exact four canonical/status/ledger
Markdown paths and commit content/hash/parent verified before selection removal. Fresh finalizer
`git diff --check` exit 0; bounded ontology validator exit 0, **ontology valid**. Finalizer source
assertions verified exact quotations, raw identity/date/capture/hash, unchanged previous canonical
text, one remaining selection and empty index. Evidence: managed `receipts/b2-i5-evidence/`.
No gameplay, source/live-data/checker/test change, new debt or push. Validator proves loaded checks,
not prose truth/runtime compliance; context percentage unavailable; no exhaustion claim.

**Retained exact authority (from deleted pending queue):**

> For each item which implies approving/refusing to increase source-precision, auto-approve it in a subagent. Do not perform any other action than handing off yourself. Only orchestrate and handoff. To review, also use subagents. Stop only when no source-precision item remain, regardless of limitation of the skill. Ensure using low context only by delegating tasks to subagents.

> The latest owner instruction authorizes automatic APPROVAL of increased source precision, including its documentation recording, without asking again. This does NOT approve new gameplay/balance/product decisions or behavior changes.

**Dependencies (supplied task inventory verbatim):** Duplicate-screen boss/roster sourcing and world-reset approvals.
**Documentation/implementation boundary (supplied task inventory verbatim):** Documentation only; no move pools, tier odds, generation, loot or reset behavior.
**Evidence (inventory locators):** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1096`;
`ontology/research/research_creatures_quests.md:248`.

**Retained detailed original inventory (verbatim fields; same approved selection):**
- Original proposal: New scout selection: attribute Darkmega's larger/colored/named world-boss report and qualitative random special-move and higher-tier-loot observations.
- Previously selected precision option: Named qualitative community corroboration of existing boss description; retain usually and equivalent-at-gold qualification. Respawn statement is historical attribution, not authority to change approved reset/occupied-site rules.
- Evidence: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1096`; `ontology/research/research_creatures_quests.md:248`; `ontology/domain.md:1868,1892`
- Dependencies: Duplicate-screen boss/roster items 1–87 and world-reset decisions before selecting exact excerpt.
- Documentation/implementation boundary: Documentation only; no move pool, tier odds, loot count, boss generation, reset or gameplay authorization.

**Non-selection research retained after last-entry queue deletion:** exact boundaries moved to
`docs/HANDOFF.md` current entry: Silk/Spinning Wheel quantities HOLD; Swamp-lands/Lion/resistance/
gear-HP design unanswered; food chronology/daily quantities/original sleep units evidence gaps;
runtime deferrals not ballots, regional loss prohibited, item 39 never implemented. Remaining
retained-guide class/weapon/lore/arena/material passages require fresh scoped duplicate-screening;
inventory positive, not exhaustive. No remaining selected entry is not proof of source exhaustion.

### Validation-contract source attribution — candidate-environment-drinks-attribution / item 92 (2026-10-10)

**Selection:** AUTO-APPROVED under the exact standing directive retained in the pending queue;
no invented per-item answer/amendment. Supplied inventory proposal / selected option (verbatim):

> New selection: attribute Darkmega's lemonade/lava and hot-chocolate/cold-water reports; classify green-smoothie protection as untested speculation.

> Qualified community attribution; retain author's never-entered-dark-forest disclaimer.

**Approval versus Refusing:** approval permits this bounded attribution; refusal rejects only
that refinement, not its opposite. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 92` / §7 after retained
raw inspection and duplicate-screening items 1–91, including food/conversion records and item 77's
separate food/potion-use report. Independent content review approved with no findings;
finalizer source/Git/index/diff/queue and fresh gates passed. Canonical commit
`35e833b69bc073f32421409d16e5ba6d74834037` content/hash/parent and exact five-document diff
verified against parent `974d0448c59a9809b3c33544437690c2b465a24e`. Only this verified item
removed; world-boss sibling unchanged/pending. No immunity, duration, recipe, availability,
biome-damage or ingredient-location inference; existing rules stand, no new implementation debt.
**Source:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1136`; raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars inspected locally. Identity separately checked at 610/825:
Darkmega, guide 1871398574, item 70's exact title. Posted **25 Sep, 2019 @ 2:24am** /
Updated **3 Oct, 2019 @ 10:14am** at 846–847, timezone unspecified; title **updated 4/10**
remains distinct. Capture **2026-10-04T21:01:17Z**, retained HTTP 200. No immutable revision,
release/introduction dating or original-build proof; item 70 limits apply. Parser text is a
derivative, not byte-equal HTML; earlier failed assertions and derivative-only differences remain
unchanged. `research_items.md §3.6` and existing consumable/status records retain the beverage
relationships; this guide does not independently verify Green Smoothie protection. No external
retrieval or primary-developer proof. Managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b2-i4-evidence/` retains baseline Git/queue, source inspection, duplicate screen and writer
review/check logs. Installed `/simplify` kept the scoped record and shared item 70 provenance;
ponytail-review removed a redundant queue instruction. Fresh `git diff --check` exited 0;
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0, **ontology valid**.
Validator checks loaded data, not prose truth or runtime compliance. No staged files, commit or
push in this recording step; context percentage unavailable.
**Independent review / finalizer verification:** substantive file-only review approved item 92,
with no findings, preserving settled consumable rules and the world-boss pending block. The bound
`reviews/b2-i4-0.json` is empty and remains unchanged; supervisor explicitly authorized recovery,
not a waiver. Complete saved reviewer JSON recovered byte-for-byte to distinct
`receipts/b2-i4-evidence/recovered-review.json` (SHA-256
`9e9d09a398684fc14c23d6f81f7d301d1638e3d7ce91c49573378eaa952188d7`, 3234 bytes),
with path/authority provenance retained beside it. Reviewer inspected sources/docs but did not
rerun Git/hash/gates. Finalizer independently verified actual branch/HEAD/upstream, five-document
scope, empty index, raw-source hash/quotations/provenance, additive canonical semantics and
unchanged sibling. Fresh whitespace and bounded-validator gates passed, **ontology valid**;
validator does not prove prose truth or runtime compliance. Canonical commit verified before
queue removal; receipt-state whitespace/bounded-validator gates also passed. No push.
Managed finalizer logs: `receipts/b2-i4-evidence/`.
**Dependencies/boundary:** exact consumable/status records and duplicate food/conversion screen
completed for this attribution only. Exact original selection/dependencies/boundary and detailed
inventory retained below from the verified queue entry; no separate answer/amendment or sibling
application. Standing authority remains in the pending queue and item 88's completed ledger.

**Original proposal (supplied task inventory verbatim):** New selection: attribute Darkmega's lemonade/lava and hot-chocolate/cold-water reports; classify green-smoothie protection as untested speculation.

**Previously selected precision option (supplied task inventory verbatim):** Qualified community attribution; retain author's never-entered-dark-forest disclaimer.

**Dependencies (supplied task inventory verbatim):** Read exact consumable/status records and duplicate-screen food items 1–87.
**Documentation/implementation boundary (supplied task inventory verbatim):** Documentation only; no immunity/duration/recipe/availability or ingredient-location inference.

**Retained detailed original inventory (verbatim fields; same approved selection):**
- Original proposal: New scout selection: attribute Darkmega's lemonade/lava and hot-chocolate/cold-water reports while explicitly classifying green-smoothie/dark-forest protection as untested speculation.
- Previously selected precision option: Named qualified community attribution for existing environmental-consumable relationships; preserve 'I've never actually gone into one yet' for green smoothie.
- Evidence: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1136`; `ontology/domain.md:1683`; `ontology/research/research_items.md`
- Dependencies: Read exact existing consumable/status descriptions and duplicate-screen food/conversion items 1–87.
- Documentation/implementation boundary: Documentation only; no immunity, duration, recipes, availability, biome damage or ingredient-location inference.

### Validation-contract source attribution — candidate-treasure-spirit-attribution / item 91 (2026-10-10)

**Selection:** AUTO-APPROVED under the exact standing owner directive retained in item 88;
no invented per-item answer/amendment. Supplied inventory proposal / selected option (verbatim):

> New selection: attribute Darkmega's nearby hovering treasure compass report.

> Qualitative direction/hidden-gold/equipment corroboration; no exact range or universal absence of NPC hints.

**Approval versus Refusing:** approval permits this bounded attribution; refusal rejects only
that refinement, not its opposite. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 91` / §7 after retained
raw inspection and duplicate-screening items 1–90, especially 21/82's bounded hint descriptions
and 88's separate bird-lift passage. Independent content review approved with no findings;
finalizer source/Git/index/diff/queue and fresh gates passed, canonical item commit verified.
Only this verified item removed; two sibling selections unchanged/pending. Global key-item policy
stands. No numeric range, spawn, hint exclusion, loot-adaptation or class-selection rule is selected;
no new implementation debt or push.
**Source:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`; raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars inspected locally. Identity separately checked at 610/825:
Darkmega, guide 1871398574, item 70's exact title. Posted **25 Sep, 2019 @ 2:24am** /
Updated **3 Oct, 2019 @ 10:14am** at 846–847, timezone unspecified; title **updated 4/10**
remains distinct. Capture **2026-10-04T21:01:17Z**, retained HTTP 200. No immutable revision,
release/introduction dating or original-build proof; item 70 limits apply. Parser text is a
derivative, not byte-equal HTML; earlier failed assertions and derivative-only differences remain
unchanged. `research_items.md:363,414` and the existing key-item/POI summaries corroborate the
bounded relationship, not independent raw proof. No external retrieval or primary-developer proof.
**Dependencies (supplied inventory verbatim):** Verify key-item historical record; duplicate-screen items 1–87.
**Boundary (supplied inventory verbatim):** Documentation only; no spawn/range/loot-adaptation policy.
**Retained detailed original inventory (verbatim fields; same approved selection):**
- Original proposal: New scout selection: attribute Darkmega's nearby hovering compass/direction report for Treasure Spirit pointing to hidden gold/equipment.
- Previously selected precision option: Named qualitative community corroboration; decent distance is not a numeric range, and author's failure to hear an NPC hint is not proof hints never exist.
- Evidence: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`; `ontology/research/research_items.md:363,414`; `ontology/domain.md:1278-1285`
- Dependencies: Verify existing key-items treasure-spirit historical record and duplicate-screen items 1–87.
- Documentation/implementation boundary: Documentation only; no range, spawn, hint exclusion, loot adaptation or class-selection policy.
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b2-i3-evidence/`: baseline Git/queue, retained source inspection, duplicate screen and
fresh check logs. Initial helpers failed on casing/heading assumptions; failures retained and
corrected inspection uses exact raw wording/current heading shapes, not normalization of source.
Installed `/simplify` removed a redundant queue instruction; ponytail-review: **Lean already. Ship.**
Fresh source/quotation/additive-scope and sibling-queue assertions passed. `git diff --check`
exited 0; `timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0,
**ontology valid**. Writer left no staged files, commit or push.
**Independent review / recovery:** reviewer `d4a62151-e919-4a8a-9d07-a91dce4c9f3c` approved
item 91 with no findings, confirming source fidelity, distance/hints qualifications and preserved
key-item/NPC policies and siblings. Bound `reviews/b2-i3-0.json` was empty; actual complete structured
report recovered under supervisor authority into distinct `receipts/b2-i3-evidence/recovered-review.json`
(managed run above), SHA-256 `5beecc1a2a4edd8344587bd3564d66a3a8190edc29a13e54a235e3f6b459ad2b`.
Original empty report/receipt unchanged; artifact failure is not a gate waiver. Reviewer inspected
writer gate logs, not fresh reviewer commands.
**Finalizer verification / receipt:** actual source/Git/index/diff/queue rechecked; fresh
`git diff --check` exited 0 and bounded ontology validator exited 0, **ontology valid**, on
reviewed canonical state and again on receipt/queue state. Managed `receipts/b2-i3-evidence/`
retains source/scope assertions, final diffs and fresh logs. Recovery helper's literal-name
assumption failed before mutation; failure retained, corrected check verifies actual complete review.
Canonical commit `bf571576db0940d583ab50ca8b2368ea075b6fc4` (parent
`5cb0b230897120fc0e9ff9e828e2d8f8b22af2bc`) content/hash/parent and exact five-document scope
verified against final diff; post-item worktree/index clean. Exact selected proposal/option,
detailed inventory, dependencies and boundary above retained unchanged. Only this verified item
removed from pending queue; two sibling selection blocks byte-unchanged. Receipt/queue maintenance
committed separately after fresh gates. No gameplay/live-data/checker/tests or push.
Validator checks loaded data, not prose truth or runtime compliance. Context percentage unavailable;
no whole-topic or exhaustion claim.

### Validation-contract source attribution — candidate-spirit-bell-attribution / item 90 (2026-10-10)

**Selection:** AUTO-APPROVED under the exact standing owner directive retained in item 88;
no invented per-item answer/amendment. Supplied inventory proposal / selected option (verbatim):

> New selection: attribute Darkmega's portcullis/spirit-realm, duration and atmosphere reports.

> Source says around 45 seconds, not settled F8 30 seconds; retain night-visibility hearsay qualification.

**Approval versus Refusing:** approval permits this bounded attribution; refusal rejects only
that refinement, not its opposite. Neither changes the approved player experience.
**Application:** HANDLED — documentation recorded in `ontology/domain.md §5 item 90` / §7 after
retained raw inspection and duplicate-screening items 1–89, including item 7 audio limits and prior
UI/control attributions. Independent review confirms source fidelity and preservation of F8;
no findings. Finalizer fresh gates and canonical commit verified; only this item removed.
F8 / `c-gate-doors` 30 seconds and global key-item policy stand. Atmosphere/manual-use reports
select no controls, realm, duration or audiovisual behavior; no new debt or push.
**Source:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`; raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
URL/status/capture sidecars inspected locally. Identity separately checked at 610/825:
Darkmega, guide 1871398574, item 70's exact title. Posted **25 Sep, 2019 @ 2:24am** /
Updated **3 Oct, 2019 @ 10:14am** at 846–847, timezone unspecified; title **updated 4/10**
remains distinct. Capture **2026-10-04T21:01:17Z**, retained HTTP 200. No immutable revision,
release/introduction dating or original-build proof; item 70 limits apply. Parser text is a
derivative, not byte-equal HTML; earlier failed assertions and derivative-only differences
remain unchanged. Existing `research_systems.md:110` aggregate and
`research_creatures_quests.md:346,372` comparison are not independent raw proof.
No external retrieval, assets, primary-developer proof or Alpha equivalence.
**Dependencies (supplied inventory verbatim):** Screen prior UI/audio/control attribution; preserve settled F8.
**Boundary (supplied inventory verbatim):** Documentation only; no duration, realm, audio/visual or manual-use implementation.
**Retained detailed original inventory (verbatim fields; same approved selection):**
- Original proposal: New scout selection: attribute Darkmega's metal-portcullis/transparent spirit-realm passage, including qualified duration and atmosphere observations.
- Previously selected precision option: Named source reports around 45 seconds; explicitly distinguish this community observation from settled F8 30 seconds. Spooky music/fog/color observations are report-only; night visibility is heard mention, not demonstrated.
- Evidence: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`; `ontology/research/research_systems.md:110`; `ontology/domain.md:3890-3915`
- Dependencies: Duplicate-screen prior controls/UI/audio sourcing; preserve F8 without reapproval.
- Documentation/implementation boundary: Documentation only; no duration, realm, visual/audio or manual-use implementation.
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b2-i2-evidence/`: baseline Git/queue, raw identity/date/content checks, duplicate screen,
minimality pass and fresh whitespace/bounded-validator logs. Initial helper incorrectly expected
literal “spooky music” / “I have heard mention”; failure preserved, exact wording checked separately,
not a source mismatch. Final raw identity/date/content, additive-only canonical scope, F8 and
sibling-queue fidelity checks passed. `/simplify` removed a redundant queue receipt locator;
ponytail-review: **Lean already. Ship.** Fresh `git diff --check` exited 0;
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0, **ontology valid**.
No staged files, commits or push. Validator checks loaded data, not prose truth/runtime compliance.
Context percentage unavailable; no whole-topic or exhaustion claim.
**Independent review / current recovery (2026-10-10):** genuine complete native review from
reviewer run `b761a2f2-6c98-4689-9e09-ee99842467ee` is approved, no issues/blockers; it inspected
raw attribution/identity/dates, F8, overlap, actual files and writer receipts (not independently
rerun checks). Original native path:
`/tmp/pi-subagents-uid-1000/async-subagent-runs/b761a2f2-6c98-4689-9e09-ee99842467ee/structured-output/pi-subagent-structured-hiZode/output.json`.
Maintenance recovered its exact **2796 bytes** at **2026-10-10T19:37:33Z**, SHA-256
`824dcdd347ee3ae3dd03f823effb1bbe5226206f4999733399abb1b2ba3de17c`, expected pre-canonical
parent `cbed31ee6a02739da3d1dfac413733a848c622c4`, distinctly into managed run
`8c4cf499-adc2-4361-acad-29dcce40dc80`,
`handoff/record-evidence/item90/independent-native-original.json`. Digest/parent/status and
original delivery were freshly verified; provenance/time and preserved originals are in that
directory's `recovery-provenance.json`. Complete prior independent audit
`71edbb08-9210-4b6b-ad27-5eda9476b261/final/scope-review.json` inspected this substantive native
review and independently verified current source/committed content, finding no current defect.
**Original delivery/gate limitation:** original `reviews/b2-i2-0.json` is only the **191-byte
announcement**, not that full review. Finalizer `7353fc71-abca-4450-a68b-329cfbb5ddf2` received
only that prose in its task and read it at **2026-10-10T13:42:06.159Z**; its historical native
receipt's full-review implication was unsupported. Announcement and original finalizer receipt
`receipts/b2-i2.json` remain unchanged and are copied distinctly beside the recovered review,
with original delivery/session excerpts. Current recovery/independent verification does not mean
the original finalizer checked the complete native payload; no retroactive gate claim, waiver or
history rewrite. Its historical source/Git/check execution remains separate from review delivery.
**Finalizer receipt:** canonical item commit `db9f36698599351fa5eb500ea73127b712b08b09`, parent
`cbed31ee6a02739da3d1dfac413733a848c622c4`, exact four canonical/status documentation files
and content/hash verified. Retained raw identity/dates/passage and source checksum independently
rechecked; all pre-existing canonical content and three sibling queue blocks preserved. Fresh
`git diff --check` and bounded ontology validator exited 0 before canonical commit and again on
receipt/queue final state; **ontology valid**. Only verified `candidate-spirit-bell-attribution`
removed; three siblings remain pending. Exact selected options/amendments and canonical pointer
retained above. Receipt/queue maintenance committed separately, no staged files or push.
Evidence: same managed run, `receipts/b2-i2-evidence/` (source/scope, exact diffs, commit verification,
queue fidelity and actual fresh gate logs). Validator checks loaded data, not prose truth/runtime
compliance. Context percentage unavailable; no whole-topic or source-precision exhaustion claim.

### Validation-contract source attribution — candidate-divine-harp-attribution / item 89 (2026-10-10)

**Selection:** AUTO-APPROVED under the exact standing owner directive retained in this ledger's
item 88 below; no invented per-item answer/amendment.
Original proposal / selected option (supplied inventory verbatim):

> New selection: attribute Darkmega's Divine harp golden-door/loot-tower approach/prompt/tune report.

> Qualitative named community corroboration, not layout or audiovisual proof.

**Approval versus Refusing:** approval permits this bounded attribution; refusal would reject
only the refinement, not approve its opposite. Neither changes the approved player experience.
**Application:** documentation recorded in `ontology/domain.md §5 item 89` / §7 after inspecting
retained raw passage and duplicate-screening items 1–88 (including §3.4 pet-food paragraphs).
Global key-item and midnight re-closing policies stand. “Usually” is not a layout guarantee;
approach/prompt/tune and adjacent appearance wording are community reports, not shipped
controls, audio or geometry proof. No acquisition, placement, door/reset/control behavior or new
implementation debt. Independent content review approved with no findings; finalizer fresh
gates and canonical commit verified, only this item removed and four siblings unchanged/pending.
No push, gameplay/live-data/checker/test or source-label changes.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`; URL/status/
capture sidecars inspected locally. Raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
Identity separately checked: guide 1871398574, title/author at 610/825. Posted **25 Sep, 2019
@ 2:24am**, Updated **3 Oct, 2019 @ 10:14am**, timezone unspecified, checked at 846–847;
title **updated 4/10** remains distinct. Capture **2026-10-04T21:01:17Z**, retained HTTP 200.
No immutable revision or release/introduction dating; item 70's limits apply. Parser inspection
text is a derivative, not byte-equal raw HTML; earlier failures and documented derivative-only
differences remain unchanged. No external retrieval, assets, primary-developer/original-build
proof or Alpha equivalence. `research_systems.md:110` is an existing aggregate report, not
independent raw proof.
**Dependencies (supplied inventory verbatim):** Verify provenance and duplicate-screen items 1–87.
**Boundary (supplied inventory verbatim):** Documentation only; no door/reset/control behavior.
**Retained detailed original inventory (verbatim fields; same approved selection):**
- Original proposal: New scout selection: attribute Darkmega's Divine harp golden-door/loot-tower passage and approach/prompt/tune description.
- Previously selected precision option: Named qualitative community corroboration, not guaranteed dungeon layout or shipped audiovisual proof.
- Evidence: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`; `ontology/research/research_systems.md:110`; `ontology/domain.md:1278-1290`
- Dependencies: Verify source provenance and duplicate-screen items 1–87.
- Documentation/implementation boundary: Documentation only; no new controls, door reset, placement, acquisition or behavior.
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`, `items/b2-i1-evidence/`:
baseline Git/queue, raw identity/date/content assertions, duplicate screen, preserved two failed
heading-extraction helpers (not source mismatches), minimality review and fresh whitespace/bounded
validator logs. Final source/scope/queue assertions passed; `git diff --check` exited 0 and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0, **ontology valid**.
No staged files. Validator checks loaded data, not prose truth/runtime compliance. Context
percentage unavailable; no whole-topic completion or source-precision exhaustion claim.
**Independent review/report recovery:** reviewer `9f36db20-045d-4661-9a63-0f0897db699a`
approved exact source/qualifiers, canonical policies and four unchanged siblings with no findings.
Original `reviews/b2-i1-0.json` and writer `items/b2-i1-record.json` remain zero bytes. Supervisor
authorized recovery of the actual complete saved reports into distinct
`receipts/b2-i1-evidence/recovered-review.json` / `recovered-writer.json`; byte equality and hashes
verified in `recovery-provenance.json`. Review SHA-256
`1b0c57e19984658e734ede7070495cb753817cac85384bbe7a08a1fafd95d010`;
writer SHA-256 `bb2f666c6b4900f85179264c83fb53a5811b3b4b938ea23cd5366b33c9bacc10`.
Delivery failures are preserved, not a gate waiver. Reviewer inspected files/source/writer logs,
not fresh execution gates. Finalizer independently rechecked actual source/Git/index/diff/queue;
one overstrict recovery-helper display-name assertion failed before copying, then scope/locator
checks passed (`recovery-helper-failure.log`). No source mismatch or external retrieval.
**Finalizer receipt:** canonical commit `b24b2e65bee3cc44b19588a75a9ce74f2337804e`, parent
`8df7674565aa9f533b8112b1d93f7c5e4e9b805a`, exact four reviewed canonical/docs files only;
content/hash/parent and empty index verified before removing this item. Canonical pointer:
`ontology/domain.md §5 item 89` / §7. Exact original proposals/options/dependencies/boundaries
and no invented per-item amendments are retained above; standing directive is retained in item 88.
Fresh finalizer `git diff --check` exited 0; bounded
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0, **ontology valid**.
Actual source/Git/diff/index/queue assertions passed. Managed evidence: `receipts/b2-i1-evidence/`
in the run above (`canonical.diff`, `canonical-source-scope-check.log`, `canonical-diff-check.log`,
`canonical-validation.log`, `canonical-commit.json`, recovered reports/provenance).
Separate receipt/queue maintenance removes ONLY `candidate-divine-harp-attribution` after verified
recording/review/gates/commit; four sibling selections and remaining research preserved.
Simplify reused this ledger's retained standing directive; ponytail-review: **Lean already. Ship.**
No gameplay/live-data/checker/test changes, new debt, external retrieval or push. Validator checks
loaded data, not prose truth/runtime compliance. Context percentage unavailable; no topic exhaustion.

### Validation-contract source attribution — candidate-sky-flute-attribution / item 88 (2026-10-10)

**Selection:** AUTO-APPROVED under the exact standing owner directive; no fabricated per-item
answer/amendment:

> For each item which implies approving/refusing to increase source-precision, auto-approve it in a subagent. Do not perform any other action than handing off yourself. Only orchestrate and handoff. To review, also use subagents. Stop only when no source-precision item remain, regardless of limitation of the skill. Ensure using low context only by delegating tasks to subagents.

Original proposal / selected option (supplied inventory verbatim):

> New selection: attribute Darkmega's Sky flute bird/pillar activation and blue-bird sky-island lift report.

> Named qualitative corroboration; preserve source name without renaming Sky Whistle.

**Approval versus Refusing:** approval permits named qualitative corroboration; refusal would
reject only that attribution, not approve its opposite. Neither changes the approved game.
**Application:** documentation recorded in `ontology/domain.md §5 item 88` / §7 after reading
retained raw passage and screening items 1–87. Item 78's shrine flute and item 72's pet whistle
do not cover this passage; the source's “bird” does not independently prove eagle identity.
No controls, acquisition, placement, audiovisual implementation, access/reset or treasure guarantee
is selected. Global key-item policy and settled choices stand; no new implementation debt.
Independent content review approved with no findings; empty bound report recovered separately
under supervisor authority, not a gate waiver. Fresh finalizer gates and canonical commit verified;
only this item removed, five siblings unchanged/pending. No push or gameplay/live-data/checker/test changes.
**Source:** retained public `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`, URL/status/
capture sidecars inspected locally; raw SHA-256
`316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611`.
Guide ID 1871398574, title and author at raw lines 610/825 checked separately from content;
Posted **25 Sep, 2019 @ 2:24am**, Updated **3 Oct, 2019 @ 10:14am**, timezone unspecified,
checked at 846–847. Title **updated 4/10** is distinct, not normalized to Updated.
Capture sidecar **2026-10-04T21:01:17Z**, retained HTTP 200; neither is immutable revision or
release/introduction evidence. Item 70's limits apply. Inspection text is a derivative, not
byte-equal raw HTML; earlier failed assertions and documented derivative-only differences remain
unchanged. No external retrieval, assets, original-build proof, Alpha equivalence or source-label change.
**Dependencies (supplied inventory verbatim):** Verify retained provenance; duplicate-screen items 1–87.
**Boundary (supplied inventory verbatim):** Documentation only; no controls, acquisition, visuals or access policy.
**Retained detailed original inventory (verbatim fields; same approved selection):**
- Original proposal: New scout selection (no historical unanswered ballot): attribute Darkmega's Sky flute report of bird/pillar structure activation and blue birds lifting the player to a sky island.
- Previously selected precision option: Named qualitative community corroboration of existing Sky Whistle access description; preserve source's Sky flute name, without silently renaming canonical identity.
- Evidence: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1120`; `ontology/research/research_world.md:133`; `ontology/research/research_systems.md:110`; `ontology/domain.md:1278-1290`
- Dependencies: Writer verifies retained public provenance and duplicate-screens completed items 1–87.
- Documentation/implementation boundary: Documentation only; no access control, acquisition, placement, visual/audio or global-policy change.
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`, `items/b2-i0-evidence/`:
baseline Git/queue, source assertions and duplicate screen, simplify/ponytail-review, diff and fresh
`git diff --check` / `timeout 150 nix develop -c godot --headless -s ontology/validate.gd` logs.
Fresh whitespace check passed; bounded validator exited 0, **ontology valid** (`validation.log`).
Source/scope assertions passed; five sibling entries unchanged and no staged files. Simplify kept
only required recording/provenance/status; ponytail-review: **Lean already. Ship.**
Validator checks loaded data, not prose truth/runtime compliance. Context percentage unavailable;
no whole-topic completion or exhaustion claim.
**Independent review recovery:** reviewer `a47a17e7-0680-43b7-a8b2-52e1878a0715` approved exact
quote/provenance, canonical identity/policy limits and unchanged siblings with no findings.
Original `reviews/b2-i0-0.json` remains zero bytes. Supervisor authorized recovery of the actual
complete saved JSON into distinct `receipts/b2-i0-evidence/review-recovered.json`; byte equality
and SHA-256 `ce0fbe1f34322d8f6bd6326953610f6df3abc2381b416980ab2d98fd28614d4e` verified.
Provenance: `recovery.log` there. Artifact-delivery failure is not rewritten; reviewer did not claim
fresh index/Git/check execution. Finalizer independently inspected actual source, Git/diff/index,
untracked queue and siblings.
**Finalizer receipt:** canonical commit `5bd6e15be2c786d95b48c6fef522915b99eb6d35`, parent
`d30e3ded0e853dd601d474159216fcd80394fb50`, exact four reviewed tracked docs only;
content/hash/parent and empty index verified before removing this item. Fresh `git diff --check`
passed; untracked queue no-index whitespace check had no diagnostics (raw exit 1 = new-file diff).
Fresh bounded `timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exited 0,
**ontology valid**. Logs/diff/Git/source/recovery and commit evidence: `receipts/b2-i0-evidence/`
in the managed run above. Simplify and ponytail-review: required quote/identity/limits retained;
no additional abstractions or behavior changes. Validator checks loaded data, not prose truth or
runtime compliance. No external retrieval or push; context percentage unavailable.
Only `candidate-sky-flute-attribution` removed after verification. Supervisor explicitly authorized
separate receipt/queue maintenance to add inherited untracked five-sibling PENDING metadata;
exact sibling proposals/options/dependencies/status preserved, not canonically applied. Remaining
research breadcrumbs preserved, not approvals. No whole-topic completion or exhaustion claim.

### Validation-contract source attribution — candidate-mana-pump / item 87 (2026-10-10)

**Selection:** auto-approved under the exact owner directive, not a fabricated numbered owner
answer:

> For each item which implies approving/refusing to increase source-precision, auto-approve it in a subagent. Do not perform any other action than handing off yourself. Only orchestrate and handoff. To review, also use subagents. Stop only when no source-precision item remain, regardless of limitation of the skill. Ensure using low context only by delegating tasks to subagents.

No per-item amendments. Original proposal / selected option (inventory verbatim):

> Retained source supporting existing mission/status fact (not an existing numbered ballot): Mana absorption slightly slows the rate at which you build mana from your attacks ... pumps are culprit. ... When all inducers are smashed the big officer ... will appear.

> Auto-approved separable precision: qualitative named guide attribution of absorption and inducer/officer/pump sequence, not exact reduction, stacking, guaranteed four-arm layout or numeric combat behavior.

**Approval versus Refusing:** approval adds qualitative absorption/sequence attribution only;
refusal would reject that attribution, not select mana or encounter parameters. Neither changes
the approved game.
**Application:** documentation recorded in `ontology/domain.md §5 item 87` / §7 after screening
items 1–86 and reading exact mission/status/POI records and the research summary; no prior separate
attribution of this passage. The guide's officer wording is not proof of the wiki-derived mech/
pilot identity, four-boss layout or individual loot. Settled choices and existing deferrals stand;
no gameplay/live-data/checker/test change or new debt. Independent review approved with no
findings; canonical commit verified and only `candidate-mana-pump` removed. Empty pending queue
deleted; no whole-topic completion or publication authority/push.
**Source:** retained public `guide.body:1128` / URL/status/capture sidecars inspected locally;
raw SHA-256 `316d6aa421167e6e71729d0c426e1fd6950947bf54ace1df844fc8d08ee75611` matches queue.
Title/author, displayed dates, capture and exact content checked separately; item 70's limits
apply: capture `2026-10-04T21:01:17Z`, title **updated 4/10** distinct from displayed Updated
**3 Oct, 2019 @ 10:14am** (timezone unspecified). No immutable revision, original-build proof,
external retrieval, Alpha equivalence or feature dating. HTMLParser inspection text is a
derivative, not byte-equal raw HTML; prior failed assertions and documented derivative-only
differences remain unchanged.
**Dependencies (inventory verbatim):** Worker must read exact canonical mission/status records and duplicate-screen before selecting final wording.
**Documentation/implementation boundary (inventory verbatim):** Documentation only; no mana formula, encounter sequencing implementation or layout rule.
**Original evidence locators:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1128`;
`ontology/domain.md:938,1500–1502`; `ontology/research/research_creatures_quests.md:255–270`
(inventory locators, not immutable line identities).
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b1-i6-evidence/`: baseline and preserved unrelated queue diff, source checks, simplify →
ponytail-review (Lean already. Ship.) and fresh whitespace/bounded-validator gates.
`git diff --check` passed; `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`
exited 0, `ontology valid` (`diff-check.log`, `validation.log`). Validator checks loaded data,
not prose truth/runtime compliance. No boot, gameplay, visual/network tests or external retrieval.
Context percentage unavailable; no whole-topic completion or exhaustion claim.

**Independent review / recovery:** reviewer `9a43987e-f17c-45b4-9808-e71645de85a8` approved
with no findings. Supervisor explicitly authorized recovery of its complete actual report, not a
gate waiver. Original bound `reviews/b1-i6-0.json` remains empty; original native status/terminal
receipts preserved beside distinct `receipts/b1-i6-evidence/recovered-review.json` under the
managed run above. Saved original:
`/tmp/pi-subagents-uid-1000/async-subagent-runs/9a43987e-f17c-45b4-9808-e71645de85a8/structured-output/pi-subagent-structured-o7ayUc/output.json`.
Byte-equivalent SHA-256: `38f888ce6ffc7f9271ba9a2e051e94942c2b7c77589b68488d093c9a0795a994`;
`recovery-provenance.json` retains scope/authority. Reviewer inspected files/raw evidence but ran
no commands, hashes or fresh gates. Finalizer independently verified source hash/sidecars/quotes,
actual Git/index, exact reviewed default-format diff and sole pending selection. Initial diff
comparison used full-index against writer's abbreviated-index diff and failed; matching-format
comparison passed with no substantive difference; original failure retained. No evidence re-fetch.
Finalizer simplify → ponytail-review kept required attribution/limits and recovery distinction.
Fresh canonical-state `git diff --check` and bounded ontology validator passed (exit 0,
`ontology valid`); `canonical-diff-check.log`, `canonical-validator.log`. Validator checks loaded
data, not prose truth or runtime compliance.

**Verified canonical commit:** `a212a74cfbe9c4961a4460d093da60bcc60b694f`, parent
`06e9f42def1433892dc37c7b7c0016d089ce55e8`; exactly four intended canonical/docs paths, no
queue/inherited edits included. Full-index binary draft, staged and committed diffs are byte-equal;
`canonical-{final,staged,committed}.diff`, `canonical-commit.log`, `canonical-verify.log`.
Exact original proposal/selected option, owner directive, no amendments, dependencies and boundary
above remain retained; canonical pointer: `ontology/domain.md §5 item 87` / §7. Only verified
mana-pump entry removed. No other pending selections or genuinely unrelated user changes exist in
the queue: captured inherited changes are authorized batch reaffirmation/dependency metadata, not
another pending decision. Preserve their unchanged snapshot/diff in managed evidence; delete the
empty pending-only queue per policy after verified item commit. Receipt/queue maintenance is a
separate commit; final-state fresh gate/scope/commit logs accompany this receipt. No gameplay/tests,
boot, visual/network checks or external retrieval; no push. Next: fresh all-topic source-precision
scan/review by distinct delegated workers, not a declaration of exhaustion. Context percentage
unavailable; no whole-topic completion claim.

### Validation-contract source attribution — candidate-petrified-village / item 86 (2026-10-10)

**Selection:** auto-approved under the exact owner directive retained in the pending queue,
not a fabricated numbered owner answer. Original proposal / selected option (inventory verbatim):

> Retained source supporting existing fact (not an existing numbered ballot): Sometimes you'll come across a town where all the people in it are turned to stone and you can't speak or interact with them ... a witch ... cancel the curse and bring everyone back to living again.

> Auto-approved separable precision: identify Darkmega as qualitative community corroboration of witch curse and restoration, not universal NPC service lock, witch placement guarantee or reset rule.

**Approval versus Refusing:** approval adds qualitative witch-curse/restoration corroboration
only; refusal would reject that attribution, not select a service or reset rule. Neither changes
the approved game.
**Application:** documentation recorded in `ontology/domain.md §5 item 86` / §7 after screening
items 1–85; no prior separate attribution of this passage. Item 85 concerns possession, not
petrification. World-shared resolved curses and existing resets stand. Independent content review
approved with no findings; canonical commit verified and only this queue entry removed.
Mana-pump unchanged/unapplied. No gameplay/live-data/checker/test change or new debt;
existing persistence deferral stands. No publication authority or push.
**Source:** retained public `guide.body:1128` / URL/status/capture sidecars inspected locally;
raw SHA-256 matches queue. Title/author/displayed dates and exact passage checked separately;
item 70's shared limits apply: capture `2026-10-04T21:01:17Z`, title **updated 4/10** distinct
from displayed Updated **3 Oct, 2019 @ 10:14am** (timezone unspecified). No immutable revision,
original-build proof, external retrieval, Alpha equivalence or feature dating. HTMLParser
inspection text is a derivative, not byte-equal raw HTML; prior failed assertions and documented
derivative-only differences remain unchanged.
**Dependencies (inventory verbatim):** Duplicate-screen prior attribution and preserve world-shared resolved curses.
**Documentation/implementation boundary (inventory verbatim):** Canonical documentation only; no curse/service or persistence behavior.
**Original evidence locators:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1128`;
`ontology/research/research_world.md:181`; `ontology/domain.md:256,1599,1688`
(inventory locators, not immutable line identities).
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b1-i5-evidence/`: baseline, source checks, simplify → ponytail-review and fresh
whitespace/bounded-validator gates. `git diff --check` passed; bounded ontology validation
exited 0, `ontology valid` (`diff-check.log`, `validation.log`). Validator checks loaded data,
not prose truth/runtime compliance. Context percentage unavailable; no whole-topic completion
or exhaustion claim.

**Independent review / artifact recovery:** reviewer `89f59327-e0e3-4e95-984b-cee4dc6f671c`
approved item 86 with no findings. Parent inspected the complete saved report and authorized
same-protocol recovery, not a review waiver. Original bound `reviews/b1-i5-0.json` remains empty;
original native status/terminal receipt preserved beside distinct recovery in managed run above,
`receipts/b1-i5-evidence/recovered-review.json`. Saved original:
`/tmp/pi-subagents-uid-1000/async-subagent-runs/89f59327-e0e3-4e95-984b-cee4dc6f671c/structured-output/pi-subagent-structured-qksXoG/output.json`.
Byte-equivalent SHA-256: `202a5ce84776c2f394412415f6e5f1eeb00a1fba18accc348670c493bf5e048c`;
provenance retained in `recovery-provenance.json`. Reviewer inspected current docs/raw quotations,
identity/sidecars, dependencies and sibling selection; did not freshly execute Git/index/hash/gates.
Finalizer independently verified actual branch/HEAD/upstream, reviewed docs-only diff/no staging,
source hash/identity/date/qualified quotes and sibling preservation. Retained local evidence only;
validator checks loaded data, not prose truth/runtime compliance. No push.

**Finalizer gates / canonical receipt:** fresh `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (exit 0,
`ontology valid`); logs `canonical-diff-check.log` / `canonical-validation.log` in managed
`receipts/b1-i5-evidence/`. Simplify → ponytail-review: Lean already. Ship.
Canonical commit `ce536ec6f2a47bcd87421c72ff0d046d03cc3935`, parent
`35ceca303022c96f3863ac0a81af7ff729d409ef`, was verified byte-for-byte against the reviewed
and saved staged diff; exactly four intended canonical/docs files, no queue or unrelated edits.
Exact proposal/selection/amendments, dependencies and boundary above remain retained;
canonical pointer: `ontology/domain.md §5 item 86` / §7. Only verified petrified-village entry
removed; mana-pump block and pre-existing unrelated queue edits preserved. Receipt/queue
maintenance is separately scoped; final-state fresh gate/scope/commit logs accompany this receipt.
No gameplay/tests, boot, visual/network checks or external retrieval; no push.
Context percentage unavailable; no whole-topic completion or exhaustion claim.

### Validation-contract source attribution — candidate-possession / item 85 (2026-10-10)

**Selection:** auto-approved under the exact owner directive retained in the pending queue,
not a fabricated numbered owner answer. Original proposal / selected option (inventory verbatim):

> Existing HANDOFF lead: possession reports need duplicate screening. Exact source: Sometimes they even possess villagers in the town who will attack you ... They will respawn with the day mobs, but will remain possessed and hostile until the portal is busted.

> Auto-approved: guide attribution for big/red/stronger possessed mobs and hostile villagers until portal destruction; distinguish observed/qualified reports from guarantees. Portal healing is explicitly speculative and must not become fact.

**Approval versus Refusing:** approval attributes qualified possession reports only; refusal
would reject this attribution, not select another curse or hostility rule. Neither changes the game.
**Application:** documentation recorded in `ontology/domain.md §5 item 85` / §7 after screening
items 1–84; separate named corroboration of existing possession facts, not new mechanics.
World-shared curse persistence, resets and hostility exceptions stand. No gameplay/live-data/
checker/test change or new implementation debt; existing possession deferral stands.
Independent content review approved with no findings; canonical commit verified and only this
queue entry removed, two unchanged siblings unapplied. No publication authority or push.
**Source:** retained public `guide.body:1128` / URL/status/capture sidecars inspected locally;
raw SHA-256 matches queue. Title/author/displayed dates and exact passage checked separately;
item 70's shared limits apply, including capture `2026-10-04T21:01:17Z` and title **updated 4/10**
distinct from displayed Updated **3 Oct, 2019 @ 10:14am** (timezone unspecified).
No immutable revision, original-build proof, external retrieval, Alpha equivalence or feature dating.
HTMLParser inspection text and `guide.text` are derivatives, not byte-equal raw HTML.
Failed diagnostic searches remain in managed evidence; existing failed assertions and documented
derivative-only differences remain unchanged.
**Dependencies (inventory verbatim):** Preserve existing curse persistence/reset and hostility exceptions.
**Documentation/implementation boundary (inventory verbatim):** Documentation only; no possession AI, portal HP, spawn rate or healing rule.
**Original evidence locators:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1128`;
`ontology/research/research_creatures_quests.md:64`; `ontology/domain.md:257,633,3177`
(inventory locators, not current line identity).
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b1-i4-evidence/`; actual Git baseline/scope, source checks, simplify → ponytail-review and
fresh whitespace/bounded-validator gates recorded there. Validator checks loaded data, not prose
truth or runtime compliance. Writer staged/committed/pushed nothing; context percentage unavailable.

**Independent review / artifact recovery:** reviewer `031b78fc-04d9-48a9-8c10-0b72b9536d76`
approved item 85 with no findings. Parent inspected the complete saved report and authorized
same-protocol recovery, not a review waiver. Original bound `reviews/b1-i4-0.json` remains empty;
original native status/terminal receipt preserved beside the distinct recovery in managed run above,
`receipts/b1-i4-evidence/recovered-review.json`. Saved original:
`/tmp/pi-subagents-uid-1000/async-subagent-runs/031b78fc-04d9-48a9-8c10-0b72b9536d76/structured-output/pi-subagent-structured-T21psh/output.json`.
Byte-equivalent SHA-256: `a3bd4d814d6f61cea0c466afe20e41d0c172cc28d322fd317c01992c5cce8334`;
provenance retained in `recovery-provenance.json`. Reviewer inspected current docs/raw quotations,
identity/sidecars, dependencies and sibling selections; did not freshly execute Git/index/hash/gates.
Finalizer independently verified actual branch/HEAD/upstream, docs-only scope/no staging, source
hash/identity/date/qualified quotes and sibling preservation. Retained local evidence only;
validator checks loaded data, not prose truth/runtime compliance. No push.

**Finalizer gates / canonical receipt:** fresh `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` passed (exit 0,
`ontology valid`); logs `canonical-diff-check.log` / `canonical-validation.log` in managed
`receipts/b1-i4-evidence/`. Simplify → ponytail-review: Lean already. Ship.
Canonical commit `03cd92ab4c339053da7b893910bfbe73ac8d8220`, parent
`8d52ddf0c24b3add4f3b542c0fa9a9113d297e77`, was verified byte-for-byte against the saved
staged diff; exactly four intended canonical/docs files, no queue or unrelated edits committed.
Exact proposal/selection/amendments, dependencies and boundary above remain retained;
canonical pointer: `ontology/domain.md §5 item 85` / §7. Only verified possession entry removed;
two sibling blocks and pre-existing unrelated queue edits preserved. Receipt/queue maintenance
is separately scoped; final-state fresh gate/scope/commit logs accompany this receipt.
No gameplay/tests, boot, visual/network checks or external retrieval; no push.
Context percentage unavailable; no whole-topic completion or exhaustion claim.

### Validation-contract source attribution — candidate-circle-power / item 84 (2026-10-10)

**Selection:** auto-approved under the exact owner directive retained in the pending queue,
not a fabricated numbered owner answer. Original proposal / selected option (inventory verbatim):

> Existing HANDOFF lead: Circle of Power reports need duplicate screening. Exact source: Defeating the boss will drop eternal embers which allows you to ignite the brazier ... I'm not sure what that entails, probably some small stat boosts, but it appears in the top left buff bar when completed.

> Auto-approved: named community report for ember/brazier/buff presentation; explicitly preserve author's uncertainty about effect. It does not substantiate or overturn approved +10% attack/HP.

**Approval versus Refusing:** approval attributes the ember/brazier/presentation report and
its uncertainty only; refusal would reject that attribution, not change D6. Neither changes the
approved game.
**Application:** documentation recorded in `ontology/domain.md §5 item 84` / §7 after
screening recorded items 1–83. Community corroboration only; D6 and item 35 stand.
No gameplay/live-data/checker/test change or new debt. Independent content review approved
with no findings; canonical commit verified and only this queue entry removed, three siblings unapplied.
No publication authority or push.
**Source:** retained public `guide.body:1128` / URL/status/capture sidecars inspected locally;
raw SHA-256 matches queue. Title/author/displayed dates and exact passage checked separately;
item 70's shared identity/date limits apply. No immutable revision or original-build proof,
external retrieval, Alpha equivalence or feature dating. HTMLParser inspection text is derivative,
not byte-equal raw HTML; previous failed assertions and derivative-only differences remain unchanged.
**Dependencies (inventory verbatim):** D6 effect remains settled.
**Documentation/implementation boundary (inventory verbatim):** Documentation only; no new buff magnitude, persistence or UI behavior.
**Original evidence locators:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1128`;
`ontology/domain.md:1490–1492,3590–3593` (inventory locators, not current line identity).
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b1-i3-evidence/`: before snapshots, source/scope/preservation checks, full-index diff,
simplify → ponytail self-review and fresh whitespace/bounded-validator logs; report
`items/b1-i3-record.json`. Initial diagnostic extended the ellipsized proposal with guessed
“minor buff” wording; exact-match check returned **False** (`source-screen.log`), not a source
identity/content mismatch. The actual raw passage has quoted “eternal embers” / “power” and
“throughout the region”; corrected exact-match evidence is retained separately. No guessed
wording enters canonical documentation. Self-review is not independent acceptance; validator
checks loaded data, not prose truth or runtime compliance. Context percentage unavailable;
no exhaustion claim. Fresh `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exit **0**;
validator reports **ontology valid**. These are pre-commit writer checks; logs/report retained.

**Independent review / artifact recovery:** reviewer `43375148-1005-4948-a1ef-7589906094a4`
approved the exact item-84 recording with no findings; simplify then ponytail review found
no necessary adjustment. Its bound `reviews/b1-i3-0.json` and writer's `items/b1-i3-record.json`
were both empty. Supervisor explicitly authorized recovery, not a review waiver. Complete saved
JSONs were inspected and copied byte-for-byte to distinct `receipts/b1-i3-evidence/recovered-review.json`
and `recovered-writer.json`; original empty artifacts remain unchanged. Saved paths, run IDs and
SHA-256 hashes are retained in `recovery-provenance.json`. Reviewer checked raw quotes/identity/
dates, scope and sibling preservation, but did not freshly run Git/hash/gates. Finalizer independently
verified actual branch/HEAD/upstream/index/diff, raw hash/quote and queue before final bounded gates.
Retained evidence only, no retrieval or push. Recovery does not repair the original delivery failure.
Fresh finalizer `git diff --check` and bounded ontology validator both exited **0**;
validator reports **ontology valid**. Logs: `precommit-diff-check.log` / `precommit-validation.log`
in `receipts/b1-i3-evidence/`. Gates check whitespace/loaded data, not prose truth or runtime compliance.

**Verified item receipt:** `candidate-circle-power` → canonical commit
`cad81bbfbd48bc43fbc4a08a89e1aeb8bb491b5c` (parent
`42e144874ea20c7bd59e5044891e2fc120b044bd`), `ontology/domain.md §5 item 84` / §7.
Exact four-file commit content/hash and raw passage were verified before removing only this
queue entry; selected proposal/option/dependency/boundary above remain retained. Final canonical
whitespace/bounded-validator gates exited **0** (`canonical-final-diff-check.log` /
`canonical-final-validation.log`); validator reports **ontology valid**. Queue/receipt maintenance
is separately scoped; sibling bodies and unrelated pre-existing queue edits are preserved.
Not pushed; source limitations and original report-delivery failures remain.

### Validation-contract source attribution — candidate-mage-tower-barrier / item 83 (2026-10-10)

**Selection:** auto-approved under the exact owner directive retained in the pending queue,
not a fabricated numbered owner answer. Original proposal / selected option (inventory verbatim):

> Existing HANDOFF lead: tower/barrier reports need duplicate screening. Exact source: breaking all crystals in the biome will break the spell on blue forcefield doors.

> Auto-approved: named guide attribution for mage/crystal tower and all-crystal barrier clearing, qualitative boss/crystal loot only; no guaranteed population, loot counts, reset or difficulty mapping.

**Approval versus Refusing:** approval improves this qualitative attribution only; refusal
would reject the attribution, not select barrier or loot mechanics. Neither changes the approved game.
**Application:** recorded in `ontology/domain.md §5 item 83` / §7 after duplicate-screening items
1–82. Existing world research/POI/mission/guards facts gain named community corroboration, not new
mechanics. §3.7 saved-world persistence item 4 and existing reset rules stand; no source labels,
live JSON, gameplay, checker/test change or new implementation debt. Independent content review
approved and canonical commit verified; only this entry removed, four siblings remain unapplied.
No publication authority or push.
**Source:** retained public `guide.body:1128` / URL/status/capture sidecars inspected locally;
raw SHA-256 matches queue. Author/title/displayed dates and exact tower passage checked separately;
item 70's shared provenance/date limits apply. No immutable revision or original-build proof,
external retrieval, Alpha equivalence or feature dating. Derived inspection text is not byte-equal
raw HTML. Previous failure receipts and documented derivative-only differences remain unchanged.
**Dependencies (inventory verbatim):** Check saved-world persistence and existing mission facts; retain original source uncertainty.
**Documentation/implementation boundary (inventory verbatim):** Documentation only; no barrier implementation, loot or encounter change.
**Original evidence locators:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1128`;
`ontology/research/research_world.md:217`; `ontology/domain.md:286,1500,1599,1662`.
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b1-i2-evidence/`: before snapshots, source/preservation checks, full-index diff, simplify →
ponytail self-review and fresh whitespace/bounded-validator logs; report `items/b1-i2-record.json`.
Initial local inspection guessed a nonexistent `#### Item 1` heading and exited **1**;
`initial-heading-check.log/.exit` preserve that failure, not a source-content mismatch. Corrected
screen uses the actual Validation-contract mapping boundary. Fresh source/preservation checks,
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`
each exit **0**; validator reports **ontology valid**. Logs/report retain actual results; the
validator checks loaded data, not prose truth or runtime compliance. Self-review is not independent
acceptance. Context percentage unavailable; no exhaustion claim.
**Independent review:** reviewer `0b4def2b-48ab-405a-9ca2-98d58d56cf5e` approved this item with
no findings. Parent inspected the full saved report and authorized same-protocol recovery, not
an execution/review waiver. Original empty bound `reviews/b1-i2-0.json` and native runtime
receipts remain unchanged. Actual saved JSON:
`/tmp/pi-subagents-uid-1000/async-subagent-runs/0b4def2b-48ab-405a-9ca2-98d58d56cf5e/structured-output/pi-subagent-structured-cVDgAV/output.json`.
Distinct byte-equivalent recovery: managed run above, `receipts/b1-i2-evidence/recovered-review.json`,
SHA-256 `b96894bae59704939505a06ea59694349720fa14c46e63545ff018614c7e090a`.
Native status/terminal receipt copies and recovery provenance retained beside it. Reviewer inspected
actual documents and retained evidence, not fresh Git/hash/gates; finalizer independently checks
actual current source/Git/scope/queue and reruns bounded gates before committing/removing this item.
Finalizer diagnostic failures retained: initial recovery check guessed a 12-entry report (actual
complete JSON has 11 entries); source excerpt lookup guessed capitalized headings, corrected to
the actual lowercase passage. Neither is an identity/content mismatch; authoritative source unchanged.
**Verified item-to-commit receipt:** canonical item commit
`8ddea40b9138c1e07b3aaef75c3ff9df5c929ea3`, parent
`e57bf70f53db17ed3ca075c6cea71dc4dd743258`, canonical pointer `ontology/domain.md §5 item 83` / §7.
Original proposal, precision selection, dependencies and boundary above retained exactly; no amendments.
Only four intended canonical/status/ledger Markdown files staged; queue excluded. Selected, staged
and committed full-index patches match exactly. No unrelated decisions committed; nothing pushed.
Finalizer evidence: managed run above, `receipts/b1-i2-evidence/`: actual Git/source/scope/queue
preservation assertions, simplify → ponytail review, canonical/receipt patches, exact staged/commit
receipts and fresh bounded gates. Canonical and receipt-state `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` exit **0**, reporting
**ontology valid**; these check loaded data, not prose truth or runtime compliance. Only this
verified item removed; four sibling blocks and pre-existing unrelated queue edits preserved.
Queue maintenance is staged selectively; unrelated edits stay dirty and unstaged. No new tests,
external retrieval, gameplay/visual/multiplayer check, new implementation debt or publication.

### Validation-contract source attribution — candidate-npc-location-dialogue / item 82 (2026-10-10)

**Selection:** auto-approved under the exact owner directive retained in the pending queue,
not a fabricated numbered owner answer. Original proposal / selected option (inventory verbatim):

> Existing HANDOFF lead: quest-location dialogue against existing UI/NPC facts. Exact source: Most will have random banter, but a few will tell you of places where someone might be being held by evil mobs, or places they remember seeing special key items.

> Auto-approved: qualitative town/adventurer location-hint attribution; not a fixed corpus, frequency, guaranteed quest disclosure or literal mandatory line.

**Approval versus Refusing:** approval improves attribution only; refusal would reject this
attribution, not select dialogue frequency/content. Neither changes the approved game.
**Application:** recorded in `ontology/domain.md §5 item 82` / §7 after screening recorded items
1–81, especially 21/54/81. Item 21's wiki hints are complemented by named Darkmega town/adventurer
corroboration; item 54's dungeon warning and item 81's presentation remain separate. No dialogue
generator, mission-reveal/UI trigger, NPC population rule, source label, live-data, checker/test or
gameplay change; no new implementation debt. Independent content review approved and canonical
commit verified; only this entry removed, five siblings remain unapplied. No publication authority or push.
**Source:** permitted retained guide/sidecars inspected locally; raw hash, URL/status/capture,
author/title/displayed dates and both exact passages checked separately. Actual raw locator for
both is `guide.body:1056`; the inventory's `:1120` does not contain the adventurer sentence.
Original locator remains in the queue; local locator mismatch is not a source-content mismatch.
Shared provenance/date limits: canonical item 70. No immutable revision, original-build proof,
external retrieval or Alpha dating; derivative inspection text is not byte-equal raw HTML.
Previous failure receipts and documented derivative differences are unchanged.
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b1-i1-evidence/`: before snapshots, source/scope checks, full-index diff, simplify →
ponytail self-review and fresh whitespace/bounded-validator logs. Writer report:
`items/b1-i1-record.json`. Validator checks existing loaded data, not prose truth or runtime
compliance; self-review is not independent acceptance. Context percentage unavailable;
no exhaustion or whole-topic completion claim. Source/scope checks, `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` each exit **0**;
validator reports **ontology valid**. Initial local scope-check script guessed a nonexistent
`#### Item 1` heading and exited **1**; its original log is preserved as `initial-source-scope.log`.
After inspecting actual headings, a prefix-preservation check passed; no source evidence changed.
**Independent review:** reviewer `1882909e-7ce4-4992-adf1-f24b3e44b53e` approved this item with
no findings. Parent inspected the full saved report and authorized recovery of the empty bound
`reviews/b1-i1-0.json`, which remains unchanged. Actual saved JSON:
`/tmp/pi-subagents-uid-1000/async-subagent-runs/1882909e-7ce4-4992-adf1-f24b3e44b53e/structured-output/pi-subagent-structured-bZtXK5/output.json`.
Distinct byte-equivalent recovery: managed run above, `receipts/b1-i1-evidence/recovered-review.json`,
SHA-256 `3cf509f5cad1dab17604cc9d349c0a276593939bf53253166399aa594f2e7fb3`.
Original runtime status/transcript summary and recovery provenance are preserved beside it.
Reviewer inspected current documents and retained evidence, not fresh shell execution;
substantive approval is separate from the empty artifact delivery and finalizer checks.
**Dependencies (inventory verbatim):** Preserve item 54's separate dungeon-warning attribution; screen item 21.
**Documentation/implementation boundary (inventory verbatim):** Documentation only; no dialogue generator, mission reveal or NPC population rule.
**Original evidence locators:** `/tmp/pixlnd-presentation-world.I1sm3d/guide.body:1056,1120`;
`ontology/research/research_creatures_quests.md:284`; `ontology/domain.md:468,1914,2534–2549`.
No amendments beyond the explicitly documented locator correction; original proposal/option stand.
**Verified item-to-commit receipt:** canonical item commit
`391716e2fd93975d4e7b8bf863f4d9aad98c1c95`, parent
`a9a7213c5fe7b7b4aaf45b03f36425a11da72969`, canonical pointer `ontology/domain.md §5 item 82` / §7.
Only four intended canonical/status/ledger Markdown files were staged; pending queue excluded.
Saved, staged and committed full-index patches match exactly. No unrelated decisions were committed.
Finalizer evidence: managed run above, `receipts/b1-i1-evidence/`: source/scope and Git/queue
preservation assertions, simplify → ponytail review, canonical and receipt patches, exact staging/
commit receipts and fresh bounded gates. Canonical and final receipt-state source/scope checks,
`git diff --check` and `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`
each exit **0**; both validators report **ontology valid**. The original writer scope-script failure
and empty review artifact remain preserved; finalizer made one failed guessed recovery-skill-path
read, then located and loaded the installed skill; no validation/infrastructure gate failed.
Only this verified entry was removed from the pending queue after the canonical commit was checked.
Pre-existing queue reaffirmation/dependency edits are preserved unstaged and excluded from both
item commits; no sibling selection changed. Receipt/status/queue maintenance is committed separately.
Checks cover existing loaded data and recording/source fidelity, not prose truth, historical runtime
or new enforcement. No gameplay tests added/run; no external retrieval, publication or exhaustion claim.

### Validation-contract source attribution — candidate-friendly-npc-presentation / item 81 (2026-10-10)

**Selection:** auto-approved under the exact owner directive retained in the pending queue,
not a fabricated numbered owner answer. Original proposal / selected option (inventory verbatim):

> Existing HANDOFF lead: NPC light-blue names/waving against existing UI/NPC facts. Exact source: Otherwise they should have a light blue name above them and wave when you get within chatting distance.

> Auto-approved: direct named community attribution of friendly presentation, preserving should/usually qualifiers, not a hostility detector contract or numeric interaction range.

**Approval versus Refusing:** approval improves attribution only; refusal would reject this
attribution, not select another hostility rule. Neither changes the approved game.
**Application:** recorded in `ontology/domain.md §5 item 81` / §7 after duplicate screening
recorded source items 1–80, particularly 21/35, and settled hostility policy. Named corroboration
of an existing presentation description, not a detector/range/animation rule. No gameplay,
source-label, live-data, checker/test change or new implementation debt. Independent content
review approved with no findings; canonical commit verified, only this queue entry removed.
Six siblings remain unapplied. No publication authority or push.
**Source:** retained public guide and sidecars inspected locally; URL/status/capture/raw SHA-256,
author/title/displayed dates and exact qualified paragraph checked separately. No immutable
revision, original-build proof, external retrieval or Alpha dating; derivative text is not raw
byte equality. Shared provenance/limits: canonical item 70. No failed source assertion occurred
in this item; earlier receipts and documented derivative differences are unchanged.
**Evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b1-i0-evidence/`: source/scope checks, before snapshots, full-index diff, simplify →
ponytail self-review and fresh whitespace/bounded-validator logs. Final structured writer report:
`items/b1-i0-record.json`. Fresh source/scope assertions, `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` each exit **0**;
validator reports **ontology valid**. It checks loaded data, not prose truth or runtime compliance;
writer review is not independent acceptance. Context percentage unavailable; no exhaustion claim.
**Independent review / delivery recovery:** complete approved JSON at
`/tmp/pi-subagents-uid-1000/async-subagent-runs/4c3b1880-5a43-4331-9149-d42311f899d5/structured-output/pi-subagent-structured-Q85nbT/output.json`;
parent inspected and authorized recovery. Bound `reviews/b1-i0-0.json` remains empty: substantive
approval is separate from failed artifact delivery. Byte-identical distinct copy:
`receipts/b1-i0-evidence/recovered-review.json`, SHA-256
`351dae87a86efb5c3d25d7c814274ad4d24408a8c0ca80337f4df40bdb756413`.
Original failed artifact and recovery provenance are retained there. Reviewer inspected source/
patch/current files and writer logs, but executed no fresh Git/hash/validator commands; finalizer
must do so. Two local recovery-wrapper assertions failed before copying/mutation (case-sensitive
item substring, guessed evidence count); corrected after inspecting actual JSON, without changing it.
**Verified item receipt:** canonical commit `b2db261c46ce65d999556a1dc9f35bfaffb205ba`,
parent `ad74ffd206db16fd3f08dd98731398120917185d`; exactly four canonical/status Markdown
paths, staged/committed full-index diffs byte-identical. Queue and unrelated reaffirmation edits
excluded from that commit. Canonical pointer: `ontology/domain.md §5 item 81` / §7; exact proposal
and precision selection above remain unchanged. Finalizer freshly checked branch/HEAD/upstream/
index, actual scope, retained raw hash/identity/dates/capture/quote/qualifiers and six byte-identical
sibling blocks. `git diff --check` and bounded ontology validator exit **0**, **ontology valid**.
Simplify → ponytail content review found no reduction; finalizer status/receipt edits are bookkeeping
only. Managed evidence: `receipts/b1-i0-evidence/` (scope/source script/logs, fresh gates,
canonical staged/committed diff/hash and recovery provenance). Receipt/queue maintenance is a
separate commit; pre-existing queue reaffirmation/dependency edits remain unstaged and preserved.
Validation checks loaded data, not prose truth or runtime compliance; no external retrieval,
gameplay tests or push. Context percentage unavailable, no exhaustion or whole-topic completion claim.

### Validation-contract source attribution — candidate-sleep-darkmega / item 80 (2026-10-10)

**Selection:** under the latest exact owner directive in `docs/todo_handle_reconciled_items.md`,
not a fabricated numbered owner answer. Supervisor narrowed the aggregate worker brief to
**candidate-sleep-darkmega ONLY**; the other seven candidates require distinct fresh workers.
Original proposal / selected option (inventory verbatim):

> Existing HANDOFF lead (lines 23–30): sleeping-bag gradual healing/time acceleration (duplicate-check items 8–11). Exact source: sleeping in a sleeping bag ... will regenerate your health gradually and speed up time flow.

> Auto-approved: add this separate named Darkmega community corroboration, with no rate, units, activation or original-build proof; duplicate-check recorded items 23/26/29 before writing.

**Approval versus Refusing:** approval adds defensible community corroboration only; refusal
would reject that attribution, not select another sleep rule. Neither changes the approved game.
**Application:** canonical documentation recorded after screening items 1–79, including
10–11/23/26/29 and item 70's guide provenance; new named corroboration, not duplicated rate policy.
Independent content review approved with no findings; canonical commit verified and only this
selection removed from the pending queue. Seven other entries unchanged.
No gameplay, source labels, live JSON, checker/code/tests or new implementation debt.
**Writer evidence:** managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`,
`items/b0-i0-evidence/` under the session output directory: local raw-source identity/date/content
check, saved diff, simplify/ponytail review and fresh whitespace/validator logs. Validation checks
existing loaded data only, not prose truth, original-game behavior or new enforcement.
**Fresh writer gates:** local source/scope assertions, `git diff --check` and
`timeout 150 nix develop -c godot --headless -s ontology/validate.gd` all exit **0**;
validator reports **ontology valid**. `/simplify` then ponytail-review applied; writer self-review
is not independent acceptance. No external retrieval, immutable revision, original-build test,
boot or publication claim.

**Verified item receipt:** `candidate-sleep-darkmega` → `ontology/domain.md §5 item 80` / §7 →
canonical commit **`d662a2099972136934dd1c1cfe92d49b8e2a605e`**, parent
`555d4f73bdf7273eac0bae19342bd5782b29c444`. Original proposal/selected option above retained;
no per-item amendments. Standing exact owner answer:
**“For each item which implies approving/refusing to increase source-precision, auto-approve it in a subagent.”**
The seven sibling selections are not handled by this receipt.

**Review and recovery:** independent reviewer `9cbcaa06-9e8c-40d0-b399-45bac56780b9`
approved sleeping-bag-only content/source/provenance and all five current Markdown files;
no findings; simplify then ponytail review complete. Bound `reviews/b0-i0-0.json` was **0 bytes**:
artifact-delivery failure remains preserved, not relabelled successful. Supervisor authorized
recovery of complete saved JSON from
`/tmp/pi-subagents-uid-1000/async-subagent-runs/9cbcaa06-9e8c-40d0-b399-45bac56780b9/structured-output/pi-subagent-structured-7DxXfX/output.json`.
Recovered SHA-256: `475a01bca6f4c94b17877543f5c9f2c73780463f44ec4962542151ce1d30cb71`.
Reviewer had file-only tools: no fresh Git/hash/validator execution. Its content approval is
separate from finalizer checks, not an execution-protocol replacement.

**Finalizer verification:** actual branch/HEAD/upstream/index matched expected checkpoint before
mutation. Fresh full-index diff and queue byte-equal reviewed writer snapshots; default abbreviated
Git index hashes initially failed a hash assertion, then exact full-index comparison passed.
Local source quotation/qualifier/URL/status/capture/raw hash checked again. Fresh
`git diff --check` and bounded ontology validator each exit **0**, **ontology valid** before
canonical commit; hash/parent/content verified afterward. Receipt/queue state also passes fresh
whitespace/validator checks; no source-supported semantics changed in closure. Existing loaded-data
validation does not prove prose truth, historical behavior or new enforcement. No gameplay/boot/
visual/multiplayer checks, external retrieval or push. Evidence, recovery provenance and logs:
managed run `9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1`, `receipts/b0-i0-evidence/`.

### Verified sourcing batch 70–74 — recording and closure receipts (2026-10-09)

All five original selections below are handled without owner amendments or unresolved dependencies.
Item 70's POI clarification preserves the quoted source meaning, not a new owner decision.
Preparation `60a51dd5dd3ada79a60d5fe4f0b2747a1226b5fd` follows baseline
`5df0f3b040d373a46ea8d259175c24e027bf3c7a`; each item below follows the preceding row.
Canonical pointers: `ontology/domain.md §5 items 70–74` / §7. Completed selections stay here;
empty pending-only queue deleted after item checks, commits, independent review and parent acceptance.

| Item | Commit | Parent | Writer evidence |
|---|---|---|---|
| 70 | `25d9a4193cecfb37671fd0854e1491c5845302e9` | `60a51dd5dd3ada79a60d5fe4f0b2747a1226b5fd` | `/tmp/pixlnd-source-item-70-nAbRIi/` |
| 71 | `0e391ffcd1c149d2af1cf1cf6e0aa03538325d31` | `25d9a4193cecfb37671fd0854e1491c5845302e9` | `/tmp/pixlnd-source-item-71-G3AH0R/` |
| 72 | `d0dbbba5fe2a59bcbbf4a030a548e675fe9f1f1c` | `0e391ffcd1c149d2af1cf1cf6e0aa03538325d31` | `/tmp/pixlnd-source-item-72-N046fs/` |
| 73 | `3014ccd93d360405c87aafb616802e99cf248cdc` | `d0dbbba5fe2a59bcbbf4a030a548e675fe9f1f1c` | `/tmp/pixlnd-source-item-73-QLGPE7/` |
| 74 | `0c0ae7fe1c4b8522618d39b03bed811e969ef7d0` | `3014ccd93d360405c87aafb616802e99cf248cdc` | `/tmp/pixlnd-source-item-74-LDgGzB/` |

Each writer inspected retained public sources and scope, performed simplify → ponytail-review,
ran bounded ontology validation/whitespace gates (exit 0) and retained matching unstaged/staged/
committed binary full-index diffs. Independent recording review: **OK with notes**, no P0/P1;
one P2 stale current-checkpoint label in `todo_implement.md`, verified and corrected by parent.
Report: `/tmp/pixlnd-source-parent-70-74/recording-review.md`, preserved from managed run
`57635ae4-2e91-4b83-9036-fc5aa474f6c1`. Reviewer read raw sources, patches and logs but ran no
commands/tests/hash calculations/byte comparisons. Its recording review is not closure review.

Parent inspected actual aggregate changes and reran exact per-commit Git/diff/source/preservation
audit, bounded validator and boot, all exit 0 (`/tmp/pixlnd-source-parent-70-74/{audit,validator,boot}.*`).
Workflow receipt and retained `workflow-summary.json` confirm five distinct worker run IDs and
requested/resolved fresh contexts (`distinct-fresh-workers.*`). Preparation's broad directory-search
failure and item 70's guessed skill-directory failure were retained; exact-path same-protocol
continuations were authorized. Parent `audit-initial.*` preserves an overbroad assertion that
mistook authorized §7 status edits for changed rules; corrected audit explicitly permits only the
three inspected status lines while preserving prior canonical rules/attributions. No failure erased.

Public source: `/tmp/pixlnd-presentation-world.I1sm3d/guide.body` and URL/capture sidecars; source
identity, dates and limits: canonical item 70. Parent checked eleven exact bounded quotes from raw
HTML and its unchanged saved hash; derived text is not byte-equal HTML. No immutable revision,
release chronology, Alpha equivalence or original-build demonstration is claimed. No external
retrieval/private DOM/assets/gameplay/visual/multiplayer checks. Validator/boot cover existing loaded
data/startup, not prose/history or new enforcement. Follow-up closure review by the retained
reviewer (`fa84e18c-6457-4b22-9e10-43ada283b5e9`): **OK**, one evidence-pointer correction.
Parent applied it: the original recording report is preserved separately because resumed managed
output overwrote its previous path. Closure report: parent `closure-independent-review.md`;
final scope/review/gate/commit receipts: `closure-final-*`. Reviewer performed no commands/tests/
byte comparisons; parent inspected the final pointer/receipt delta. No push authority.
Remaining unscreened leads and evidence gaps: current `docs/HANDOFF.md`; no new numbered selection.

### Verified sourcing batch 75–79 — recording and closure receipts (2026-10-10)

All five original selections below are handled under the exact current standing answer above,
without amendments or unresolved dependencies. Each distinct item worker saved the selection
before canonical recording and made its own scoped commit. Canonical pointers:
`ontology/domain.md §5 items 75–79` / §7. Empty pending-only queue deleted after verified item
checks/commits, independent recording review and parent acceptance.

| Item | Commit | Parent | Writer evidence |
|---|---|---|---|
| 75 | `94007e582a5ac01581b584f44c00d2fc7a87f23f` | `858aaf7d8bbe2074d17ce582486702ee49fb54a0` | `/tmp/pixlnd-source-item-75/` |
| 76 | `9f995441274043cff599f9efff01b5d5a29651a8` | `94007e582a5ac01581b584f44c00d2fc7a87f23f` | `/tmp/pixlnd-source-item-76/` |
| 77 | `051b6054b270d668f005e2749673d7034b9d8612` | `9f995441274043cff599f9efff01b5d5a29651a8` | `/tmp/pixlnd-source-item-77/` |
| 78 | `6d39cf31a0cfd2905a174d4aa4e61311a63794e0` | `051b6054b270d668f005e2749673d7034b9d8612` | `/tmp/pixlnd-source-item-78/` |
| 79 | `14bbdb8bbc0f13bfa0705ec5c5e1df26a5bf5d55` | `6d39cf31a0cfd2905a174d4aa4e61311a63794e0` | `/tmp/pixlnd-source-item-79/` |

Each writer retained source inspection, simplify → ponytail-review, passing whitespace/bounded
validator logs/exits and matching raw full-index binary unstaged/staged/committed diffs.
Fresh independent recording review: **OK with notes**; source/scope passed, sole **P2** was the
new batch's copied Oct09 decision/recording labels. Parent confirmed Oct10 from actual clock/
commit evidence and approved the minimal closure correction; prior/source/capture dates and
historical snapshots are unchanged. Archived review and date proof:
`/tmp/pixlnd-source-session-01a1251a/parent/{recording-review-batch-1.md,batch-date-evidence.txt}`.
Reviewer manually compared public sources/prose/patches and read receipts; no commands, tests,
parsers, hashes or byte comparisons. Recording review is not closure review.

Parent independently inspected actual aggregate changes, all five commits/parents and three saved
patch variants per item, 15 bounded raw-HTML-derived quotations, unchanged raw hash/identity/capture,
prior canonical rules and exact selections/queue. Parent audit, whitespace, bounded validator and
boot passed (exit 0): that parent directory's `audit-batch-1.*`, `diff-check-batch-1.*`,
`validator-batch-1.*`, `boot-batch-1.*`; actual patches: `item-75-actual.diff` through
`item-79-actual.diff`. Source remains the retained public Darkmega guide from item 70, not an
immutable revision or demonstrated original build. No external retrieval, private DOM, assets,
gameplay/visual/multiplayer checks or new implementation debt. Validator/boot check existing loaded
data/startup, not historical truth, prose semantics or new enforcement.

Closure-only date/status/queue/handoff review, simplify → ponytail-review, fresh scope/whitespace/
validator/boot gates and exact diff/commit receipts: `/tmp/pixlnd-source-session-01a1251a/closure-batch-1/`.
Parent separately verifies the closure delta before another inventory; next scout must contact
parent before research expansion/selection. Concrete remaining leads: current `docs/HANDOFF.md`.
No new item, whole-topic completion or publication authority.

### Validation-contract source attribution — item 79 (2026-10-10)

**Selection:** auto-approved as proposed under the exact current owner request above, not a
numbered owner answer. Amendments: none. Original proposal / selected option (verbatim):

> Attribute the qualitative report that freeing a captured supplier gnome by defeating enemies gives loot and improves village armor/weapon shop inventory according to freed gnomes, with separate daily shop-resupply context. Approval versus Refusing: accepting sharpens existing supplier/shop sourcing; refusing omits only this attribution. Both leave rewards, stock, rescue repeatability and persistence unchanged.

**Application:** handled in `ontology/domain.md §5 item 79` / §7; independent recording review,
parent acceptance and full commit receipt above. Source limits remain canonical; one-time rescue,
world-shared persistence and item 19's distinct jewelry prerequisite stand. No new implementation debt.

### Validation-contract source attribution — item 78 (2026-10-10)

**Selection:** auto-approved as proposed under the exact current owner request above, not a
numbered owner answer. Amendments: none. Original proposal / selected option (verbatim):

> Attribute the guide's angel-shrine description and E-triggered flute activation making a shrine the current spawn point and opening it for travel. Approval versus Refusing: accepting adds bounded sourcing to existing shrine/flute facts; refusing declines only this attribution. Both leave activation, respawn, travel and persistence rules unchanged.

**Application:** handled in `ontology/domain.md §5 item 78` / §7; independent recording review,
parent acceptance and full commit receipt above. Source limits remain canonical; activation,
respawn, travel and personal saved-world records stand. No new implementation debt.

### Validation-contract source attribution — item 77 (2026-10-10)

**Selection:** auto-approved as proposed under the exact current owner request above, not a
numbered owner answer. Amendments: none. Original proposal / selected option (verbatim):

> Attribute the qualitative report that potions can be consumed while moving whereas food is consumed sitting down over a longer duration. Approval versus Refusing: accepting improves sourcing of existing consumable-use descriptions; refusing omits this attribution only. Both leave healing, movement, timing and controls unchanged.

**Application:** handled in `ontology/domain.md §5 item 77` / §7; independent recording review,
parent acceptance and full commit receipt above. Source limits remain canonical; hybrid rules and
current instant-use simplification stand. No new implementation debt.

### Validation-contract source attribution — item 76 (2026-10-10)

**Selection:** auto-approved as proposed under the exact current owner request above, not a
numbered owner answer. Amendments: none. Original proposal / selected option (verbatim):

> Attribute free eagle rides to friends and the guide's map-head/accompanying flight-point UI at the Flight Master, with its contextual 5–30 second distance-dependent travel report. Approval versus Refusing: accepting refines existing multiplayer/travel sourcing; refusing declines only this attribution. Neither changes multiplayer, destination selection, timing or prices.

**Application:** handled in `ontology/domain.md §5 item 76` / §7; independent recording review,
parent acceptance and full commit receipt above. Source limits remain canonical; contextual timing
is not a runtime bound and hybrid rules stand. No new implementation debt.

### Validation-contract source attribution — item 75 (2026-10-10)

**Selection:** auto-approved as proposed under the exact current owner request above, not a
numbered owner answer. Amendments: none. Original proposal / selected option (verbatim):

> Attribute the guide's Flight Master/eagle-perch encounter opening a map with plus-sign flight points, purchased points usable again, and a temporary drop-off glider even without an owned glider. Approval versus Refusing: accepting adds bounded community sourcing to existing travel descriptions; refusing omits only that attribution. Both leave travel, prices, controls and traversal gates unchanged.

**Application:** handled in `ontology/domain.md §5 item 75` / §7; independent recording review,
parent acceptance and full commit receipt above. Source limits remain canonical; gliding gates,
world bounds and personal travel records stand. No new implementation debt.

### Validation-contract source attribution — item 74 (2026-10-09)

**Selection:** auto-accepted under the exact batch 70–74 standing answer above, not a numbered
owner approval. Original proposal / selected option (inventory verbatim):

> Attribute qualitative Crafting Kit encounters that can involve bosses or captured NPCs, reward a crafting book and unlock recipes. Approval versus Refusing: accepting adds community sourcing to existing book/mission facts; refusing rejects only the attribution. Both leave crafting/rewards unchanged.

**Application:** handled in `ontology/domain.md §5 item 74` / §7; independent recording review,
parent acceptance and full commit receipt above. No gameplay, labels, live-data change or new
implementation debt; hybrid crafting rules stand.

### Validation-contract source attribution — item 73 (2026-10-09)

**Selection:** auto-accepted under the exact batch 70–74 standing answer above, not a numbered
owner approval. Original proposal / selected option (inventory verbatim):

> Attribute the Reins-context instruction to use T beside a pet to mount. Approval versus Refusing: accepting improves historical control sourcing; refusing omits this attribution. Neither changes rideability or approved mounting requirements.

**Application:** handled in `ontology/domain.md §5 item 73` / §7; independent recording review,
parent acceptance and full commit receipt above. No gameplay, labels, live-data change or new
implementation debt; mounting gates stand.

### Validation-contract source attribution — item 72 (2026-10-09)

**Selection:** auto-accepted under the exact batch 70–74 standing answer above, not a numbered
owner approval. Original proposal / selected option (inventory verbatim):

> Attribute pet joining the player's initial fight, T whistle recall, far-away teleport and short-time nearby return after going down. Approval versus Refusing: accepting adds sourcing to existing pet behavior; refusing declines that attribution only. Both leave pets unchanged.

**Application:** handled in `ontology/domain.md §5 item 72` / §7; independent recording review,
parent acceptance and full commit receipt above. No gameplay, labels, live-data change or new
implementation debt; pet rules stand.

### Validation-contract source attribution — item 71 (2026-10-09)

**Selection:** auto-accepted under the exact batch 70–74 standing answer above, not a numbered
owner approval. Original proposal / selected option (inventory verbatim):

> Attribute the guide's left/right arrows centering the map view on previously visited biomes. Approval versus Refusing: accepting sharpens existing map-selector sourcing; refusing omits only this attribution. Neither changes exploration/gameplay.

**Application:** handled in `ontology/domain.md §5 item 71` / §7; independent recording review,
parent acceptance and full commit receipt above. No gameplay, labels, live-data change or new
implementation debt.

### Validation-contract source attribution — item 70 (2026-10-09)

**Selection:** under the exact batch 70–74 standing answer above, not a numbered owner approval.
Original proposal / selected option (inventory verbatim):

> Attribute M-open, wheel-zoom, middle-click marker, right-click pan, left-click rotate and player markers visible on a zoomed-out minimap. Approval versus Refusing: accepting improves sourcing; refusing declines only this attribution. Both leave controls/gameplay unchanged.

**Fidelity clarification:** “player markers” means player-created POIs, not player positions;
retained queue clarification, not a new owner amendment. Canonical report/provenance/limits:
`ontology/domain.md §5 item 70` / §7. No gameplay, labels or live-data change; no new debt.
**Application:** handled; independent recording review, parent acceptance and full commit receipt
above.

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
