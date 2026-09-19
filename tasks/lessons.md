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

## Aggro decay is not forgiveness

- Owner direction/correction (2026-09-18): threat decays continuously at a fixed rate for each
  mob/player pair, in and out of combat; hits add threat while that decay continues. Losing
  highest-threat priority does not clear the remaining score: if the teammate dies, the mob
  can target the original player again under normal priority rules.
- Rule: distinguish threat amount from current target selection. Never treat target switching
  as forgiveness, decay as out-of-combat-only, or attacking as pausing/restarting decay.
  Example numbers are not approved balance values; confirm the rate separately. Keep runtime
  authorization and zero-threat/reset decisions separate from this ontology policy.

## Zero aggro clears historical tie priority

- Owner correction (2026-09-19): when a mob's aggro toward a player reaches zero, remove that
  player's old engagement-order position from that mob's tie-breaker memory. If needed afterward,
  determine a fresh tie-breaker; do not retain or restore the old priority.
- Rule: do not preserve historical tie priority at zero merely to keep engagement order stable.
  Scope clearing to that mob/player pair; preserve other players' state, normal detection and
  existing targeting priorities. Do not invent the fresh-order assignment trigger or treat this
  ontology correction as runtime, commit or push authorization.

## Normalize aggro gains across progression

- Owner correction (2026-09-18): award aggro by the percentage of a mob's maximum HP actually
  removed, not raw damage: 1 point per percentage point, including fractional gains. Equivalent
  hits must not take longer to decay merely because late-game HP/damage numbers are larger.
- Rule: use `100 × actual HP removed / mob max HP`, not remaining HP or attempted damage;
  check equal-percentage examples at different HP scales. Preserve continuous decay and target
  priority rules; this correction does not approve a decay rate or runtime implementation.

## Permanent exclusion: regional gear power loss

- Owner correction (2026-09-15): never propose or implement regional power loss in pixlnd,
  even when cloning Cube World. Crossing a region boundary must not weaken equipment.
- Rule: this is permanently excluded, **not** a v2 deferral, fidelity tradeoff or alternate mode.
  Preserve historical Steam descriptions only as non-shipping reference; they cannot override
  this decision. Do not present regional power loss as a possible consequence to choose.
