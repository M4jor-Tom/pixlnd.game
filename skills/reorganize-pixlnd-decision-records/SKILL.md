---
name: "reorganize-pixlnd-decision-records"
description: "Use when pixlnd decision documents mix approved choices, historical facts, execution receipts or ambiguous numbered summaries."
version: 1
created: "2026-10-15"
updated: "2026-10-15"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

## When to Use
For owner-authorized reorganization of ontology/decisions/, without changing game rules or implementation. Read current ontology/decisions/AGENTS.md; do not assume historical preservation is wanted.

## Procedure
1. Freeze inputs and HEAD/index/unapproved-file hashes outside the repo. Inventory each source independently, distinguishing actual choices, necessary scope, facts, receipts and introduction guidance.
2. Map substantive choices to descriptive files; consolidate same-choice amendments. Preserve known IDs only. If numbered proposals were compressed into an unmapped summary, ask before guessing boundaries; bare approval counts do not justify placeholder records.
3. Follow the owner's disposal policy. Preserve real design overrides even under F labels, but distinguish a chosen engine version from a subsequently implemented toolchain pin.
4. Use one writer under an exclusively owned hand.lock. Update necessary navigation and consolidate introduction guidance into the linked repository-owned recording guidance, retaining the mandatory decisions/AGENTS.md entrypoint. Keep coverage maps, checks and reports outside the repo.
5. Run simplification, ponytail review and source-to-output semantic review. Inspect incoming link wording as well as targets when removing an ambiguous attribution.
6. Apply justified corrections, rerun link/anchor/scope/whitespace checks and the timeout-bounded ontology validator, then release only the verified owned lock.

## Pitfalls
- A green validator or resolving Markdown link does not prove correct decision attribution.
- Generic taxonomy and a particular species override are separate choices; do not give both an uncertain historical item number.
- Preserve prior failed reviews and manifests; put correction evidence in distinct artifacts rather than rewriting earlier evidence.
- File-only subagents must emit a nonempty final acknowledgment after saving reports.

## Verification
1. Every retained decision has source-backed meaning, numbers and limits; history-only material follows current owner policy.
2. All new files and incoming links match the final decision boundaries; no invented IDs or promoted implementation receipts.
3. Only authorized files changed; HEAD/index remain unchanged unless separately authorized; owned lock is released.