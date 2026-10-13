## 0. Conventions

- Every class, relation, generator and instance has a **stable kebab-case ID**. IDs never change
  once referenced; rename the `name`, not the `id`.
- **Version tags** mark where a fact comes from, not pixlnd availability or implementation
  status. A feature may exist in several source versions; hybrid scope follows §1 and approvals.
  - `A`  Alpha 0.1.0 / 0.1.1 (July 2013)
  - `S`  Steam 0.9.x beta → 1.0.0-1 (Sept 23 – Oct 1 2019)
  - `Ω`  Cube World Omega (announced 2023-05-25, unreleased; only announced facts)
  - `X`  present in shipped data / devlog but cut, unused or never functional
- `?` after a source value marks uncertainty, including qualified version annotations such as `S?` / `A?` (§5 Validation-contract mapping item 3); §7 separates active hybrid questions from reference-only research gaps. In type notation (`int?`, `ref?`), it instead means nullable/optional, not an unanswered design question.
- Properties are split **intrinsic** (belong to the thing) vs **extrinsic** (references to other IDs).
- Runtime-generated content (terrain, dungeons, names, loot rolls, bosses) is **not** enumerated;
  its **generator** is a class (§6) and its config lives in `instances/generators.json`.
- Numeric formulas are written in plain infix. `lvl` = character level, `n` = item level.

**Undeployed-game clarification (owner, 2026-09-28):** no player data exists to migrate.
Require current approved definitions directly; obsolete checked-in values need direct replacement
when separately authorized, not save/config migrators, legacy-read fallbacks or compatibility
paths. Older “migration” deferrals in this document mean data correction/enforcement debt only,
not a migration plan. Stable source IDs and previously approved names remain unchanged.

---

