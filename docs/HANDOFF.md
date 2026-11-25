# Handoff — current pending work

## Host memory exhaustion — do not restart the full local gate

`fbd39ca`'s post-commit LinkML suite was interrupted at 23:48:18 UTC on Nov 24, coincident with a global OOM killing Python 3.12 (13.3 GiB resident, only 124 KiB swap free). Its terminal scope also stopped. The last test logged was `StructuredWorldTests.test_same_contract_metadata_mutations`; no evidence identifies the allocating test or object. The later 06:39 UTC power-off was requested via `systemctl`, not an immediate kernel reboot. The worker recorded exit 143, unknown command exit, and missing `drained.json`; the shell's zero is not a pass. Preserve the attempt and detached checkout. Before any new local full gate, isolate its RAM/swap consumption and address the missing cleanup proof without fabricating a receipt. Evidence: `/home/theta/.pi-game-dev/recovery/pixlnd-host-oom-20261125.z4x84QjR/`.

## Generated-domain baseline — reconcile before broad regeneration

A fresh render of the pre-Task 8 schema differed from 35 other checked-in scripts.
Task 8 applied only the controller documentation delta attributable to its schema change.
Reconcile the historical generator baseline separately before any whole-directory regeneration;
no such work is selected. Evidence:
`/home/theta/.pi-game-dev/recovery/pixlnd-task8-restart.CJzfJiF9/resume.b8npyQ/fixes/render-comparison.txt`.

## Schema/native enforcement — retained ceilings and unselected follow-ups

The [coverage map](ontology/phase-1-coverage.md) retains source-pinned structural verification
and historical family qualifications; green structural checks do not remove these ceilings.
Existing working GDScript remains in place; ongoing GDScript↔YAML drift enforcement is unselected.
No gameplay/runtime/save/raw-instance change, full Item payload, C# cutover or new storage/numeric
lookup algorithm follows from schema authoring.

### Save and Item enforcement

[Current-save coverage](ontology/phase-1-coverage.md#task7--current-save-structures-no-runtime-cutover)
and the [save consumer mapping](ontology/consumer-integration.md) retain exact raw-integer versus
Godot-parsed-number distinctions and native key/body, conditional cardinality, Boolean/expression,
absence, uniqueness, integrity and FK limits. Structural admission is not full native admission,
parser/wire equivalence or runtime/lifecycle proof. Keep current-rule invalid-save/original-file
protection unchanged; any consumer alignment needs separate authority.

Canonical Item defines active placed cubes, count=list length and a scalar contextual weapon-type
link. Existing type/sub-type fields, 16/32 limits and formulas remain unchanged. The coverage map
retains array/count/material native enforcement gaps and qualified field-oracle/source receipts;
full save-graph/reference-metadata equality is not claimed. Native admissions are not gameplay
permission; no gold exception or new spirit whitelist follows.

### Native Mermaid boolean-range projection

The unchanged native Mermaid generator omits the `saved-mob.special` and
`saved-reward.classes` relationship edges when their optional non-null ranges live
inside boolean slot expressions. The declarations and native validation still retain
the references; the regenerated views remove only those two edges/click links. Evidence:
`/home/theta/.pi-game-dev/recovery/pixlnd-task7-execution-20261122.x3WwXE/publication/mermaid.log`
and exact generated diff. No schema weakening or custom generator repair is selected.
Qualify branch-range rendering separately before using generated diagram edges as a complete
relationship inventory.

### Consumer colour alignment

Canonical configuration colours require mandatory # and exactly 6 or 8 hex digits;
all 25 scoped source values conform unchanged. Existing consumer checks accept broader forms.
Consumer/runtime/parser alignment remains separately selectable deferred debt; no raw-data change
follows.

### Pinned interpreter and deprecated ReferenceValidator

Avoid asynchronous faulthandler sampling on the pinned Python interpreter; its retained diagnostic
core faulted in the dump thread, not a diagnosed schema failure. Underlying cause remains
unselected/unresolved. Evidence under
`/home/theta/.pi-game-dev/recovery/pixlnd-phase1-execution-20261106.bT2ZoyM5/`:
`task6-active/review-round-0.MFzAgn2m/fix-round-1/vr-partition-1/cold-baseline-diagnostic-1/parent-crash-correlation.md`.
No instrumentation, SDK or interpreter repair is selected.

Installed deprecated `ReferenceValidator` has source-only hazards: class slot conditions sit inside
its `is_a` branch, and numeric equality uses a loop variable while skipping zero by truthiness
(`referencevalidator.py:958–1001`). No executable reproduction or current JSON Schema/gameplay
failure is claimed. Evidence: the recovery's `expressions-and-candidates.md` and pinned consumer
sources. No SDK repair/probe is selected; qualify separately before future use.

### Native membership and uniqueness

Task6 required non-offhand class-weapon moveset membership is authored as 15 precise predicates
and survives get/induced metadata; the pinned JSON Schema backend emits only repeated empty
`entries` checks and admits all 15 missing-weapon witnesses. Keep the declaration/canonical rule;
native membership/FK enforcement remains a measured ceiling, not gameplay permission or a
custom-admission mandate. Qualified same-oracle deletion/no-effect, fresh D/M0 and retained
full-source C evidence:
`/home/theta/.pi-game-dev/recovery/pixlnd-phase1-execution-20261106.bT2ZoyM5/task6-active/review-round-1.fCDI8SZH/fix-round-2/phase-b/review-package/`.

Native exploration uniqueness is declared but unenforced. Preserve raw JSON, source signedness/ABI
distinctions, symbolic values and overhang qualifications in the coverage map. No native
integrity/full-wire enforcement or replacement validator is implied.

The [pending sandstone yield finding](#deposit-yield-outside-its-declared-reference-range)
retains its original reference-check evidence at
`/home/theta/.pi-game-dev/recovery/pixlnd-linkml-csharp-execution-20261104/resume-dual-20261105.tF8fVc/continuation-3.RQ68gs/parent-reference-check.h5lv08/targets-fixed.json`.

## Python/Bash limits — deferred cleanups and follow-ups

Current limits under `scripts tests skills monitors tools`: 600 lines/file,
100 lines/function, cognitive complexity 15, no baseline or inline exemption.
Shell Python remains 3.14; locked LinkML uses Python 3.12 through `UV_PYTHON`/uv.
Preserve existing test behavior when refactoring; source pins must match current files.
The optional local refactor manifest is `docs/superpowers/2026-11-15-python-bash-limits-manifest.md`.

Owner choices/follow-ups, not Task 3 implementation scope:
- Godot in the dev shell inherits an incompatible host `LD_LIBRARY_PATH` (`GLIBC_2.43`).
  Run gates/pushes under `env -u LD_LIBRARY_PATH`; host-profile versus dev-shell repair
  remains unselected.
- Checker discovery covers only the listed directories. `git ls-files` changes
  symlink/non-Git-scratch behavior; nested defs are scored separately, module/top-level
  code is unscored, and Bash `[[ a ]] && c` scores 2. Resolve the nested-def policy
  wording before changing these behaviors.
- Checker hardening: malformed UTF-8, absent `shfmt`, unexpected shfmt JSON and deep
  recursion produce tracebacks. Tests lack exact diagnostic-prefix/Python parse-error
  line/no-argument-exit assertions. Line counting duplicates `check_sizes.py`; shell
  Python is not explicitly pinned to one of the two propagated 3.14 paths; `BASH_LOOPS`
  also includes `CaseClause`.
- Cosmetic test debt: long `verify_*` parameter lists, some helpers after classes,
  redundant site-assembly `oracle`, local `assert_declared_root` imports, ruins-value
  import order, local-difficulty indentation, repeated scalar-typing comment, `_tuple`
  dispatcher and unwrapped calls. No behavior-changing cleanup is selected.

## Skill smoke check — stale inventory

`python3 skills/check.py` fails with inventory mismatch
`{'verify-pixlnd-nvidia-launcher'}`: the skill is absent from `EXPECTED`; no gate
invokes this checker. Owner must select the inventory update and possible gate wiring.

## Separate C#/native preparation

Preparation remains unqualified and parked; no live-quality operation or structural
cutover is selected. Its evidence is under
`/home/theta/.pi-game-dev/recovery/pixlnd-linkml-csharp-execution-20261104/resume-dual-20261105.tF8fVc/native-adapter-timeout-recovery.d6WWiF/`,
including `parent-option-check.oplEyH/assessment.md`.

## Native map capture and respawn — unresolved characterization

These are separate retained findings, not authorized Task 3 fixes:
- Composed capture can finish bootstrap/HUD/cursor/map/inventory checks and four images
  while the `world advances naturally under map` check fails. Cause and ordinary-game
  applicability are unclassified; a passing print-only observation does not establish
  reliability or resolve the failed combined capture.
- Composed frames show left-side repeated white text traces and initial terrain pop-in.
  Origin/applicability are unclassified, not a proven GPU or new gameplay regression.
- Native `live map does not prevent ordinary respawn` fails in the retained pre-Task9
  baseline. Clock/callback cause is undiagnosed; later passes do not resolve it. No
  timing/tolerance/physics remedy or ordinary-error waiver is selected.

Evidence root:
`/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task9-7446c92.Or5BJ5/usage-continuation-20261104T111714/`.
Use `final/`, sibling `clock-observation/`, `native-close-original/`,
`original-close-observation/` and `corrected-fixture/green-results.json` as applicable.
Select a bounded disposition separately; preserve actual failures and capture qualifiers.

## Staged native touch panel/HUD overlap

Staged touch inventory/skills/shop frames overlap HP/MP/stamina bars with titles/rows.
Ordinary-game and Android-hardware applicability are unknown; no layout/physics fix is
selected. Manual-physics frames do not certify natural simulation timing. Evidence:
`/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task8-7446c92.U2ycOi/reconnect-20261103/tail-c735-20261103/`;
use its native UI captures and retained parent inspection receipt, not a hardware claim.

## Native windowed fresh-jump assertions

Windowed `desktop fresh grounded jump succeeds` and `native fresh grounded jump succeeds`
fail on the retained pre-refactor upstream baseline. Cause is undiagnosed; fix deferred.
Do not identify this with the parked collision issue or change physics/input/tolerances
without separately selected reproduction and disposition. Evidence: `origin-baseline/`
under the Task8 `reconnect-20261103/tail-c735-20261103/` evidence root. Preserve exact
baseline pins, test body, failed logs and the separate synthetic/hardware qualifications.

## Deferred cognitive complexity: arrival-resource-recheck

The owner-approved narrow exception remains in
`game/entities/test_android_controls.gd::_competing_request`:
`# @cognitive-defer arrival-resource-recheck`, current score 30, target 15 or less.
Preserve both class-skill/dodge arrival orders, remaining stamina 0/75, busy/dodge
states, checks and cleanup. Refactor to the real `Abilities.busy() -> bool` interface
without production changes, then remove the flag/narrow exception and run escape-marker
regressions, affected tests and the full gate. No wider exemption is authorized.

## Mutation harness caller budget

Before reuse, budget three possible 681-second Godot children per selected row plus
Nix/cleanup; a 900-second outer budget is not a worst-case ownership guarantee. Keep
actual owned waits/cleanup proof; no new mutation batch is selected. Exact harness and
boss-exit disposition are under
`/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task5-boss-test-rebuild.frtFvi/owner-exit-disposition.08xs3F/`.

## External headed-comparison wrapper

The optional wrapper cannot safely pass undefined `outputPathMapping` to
`state.set('capture-result')`. If separately reused, omit absent fields or normalize
JSON values and verify the metadata path. Existing successful images/reports remain
usable; this bookkeeping defect is not a failed capture or headless-nonexit remedy.
Evidence: `/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task5-headed-compare.iqIM96/retry-1/wrapper-failure/`.

## Boss-exit capture — unmodified-target qualification

The recorder depends on a cooperating fixture's readiness/registration protocol;
unmodified Godot has no such protocol. Startup ownership, adoption and bounded cleanup
are not qualified for the game. A matched failing-thread trace/discriminator is absent.
Select and verify the unmodified-target path before reuse; do not alter game code or
infer readiness from fixture tests. Current external-tool contract and exact evidence:
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/c2911a8f-6bce-4d35-b946-218ca7fe723a/task5-recorder-r1-finalized/`.

## Inventory read-only API errors

Explicitly read-only public inventory containers expose pre-existing native error paths:
read-only equipment can lose a removed bag item despite reporting failure; a read-only
bag can leave the new item in the bag and also equip it, without returning the displaced
item, while reporting success. Normal mutable-container gameplay is not shown to fail.
No rollback/admission fix is selected.
Evidence: `/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task2-parent-inventory-probe.QW2mE1/`.

## Natural terrain and optional guidance — native acceptance

Implementation, independent source reviews and headless checks are accepted; full native
acceptance, shutdown diagnosis, streaming/contact/UI characterization and HUD movie are
pending. Do not restore external-connection walkability requirements. Keep the paired
player-facing changelog pending with the movie; reconcile its code-hash naming with the
single-final-commit requirement when that follow-up is selected. Evidence:
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/artifacts/object-guided-paths-01a181dc/`
(`async-native-parent-disposition.md`, `async-native-independent-review.md`,
`async-final-rerun1-result.json`). Debt: [implementation backlog](ROADMAP/todo_implement.md).

## Deferred Godot collision issue — owner-parked

Translated flat-floor capsule setups disagree on shallow contact/downward sweep, with
about 0.241565 m penetration in one case. A direct physics-query replay reproduces this
without controller/rebasing/AI history, but private numerical divergence remains unknown.
Keep the separately verified floor-only step-up and logical/native frame corrections.
No epsilon/floor forcing/coyote-time/adaptive-input/margin/geometry/default change is selected.

Current blocker: no matched DWARF/private types or failing-thread trace. The external
observer v2 is unsealed; its host fixture uses parent PID 100 without mocking
`observer.os.getpid()`. A test-only correction and fresh review must be selected before
parse/load/ownership/phase use. Address-only symbol lookup works; the cast expression
does not. Do not force architecture, truncate pointers or treat symbols-only metadata
as a phase trace. GDB 17.2 is already dev-shell-only; do not provision it again.

Use the exact stock Godot 4.7.2 ELF/source pins and original twelve cold queries from
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/artifacts/initial-encounters-01a16525/`.
Further diagnostics require separately selected bounded steps, current pins, independent
review and owned-process/cleanup proof. No debug-symbol download, custom engine build,
helper instrumentation, arbitrary inferior calls or engine upgrade is approved.

## Android touch — characterization/publication boundary

Current hardware/checklist limits are in the
[Android profile](../ontology/domain/controller-profiles.md#android). Broader device
characterization/render-cost measurements are optional separately selected work, not a
combat-slice prerequisite. Do not infer checklist passes or provision SDK/ADB/export
tooling. Android push/publication and changelog backfill remain unapproved. See the
[controls backlog](ROADMAP/todo_implement.md#device-independent-controls-documentation-only).

## Source walkthrough — dormant

No source item is selected; research is not exhausted. A separate owner request is
required to resume the source walkthrough or its publication. Silk/Spinning Wheel
quantities remain HOLD; retained/withdrawn leads are unapproved. Existing gaps are in
[§7](../ontology/domain/7_Open_points_for_validation.md#7-open-points-for-validation) and
[validation-contract debt](ROADMAP/todo_implement.md#validation-contract-documentation-approved-implementation-unauthorized).
Follow [lessons](lessons.md): public inspected article text only; no private authenticated
DOM/account/token material. Task 3 permits only its scoped retained-source use.

## SaveData malformed equipment-key boundary

A structurally valid ring under an integer equipment Dictionary key triggers a native
int/String comparison error while `validate_character` errors remain empty. This is a
raw-Dictionary API case, not a normal JSON-loader/capture-writer result; atomic-write
consequences are unqualified. A separate fail-closed characterization/disposition is
needed; no incidental guard is selected. Evidence:
`/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task4-7446c92/safety-extra-original.log`
and sibling `safety-extra-comparison.json`, case `integer-equipment-key`.

## Deposit yield outside its declared reference range

Scope: `ontology/instances/deposits.json` vs `ontology/schema` `deposit-source-row.yields`
(range `ingredient`). The sandstone deposit (aid 134) yields `"sandstone"`, which is a
material id, not an ingredient id; the old GDScript validator never checked deposit yields.
Found by the generic catalog-reference check in `scripts/ontology_bind.py` (branch
`feat/generated-domain-model`), which tolerates exactly this one diagnostic as `KNOWN_FINDINGS`.
Next: owner decides between widening the range (ingredient or material) and changing the data;
then remove the `KNOWN_FINDINGS` entry.

## Older local gate — unresolved lifetime and missing exit receipt

The prior local full gate on tree `0421db0a4ea3cc4f8d5d4248c04cc774464cfe0f` stopped
in `ontology-schema-tests` without an exit receipt. The kernel's OOM kill was for a different
process. This is separate from the host OOM/lost-drain finding above; the newer off-host Quality
pass establishes neither this old command's exit nor its lifetime/cleanup proof. Preserve old
attempts, guardians and worktrees; no cleanup or expensive local replay is authorized.
Retained logs (`remaining-ci/`, `focused-ci/`, `ci-run/quality-job.log`) and command matrix:
`/home/theta/.pi-game-dev/recovery/pixlnd-linkml-cap-resume-20261121.JMYhzg/`.
Do not merge temporary diagnostic commits `1a093a1` or `99716b1`: they replace
`.github/workflows/quality.yml` solely for focused CI execution. Historical failed/partial
receipts remain immutable, not retroactively green.

## Fresh-checkout Godot runs — retained autoload characterization

On a clean export of `8ce6932`, `godot --headless -s ontology/validate.gd` prints `ontology valid`
and exits 0, then logs `SCRIPT ERROR: Invalid type in function '_rows' … Cannot convert argument 1
from Dictionary to Object` (`game/domain/domain.gd:123`) and `Nonexistent function
'default_ruleset' in base 'Nil'` (`game/ontology_db.gd:23`); identical in this worktree.
The background gate for that tree (`.git/pixlnd-gate/c2960ca1….log`) failed earlier still:
`godot --headless --import` aborted (exit 134, `Parameter "singleton" is null`,
`editor/editor_node.cpp:6618`), so the gate never reached the LinkML tests. The
current clean Ubuntu CI checkout passed `scripts/checks.sh`, including import,
ontology validation and boot; it did not reproduce the local abort.

## Godot import shutdown crash — owner-parked

Owner explicitly chose to leave this crash unresolved while preparing the Task 7
checkpoint. No further probe, engine patch/build, retry, CLI substitution or error
suppression is selected. Keep its evidence and ordinary gate failure behavior intact;
revisit only on a separate owner request.

The normal `cc9aa25` checkpoint gate reproduced the minimal runner fixture's import
abort. Its matched preserved core (PID139070, `godot --headless --import`, exact
fixture cwd/binary) places the fault in `EditorHelp::_reload_scripts_documentation`
on its script-doc regeneration thread while the main thread is already tearing down.
This is an editor-lifecycle failure, not a game assertion or timeout kill. Pinned source
shows static doc callbacks surviving cleanup; `EditorNode::is_cmdline_mode()` returns false
for a destroyed singleton, permitting script-doc regeneration against the cleared filesystem.
Import already selects the intended documentation-skip mode; no supported caller flag was
found to enforce the missing lifetime boundary. Fresh isolated fixtures and one inherited
host-state fixture passed, which does not establish reliability or close the failure. The
precise private pointer/interleaving was not observed; no engine fix is yet implemented.
No retry/error suppression/CLI substitution is accepted.
Evidence: `import-preserved-core-diagnosis.md`, `import-host-state-discriminator.md` and
`import-pinned-source-diagnosis.md` under
`/home/theta/.pi-game-dev/recovery/pixlnd-blocker-repair-20261122.LXbafg/`.
If separately reselected, a causal engine correction needs late-callback/shutdown
regression evidence and complete fresh class/resource import plus a native consumer,
with strict error detection. No such engine change is part of Task 7 preparation.
