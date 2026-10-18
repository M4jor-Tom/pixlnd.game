---
name: record-finding
description: Use when authorized source precision or provenance research concerns an existing claim in pixlnd.
version: 1
created: "2026-10-13"
updated: "2026-10-13"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

# Record Finding

## When to Use
Substantive source research about an existing claim: attribution, identity, provenance, qualified detail or contradictory evidence. Not routine approvals/refusals, reviews, commits or run logs. The effective game contract stays in ontology; a finding is research, not a competing specification.

## Procedure
1. Before FUTURE repository recording, require explicit repository write authority and actual exclusive worktree ownership within current scope. Stop if either is absent; respect other writers.
2. Duplicate-screen existing findings and legacy records by claim, topic, qualifications and provenance. Reuse the matching topic/anchor in `docs/findings/<slug>.md`: one coherent finding, not one file per workflow step. If already recorded with no substantive delta, reference it without a new record. Unmigrated historical records remain valid read-only references; this policy authorizes no migration, reapproval or deletion.
3. Record only the authorized new substantive delta, with these parts:
   - **Claim and domain link:** the precise existing claim and its canonical ontology anchor; link relevant legacy references without copying their blocks.
   - **Source identity and passage:** exact author/source, URL or identifier, only the passage/locator needed to support the current claim and its qualifications. Keep raw source snapshots, revision/capture metadata and digests in managed evidence; distinguish retained evidence from freshly verified bytes and mark unavailable evidence unknown.
   - **Evidence:** supporting and contradictory evidence, with exact locators and qualifications. Separate developer authority from community reports; identifiers from shipped functionality. Preserve current-claim qualifications; raw capture/revision chronology belongs in managed evidence.
   - **Certainty and unknowns:** preserve approximations, contradictions and limits; never guess edition/build availability or authenticate a build from a name, timestamp or ID.
   - **Conclusion and current-rule impact:** narrowly supported conclusion; state impact explicitly, often **NONE**, and point to the unchanged effective rule. Major behavior choices require distinct explicit approval, not this finding.
4. Follow [current recording routes](../record-impactful-decision/recording-guidance.md). Findings contain current-claim evidence/qualifications, not historical narratives or user exchanges; never use findings as a backdoor archive for deleted decision history. Raw authority, source snapshots and run/capture metadata stay in managed evidence outside the repo. Authorized ontology/ledger references are compact pointers, not duplicate research archives. Routine execution/approval metadata and review/commit/run receipts belong in managed evidence, not the finding. Preserve exact source qualifications through simplification and review.

## Pitfalls
Standing source precision authority never authorizes gameplay or labels. Citation approval grants no balance, JSON, runtime, checker or test changes. A refusal rejects that proposal, not its opposite; it is not substantive research or a major decision by itself. Missing edition proof limits the conclusion, not every qualified attribution.

## Verification
Check authority/ownership, novelty, matching topic/anchor, source-to-claim fidelity, supporting/contradictory evidence, uncertainty and explicit current-rule impact. Confirm no legacy blocks moved or duplicated, no routine logs archived, and no gameplay or label changes. Claim only checks actually performed; independent review and future repository gates remain separately required.
