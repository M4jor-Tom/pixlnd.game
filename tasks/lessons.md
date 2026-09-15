# Lessons

## Ontology walkthroughs: describe the finished game

- Owner preference: propose each decision in gamer-facing terms, as it would finally play, rather than leading with schema edits or current implementation limitations.
- Rule: explain the player action and consequence, distinguish settled rules from the new proposal, then ask one approval question. Record deferrals; ontology approval alone does not authorize gameplay implementation.
- Owner correction: include the built-game consequence of not approving each item, not only the proposed benefit.
- Rule: every proposal states both approval and non-approval outcomes for players. Distinguish current behavior from a future risk or unresolved design; never claim declining a documentation correction immediately breaks the game or approves the opposite rule. If neither choice changes the already-approved game, say so.

## Resume the walkthrough, not gameplay implementation

Owner instruction (2026-09-15): **"resume walking through items"** must restore this same
interactive approach with any agent, without requiring the previous conversation.

1. Read this file, `docs/ROADMAP/todo_decide.md §E` (especially the resume checkpoint, approvals,
   open questions and application checklist), `docs/HANDOFF.md` and the relevant `ontology/`
   sources. Inspect the actual branch/diff; preserve pending edits and recorded approvals.
2. Resume at the checkpoint's next unpresented item, keeping its number. Do not restart approved
   items or mistake an unchecked, explicitly deferred implementation for the next decision.
3. Explain one concrete recommendation in gamer-facing terms: what the finished game lets a
   player do and its rewards, costs or tradeoffs. Give both approval and non-approval outcomes;
   separate settled rules, current behavior, temporary approximations and future risks.
4. Ask **one approval question**, then wait. Never offer a permanently rejected feature as an
   option or reopen settled choices. Record a rejection/deferral without selecting its opposite.
5. On approval, record the precise authorization, apply only authorized ontology corrections,
   verify scope and run relevant checks, then update approval/application status and the checkpoint.
   JSON consumed by gameplay can change behavior without code edits; ontology approval alone
   does not authorize gameplay, validator or consumer implementation. A green validator does
   not prove complete semantic consistency. Commit/push only when authorized.
6. Normally continue one item at a time after recording the answer. Honor explicit stop points:
   stop after the requested item, record the next unpresented item, and wait for a resume request.
   Never turn this prompt into an automatic implementation slice or batch approval.

Owner clarification: "commit several times" means commit the entire current diff, optionally
split into coherent parts—not further implementation rounds. Rule: preserve that scope; no
push without authorization.

## Permanent exclusion: regional gear power loss

- Owner correction (2026-09-15): never propose or implement regional power loss in pixlnd,
  even when cloning Cube World. Crossing a region boundary must not weaken equipment.
- Rule: this is permanently excluded, **not** a v2 deferral, fidelity tradeoff or alternate mode.
  Preserve historical Steam descriptions only as non-shipping reference; they cannot override
  this decision. Do not present regional power loss as a possible consequence to choose.
