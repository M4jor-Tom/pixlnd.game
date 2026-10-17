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
Rule: use a distinct fresh subagent for each selected item, sequential single writer and one
scoped item commit; one child processing the whole batch does not satisfy this instruction.
The narrow sourcing-only authority below is unchanged; this is not broader approval.
Owner approval-dispatch correction (retained in managed run
`9ea9ff24-5c4b-41cc-bf4f-ca74fe4b73f1/queue/2.json`, recorded here 2026-10-10):
**“Dispatch approvers telling them to approve 3-5 items depending on the size. Not having access
to the context seems to tie them to 1.”**
Rule: give approvers size-adjusted packets of **3–5 items**, with enough per-item context:
exact proposal/selected precision option, standing authority, evidence/uncertainty, dependencies
and documentation/implementation boundary. This changes approval dispatch only, not the distinct
individually scoped canonical recording, independent review and commit boundaries. It approves
no new candidates and cannot override an explicit finite session STOP.
Rule: apply this only to defensible sourcing-precision refinements of existing facts, preserving
source uncertainty and evidence limits. It grants no mechanics, source labels, live JSON,
checker/code/test changes or publication authority. Do not fabricate per-item owner answers.
Save exact selected items and the standing answer in the pending queue before canonical recording;
retain them until checks, independent review and commit are verified. Genuine new mechanics or
scope choices still require owner approval. Prior checkpoint STOP does not bar a separately
requested sourcing task; it supplies no authority for further implementation or publication.

## Pending choices are not a historical ledger

Required: follow the [repository workflow](../skills/ontology-resume-router-slice/repository-workflow.md#pending-choices-are-not-a-historical-ledger).

## Context-bounded reconciliation and retained selections

Rule: central information locations belong in `ontology/AGENTS.md`, not migration breadcrumbs; an unavailable init skill is not simulated.

Owner workflow update (2026-10-05): question batches must be ready at **~60% context maximum**;
begin handoff by **~85%**, earlier if the next item/review would consume the publication reserve.
Rule: use bounded inspection/delegation, stop new research/questions/items at the handoff boundary,
commit the checkpoint and push the authorized branch, verify publication, then STOP. Do not rely
on automatic compaction or invent context percentages when the meter is unavailable. An unavailable
meter alone is not an automatic one-item stop: inventory all currently defensible refinements,
retain every selection and use bounded per-item work with review/closure reserve. Genuine evidence
gaps remain research, not facts invented to fill a batch. If context-meter is unavailable, batch a
full topic together, and indicate to the user that he's responsible for your context management.

Owner instruction, refined 2026-10-05: use **`./docs/todo_handle_reconciled_items.md`** only for
decided but unhandled reconciliations, not completed history. Rule: save exact selections/amendments
and application status before recording; resume pending **Previously selected** entries without
unchanged reapproval. After canonical recording, checks, required review and item commit are
verified, retain significant choices in `ontology/decisions/`, findings in `docs/findings/`
and routine receipts in managed evidence. Remove resolved questions from `todo_decide.md`
and the handled queue entry; delete either pending file when empty. The former `docs/reconciled.md`
name is retired. Keep canonical rules in `ontology/domain/index.dsl`.

## Separate settled rules from stale executable data

Required: follow the [repository workflow](../skills/ontology-resume-router-slice/repository-workflow.md#separate-settled-rules-from-stale-executable-data).

## Resume the walkthrough, not gameplay implementation

Owner instruction (2026-09-15): **"resume walking through items"** must restore this same
interactive approach with any agent, without requiring the previous conversation.

1. Read this file, `ontology/AGENTS.md`, the unresolved choices in
   `docs/ROADMAP/todo_decide.md`, `docs/HANDOFF.md` and the relevant `ontology/` sources.
   Inspect the actual branch/diff; preserve pending edits and recorded approvals.
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

Required: follow the [repository workflow](../skills/ontology-resume-router-slice/repository-workflow.md#distinguish-retroactive-diminishing-returns-from-acquisition-order-rewards).

## Explicit family assignment overrides current data

- Rule: explicit owner assignment supersedes current-data classification. Conditional rarity
  does not authorize guessed encounter frequency, combat/loot tier or strength rules; clarify
  it separately without reopening the approved family assignment.

## Species amendments override preserved traits

- Rule: do not infer a food pairing or riding permission from “tameable”.

## State the denominator of an encounter chance

Required: follow the [repository workflow](../skills/ontology-resume-router-slice/repository-workflow.md#state-the-denominator-of-an-encounter-chance).

## Aggro decay is not forgiveness

Required: follow the [repository workflow](../skills/ontology-resume-router-slice/repository-workflow.md#aggro-decay-is-not-forgiveness).

## Normalize aggro gains across progression

Required: follow the [repository workflow](../skills/ontology-resume-router-slice/repository-workflow.md#normalize-aggro-gains-across-progression).
