# Validate required heterogeneous inputs

Require the approved hybrid's data paths and documented heterogeneous root/row shapes,
not just whichever inputs happen to load. Missing required inputs must fail rather than skip
checks. Exact paths and shapes remain in the canonical
[validation mapping (locator=item-4--required-inputs-source-scopes-and-check-boundaries)](../domain/5_Constraints.dsl).
This is not permission to implement loaders/checkers or activate reference-only content.
