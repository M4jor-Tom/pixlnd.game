# LinkML, C# and stateless local quality

## Technical contract

LinkML is the sole authored structural model and relationship definition. Schema-generated
C# lives in `game/generated/`; neither handwritten DTO mirrors in `ontology/` nor manual
changes to generated output are permitted. Generate structural reference metadata and human
reference pages from that same schema. Stable element identities connect definitions to
[canonical gameplay prose](../domain/index.md); schema descriptions explain local definitions,
not duplicate long-form rules, formulas or balance tables.

C# owns complete model-dependent operations: admission/loading, structural and reference
integrity, custom rules/formulas and their actual consumers. A POCO → JSON/dictionary →
GDScript catalog bridge is not the architecture. Keep unrelated GDScript behind ordinary
Godot nodes, commands, signals and narrow Variant-compatible results. A command result may
contain values needed by that operation; it must not expose a generic catalog traversal API.
Move only dependency-proven responsibilities, not the whole game by assumption.

Generated declarations do not replace behavioral validation. Every non-declaration operation
in `ontology/model*.gd` needs an explicit C# owner and retargeted checks before removal.
Preserve [validation failure semantics](../domain/5_Constraints.md), diagnostic accumulation,
fail-closed startup, immutable shared catalogs, separately owned mutable state and
[current-rule save protection](../domain/3_Classes.md#save-data). This is a technical migration,
not authority for gameplay fixes, deferred features or a legacy migration layer.

## Source and information boundaries

No provenance, `source_versions`, source-history aliases or execution status belongs in schema
definitions. Future manifests under `docs/findings/` catalog stable elements; population and
any reading of real findings must wait for the owner-supplied split findings. Preserve exact
qualified claims and unresolved attribution without fabricating sources. Schema migration
must not silently delete existing provenance checks while awaiting those inputs.

Long-form nonstructural rules stay in `ontology/domain/`. Implementation status and deferrals
belong only in `docs/ROADMAP/todo_implement.md` and `docs/HANDOFF.md`, never generated reference,
`game/README.md`, schema, technical design or plan execution ledgers. Plans are static recipes.

## Reproducible platform

All new system tools are Nix-managed with version/content pins; project packages have locked
content and an auditable restore path. Keep Godot **4.7.2** and explicitly qualify compatible
.NET SDKs, JDK, scanner, server and database. No global installs, unmanaged engine, silent SDK
upgrade, disabled package audit or offline certificate-revocation workaround as a production
default. A missing package or unsupported combination blocks adoption rather than changing
versions without authority.

Qualify Android .NET compilation and export before broad migration. Preserve the existing
Linux, Windows, macOS and Android presets/artifact contracts, and verify managed/runtime
companions survive final packaging, not just directory export. Qualify the final AppImage
launch; an incomplete single-executable Windows deliverable requires owner-approved packaging
before adoption. Godot 4 .NET's unsupported Web export is a constraint, not permission to delete
a target. Export qualification establishes no signing, publication or device/hardware acceptance.

## Stateless quality contract

A repository Nix app provides command-line SonarQube **Community Build** through the
**SonarScanner for .NET** begin/build/test/end workflow. Standalone Scanner CLI cannot analyze
C#; the separate proprietary-bundled nixpkgs `sonarqube-cli` companion is not required.
Use one implementation manually, at every pre-push (including documentation-only pushes),
and in CI. Preserve the existing locked-Nix checkout/index policy, not arbitrary pushed-ref
archives, and preserve the existing GDScript gate and its one named Android test deferral.

Each run creates and tears down its own loopback-only server, database, indexes, scanner
workspace, credentials, profile, gate and analysis. Nothing Sonar-derived persists between
runs, on success or failure; print actionable redacted diagnostics before cleanup, never
archive/upload reports or caches. Only immutable Nix artifacts and committed configuration
persist. Isolate concurrent runs or reject/serialize them explicitly. Own processes by verified
identity; clean up errors, deadlines, SIGINT and SIGTERM without broad `pkill` or host services.
SIGKILL/power loss cannot be trapped: launch ownership must be durable before releasing a child
to start server work; next setup safely discards stale owned state without reusing results or
terminating unrelated processes. Include boot identity in recovery. Cleanup failure is gate failure.
No privileged host tuning or container-daemon provisioning is implied; unmet Elasticsearch,
qualified effective-memory/heap or disk-space prerequisites block before server startup.
H2's evaluation-only support is not production database qualification.

Enforce zero detected violations under a committed, versioned required-rule profile across
**all current in-scope code**, not a baseline, new-code-only gate or acceptance inherited from
another run. Explicit overall-code gate conditions, completed server compute, exhaustive issue/
hotspot queries and independently verified analyzed-file coverage are required. Empty discovery,
missing/skipped sources, analyzer errors, provisioning drift, timeouts and unverifiable coverage
fail closed. Generated code and tests receive the required checks, not blanket exemptions.
A passing gate is not a mathematical guarantee of bug-free code.

Keep formatting (`dotnet format --verify-no-changes`), compiler/analyzer failures, test results
and server quality results independently fatal. Enforce **600 physical lines/file**, **100
physical lines/callable** (including internal comments/blanks, accessors, local functions and
lambdas) and **cognitive complexity 15/function**. Sonar C# cognitive complexity is distinct from
gdmetrics C-COG. Verify native rule coverage first; add only the smallest syntax-aware Roslyn
or native supplement for demonstrated gaps. No broad suppressions, issue baselines or generated/
test exclusions to get green. Define coverage metrics/denominators explicitly; this contract
selects neither an arbitrary 100% execution-coverage threshold nor all available Sonar rules.

## Acceptance and qualification boundaries

- Prove actual compatible pinned tools and secure restores; fixture-only generation is not a
  full-schema dialect converter, automatic reference validator or typed runtime consumer proof.
- Prove deterministic generation, exact serialized aliases, keyed identity, null/omission policy,
  enum validity, typed-target references, compound uniqueness and complete rule ownership.
- Prove a real C# consuming runtime slice without the rejected bridge, then preserved gameplay,
  seeded/RNG behavior, save rejection/original-byte protection and all retained checks.
- Prove Android .NET and final desktop packages, including managed/runtime contents and an
  isolated final AppImage launch, without changing engine version/targets or unapproved artifacts.
- Prove outside-shell bare-remote push success and blocked invalid push with unchanged remote;
  the same defect fails manual and CI paths. Old-code findings, repeated fresh runs, profile
  drift, missing/generated/test files, async false-green and lifecycle failures need regressions.

The [quality plan](../../docs/superpowers/plans/2026-11-04-stateless-csharp-quality.md) supplies
platform and gate qualification; the dependent
[migration plan](../../docs/superpowers/plans/2026-11-04-linkml-csharp-migration.md) supplies
schema and consumer cutover. Those local plans are intentionally ignored by Git.
Documenting the contract grants no execution, commit, push, gameplay or publication authority.
