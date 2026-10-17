---
name: "audit-pixlnd-ontology-consistency"
description: "Use when reviewing pixlnd ontology consistency or assessing what a green validator actually proves."
version: 9
created: "2026-09-13"
updated: "2026-10-13"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

## When to Use
Read-only audits of ontology/domain/index.dsl, instance data, the typed loader, and implemented gameplay. Not a gameplay implementation workflow. For source precision, explicitly load sibling `../record-finding/SKILL.md` for evidence shape; for a separately authorized significant choice, explicitly load sibling `../record-impactful-decision/SKILL.md`. Loading either does not grant repository write authority.

## Procedure
1. Record git status and HEAD; read docs/lessons.md, ontology/README.md, ontology/domain/index.dsl, docs/ROADMAP/todo_decide.md if present, and todo_implement.md. Separate historical facts, hybrid decisions, explicit deferrals, contradictions and unanswered questions.
2. Run `timeout 90 nix develop -c godot --headless -s ontology/validate.gd`; do not equate a green result with full semantic coverage.
3. Compare relation cardinalities and ID namespaces against concrete instances, then trace each relevant load-time constraint into model.gd. Check missing whole tables/blocks as well as invalid individual entries. For dynamic state, tabulate each event's independent effects on amount, selected target and historical tie priority, its entity/pair scope and unaffected records. Check hits/decay, target switches, zero, re-engagement, death and escape/return against canonical rules; flag undefined transitions rather than inventing resets or retention. A target switch alone proves neither score clearing nor historical-priority persistence.
4. Use a scratch SceneTree script outside the repository to preload `res://ontology/model.gd`, load a fresh Ontology for each case, mutate only in-memory data, and print both validate() and errors. Execute with `nix develop -c godot --headless --path /home/theta/repos/pixlnd -s /tmp/<probe>.gd` under timeout.
5. For runtime contradictions, instantiate existing scenes in a deferred test entrypoint, reuse their setup calls, and probe boundary cases directly. Run the existing related headless tests separately to distinguish missing coverage from failing baseline tests.
6. Return audit findings in managed artifacts with both contract and implementation citations; distinguish executed probes from source-derived hypotheses. For substantive source research, use the loaded finding helper's evidence shape without invoking its repository-recording procedure. Persist at docs/findings/<slug>.md only under explicit recording authority and exclusive worktree ownership in a separately authorized recording task; ordinary audits stay managed evidence. Significant owner choices belong through the loaded decision helper at ontology/decisions/<slug>.md, not audit conclusions. List owner questions and exact artifacts to clarify without silently deciding them. Confirm the repository remains unchanged.

## Pitfalls
- Effective game rules stay in canonical ontology; source precision never authorizes gameplay or labels. Do not record routine audits as research or routine approvals/reviews/commit/run logs as major decisions. Unmigrated historical records remain valid read-only references: no migration, reapproval or deletion. Future authorized §E/§7/README/status writes are concise links/current pending state, not duplicate histories; §E belongs to docs/ROADMAP/todo_decide.md, not ontology/domain/index.dsl.
- An empty ontology may fail while individual required tables or whole config blocks can still be missing; test both cases.
- Mutating typed properties tests validator facets; it does not prove a malformed on-disk row follows the same loader path. Exercise ingestion separately when relevant.
- validate() can report no new errors while previous errors remain; inspect the error collection too.
- A declared runtime deferral is not an undocumented drift. Older decision entries may be historical snapshots, so check later overrides.
- Do not treat absent generated artifact instances as existing broken gameplay; distinguish definition validation from generator/runtime constraints.
- A documentation-only validation-contract approval can settle policy without settling exact required paths, provenance inheritance or every constraint layer. Keep unresolved mappings explicit, distinguish documented requirements from implemented checks, and verify that executable code and live JSON remain unchanged.
- Status application during dodge does not prove that scheduled damage bypasses dodge. Trace the original status ID through config aliases and shared storage, then drive actual ticks and assert HP changes, cadence and feedback. Probe an ordinary hit after the tick and replacement by another effect to catch an immunity exemption leaking beyond its intended status.
- Resource-exhaustion probes must deliver consecutive complete hits without awaiting a physics/defence update. Exercise creature melee _tick and projectile-impact _strike paths; check HP, power, MP and attached statuses for both the exhausting hit and its successor, including a positive remainder below one hit's cost. Damage mutates power before statuses run: audit propagation of take_damage's per-hit block result, not just blocks_from's current state. A hit-time guard alone can wrongly expose the final valid block to statuses. Distinguish direct impact-callback coverage from flying-projectile coverage.
- For documentation/data-description reconciliation, distinguish optional type suffixes (int?, ref?) from uncertain source values and historical snapshots from current behavior. Parsers can hide duplicate JSON keys: inspect the raw diff/key occurrence as well as comparing sorted jq snapshots to prove effective values unchanged. Keep the existing open-question section unchanged and check runtime, validator/loader and research paths have no diff.
- For dynamic relations, distinguish entity-instance identity from catalog identity: ontology/domain/3_Classes.dsl (locator=creature) and model.gd Creature describe species, not individual mobs. Attach per-mob/player state to entity instances; keep pair-scoped amounts separate from target selection. Audit directed endpoints, optional cardinalities, per-pair uniqueness and units. Do not add static instance JSON or an enumerable Resource class for runtime relationship state; Markdown relationship checks and semantic review remain separate from the existing headless validator.
## Verification
1. Baseline command exit status and exact tested scope are recorded.
2. Each claimed reproduced defect includes observed and expected behavior.
3. No source files, canonical data or settled owner choices were changed by audit probes.
4. For historical attribution, pair each claimed subfact with its original retained-source passage and exact scope; check sibling clauses for narrower exceptions. A biome's version column does not automatically date its fauna, an identifier name does not prove shipped functionality, and preview/music-publication dates do not prove build inclusion.
5. Review actual source passages before accepting scout matrices. Separate retained-research evidence from fresh external verification, preserve qualified/unsupported histories and unresolved contradictions, and distinguish source attribution from owner-approved hybrid behavior. Check helper-shaped source evidence, exact anchors and unchanged current-rule impact; verify audit outputs are managed only and no recording authority was inferred.