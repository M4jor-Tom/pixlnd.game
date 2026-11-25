# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

(`CLAUDE.md` is a symlink to `AGENTS.md` — edit `AGENTS.md`.)

## What this is

Cube World rebuild in Godot 4.7.2 + GDScript, developed **ontology-first**. `ontology/` is the
source of truth; `game/` only consumes it and never redefines it.

Three files describe the whole repo, read them in this order before doing anything:
1. `docs/HANDOFF.md` — pending continuation and active authority/blockers; empty when none remain.
2. `ontology/README.md` + `ontology/domain/index.md` — classes, relations, §5 constraints, §6 generators.
3. `game/README.md` — folder-per-§3-section table, slice workflow, gotchas and headless checks.

## Sync rule (step 0 of any domain-touching task)

Land approved necessary domain changes in `ontology/` before engine code, then implement by
consuming it. For gameplay slices, require the repository-owned [resume workflow](skills/ontology-resume-router-slice/SKILL.md)
and its authority/precision gate. Follow the [recording workflow](skills/record-impactful-decision/SKILL.md)
for significant choices (technical records belong in `docs/decisions/`); reuse precise approved rules without inventing decisions or completed
backlog entries. Run the validator before coding. Skip ontology sync only for tasks that don't
touch the domain (build, tooling, debugging).

## Bugs found during other work

All agents must record newly discovered bugs promptly in `docs/HANDOFF.md`, even while
working on another task; do not wait until task completion. Include the affected scope,
observed behavior, evidence or reproduction, and the next action. Respect single-writer
ownership: read-only agents or agents without ownership of that file must notify the parent
or owning writer immediately so the finding is recorded there.

Recording a bug does not authorize fixing it. Incidental fixes during authorized work are
welcome; actively pursuing unrelated fixes is forbidden unless necessary to execute the
authorized workflow. Keep any necessary unblocker minimal, tested and disclosed. Keep
HANDOFF pending-only: remove a finding after its resolution is verified, retaining detailed
receipts in managed evidence rather than a completed-bug history.

## Commands

The [quality gate](docs/quality-checks.md) runs the same formatting, essential lint, ontology and headless
checks on demand locally and in GitHub Actions. Install once per clone with
`nix develop --no-update-lock-file -c pre-commit install`; run manually with
`bash scripts/quality_gate.sh` (the same complete manual manifest as CI).
Short gates (ruff, LinkML module size, generated diagrams/instances) block the commit.
Host commits do not queue the full suite; CI runs it. Explicit `bash scripts/gate.sh start [rev]` queues a run, not a pass. `bash scripts/gate.sh check [rev]` shows state/log and succeeds only for a validated
same-tree pass; normal pushes do not require a local receipt. Attempts/logs are retained under the common
Git dir's `pixlnd-gate/v4/<tree>/`; the Linux host needs `python3` on PATH for the lifetime
guardian (the suite's pinned interpreter is unchanged). After interruption inspect evidence
and explicitly `start` again after kernel drain. Lost guardian proof blocks cleanup and new
expensive work across trees; a free lock is not proof. Never signal by PID alone.
The independent CI Quality job is still required; see the quality-gate guide for recovery.

```bash
nix develop -c godot                                        # play (add -- --class=ranger|mage|rogue)
nix develop -c godot --headless -s ontology/validate.gd     # §5 constraints, must be 0 errors
nix develop -c godot --headless --quit                      # autoload + main scene boot check
timeout 150 nix develop -c godot --headless -s game/combat/test_defence.gd   # one test
nix develop -c godot -s game/combat/test_defence.gd         # same test, windowed (drop --headless)
./monitors/godot_threads.sh                                 # while the game runs: red = physics spiral
```

Headless tests are plain `extends SceneTree` scripts under `game/`, `ontology/` and `tests/ontology/`; `game/README.md`
lists every check with what it covers. Always run them under `timeout` — an error after an `await`
leaves the tree running forever. Never `pkill -f <script>`, it matches your own shell.

## Architecture

- `OntologyDB` (autoload, `game/ontology_db.gd`) uses `game/domain/domain.gd` for raw configurations and bound catalogs;
  it aborts on load diagnostics or a missing default ruleset. Read-only for the whole run.
  `OntologyDB.design` = the owner-decided numbers, `OntologyDB.flag("…")` gates features by ruleset.
- Gameplay scripts never touch `OntologyDB`. `main.gd` injects the design dicts
  (`player.setup(...)`, `creature.setup(...)`, `world.design = …`) so `-s` tests can drive them.
- Consumer tests belong in `tests/ontology/`; `ontology/validate.gd` checks the local model independently.
- Mutable state (world, characters, inventory) belongs to save-data (§3.7), not to the autoload.
- `game/` folders mirror `ontology/domain/index.md §3`: `world/ entities/ combat/ items/ progression/ missions/ meta/`.

## Gotchas beyond the two above

- `@onready` vars are null when `setup()` is called from a `SceneTree._init` test → use `$Node` inside `setup()`.
- `--headless --write-movie` crashes (exit 134); the movie writer needs the windowed form in `game/README.md`,
  and it drops CanvasLayer UI, so HUD checks need a viewport capture from `main.gd` in a windowed run.
- zsh here does not word-split `$var`: loops that build Godot arguments run under `nix develop -c bash -c '…'`.
- `Engine.time_scale` (hit-stop) also scales `physics_frame` waits and tweens — tests that must pass a
  hit-stop wait on a real-time timer, `create_timer(s, true, false, true)`.

## Style

Lazy version first (ponytail): shortest diff that works, no speculative abstraction. Every deliberate
cut gets a `ponytail:` comment naming the ceiling **and** a line in `docs/ROADMAP/todo_implement.md`.

## Changelogs

One per slice, its own commit (`docs: D<n> changelog`), written after the code commit so its hash is known:

`docs/changelogs/pre-v1/<yyyymmddhhmmss>_D<n>_<slice commit hash>.md`

**Written for players, not developers** — these get published on the game's page. Say what the player
can now do, grouped by weapon / skill / screen, in plain words. Short `#` title with the date, a few
`##` groups of bullets, and at most one closing `Coming next:` line.

Never in a changelog: file names, script names, constraint or design ids (`c-…`, `design.…`), commit
hashes in the body, D-numbers, engine terms, or a "deferred / known issues" section. That detail
belongs in the commit message, `docs/HANDOFF.md` and `docs/ROADMAP/todo_implement.md`. The hash in
the file name is provenance enough. Don't back-fill older slices unless asked.

See `docs/changelogs/pre-v1/20260911235517_D26_ce94c6d.md` for the shape.
