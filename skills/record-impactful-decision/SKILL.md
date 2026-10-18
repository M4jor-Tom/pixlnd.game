---
name: "record-impactful-decision"
description: "Use when routing an authorized game, domain, control or technical choice in pixlnd, or reviewing a technical record for misplaced domain information."
version: 2
created: "2026-10-13"
updated: "2026-10-14"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

# Record Impactful Decision

## When to Use
Route authorized substantive choices to their current information home. Gameplay significance
does not justify a decision record. Required: follow the [recording guidance](recording-guidance.md).

## Procedure
1. Require explicit repository write authority, its exact scope and exclusive worktree ownership.
   Stop if absent. Never infer approval from silence, review or checks; rejecting a proposal
   does not select its opposite. Documentation approval grants no gameplay, labels,
   behavior-changing JSON, runtime, loader, checker, tests, commit or push permission.
2. Classify the selected current information using the guidance table. Put gameplay meanings,
   formulas, numbers, exclusions and straightforward functional architecture in their existing
   canonical ontology homes, with amendments folded into the effective rule. A consequential
   permanent gameplay exclusion is a rule, not an ADR. Source-claim precision uses `record-finding`.
3. Duplicate-screen the existing topic and stable IDs. Only a genuine nontrivial technical
   choice or non-obvious technically motivated architecture warrants `ontology/decisions/<slug>.md`.
   Reuse a matching record; routine approvals/refusals, checks and status changes create no record.
   Do not migrate or purge unrelated legacy records without authorization.
4. A technical record contains the current selected tool/technical choice, necessary technical
   context, supported rationale/tradeoffs and links to canonical domain meanings. State current
   implementation/authorization limits. Do not invent rationale, alternatives, dates or IDs.
   Do not include history, owner exchanges/approval messages, execution logs or duplicate domain facts.
5. **Post-record classification review is required.** Read the entire record: move any domain
   information into its appropriate existing ontology home and replace duplication with links.
   Remove an empty/redundant record and repair incoming navigation; do not leave a tombstone or
   archive its removed history elsewhere in the repository. Keep raw authority and check evidence
   in managed evidence outside the repository. Preserve every effective rule and boundary.

## Verification
Check authority, classification, amendments, deduplication, links and effective-rule fidelity.
Confirm technical records contain only current technical choices, not gameplay policy or transcripts.
Use the pending-only queue contract in the guidance; claim only checks actually performed.
Independent review remains required; a green validator proves only its implemented checks.
