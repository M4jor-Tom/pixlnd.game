# Phase-1 structural coverage

This is an anchor-to-element/test map, not a second definition of properties or
relations. YAML declarations are authoritative for structure. The accepted
candidate starts with 21 YAML modules, seven test files / 72 methods and the
current-save fixture. Task 1 adds tooling and three root-guard methods only;
it does not establish full-family admission or complete the structural cutover.

## Standalone checks

From the repository root, use the pinned Nix shell and locked Python project:

```sh
timeout 330 nix develop --no-update-lock-file -c uv run --project tools/ontology --locked -- \
  python -m unittest discover -s tests -p test_ontology_schema_contracts.py -v
timeout 3600 nix develop --no-update-lock-file -c uv run --project tools/ontology --locked -- \
  python -m unittest discover -s tests -p 'test_ontology_schema*.py' -v
timeout 330 nix develop --no-update-lock-file -c uv run --project tools/ontology --locked -- \
  linkml-lint --config .linkmllint.yaml ontology/schema
```

Callers must allow 390 / 3660 / 390 seconds respectively. Python 3.12 comes
explicitly from the existing Nix pin; uv interpreter downloads are disabled.
`tools/ontology/uv.lock` pins transitive distributions and hashes. The Linux
Python wrapper supplies the pinned C++ runtime needed by LinkML's native wheel;
it does not set a global library path or change the Godot environment.
Generated JSON Schemas are temporary validation outputs, never parallel models.

`assert_root` in `tests/test_ontology_schema_contracts.py` checks class existence,
selected definition and root agreement before admission. It takes independent
literal property/required/policy expectations; typed-extra roots must supply
the exact expected subschema rather than asserting universal closedness.
Its negatives exercise unknown classes, wrong properties, weakened requiredness/
closedness and misdirected root references. They mutate generated output, not
YAML. Future full-source contracts must use the guard before any validation;
existing projection tests are not retroactively full-source contracts.

## Accepted anchor map (bounded starting coverage)

Paths below are relative to `ontology/`; test paths are relative to `tests/`.
This map references declarations, not copied field/type definitions. Each family
must extend it to every approved source path and convertible facet as authored.
Complete source envelopes, controls/profiles, encounter contracts and §6
configuration coverage are still a frontier, not silently admitted by projections.

| Source anchor/path | Explicit YAML element(s) | Existing contract evidence |
|---|---|---|
| `domain/3_Classes.md#entity` | `entities.yaml`: `entity`, `race-or-creature`, `entity-species` | `test_ontology_schema.py`: `test_entity_species_reference` |
| `domain/3_Classes.md#character-class` | `identity.yaml`: `character-class` | `test_ontology_schema.py`: `test_real_identity_projections_and_negative_controls` |
| `domain/3_Classes.md#specialization` | `identity.yaml`: `specialization` | `test_ontology_schema.py`: `test_imports_ranges_aliases_and_compound_keys` |
| `instances/abilities.json` (selected tree positions) | `combat.yaml`: `ability-tree-position` | `test_ontology_schema_authoring.py`: `test_ability_tree_unchanged_projections` |
| `domain/4_Relations.md` | `relation-types.yaml`: `threat-pair`; `relations.yaml`: `threat-mob`, `threat-player`, `aggro-points` | `test_ontology_schema.py`: `test_threat_association_numeric_contract` |
| `domain/4_Relations.md` | `associations.yaml`: `resource-cost`, `recipe-consumption`, `ingredient-yield` | `test_ontology_schema_authoring.py`: `test_payloads_and_compound_metadata` |
| `domain/3_Classes.md#save-data` | `associations.yaml`: `realm-knowledge` | `test_ontology_schema_authoring.py`: `test_lore_scope_is_logical_not_a_save_field` |
| `instances/equipment-slots.json` (selected acceptance facets) | `catalog-properties.yaml`: `slot-acceptance-condition`, `slot-acceptance-phase` | `test_ontology_schema_authoring.py`: `test_equipment_slot_conditional_acceptance_projections` |
| `instances/landscapes.json` (selected generation) | `world.yaml`: `landscape-generation` | `test_ontology_schema.py`: `test_real_specializations_and_landscape_configuration` |
| `instances/flora.json`, `instances/dungeon-types.json`, `instances/static-entities.json` (selected structures) | `structured-world.yaml`: `flora-yield-entry`, `dungeon-variant-entry`, `static-entity-catalog` | `test_ontology_schema_structured_world.py`: `StructuredWorldTests` |
| `instances/block-types.json` (scale/cub-format only) | `structured-world.yaml`: `block-type-catalog`, `block-scale`, `block-cub-format` | `test_ontology_schema_structured_world.py`: `BlockConfigurationTests` |
| `instances/poi-types.json` (selected pairs) | `world-catalog.yaml`: `poi-type-alpha-loc`, `poi-type-quarter` | `test_ontology_schema_world_catalog.py`: `PoiPairTests` |
| `instances/ingredients.json`, `instances/materials.json`, `instances/factions.json`, `instances/npc-roles.json` (selected rows) | `catalog-crafting-social.yaml`: `ingredient-refinement`, `material-class`, `faction-alignment`, `npc-role-service` | `test_ontology_schema_crafting_social.py`: `CraftingSocialTests` |
| `domain/controls.md` (all 54 canonical action IDs) | `meta.yaml`: `ControlActionId`, `control-action`/`bound-to-input`, `input-binding`/`input-binding-action`, `controller-profile`/`has-input-binding`; `catalog-meta.yaml`: source-only binding action mappings | `test_canonical_actions_and_selected_profile_are_not_inferred`, `test_profile_bindings_keep_phases_context_and_distinct_references`, `test_actual_yaml_mutations_keep_profile_option_and_reference_oracles`, `test_ontology_schema_ui_presentation.py` |
| `instances/rulesets.json` (complete source) | `catalog-meta.yaml`: `rulesets-source`, `ruleset-source-entry`, `ruleset-source-row`, `ruleset-source-flag-entry`; `meta.yaml:ruleset` | `test_whole_rulesets_source` |
| `instances/controller-profiles.json` (complete source) | `catalog-meta.yaml`: `controller-profiles-source`, `controller-profile-source-entry`, `android-profile-source-row`; `meta.yaml`: `controller-profile`, `has-input-binding`, `android-controller-profile`, `android-profile-parameters`, `input-binding` | `test_whole_controller_profiles_source`, `test_profile_bindings_keep_phases_context_and_distinct_references`, `test_android_profile_source_values_and_boundaries`, `test_actual_yaml_mutations_keep_profile_option_and_reference_oracles`, `test_actual_yaml_native_schema_mutations_for_profile_and_option_records` |
| `domain/controller-profiles.md#android` (Android parameter policy) | `meta.yaml`: `android-profile-parameters`, `android-controller-profile`, `android-profile-deadzone-ratio`, `android-profile-min-target-dp`, `android-profile-look-deg-per-safe-width`; `catalog-meta.yaml`: `android-profile-source-row` | `test_android_profile_parameter_facets_match_literal_policy`, `test_android_profile_source_values_and_boundaries`, `test_actual_yaml_native_schema_mutations_for_profile_and_option_records` |
| `instances/keybinds.json` (complete source) | `catalog-meta.yaml`: `keybinds-source`, `keybinds-source-profile-entry`, `keybinds-source-profile`, `keybinds-source-binding-entry` | `test_whole_keybinds_source`, `test_keybind_groups_keep_all_physical_aliases_and_metadata` |
| `instances/ui.json` (complete source, including UI metadata/envelopes) | `catalog-meta.yaml`: `ui-source` and source rows; `meta.yaml`: presentation/options/screens/context structures | `test_full_ui_missing_list_and_option_scalar_contract`, `test_ontology_schema_ui_presentation.py`, `test_ontology_schema_ui_screens.py` |
| `instances/audio.json` (complete source) | `catalog-meta.yaml`: `audio-source`, track/music-rule/ambient source rows | `test_whole_audio_source`, `test_history_and_audio_keep_source_qualified_values` |
| `instances/slash-commands.json` (complete source) | `catalog-meta.yaml`: `slash-commands-source`, command/chat-rule source rows | `test_whole_slash_commands_source`, `test_slash_command_keys_and_modded_server_context_are_literal` |
| `instances/versions.json` (complete history/delta/reception source) | `catalog-meta.yaml`: `versions-source`, `version-timeline-entry`, `version-delta`, reception rows | `test_whole_versions_source`, `test_history_and_audio_keep_source_qualified_values` |
| `instances/generators.json#design` (selected ability/progression projections) | `design-combat.yaml`: `ability-runtime`; `design-progression.yaml`: `progression-design` | `test_ontology_schema_authoring.py`: `test_current_design_ability_and_progression_projections` |
| `domain/3_Classes.md#save-data`, `tests/fixtures/ontology-schema/current-save.json` (repository fixture) | `save-world.yaml`: `save-data`, `world-state`; `save-character.yaml`: `character-state`, `saved-item` | `test_ontology_schema_authoring.py`: `test_synthetic_current_save_and_native_limits`, `test_current_world_envelope_and_nested_geometry`; `test_ontology_schema_contracts.py`: `FullInputContracts` |
| `domain/3_Classes.md#save-data` (selected content/combat) | `save-combat.yaml`: `saved-combat`; `save-content.yaml`: `saved-special` | `test_ontology_schema_authoring.py`: `test_current_combat_and_content_payloads`, `test_saved_special_empty_or_three_coordinates`, `test_saved_special_coordinate_bound_mutations` |

## Constraint/enforcement classification

1. **Declared and natively enforced:** selected scalar/list/union/enum ranges,
   requiredness, closed roots, numeric bounds and cardinality. Examples:
   `entity-skills` → `test_exact_count_boundaries`; `saved-special-origin` /
   `saved-special-endpoint` → `test_saved_special_coordinate_bound_mutations`.
2. **Declared, not fully enforced by this backend:** references/inverses, compound
   uniqueness and keyed identity agreement. `specialization.class-index` and
   `threat-pair.mob-player` are inspected by
   `test_imports_ranges_aliases_and_compound_keys`; `realm-knowledge` metadata by
   `test_lore_scope_is_logical_not_a_save_field`. Native keyed encodings can
   admit alternate bodies and key/body disagreement, explicitly characterized by
   `test_current_character_and_item_wire` and the UI identity tests. Retain the
   YAML facets; do not infer FK existence or source-wire equivalence from green.
3. **Behavioral/nonstructural:** gameplay timing and lifecycle/admission procedures
   remain in canonical prose, e.g. `domain/3_Classes.md#save-data` and
   `domain/encounter-contracts.md`. Structural cross-field rules/formulae are not
   automatically category 3: family work must inspect the pinned metamodel and
   qualify precise representable declarations before assigning this category.

Unmapped structural shapes remain unfinished work or blockers, never category 3
by default. `instances/deposits.json#sandstone-deposit.yields` retains its absent
ingredient target; `world-catalog.yaml:deposit-yields` retains the ingredient
range. Structural tests do not reconcile source data or prove FK existence.

## Native lint policy and diagnostic frontier

`.linkmllint.yaml` extends native recommended rules. Kebab class/slot naming
preserves accepted identifiers. Exact exclusions are naming-only: existing
`ability-_controls` (serialized alias `_controls`), the accepted legacy names,
source literals, and the 39 exact `ControlActionId` values listed under
`standard_naming.exclude`. Those values remain the canonical IDs in
[`domain/controls.md`](../../ontology/domain/controls.md); they are not renamed
in schemas or source inputs. LinkML 1.12.1 matches each excluded name globally
across element kinds, not only enum values, so this is a finite, disclosed
spillover—not enum-scoped enforcement. No element type, enum, naming pattern or
substantive declaration/range/identifier/key/metadata rule is excluded.
Task5 naming controls use one isolated positive fixture with all 54 canonical
IDs and separate negatives for malformed class, slot, enum and nonallowlisted
PV names plus an undeclared range; substantive native rules remain enabled.
This multi-root library has no imposed single `tree_root`.

Task1's directory command aborts on module-local undeclared slots; entry-only
lint is insufficient. The default entry reports 733 naming warnings; the
configured entry is clean, but nine standalone modules still abort during range
induction. Twelve finish, with retained module-local findings. This is **not a
complete native-rule baseline or a passing directory gate**. The pending blocker
is recorded in `docs/HANDOFF.md`; complete raw per-module diagnostics and
unobserved-rule accounting are retained in managed Task1 evidence.

Diagnostic lead ownership (not permission to fix unrelated source):

| Task | Existing modules/frontier |
|---|---|
| 2 | `identity`, `entities`, `combat`, `relations`, `relation-types`, `associations`, `catalog-properties`: missing imports/declarations and metadata; cross-family save associations may go to Task7 |
| 3 | `world`, `world-catalog`, `structured-world`: missing imports/declarations and metadata |
| 4 | `items`, `catalog-crafting-social`: missing imports/declarations and metadata |
| 5 | `meta`, `catalog-meta`: complete Task5 source coverage and no Task5-owned diagnostics after qualification; remaining diagnostics are in later-family modules. |
| 6 | `design-combat`, `design-progression`: ranges/metadata |
| 7 | All five `save-*` modules: ranges/metadata and unchanged `saved-hostility` H/N/P/F naming findings |

`pixlnd` is the shared importing entry. Task5's earlier qualified directory row
predates the round3 `bound-to-input`/`has-input-binding` attachments. The round4
frozen-pin directory row requalifies those attachments: its complete diagnostic
Counter and raw log are unchanged from that earlier frontier, with 28 errors
and 214 warnings across seven unchanged design/save owners, no added/removed
or `meta`/`catalog-meta`/entry-owned diagnostics. Managed round4 evidence records
the exact schema/config pins, raw log, normal wait2 and full Counter comparison.
Native directory lint still exits 2 and fails globally; Counter equality is not
a clean lint gate or a warning allowance. Tasks2–7 must run native directory
lint and assign every remaining/new diagnostic; Task9 requires exit 0 with no
warnings/errors. For aborted modules, remaining range checks plus identifier/
key/metadata/type/naming checks cannot be claimed observed.

## Generator readiness (not backend certification)

- **Imports/induced slots:** `test_imports_ranges_aliases_and_compound_keys`
  uses `SchemaView` across the entry graph. The identity/combat delta below adds
  explicitly tested inheritance; this does not certify all remaining family constructs.
- **Names/aliases:** `test_entity_species_reference` and
  `test_current_character_and_item_wire` inspect aliases and semantic URIs.
  Target-language names/reserved words/serialization policy belong to consumers.
- **Identifiers/local keys:** UI standalone/keyed identity tests and
  `test_current_character_and_item_wire` distinguish logical identity from
  container keys; key/body equality is not native enforcement.
- **References/inlining:** species scalar references and inline save payloads
  have native checks; target existence does not. Identity-free targets can force
  inlining; removing explicit inlining can have no emitted effect.
- **Lists/maps/unions/enums:** cardinality tests, association tests and the
  retained actual-YAML mutations qualify selected constructs, not every family.
- **Omission/null:** existing optional-boundary tests characterize backend null
  admission separately from source contracts. A key can imply requiredness even
  after `required: false`; native no-effect is not declaration equivalence.
- **Beyond typing:** retain logical facets and the enforcement classifications
  above. Synthetic-output guard negatives do not replace actual YAML mutations.

Any future direct GDScript backend should consume Python `SchemaView` and induced
definitions, not parse raw YAML or reverse-engineer JSON Schema. Generated data
holders do not replace loaders/validators. No backend, migration or ongoing
GDScript↔YAML drift enforcement is implemented or certified here.

## Identity, living entities and combat source contracts

This section extends the bounded starting map above. It covers eleven complete
unchanged documents, not projected rows. `ontology_source_contracts.validate_source`
checks the declared selected root before native validation; the independent literal
root expectations remain in `FullInputContracts`. The same shared root guard backs
both paths. Missing-class fallback is not admission.

All eleven documents currently use **bound source contracts**, not direct raw-wire
admission. Each flat catalog retains its explicitly declared metadata and moves
all remaining original key/value pairs into YAML-declared local entry records.
`stats-source` retains its fixed envelope and binds only the two catalog maps and
its decimal-level table. `source-map-entries` and `source-map-paths` describe that
structural representation. They do not define a consumer-specific mapping engine.
Keys are exact original container keys, never fabricated body/global identities.
Binding and inverse reconstruction preserve every value, reject overwriting or
duplicate keys, and prove complete-document round-trip equality. Catalog IDs do
not become model properties.

Native qualification (`test_native_source_styles`) establishes why this is needed:
`extra_slots.range_expression` can enforce nonnull rows with `required: true`, but
cannot constrain the dynamic property names. Native inlined keyed collections
also ignore the key pattern on object property names and permit SimpleDict scalar
shorthand. Required fixed fields and closed fixed/config/save-style roots work
directly. Only the demonstrated map mismatches are bound; no save/config adapter
or global generator-null change was introduced. Literal descriptive map labels
(e.g. forest roster variants, comparison colors and source attack names) are not
silently promoted to global ontology IDs. Native typing of those dynamic values
does not prove key/reference membership.

All elements in the following table are in `catalog-identity-combat.yaml` unless
another module is named. Tests are in `test_ontology_schema_contracts.py`.

| Complete source and non-row anchors | Explicit YAML elements | Whole-source evidence |
|---|---|---|
| `races.json`, including `$schema`, `_doc`, `_creation`, per-gender IDs/customization | `races-source`, `race-source-entry`, `race-source-row`, `race-source-ids`, `race-creation`, `source-version-text`, `source-version-text-lists`; existing `gender-option-counts` | `test_whole_races_source` |
| `classes.json`, including `_paladin` and `_shared.spec-change` | `classes-source`, `class-source-entry`, `class-source-row`, `class-reference`, `class-shared` | `test_whole_classes_source` |
| `specializations.json`, including explicit A/S passive/kit lists | `specializations-source`, `specialization-source-entry`, `specialization-source-row`, `source-version-abilities` | `test_whole_specializations_source` |
| `creatures.json`, including `_playable-races-as-enemies`, qualified role/hostility/habitat text and unrecorded source IDs | `creatures-source`, `creature-source-entry`, `creature-source-row`, `source-note-record` | `test_whole_creatures_source`, `test_creature_optional_boolean_null_boundary`, `test_source_optional_collections_are_not_null` |
| `creature-families.json`, including both distinct roster configurations | `creature-families-source`, `family-source-entry`, `family-source-row`, `forest-rosters`, `forest-roster`, `landscape-rosters` | `test_whole_creature_families_source` |
| `factions.json`, including separate `realm-name-examples` | `factions-source`, `faction-source-entry`, `faction-source-row`, `realm-name-examples` | `test_whole_factions_source` |
| `abilities.json`, including source costs/timings, tree/control references and `_omega-signature` | `abilities-source`, `ability-source-entry`, `ability-source-row`, `source-resource-amounts`, `source-ability-cost`, `source-version-quantity`, `signature-descriptions`; `combat.yaml:ability-tree-position` | `test_whole_abilities_source`, `test_source_optional_collections_are_not_null` |
| `weapon-types.json`, including `_controls`, unused rows and scalar/list attack IDs | `weapon-types-source`, `weapon-source-entry`, `weapon-source-row`, `weapon-source-controls`, `source-attack-ids`, `SourceHands` | `test_whole_weapon_types_source` |
| `status-effects.json`, including `ability-buffs` and `not-found` | `status-effects-source`, `status-source-entry`, `status-source-row`, `source-ability-buffs`, `SourceStatusKind` | `test_whole_status_effects_source` |
| `rarities.json`, including both comparison configurations and nullable source facts | `rarities-source`, `rarity-source-entry`, `rarity-source-row`, `source-mob-tiers`, `source-mob-tier`, `source-relative-colors`, `source-text-map` | `test_whole_rarities_source` |
| `stats.json`, both catalogs, both formula blocks, power table and gap metadata | `stats-source`, `resource-source-entry`, `resource-source-row`, `stat-source-entry`, `stat-source-row`, `source-item-formulas`, `source-character-formulas`, `source-power-entry` | `test_whole_stats_source` |

`SourceVersion` preserves explicit A/S/Ω/X tags; it does not resolve unmapped
histories, infer availability or promote qualified source annotations. Source
formula strings remain text, not executable formula validation. Assassin's
`also-ultimate` remains source identity metadata: the complete-source test keeps
one rank-3 Camouflage and its third-slot control, not a second ultimate. Raw
forest race/family tokens remain literal, including `beetle`; no alias is invented.
Skeleton Dog's unchanged source family/taming/roster facts remain distinct from
later approved hybrid behavior. Unrecorded numeric IDs and null taming facts
remain nullable; optional Boolean flags and typed optional collections do not
receive null-as-a-value merely because the native generator defaults permit it.

### Logical anchors and structural facets

The following is a source-to-declaration map, not a parallel property/type table.
`test_source_qualified_appearance_and_entity_state`,
`test_character_world_travel_slot_placement` and
`test_identity_combat_logical_facets` are in `test_ontology_schema_authoring.py`.

| Canonical anchor/group | Explicit declaration | Contract evidence |
|---|---|---|
| §3.2 `entity`: motion/orientation, humanoid classification, resource state, scaling, combo/timers, flags/equipment/statuses | `entities.yaml:entity` and its named `entity-*` slots; `associations.yaml:status-application` | `test_source_qualified_appearance_and_entity_state`; existing exact-count and species-reference tests |
| §3.2 `appearance`: color, source model/scale/offset/orientation groups, flags and qualified expressions | `entities.yaml:appearance`, named `appearance-*` slots and `AppearanceFlag`/`AppearanceExpression` | `test_source_qualified_appearance_and_entity_state` |
| §3.2 `race`, `character-class`, `specialization` intrinsic fields | `identity.yaml` classes and attributes, existing customization slots | `test_identity_combat_logical_facets`; full-source tests above and retained class/spec projections |
| §3.2 `player-character` and §3.5 skill investment/bank | `entities.yaml:player-character`, its `entity-species`/`entity-specialization` slot refinements, `player-character-skills`, `player-character-banked-skill-points`, `player-character-active-pet`, `player-character-pet-slot`; existing `knows-recipe` and `realm-knowledge` | `test_inherited_entity_aliases_and_roots`; inherited cardinality/save/knowledge checks; induced-slot coverage and logical-facet tests |
| §3.2 personal world position/travel and §3.7 scope | `player-character-world-states`, `associations.yaml:character-world-state`, its compound key and named discovery slots | `test_character_world_travel_slot_placement` |
| §3.2 `npc-role` versus species/individual; `creature`, `creature-family`, `faction` | `identity.yaml` classes; source-qualified role/faction slots in existing catalog modules; `entities.yaml:race-or-creature` | inherited selected-field/reference tests, full source tests and logical-facet test |
| §3.2 `pet`: identity/progression/hydration/boss origin | `entities.yaml:pet`, `pet-*`; global `owns`, `mounts`, `scales-with` retain their scoped relation meanings | `test_identity_combat_logical_facets`; inheritance checks in entity/appearance test |
| §3.2 `mob-strength-tier`, §3.3 `resource`/`stat` | `combat.yaml` classes and attributes, source comparison/formula classes above | logical-facet test and whole stats/rarities tests |
| §3.3 `ability`/`weapon-type`/`status-effect` intrinsic definitions | `combat.yaml` classes; cost payloads in `associations.yaml`; source qualifications remain distinct | logical-facet, payload/compound, tree and whole-source tests |
| §4 all fact types, including cross-family endpoints | Existing `relations.yaml`, `relation-types.yaml`, owning identity/combat/entity slots; association-class annotations remain | `test_imports_ranges_aliases_and_compound_keys`, `test_payloads_and_compound_metadata`, `test_identity_combat_logical_facets` |
| §4 threat pair/current target and resource costs | `threat-pair`, `threat-mob`, `threat-player`, `aggro-points`, `current-target`, `resource-cost` | existing numeric/compound tests; logical entity state test |
| §5 class/spec indices, cardinalities, unions, source/key/enum/type boundaries | Existing `specialization.class-index`, inverse `has-specialization`/`specialization-class`, `entity-species`, source entry/root classes | inherited negative controls; `test_actual_species_yaml_mutation_uses_same_oracle`, `test_boolean_branch_ranges_and_dynamic_values` |

**Category 1 — native structural enforcement:** the source/root guards, selected
closed fields, dynamic value types, local bound entry key patterns, numeric
width/bounds, list sizes, enums, optional-nonnull Boolean expressions and explicit
source-null cases above. `assert_ranges` now checks every branch of `any_of`,
`exactly_one_of`, `all_of`, `none_of` and dynamic-value expressions. Actual YAML
mutation of `entity-species.range` to `string` is rejected by the **same inherited
declaration oracle**, even though an unknown ID string still passes native shape.

**Category 2 — declaration without complete backend enforcement:** FK existence,
reference namespace membership, inverse agreement, compound uniqueness, set
integrity, key/body identity agreement, ordered specialization ownership and
required catalog membership/census. Preserve target classes, inverse and
compound/set/cardinality facets; native shape admission is not their proof.
`character-world-state` makes world ownership explicit; it is not a replacement
save format. Historical thirteen-position equipment and the twelve usable-slot
`equips` relation remain distinct, not a new empty-slot wire encoding.

**Category 3 — nonstructural behavior:** §3.2 AI targeting/perception/pack response,
provocation, pursuit/return, pet revival/taming/traversal; §3.3 combo, charging,
blocking/exhaustion, dodge/stealth, mitigation, DOT scheduling and death; §3.5
level-up, spending, respec and traversal gates. These depend on events, elapsed
simulation, world/player state and lifecycle, not just a catalog object's shape.
The structural state/payload portions are mapped above; the behavioral rules
stay at their canonical anchors. Formula expressions are retained with source
qualifications: backend numeric typing does not execute formula text, prove
historical correctness or replace current-rule checks. This classification does
not erase the declared structural portions or certify unimplemented runtime rules.

### Qualified appearance and raw combo-clock representation

Structural source detail is pinned to third-party cuwo revision
`240bb61ec42abb10a73d750ce72f243e04e55509`,
[`entity.pyx` lines106–241](https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/cuwo/entity.pyx#L106-L241).
The declaration follows the actual asymmetric field lists. Name lookup is not
model-field storage; a numeric codec field is not a fabricated stable global ID.
No uniform per-part transform, missing hair-scale/weapon-model/shoulder-offset,
legal-ID census or universal negative sentinel is inferred. Source initialization
values are not ontology defaults. Broad appearance meaning and Omega expression
prose remain distinct from this Alpha-oriented codec evidence.

`entity-last-hit-time` records only the qualified cuwo raw storage shape. The
structurally corresponding Berld field at revision
`f5d3886ce06cde28cc66932f23eea85a05149bc7` has a different signed interpretation and
an explicit elapsed-millisecond interpretation in its anti-cheat code. Neither
third-party implementation authenticates original-client or cross-edition clock
semantics. Units, epoch, reset/wrap/freeze behavior and hybrid clock meaning remain
unresolved; no unit, arithmetic, default or universal elapsed/timestamp rule is
authored. This is an evidenced representation with a semantic ceiling, not a new
hybrid timing choice or a fabricated numeric/string union.

### Family lint and generator readiness delta

Family modules now declare their import dependencies and recommended metadata.
The qualified nine-module Task2 matrix covers `identity`, `entities`, `combat`,
`relations`, `relation-types`, `associations`, `catalog-properties`,
`catalog-identity-combat` and `pixlnd`. The directory still aborts in unchanged
`items`, assigned to Task4; modules after that abort are **not observed by that
directory run**. The Task1 matrix and ownership table above retain remaining
Tasks3–7 diagnostics and crashed-module unobserved checks. No unrelated module
or substantive lint rule is waived, and a clean final directory gate is still
mandatory. Exact run/policy/source pins remain in managed task evidence.

The naming policy adds only parent-approved exact source-literal PV exceptions,
including `during-taming`. Native exclusion matching is global by exact name,
not enum-scoped; positive/negative fixtures retain malformed class/slot/enum/PV
and undeclared-range controls, including near-miss `during-tamin`. Values are not
renamed to satisfy lint, and this is no wildcard or substantive-rule suppression.

`test_inherited_entity_aliases_and_roots` proves one induced classification fact
per concept, not merely unique aliases: player `slot_usage` refines inherited
`entity-species` and `entity-specialization` into its existing `race`/`spec`
representation. The guarded closed native player root rejects redundant
`species`/`specialization` properties. Base entity and pet classification contracts,
player requiredness and other subclass facets remain checked. Pre-existing global
named slot declarations remain available, but their redundant player attachments
are absent. Unknown reference-string membership remains a separate native limit.

Readiness extends to `entity` inheritance by player/pet, source-cost inheritance,
induced attributes, explicit aliases, reversible local entries and Boolean range
branches. Species definitions do not become entity subclasses. Source and logical
representations remain separately named. This is contract coverage for future
SchemaView consumers, not certification or implementation of a code generator,
consumer migration, runtime parity or ongoing drift gate.

## World, geography, structures and encounters — Task3 scope

This section maps exact source contracts and the known logical subset; it does
**not** claim Task3 completion. Numeric realm years, including optional capital
destruction year, are declared. Qualified static/marker and logical polygon contracts
are mapped below with explicit encoding, opaque-meaning and native-enforcement
ceilings. Raw source admission does not settle those wire/enforcement questions.
All nine production JSON files stay
unchanged, including the uncertain overhang description, symbolic quantities,
qualified history, desert-ruins note and sandstone ingredient target.

### Complete source inputs and guards

Each root below has an independent literal field/required/closedness oracle in
`FullWorldSources` or `FullStructuredWorldSources`. Validation then checks the
whole original document through `ontology_source_contracts.validate_source`;
there are no filtered projections or fabricated body IDs. These are **bound
contracts**, not direct raw-wire JSON Schema admission. Exact native limitations
are independently probed by `test_native_numeric_tables_require_binding` and
`test_native_positional_pair_binding` in the contracts test file.

| Entire source input | Explicit declarations in `structured-world.yaml` | Full-source test |
|---|---|---|
| `landscapes.json`, including `_shared`, descriptive climate/style/rosters, generation palettes and notes | `landscapes-source`, `landscape-source-row`, `landscape-source-climate`, `landscape-source-shared`; existing `world.yaml:landscape-generation` | `test_whole_landscapes_source` |
| `terrain-features.json`, including named Boolean/text alternatives and uncertain descriptions | `terrain-features-source`, `terrain-feature-source-row` | `test_whole_terrain_features_source` |
| `flora.json`, including empty/omitted yields, scalar/range/symbolic yields and qualified raw rosters | `flora-source`, `flora-source-row`, `flora-yields-source`, `flora-yield-source-entry` | `test_whole_flora_source` |
| `deposits.json`, including metadata, notes and unresolved sandstone | `deposits-source`, `deposit-source-row`; unchanged logical `world-catalog.yaml:deposit-yields` | `test_whole_deposits_source_and_missing_sandstone_target` |
| `dungeon-types.json`, including `_dungeon-rules`, both contents forms, variants and all raw alpha-location forms | `dungeon-types-source`, `dungeon-source-row`, `dungeon-source-rules`, `dungeon-source-contents`, `dungeon-variants-source`, `source-integer-pair`, `source-alpha-location-pair`, `source-alpha-location-pair-pair` | `test_whole_dungeon_types_source` |
| `poi-types.json`, including numeric alpha-location/quarter pairs and zero source indices | `poi-types-source`, `poi-source-row`; unchanged logical `world-catalog.yaml:poi-type-alpha-loc` / `poi-type-quarter` | `test_whole_poi_types_source` |
| `static-entities.json`, including repeated table names, missing index70, literal behaviour groups, additions and candles | `static-entities-source`, `static-names-source`, `static-name-source-entry`, `static-behaviour-source`, `static-behaviour-source-entry`, `static-candles-source` | `test_whole_static_entities_source` |
| `block-types.json`, including numeric Alpha object rows plus flags, numeric Steam strings plus note, scale and cub-format | `block-types-source`, `alpha-block-table-source`, `alpha-block-source-row`, `steam-block-table-source`, `block-source-flags`, `block-scale-source`, `block-cub-format-source` | `test_whole_block_types_source` |
| `buildings.json`, including trainer-object/string district entries, styles, population and version visibility/count descriptions | `buildings-source`, `districts-source`, `district-source-row`, `building-rows-source`, `building-source-row`, `settlement-styles-source`, `settlement-style-source-row`, `settlement-population-source`; existing `source-version-text` and `world.yaml:district-building` | `test_whole_buildings_source` |

Every keyed container has an explicit YAML entry range, not one slot per catalog
ID. Existing `source-entry-key` applies only to stable catalog keys. Dedicated
numeric-entry keys retain numeric strings; behaviour group keys retain literal
pipes and source names. Version strings retain explicit uncertain forms, not
fabricated confirmed provenance. Scalar/object/null/omission distinctions and
closed rows are enforced by native types, requiredness and nonnull optional
`exactly_one_of` expressions. Existing optional logical projection contracts stay
broader where their inherited tests characterize that boundary.

The shared helper follows only explicit inline class ranges to reach nested
annotated containers. It applies the already-declared `source-map-entries` and
`source-map-paths` transforms, preserving fixed sections and collision guards.
It never chooses arbitrary union branches or follows logical reference targets.
For the specifically qualified dungeon field, `source-tuple-positions` gives
positional order; only that annotated subtree becomes positional objects. Native
disjoint pair classes enforce flat/nested types. Raw objects are not accepted as
already-bound tuples. Binding and inverse preserve exact flat versus nested lists;
malformed count, wrong positions, null/Boolean/mixed members and extra/missing
bound positions are rejected. Production positional classes and nested Alpha/
Steam roots have additional literal root guards. Native output is never rewritten.

### Logical anchor map and remaining precision

| Domain anchor | Explicit elements | Test/evidence |
|---|---|---|
| §3.1 world / land | `world.yaml:world`, `world-seed`, `world-name`, `world-day`, `world-time-ms`, `world-spawn-rule`, `world-origin-poi`, `discovered-zones`; `land` / `land-name`, `land-landscape`, `land-level`, `land-danger-tier`, `land-tier-range`, `land-rarity`, `land-realm`, `land-border`, `land-key-items`, `land-gnome-suppliers`, `land-books-of-crafting`, `wizard-towers`, `land-circles-of-power`, `land-artifacts`, `land-settlements`, `land-coords`; `land-border` ranges over empty-structure logical `polygon`, with no concrete representation | `test_world_land_bounds_and_context_facets`, `test_land_border_logical_declaration`, `test_land_border_yaml_mutations_are_detected`; preserved source scopes and meanings remain in `3_Classes.md#world` / `#land` |
| Source map markers | Pinned captures under `/home/theta/.pi-game-dev/sessions/--home-theta-repos-pixlnd--/subagent-artifacts/outputs/f1ded118-7c48-4d6f-808e-308204fa1e01/task-3/qualified-world-execution-20261114-1/`: Alpha `t05-infinite-alpha-worldmap-h.txt` / `t06-infinite-alpha-worldmap-cpp.txt`, `ZoneTile::m_markers` list of integer triples → `structured-world.yaml:zone-tile-marker-collection.markers` and `map-marker-integer-triple`; later release `t14-release-worldmap-h.txt` / `t15-release-worldmap-cpp.txt`, `WorldMapRegion::positionsByPlace` pair-keyed collection of marker lists → `place-keyed-marker-collection.places`, `place-marker-list-entry.place/positions`, `map-marker-place-key`, and `map-marker-integer-triple` | `test_marker_collection_metadata`; `test_marker_collection_native_boundaries_and_yaml_mutations`. The composite pair key is retained as a typed logical association; uniqueness and source serialization are not natively asserted. These are separate source scopes, not polygon vertices/connectivity, client-authenticity claims, or universal wire/save contracts. |
| §3.1 zone / block | `world.yaml:zone`, `zone-size-blocks`, `zone-static-entities`, `columns`, `spawns`, `chunk-items`; `field`, `base-z`, `blocks`; `creature-spawn` and reused entity facets; `block`, `block-type`, `block-rgb`, `block-breakable`; source catalogs/config `world-catalog.yaml:block-type` and `structured-world.yaml:block-type-catalog` | `test_precise_field_spawn_clock_and_orientation`; inherited RGB/cardinality contracts; source block configuration in `BlockConfigurationTests` |
| §3.1 landscape / terrain / flora / deposit / dungeon / POI / district / building | `world.yaml:landscape`, `landscape-generation`, `settlement`, `district`, `district-building`, `building`; `world-catalog.yaml:terrain-feature`, `flora`, `deposit`, `deposit-yields`, `dungeon-type`, `poi-type`, `poi-type-alpha-loc`, `poi-type-quarter`; `structured-world.yaml:landscape-source-row`, `landscape-source-climate`, `terrain-feature-source-row`, `flora-source-row`, `deposit-source-row`, `dungeon-source-row`, `dungeon-variant-entry`, `poi-source-row`, `buildings-source`, `district-source-row`, `building-source-row` | Retained focused `world-catalog`/`structured-world` methods; `test_whole_landscapes_source`, `test_whole_terrain_features_source`, `test_whole_flora_source`, `test_whole_deposits_source_and_missing_sandstone_target`, `test_whole_dungeon_types_source`, `test_whole_poi_types_source`, `test_whole_buildings_source`; logical fauna contract and settlement-style class slots: `test_landscape_fauna_logical_roster_contract` and `test_settlement_style_class_slot_contract` in `test_ontology_schema_world_basic_p2.py` |
| §3.1 settlement | `world.yaml:settlement`, `settlement-style`, `count-per-land`, population race/animal slots; `catalog-properties.yaml:settlement-style`, named `settlement-style-*` slots | `test_world_land_bounds_and_context_facets`, `test_whole_buildings_source`; source structure stays separate |
| §3.1 climate | Existing `world.yaml:climate` scalar readings, distinct from raw descriptive climate bands | `test_basic_world_p2_roots_and_values`, `test_basic_world_p2_root_mutations`; raw source climate controls remain separate |
| §3.1 static-entity | `world.yaml:static-entity.orientation`, optional `closed` and `occupant` describe distinct logical states; `structured-world.yaml:static-entities-source` and named catalog parts cover complete source-name/behavior/config shape. Qualified source components below remain distinct | `test_precise_field_spawn_clock_and_orientation`, `test_whole_static_entities_source`; qualified components use `test_qualified_static_components` and static composition test |
| §3.1 realm | `associations.yaml:realm-leader-birth-year`, `realm-leader-hometown`, `realm-leader-tomb-location`, `realm-capital-founding-year`, `realm-capital-destruction-date`; existing names/trait and `realm-knowledge` personal lore scope remain distinct | `test_typed_realm_components` (including native optional-null characterization, not historical wire admission); retained personal lore test |
| §3.1 game-clock | `world.yaml:game-clock` (`speed`, `initial-time-ms`, qualified `reference-sleep-speed`) and `hybrid-inn-sleep-service-parameters` | `test_precise_field_spawn_clock_and_orientation`, `test_hybrid_inn_sleep_{contracts,values,mutations}`; reset/inn/agreement/offline behavior stays in canonical prose |
| §4 world-owned relations | `relations.yaml`: `yields`, `spawns-in`, `placed-in`, `hosts`, `rewards`, `guards`, `drops`, `requires-key-item`, `located-in`, `owned-by-realm`, `reveals`, `bound-to-land`, `works-in-adjacent`, `raises-stock`, `sells`, `offers-service`, `contains-station`, `in-district`, `styled-by`, `has-hazard`, `possesses`, `petrifies`, `adjacent-to`; unions in `relation-types.yaml` | `test_basic_world_p2_relation_contracts`, `test_basic_world_p2_relation_mutations`; typed endpoints are not FK-existence or applicability enforcement |
| Encounter geometry and occupancy | `world.yaml:encounter-volume`, `ruins-room-volume`, `ruins-corridor-volume`, `ruins-court-volume`, `ruins-passage-volume`, `ruins-alcove-volume`, `camp-battlefield-volume`, `rescue-battlefield-volume` | `test_encounter_geometry_and_population`; closed-union/all-player-outside occupancy remains procedural, not enclosing-box equivalence |
| Encounter populations / local difficulty | `world.yaml:encounter-population`, `ruins-population`, `camp-population`, `rescue-population`; equivalent entity level/power facets on `creature-spawn` | `test_encounter_geometry_and_population`; local stat curves/size/renewal procedures remain linked prose, not a new engine |
| Encounter permanent roles / special / spirit | `world.yaml:encounter-assignment`, including `exactly_one_of` Boolean/presence expressions; fixed spirit parameters in `initial-spirit-profile` | `test_encounter_assignments_and_shared_reward_contract`; `test_spirit_scope_fixed_profile`; category2: precise assignment declaration, not native applicability enforcement. LinkML 1.12.1 omits `equals_expression`, admitting true+omitted special and false+stomp/charge; nonnull/value/Boolean constraints remain enforced. Spirit probability execution, level conversion and lifecycle remain linked behavior, not a missing profile declaration |
| Encounter fixed boss-special parameters (`domain/encounter-contracts.md#boss-specials-and-breakable-rubble`) | `world.yaml:boss-special-profile`, `boss-stomp-profile`, `boss-charge-profile`; charge links `#local-difficulty-and-boss-size` for height | `test_boss_special_profiles`: independent closed concrete roots, required scalar constants, raw/induced native refinements, unique inherited facts/aliases, source/URI metadata and malformed controls. Category1 fixed-parameter admission only, not target-distance/height predicates, assignment selection or combat execution; no activation/save/configuration payload |
| Encounter fixed rubble parameters (`domain/encounter-contracts.md#boss-specials-and-breakable-rubble`) | `world.yaml:rubble-profile`, reusing `block-breakable` via local `slot_usage` | `test_rubble_trap_profiles`: identity-free closed root, per-arena integer count, cube edge, logical `stone` material token and world-clock-hour delay; raw/induced metadata and malformed controls. Category1 fixed numeric/string facets and required Boolean typing; category2 intrinsic `equals_expression: "True"` is declared but omitted by LinkML 1.12.1 native JSON Schema, which admits `breakable: false`. No global block restriction, Boolean coercion or custom checker. |
| Encounter fixed trap parameters (`domain/encounter-contracts.md#spike-traps-and-furnishing-contents`, `#geometry-and-occupancy`) | `world.yaml:spike-trap-profile`, plus `furnishing-profile`, `vase-profile`, `table-profile` | `test_rubble_trap_profiles`: independent closed root, per-ruins integer count, closed footprint and inclusive feet-height thresholds, simulation-second phase durations and fixed physical hit amount. Category1 fixed-parameter admission only, not targeting, timing execution or defence enforcement; no activation/save/config payload. |
| Encounter shared mission package | `world.yaml:encounter-shared-package`, including `life-potion-rarity-index` and `gear-upgrades`, and four standard LinkML class rules | `test_encounter_assignments_and_shared_reward_contract`; fixed facets and coupled tier quantities/gem identity are natively enforced; source-level is not mislabeled item power; sharing/additivity and pending class selection remain linked rules |
| Encounter placement/access, specials/rubble, traps/furnishings, boss guarantees, safe delivery/renewal, permanent-source exclusion | Retained exact `encounter-contracts.md` anchors; corresponding authored `world.yaml` profiles/assemblies and current `save-geography` / `save-content` components stay preserved | Named logical declarations and the mapped focused tests cover only their specified structure/constants; physical placement, formula execution, probability selection, lifecycle and runtime enforcement remain open. Do not infer blanket facet completion |

`test_ontology_schema_world_basic_p2.py`: `BasicWorldP2Tests` additionally guards complete logical zone/settlement/realm roots and
checks raw/induced facets with the same root/value and actual-YAML mutation oracles.
Its `test_basic_world_p2_relation_contracts` and `test_basic_world_p2_relation_mutations`
pin the world-related §4 declarations and union endpoints in `relations.yaml` /
`relation-types.yaml`. These global facts are not extra attached record fields:
endpoint/cardinality declarations do not prove foreign-key existence, compound
integrity, historical applicability or runtime behavior. The qualified static, marker,
logical polygon and other world representations are declared. Polygon topology and
portable wire encoding/serialization remain unselected; runtime rules remain in their
owning prose, while execution/enforcement is not established by these declarations.
The current Task3 native gate is complete, while whole-task acceptance, family/integration
and later-task gates remain open.

Known behavioral rules are not invented storage objects: zone retirement,
midnight flora return, blue glow, settlement layout generation, inn voting/skip,
reset coalescing, targeting/contact/refresh/delivery and permanent-source placement
remain their precise prose. Connecting guidance never reshapes terrain or gates
site validity on walkability; independent site platforms/aprons/ocean hubs and
internal passage dimensions retain their separate contract. Nothing here adds
an encounter engine or changes ambient fauna, sources, saves or generation.

Previously identified structural questions have qualified declarations; do not
mistake them for selected serialization or backend enforcement. Documented native
backend ceilings remain real limitations, not unmodeled shapes or selected omissions.
Do not use an opaque string/union/default to imply guarantees beyond the declarations. The owner approved numeric realm
years and identified settlement/POI references without a calendar/epoch/coordinate
model, full POI record, current generated availability or FK-enforcement promise.
Sandstone's scalar source value passes while its sole missing ingredient target
remains an independent data reconciliation issue; no production ingredient was
synthesized.

### Enforcement and generator readiness additions

- **Native enforced:** exact bound source roots/rows; numeric/pair/RGB/count
  boundaries; explicit tuple positional types after reversible binding; source
  required objects; geometry/population constants; package tier-coupled standard
  `rules` (positive per tier and deliberate cross-field negatives).
- **Fixed boss-special profiles:** `test_boss_special_profiles` checks native
  constant bounds and exact concrete-root structure; shared concepts are inherited
  once and refined via `slot_usage`, without duplicate aliases or defaults.
  Parameter units and inclusive/exclusive meanings stay source-linked. Cooldown
  contains recovery rather than adding another interval. Boss-height reuse and
  targeting, sight/shielding, defence/status order, interruption, cancellation,
  attack gating, pause/unload and other behavior remain linked rules, not stored
  flags or native execution claims. The existing category2 assignment limitation
  is unchanged. Rubble, trap and furnishing parameter profiles are authored and
  mapped below; placement, shattering, lifecycle, targeting and defence procedures
  remain linked behavior, not native execution claims. These source-linked procedures
  do not imply an unmodeled structural shape or a blanket nonconvertible classification.
- **Fixed rubble/trap profiles:** `test_rubble_trap_profiles` independently checks
  both declared roots, every required field, fixed-value/type violations, aliases,
  URIs and source anchors, raw/induced facets and closure against identity/policy/
  saved-state fields. Rubble material is the current rule's literal logical token,
  not an ingredient/material catalog FK or a universal alpha/Steam numeric block
  code. Intrinsic breakability reuses the existing Boolean slot with a local
  `equals_expression: "True"` refinement (category2); the known native omission
  admits false but still rejects numeric/string/null/container non-Booleans.
  Category1 numeric/string admission does not execute placement, shattering,
  charge continuation, no-drops/protected-structure rules, restoration deferral,
  trap targeting/once-per-activation/retrigger/warning/jump/defence or renewal
  behavior. These rules remain source-linked; saved broken/restore-at and trap
  phase/remainder/hit-set state is unchanged. Fixed furnishing, ordinary-loot,
  geography and local-difficulty structures are authored and mapped in the relevant
  sections below. Their references, physical placement, generated outcomes and
  runtime/lifecycle behavior are not established by those declarations. These source,
  procedural and enforcement limits do not assert an unmodeled world shape or classify
  retained facets as nonconvertible. Whole-task acceptance, wider semantic review,
  directory lint and Phase1 integration remain open.
- **Fixed furnishing profiles:** `test_furnishing_profiles` covers
  `furnishing-profile`, `vase-profile` and `table-profile` in `world.yaml`.
  Current encounter source143–148 maps room-scoped count, initial/full health
  (not saved current prop HP) and armor to the base attributes plus child
  `slot_usage`; vase copper maps to its two integer coefficients, not a payout
  field, expression interpreter or independent RNG. Source148–154 maps the
  minimum room guard-pack level to shared fixed context, not another saved level
  or list. Vase income uses stored ROOM level, not boss level or item power;
  actual safe renewal can change that level and hence the amount under the same
  equation. Source146–152 maps the table's per-renewal pair quantities, common
  rarity index (unchanged `rarities.json#common`) and zero potion power-point
  spread; the potion converts saved ROOM level under `3_Classes.md#item`, with
  no invented flask power. Literal root/property/required/closure, raw/induced
  alias/range/URI/source/constant/description and no-identity/default oracles
  check native admission, including inherited concept uniqueness and malformed
  values. They do not compute coins, execute item-power conversion or establish
  arbitrary formulas/relations. Source144–158 direct-only damage, exclusions,
  pair issuance before break/no reissue, level selection/survivors/mixed levels,
  persistence, safe coalesced renewal/no refill and no formulas/books/artifacts
  remain linked rules, not policy flags or parallel contents/configuration/state.
  Ordinary-loot profiles, site geography/assemblies and local-difficulty profiles
  have authored structures and mapped tests in the owning sections. They do not
  establish every relation/reference, procedural formula, generated outcome or
  runtime effect. Whole-task semantic acceptance and Phase1 integration remain
  incomplete; linked rule deferral is not blanket category3 classification.
- **Declared but not natively established:** reference existence, source-key/body
  identity agreement, physical/world membership, and deterministic world generation.
  `BasicWorldP2Tests.test_world_root_generation_is_repeatable` compares three
  selected emitted root schemas across two temporary copies; it establishes schema-
  generation repeatability only, not deterministic world generation or runtime.
  Numeric key patterns are enforced on bound entry fields, not presumed on
  native SimpleDict property names. No full FK/compound/set/lifecycle claim.
- **Prose-owned behavior/context:** the distinct retained rules cited above.
  Unresolved structure is not classified as behavior to avoid completion work.
- **Inheritance/induction:** strict source wrappers reuse `block-scale`,
  `block-cub-format` and `static-candles` with local requiredness refinements;
  encounter components reuse explicit volume/population facets. This adds no
  target-language hints or parallel schema backend.
- **Lint:** owned world/structured modules now load under recommended native
  rules. The sole new exact naming exception is literal `near-village`; like
  native exact excludes, it also matches other element kinds with that exact
  name. Isolated positive/substantive/near-miss controls qualify that finite
  spillover. It is not a wildcard or widened warning allowance. The directory
  still fails at the inherited Task4 items frontier; later checks remain
  unobserved until their assigned family work, not a clean Phase1 lint gate.

## Fixed ordinary site-kill loot and guaranteed boss-gear parameters

`domain/encounter-contracts.md#ordinary-kill-loot` and
`#guaranteed-boss-gear-and-spirits`, with `domain/3_Classes.md#item` /
`#loot-rule`, map to `world.yaml:ordinary-site-kill-loot-profile` and
`guaranteed-boss-gear-profile`. Existing `instances/generators.json#design.loot`,
`rarities.json#legendary` and character-class identities remain unchanged inputs.
`test_ontology_schema_world_rewards.py`: `LogicalWorldTests.test_gear_loot_profiles` guards both real identity-free roots,
independent literal property/required sets, closedness, raw/induced metadata and
native fixed numeric facets without stripping descriptions. It checks complete
positives, every missing/changed constant, malformed numbers and roots, and unknown
policy/payload/current/initial-state fields. The new method leaves all114 old
method ASTs unchanged.

The fixed parameters are category1 admission coverage, not execution of independent
Bernoulli rolls, equal-offset or relative-weight selection, conversion-before-spread,
clamping, coin formulae, current-versus-initial source selection or tier-plus-increment
rarity coupling. Those precise formula/relational facets and actual pool/reference
integrity remain outside this bounded declaration/test batch, not blanket category3.
Shared pickup/additivity, XP, anti-reroll and lifecycle remain linked procedures,
not configurable flags or new reward receipts. The two roots do not admit a whole
`design.loot` input, generate rewards, qualify saves or complete encounter authoring.
Fixed spirit acquisition, supplier-ceiling/completion and initial permanent-source profiles are now declared and mapped to `test_spirit_scope_fixed_profile` and `test_progress_exclusion_profiles`. Their applicability, probability execution, level conversion, ceiling arithmetic, restock/claim/lifecycle rules and the ordinary reward execution are not proved by those structural tests. Whole-task acceptance, Task4, directory-lint baseline and integration remain open; no additional world-shape blocker follows from this coverage.

## Initial-site spirit assignment scope and fixed acquisition parameters

`encounter-contracts.md#guaranteed-boss-gear-and-spirits`162–181 and
`#boss-specials-and-breakable-rubble`98–99 map to `world.yaml`'s
`initial-nonboss-assignment`, `initial-ruins-boss-assignment` and
`initial-mission-boss-assignment`. These logical subclasses reuse exactly the
five existing `encounter-assignment` facts/aliases/URIs; class scope is not a new
mission Boolean, site/context field or selected save serialization. Local
`slot_usage` retains precise `boss.equals_expression` False/True/True.
Required special/spirit refinements and standard class `none_of` PRESENT guards
express actual omission-only absence: nonboss has neither, ruins boss requires
both, mission boss requires special and forbids spirit. Neither optionality nor
null stands for absence. This scope covers guards, the two non-mission ruins
bosses and the camp/four rescue mission bosses, not all future encounters.

`test_ontology_schema_world_progress.py`: `LogicalWorldTests.test_spirit_scope_assignments` pins authored/induced class
scope, five inherited facts without duplicate attachments/aliases, source/URI
metadata, literal root/property/required/closure, all three positive scopes,
missing/present/malformed special/spirit combinations with both Boolean values,
malformed roots and unknown identity/mission/level/payload/receipt/effects flags.
Native qualification covers702 matrix rows:22 native admissions,11 of which
violate the intended boss Boolean predicate. Presence, absence, requiredness,
scalar types and the four type tokens are category1; `equals_expression` remains
category2: native LinkML1.12.1 omits it, admitting true nonboss or false boss
rows with otherwise matching shape. The authored/induced predicate is preserved,
not replaced by arithmetic/string coercion or a custom checker. Generic root
Boolean/presence expressions and all prior native limits remain unchanged.

The sole approved nominal correction changes the generic spirit TYPE reference
from `ingredient` to `material`, plus exactly the corresponding range literal in
`test_encounter_assignments_and_shared_reward_contract`. Existing stable keys
are `materials.json#spirit-fire`, `#spirit-unholy`, `#spirit-ice`, `#spirit-wind`
(lines27–30, A-qualified, kind spirit), not missing ingredient rows or generated
cube-instance identities. `recipes.json:39` links spirit cubes to those material
identities; `3_Classes.md#spirit-cube`1242–1258 retains acquisition/customization
qualifications. No material/ingredient hierarchy, ingredient catalog, global
range or physical cube-instance class changes. The focused actual-YAML nominal
mutation proves complete native generic schema equality before/after this
reference correction; aliases/URI/five-field shape and four-token order survive.
All114 other inherited test methods and original95 ASTs are preserved; the
one prior-method exception is exactly this one range literal, not weakened tests.

`world.yaml:initial-spirit-profile` is one identity-free fixed-parameter profile,
not a configuration, event, payload, level record or replacement type catalog.
`test_ontology_schema_world_progress.py`: `LogicalWorldTests.test_spirit_scope_fixed_profile` checks all eight required
facets, native scalar constants/bounds, raw/induced metadata, literal closed root,
missing/changed/malformed values and roots, and exclusion of policy/effect/state
fields. Existing `generators.json#design.initial-encounters.spirits`132–135 and
qualified material keys anchor the first-logical-generation type probabilities.
Existing `save-world.yaml:saved-spirit-level`79–87 explicitly identifies INITIAL
boss source level; `saved-spirit-level-level`314–321 supplies its minimum1,
not a bound inferred from current guaranteed gear or item power. Its saved
shape remains unchanged: no repeated initial/current-level state is introduced.
Canonical `3_Classes.md#item` and the encounter rule preserve power(INITIAL L),
no spread, permanent type and initial-level-derived power across daily renewal,
versus guaranteed gear's CURRENT defeated saved level. Each genuine ruins-boss
death gives one shared cube; mission bosses give zero, not per-player copies or
replacement ordinary rolls. Collection/carrying only adds no attachment/effect
numbers, regional weakening or global spirit exclusion.

Fixed-parameter/native-shape admission does not execute selection, power
conversion, level-to-power relations, independence, permanence, renewal,
anti-reroll, shared drops, reward additivity or lifecycle. These precise linked
rules remain distinct from native enforcement, not blanket category3. The fixed spirit, supplier-ceiling/completion and permanent-source structures now have declarations and focused tests; this does not prove eligibility execution, probability draws, level conversion, ceiling arithmetic, restocking, claims or lifecycle. Geography and local-difficulty declarations are separately mapped; physical placement, formula/procedure execution and remaining relational facets are not established. Whole-task acceptance, Task4, directory lint, integration and runtime acceptance remain open.

## Shared supplier ceiling, mission completion and initial-source parameters

Current `encounter-contracts.md#shared-mission-packages-and-supplier-shops`184–210
maps to `world.yaml:supplier-gear-stock-ceiling-profile` and
`shared-mission-completion-profile`; `3_Classes.md#shop`1376–1388 and
`#gnome-supplier-s`1532–1545 retain the supplier qualifications.
`rarities.json#common` / `#legendary` anchor the existing rarity indices.
`encounter-contracts.md#initial-permanent-source-scope`212–222 maps to
`world.yaml:initial-permanent-source-profile`, with `3_Classes.md#artifact` /
`#book-of-crafting` retaining personal source claims and full-land allocation.
These three identity-free fixed logical profiles add no mutable progress/state,
stock configuration, policy flag, reward event, receipt, default, duplicate package
or replacement catalog. `test_ontology_schema_world_progress.py`: `LogicalWorldTests.test_progress_exclusion_profiles`
checks independent literal roots/properties/requiredness/closure; authored/induced
ranges, constants, aliases, URIs, source anchors and unstripped descriptions;
complete positives, every missing/changed/malformed field, malformed roots and
complete-positive-plus-unknown identity/state/policy/global-exclusion controls.
All117 prior methods, including the accepted nominal material-type correction,
and existing world/test bytes remain unchanged by additions-only authoring.

Supplier parameters are land-local and shared by all players in that saved world.
The ceiling reaches legendary after four completed rescues, applies at the next
normal generation/restock without an extra rescue reroll, and does not guarantee
every offer's quality. Quantities, prices and equipment strength during travel
remain unchanged. Shared completion parameters retain the existing single package,
source level, class snapshot/fallback/deferred choice, camp-centre/captive-feet
delivery timing, once-per-cycle issuance, undelivered receipts and ordinary ground
pickup. Zero EXTRA completion XP does not remove kill XP or introduce extra currency.
Initial artifact/one-time-book source zeros cover ONLY the six initial sites,
including alcove, bosses, props and packages: not full-land coverage, a permanent
or global content exclusion, or historical Steam quantity adoption. Personal claims,
artifact allocation and retained content remain; later full-land sources and spirit
customization are deferred, not prerequisites or deletions.

The seven numeric facts are category1 native fixed-parameter admission, not proof
of completed-rescue counting, ceiling arithmetic/capping relationships, eligibility,
restock execution, delivery/issuance timing, class selection, personal claims or
lifecycle. These precise remaining formula/relational/procedural facets are not
blanket category3. Existing generic assignment/Boolean category2 and package
contracts are unchanged. Geography and local-difficulty declarations are authored and mapped; physical placement, formula/relation execution and full partial-candidate review remain incomplete.
Whole-task acceptance, Task4, Task1 directory-lint/integration-budget frontiers and Phase1
integration remain open; the retained Task8 description-routing note is unchanged.
No polygon pass/retrieval, runtime, full-world/family/covering test, dependency,
staging, commit, merge or push qualification follows from this bounded batch.

## Ruins saved room-level conditional — declaration and native boundary

`encounter-contracts.md#spike-traps-and-furnishing-contents`148–158 maps to
`save-world.yaml:saved-site.rules`, using the existing `saved-site-family` and
`saved-site-room-levels` facts. `test_ontology_schema_world_progress.py`: `LogicalWorldTests.test_ruins_room_level_condition`
pins the source-linked raw/get/induced conditional, independent literal full-root
properties/requiredness/closure, aliases/URIs/ranges and unchanged base list facets.
Its actual-YAML removed-rule, wrong-family and wrong-cardinality mutants fail the
SAME declaration oracle even when native admission cannot distinguish them.

This conditional is **category2** on pinned LinkML1.12.1. On the actual saved-site
root the anonymous rule emits canonical property names instead of wire aliases:
its `if` requires `saved-site-family`, absent from the closed aliased root. The
actual canonical `then.properties.saved-site-room-levels` array also omits both
cardinality bounds. Native short ruins arrays therefore still admit; base required
integer/item-minimum/maximum-cardinality checks reject malformed or overlong lists.
Camp/supplier admission is unchanged. Direct-list cardinality support is not proof
of conditional-array enforcement. No emitted-schema rewrite, custom validator or
new logical permission follows from these observations.

No new state, room store, identity, survivor equality or nonruins room entry is
introduced. Mixed-level surviving guards and creation/safe-renewal/restart rules
remain unchanged. Existing camp fixture and all118 prior methods are preserved.
Logical room membership/assembly, designated population/assignment structure and local-difficulty parameters are authored and mapped; physical allocation, live tiers/roles, formula execution and full Task3 review remain incomplete. The
inherited standalone save-world import/metadata lint frontier belongs to Task7;
this narrow rule does not close it, final directory lint or Phase1 integration.

## Initial-site logical assembly and access

`encounter-contracts.md#geometry-and-occupancy`32–43 maps to
`world.yaml:initial-ruins-assembly`, `initial-camp-assembly`,
`initial-rescue-assembly` and the identity-free `initial-battlefield-exit`.
The assemblies attach the unchanged `relations.yaml:located-in` reference and
inherit the existing nominal dungeon/POI identity. The seven existing component
volume declarations remain the ranges of the contained occurrences; outdoor
containment uses the two source-scoped shared slots, attached only to the new
subclasses, with contextual battlefield refinement. Generic dungeon/POI roots
retain their original sole identity field. This is logical inline containment,
not a new current-save, configuration, coordinate or runtime representation.

`test_ontology_schema_world_site_assembly.py`: `LogicalWorldTests.test_initial_site_assembly_contracts` independently pins the
literal complete roots, raw/induced ownership, aliases, URIs, inheritance,
requiredness, references, inlining, cardinalities and fixed scalar facets. Its
actual copied-YAML class/attachment/range/count/requiredness/inlining/alias/URI
mutants use the SAME independent oracle.
`test_ontology_schema_world_site_assembly.py`: `LogicalWorldTests.test_initial_site_assembly_values` independently guards each
complete root before source-shaped nested admission and malformed/missing/null/
reference/container/member/count/dimension witnesses. Ordinary closed roots,
required fields, nested constants and direct-list bounds are **category1** on
pinned LinkML1.12.1. Nonfinite witnesses are labeled in-memory validator values,
not fabricated JSON source values. Repeated equal-value rooms/exits remain valid;
no uniqueness constraint or invented component identity is implied.

Named nominal ranges and their contextual refinement remain precise model facts:
the corridor/passage range mutation changes the emitted reference but identical
component dimensions can preserve native admission. That is not proof of the
correct nominal role. Typed `located-in` does not prove referenced-land existence.
No custom validator, generated-output rewrite or foreign-key/spatial rejection
is claimed. Native structural witnesses do not establish connected corridors,
side/entrance placement, opposite physical exits, visible boundaries, actual door
or lane clearance, or occupancy execution. These are **category3** spatial rules
at the exact linked source anchor, not Boolean policies or invented positions.
The enclosing bounds are not the playable union; ceiling clearance is distinct
from component occupancy extents, including the unchanged outdoor extents.

This closes the preceding checkpoint's logical assembly/access declaration gap
only. Populated ruins-room/assembly, outdoor camp/rescue assemblies, whole-land
associations and local-difficulty structures are authored and mapped below; these
logical declarations do not establish physical placement, generated populations,
probability execution, formulas or runtime lifecycle. These procedure and execution
limits do not assert a remaining qualified shape gap; full Task3 semantic review
remains pending. Existing conditional alias/cardinality category2 limits, the
separate saved-world lint frontier and full directory/integration gates are unchanged.

## Outdoor designated population and permanent assignments

`encounter-contracts.md#populations-tiers-and-clear-conditions`44–66 and
`generators.json#design.initial-encounters` camp/supplier/pack-size map to
`world.yaml:initial-populated-camp-assembly` and
`initial-populated-rescue-assembly`. These refine the unchanged outdoor geometry
assemblies by associating the existing designated population and permanent
pack/singleton mission-boss assignment contracts. “Populated” means complete
DESIGNATED association, not currently alive/spawned/cleared state or a new empty
site gameplay variant. Existing identities, geometry/counts and scoped assignment
contracts remain reusable and unchanged. One occurrence represents one rescue
site at a permitted tier, not exactly four distinct suppliers or land allocation.

`test_ontology_schema_world_outdoor_population.py`: `LogicalWorldTests.test_initial_outdoor_population_contracts` pins raw/get/induced
ownership, inheritance, one identity, aliases, URIs, ranges, inlining, cardinalities
and all tier conditions against an independent literal eight-field required
closed root. Actual copied-YAML metadata/class/parent/range/count/tier/coupling
mutations exercise the SAME family oracle.
`test_initial_outdoor_population_values` independently guards both complete roots
before complete logical camp/all-four-rescue witnesses, both pack entries, boss,
repeated equal assignments and malformed/missing/null/container/member controls.
`test_initial_outdoor_population_native_mutations` regenerates the selected actual
rule/count/population-range mutations against the SAME declaration oracle and
separately checks native broadening and admission no-effect.

Required closed roots, nested population constants, direct two-pack bounds,
camp tier and its BOTH pack/boss tier agreement are **category1** on pinned
LinkML1.12.1. Rescue site bounds and singleton boss agreement at all four tiers
are also category1. Rescue PACK tier agreement is declared precisely in all four
raw/get/induced class rules but is **category2**: the native anonymous conditional
emits object `properties.tier`/`allOf` on `pack-assignments`, with no array `items`.
Either pack or both packs can therefore disagree while a wrong boss rejects.
Removing tier3 postconditions fails the SAME declaration oracle and broadens boss
admission, while already admitted pack-only mismatches remain admitted; this is
not whole-rule native enforcement or total no-effect. No schema-output rewrite,
custom admission engine or new wrapper/state/policy hides that boundary. Existing
assignment `boss.equals_expression` Boolean non-enforcement stays category2;
required boss special and forbidden nonboss special/spirit/mission spirit remain
separately enforced. Equal assignment values do not imply uniqueness or rerolls.

These logical witnesses are not raw configuration/current-save admission, land
FK validity, physical placement/occupancy, live survival, independent role RNG,
probability attachment, captive identity, completion/renewal or local-difficulty
execution. Room and whole-land association structures, population counts/tiers and
local-difficulty profiles are declared above; this does not prove generated room
allocation, whole-land totals/distinct supplier tiers, species/roles, formulae or
runtime behavior. Polygon topology and portable wire encoding/serialization remain
unselected. Known native backend ceilings are documented above; they do not establish
additional runtime enforcement. Full Task3 review remains pending. Historical fixture
invocation evidence gaps, save-world57/directory-lint and Task4/Task7/runtime/integration
gates remain; metadata114 was completed with the approved 57/57 partitions.


## Ruins designated rooms, population and permanent assignments

`encounter-contracts.md#geometry-and-occupancy`30–42 and
`#populations-tiers-and-clear-conditions`44–66, with unchanged
`generators.json#design.initial-encounters.ruins`/`pack-size`, map to
`world.yaml:initial-populated-ruins-room` and `initial-populated-ruins-assembly`.
The room IS its inherited volume occurrence, without new identity, ordinal,
parallel geometry or saved state. Its singleton pack assignment is shared by
three guards; separate non-mission bosses retain the existing special/spirit
scope. The assembly refines the SAME inherited `rooms`, not copies or parallel
tier lists, and associates the existing complete designated population.

Four `LogicalWorldTests.test_initial_ruins_population_*` methods in
`test_ontology_schema_world_ruins_population.py` and `test_ontology_schema_world_ruins_population_values.py` cover complete both-owner RAW goldens
before induction, get/induced/contextual facets, unique inherited names/aliases,
independent closed native roots, complete logical witnesses and actual copied-YAML
mutations against the SAME full oracle. `contracts` preserves the old assembly
and volume and sibling identity/range contracts; `order_binding` uses the actual
public SDK/contextual SchemaView with fourteen complete containing objects and
proves nonmutation. `values` separately characterizes343 native cases, including
all31 intended positives and exactly18 intended-negative admissions.
`native_mutations` distinguishes declaration loss, expected-value absence,
native no-effect and concrete scalar-bound broadening; no generated output is edited.

**Category1, within these controls:** inherited geometry/counts, required closed
fields, typed singleton/list/cardinality/scalar facets, room/pack/boss tier
coupling, forbidden tier1 boss, required tier2/3 boss KEY, and tested special/spirit
boundaries. **Category2:** exact sequence/duplicate exclusion is declared by the
contextual `equals_expression` plus ordered required exact-three typed rooms.
Public `generate_slot_value` returns the SAME whole list only for123, otherwise
an unequal empty list. This is expected-value binding, NOT native admission,
STRICT inference rejection or a general validator; cardinality excludes empty
input. Removing ONLY that expression makes all14 SDK results absent (`None`),
while native selected definitions and all6 permutation admissions are unchanged.

Native LinkML1.12.1 admits five wrong permutations, six duplicate-tier lists,
five inherited contrary boss Booleans and two null tier2/3 bosses:18 source-intended
negative admissions, not newly valid domain values. Boolean equality predicates
remain precisely declared. Conditional PRESENT plus nominal boss range/inlining
requires an actual nonnull assignment; anonymous native `omit_type` conditions
weaken this to key presence against the optional ref-or-null property. Retain all
three category2 ceilings separately; no custom checker or global null change.

These synthetic logical witnesses are not source configuration/current-save
admission, production identities, referenced-land existence, spatial placement,
role RNG/independence, live survivors, safe renewal or lifecycle execution.
The logical fauna slot now has focused authored/induced/native and actual-YAML
mutation coverage in `test_ontology_schema_world_basic_p2.py`, but creature-reference
existence and generated fauna selection remain unproved. Whole-land allocation,
species/role RNG and difficulty/formula execution, historical fixture gaps,
save-world/directory lint and Task4/Task7/final/integration gates remain open.
Metadata114 coverage is complete under the approved partitions. Polygon topology and
portable wire encoding/serialization remain unselected rather than unmodeled shape gaps;
documented native backend ceilings remain explicit.

### Initial-site hostile profile

`world.yaml#initial-site-hostile-profile` links the existing designated-hostile
species and role probabilities to
[the population rule](../../ontology/domain/encounter-contracts.md#populations-tiers-and-clear-conditions)
and `generators.json#design.initial-encounters`.
`test_ontology_schema_world_hostile_profile.py`: `LogicalWorldTests.test_initial_site_hostile_profile_contracts` and
`test_initial_site_hostile_profile_mutations` cover the raw/induced nominal
contract, closed native root, 45 finite payloads, actual-YAML metadata mutations
and numeric-bound broadening. Category1: required scalar literal/fixed bounds;
nominal `creature` typing is not native FK existence enforcement (category2).
Independent once-only pack/singleton choice and retention remain linked behavior
(category3), not RNG/lifecycle/runtime proof. Captives and ambient rosters stay
separate; whole-land allocation and local difficulty remain outside this profile.
Full Task3 and integration remain open.


### Initial-site local difficulty and boss size

`world.yaml#initial-site-local-difficulty-profile`, `#initial-site-hostile-spawn`
and `#initial-site-boss-spawn` declare the precise logical specialization of
[local difficulty and boss size](../../ontology/domain/encounter-contracts.md#local-difficulty-and-boss-size).
`test_ontology_schema_world_local_difficulty.py`: `LogicalWorldTests.test_initial_site_local_difficulty_contracts`, `_values` and
`_mutations` cover raw typed fixed facets, semantic SDK integer metadata, nine
inherited facts, SAME parameters, independent complete closed roots, full logical
witnesses, public safe-slot/class/Config inference, nonmutation and14 actual-YAML
mutants through the SAME raw-first oracle.

Category1: required closed typed fields, fixed numeric bounds, designated species
and hostility, tier/power/height bounds. Category2: nominal references are not FK
existence checks; power and height equations are declared and publicly computable,
but native JSON Schema admits wrong in-bounds supplied targets. SDK inference
returns the calculated value without comparing or updating the stored target.
Removing either expression yields SDK None with byte-equivalent native schemas.
The1e-12 allowance is SDK arithmetic reconstruction only, never authored-bound or
engine tolerance. Inherited level has no invented gameplay minimum.

These are logical witnesses, not raw generator-envelope/current-save admission.
Relative boss HP/direct damage remain distinct from existing NPC curves, party
selection, no-rescale and once-only hit-derived DOT rules. RNG, lifecycle and
runtime application remain category3 linked behavior, not tested simulation.
Whole-land allocation remains a separate allocation question; directory/save
frontiers and full Task3/Task4/Task7/integration acceptance remain open.

### Initial populated land

`world.yaml#initial-populated-land` specializes the existing land and links its
six designated sites to [placement and populations](../../ontology/domain/encounter-contracts.md#placement-and-access).
`test_ontology_schema_world_populated_land.py`: `LogicalWorldTests.test_initial_populated_land_contracts`, `_owner_binding` and
`_mutations` cover independent raw/getter/induced facets, five closed selected
roots, a complete synthetic logical land/site fixture, malformed/required controls,
16 actual-YAML losses and nonmutating public owner computations.

Category1: required singleton scalar references and existing identifier shape.
Category2: nominal target classes, rescue tiers and the local inherited-id owner
equality remain declared; record JSON Schema does not resolve existence, class,
tier, ownership or graph uniqueness. Explicit supplied typed JsonObj endpoint
views preserve scalar references and owner strings; the SDK callback only supplies
those views. A mismatch result is a contradiction witness, never a replacement ID
or native rejection. Removing the equality has no native schema effect. Missing
or ambiguous supplied endpoints are incomplete resolution, not FK rejection.
Identifiers remain class/ancestor scoped; arbitrary multi-typed distinctness and
the deferred P2 object-member permutation are not certified. These are not raw
save/configuration, runtime resolver, lifecycle or engine tests. Remaining source
precision, full Task3/family/final gates and integration remain open.

### Initial-site placement parameters

`world.yaml:initial-site-placement-profile` records the fixed parameters in
`encounter-contracts.md#placement-and-access`. The three
`test_ontology_schema_world_site_placement.py`: `LogicalWorldTests.test_initial_site_placement_{contracts,values,mutations}`
methods guard the raw declaration and native closed root, exact constants and
metadata, malformed admission and actual-YAML facet losses. Integer equality,
required fields and closed object shape are category 1; source/alias/URI metadata
are authored/induced contracts rather than extra native data constraints.
Seeded fixed positions, village-square distance measurement, the floor relationship,
conditional failed-ocean-village dry hub, protected area, joint required geography
and optional non-walkability-guaranteeing guidance remain linked procedures
(category 3), not runtime or saved-world qualification by parameter admission.

### Deposit yield interval and hybrid inn paid sleep

`3_Classes.md#deposit`182–185 maps to `world.yaml:deposit-ingredient-yield`,
a contextual subtype of the unchanged `associations.yaml:ingredient-yield`.
Only the inherited minimum/maximum are refined; `world-catalog.yaml:deposit-yields`
and raw catalog strings remain unchanged. The three
`test_ontology_schema_world_yield_sleep.py`: `LogicalWorldTests.test_deposit_yield_interval_{contracts,values,mutations}`
methods guard complete raw/SDK/native 3/3 required closed roots, inherited aliases,
integer constants and malformed roots/fields, with 18 actual copied-YAML losses
through the SAME raw-first oracle and a native equality-loss broadening witness.
Category1: required typed closed shape and fixed endpoints. Category2: nominal
ingredient typing does not establish FK existence; sandstone remains the sole
missing ingredient among nine targets (eight resolved). The generic association's
coupled minimum<=maximum rule remains unenforced, not silently narrowed globally.
This is the fixed interval, not an emitted quantity, distribution or raw payload.
Renewal and extraction behavior remain linked procedures (category3).

`3_Classes.md#game-clock` hybrid settlements/inn items2–4 (314–336) and
`5_Constraints.md#c-inn-hours` map to
`world.yaml:hybrid-inn-sleep-service-parameters`. The three
`test_ontology_schema_world_yield_sleep.py`: `LogicalWorldTests.test_hybrid_inn_sleep_{contracts,values,mutations}` methods
cover the independent complete 4/4 required closed root, exact integer constants,
malformed/missing/null/bool/extra controls and 40 actual copied-YAML losses through
the SAME oracle, including native fee-equality broadening. These scalar facets
are category1. The overnight18→6 window is not an ordered numeric interval.
Free anytime healing/respawn, explicit connected-party agreement, the single
initiator fee only on success, refusal/no charge, next07 semantics, ordinary
midnight resets only when crossed/no extra refresh and no accelerated combat,
statuses or cooldowns remain linked procedures (category3), not runtime checks.
`game-clock`, including fresh-world07 and historical100x reference sleep, is
unchanged. Neither profile qualifies configuration/current-save envelopes,
lifecycle, FK resolution, full Task3, Task4 or integration.


## Qualified world component declarations (Task3; not completion)

| Canon/source | Elements | Contract |
|---|---|---|
| §3.1 world/zone; cuwo ChunkDiscovered and CWSDK global-zone keys | `zone-coordinate`, `cuwo-discovery-coordinate-components`, `cwsdk-zone-coordinate-components`, `world.discovered-zones` | `test_qualified_discovery_components`, `test_qualified_world_attachments_and_state`; logical pair objects/world-shared exploration, not raw packets, personal unlocks or persistence encoding. cuwo u32/256-block context differs from SDK signed C++ int/64-block context; portable SDK width is unknown; 20-block mapchunks remain separate. |
| §3.1 zone; cuwo ChunkItemData, berld GroundItem | `dropped-item`, cuwo/berld `dropped-item-components`, `zone.chunk-items` | `test_qualified_drop_components`; known f32 rotation/scale and qualified source timer signedness, signed position triple and nominal Item reference. No yaw degrees, positive/uniform scale, timer unit/age/epoch or active/save encoding selected. Complete-wire Item admission is later work. |
| §3.1 static-entity, raw catalog header, cuwo header/use, berld WorldObject/Hitbox | `static-entity.closed`, `.occupant`, `cuwo-static-header-components`, `berld-static-header-components`, `berld-static-size-components` | `test_qualified_static_components`, attachment/state contract; cardinal orientation, separate Boolean-use/state and sitter reference. cuwo vec3 size differs from berld named Hitbox components. No universal signedness, ABI, identity or empty sentinel. Storage projections do not enforce berld Kind enum membership or certify original-client legality. |
| §3.1 static-entity; cuwo `StaticEntity`, `ItemWithHeader`, list wrappers | `cuwo-static-entity-components`, `cuwo-item-with-header-components`, `cuwo-item-with-header-list-components`, `cuwo-item-with-header-lists-components` | `test_ontology_schema_world_static_composition.py`: outer header/list/nominal Item composition and source `something1`–`something7` u32 types, pinned to `cuwo/tgen_wrap.pxd#L222-L292`. The seven components have no inferred meanings; Item stays a nominal reference with no full payload. List/vector fields model only known nested collection shape, not portable ABI/storage. |

All new roots have independent native root guards; real class-deletion and field/
facet SAME actual-YAML mutations call the same raw/induced/native oracle. The
historical source-preparation checkpoint retained 149 methods/cases/helpers,
with only required literal world/zone root and empty-positive updates. The current
scoped gate provides passed evidence for 113 selected methods across 108 obligations;
it is not a whole-family or all-149 test pass, whole-Task3 acceptance, or portable
wire/runtime certification.

Backend limits: float typing does not prove f32 precision/packing; numeric storage
bounds do not authenticate legal source codes. Foreign-key existence, sit/open
subset applicability, timer behavior and world-shared exploration behavior are not
runtime enforcement. Optional logical state null remains native characterization,
not historical wire null. Exploration set uniqueness is declared and induced;
the pinned native characterization emitted no `uniqueItems` and admitted duplicate
coordinate pairs. Native duplicate rejection is not established; no custom checker
or runtime enforcement is selected. Raw header components exclude padding, packet
envelopes and additional static Item/list/opaque fields; this is not full
logical/static/source family coverage. The canonical `land-border` declaration uses
`polygon` only as a logical kind: the authored class and induced range have no vertex
slots. The pinned JSON Schema backend currently emits the empty class as a closed
object and the optional border range as nullable; neither projection is selected as a
polygon wire contract or full-wire admission. No vertex encoding, coordinates, identity,
topology, or geometry validation is established.
Historical marker lists are not selected as polygon vertices and are not evidence of
canonical polygon correspondence. Task3 is incomplete; no Task4 Item bodies, runtime,
saves or domain decisions follow.

## Task4 — items, crafting, economy and mission inputs

Paths are relative to `ontology/`; tests are in `tests/`. These are structural
contracts, not runtime/save adoption, whole-Task4 acceptance or a fresh native replay.
The source roots below retain complete documents, not logical Item projections.

| Canonical anchor / source | Named YAML facets | Actual focused contract and limit |
|---|---|---|
| §3.4 `item`; §5 c-item-upgrade-count/c-item-weapon-type/c-cube-cap | `items.yaml`: `item`, `item-upgrade`, `item-{type,sub-type,weapon-type,modifier,minus-modifier,rarity,material,flags,level,upgrades,upgrade-count,name,land,plus}`, `item-upgrade-{x,y,z,material,level}`; `item.rules[0..1]`, `item.all_of[0..2]`; `identity.yaml`: `uint32`, `u8`, `i16`, `i8` | `test_ontology_schema_task4_item_facets.py`: `test_declared_item_upgrade_inventory_facets`, `test_item_facet_mutations_fail_raw_oracle`, `test_item_roots_match_explicit_literal_fields`, `test_active_count_expression_sdk_semantics`, `test_native_item_capacity_and_material_limits`, `test_native_upgrade_inventory_boundaries`. Native widths, logical power bounds, global list32 and conditional scalar count16 do not prove count=list, conditional list16 or wood/iron member predicates. No raw ABI/FK lookup or numeric type conversion. |
| §3.4 `inventory`; §4 holds/equips | `items.yaml`: `inventory`, `inventory-entry`, `equipment-assignment`, `inventory-{entries,equipment,coins}`, `inventory-entry-{item,count}`, `equipment-assignment-{slot,item}`, `equipment-assignment.unique_keys.slot`; `entities.yaml:player-character-inventory`; `relations.yaml:{holds,equips}` | Same Item-facets declaration/root/mutation/boundary methods; `CraftingSocialTests.test_task4_logical_item_and_recipe_contracts`. Positive count, uint32 coins, list12 equipment and uncapped bag/stack remain distinct from native slot uniqueness, stack eligibility, slot/class/hand/subtype legality. `inventory.start` is the original Task6-owned/unconverted row, not counted as converted. |
| §3.4 recipe/formula/book; §3.5 power-gate; §4 knows-recipe/crafted-at/consumes/produces/refines-to | `items.yaml:{recipe,recipe-required-power,formula,formula-recipe,book-of-crafting,book-recipes}`; `entities.yaml:slots.knows-recipe` (alias `known-recipes`, `list_elements_unique: true`, attached in `classes.player-character.slots`); `relations.yaml:{crafted-at,consumes,produces,refines-to}`; `associations.yaml:recipe-consumption`, `recipe-consumption-{input,count}`; `catalog-crafting-social.yaml:ingredient-refinement` | `CraftingSocialTests.test_task4_logical_item_and_recipe_contracts`; `Task4LogicalTests.test_attached_logical_fields`, `test_native_item_formula_and_book_boundaries`, `test_native_recipe_power_and_artifact_boundaries`, `test_actual_yaml_added_facet_mutations`. Formula inherits Item, book does not; recipe power is +1..+100, book count3–4 is S reference, not hybrid cardinality. Native does not execute learning/duplicates/power locks or FK/learned-set uniqueness. |
| §3.4 artifact; §5 c-artifact-stat | `items.yaml:artifact`, `ArtifactTraversalKind`, `traversal-kind`, `artifact-name`, `artifact-origin-realm`, `artifact.slot_usage.raises-stat`, `artifact.rules[0..7]` | `Task4LogicalTests.test_artifact_and_arena_exact_declarations`, `test_artifact_native_membership_enforcement_limits`, `test_artifact_arena_actual_yaml_rule_mutations`, `test_native_recipe_power_and_artifact_boundaries`. Three distinct targets and all memberships are declared; native enforces size and attack membership, not hp/matching-traversal membership or uniqueness. Readonly is annotation, origin is nominal. Logarithm/equal shares/current-stat recalculation remain canonical formulas, not native execution. |
| §3.4 artifact/book personal claims; §5 c-permanent-source-claim | `associations.yaml:personal-permanent-source-claim`, its character/world/source-kind/source-key attributes and `unique_keys.character-world-source`; `PersonalPermanentSourceKind` | `test_ontology_schema_task4_claims.py`: all four `PersonalSourceClaimTests` methods. Character + saved-world + kind + opaque source key is distinct from seed/reward ID; no current save member. Shape/token rejection does not enforce compound uniqueness, source existence, issuance or nonrenewing lifecycle. |
| §3.6 mission-type/arena | `meta.yaml:mission-type.{icon,tier,repeat,structures}`, `MissionTier`, `arena.{waves,host,repeat,reward-coins}`, `arena-wave.tiers`; `relations.yaml:rewards` | `LogicalMissionTests.test_mission_and_arena_logical_structures`, `test_mission_arena_and_artifact_native_boundaries`; `Task4LogicalTests.test_artifact_and_arena_exact_declarations`, `test_arena_native_constant_enforcement_limits`, `test_artifact_arena_actual_yaml_rule_mutations`. Native count/tier/host/repeat facets do not enforce exact ordered ladder/coin expression values, referenced targets, final-boss execution or source availability. |
| §3.4 material/ingredient/equipment-slot/pet-food; §5 required inputs | `items.yaml:{material,ingredient,equipment-slot,pet-food}`, `pet-food-tames`; `catalog-crafting-social.yaml` material/ingredient facets; `catalog-properties.yaml:slot-acceptance-condition` | `CraftingSocialTests.test_selected_facets`, `test_native_values_and_limits`, `test_complete_ordinary_projections`, metadata mutation methods; source contracts below. Qualified descriptions are not parsed class/station/process rules. Logical plural taming targets do not rewrite the original scalar source or invent species IDs/history. |

### Complete source-root map

| Exact source file | YAML root / nested declaration seam | Real positive/negative contracts |
|---|---|---|
| `instances/item-types.json` | `items.yaml:item-types-source`, `item-type-source-{entry,row,additions}`, `item-type-subtype-{map,entry,key}`; `subtypes.exactly_one_of`, `source-map-union-range` | `ItemSourcesTests.test_complete_item_sources_roundtrip`, `test_item_sources_reject_missing_roots_and_malformed_shapes`, `test_item_type_map_union_yaml_guards`: symbolic scalar versus numeric-key map, no fabricated type IDs. |
| `instances/materials.json` | `items.yaml:materials-source`, `material-source-{entry,row}` | `CraftingSourcesTests.test_complete_crafting_sources_roundtrip`, `test_crafting_sources_reject_missing_roots_and_malformed_rows`: nullable bronze ID, numeric coefficients, qualified raw/class text preserved. |
| `instances/equipment-slots.json` | `items.yaml:equipment-slots-source`, `equipment-slot-source-row`, `equipment-extra-{source,row}`, `equipment-accepts-condition-{map,entry}` | Item-source positive/negative contracts: slots array, reserved empty accepts, subtype/condition maps, separate extra objects and rules string array. Not native equip applicability. |
| `instances/consumables.json` | `items.yaml:consumables-source`, `consumable-source-{entry,row}`, `consumable-rules-{map,entry}`, `consumable-recipe{,-entry}` | Item-source positive/negative contracts: source scalar/list union and numeric/symbolic recipe counts remain literal, no healing/default invention. |
| `instances/ingredients.json` | `items.yaml:ingredients-source`, `ingredient-source-{entry,row}`, `ingredient-unused-{data,entry}`, `ingredient-source-refinement{,-entry}` | Crafting-source positive/negative contracts: typed unused numeric table, compact symbolic refining maps, booleans-as-count negatives. No process parser. |
| `instances/recipes.json` | `items.yaml:recipes-source`; `recipe-armor{,-common,-tier}`, `recipe-piece`, `recipe-base`, `recipe-stations`, `recipe-weapons`, `recipe-weapon-{entry,row}`, `recipe-gems-by-rarity`, `recipe-refining{,-entry}`, `recipe-ingredient-{inputs,outputs}`, `recipe-{input,output}-entry`, `recipe-reference`, `recipe-sources`, `recipe-customization`, `recipe-null-marker` | `RecipesSourceTests.test_complete_recipes_source_roundtrips`, `test_recipes_source_rejects_incomplete_or_malformed_shapes`, `test_actual_yaml_marker_requiredness_annotation_and_shape_guards`, `test_literal_null_binding_requires_exact_empty_marker`: common gem is REQUIRED literal null, not omission or []; symbolic counts/grouped keys stay data. |
| `instances/crafting-stations.json` | `items.yaml:crafting-stations-source`, `crafting-station-source-{entry,row}` | Crafting-source positive/negative contracts: nullable static ID and descriptive action text retained, not runtime bench execution. |
| `instances/key-items.json` | `items.yaml:key-items-source`, `key-items-source-entry`, `key-item-source-row`, `key-item-{counts-source,cut-summary-source,acquire-source,artifact-source}` | `SocialSourcesTests.test_complete_social_sources_roundtrip`, `test_social_sources_reject_malformed_roots_and_values`; `FixedSectionsTests` below: fixed summaries are not admitted as ordinary item rows. Historical quantities/name forms/seven stat kinds and X group retained. |
| `instances/pet-food.json` | `items.yaml:pet-food-source`, `pet-food-source-{map,entry,row}`, `pet-food-cut-row` | Item-source positive/negative contracts: foods/cut catalogs, rules/shop-set arrays and scalar tame text. Reference validity, shared-food migration and availability are not native admission. |
| `instances/affixes.json` | `items.yaml:affixes-source` and its eight named array/string facets | Item-source positive/negative contracts: all rarity/name-form/example arrays and plus-suffix preserved; excluded S suffix is not active hybrid naming. |
| `instances/economy.json` | `catalog-properties.yaml:economy-source`, `economy-{currency,incomes,prices,shops,rules,loot}-source` and exact nested alpha/steam components | Social-source positive/negative contracts: A/S subfacts, exact numeric/string/map/list shapes, rules/gaps metadata; not global source inheritance or hybrid stock/price execution. |
| `instances/npc-roles.json` | `catalog-crafting-social.yaml:npc-roles-source`, `npc-role-source-{entry,row}`, `npc-dialogue-corpus-source` | Social-source positive/negative contracts; fixed-section tests: dialogue corpus is separate, building:null differs from omission, conditional attackability is text not a Boolean permission. |
| `instances/mission-types.json` | `catalog-properties.yaml:mission-types-source`, `mission-{alpha,steam,shared}-source`, nested entries/rows | Social-source positive/negative contracts; fixed-section tests: alpha/steam catalogs, `_shared` config, completion-order guide array and nullable icons stay distinct; cut/reference scopes remain. |

`test_ontology_schema_task4_fixed_sections.py`: `FixedSectionsTests.test_literal_root_and_nested_policies`,
`test_all13_unchanged_sources_roundtrip`, `test_fixed_sections_reject_missing_null_wrong_shapes_and_rows`,
`test_fixed_section_missing_members_and_guide_policy`, `test_unseen_keys_and_typed_unused_table`
and `test_actual_yaml_fixed_section_mutations` additionally guard fixed-versus-content
sections. All thirteen entire source documents retain exact original bytes and values.
YAML map/null/union annotations select reversible binding only, not source mutation.
Required-null common gem uses its precise empty-marker inverse; ordinary optional
nullable scalars need no marker. Key patterns bind entry keys; native JSON object-key
uniqueness/FK checking and global source attribution are not implied.

The retained evidence map has 69 selectors: 12 reused D1 passing receipts, 54
qualified prior passes and three unaffected-not-replayed literal probes, not 69 new
passes. Known native ceilings remain explicit; full save logical graph/reference
metadata is unequal, while the reused save-root guard is qualified only for its
actual unchanged root predicates. The latest directory lint remains the unchanged
254-diagnostic later-family frontier (28 errors, 226 warnings), not a clean gate.
Historical A/S, X/cut, uncertainty and finite §5 source inheritance remain canonical;
untagged histories gain no default tags. Regional gear weakening is permanently
excluded, not deferred. No runtime, save, raw source or generator defaults change.

## Task6 generator and selected design contracts (candidate, not acceptance)

This extends only generator/design coverage. No runtime, generator, save-format,
backend adoption or Markdown handoff is established by these checks. All original
`generators.json` values, A/S/X/Omega qualifications and excluded regional gear
weakening remain unchanged. `design-world.yaml` and `design-items.yaml` remain
public imports alongside combat/progression; their topic modules hold the moved declarations.
The terrain, selected design, initial encounters and source envelope attach named slots with their original wire aliases.
The source contract is bound, not direct raw-wire admission: local `{key,value}`
entries, declared positional tuples and the one literal-null marker preserve the
whole document with inverse equality. IDs are not fabricated model attributes.

| Scoped canonical anchor/source | Explicit YAML destination | Source-named checks |
|---|---|---|
| §5 required-inputs; complete generators source, historical siblings and all design groups | `design-items.yaml:generators-source`, `generator-design` and their attached slots in `design-items-*.yaml`; `design-world-*.yaml` source/selected owners; existing `design-combat.yaml` / `design-progression.yaml` | `test_ontology_schema_generators.GeneratorSourceTests`; `test_required_whole_source_and_every_design_group`; `FullInputContracts.test_whole_generators_source` |
| §5 c-world-bounds/c-zone-size/c-time-speed/c-sim-radius; terrain/climate/name/spawn pairs | `design-world.yaml:generator-design-terrain` with `design-world-terrain-*.yaml` slots; `design-world-{time,climate,names,spawns,spawn-ai}.yaml` | complete source/roundtrip, climate collection, selected bounds, coupling scalar/native-ceiling methods |
| §5 c-ability-runtime/c-moveset-config; resource/special/status configuration | `design-combat.yaml:ability-runtime`, `runtime-cost`, `runtime-strike`, `runtime-projectile`, `generator-design-{abilities,resources,special-attack,status-effects,movesets}`, `generator-status-entry` | declaration oracle, exact selected/Boolean/projectile boundaries, status map and closed moveset tests |
| §5 c-progression-config/c-gear-hp/c-artifact-stat | `design-progression.yaml:generator-design-progression`, `generator-progression-gap`, `gear-hp-design`, `artifact-design` | complete source, selected bounds, retained ability/progression projection |
| §5 c-defence-config/c-feel-config/c-creature-roles/c-design-color-syntax | `design-combat.yaml:generator-design-{movement,defence,feel,creature-roles,frame-budget}`, `generator-projectile-role`, `generator-role-override`, `generator-rgb-entry`; parent-context fields in `design-items-design-presentation-fields.yaml` and `design-items.yaml:generators-source-field-design` | literal raw/get/induced contexts, scalar/native-ceiling tests, seven strict string-colour locations, RGB map/role overrides |
| §5 c-loot-config/c-encounter-rewards-config/c-settlement-config | `design-items-{loot,prices,inventory,settlement}.yaml` and their imported loot map, shop, footprint and style declarations | selected loot/shop/AI inputs, map/default/reference tests, exact bounds and actual-YAML selected-input loss |
| §5 c-initial-encounter-config; encounter-contracts placement/geometry/populations/local difficulty/specials/rubble/traps/furnishings/rewards | `design-items-encounters.yaml:generator-design-initial-encounters` and `design-items-encounter-*.yaml` slots and children; retained `world.yaml` initial placement/assembly/population/special/reward profiles | complete source and literal independent selected geometry/tier/colour/weighted-profile declarations; inherited dungeon evidence stays qualified |
| §6 gen-world/climate/terrain/coarse-map | `design-world-{source-world-scales,source-time-climate,source-terrain,omega-coarse-map}.yaml`; active terrain/climate designs | full-source and climate tuple/type/order-preservation checks, not world generation |
| §6 gen-flora/dungeon/poi/missions | retained earlier flora/dungeon/POI roots; `generator-source-{land,dungeon}`, initial-encounter config | prior family receipts and affected dungeon selector; no fabricated generators.flora/poi fields |
| §6 gen-settlement/spawns/boss/name | historical `generator-source-{settlement,spawns,boss,names}`, active settlement/spawn/name/role config | real-source positives, arena bound-carrier literal and map/reference checks; no RNG/placement proof |
| §6 gen-item/gen-item-stats/gen-loot | `generator-source-item`, `generators-source.loot` STRING, active loot/gear-HP/item-stat-curve fields | complete source and selected scalar/map/pool tests; formulae remain canonical |
| §6 gen-realm/npc-appearance/schedule/key-items | corresponding `generator-source-*` owners | complete source envelopes; historical/availability/source qualifications retained |

`ontology_generator_expectations.py` holds independent literal obligations, not a
second schema. `declaration_oracle` applies them before SDK construction, then
checks get/induced facets and real emitted closed roots. The SAME oracle validates
unchanged baselines and each actual-YAML loss/broadening mutant. Original10cases
remain; correction adds6coupling/context and8selected-input cases. Each asserts
actual source bytes changed; mutation-specific expected-output rewriting is absent.
The declaration context test explicitly executes NO expression/evaluator/rule engine.

### Precise predicates and deliberately retained boundaries

- Settlement keeps integer radius minimum1/blend0/no-hostiles0 and three separate
  typed completed-object predicates. Negative ring-radius remains legal where
  ring<radius. No new tunable, epsilon or ring minimum is inferred.
- Simulation and ranged/mage comparisons use complete existing objects and literal
  raw keys, not assumed underscore normalization or later sibling bindings. Feel
  compares all eleven REQUIRED durations with the configured maximum; dodge cost
  compares with the configured stamina maximum. The failure carrier is outside
  the required object range. Static support is not end-to-end rule execution.
- The five sample-sorted enemy-HP/spawn/camera pairs retain their2item types and
  cardinalities, but NO unapproved ordering predicate. Shape-valid reversed
  examples are not called canonical violations. Overnight inn-hours is unchanged.
- Arena equality describes the bound positional dictionaries, preserving original
  raw arrays/order. Supplier and True literals remain. Redundant iframe equality
  is removed while its numeric minimum remains.
- Exact selected loot/shop/AI/taunt inputs are explicit, without freezing unrelated
  tunables. Optional nested projectile multiplier excludes0WHEN PRESENT; omission
  and the real shuriken-attack.6 fixture remain valid. Generic burst/taunt0damage
  remains legal. The callers are ability throw, projectile role shot and optional
  species shot override; retained projections are dependency-qualified, not whole
  unchanged metadata claims.
- Status entries correlate six known keys with six closed payload variants, while
  only burning/poison have selected required-member declarations. Numeric feedback
  colours require only hit plus RGB3[0,1]; footprints require only default plus
  building overrides. Maps preserve repeated building references and scalar types.
- Seven selected string-colour fields use mandatory# plus exactly6or8hex digits
  with exact end/case-insensitivity; optional override omission is valid, null is
  not. Numeric RGB maps are separate. No raw colour value or runtime parser changes.
- Artifact text remains string-typed with canonical logarithm/contributor/state
  semantics; no spelling freeze or ln/climate evaluation. Variable mixed numeric/
  `all` stamina costs, merged roles, configured-key/alias/source-style/audio joins,
  FK existence, lifecycle/RNG/physics/solvability remain precisely retained rules,
  not automatically certified by native JSON Schema.

Native scalar bounds/cardinalities/closed known payloads are construct-specific:
the V1seven-call qualification rejects common59(min60), weapon3(min4) and Heroic
Shout taunt2(min3) through emitted numeric/nested-slot postconditions. It admits
pool reorder/duplicates and missing heroic membership. Class-range status
postconditions remain a separately observed ceiling; do not infer all correlations
are ignored. Copied bound negative fixtures in the selected-input/coupling methods
reuse one actual-source binding/inverse equality/native positive each, not a raw
roundtrip per negative. Exact logical keys select weighted-map/ability mutations.
These admissions are backend observations, not secretly accepted domain rules. Deprecated ReferenceValidator source hazards remain unexecuted and unfixed.
No SDK evaluation or custom grammar/interpreter is part of the suite.

### Evidence frontier

The correction's semantic RED starts with the real declared settlement root and
positive fixture: all three scalar-1negatives were admitted (3intentional failures,
1method52.396body/67.469owned seconds), not missing-class/setup errors. Final
selected declaration/value/mutation/lint/cap receipts and their source pins belong
in the managed cumulative Task6review package; this test map does not itself claim
review acceptance. Existing full-source3method evidence remains at its actual
pins (295.463owned vs267.973body). Fresh real-source affected-owner fragments compose
with explicit unchanged source/binding/alias/tuple/order/method bridges; unrelated
changed `$defs` are never called byte-identical whole schemas. Changed boundary,
status, declaration and oracle methods are excluded from old-green bridges.

The last qualified directory frontier is184save diagnostics (26errors/158warnings),
zero Task6/new diagnostics, not global clean. Exact Counter/five-protected-source
comparison remains required. The single `at-cursor` naming exception preserves its
literal/enum identity and has native positive/five-negative policy controls; its
name match is global, not enum/file-scoped. No later-family repair is selected.


### Task6 review-fix round1 qualification boundary

The prior unchanged-result bridge for
`test_remaining_config_facets_and_required_weapon_entries` is WITHDRAWN: its old
zero-spread positive contradicted the selected exact1source bound. The corrected
method retains1positive,0/-1/Boolean negatives and all later scalar/map/weapon
cases. Native results at final fix pins are recorded separately in managed evidence;
unchanged method text alone never qualifies a changed dependency.

The existing ability-runtime projectile conditional now owns strict-positive
speed/life facets; generic global optional/minimum0and burst damage0remain unchanged.
Configured runtime/kind membership joins remain explicit canonical cross-collection
rules, not frozen sample lists or a rule interpreter. Level-up text is nonempty
without a single-line restriction. One concrete `generator-feel-event` replaces
only the eleven identical new child types: all11parent slot identities and all3
payload aliases/types/bounds/requiredness remain. Child type/slot IRIs intentionally
consolidate; old metadata bytes are not claimed equal. Full-source tests reuse the
unchanged validate_source roundtrip once; no separate duplicate traversal remains.


#### Preserved VRpartitions after timeout

The original remaining-config monolith timed out at330seconds with unknown
reachability. Its legacy selector now denotes scalar partition A ONLY; the new
map-shape/malformed and required-weapon-membership selectors are partitions B/C.
Their mechanical ASTcase/assertion union preserves all28scalar validations,3map
shape assertions/5raw malformed owner-bound fixtures and15logical-key omissions.
Each repeats necessary real-source bind/inverse/native-positive setup and flushes
monotonic phase labels. Complete former-method coverage requires all three actual
results; no old monolith pass or historical reachability is inferred.

#### Projectile anonymous-condition wire aliases

The first full VN qualification failed four zero-admission assertions: both real
projectile abilities admitted speed0 and life-s0. A single full-source copied-graph
qualification then established the attachment cause: anonymous conditions emitted
internal slot names instead of runtime/speed/radius/life-s. Equals-number0 was
present in the emitted not/const branch; it was not dropped as a falsey value.
Four explicit aliases on that projectile rule alone attach its existing predicate
and strict-positive postconditions to the actual wire properties. The copied
candidate rejected all four zeros while retaining the complete-source positive,
nonprojectile optional speed0/life-s0 and generic burst damage0 controls. The real
schema consumes exactly those four aliases; values/mutation tests remain unchanged.
Fresh declaration/VN/full-C/mutation outcomes at these new pins are pending until
recorded in managed evidence; prior metadata passes do not certify native effect.

The other five ability-runtime rules still emit internal anonymous condition keys.
Their attachment risk is outside this selected correction and is disclosed to the
parent; no additional rule repair or enforcement claim follows. Full C passed at
its earlier actual pins with all15 omissions,332.179833887owned/298.955body seconds;
its exact scoped normal timeout is1248native/1278wait/1308caller. A/B retain their
actual earlier pins. Old failed330/139receipts, the original Dpreflight gap and exact
helper restoration remain separate qualifications, never relabeled clean evidence.

#### Review-fix qualification at final implementation pins

The four projectile anonymous aliases were qualified on a real copied graph and
then consumed by the schema before strengthening the independent raw/get/induced/
emitted wire-key oracle. Fresh complete D, unchanged VN, full C, SG, SC and all
10/6/8/4 actual-YAML mutation targets passed at those source pins. VN's original
four zero admissions are now intended conditional rejections; nonprojectile
optional0/0 and burst0 remain legal. Required-weapon/registry/status/reference
and completed-object expression limitations remain precise backend ceilings,
not domain permission or universal conditional enforcement. The other five
ability-runtime rule attachments remain separately disclosed, outside this fix.

The final cap-only adjustment changes M3's positive-fixture selection to a literal
local two-override lookup with the same default object. Whole-module/corpus/assert/
native-call preservation and actual four-label value AND object-identity equality
were proved before native. The same seven-path600/100/15 gate now passes; the
same full four-case M3 native qualification also passes. Its old16cap failure is
retained. No unrelated successful row was replayed. M0/M1/M2, D/VN/C/SG/SC and the
exact184save-diagnostic directory frontier retain their actual qualified inputs;
the test-only selection and this documentation have no schema/binding/fixture/
native-validation dependency for those methods. Managed evidence distinguishes
these bridges from fresh M3/CAPS results. Whole cumulative source/Markdown review
and application acceptance remain parent gates; no overlay is applied here.

### Task6 review round2 phase A (qualification only)

A combined full-source regression now covers18required runtime field contexts
(omission/null/Boolean),13fractional numeric domains,coherent radius0.5and a legal
negative ring radius. Current-source semantic REDobserved37specific failures
(12omissions,10nulls,13fractional fields and2geometry cases),after healthy complete
bind/inverse/native-positive baselines. Exactly17wire aliases,eight scoped numeric
all_of conjuncts and13integer-to-number restorations consume the existing rules.
Counts/exact constants and all older16values/28mutation intentions stay unchanged.
The same new five-method class passes with33real-YAML loss/native-effect checks
against the SAME independent raw/get/induced/emitted/root oracle. This is not a
full old-suite pass or source acceptance. Phase B's affected qualification and
complete fresh review/package remain pending; no domain overlay is applied.

### Task6 review round2 phase B (source still unaccepted)

Selected fresh D(5methods),VN(1),M0(2/10targets),M1(1/6),M2(1/8),M3(1/4)
pass at the repaired source. M3zero-exclusion removals still broaden despite the
new nonnull conjuncts. Configured directory lint exits2normally; complete raw
output is byte-identical to the accepted184diagnostic frontier(26errors,
158warnings,five frozen save owners),not globally clean. A first external
one-line Counter parser failed on header-formatted diagnostics; that failure
remains preserved, with separate parent-approved complete-byte comparison and
no lint replay. New five-method/33target evidence remains Phase A's actual run,
not a reporting rerun. Full old-suite/engine/native relational enforcement is
not claimed; source/package acceptance and actual Markdown application remain
separate parent gates.

## Godot frame-budget adapter association

The Godot adapter maps `design.frame-budget.max-catch-up-steps` to
`Engine.max_physics_steps_per_frame`. Schema validation does not execute or verify
that engine assignment; the domain's timing rule and configuration facets remain
separate from this consumer-specific association.
