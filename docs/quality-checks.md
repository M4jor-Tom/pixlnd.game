# Local and CI quality gate

## Install the local hook

From this checkout, run once (and again after cloning):

```sh
nix develop --no-update-lock-file -c pre-commit install
```

The configuration installs **pre-push only**, not a commit hook. Each `git push`
runs the full gate, including tests, even for documentation-only changes. The hook
enters the locked Nix environment itself, so pushing outside `nix develop` works.

The full suite can take many minutes. For SSH remotes, enable keepalives so the
connection stays open while the hook runs. If you have no custom `core.sshCommand`:

```sh
git config --local core.sshCommand 'ssh -o ServerAliveInterval=30'
```

Preserve existing SSH options if that command is already customized.

## Run manually

This is also the exact command in `.github/workflows/quality.yml`:

```sh
nix develop --no-update-lock-file -c pre-commit run --all-files --hook-stage pre-push
```

`.pre-commit-config.yaml` is the shared definition. Its local hooks run:

1. `tests/test_checks.sh`: regression checks for the runner's pass/fail behavior,
   including size/complexity boundaries, class methods and bypass prevention.
2. `scripts/checks.sh`: GDScript formatting and lint, file/function size, cognitive complexity,
   ontology validation, every
   `ontology/test_*.gd` and `game/*/test_*.gd`, then a headless main-scene boot.
   The map test also runs at fixed 1000 FPS to catch render/physics ordering races.
   Each Godot invocation prints its own wall-clock `Elapsed:` time, excluding Nix setup,
   lint, formatting and size checks. Hook output is visible on success locally and in CI.

Both use the same `flake.lock`-pinned Godot, gdtoolkit and pre-commit packages.
`flake.nix` additionally pins gdmetrics-g4 v1.6.1 by source commit and content hash,
exposed only in the development shell as `GDMETRICS_G4`.
Nothing installs into the game's runtime. Tests use a temporary `PIXLND_TEST_DIR`
and the boot uses an explicit scratch save; your normal save is untouched.
Godot deadlines are `3 × ceil(1.25 × longest measured duration in the timeout group)`:
all previously calibrated limits are tripled, without changing the underlying measurements.
The local pre-push calibration at `f383ef1` measured all 62 Godot invocations with
local deadlines disabled; by owner selection, CI execution times are not included yet.

| Timeout group | Slowest local invocation | Measured | Deadline |
|---|---|---:|---:|
| Ordinary validation/tests, including fixed-1000-FPS map | `ontology/test_required_inputs.gd` | 180.824s | 681s |
| Both long capsule traversals | `game/world/test_local_frame_routes.gd` | 336.189s | 1263s |
| Headless main-scene boot | `--quit` | 3.072s | 12s |

Cognitive analysis also uses the ordinary 681-second deadline; it was not part of
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

### Cognitive complexity

`scripts/check_complexity.gd` enforces a **maximum per-function C-COG of 15** using
[gdmetrics-g4](https://github.com/JaponBaligi/gdmetrics-g4/tree/v1.6.1)'s native tokenizer,
control-flow detector and cognitive-complexity calculator. A score of 15 passes;
16 or more fails, with the file, line, function and score printed. This is gdmetrics'
C-COG metric, not cyclomatic complexity or an interchangeable Sonar score.

Every `.gd` file under `game/` and `ontology/`, including tests, is analyzed in a
temporary project without game autoloads or normal saves. A complete `find` manifest
includes hidden paths and names containing `..`, which native discovery skips.
No result cache, baseline,
inline ignore or default directory exclusion exempts existing code. Empty discovery
and analyzer errors fail the gate. Over-limit existing methods therefore block the
gate until separately refactored; installing the check does not establish a green
repository.

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
