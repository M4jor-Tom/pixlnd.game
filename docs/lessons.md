# Lessons

## Ontology walkthroughs: describe the finished game

- Owner preference: propose each decision in gamer-facing terms, as it would finally play, rather than leading with schema edits or current implementation limitations.
- Rule: explain the player action and consequence, distinguish settled rules from each proposal, and use the topic-batched approval protocol below. Record deferrals; ontology approval alone does not authorize gameplay implementation.
- Owner correction: include the built-game consequence of not approving each item, not only the proposed benefit.
- Rule: every proposal states both approval and non-approval outcomes for players. Distinguish current behavior from a future risk or unresolved design; never claim declining a documentation correction immediately breaks the game or approves the opposite rule. If neither choice changes the already-approved game, say so.
- Owner correction (2026-09-19): use **"Approval versus Refusing"**, not "Approval versus leaving it open", for future items.
- Rule: use that exact heading and describe the player-facing consequences of accepting or refusing the proposal. Refusal rejects this proposal; it does not silently approve the opposite mechanic.
- Owner clarification (2026-09-19): a question about a mechanic is not a correction or rejection. Rule: answer it without withdrawing the proposal or recording a design-failure lesson; additional mechanics can address the concern separately.

## Standing approval for sourcing precision

Owner prior exact answer (2026-10-05): **“If the items are about accepting or refusing to add more precision to the sourcing of a data, auto-approve it”.**
Owner reaffirmation (2026-10-09): **“Auto-accept all items which are about the topic of augmenting the precision of sourcing or not.”**
Owner further instruction: **“Auto-accept all items which are about the topic of augmenting the precision of sourcing or not, each in one separate subagent.”**
Owner latest exact reaffirmation: **“For all items about accepting/refusing to increase the source precision of informations, auto-accept each of them in subagents”.**
Rule: use a distinct fresh subagent for each selected item, sequential single writer and one
scoped item commit; one child processing the whole batch does not satisfy this instruction.
The narrow sourcing-only authority below is unchanged; this is not broader approval.
Rule: apply this only to defensible sourcing-precision refinements of existing facts, preserving
source uncertainty and evidence limits. It grants no mechanics, source labels, live JSON,
checker/code/test changes or publication authority. Do not fabricate per-item owner answers.
Save exact selected items and the standing answer in the pending queue before canonical recording;
retain them until checks, independent review and commit are verified. Genuine new mechanics or
scope choices still require owner approval. Prior checkpoint STOP does not bar a separately
requested sourcing task; it supplies no authority for further implementation or publication.

## Browser-first source retrieval

Owner instruction (2026-10-05): try Playwright first; ask for manual authentication if needed;
use bash/curl otherwise, but stop on an unwanted result.
Rule: use Playwright before shell retrieval. Pause for the owner to handle login/access checks
manually; never request credentials or automate a bypass. Shell fallback covers technical browser
unavailability, not access denial. Stop on unexpected redirects, error/challenge pages or unusable
source content; retain the failure evidence rather than retrying around it.

Owner correction (2026-10-05): the headed Chromium UI remained blue/unresponsive; use a
different browser. Rule: when the owner requests a browser switch for manual access, use
another already-installed browser rather than repeating automated retrieval or guessing at
rendering fixes. Browser switching does not authorize challenge bypass or resumed research.

Owner correction (2026-10-05): Firefox was reopened with the wrong profile.
Rule: confirm the owner's intended logged-in profile before restarting Firefox; do not infer
it from an existing process's `-P` argument or the default-profile flag. On a profile mismatch,
stop automation and ask which profile to use instead of silently choosing another.
Owner selected `default` and explicitly asked to preserve remaining `privacy` windows.
Rule: inspect and act only on the confirmed default profile's process/lock; never close or
kill unrelated Firefox profiles, and never delete a lock without proving no live owner holds it.

## Context-bounded reconciliation and retained selections

Owner workflow update (2026-10-05): question batches must be ready at **~60% context maximum**;
begin handoff by **~85%**, earlier if the next item/review would consume the publication reserve.
Rule: use bounded inspection/delegation, stop new research/questions/items at the handoff boundary,
commit the checkpoint and push the authorized branch, verify publication, then STOP. Do not rely
on automatic compaction or invent context percentages when the meter is unavailable. An unavailable
meter alone is not an automatic one-item stop: inventory all currently defensible refinements,
retain every selection and use bounded per-item work with review/closure reserve. Genuine evidence
gaps remain research, not facts invented to fill a batch.

Owner instruction, refined 2026-10-05: use **`./docs/todo_handle_reconciled_items.md`** only for
decided but unhandled reconciliations, not completed history. Rule: save exact selections/amendments
and application status before recording; resume pending **Previously selected** entries without
unchanged reapproval. After canonical recording, checks, required review and item commit are
verified, retain completed decisions/receipts in §E and remove the queue entry; delete the file
when empty. The former `docs/reconciled.md` name is retired. Keep canonical rules in
`ontology/domain.md`; item 39's visual bug remains documentation only, never implemented.

## Separate settled rules from stale executable data

- Owner clarification: artifact data still describing pre-logarithmic bonuses is stale checked-in data, not a new choice about the approved accumulation rule.
- Rule: lead with the latest canonical decision, then distinguish superseded data from missing enforcement. Hypothetical invalid output does not mean the definition permits it; do not ask to reapprove settled mechanics when proposing validation documentation.
- Owner correction (2026-09-28, validation mapping item 4): the game is undeployed; no player data exists to migrate. Require the current rules directly.
- Rule: do not plan or implement migrators, legacy-read fallbacks or compatibility paths for obsolete saves/config. Direct checked-in data correction and enforcement still need separate authorization; documentation approval does not permit them.

## Resume the walkthrough, not gameplay implementation

Owner instruction (2026-09-15): **"resume walking through items"** must restore this same
interactive approach with any agent, without requiring the previous conversation.

1. Read this file, `docs/ROADMAP/todo_decide.md §E` (especially the resume checkpoint, approvals,
   open questions and application checklist), `docs/HANDOFF.md` and the relevant `ontology/`
   sources. Inspect the actual branch/diff; preserve pending edits and recorded approvals.
2. Resume the checkpoint's unfinished topic/items; otherwise take the next open topic. Preserve
   item labels and approvals. Deferred implementation is not an unanswered design question.
3. Present **all known remaining questions for that topic together**, numbered, with concrete
   gamer-facing recommendations. Use **"Approval versus Refusing"** for the player consequences;
   distinguish settled rules, current behavior, temporary approximations and future risks.
4. Wait for answers (or apply the bounded standing sourcing approval above), then check them
   against one another and settled decisions. Refusal does not choose the opposite rule;
   questions are not rejection. Ask a follow-up batch for ambiguous,
   contradictory or newly exposed cases, adding topic items when needed. Never silently resolve
   conflicts, reopen settled choices or offer permanently rejected features.
5. Apply only approved, internally consistent ontology corrections; verify scope, run relevant
   checks, update approval/application status and checkpoint, and **commit each reconciled item
   separately**. Hold dependent items until their conflicts are resolved. Ontology approval does
   not authorize gameplay, validator or consumer implementation, including behavior-changing JSON.
   A green validator proves only its implemented checks, not full semantic consistency.
6. Continue within the topic until reconciled, then proceed to the next topic unless told to stop.
   On an explicit **handoff** request, record resolved/refused/pending items, outstanding questions
   and the exact next topic or unfinished items; **commit and push**, then stop. Otherwise do not
   push. The next agent resumes that checkpoint, not a gameplay implementation slice.

Owner workflow change (2026-09-27): topic-batched questions, consistency follow-ups, one commit
per reconciled item, and commit + push on handoff supersede the former one-question-at-a-time
protocol. Rule: update both entry-point documents when the walkthrough protocol changes.

Owner clarification: "commit several times" means commit the entire current diff, optionally
split into coherent parts—not further implementation rounds. Rule: preserve that scope; no
push without authorization.

Owner correction (2026-10-04): the current task is **handoff/review of the handoff**; a new agent
will start reconciliation. Rule: resume/compaction notices continue the authorized parent objective,
not the next topic. Review/finalize the handoff and stop; retain any unpresented research as unapproved
leads, not new numbered ballots or canonical decisions.

## Distinguish retroactive diminishing returns from acquisition-order rewards

- Owner correction (artifact item 1): contributors to the same traversal stat share the
  current rate, rather than preserving acquisition-order bonuses. The initial equal-share
  examples (5%; 4.5% each; 4.05% each) are superseded by item 5's logarithmic direction:
  total bonus must not fall when another artifact is collected, and zero artifacts give zero.
- Rule: distinguish equal sharing from the aggregate curve. Simplify proposed formulas to
  detect cancelled balance parameters; calculate zero/first/large-count cases and check
  monotonic totals before recording policy. Clarify units and conflicts with earlier floors;
  do not invent curve constants or silently add a clamp. Attack/HP count all artifacts (item 4).
  Do not extend the mechanism to other item kinds. Inspect their existing rules and ask before
  changing any existing reduction mechanism. Preserve independent approvals while clarification
  is pending; the owner's request to reformulate is not implementation permission.

## A percentage reduction is not a stamina exemption

- Owner correction (2026-09-28, traversal item 4): Climbing Spikes reduce climbing stamina
  consumption by **75%**, replacing the proposed infinite-endurance exemption.
- Rule: record the specified percentage, not zero cost or useless skill points. Do not infer
  stacking rules from a percentage; item 5's remaining-cost rule needed separate owner approval.
  Preserve source S behavior as historical reference and defer runtime implementation.

## Explicit family assignment overrides current data

- Owner amendment (2026-09-27): Skeleton Dog's primary family is `dogs`, not `skeletons`;
  descriptive skeleton membership and the independent undead category remain.
- Rule: explicit owner assignment supersedes current-data classification. Conditional rarity
  does not authorize guessed encounter frequency, combat/loot tier or strength rules; clarify
  it separately without reopening the approved family assignment.

## Species amendments override preserved traits

- Owner amendment (2026-09-27): item 7's Collie fallback is approved, but Skeleton Dog must
  be non-aggressive and tameable, not retain its old hostile/untameable traits.
- Rule: apply the explicit exception without reopening the approved mapping or rarity. Do not
  infer a food pairing or riding permission from “tameable”; clarify concrete dependencies and
  defer runtime implementation.
- Owner correction (2026-09-27, item 8): skeletal dogs behave like normal dogs; “skeletal” is
  a different dog breed, not a special behavior category. Item 9 separately approves Bubble Gum.
- Rule: reuse normal dog behavior in the same encounter/state. Do not invent Skeleton-Dog-only
  pacifism, retaliation or taming-provocation exemptions, or reinterpret “dog race” as a new
  playable race. Preserve the existing family/category distinctions and separately approved bait.

## State the denominator of an encounter chance

- Owner amendment (2026-09-27): Skeleton Dog's encounter chance is **1% relative to dog spawns**,
  not a relative weight against arbitrary creature species.
- Rule: record both the percentage and its population. An amended probability supersedes the
  earlier proposal; do not import unapproved roll-unit or habitat assumptions. Use plain
  encounter examples before implementation details.

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
