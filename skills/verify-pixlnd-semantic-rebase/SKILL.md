---
name: "verify-pixlnd-semantic-rebase"
description: "Use when rebasing pixlnd commits across upstream tooling, script-UID, or release-convention changes, including a conflict-free replay."
version: 1
created: "2026-09-18"
updated: "2026-09-18"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

## When to Use
For authorized history maintenance, not permission to implement deferred ontology/gameplay decisions.

## Procedure
1. Confirm clean branch/index, fetch the requested upstream, record exact base/old/upstream SHAs, and create a named recovery branch before rewriting. Read every upstream/local patch and affected callers; record each local commit's intent and required adaptations in temporary evidence.
2. Run the baseline. Replay in order with an interactive rebase: use edit stops only for adaptations and exec checks for each commit. Preserve author identity/date/messages. Keep a single writer; do not push without separate permission.
3. Match upstream's tracked .gd.uid convention for newly introduced scripts. At the introducing commit run `timeout 150 nix develop -c godot --headless --editor --import`, stage only the new sidecars, and amend. Preserve existing UIDs. Update live SHA references and stale handoff/release instructions in the appropriate documentation commit without changing historical approvals.
4. At each replay run ontology/validate.gd, all game/**/test_*.gd present at that commit, and main boot via timeout-bounded `nix develop -c godot --headless`. Check both process exit and SCRIPT ERROR/ERROR logs. At final HEAD also run editor import and `timeout 150 nix run . -- --headless --quit`.
5. Inspect range-diff and an original-to-rebased commit map. Prove every upstream-only path is unchanged, scripts/instance data differ only where explicitly justified, every tracked script has a unique UID, and the branch/index have no rebase state or unintended files. Finish with simplification and independent correctness/ponytail reviews.

## Pitfalls
- A conflict-free replay can miss new upstream conventions: newly added test scripts still need UID sidecars.
- Installed Nix treats the first positional argument as an installable even after --; use explicit `nix run . -- ...` when passing Godot flags.
- The suite grows as regression scripts are introduced; discover tests at each commit instead of hardcoding the final count.
- Godot can log script errors despite a successful exit. Local export templates are intentionally absent; boot success does not prove macOS/Android packaging.
- Keep logs/maps/check scripts in temporary or managed artifacts, not new repository process documents. Rebase authorization does not authorize gameplay changes or remote publication.

## Verification
1. Range-diff accounts for every original commit and every changed patch; backup remains available.
2. Baseline/per-commit/final logs name checked revisions and contain explicit pass results plus clean error scans.
3. UID coverage/uniqueness and editor-import stability pass; upstream files and approved scope are preserved.
4. Final worktree/index are clean, no rebase is active, and export/UI/multiplayer limitations are reported accurately.