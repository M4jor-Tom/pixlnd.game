## 1. Scope

**Reference domain:** a seed-driven voxel, third-person action RPG, historically described as
“infinite” (not the hybrid bound below), with 8 races ×
4 classes × 2 specializations, procedurally generated lands (biomes, dungeons, settlements,
missions), a tame-anything pet system, crafting, and drop-in co-op. The original Cube World
shipped two rulesets with **mutually exclusive progression**; these are historical comparisons,
not additional playable modes in pixlnd. The chosen hybrid target is listed alongside them:

| Ruleset | Progression | Gear scope | Traversal unlocks | Fast travel |
|---|---|---|---|---|
| `ruleset-alpha` (A) | XP → levels → 2 skill points/level, skill tree, item power +1..+100 | global, Adaptation re-levels gear | skill tree + bought glider/boat | portals (rune stones), revival statues |
| `ruleset-steam` (S) | no XP; level = artifacts found; gear is the only combat power | **region-locked**; `+` items work in adjacent regions | per-region key items + artifacts | shrines of life, flight masters |
| **`ruleset-hybrid` (chosen)** | alpha XP/levels/skill tree | global, never degrades | skill tree + key items (global once found) + artifacts | portals, shrines, flight masters |

Everything else (world, creatures, weapons, combat feel, crafting stations, pets, settlements) is
shared with version-specific deltas.

**Decision D1 (owner, 2026-09-07): ship `ruleset-hybrid`.** Alpha progression (XP → levels →
skill points, skill tree, item power, adaptation, spirit cubes, formulas) **plus** approved Steam
content, subject to D3/D4 and subsequent approvals (key items, artifacts, lore, arenas, factions
and events, shrines, flight masters, elixirs, gnome suppliers, books of crafting).
**Region lock is dropped** (D4): equipment never loses power
when the character travels; there are no `+` items, no `worn` degradation, no per-land inventory
pages, and key items work everywhere once found. Artifacts stay as permanent collectibles
with traversal and D6 attack/maximum-HP rewards, but do not grant character levels.
Flags in `instances/rulesets.json#ruleset-hybrid`.
Alpha/Steam rulesets remain documented for reference only.

**Permanent exclusion (owner reaffirmed 2026-09-15):** never propose or implement regional
gear power loss in pixlnd, even for Cube World cloning fidelity. This is not a v2 deferral or
an alternative mode. Historical region-lock data is reference only, never an implementation target.

**Hybrid v1 scope (item 8, owner approved 2026-09-15):** the approved hybrid above, with D1–D26
and subsequent reconciliation approvals preserved. Ontology coverage is broader than v1:
`X` cut/data-only content and `Ω`-only announcements are reference/roadmap material, not launch
availability, even if a historical flag is true. Their existing definitions and provenance remain.
**Current-build coverage:** dated slice notes and `generators.json#design` describe approved
implementation stages, including temporary approximations, not proof that the final target is
implemented. Later decisions supersede earlier placeholders. Current decision/research status
is indexed in [§7](7_Open_points_for_validation.md#7-open-points-for-validation);
this scope clarification does not authorize gameplay changes.
**Out of scope:** Picroma's engine internals (Plasma GUI runtime, DX11 renderer), the exact
network byte layout of the 2013 protocol (kept as reference only), Steam platform integration,
Omega content beyond what was publicly announced.
**Roadmap, not a release promise:** cut content and Omega-only systems (weather, procedural body
parts, signature abilities per species, coarse-map-first generation) remain in `docs/ROADMAP/`
under D3/D4. Modeling them does not authorize enabling them; a later inclusion needs owner approval.

---

