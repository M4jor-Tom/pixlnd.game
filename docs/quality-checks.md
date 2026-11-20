# Local and CI quality gate

## Install the local hook

From this checkout, run once (and again after cloning):

```sh
nix develop --no-update-lock-file -c pre-commit install
```

The configuration installs pre-commit, post-commit and pre-push hooks. Each commit starts the
full gate, including tests, in the background on a clean export of the committed tree
(`scripts/gate.sh start`). Each `git push` only checks that the pushed commit's tree passed
(`scripts/gate.sh check`): it fails fast while the gate is running, after a failure, or when no
gate ran (e.g. a `--no-verify` commit: run `bash scripts/gate.sh start <rev>`). Receipts and
logs live in `.git/pixlnd-gate/<tree>.{running,pass,fail,log}`; a squash or rebase with an
identical tree reuses its pass. One gate runs at a time; later ones queue. The hooks enter the
locked Nix environment themselves, so committing or pushing outside `nix develop` works.

On commits touching `ontology/schema/`, the pre-commit hook regenerates the
[ontology Mermaid diagrams](ontology/mermaid/overview.mmd). If they change, the commit fails:
`git add docs/ontology/mermaid` and commit again.

The overview shows the `world`, `entity`, `item`, `ability` and `generators-source` core
with one-hop references; complete per-class views remain unfiltered in `classes/`.
The existing generator runs `tests/test_ontology_mermaid.py` to enforce the 50,000-character
budget and core/detail coverage in normal hooks and CI.

The full suite can take many minutes, which is why it no longer runs inside `git push`
(a long pre-push hook held the SSH connection open until the server timed out).

## Run manually

This is also the exact command in `.github/workflows/quality.yml` (synchronous, same hooks):

```sh
nix develop --no-update-lock-file -c pre-commit run --all-files --hook-stage manual
```

`.pre-commit-config.yaml` is the shared definition. Its local hooks run:

1. `tests/test_checks.sh`: regression checks for the runner's pass/fail behavior,
   including size/complexity boundaries, class methods and bypass prevention.
2. `scripts/checks.sh`: GDScript formatting and lint, file/function size, Python/Bash limits,
   cognitive complexity, ontology validation, every
   `ontology/test_*.gd` and `game/*/test_*.gd`, then a headless main-scene boot.
   The map test also runs at fixed 1000 FPS to catch render/physics ordering races.
   Each Godot invocation prints its own wall-clock `Elapsed:` time, excluding Nix setup,
   lint, formatting and size checks. Hook output is visible on success locally and in CI.
3. `scripts/ontology_mermaid.sh` (also the pre-commit hook): regenerates `docs/ontology/mermaid/`
   with LinkML's `gen-erdiagram` and `gen-mermaid-class-diagram` from the `uv.lock`-pinned
   `tools/ontology` environment, failing on stale diagrams (e.g. committed with `--no-verify`).

The first two use the same `flake.lock`-pinned Godot, gdtoolkit and pre-commit packages.
`flake.nix` additionally pins gdmetrics-g4 v1.6.1 by source commit and content hash,
exposed only in the development shell as `GDMETRICS_G4`.
Nothing installs into the game's runtime. Tests use a temporary `PIXLND_TEST_DIR`
and the boot uses an explicit scratch save; your normal save is untouched.
Godot deadlines are `3 × ceil(1.25 × longest measured duration in the timeout group)`:
the factor of three retains the existing tripled margin; the ordinary-group measurement
refresh below does not change this formula.
The local pre-push calibration at `f383ef1` measured all 62 Godot invocations with
local deadlines disabled; by owner selection, CI execution times are not included yet.

| Timeout group | Slowest local invocation | Measured | Deadline |
|---|---|---:|---:|
| Ordinary validation/tests, including fixed-1000-FPS map | `ontology/test_required_inputs.gd` | 457.701s | 1719s |
| Both long capsule traversals | `game/world/test_local_frame_routes.gd` | 336.189s | 1263s |
| Headless main-scene boot | `--quit` | 3.072s | 12s |

On 20 November 2026, the unchanged full 1687-case `ontology/test_required_inputs.gd`
completed with zero failures in 457.701 seconds of Godot wall time. Refreshing only the
ordinary group's old 180.824s/681s basis gives `3 × ceil(1.25 × 457.701) = 1719s`.
The 501.032956208-second owned duration includes Nix/setup and is not the Godot measurement.
Other group measurements remain historical; this does not remeasure every current invocation
or include CI times. The diagnostic is not a normal full-gate pass. Measurement evidence:
`publication-20261120/required-input-diagnostic-2/` in the managed Task6 evidence root.
`tests/test_quality_deadlines.py`, invoked by the runner regressions, checks this calibration
against the three ordinary allocations and preserves the special and boot limits.

Cognitive analysis also uses the ordinary 1719-second deadline; it was not part of
that earlier calibration. These limits apply separately to each invocation, locally and in CI. There is no
whole-suite local deadline; the CI quality job has a tripled 90-minute total limit,
including setup.
Nonzero exits, timeouts, `SCRIPT ERROR`, engine `ERROR` and `ontology INVALID`
output all fail the gate, including when Godot exits zero.

## Scope and limits

`gdformat --check` enforces the pinned formatter's default layout without changing
files during hooks or CI. `gdformatrc` explicitly enables parse-tree, comment and
formatting-stability safety checks. Apply formatting locally with:

```sh
nix develop --no-update-lock-file -c gdformat game ontology scripts
```

### File and function size

`scripts/check_sizes.py` uses the pinned gdtoolkit syntax tree to enforce hard
physical-line caps across every `.gd` file in `game/`, `ontology/` and `scripts/`,
including tests, hidden paths and symlinked sources:

| Metric | Maximum |
|---|---:|
| File length | 600 lines |
| Function or method length | 100 lines |

Files count all lines, including blanks and comments. Function spans run from the
declaration through the last syntax statement, including internal blank/comment
lines, but not following separators or trailing comments. Multiline expressions
include their closing delimiters. Static and inner-class methods, property getters/
setters, abstract declarations and lambdas use the same cap. A file of 600 lines or
function of 100 lines passes; 601/101 fails with its location and measured length.
There are no baselines or inline-lint exemptions; existing violations block the gate.
No new package is required.

### Python and Bash limits

`scripts/check_python_bash.py` applies the same hard caps to every `.py` and `.sh` file under
`scripts/`, `tests/`, `skills/`, `monitors/` and `tools/` (symlinks followed, `.venv` pruned):
600 lines per file, 100 lines per function, cognitive complexity 15 per function. 600/100/15
passes; 601/101/16 fails with the file, line, function and measured value. There is no baseline
or inline exemption. Python is parsed with `ast`; Bash with `shfmt -ln bash --to-json`, which
`flake.nix` adds to the development shell. A file that does not parse fails.

Function length runs from the declaration (decorators excluded) through the last statement.
Module-level and top-level shell code is not scored. Each nested function is scored on its own
and not added to its parent. Cognitive rules (our reading of Sonar's):

| Construct | Increment |
|---|---|
| `if`, loops (`for`, `while`, `until`), `match`/`case`, `except`, ternary | +1 plus nesting; body one level deeper |
| `elif`, `else` | +1, no nesting penalty |
| run of the same `and`/`or` (`&&`/`||`) | +1 per run |
| lambda | 0; body one level deeper |
| `with`, `try` body, comprehensions, pipes, subshells, blocks, recursion | 0 |

### Cognitive complexity

`scripts/check_complexity.gd` enforces a **maximum per-function C-COG of 15** using
[gdmetrics-g4](https://github.com/JaponBaligi/gdmetrics-g4/tree/v1.6.1)'s native tokenizer,
control-flow detector and cognitive-complexity calculator. A score of 15 passes;
16 or more fails, with the file, line, function and score printed. This is gdmetrics'
C-COG metric, not cyclomatic complexity or an interchangeable Sonar score.

Every `.gd` file under `game/` and `ontology/`, including tests, is analyzed in a
temporary project without game autoloads or normal saves. A complete `find` manifest
includes hidden paths and names containing `..`, which native discovery skips.
No result cache, baseline or default directory exclusion exempts existing code. Empty discovery
and analyzer errors fail the gate. One owner-approved test-only deferral is described below;
all unflagged functions and all other identities still fail above 15. Over-limit existing methods therefore block the
gate until separately refactored; installing the check does not establish a green
repository.

### One owner-approved pending test deferral

Only `game/entities/test_android_controls.gd::_competing_request` may carry the exact root-level
comment `# @cognitive-defer arrival-resource-recheck`, immediately before its declaration.
The checker still calculates and visibly reports its actual score as `DEFERRED`, with a deferred
count and `docs/HANDOFF.md` reference. Reducing this one cohesive arrival-resource case to 15 is
pending, not completed; its original scenarios and independent stamina expectations 0 / 75 remain.
Test equivalence follows the real Player / `Abilities.busy() -> bool` interface; production
behavior and native-error ownership are not relaxed.

Unknown, malformed, duplicate, misplaced, wrong-identity, nested, missing-callable and stale
(15-or-less) flags fail. Marker text inside string literals is not an annotation. Without the
flag even this exact function fails above 15. No whole-file/run/production exemption, CLI or
environment bypass exists. Size 600/100, lint, formatting, discovery, analyzer errors, runtime
checks and deadlines remain independent. `tests/test_cognitive_defer.sh`, also called by the
runner regressions, covers these boundaries. The pending HANDOFF task requires removing both
flag and narrow exception after the deferred refactor is verified. A passing final gate therefore
uses this disclosed single-exception policy, not unconditional native-15 compliance.

The adapter supplies only leading whitespace to the native function-boundary detector:
v1.6.1 otherwise mistakes inline spaces for dedents in class methods. Each detected
function is scored separately so repeated method names cannot overwrite one another.
The native control-flow nodes and C-COG formula are unchanged.

`gdlintrc` still defers naming/design style cleanup; hard sizes are enforced by
`check_sizes.py` rather than gdlint's suppressible file-size rule. Syntax and the
remaining lint checks are enforced; one existing side-effectful conditional test
assertion has a scoped gdtoolkit false-positive suppression. These checks do not
establish full ontology consistency or resolve the native collision issue retained
in `docs/HANDOFF.md`.

Run pushes from the checked-out branch with the intended changes committed:
pre-commit checks the local checkout/index, not an isolated archive of arbitrary
pushed refs. CI checks its own checkout (the pushed commit, or PR merge commit).
A hook is a convenience, not a security boundary; Git permits bypassing it.

The **Quality** GitHub Actions workflow runs on pushes and pull requests. To prevent
merging after a bypass or failure, require its `quality` job in GitHub branch
protection/rulesets. This setup does not change remote rulesets or the existing
independent release workflow. Windowed visual checks, exports and host-dependent
NVIDIA launcher checks remain separate.
