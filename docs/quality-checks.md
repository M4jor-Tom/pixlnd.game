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

1. `tests/test_checks.sh`: regression checks for the runner's pass/fail behavior.
2. `scripts/checks.sh`: GDScript formatting and lint, ontology validation, every
   `ontology/test_*.gd` and `game/*/test_*.gd`, then a headless main-scene boot.
   The map test also runs at fixed 1000 FPS to catch render/physics ordering races.
   Each Godot invocation prints its own wall-clock `Elapsed:` time, excluding Nix setup,
   lint and formatting. Hook output is visible on success locally and in CI.

Both use the same `flake.lock`-pinned Godot, gdtoolkit and pre-commit packages.
Nothing installs into the game's runtime. Tests use a temporary `PIXLND_TEST_DIR`
and the boot uses an explicit scratch save; your normal save is untouched.
Godot validation/tests have a 300-second timeout (450 for the two long capsule traversals).
The headless main-scene boot has a 150-second timeout.
Nonzero exits, timeouts, `SCRIPT ERROR`, engine `ERROR` and `ontology INVALID`
output all fail the gate, including when Godot exits zero.

## Scope and limits

`gdformat --check` enforces the pinned formatter's default layout without changing
files during hooks or CI. `gdformatrc` explicitly enables parse-tree, comment and
formatting-stability safety checks. Apply formatting locally with:

```sh
nix develop --no-update-lock-file -c gdformat game ontology
```

`gdlintrc` still defers naming and size/complexity constraints. Syntax and the
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
