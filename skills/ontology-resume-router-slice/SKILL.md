---
name: ontology-resume-router-slice
description: Use when asked to resume gameplay implementation or continue an authorized slice in pixlnd's ontology-first game, not when resuming an ontology walkthrough or source research.
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

# Ontology Resume → Router → Slice

Resume from current repository evidence, not session memory. Land one authorized, precise slice;
missing game-design precision is a blocker, not an invitation to rule on behalf of the owner.
Read the required [repository workflow](repository-workflow.md) for pending choices, stale data
and numerical decision review. Paths in backticks below are relative to the repository root.

## Recover objective and authority

1. Follow the bootstrap order in [AGENTS.md](../../AGENTS.md), then read
   [ontology instructions](../../ontology/AGENTS.md), [decision instructions](../../ontology/decisions/AGENTS.md),
   `docs/lessons.md`, current decision records and `docs/ROADMAP/todo_implement.md`.
   Read `docs/ROADMAP/todo_decide.md` and `docs/todo_handle_reconciled_items.md` only if present:
   they are pending-only and may correctly be absent. An empty HANDOFF is valid.
2. Establish the current objective, branch, HEAD, index, worktree ownership and exact owner
   authorization before mutation. Preserve unrelated edits; stop on overlapping ownership.
   Resume/compaction does not change a handoff/review objective into implementation.
   A dormant walkthrough or source checkpoint supplies no gameplay or research grant. For an
   authorized walkthrough use `ontology-reconcile-topic`, not this slice loop.
3. Identify a candidate from unfinished HANDOFF work, then README/backlog hints if needed.
   These are navigation, not approval. Require actual implementation authority for the coherent
   slice, not new permission for every ordinary file/test within it. Documentation/research
   approval alone is insufficient. Without a selected authorized scope, report the candidate
   and ask the owner; do not invent a next D-number or activate dormant work.
4. Record missing/stale documents or checks rather than automatically restoring history or
   repairing them. A failed check is evidence, not permission to turn the task into a repair
   slice. Any needed alignment/repair must be within explicit authorized scope.

## Select a bounded range and prove readiness

Before any slice mutation, prepare a brief in the current managed workspace. Record the objective,
authority locator, included/excluded behaviors and exact source locators: split
`ontology/domain/index.md` section files and anchors, IDs, instance/design paths and decision
references (including descriptive slugs, not just historical D-IDs). Follow relevant relations,
generators, constraints and decision links through all selected dependencies, even outside the
initial section range. Read the canonical §5 validation contract; do not replace it with this skill.

For each behavior/dependency, fill this table with concrete evidence, not just “defined”:

| Behavior / dependency | Current rule + approval locator | Inputs, formula, units; applicable timing/order/edges | Data/runtime drift | Acceptance evidence (existing / to build) | Unresolved item | Verdict |
|---|---|---|---|---|---|---|
| <selected behavior or required dependency> | <exact anchors and authority> | <values/semantics or justified N/A> | <aligned / stale / unimplemented> | <check and expected observation> | <gap or none> | <PASS / BLOCKED> |

**PASS threshold:** an engineer can implement the entire selected slice without making an
unapproved game-design choice. Ordinary non-domain implementation details remain engineer choices.
Overall PASS requires sufficient implementation authority and PASS for every required dependency.
Recheck after any scope, authority or dependency change, and before game implementation.

**BLOCKED:** missing material quantities/formulas, applicable failure/capacity rules, timing/order
or edge semantics; conflicting current rules; unresolved selected dependencies; insufficient
implementation authority. Name exact missing locators/values, affected behavior and the next owner
question. Do not invent quantities, curves, clamps or defaults, hide gaps behind green tests, or
silently shrink scope. A proposed smaller slice needs owner approval. Deadlines and sunk work do
not relax the gate. Stop dependent mutation until resolved; recording the blocker grants no research.

Unrelated historical uncertainties and intentionally optional/nullable fields are not automatic
blockers. Nor is absent runtime/validator coverage in a newly authorized implementation slice:
readiness is not completion. Enumerate the coverage to build. A precise approved rule with stale
executable values needs an explicit authorized alignment step, not reapproval of the settled rule
or adoption of stale defaults as policy. If the alignment is not authorized, report that boundary.
A green validator proves only implemented checks, not missing precision or full runtime compliance.

## Execute only a PASS brief

The brief is the requirements. Include the table, dependency closure, approved alignment steps,
allowed changes, checks, required skills and commit/push authority. Record BASE and current dirty
state before dispatch. Keep progress, briefs, raw checks and reports in the managed workspace;
after compaction verify actual files/Git/evidence rather than trusting a “complete” line alone.

1. **Ontology sync only where necessary and approved.** Update the canonical section, relation,
   constraint or design path that actually needs changing. Follow
   [record-impactful-decision](../record-impactful-decision/SKILL.md) for significant choices.
   Existing precise approved rules need neither a new decision nor an empty ontology commit.
   Behavior-changing JSON, loader/validator and runtime changes require implementation scope;
   source or documentation approval does not grant it. Validate before engine coding under
   `timeout 150 nix develop -c godot --headless -s ontology/validate.gd`.
   For authorized new drift checks, prove they reject broken data in a scratch/in-memory case.
   Stop on failures outside scope; do not automatically repair them.
2. **Route and implement.** Load `game-from-ontology` → `ontology` → `router` and list the selected
   implementation skills in the brief. Recheck PASS against any newly exposed dependency.
   Follow canonical architecture, test and deliberate-cut rules in AGENTS.md and game/README.md;
   do not redefine game values in code. Add the bounded slice check and planned acceptance coverage.
3. **Verify and review.** Run the full applicable game/README.md check list (validator, boot,
   every game test; windowed captures where applicable), with a timeout on each command.
   Inspect logs as well as exit codes; inspect actual captures before claiming visual coverage.
   Keep command, exit, revision and coverage limits. Run /simplify then ponytail-review.
   Obtain fresh independent spec and quality review of the brief, actual diff, new/untracked
   files and evidence. Parent inspects actual outputs and resolves findings within scope;
   re-gate if a finding changes authority, scope or dependencies. Never treat a failing baseline
   or green narrow test as authority or comprehensive proof.
4. **Close only verified work.** Update game/README.md and implementation debt where needed.
   Refresh only pending continuation using [handoff-template.md](handoff-template.md); keep
   completed receipts in managed evidence. Follow the actual player changelog conventions in
   [AGENTS.md](../../AGENTS.md#changelogs), after an authorized code commit supplies its hash.
   Retain real decision identities; do not manufacture a D-ID to satisfy an old naming pattern.
   If naming needs an owner choice, report it. No backfilling older slices unless requested.
   Use scoped conventional commits only when authorized, not a mandatory three-commit sequence
   or forced attribution trailer. Push only with current authority; verify publication before
   claiming it. If commits are withheld, report pending hash-dependent changelog/publication work.

## Native delegation and model routing

Parent orchestrates; workers never spawn. Load `pi-subagents` and use its installed native API,
capabilities and current workflow authority; do not substitute obsolete Agent templates or CLI
sessions. Bind reports through output fields, not a filename mentioned only in prose. Use
[phase-prompts.md](phase-prompts.md) as task content, not tool-call syntax.

Choose an available model for each dispatch: cheap-to-mid for bounded ontology sync/changelog,
standard for implementation, more capable for new runtimes or broad engine changes; reviewer
capacity scales with the diff. After three unsuccessful fix rounds, reassess the blocker and use
a more capable available model only within current authority. Never guess provider/model names.
Keep one writer and fresh independent reviewers, with full native results across dependency barriers.

On subagent infrastructure failure, STOP and preserve the actual error/run, cwd, branch/HEAD/index
and partial diff. Request governed recovery; do not silently switch execution modes, waive review
or invoke external agents. This skill supplies no additional orchestration or publication authority.

## Handoff contract

`docs/HANDOFF.md` is pending-only, not a build log. Drop handled points once progression and
unique decisions/evidence, qualifications and failed-check caveats are visible in existing project
records. Keep only unfinished work, its next action, active authority/blockers and links needed to
resume. A complete/terminated project with no continuation needs has an empty (zero-byte) handoff.
Do not edit it while another agent owns it. Never restore completed history into an empty handoff.

**Narration:** one short line between tool calls at most.
