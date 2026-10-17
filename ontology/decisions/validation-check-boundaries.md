# Validate at the appropriate boundary

Definition/config load checks, generator checks and runtime/save/import checks have distinct
responsibilities. Follow the canonical
[check-boundary mapping (locator=item-4--required-inputs-source-scopes-and-check-boundaries)](../domain/5_Constraints.dsl);
valid definitions do not prove generated objects or runtime behavior. Missing whole inputs
and cumulative errors remain governed by the [validation contract (locator=validation-contract-item-9-owner-approved-2026-09-17)](../domain/5_Constraints.dsl).
Enforcement is separately deferred, not authorized by documentation.
