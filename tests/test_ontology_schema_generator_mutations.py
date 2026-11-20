"""Actual YAML loss/broadening against the same independent baseline oracle."""

from copy import deepcopy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import jsonschema
from linkml.generators.jsonschemagen import JsonSchemaGenerator
import yaml

from ontology_generator_expectations import REQUIRED_WEAPONS
from ontology_source_contracts import _walk, class_contract, assert_declared_root
from test_ontology_schema import SCHEMA, generated
from test_ontology_schema_authoring import catalog
from test_ontology_schema_generator_declarations import declaration_oracle


def assert_member_no_effect(test, baseline, emitted, movesets):
    for schema in (baseline, emitted):
        native = jsonschema.Draft201909Validator(schema)
        native.validate(movesets)
        admitted = []
        for key in REQUIRED_WEAPONS:
            bad = deepcopy(movesets)
            bad["entries"] = [entry for entry in bad["entries"] if entry["key"] != key]
            if not list(native.iter_errors(bad)):
                admitted.append(key)
        test.assertEqual(admitted, list(REQUIRED_WEAPONS))
    test.assertEqual(len(baseline["$defs"]["generator-design-movesets"]["allOf"]), 15)
    test.assertEqual(len(emitted["$defs"]["generator-design-movesets"]["allOf"]), 14)
    print("MEMBERSHIP mutant: SAME oracle rejects; native allOf15→14; same15 omissions admitted")


class GeneratorMutationTests(unittest.TestCase):
    def test_actual_yaml_bound_alias_and_attachment_mutations(self):
        declaration_oracle(self)
        baseline = generated("generator-design-terrain")
        value = {"zone-blocks": 65}
        fragment = {"$defs": baseline["$defs"],
                    **baseline["$defs"]["generator-design-terrain"]["properties"]["zone-blocks"]}
        print("BASELINE terrain.zone-blocks", json.dumps(
            baseline["$defs"]["generator-design-terrain"]["properties"]["zone-blocks"], sort_keys=True))
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate(value["zone-blocks"], fragment)
        movesets = _walk("generator-design-movesets", catalog("generators")["design"]["movesets"], False)
        member_baseline = generated("generator-design-movesets")
        jsonschema.validate(movesets, member_baseline)
        for mutation in ("bound", "alias", "attachment", "required-member"):
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                name = {"attachment": "design-items", "required-member": "design-combat"}.get(mutation, "design-world")
                path = target / (name + ".yaml")
                data = yaml.safe_load(path.read_text())
                if mutation == "required-member":
                    data["classes"]["generator-design-movesets"]["all_of"].pop()
                elif mutation == "attachment":
                    data["classes"]["generators-source"]["attributes"]["design"]["range"] = "generator-design-terrain"
                elif mutation == "alias":
                    data["classes"]["generator-design-terrain"]["attributes"]["zone-blocks"]["alias"] = "zone-count"
                else:
                    data["classes"]["generator-design-terrain"]["attributes"]["zone-blocks"].pop("maximum_value")
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.assertRaises(AssertionError):
                    declaration_oracle(self, target)
                if mutation == "attachment":
                    continue  # Raw attachment loss is rejected by the SAME oracle, not an admission claim.
                emitted = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"),
                    top_class="generator-design-movesets" if mutation == "required-member" else "generator-design-terrain",
                    preserve_names=True, not_closed=False).serialize())
                if mutation == "required-member":
                    assert_member_no_effect(self, member_baseline, emitted, movesets)
                    continue
                definition = emitted["$defs"]["generator-design-terrain"]
                if mutation == "bound":
                    broadened = {"$defs": emitted["$defs"], **definition["properties"]["zone-blocks"]}
                    jsonschema.validate(65, broadened)
                    print("BOUND mutant: SAME oracle rejects; native 65 broadens to admitted;",
                          json.dumps(definition["properties"]["zone-blocks"], sort_keys=True))
                else:
                    self.assertNotIn("zone-blocks", definition["properties"])
                    self.assertIn("zone-count", definition["properties"])
                    print("ALIAS mutant: SAME oracle rejects; native field becomes zone-count")

    def test_actual_yaml_map_and_tuple_mutations(self):
        declaration_oracle(self)
        owner = "generator-design-settlement-footprint"
        original = generated(owner)
        specimen = deepcopy(catalog("generators")["design"]["settlement"]["footprint"])
        specimen["inn"] = [8, 6, 7, 8]
        invalid = _walk(owner, specimen, False)
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.validate(invalid, original)
        cases = [
            ("rgb-map-attachment", "design-combat", "generator-design-feel-numbers", "colours", "range", "generator-design-feel-events"),
            ("status-map-range", "design-combat", "generator-status-entry", "key", "range", "string"),
            ("status-correlation", "design-combat", "generator-status-entry", None, None, None),
            ("footprint-cardinality", "design-items", "generator-footprint-entry", "value", "maximum_cardinality", None),
            ("pair-cardinality", "design-combat", "generator-design-movement-hitbox", "small", "maximum_cardinality", None),
            ("building-reference", "design-items", "generator-design-settlement", "buildings", "range", "string"),
        ]
        for mutation, module, component, field, facet, replacement in cases:
            with self.subTest(mutation=mutation), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                path = target / (module + ".yaml")
                data = yaml.safe_load(path.read_text())
                if mutation == "status-correlation":
                    rules = data["classes"][component]["rules"]
                    selected = [r for r in rules if r["preconditions"]["slot_conditions"]["key"]["equals_string"] == "poison"]
                    self.assertEqual(len(selected), 1)
                    removed = selected[0]
                    rules.remove(removed)
                    self.assertEqual(removed,
                        {"preconditions": {"slot_conditions": {"key": {"equals_string": "poison"}}},
                         "postconditions": {"slot_conditions": {"value": {
                             "range": "generator-design-status-effects-poison", "inlined": True, "required": True}}}})
                    print("M0removed original poison predicate:", removed, "remaining:",
                          [r["preconditions"]["slot_conditions"]["key"]["equals_string"] for r in rules])
                elif replacement is None:
                    data["classes"][component]["attributes"][field].pop(facet)
                else:
                    data["classes"][component]["attributes"][field][facet] = replacement
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                with self.assertRaises(AssertionError):
                    declaration_oracle(self, target)
                if mutation == "footprint-cardinality":
                    emitted = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"),
                        top_class=owner, preserve_names=True, not_closed=False).serialize())
                    jsonschema.validate(invalid, emitted)
                    print("FOOTPRINT cardinality mutant: SAME oracle rejects; four dimensions broaden to admitted")
                print("MAP/TUPLE mutant rejected by SAME oracle:", mutation)

    def test_actual_yaml_coupling_and_context_loss(self):
        declaration_oracle(self)
        cases = [
            ("settlement-minimum", "design-items", ("generator-design-settlement", "attributes", "radius", "minimum_value"), None),
            ("settlement-conjunctions", "design-items", ("generator-design", "attributes", "settlement", "all_of"), None),
            ("feel-maximum", "design-items", ("generator-design", "attributes", "feel", "equals_expression"), None),
            ("dodge-maximum", "design-items", ("generators-source", "attributes", "design", "equals_expression"), None),
            ("role-raw-key", "design-combat", ("generator-design-creature-roles", "attributes", "ranged", "equals_expression"),
             "ranged if ranged['range'] > ranged['keep_away'] else ''"),
            ("simulation-radius", "design-world", ("generator-design-spawns", "attributes", "ai", "equals_expression"), None),
        ]
        for label, module, parts, replacement in cases:
            with self.subTest(mutation=label), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                path = target / (module + ".yaml")
                before = path.read_text()
                data = yaml.safe_load(before)
                node = data["classes"]
                for key in parts[:-1]:
                    node = node[key]
                if replacement is None:
                    node.pop(parts[-1])
                else:
                    node[parts[-1]] = replacement
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                self.assertNotEqual(path.read_text(), before)
                with self.assertRaises(AssertionError):
                    declaration_oracle(self, target)
                print("COUPLING actual-YAML loss rejected by SAME baseline oracle:", label)

    def test_actual_yaml_selected_input_loss(self):
        declaration_oracle(self)
        cases = [
            ("arena-carrier", "design-world", ("classes", "generator-source-boss", "attributes", "arena-waves", "equals_expression"),
             "[['white','green'],['white','green'],['green','blue'],['blue','purple'],['purple','yellow']]"),
            ("loot-bound", "design-items", ("classes", "generator-design-loot", "attributes", "gear-chance", "minimum_value"), 0),
            ("rarity-correlation", "design-items", ("classes", "generator-design-loot-rarity-weights-entry", "rules", 0), None),
            ("shop-cap", "design-items", ("classes", "generator-design-settlement-shop", "attributes", "rarity-cap", "equals_string"), None),
            ("threat-coefficient", "design-world", ("classes", "generator-design-spawns-ai", "attributes", "threat-per-full-hp", "minimum_value"), 0),
            ("taunt-required", "design-combat", ("classes", "generator-ability-entry", "rules", 0, "postconditions", "slot_conditions",
              "value", "range_expression", "slot_conditions", "ability-runtime-taunt-s", "required"), None),
            ("known-status-correlation", "design-combat", ("classes", "generator-status-entry", "rules", "slow"), None),
            ("nested-shot-zero", "design-combat", ("slots", "runtime-projectile-damage-mult", "none_of"), None),
        ]
        for label, module, parts, replacement in cases:
            with self.subTest(mutation=label), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                path = target / (module + ".yaml")
                before = path.read_text()
                data = yaml.safe_load(before)
                node = data
                for key in parts[:-1]:
                    node = node[key]
                if label == "known-status-correlation":
                    selected = [r for r in node if r["preconditions"]["slot_conditions"]["key"]["equals_string"] == "slow"]
                    self.assertEqual(len(selected), 1)
                    node.remove(selected[0])
                    print("M2removed explicit slow predicate:", selected[0], "remaining:",
                          [r["preconditions"]["slot_conditions"]["key"]["equals_string"] for r in node])
                elif replacement is None:
                    node.pop(parts[-1])
                else:
                    node[parts[-1]] = replacement
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                self.assertNotEqual(path.read_text(), before)
                with self.assertRaises(AssertionError):
                    declaration_oracle(self, target)
                print("SELECTED input actual-YAML loss rejected by SAME baseline oracle:", label)

    def test_reviewed_facet_and_shared_event_losses(self):
        declaration_oracle(self)
        source = catalog("generators")["design"]
        cases = [("speed", "ability-runtime", dict(source["abilities"]["fire-missiles"], speed=0)),
                 ("life-s", "ability-runtime", dict(source["abilities"]["fire-missiles"], **{"life-s": 0})),
                 ("text", "generator-design-feel-level-up", dict(source["feel"]["level-up"], text="\n")),
                 ("event-range", "generator-design-feel-events", source["feel"]["events"])]
        for label, owner, fixture in cases:
            class_contract(owner)
            baseline = generated(owner)
            definition = baseline["$defs"][owner]
            valid = {"text": source["feel"]["level-up"], "event-range": source["feel"]["events"]}.get(
                label, source["abilities"]["fire-missiles"])
            jsonschema.Draft201909Validator(baseline).validate(valid)
            if label in ("speed", "life-s"):
                with self.assertRaises(jsonschema.ValidationError):
                    jsonschema.Draft201909Validator(baseline).validate(fixture)
            else:
                jsonschema.Draft201909Validator(baseline).validate(fixture)
            with self.subTest(mutation=label), tempfile.TemporaryDirectory() as scratch:
                target = Path(scratch) / "schema"
                shutil.copytree(SCHEMA.parent, target)
                path = target / "design-combat.yaml"
                before = path.read_text()
                data = yaml.safe_load(before)
                if label in ("speed", "life-s"):
                    rule = next(r for r in data["classes"]["ability-runtime"]["rules"]
                                if r["preconditions"]["slot_conditions"]["ability-runtime-runtime"]["equals_string"] == "projectile")
                    rule["postconditions"]["slot_conditions"]["ability-runtime-" + label].pop("none_of")
                elif label == "text":
                    data["classes"][owner]["attributes"]["text"]["pattern"] = "^.+$"
                else:
                    self.assertIn("generator-feel-sound", data["classes"])
                    data["classes"][owner]["attributes"]["hit"]["range"] = "generator-feel-sound"
                path.write_text(yaml.safe_dump(data, sort_keys=False))
                self.assertNotEqual(path.read_text(), before)
                with self.assertRaises(AssertionError):
                    declaration_oracle(self, target)
                emitted = json.loads(JsonSchemaGenerator(str(target / "pixlnd.yaml"), top_class=owner,
                    preserve_names=True, not_closed=False).serialize())
                from linkml_runtime.utils.schemaview import SchemaView

                assert_declared_root(owner, set(definition["properties"]), set(definition["required"]),
                                     schema=emitted, view=SchemaView(str(target / "pixlnd.yaml")))
                if label in ("speed", "life-s"):
                    jsonschema.Draft201909Validator(emitted).validate(fixture)
                else:
                    with self.assertRaises(jsonschema.ValidationError):
                        jsonschema.Draft201909Validator(emitted).validate(fixture)
                print("REVIEWED actual-YAML loss SAME-oracle rejected/native effect:", label,
                      "before", json.dumps(definition, sort_keys=True),
                      "after", json.dumps(emitted["$defs"][owner], sort_keys=True))


if __name__ == "__main__":
    unittest.main()
