---
name: "record-impactful-decision"
description: "Use when an owner makes a major meaningful game, domain or architecture choice in pixlnd."
version: 2
created: "2026-10-13"
updated: "2026-10-14"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

# Record Impactful Decision

## When to Use
Significant long-lived game/domain/architecture choices with real tradeoffs, substantial supersession or consequential permanent exclusion. The effective contract remains current ontology definitions; decision history preserves rationale/authority, not a second mutable balance config. These records hold impactful game information and belong in `ontology/decisions/<slug>.md`.

Required: follow the [recording guidance](recording-guidance.md) retained from the ontology instructions.

## Procedure
1. Apply significance before the accepted/rejected outcome. Routine approvals/refusals, reviews, citation corrections, checks and commit/run logs do not qualify; keep needed receipts in managed evidence. A consequential explicit permanent exclusion qualifies even when rejected. Source research belongs through `record-finding`, not here.
2. Require actual owner authority and its exact scope. Never automatically select mechanics, infer approval from silence/review/checks, or treat refusal as approval of its opposite. Before FUTURE repository recording require explicit write authority and actual exclusive worktree ownership. Stop if absent.
3. Duplicate-screen by topic and existing stable D/F/decision IDs across decisions and legacy references. Use one coherent record at `ontology/decisions/<slug>.md`, plural, not one per answer/workflow step. Reuse a matching new-policy record; minor corrections or status updates do not create endless new records. If already recorded with no substantive delta, reference it without creating another. Unmigrated historical records remain valid read-only references; no migration, reapproval or deletion is authorized.
4. Record only the authorized substantive choice, with:
   - **Title, status, date and IDs:** distinguish accepted/rejected/superseded authority from recording and implementation status; retain actual authority provenance. Missing dates, evidence or IDs remain unknown, never invented.
   - **Context:** the consequential problem, scope and settled constraints.
   - **Choice:** exact selected choice or consequential rejected proposal, exact exclusion scope and important owner amendments verbatim in their sequence. Preserve rejection without manufacturing an opposite rule.
   - **Rationale and alternatives:** actual tradeoffs and reasons; mark unavailable reasoning unknown.
   - **Domain-rule and finding links:** canonical effective-rule anchors and relevant findings; use `record-finding` for needed source evidence, not copied source transcripts.
   - **Supersedes / superseded links:** identify the affected choice and explicit replacement when applicable; preserve impactful rejected and superseded choices without reopening them. State conflicts/application gaps rather than silently merging rules.
5. Keep new decision history in this single home. Authorized indexes link; never copy history into domain §7, README, §E or HANDOFF. Reconciliation callers manage pending-only queues, context and existing Handoff policy; do not redefine them here.

## Pitfalls
Recording grants no gameplay, labels, JSON, runtime, checker or tests permission. Standing source precision authority never authorizes gameplay or labels. Historical descriptions cannot overturn owner choices.

## Verification
Check significance, exact authority/amendments, deduplication, record shape, links, status and uncertainty. Confirm one history home, unchanged legacy references and effective-contract separation. Claim only checks actually performed; independent review remains required.
