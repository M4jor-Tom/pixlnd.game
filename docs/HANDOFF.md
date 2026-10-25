# Handoff — pending continuation

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
