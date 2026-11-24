# Preserve model observation boundaries during decomposition

Date: 2026-10-30

## Context

The [selected engine](engine-choice.md) must support the model's existing public
construction, types and observable validation behavior within the
[code-size and complexity limits](../quality-checks.md).
A smaller function is not equivalent if it changes callback order, error ownership,
subclass dispatch or which remaining checks execute after a GDScript error.

## Decision

Keep the public preload entry point and concrete Resource/enumeration definitions in
[`model.gd`](../../ontology/model.gd). Keep typed operations involving those definitions in that
facade, avoiding helper-to-facade preload cycles.

Use one [`model_ontology.gd`](../../ontology/model_ontology.gd) implementation base for existing
instance state, forwarding and necessary same-instance validation phases. Extract
other cohesive families into focused `model_*` modules. This is implementation
structure, not a new domain hierarchy or state owner.

Preserve original evaluation and failure boundaries:

- Carry a backing Resource when its fields must be reread after callbacks; retain
  an earlier Dictionary alias when the original deliberately captured that alias.
- Keep potentially failing expressions in their original-equivalent execution
  scope. Use direct typed-return phases where necessary to preserve propagation.
- Where a split loop needs a completion result, distinguish ordinary invalid data
  from an execution error. Do not turn accumulated validation errors into fail-fast
  control flow or promote a smaller helper's failure to its caller's scope.
- Keep callback-sensitive lexical static calls in meaningful same-instance phases.
  Do not replace them with a fixed module receiver or script-introspection proxy.

## Alternatives considered

Keeping every operation in one script conflicts with the selected hard limits.
Moving public definitions behind new imports risks changing construction and type
identity. Retaining those definitions and moving implementation responsibilities
avoids that additional compatibility boundary.

Fixed-module calls can lose inherited static overrides. `get_script()` and the
`script` property can invoke user-defined behavior that an original lexical call
did not invoke; they are not transparent dispatch substitutes.

## Consequences

Additional implementation phases and forwarding are necessary. Keep them cohesive,
not a general validation framework or one helper per branch. A successful numeric
conversion does not make later operations on the original Variant safe, so preserve
entire short-circuit expressions rather than extracting unsafe recovery predicates.

## Resumption and verification

Use the existing model compatibility checks and the
[shared verification policy](../quality-checks.md). Changes to these seams
need original/current controls for callback read order, retained aliases, local and
global error ownership, malformed values and inherited dispatch, followed by the
affected game checks. Passing finite checks is not a universal equivalence proof.

The canonical [domain model](../../ontology/domain/index.md) and
[validation contract](../../ontology/domain/5_Constraints.md#validation-contract-item-9-owner-approved-2026-09-17)
remain authoritative. This technical structure selects no new gameplay rule,
validation obligation or permission to bypass a quality check.
