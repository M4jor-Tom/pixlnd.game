# Validate at the appropriate boundary

Definition/config load checks, generator checks and runtime/save/import checks have distinct
responsibilities. Follow the canonical
[check-boundary mapping](../domain/5_Constraints.md#item-4--required-inputs-source-scopes-and-check-boundaries);
valid definitions do not prove generated objects or runtime behavior. Missing whole inputs
and cumulative errors remain governed by the [validation contract](../domain/5_Constraints.md#validation-contract-item-9-owner-approved-2026-09-17).
Enforcement is separately deferred, not authorized by documentation.
