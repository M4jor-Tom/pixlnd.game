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

**Current finite completion authority (2026-10-11):** latest owner instruction
**“Finish approving item 111 from handoff, then handoff, commit, push”** supersedes
historical STOP/NO PUSH checkpoints only for finite 108–111 completion and verified
status/handoff maintenance, then normal publication of the current branch after
prerequisites and parent acceptance/native acknowledgment. Only the final publisher
may access remote Git/push; source approval is not publication authority. No new items.

**Sourcing-only pass (2026-10-11; earlier authority snapshots historical):** owner answered **“Yes”** to a new
precision pass under standing auto-approval. Previous skill creation/publication
completed at baseline `c29d0c06f7a976874aaa1cafc822b1710d34594a`; former 94–107
STOP/prepublication snapshot below is historical. Prior push instruction was fulfilled;
that new-pass source approval supplied **no new publication authority** (latest completion
instruction above is separate). Exactly four selected items **108–111** are approved;
item **108** is **handled locally** in `domain.md §5` / §7: Furnace/Saw location
attribution only, independently reviewed and canonical commit verified; exact approval,
qualifications, review/gate limits and canonical receipt are in `todo_decide.md §E`.
Item **109** is **handled locally** in `domain.md §5` / §7: Darkmega's general
Combo Counter attribution, with approximate caps/armor/timing qualified and hybrid
rules unchanged. Independent review and fresh gates passed; canonical commit
`ce3ea42dfdb8bab6682ed24c73c00c55ed5ffeeb` matches the reviewed full diff.
Exact selection/review/gate receipt: §E. Item **110** is **handled locally** in
`domain.md §5` / §7: historical Darkmega Spikes cost-nullification attribution, not a
hybrid target; the approved remaining-cost ×0.25 reduction stands. Independent review
and fresh gates passed; canonical commit `3ab368988920d887ed2885767cfb7cf347c1673d`
byte-matches the reviewed diff. Exact selection/review/gate/recovery receipt: §E.
Item **111** is **handled locally** in `domain.md §5` / §7: Darkmega's qualitative
death/travel-time attribution, not a loss audit or respawn/reset rule; existing death
rules and cut injured-history descriptions stand. Fresh independent review and separate
finalizer gates passed before canonical commit `162fadfee9437eb2c30e24cd39eb07bdd8188df8`,
verified byte-equal to the reviewed diff. Exact selection/provenance/gates: §E.
Source items **1–111 handled**; finite **108–111 complete locally**, with canonical/separate
receipt pairs in §E. Truly empty pending queue deleted after verification. Current §7
status/authority references now match this finite frontier; older source-choice permission
snapshots remain dated provenance. This status/handoff is a **prepublication checkpoint**:
independent review of the exact status/handoff diff, fresh separate gates, then the exact
scoped maintenance commit with actual hash/parent/scope/full-diff verification. Next comes a
fresh finite committed-state audit bound to that maintenance HEAD, explicit parent native
acceptance/acknowledgment, then the conditional publisher for normal publication of that same
HEAD on `fix/ontology-reconciliation` only. Actual publication is established only by external
native receipt/live Git, not this checkpoint. Verify fresh clean local HEAD/configured
upstream/remote-tracking/live remote exact equality, then stop. Item recording
alone is not overall completion. Items 1–107/D1–D26/later
choices stand; no gameplay/source-label/live-data/checker/tests/research changes or
new debt. HOLDs/gaps and UNAPPROVED retained leads persist; no research beyond this
packet while recording, no exhaustion claim. Both failed-workflow recoveries and
native byte-verification/derivative correction are retained in HANDOFF/§E and immutable evidence.

**Historical prepublication session snapshot (2026-10-10):** selected inventory-3 frontier **94–107 complete**;
pending queue absent. **STOP** research, inventories and proposals. Verified handoff comes first
(final independent review/parent verification still required), then parent creates
`/ontology-auto-approve-data-source-precision-increase` in harness project memory, then separately
delegates conditional publication of `fix/ontology-reconciliation` and verifies fresh equality/
clean state. Skill/publication **not yet done**; not pushed. Historical leaf restrictions remain
dated limits, not absence of current conditional permission. No universal source exhaustion;
remaining/withdrawn leads are unapproved research. Exact instructions and current maintenance/
item 90 native-review recovery with original delivery limitation: HANDOFF/§E. Item 97's actual
supervisor-authorized postcanonical validator timing remains unchanged. No domain/source-block,
gameplay, JSON or checker/test change.

**Previous source precision (2026-10-10):** `candidate-darkmega-glider-boat` documentation
recorded in `domain.md §5 item 107` / §7 under previously selected auto-approved authority.
Named historical qualitative forward/Space stamina and continuing boat-direction instructions;
no hybrid controls, steering/autopilot or balance defaults. Item 75's free glider waives no gates;
D1/D4 exclude regional disappearance. Training/equipped-item gates, global use, outer-world
bounds and settled stamina rules stand. Local raw/sidecars and canonical duplicate-screen through
item 106 checked. Independent source/scope review approved with no findings; exact native
result/origin retained distinctly and checked against real saved JSON. Finalizer fresh gates
passed before canonical commit `49e6f362d141a8835827f5518a5bb0f89bbf4967`; hash/parent/
paths/content match the reviewed diff. Last selection removed after verification; empty queue
deleted, research boundaries retained in HANDOFF/§E; §7's stale queue/index status corrected.
No gameplay/live-data/checker/tests, assets, new debt or push. Exact selections/review/receipt:
§E; queue exhaustion does not establish broader source exhaustion.

**Previous source precision (2026-10-10):** `candidate-darkmega-artifact-dungeons` documentation
recorded in `domain.md §5 item 106` / §7 under previously selected auto-approved authority.
Qualified icon, discover-before-reveal, key-access and multiple-relic reports retain “normally”,
“sometimes” and “Usually”; no orange-circle authentication or exact count. Source leveling/
qualitative stacking remain historical Steam comparison. D1/D6, logarithmic rewards, 1–3 per
land, traversal gates and personal lore/nonrenewing artifact claims stand. Local raw/sidecars
and items 1–105 duplicate-screen checked. Independent source/scope review approved with no
findings; exact native result/origin retained distinctly and checked against real saved JSON.
Finalizer fresh gates passed before canonical commit `564daa26181ede0611e9554dc53d770a16f30392`;
hash/parent/paths/content match the reviewed diff. Only artifact-dungeon removed; glider/boat
unchanged and pending. No gameplay/live-data/checker/tests, new debt or push. Exact saved
selections/review/receipt: §E; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-faction-encounters` documentation
recorded in `domain.md §5 item 105` / §7 under previously selected auto-approved authority.
Named qualitative necromancer/undead, paladin/unholy-pact, druid/steel and conditional spawning-
structure examples preserve author labels and “in some cases”; no catalog identity equivalence
or universal allegiance/hostility inferred. Items 74/79/83–87 and settled rules stand. Local raw/
sidecars and items 1–104 duplicate-screen checked. Independent source/scope review approved with
no findings; exact native result/origin retained distinctly and checked against real saved JSON.
Finalizer fresh gates passed before canonical commit `a1c83918d44304332074c48bb2dd666175831830`;
hash/parent/paths/content match the reviewed diff. Only faction removed; two unchanged siblings
pending. No gameplay/live-data/checker/tests, new debt or push. Exact saved selections/review/
receipt: §E; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-ingredient-attribution` documentation
recorded in `domain.md §5 item 104` / §7 under previously selected auto-approved authority.
“Apparently”, “feel like” speculation, “some” / “occasionally” and explicit sugar/lemon reports
remain distinct named community claims, not authentication of catalog locations or A/S tags.
Items 45/92 and settled rules stand. Local raw/sidecars and items 1–103 duplicate-screen checked.
Independent source/scope review approved with no findings; exact native result/origin retained
distinctly and checked against real saved JSON. Finalizer fresh gates passed before canonical
commit `c4f328dc7c71242219a4cec721abf0fe37db4fb3`; hash/parent/paths/content match the reviewed
diff. Only ingredient removed; three unchanged siblings pending. No gameplay/live-data/checker/
tests, new debt or push. Exact saved selections/review/receipt: §E; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-arena-attribution` documentation
recorded in `domain.md §5 item 103` / §7 under previously selected auto-approved authority.
Named qualitative boss-rush/loot and qualified final-boss/respawn reports; three preliminary
rounds explicitly disagree with, but do not replace, the exactly-five-wave ladder. “Usually” /
“I think”, existing rewards and hybrid reset/permanent-claim policy stand. Local raw/sidecars
and items 1–102 duplicate-screen checked. Independent source/scope review approved with no
findings; exact native result/origin retained distinctly and checked against real saved JSON.
Finalizer fresh gates passed before canonical commit `d7c89560bf02489c31cb8c1868417bfc8808f57a`;
hash/parent/paths/content match the reviewed diff. Only arena removed; four unchanged siblings
pending. No gameplay/live-data/checker/tests, new debt or push. Exact saved selections/review/
receipt: §E; owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-lore-attribution` documentation
recorded in `domain.md §5 item 102` / §7 under previously selected auto-approved authority.
Named qualitative lore-site/artifact-reveal report; both “usually” and “potential” qualifications
retained. ≈10 % / 100 %, character/world lore, shared terrain and D1/D6 stand. Local raw/sidecars
and duplicate-screen checked. Independent source/scope review approved with no findings; exact
native result/origin retained distinctly and checked against real saved JSON. Finalizer fresh gates
passed before canonical commit `251cb4bc628ed7c3b00430890376735efe9d0faf`; hash/parent/paths/
content match the reviewed diff. Only lore removed; five unchanged siblings pending. Documentation
only, no live-data/gameplay/checker/tests, new debt or push. Exact saved selection/review/receipt:
§E. Owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-mage-weapons` documentation
recorded in `domain.md §5 item 101` / §7 under previously selected auto-approved authority.
Named qualified fixed-location Staff tornado, finite hitscan Wand and gravity-free Bracelet reports;
estimates, terrain/combo/cancellation and qualitative comparisons remain historical, not defaults.
Approved Wand item 1, whole-channel combo policy and D24 stand; item 97 is distinct. Retained raw/
sidecars and canonical duplicate-screen checked locally; no immutable revision or original-build/
Alpha proof. Independent source/scope review approved with no findings; exact native result/origin
retained distinctly and checked against real saved JSON. Finalizer fresh gates passed before canonical
commit `e6b1b5139ca884c58c949e9224f47c2370c80858`; hash/parent/paths/content match the reviewed
diff. Only Mage weapons removed; six unchanged siblings pending. Documentation only, no live-data/
gameplay/checker/tests, new debt or push. Exact saved selections/review/receipt: §E; owner frontier
unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-ranger-weapons` documentation
recorded in `domain.md §5 item 100` / §7 under previously selected auto-approved authority.
Named qualified Bow arc/four-arrow volley, Crossbow charged bolt and cursor-following Boomerang/
dual-toss reports; random-loot and untested-Sniper qualifiers preserved. Counts, qualitative ranges,
timers, dud shots and knockdown remain reports; consolidated 4–5, items 53/95 and D24 stand.
Retained raw/sidecars and canonical duplicate-screen checked locally; no immutable revision or
original-build/Alpha proof. Independent source/scope review approved with no findings; exact
native result/origin retained distinctly and checked against real saved JSON. Finalizer fresh gates
passed before canonical commit `e4a60f47d2f0f1738882913ccd12191471838b38`; hash/parent/paths/
content match the reviewed diff. Only Ranger removed, seven unchanged siblings pending.
Documentation only; no live-data/gameplay/checker/tests, new debt or push. Exact saved selection/
review/receipt: §E. Owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-rogue-weapons` documentation
recorded in `domain.md §5 item 99` / §7 under previously selected auto-approved authority.
Named qualified roundhouse, Dagger poison and multi-hit-lunge reports; minor testing stays tentative,
counts/stacking/crit observations historical. Items 49/64, D24/D26, poison/dodge, combo and equipment
rules stand; repeated-right source pairing is not repaired into policy. Retained raw/sidecars and
canonical duplicate-screen checked locally; no immutable revision or original-build/Alpha proof.
Independent source/scope review approved with no findings; exact native result/origin retained
distinctly and checked against real saved JSON. Finalizer fresh gates passed before canonical commit
`05a18f13d9e0c8fdd3ddc063e4426adcaf3af75b`; hash/parent/paths/content match the reviewed diff.
Only Rogue removed, eight unchanged siblings pending. Documentation only, no live-data/gameplay/
checker/tests, new debt or push. Exact saved selection/review/receipt: §E. Owner frontier unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-warrior-weapons` documentation
recorded in `domain.md §5 item 98` / §7 under previously selected auto-approved authority.
Named qualitative great-weapon sequence, overhead/defensive sweep, dual spin and shield
block/charged-swipe corroboration; favorites/proc impressions remain reports, not mechanics
authority. Item 96's block-mana disagreement and D11/D23/D24 stand; charge is not a dash.
Retained raw/sidecars and duplicate-screen checked locally; no immutable revision or original-build/
Alpha proof. Independent source/scope review approved with no findings; exact native result/origin
retained distinctly. Finalizer fresh gates passed; canonical commit
`24a94c5a40d2361a9ddcf55515f73a5626df8359` hash/parent/paths/content verified.
Only this handled selection removed, nine unchanged siblings pending. Documentation only, no
live-data/gameplay/checker/test change, new debt or push. Exact selection/review/receipt limits:
§E. Owner frontier below unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-mage-abilities` documentation
recorded in `domain.md §5 item 97` / §7 under previously selected auto-approved authority.
Named qualified Fire/Water Mage reports; hover seems-free/reapplication and puddle stacking stay
historical, not formulas; four missiles and around-six bubbles separately attributed. F1's six
bubbles and D21/D24 stand. Local raw/sidecars and duplicate screen checked; no immutable revision
or original-build/Alpha proof. Independent source/scope review approved with no findings; exact
native result/origin retained distinctly. Canonical commit `67c3cd489d686cb760d4fcfc857700078bd93818`
hash/parent/paths/content verified. Finalizer whitespace passed precommit; bounded validator passed
postcommit under explicit supervisor retention authority after a shell-sequencing error; timing
exception and fresh receipt checks: §E. Only Mage removed, ten unchanged siblings pending.
No gameplay/live-data/checker/test change, new debt or push. Exact selection/evidence/check limits:
§E; current owner session/publication frontier below stands.

**Previous source precision (2026-10-10):** `candidate-darkmega-warrior-abilities` documentation
recorded in `domain.md §5 item 96` / §7 under previously selected auto-approved precision authority.
Named qualified Darkmega Berserker/Defender corroboration; Fury duration/attack-speed/proc
impressions and internal block-mana disagreement remain explicit. F1's 13% proc, D11/D23 block
MP and approved taunt/healing stand. Retained raw/sidecars and duplicate-screen checked locally;
no immutable revision or original-build/Alpha proof. Independent source/scope review approved with
no findings; exact native result/origin retained distinctly. Finalizer fresh gates passed; canonical
commit `a53c005f09aac94baaa91b827a5efb9649b2a602` hash/parent/paths/content verified.
Only this handled selection removed; eleven unchanged siblings pending. No gameplay/live-data/
checker/test change, new debt or push. Exact selection/review/receipt limits: §E; owner frontier
below remains unchanged.

**Previous source precision (2026-10-10):** `candidate-darkmega-ranger-abilities` documentation
recorded in `domain.md §5 item 95` / §7 under previously selected auto-approved precision authority.
Named qualified Darkmega Sniper/Scout corroboration; approximate clone/trap reports and speculative
aggro remain report-only. F1/D21's 30-second Shadow Shooter, settled targeting and cooldowns stand.
Local raw/identity/sidecars and duplicate screen checked; no immutable revision/original-build proof.
Independent source/scope review approved with no findings; original native result/provenance
retained. Finalizer fresh gates passed; canonical commit
`2ce579e699e4260ddfa9742d339ffe36de71cf69` hash/parent/paths/content verified.
Only this handled selection removed; twelve unchanged siblings pending. No gameplay/live-data/
checker/test changes, new debt or push. Exact selection, receipts and source/check limits: §E;
current owner session/publication frontier below stands.

**Previous source precision (2026-10-10):** `candidate-darkmega-rogue-abilities` documentation
recorded in `domain.md §5 item 94` / §7 under standing auto-approval. Named qualified Darkmega
Assassin/Ninja corroboration; aggro-reset/interruption uncertainty and report-only values retained.
Full-stealth threat policy and Assassin key-3/no-separate-ultimate exception stand. Independent
source/scope review approved with no findings; original native result/provenance retained.
Finalizer fresh checks passed; canonical commit `0c7bf74d8348ec13d022940b2472230fb0142eba`
hash/parent/paths/content verified. Only this selection removed; thirteen unchanged siblings
pending. No gameplay/live-data/checker/test changes, new debt or push. Retained local evidence,
no immutable revision or original-build/Alpha proof; exact decisions, receipts/check limits: §E.
Latest owner frontier: only the fourteen queued inventory-3 candidates (fixed 4/4/3/3 packets),
then verified local handoff; no further selections or broader exhaustion claim. Parent creates
the requested harness-project-memory skill only after handoff; exact scope: HANDOFF.
Latest “After all that, push” conditionally authorizes this branch's publication only after that
workflow, verified handoff and skill creation; parent delegates push and verifies clean state /
local-upstream-remote equality separately. No leaf push now or broader Git authority.

**Previous source precision (2026-10-10):** `candidate-darkmega-world-boss-attribution`
documentation recorded in `domain.md §5 item 93` / §7 under auto-approved precision authority.
Named Darkmega qualitative boss/move/loot corroboration; “sometimes”, “usually” and
equivalent-at-gold retained. Hybrid reset/occupied-site rules and permanent claims stand.
Retained local evidence checked, no immutable revision or original-build proof. Fresh whitespace
and bounded-validator checks passed. Independent content review approved with no findings;
empty bound report recovered under supervisor authority, not a gate waiver. Finalizer fresh
source/Git/index/diff/queue and whitespace/bounded-validator gates passed; canonical commit
`474ec28621be8e4527e98941e0bdf57ad02eafec` content/hash/parent verified. Last selected entry
handled; pending-only queue deleted, non-selection research boundaries retained in HANDOFF/§E.
No gameplay/live-data/checker/test change, new debt or push; source/check/recovery limits: §E.
Further scoped precision screening required; no exhaustion claim.

**Previous source precision (2026-10-10):** `candidate-environment-drinks-attribution`
documentation recorded in `domain.md §5 item 92` / §7 under auto-approved precision authority.
Named Darkmega lemonade/lava and hot-chocolate/cold-water reports; Green Smoothie protection
remains untested speculation with the author's never-entered-dark-forest disclaimer. Existing
rules stand, no new behavior or debt. Retained local evidence, no immutable revision or
original-build proof. Independent content review approved with no findings; empty bound report
recovered under supervisor authority, not a gate waiver. Finalizer source/Git/index/diff/queue
and fresh whitespace/bounded-validator gates passed; canonical commit
`35e833b69bc073f32421409d16e5ba6d74834037` content/hash/parent verified. Only this item removed;
world-boss sibling unchanged/pending, no push. Source/recovery/check limits: `todo_decide.md §E`.

**Previous source precision (2026-10-10):** `candidate-treasure-spirit-attribution` documentation
recorded in `domain.md §5 item 91` / §7 under auto-approved precision authority. Named Darkmega
qualitative nearby-hovering compass/direction and hidden-gold/equipment corroboration only;
“decent distance” is not a numeric range, and personal lack of hints is not universal absence
proof. Global key-item policy and items 21/82 stand; no spawn, loot-adaptation or class-selection
change or new debt. Retained local evidence, no immutable revision/original-build proof.
Independent content review approved with no findings; empty bound report recovered under supervisor
authority, not a gate waiver. Finalizer source/Git/index/diff/queue and fresh gates passed; canonical
commit `bf571576db0940d583ab50ca8b2368ea075b6fc4` content/hash/parent verified. Only this item
removed; two siblings unchanged/pending, no push. Source/recovery/check limits: §E.

**Previous source precision (2026-10-10):** `candidate-spirit-bell-attribution` documentation
recorded in `domain.md §5 item 90` / §7 under auto-approved precision authority. Named Darkmega
portcullis/transparent-realm and atmosphere reports only; approximate 45 seconds does not replace
settled F8 30 seconds. Night visibility remains hearsay; no controls, realm or audiovisual change
or new debt. Retained local evidence, no immutable revision/original-build proof. Independent
review confirms source fidelity and preservation of F8; no findings. Finalizer source/Git/scope
and fresh gates passed; canonical commit `db9f36698599351fa5eb500ea73127b712b08b09`
content/hash/parent verified. Only this item removed; three siblings pending, no push.
Source/check limits: §E.

**Previous source precision (2026-10-10):** `candidate-divine-harp-attribution` documentation
recorded in `domain.md §5 item 89` / §7 under auto-approved precision authority. Named Darkmega
qualitative golden-door/loot-tower and approach/prompt/tune corroboration only; “Usually” retained,
not layout or shipped audiovisual proof. Global key-item and midnight re-closing policies stand;
no new behavior or debt. Retained local evidence, no immutable revision/original-build proof.
Independent content review approved with no findings; empty writer/review reports recovered
separately under supervisor authority, not a gate waiver. Finalizer source/Git/index/diff/queue
and fresh gates passed; canonical commit `b24b2e65bee3cc44b19588a75a9ce74f2337804e`
content/hash/parent verified. Only this item removed; four siblings pending. No push.
Source/recovery/check limits: `todo_decide.md §E`.

**Previous source precision (2026-10-10):** `candidate-sky-flute-attribution` documentation recorded
in `domain.md §5 item 88` / §7 under auto-approved precision authority. Named Darkmega qualitative
bird/pillar activation and blue-bird sky-island lift only; source “Sky flute” does not rename
Sky Whistle. Global key-item policy stands; no controls, acquisition, visuals, access-policy change
or new debt. Retained permitted local evidence, not immutable revision/original-build proof.
Independent content review approved with no findings; empty bound report recovered separately
under supervisor authority, not a gate waiver. Finalizer source/Git/diff/queue and fresh gates
passed; canonical commit `5bd6e15be2c786d95b48c6fef522915b99eb6d35` content/hash verified.
Only this item removed; five siblings remain pending. Queue metadata durably retained under
explicit supervisor authority, not sibling application. No push. Receipt/check limits: `todo_decide.md §E`.

**Previous source precision (2026-10-10):** `candidate-mana-pump` documentation recorded in
`domain.md §5 item 87` / §7 under auto-approved precision authority. Named Darkmega qualitative
absorption and inducer/officer/pump sequence only; no reduction value, stacking, guaranteed
four-arm layout, officer/mech identity or numeric combat behavior. Settled hybrid choices and
existing deferrals stand; no new debt. Retained local evidence, not immutable revision or
original-build proof. Independent content review approved; empty bound report recovered under
supervisor authority, not a gate waiver. Finalizer source/Git/diff/queue and fresh gates passed;
canonical commit `a212a74cfbe9c4961a4460d093da60bcc60b694f` content/hash verified. Only this item
removed; empty pending queue deleted. No gameplay/live-data/checker/test change or push.
Next: all-topic source-precision scan/review, not exhaustion. Receipt/check limits: `todo_decide.md §E`.

**Previous source precision (2026-10-10):** `candidate-petrified-village` documentation recorded
in `domain.md §5 item 86` / §7 under auto-approved precision authority. Named Darkmega qualitative
witch-curse/restoration corroboration only, not a universal NPC-service lock, witch placement
guarantee or reset rule. World-shared resolved curses and existing resets stand; no new behavior
or debt. Retained local evidence, not immutable revision/original-build proof. Independent content
review approved; empty bound artifact recovered separately under supervisor authority. Finalizer
verified source/Git/diff/queue and fresh whitespace/bounded-validator gates. Canonical commit
`ce536ec6f2a47bcd87421c72ff0d046d03cc3935` content/hash verified; only this item removed,
mana-pump queued/unapplied. Pre-existing unrelated queue edits preserved; no push.
Selection/recovery/check limits: `todo_decide.md §E`.

**Previous source precision (2026-10-10):** `candidate-possession` documentation recorded in
`domain.md §5 item 85` / §7 under auto-approved precision authority. Qualified Darkmega
big/red/stronger possessed-mob and hostile-villager respawn/until-portal-destruction reports only;
portal healing remains speculative. Curse persistence/resets and hostility exceptions stand.
Retained local evidence, not immutable revision/original-build proof. Independent content review
approved; empty bound artifact recovered separately under supervisor authority. Finalizer verified
source/Git/diff/queue and fresh whitespace/bounded-validator gates. Canonical commit
`03cd92ab4c339053da7b893910bfbe73ac8d8220` content/hash verified; only this item removed,
two siblings queued/unapplied. Documentation only, no new behavior/debt or push;
selection/recovery/check limits: `todo_decide.md §E`.

**Previous source precision (2026-10-10):** `candidate-circle-power` documentation recorded in
`domain.md §5 item 84` / §7 under auto-approved precision authority. Named Darkmega ember/brazier
and top-left buff-bar report only; uncertain effect, not support for or revision of settled D6
+10 % attack / +10 % max HP. Duplicate-screened items 1–83; retained local evidence, no immutable
revision or original-build proof. Independent content review approved with no findings; empty
writer/review artifacts recovered under supervisor authority. Finalizer source/Git/scope/queue
and fresh whitespace/bounded-validator gates verified. Canonical commit
`cad81bbfbd48bc43fbc4a08a89e1aeb8bb491b5c` content/hash verified; only this item removed,
three siblings queued/unapplied. Documentation only, no new behavior/debt or push.
Evidence/recovery/check limits: `todo_decide.md §E`.

**Previous source precision (2026-10-10):** `candidate-mage-tower-barrier` documentation
recorded in `domain.md §5 item 83` / §7 under auto-approved precision authority. Named Darkmega
mage/crystal-tower, all-crystal blue-forcefield clearing and qualitative boss/crystal loot
corroboration only; no guaranteed population, loot counts, reset or difficulty mapping.
Saved-world persistence and settled hybrid choices stand; no gameplay/live-data/checker/test
change or new debt. Independent content review approved with no findings; empty bound artifact
recovered under supervisor authority. Canonical commit `8ddea40b9138c1e07b3aaef75c3ff9df5c929ea3`
verified; finalizer checked source/Git/scope/queue and fresh whitespace/bounded-validator gates.
Only this item removed; four siblings remain unapplied. Source/recovery/check limits: §E. No push.

**Previous source precision (2026-10-10):** `candidate-npc-location-dialogue` is handled in
`domain.md §5 item 82` / §7; canonical commit `391716e2fd93975d4e7b8bf863f4d9aad98c1c95`
verified. Independent content review approved with no findings; empty bound artifact recovered
separately under supervisor authority. Fresh finalizer source/Git/scope/queue/whitespace/validator
checks passed; only this item removed, five siblings remain unapplied. Qualitative Darkmega
town/adventurer hint corroboration only, no fixed corpus, frequency, guaranteed disclosure,
mission reveal or population rule. Items 21/54 and hybrid choices stand. Retained local evidence,
not immutable revision or original-build proof; no gameplay/live-data/checker/test change or
new debt. Exact selection, recovery and check limits: `todo_decide.md §E`. Not pushed.

**Previous source precision (2026-10-10):** `candidate-friendly-npc-presentation`
is recorded in `domain.md §5 item 81` / §7 as Darkmega's qualified light-blue-name/waving
attribution only. “Should” and adjacent “usually”/setting context remain qualified, not a
hostility detector or numeric chatting-range contract. Canonical commit
`b2db261c46ce65d999556a1dc9f35bfaffb205ba` verified; independent content review approved.
Empty bound artifact recovered separately under supervisor authority; finalizer Git/source/diff/
queue and fresh whitespace/validator checks passed. Only this item removed; six siblings remain
unapplied. No gameplay/live-data/checker/test change or new debt; no push. Evidence/limits:
`todo_decide.md §E`.

**Previous source attribution (2026-10-10):** `candidate-sleep-darkmega` is handled in
`domain.md §5 item 80` / §7 as named sleeping-bag healing/time-flow corroboration only;
canonical commit `d662a2099972136934dd1c1cfe92d49b8e2a605e` verified. Independent content review
approved; missing bound artifact recovered under supervisor authority. Fresh finalizer Git/source/
diff/queue/validator checks and recovery limits: `todo_decide.md §E`. Only this entry removed;
seven selected candidates remain unapplied for distinct workers (`docs/todo_handle_reconciled_items.md`).
Rates/units, original-build proof and hybrid inn rules unchanged; no gameplay, live-data change
or new implementation debt. No push authority or publication.

**Previous source-attribution items 75–79 (2026-10-10):** Flight Master, free friend-flight
UI/contextual duration, potion movement/sitting to eat, shrine/flute and supplier/shop reports
recorded in `domain.md §5` / §7. Independent recording review and parent source/diff/Git/validator/
boot acceptance complete; the new batch's incorrect Oct09 labels are corrected to Oct10.
All five handled; empty pending queue deleted. Exact selections, item commits and check limits:
`todo_decide.md §E`. No gameplay, live-data or hybrid rule change; no new implementation debt.
Remaining research and next-scout parent gate: `docs/HANDOFF.md`. No publication authority or
whole-topic completion.

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
