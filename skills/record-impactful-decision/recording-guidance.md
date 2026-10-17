# Recording guidance

Paths in backticks are relative to the repository root.

## Current information homes

| Information | Home |
|---|---|
| Gameplay definitions, effects, formulas, numbers, exclusions | Existing canonical `ontology/domain/`, stats, instances, constraints or generators as appropriate |
| Control meanings and lifecycles | `ontology/domain/controls.dsl` |
| Physical schemes, key bindings and device policy | `ontology/domain/controller-profiles.dsl` |
| Straightforward functional control/controller/binding separation | Canonical ontology classes and relations, linked to controls/profiles |
| Genuine engine/tool selection or non-obvious technical architecture tradeoff (e.g. performance) | Concise current technical record in `ontology/decisions/`; link domain facts rather than copy them |
| Source evidence and qualifications for an existing current claim | `record-finding`; not a historical narrative or transcript archive |
| Raw authority, conversations, source snapshots, capture/run metadata and check receipts | Managed evidence outside the repository |
| Deferred implementation | `docs/ROADMAP/todo_implement.md` |

Do not record historical facts or user exchanges in repository records. Do not relocate them
into findings, HANDOFF or another repository archive. This is not authority to purge unrelated
legacy material. Current-claim evidence/qualifications are distinct from historical narratives.

## Technical record review

Use one descriptive kebab-case file per actual technical choice or coherent technical bundle.
Record the current selection, necessary technical context and supported rationale/tradeoffs;
unknown reasoning stays unknown. Review after writing: route any gameplay or straightforward
functional requirement to its existing canonical ontology home, fold amendments into the current
rule and link it. Delete empty/redundant records and fix references without tombstones or archives.
No approval quotations, ballots, chronology, logs or duplicate domain policy belong in a record.
Do not infer a selected opposite from a rejected proposal. Authorization to document is not
implementation permission; preserve current scope and deferrals.

## Pending-only queues

`docs/ROADMAP/todo_decide.md` contains unresolved choices only; remove resolved entries and
delete it when empty. `docs/todo_handle_reconciled_items.md` contains only selected current
rules/options awaiting closure, with amendments folded in, status, dependencies and the
documentation/implementation boundary. Preserve pending selections without reopening them.
Exact conversations, approval messages and original dialogue stay in managed evidence, not queues.
Remove handled entries after the authorized closure checks; delete an empty queue. Do not create
completed-item indexes, parallel histories or a new queue when nothing is pending.

## Boundaries

Canonical [domain](../../ontology/domain/index.dsl) and [instances](../../ontology/instances/)
remain authoritative; stale executable values do not overturn precise approved rules.
Distinguish scoped approximations from final rules and permanent exclusions. Optional/null
fields are not automatically unknown facts or undecided choices. Require current rules directly;
see [current-rule validation](../../ontology/decisions/current-rule-validation.md).
[Open validation points (locator=7-open-points-for-validation)](../../ontology/domain/7_Open_points_for_validation.dsl)
and [implementation debt](../../docs/ROADMAP/todo_implement.md) retain their existing homes.
A green validator proves only implemented checks, not complete consistency or runtime behavior.
