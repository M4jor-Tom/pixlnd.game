# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

(`CLAUDE.md` is a symlink to `AGENTS.md` — edit `AGENTS.md`.)

## What this is

Cube World rebuild in Godot 4.7.2 + GDScript, developed **ontology-first**. `ontology/` is the
source of truth; `game/` only consumes it and never redefines it.

Three files describe the whole repo, read them in this order before doing anything:
1. `docs/HANDOFF.md` — state of the build, the per-slice loop, the verified gotchas, next slice.
2. `ontology/README.md` + `ontology/domain.md` — classes, relations, §5 constraints, §6 generators.
3. `game/README.md` — folder-per-§3-section table and the full list of headless checks.

## Sync rule (step 0 of any domain-touching task)

Land the change in `ontology/` first — class, relation, constraint, `generators.json#design.<topic>`,
a `**D<n> … — DECIDED <date>**` line in `domain.md §7`, a `[x] D<n>` in `docs/ROADMAP/todo_decide.md`,
a status line in `ontology/README.md` — then implement by consuming it. Run the validator before coding.
Skip only for tasks that don't touch the domain (build, tooling, debugging).

## Commands

```bash
nix develop -c godot                                        # play (add -- --class=ranger|mage|rogue)
nix develop -c godot --headless -s ontology/validate.gd     # §5 constraints, must be 0 errors
nix develop -c godot --headless --quit                      # autoload + main scene boot check
timeout 150 nix develop -c godot --headless -s game/combat/test_defence.gd   # one test
nix develop -c godot -s game/combat/test_defence.gd         # same test, windowed (drop --headless)
./monitors/godot_threads.sh                                 # while the game runs: red = physics spiral
```

Tests are plain `extends SceneTree` scripts at `game/**/test_*.gd`, one per slice; `game/README.md`
lists every check with what it covers. Always run them under `timeout` — an error after an `await`
leaves the tree running forever. Never `pkill -f <script>`, it matches your own shell.

## Architecture

- `OntologyDB` (autoload, `game/ontology_db.gd`) loads `ontology/instances/*.json` through
  `ontology/model.gd`, validates, and aborts on any violation. Read-only for the whole run.
  `OntologyDB.design` = the owner-decided numbers, `OntologyDB.flag("…")` gates features by ruleset.
- Gameplay scripts never touch `OntologyDB`. `main.gd` injects the design dicts
  (`player.setup(...)`, `creature.setup(...)`, `world.design = …`) so `-s` tests can drive them.
- Engine scripts `preload("res://ontology/model.gd")`, never `CubeWorldModel` by name: headless
  Godot has no class-name cache.
- Mutable state (world, characters, inventory) belongs to save-data (§3.7), not to the autoload.
- `game/` folders mirror `domain.md §3`: `world/ entities/ combat/ items/ progression/ missions/ meta/`.

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
