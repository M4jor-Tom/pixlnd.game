# Decision records

- Keep decisions only here, one file per actual choice or explicitly identified decision bundle.
- Use descriptive kebab-case filenames; retain known IDs and dates, never invent missing ones.
- Fold amendments into the final rule. Keep necessary numbers, exclusions, rationale and dependencies.
- Link related decisions instead of repeating their rules; age alone does not supersede a choice.
- Drop historical source facts and execution, review, build and publication receipts; do not archive them here.
- Source attribution is not hybrid policy. Approval to document a decision is not implementation permission.
- [Domain](../domain/index.md) and [instances](../instances/) remain the semantic/data source of truth.
  Obsolete live values cannot override later approved definitions.
- Distinguish a scoped implementation approximation from a final rule or permanent exclusion.
- [Current decision/research status](../domain/7_Open_points_for_validation.md#7-open-points-for-validation) and
  [deferred implementation](../../docs/ROADMAP/todo_implement.md) keep their existing homes;
  the unresolved-choice backlog is absent when empty.
- Optional/null fields are not automatically unknown facts or undecided design.
- Require current approved rules directly, not legacy compatibility; see
  [current-rule validation](current-rule-validation.md).
- A green validator proves only its implemented checks, not all prose, generated content or runtime behavior.
