# Artifacts item 5 — Normalized logarithmic total

Use the [canonical artifact equation](../domain/3_Classes.md#artifact) with **initial z=0.1**.
Zero contributors make no change; the first gives **5%**. Totals increase without a hard cap,
with diminishing marginal gains. Positive `z` is the sole curve knob; there is no separate
logarithm-base knob.

This rejects decreasing totals and pickup-order-dependent larger grants. It supersedes only
[D6](numeric-design.md)'s artifact accumulation/decay/floor, not its other choices, reward
targets or the [artifact count per land](../domain/3_Classes.md#artifact). Earlier exponential and z-cancelling expressions
are not alternate modes. [Equal shares](artifact-additive-shares.md),
[recalculation](artifact-recalculation.md) and [no floor](artifact-no-floor.md) apply.

Obsolete live artifact values do not override this definition. Direct correction and
model/loader/validator/runtime enforcement remain separately deferred; no legacy migration
support is required ([current rules](current-rule-validation.md)).
