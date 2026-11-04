# Handoff — pending continuation

## Task9 composed native capture interval — unclassified follow-up

The new external real-main capture helper exited **1** with exactly
`world advances naturally under map` false, no script/engine diagnostics. All
bootstrap/HUD/cursor/map/inventory checks and four actual1280×720 composed PNG
writes completed; this is a failed combined capture, not a passed native group.
Own Godot PID586228 (timeout586227), X11/Vulkan1.4.329/NVIDIA MX450, 6.717s,
2026-11-04T12:09:09+01:00. Candidate396 source manifest
`b7504182b8805d596825fc02e8085457cec097e9cc0e3f3723322b1e7b42c416`
was unchanged before/after. The helper reads elapsed, waits an ignore-time-scale
0.2s timer, then tests elapsed increase; actual clock/callback chronology was
not captured. No engine/collision/clock cause or production regression is
established, and no wait/tolerance/physics remedy is authorized.

Evidence: `/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task9-7446c92.Or5BJ5/usage-continuation-20261104T111714/final/`:
`capture-result.json`, `composed-native/native.log`, all four PNGs,
`capture-failure*`, source pins and actual collected wait. A separately selected
print-only observation preserved all original checks/waits and completed actual0
(own Godot594138, 6.751s): physics frames32→40, elapsed0.5166667→0.65,
process frames3→4, 202398µs wall interval, time_scale1, physics enabled/can-process,
same main/world state identity. New four composed PNGs and raw records are in
sibling `clock-observation/`. The failed interval was not reproduced, so no cause
or fix is established and its actual1 remains failed/unclassified. Parent allowed
progression with this bounded positive evidence, not a general reliability claim,
ordinary-error waiver or acceptance of the residual. Next action: separately
selected capture-interval disposition if needed; no further capture/observer/
clock remedy is selected during this refactor.

## Task9 composed capture visual traces — unclassified follow-up

Parent opened all four actual1280×720 composed PNGs from the failed capture above.
`inventory-after-map.png` and `closed-hud.png` show diagonal/repeated white
status/terrain-text traces at the left around x0–190/y450–515; `boot-hud.png`
shows initially incomplete terrain/pop-in. HUD bars/hotbar, map outline/You
marker/Close, inventory and composed world are visible. Origin and ordinary-game
applicability of the traces remain unclassified, not a proven Task9 regression,
GPU diagnosis or Android hardware result. No redraw/layout/physics or other
unrelated remedy is authorized. Next action: separately selected visual/source
disposition if needed; preserve these PNGs and parent inspection receipt. Existing
staged touch/HUD overlap and optional native guidance scopes remain separate.

## Task9 original native map respawn observation — unclassified follow-up

An actual Task9 BASE `edbc67ea0cf841af7e86717af252a61fb4470e40` native map run
failed `live map does not prevent ordinary respawn`, alongside a separately
corrected Close fixture failure. A print-only BASE observation repeated both
failures. No script/engine diagnostics; own Godot PIDs556064/564633, actual1 at
40.390s/42.077s on pinned Godot4.7.2, X11/Vulkan1.4.329/NVIDIA MX450, unchanged681s.
The test waits35 physics frames after lethal DOT, then an ignore-time-scale2.2s
timer; Player's respawn uses the existing default scaled2.0s timer. Actual clock
state/completion chronology and cause were not measured; no clock/timing/tolerance
remedy is authorized. This demonstrates occurrence before Task9, not before the
whole refactor or universal reproduction.

Later H2 and corrected original/current native runs did not fail respawn, but
those passes do not retroactively resolve/classify the earlier failures. Preserve
all failed receipts; no additional native/ordinary gate exemption follows. Next
action: separately selected bounded disposition/characterization if required;
do not actively pursue it during this refactor.

Evidence root: `/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task9-7446c92.Or5BJ5/usage-continuation-20261104T111714/`.
Original raw logs: `native-close-original/native.log` and
`original-close-observation/native.log`; source/engine/actual waits in their
`original-native-*` / `original-close-observation-*` records. Later native
observations are in `corrected-fixture/green-results.json`, not a retrospective
waiver of these failures.

## Staged native touch panel/HUD overlap — follow-up deferred

Parent inspected all24 composed Task8 panel captures and observed HP/MP/stamina
bars over the left title/first rows of touch inventory, skills and shop in open
and live-expired phases. `native-ui/captures/touch-inventory-open.png` obscures
Inventory title/coins near y280–345 in the1600×900 viewport (own PID3233826).
Origin and applicability to ordinary gameplay are unknown: this may be staged
fixture/layout behavior, not a proven Task8 regression or Android hardware issue.
No fix, replay or additional comparison is selected; retain a separately scoped
follow-up after source/image disposition. These manual-physics captures prove
composed rendering, not natural simulation clock rate; do not claim visual issues
absent or the complete native group passed.

## Native windowed fresh-jump assertions — demonstrated before refactor, fix deferred

The windowed stun/input test fails `desktop fresh grounded jump succeeds` and
`native fresh grounded jump succeeds` under the sampled native conditions. The
owner-selected single reproduction also demonstrated both failures using the
actual latest pre-entire-refactor `origin/master`, queried2026-11-03T15:58:33+01:00:
`7a940d2b5e985ec4315da7d63278ad5831c6c718` (2026-10-29, async terrain/optional
guides), before the quality-gate and source-refactor commits. Do not confuse this
with pre-Task8 `9b6fc626`, which already includes Tasks1–7.

All332 historical source entries and the original test body were preserved; the
external executed copy adds only the same own-PID/backend print as prior controls.
Original flake/lock/project and pinned stock Godot4.7.2 ELF were verified. The run
used X11/Vulkan1.4.329/NVIDIA MX450, isolated saves and unchanged681s deadline,
exited1 after250.270s with exactly those two failures and `stun input FAILED (2)`,
without script/engine diagnostics (own Godot PID3336655). Actual1 remains failed,
not a native pass. Earlier current/pre-Task8 controls also remain failed receipts.

Cause is undiagnosed; this does not identify the parked collision issue, prove
universal reproducibility or establish Android hardware behavior. Per the owner,
record the demonstrated pre-refactor occurrence, defer its fix and continue the
refactor's next steps without a physics/timing/tolerance/assertion remedy. No
blanket failure waiver follows; the separate staged HUD overlap stays unclassified.
Evidence: Task8 `reconnect-20261103/tail-c735-20261103/origin-baseline/`
(`remote-query.log`, original archive/source proof, toolchain and real
`run/{result,classification}.json`, `run/native.log`). Host-only simulated PID-1
preflight output is separate and is not reproduction evidence.

## Deferred cognitive complexity: arrival-resource-recheck

Owner-approved Task 8 exception: defer reducing the arrival-order resource check to
native cognitive complexity **15**. Keep both class-skill/dodge arrival orders, expected
remaining stamina **0 / 75**, busy/dodge states, check coverage and cleanup. Test-equivalence
may follow the real `Abilities.busy() -> bool` interface; production behavior is unchanged.

Required searchable escape flag: `# @cognitive-defer arrival-resource-recheck`, immediately
before `game/entities/test_android_controls.gd::_competing_request`. The narrow shared-checker
support and flag placement are implemented in the current refactor: the root-level case
currently measures **30**, visibly reported as deferred. No whole-file, whole-runner or
production exemption is authorized. All other cognitive limits, **600**
lines/file and **100** lines/callable remain enforced. The checker must report the deferred
score visibly; this is not an unconditional under-15 result.

- [ ] Refactor this specific check/case to native cognitive complexity **15 or less**, preserving
  the original scenarios, independent expected values and supported interface/read/error/check/
  cleanup behavior; do not resume arbitrary temporary-object workaround experiments by default.
- [ ] Remove its flag and the corresponding narrow checker exception after verification; run
  the escape-marker regressions, affected tests and full quality gate. Remove this pending
  entry only once resolution is verified.

## Mutation harness caller budget — before future reuse

The standalone mutation harness can run three 681-second Godot commands per selected row
plus Nix overhead. A successful 900-second outer invocation is not a worst-case ownership
guarantee. Before any separately selected reuse, budget the whole owned unit and retain
actual child wait/cleanup evidence; do not lose the Python waiter as in the archived batch.
No further mutation batch is required for the current refactor. Original failed/unknown
receipts and the owner-accepted boss-exit disposition are retained outside tracked source at
`/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task5-boss-test-rebuild.frtFvi/owner-exit-disposition.08xs3F/`.

## External headed-comparison wrapper — optional result metadata failure

The capture child completed and its saved report/images remain usable, but the external
ignored `task5-headed-retry-workflow.js` then failed `state.set('capture-result')` because
`outputPathMapping` was undefined rather than a JSON value. This is orchestration bookkeeping,
not a failed game capture or a fix for the original headless nonexit. The failed workflow
receipt remains unchanged; actual final images/logs were independently inspected by parent.
Evidence: `/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task5-headed-compare.iqIM96/retry-1/wrapper-failure/`.
Before reusing that script, separately correct/check optional-field serialization (omit absent
fields or normalize them to JSON values). No capture replay, gameplay change or Task5 acceptance
is authorized by recording this finding.

## Boss-exit capture — unmodified-target integration remains unqualified

The current external recorder requires a cooperating harmless fixture to publish startup
readiness and wait for registration. That protocol is not present in unmodified Godot;
do not add it to game code or treat fixture qualification as game capture readiness.
Loss before spawn/ready notification, initial ownership failure and unprovable adoption
remain unqualified; rejecting an unsafe signal does not guarantee descendant cleanup.

Before any game reuse, separately select and verify an unmodified-target ownership,
registration and bounded-cleanup path. A trace of an actual failing game thread and a
matched discriminator for its origin are still missing. The original two 681-second
failures, earlier unknown result and later natural exits remain distinct and unresolved.
No further fixture/game run, gameplay remedy or Task 5 acceptance follows from this note.

Scope, residual limits and the qualified external-tool evidence are preserved in:
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/c2911a8f-6bce-4d35-b946-218ca7fe723a/task5-recorder-r1-finalized/`.
Keep prior executed versions and failed receipts immutable; do not reuse an older recorder
merely because the newer cooperating-fixture paths have separate qualification.

## Pre-existing inventory read-only error paths — deferred

Bounded Task 2 probes observed existing behavior when public inventory containers are
explicitly made read-only:

- A read-only equipment Dictionary makes equip report failure after the bag item has
  already been removed, leaving it in neither bag nor equipment.
- A read-only bag Array during replacement emits two Array errors but still reports
  success and notifies; the new item remains in the bag and also becomes equipped, while
  the displaced item is not returned to the bag.

These error paths predate the Task 2 refactor. No ordinary mutable-container gameplay
failure is established. Resolution is deferred under the owner's instruction and is not
required for the refactor. Retain this pending entry; do not bundle rollback or read-only
admission changes into the quality-gate refactoring.
Original/candidate proof, explicit read-only setup and mutable controls:
`/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task2-parent-inventory-probe.QW2mE1/`.

## Natural terrain and optional guidance — deferred native acceptance

Implementation, independent source reviews and headless verification are complete; full native
acceptance remains unestablished. The windowed family check timed out after scene cleanup and its
completion message; the shutdown cause is unknown. Material streaming hitches and native contact/UI
coverage limitations also remain unclassified, not established production regressions.

The shutdown investigation, further windowed checks and HUD demonstration movie are deferred.
Resume only with a separately selected scope; do not restore external connection walkability
requirements. Keep the paired player-facing changelog pending with its movie; resolve the usual
code-hash filename convention against the single-final-commit requirement before that follow-up.

Machine-local evidence (preserve before moving machines):
`/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/artifacts/object-guided-paths-01a181dc/`.
Read `async-native-parent-disposition.md` and `async-native-independent-review.md`; the accepted
headless packet is `async-final-rerun1-result.json`. Remaining work is tracked in
[implementation debt](ROADMAP/todo_implement.md).

## Deferred Godot collision issue — investigation parked by owner

### Symptom and scope

Equivalent flat-floor capsule setups at translated native coordinates can produce a shallow hit
in one placement but a missed downward sweep/full travel and about **0.241565 m penetration** in
another. In the player action controls this appears as landing on callback 224 versus 225 after
matched jump inputs. Earlier poses already differ slightly; this is not a bit-identical-state
claim. The issue remains unresolved, not an approved tolerance or gameplay rule.

A bare `PhysicsServer3D.body_test_motion` replay reproduces the discrepancy without the player
controller, live rebasing, AI, warm-up callbacks or original movement history. This shows those
are unnecessary for the particular query outcomes, not that all such code is universally safe.
The separate, justified floor-only `step_up()` correction and scalar logical/native frame
integration are already implemented and regression-checked. Preserve them without claiming that
the passing scoped checks resolve this remaining native collision behavior.

### Reproduction and retained evidence

The machine-local evidence store is:

```text
/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/artifacts/initial-encounters-01a16525
```

Preserve/copy it before moving machines. Paths below are relative to that store; full raw packets,
source snapshots, failed attempts and commands remain there rather than being copied into Git.

- `landing-factorial-data.md` and `landing-factorial-actual-response.md`: translated layouts
  crossed with no extra transaction versus a zero-displacement transaction. Layout alone was
  sufficient for landing divergence; the extra transaction was not required in those cells.
- `motion-replay-v4-data.md`, `motion-replay-v4-actual-response.md` and
  `query-replay-v4/run-replay12-20261023T220911342722Z/replay.jsonl`: exactly twelve independently
  cold capsule/box queries. The key pair is `down225-R0-to-L` / `down225-R0-to-R` (queries 11/12).
  Capsule radius approximately 0.4 m, height 1.8 m, local centre Y 0.9 m; static floor box
  512×1×512 m; downward motion Y `-0.2401711791753769`, margin `0.0010000000474974513`,
  recovery-as-collision true, maximum six contacts. Safe/unsafe fractions are
  `0.021484375/0.0244140625` versus `1/1`, UP depths about `0.00725747/0.24156506`.
  Use the complete saved packets: relative X itself differs by about 3.8 µm after float storage;
  do not silently manufacture a bit-identical or single-operand experiment.
- `capsule-box-native-source-audit.md` and its review/response: pinned Godot source shows
  explicit-margin SAT recovery/rest and fresh zero-margin GJK-distance sweep tests. World-coordinate
  support calculations and an origin-dependent-looking capsule/box axis were identified as leads,
  **not observed erroneous private branches or an evidence-backed engine patch**.
- `gdb-cast-v8-data.md` and `gdb-cast-v8-actual-response.md`: completed PID0, symbols-only metadata
  probe, not a target/physics trace. Runtime checkpoint SHA256
  `3fb062c7916877d73525d064b66e27ca61693e33f4c7420aa0d7ebb5124808e6`;
  raw observations SHA256 `d74163e63a1b5ccb28ff3f25dcf9e04a9b09066671ca4cea3a07af8130a5cefd`.

The engine is stock Godot `4.7.2.stable.nixpkgs.ed1daf0bf`, source commit
`ed1daf0bf001b61586d9930840f2f1394092c079`. Exact ELF:

```text
/nix/store/n6r2zl1kqjd498bwj8ndizpyba3y2qc2-godot-4.7.2-stable/libexec/godot.linuxbsd.editor.x86_64
SHA256 1db3afe38d0549f72167d7c1cccdfb530118a1099e832e55fd708ae92ebd133a
BuildID f25ce0f3ccf923fe0f41bacb2299d151bbfacd8c
```

It has minimal function symbols but no embedded DWARF/debug-link information; Godot private types
were unavailable. Public getters/replay outputs do not expose private pending transforms,
contact/cache state, GJK decisions or exact internal intermediate values.

### Debugger status and shortest continuation

GDB 17.2 is already available through the approved **devShell-only** `gdb` package addition;
no lock/runtime/export dependency was added. Pinned Python is 3.14.7. Do not provision GDB again.
In that GDB, `gdb.parameter('debuginfod enabled')` was actually observed as builtin string `off`,
not boolean False. With the retained minimal environment, its startup emitted the exact
index-cache-directory warning; its cause/timing/prevention is not established. The successful
metadata harness admits only that exact GDB warning line or empty stderr, never target errors.

In the new PID0 probe, `(void *)&'<symbol>'` fails **inside `parse_and_eval`** with `Invalid cast.`;
its later integer conversion is unobserved. Address-only `&'<symbol>'` succeeds and Python `int`
returns `19301168` (`0x1268330`) for `GodotSpace3D::test_body_motion`. This supports the proposed
address-only lookup, not retrospective localization of the original observer's outer error or
proof of a relocated PIE address. Metadata reported auto/current `i386` while the returned pointer
had sizeof8; do not force architecture or truncate pointers based on that observation.

`gdb-phase-observer-v2-preparation.md` is the exact parked state. New observer source in
`gdb-phase-observer-v2/` is **unsealed and not independently reviewed**. Compilation and source/
namespace-preservation checks passed, but the first host-check group failed because the synthetic
loader fixture uses parent PID100 while `observer.os.getpid()` is not mocked. The proposed
**test-only** PID mock has not been applied. Fix/validate this separately before using the probe;
never weaken the actual owned-process check. No new observer parse/load/loader/phase trace ran.

The proposed trace observes exact function-entry/return/verified call continuations and four
caller-tested AL booleans, with phase events only for queries 11/12 and all twelve public outputs
checked. It does not recover private fields or prove first numerical divergence. The rest site
is a solver-call continuation, not rest-phase completion or a boolean result.

### Tools, authorizations and limits still needed

- Ordinary encounter implementation/tests and this handoff are authorized. The diagnostic lane
  is parked; no old once-only execution receipt authorizes a replay. Preserve sealed inputs,
  failure logs and original hashes; repository code will now legitimately advance for features.
- Resuming native diagnostics needs a newly selected bounded source correction/checks, fresh
  review, current source/input pins, and separate exact selections for parse-only, symbols-only
  load, owned loader smoke, phase trace and any offline analysis. Retain ASLR, all-stop/scheduling,
  pre-breakpoint PIE/code-byte validation, exact PID/start/executable/parent/session ownership,
  race-safe cleanup, the original twelve cold fixtures and strict public equivalence.
- Matching debug-symbol investigation/download, or a **temporary diagnostic build of the same
  pinned Godot outside this repository**, was suggested but **has not been approved**. These are
  potentially useful for seeing the missing locals/types; first establish matching provenance.
  No engine upgrade, changed shipped backend/compiler/SDK, instrumentation/helper DSO, arbitrary
  inferior calls/state writes or new dependencies are authorized by the feature request.
- Do not introduce epsilon/floor forcing/coyote time/adaptive inputs/query-budget, margin,
  collision-geometry or movement-default changes to conceal the issue. Any proposed remedy needs
  its own source-backed RED/GREEN evidence, then verification against the release behavior.
  Feature evidence must clearly separate this retained known failure from new regressions.

## Android touch — characterization and publication follow-up

Current hardware-test status and its evidence limits live in the
[Android profile](../ontology/domain/controller-profiles.md#android). Further device/checklist
characterization and overlay render-cost measurement remain optional separately selected work,
not a device-access prerequisite for the authorized combat slice. Do not infer individual
checklist passes or install an Android SDK/ADB/export environment.

Android push, publication and changelog backfill remain unauthorized; the separately authorized
combat DOT documentation and feature-branch push do not extend to this follow-up.
Remaining controls scope stays in the
[backlog](ROADMAP/todo_implement.md#device-independent-controls-documentation-only).

## Dormant source continuation — separate owner request required

The earlier finite 108–111 source-pass audit, parent native acceptance/acknowledgment and
publication outcome remain unestablished by this gameplay checkpoint. Inspect existing native
evidence and the prior checkpoint at
`9b63e6e11c8c52b38183624c4fd1c43e9f09a870:docs/HANDOFF.md` before any separately authorized
continuation. Source-status maintenance already exists in `f801166`; do not recreate it or
restore the old §E history. Publishing gameplay documentation renews no earlier conditional
source-pass grant and does not establish its acceptance/publication outcome.

No selected source item is pending; research is not exhausted. Existing remaining evidence gaps
stay at [§7](../ontology/domain/7_Open_points_for_validation.md#7-open-points-for-validation) and
the [validation-contract backlog](ROADMAP/todo_implement.md#validation-contract-documentation-approved-implementation-unauthorized).
Silk/Spinning Wheel quantities remain **HOLD**. Retained/withdrawn source leads stay **UNAPPROVED**;
do not reopen handled class/weapon/lore attributions. Any future sourcing must follow
[lessons](lessons.md) and the current reconciliation contract: only inspected public article
extracts are public-safe; private authenticated DOM/account/token material is prohibited.
This continuation note authorizes no source research, inventory, selection or publication.

## SaveData direct malformed equipment key — pre-existing native/empty-diagnostic path

An isolated BASE-versus-candidate persistence probe supplies a structurally valid ring under an
integer equipment Dictionary key. Original `validate_character` emits a native int/String slot
comparison error and returns with `errors` still empty; the refactor preserves that outcome and
abort/continuation ownership. This is a malformed raw-Dictionary API case, not evidence that the
normal capture writer or JSON loader produces integer equipment keys. The outer `validate`/atomic
write consequence has not been separately reproduced; its errors-empty acceptance is a follow-up
boundary to assess, not an authorized incidental fix in this pure refactor.
Evidence: `/home/theta/.pi-game-dev/recovery/pixlnd-quality-gate-refactor/task4-7446c92/safety-extra-original.log`
and `safety-extra-comparison.json`, `integer-equipment-key` case. Next action: separately select a
bounded fail-closed characterization and rule/bug disposition; do not silently add a guard here.
