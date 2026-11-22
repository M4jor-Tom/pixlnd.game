# Current-save consumer mapping

Task7 is authoring only. No loader, writer, gameplay import or validation route changes.
The logical portable progression contracts remain separate from this implemented wire format.

| Existing consumer source | Explicit LinkML elements | Structural checks |
|---|---|---|
| `game/world/save_data.gd`: `capture`, `item_data` | [`save-data`, `world-state`](../../ontology/schema/save-world-world-state.yaml); [`character-state`, `skill-investment`](../../ontology/schema/save-character-character-state.yaml); [`saved-item`, `saved-equipment-entry`](../../ontology/schema/save-character-saved-item.yaml) | `FullInputContracts.test_current_save_full_fixture_and_root`; `CurrentSaveContracts.test_literal_fields_required_and_closed_definitions`, `test_empty_hands_spirits_and_keyed_alternatives` |
| `game/world/save_character_rules.gd` | `saved-item-type`, `saved-item-level` and the `saved-item` power rule; `character-state` and `skill-investment` | `test_existing_item_and_conditional_wire_facets`; `test_current_character_and_item_wire` |
| `game/world/world_state.gd`: `snapshot`, `restore` | [`world-state`, `save-data`](../../ontology/schema/save-world-world-state.yaml); [`character-world-position`](../../ontology/schema/save-character-character-world-position.yaml) | literal inventory, nested deletions, direct root and world-envelope tests |
| `game/world/saved_spawn.gd`; `game/world/save_world_rules.gd` | [`saved-mob`](../../ontology/schema/save-combat-saved-mob.yaml), [its state slots](../../ontology/schema/save-combat-saved-mob-state.yaml); [`saved-combat`](../../ontology/schema/save-combat-saved-combat.yaml); [`saved-threat`, `saved-order`, `saved-provocation`](../../ontology/schema/save-combat-threat-records.yaml) | `test_positive_health_and_threat`; `test_scalar_list_and_coordinate_boundaries`; `test_current_combat_and_content_payloads` |
| `game/combat/targeting.gd`: `fresh` | `saved-combat` and its keyed threat/order/provocation rows | nested deletion/shape tests; `test_conditional_payloads_and_native_provocation_limit` |
| `game/world/encounter_gen.gd`: `plan`, `make_site`, `assignment` | [`saved-village`, `saved-land-plan`](../../ontology/schema/save-geography-saved-village.yaml); [`saved-site-layout` and its family rules](../../ontology/schema/save-geography-saved-site-layout.yaml); [`saved-assignment`](../../ontology/schema/save-geography-saved-assignment.yaml) | literal inventory; nested geometry/scalar tests; conditional facet tests |
| `game/world/world_sites.gd`: site/incarnation staging; `game/world/save_site_rules.gd` | [`saved-site` and its room rule](../../ontology/schema/save-world-saved-site.yaml); [`saved-spirit-level`, `saved-site-room-levels`](../../ontology/schema/save-world-saved-site-collections.yaml); [`saved-special`](../../ontology/schema/save-content-saved-special.yaml) | room declaration/native-limit and mutation tests; `test_saved_special_empty_or_three_coordinates`, `test_saved_special_coordinate_bound_mutations` |
| `game/world/encounter_gen.gd`: `fresh_contents`; `game/world/save_feature_rules.gd` | [`saved-contents`](../../ontology/schema/save-world-saved-contents.yaml); [`saved-rubble`, `saved-prop`, `saved-trap`](../../ontology/schema/save-content-saved-props-traps.yaml) | nested deletion/shape, scalar/list and current combat/content tests |
| `game/world/world_rewards.gd`; `game/world/save_reward_rules.gd` | [`saved-reward` and source-kind rules](../../ontology/schema/save-world-saved-contents.yaml); [`saved-vendor`](../../ontology/schema/save-content-saved-vendor.yaml) | conditional payload tests, literal inventory, nested deletion/shape tests |
| World/content keyed dictionaries | [`saved-mob-entry`, `saved-land-entry`, `saved-vendor-entry`, `saved-rubble-entry`, `saved-prop-entry`](../../ontology/schema/save-world-saved-entries.yaml); `saved-site`, `saved-reward`, `saved-spirit-level` | compact/explicit-wrapper admissions; `test_site_keyed_body_identity_limits` |

## Enforcement boundary

1. **Native structural enforcement:** direct closed root, mandatory parent fields, represented nested payload shapes, scalar kinds, coordinate/list cardinalities, non-null optional values, positive health/threat, item kinds and gear/consumable power bound. Empty hands remain omitted equipment keys. Layout family rules enforce tier/captive presence; source-supplied reward rows enforce conditional required fields.
2. **Declared but not equivalently enforced by pinned LinkML 1.12.1 JSON Schema:** keyed bodies may omit their identity or disagree with the map key; scalar maps admit explicit wrappers. The exact family-dependent room3/0 rule is retained, but native only enforces the generic empty-or-three list union. Provocation's true-only expression and list uniqueness are not enforced. Compact reward bodies omit the source key, so source-dependent rules do not determine their variant. Even with an explicit source, multiple `ABSENT` conditions emit one `not/required` group: native forbids their co-presence, not each field independently. Tests measure empty and nonempty extra class-list admission rather than pretending absence is enforced.
3. **Existing consumer responsibility:** catalog/reference closure, class/spec ownership, progression settlement/prerequisites/totals, equipment legality, deterministic geography, mob/pack identities and curves, source/cycle reward integrity, earned supplier ceilings, stock subsequences, world bounds and lifecycle. The synthetic fixture and its in-memory expansion are not valid generated-world or earned-progression certificates.

`SaveData.validate` still owns current-rule admission. `load_file` validates before returning state;
`write_atomic` validates before opening the temporary file and replacing original bytes. No runtime
source changed, so no new atomic-write, boot, migration, offline-time or crash-checkpoint guarantee
is claimed. Existing malformed raw-Dictionary equipment-key handling remains separately recorded
in `docs/HANDOFF.md` and is not repaired here.

## Reviewed scalar and snapshot facets

`CurrentSaveFacetTests` maps the existing validation predicates to the following precise
save declarations; it does not replace `SaveData.validate` or change atomic JSON persistence:

- `save_data.gd::integer` → exact `maximum_value` on the literal paths in
  `ontology_save_facet_expectations.INTEGER_SLOTS`. Raw/get/induced/emitted integer values and
  one actual-YAML maximum mutant are checked. Preserve stronger version1, rarity4 and the
  existing power100 conditions. `world-state-seed` uses a different source predicate and is
  intentionally excluded, as are unrelated generated geography integers.
- `save_character_rules.gd` coin rule → `saved-item.rules` empty subtype/material condition.
  `save_world_rules.gd` pack text and `save_feature_rules.gd` hit text → `saved-mob-pack.pattern`
  and `saved-trap-hit.pattern`; newline-only strings are valid nonempty controls.
- `save_site_rules.gd` active/inactive snapshots and phase restrictions → four `saved-special.rules`,
  including cooldown recovery `equals_expression: min({recovery}, {left})`. The installed pinned
  evaluator qualifies that equality over representative nonnegative pairs; native schema does
  not evaluate it. Configuration-dependent ceilings, distance/floor checks, kind/assignment
  agreement and lifecycle execution remain separate consumer responsibilities.
- `save_feature_rules.gd` rubble deadline and idle/warning hit emptiness → `saved-rubble.rules`
  canonical-slot disjunction and `saved-trap.rules`. SDK and raw declarations retain the exact
  correlations despite measured native boolean/cardinality gaps.

The numeric seam was measured once using the existing static helper, without save writes or
engine changes. Raw integer `9223372036854775295` passes and its successor fails; Godot parses
that successor JSON token as the smaller FLOAT `9223372036854774784`, which passes. Schema
checks distinguish raw integers and those observed parsed values; they do not certify lexical
JSON-parser equivalence. No blanket signed maximum was applied to all integers.

The otherwise-valid reward witnesses now measure individual field presence: mission position
alone rejects, while individual kill/furnishing prohibited fields can pass; grouped prohibited
co-presence rejects. Prior invalid-shape checks are retained but no longer described as absence
proof. Snapshot-limit witnesses also explicitly admit wrong active/inactive coordinate variants,
false active engagement, cooldown recovery above the remainder, rubble deadline mismatches and
nonempty idle/warning hitsets. These are backend qualifications, not weaker domain rules.
