"""Closeout references and SDK range closure, not another model or admission engine."""

import ast
import re
import unittest
from copy import deepcopy
from functools import lru_cache
from pathlib import Path

import yaml
from linkml_runtime.linkml_model.meta import ClassDefinition, SchemaDefinition
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import source_view
from test_ontology_schema import ROOT, assert_ranges

COVERAGE = ROOT / "docs/ontology/phase-1-coverage.md"
START = "<!-- task9-completion-map -->"
END = "<!-- /task9-completion-map -->"


def anchors(text):
    headings = re.findall(r"^#{1,6} (.+)$", text, re.M)
    return {re.sub(r"[^\w\s-]", "", h.lower()).replace(" ", "-") for h in headings} | set(
        re.findall(r'<a id="([^"]+)"></a>', text))


def source_obligations():
    obligations = {"instances/" + p.name for p in (ROOT / "ontology/instances").glob("*.json")}
    for name in ("3_Classes", "controls", "controller-profiles", "encounter-contracts"):
        path = "domain/" + name + ".md"
        obligations.update(path + "#" + anchor for anchor in anchors((ROOT / "ontology" / path).read_text()))
    for name, pattern in (("4_Relations", r"^\| (?:\[)?([a-z][a-z-]+)(?:\]| \|)"),
                          ("5_Constraints", r'^\| (?:<a id="[^"]+"></a>\s*)?(c-[a-z0-9-]+) \|'),
                          ("6_Generators", r"^\| (gen-[a-z-]+)")):
        path = "domain/" + name + ".md"
        text = (ROOT / "ontology" / path).read_text()
        obligations.update(path + "@" + key for key in re.findall(pattern, text, re.M) if key != "id")
    path = "domain/5_Constraints.md"
    text = (ROOT / "ontology" / path).read_text()
    inventory = text.split("**Required paths and shapes.**", 1)[1].split("**Permitted source inheritance.**", 1)[0]
    obligations.update(path + "@input:" + key.strip() for key in re.findall(r"^\| ([^|]+) \|", inventory, re.M)
                       if key.strip() != "dependency")
    return obligations


def completion_rows(text):
    assert text.count(START) == text.count(END) == 1, "Missing or duplicate completion map"
    table = text.split(START, 1)[1].split(END, 1)[0].strip().splitlines()
    assert table[:2] == ["| Source obligation | YAML elements | Tests | Classification / retained prose |",
                         "|---|---|---|---|"], "Unexpected completion map format"
    rows = {}
    for line in table[2:]:
        assert line.startswith("| ") and line.endswith(" |"), line
        cells = [cell.strip() for cell in line[1:-1].split("|")]
        assert len(cells) == 4, line
        sources, elements, tests, classification = cells
        kinds, prose = classification.split(":", 1)
        assert set(kinds.split(",")) <= {"1", "2", "3"} and prose.strip(), classification
        assert elements != "-" or kinds == "3", "Convertible mapping has no YAML elements: " + sources
        addresses = [] if elements == "-" else elements.split("; ")
        selectors = tests.split("; ")
        assert selectors and all(selectors), sources
        for source in sources.split("; "):
            assert source.startswith("`") and source.endswith("`"), source
            source = source[1:-1]
            assert source not in rows, "Duplicate source obligation: " + source
            rows[source] = (addresses, selectors)
    assert rows, "Empty completion map"
    return rows


@lru_cache(maxsize=None)
def test_selectors(module):
    path = ROOT / "tests" / (module + ".py")
    assert path.is_file(), "Missing test module: " + module
    tree = ast.parse(path.read_text(), filename=str(path))
    return {module + "." + cls.name + "." + method.name
            for cls in tree.body if isinstance(cls, ast.ClassDef)
            for method in cls.body if isinstance(method, ast.FunctionDef) and method.name.startswith("test_")}


def assert_element(test, view, modules, address):
    match = re.fullmatch(r"([a-z0-9-]+\.yaml):(class|slot|attribute|induced|refinement|rule|enum|type):([\w.-]+)", address)
    test.assertIsNotNone(match, address)
    module, kind, name = match.groups()
    test.assertIn(module, modules, address)
    schema = modules[module]
    if kind in ("class", "enum", "type"):
        declarations = getattr(schema, {"class": "classes", "enum": "enums", "type": "types"}[kind])
        test.assertIn(name, declarations, address)
    elif kind == "slot":
        test.assertIn(name, schema.slots, address)
    elif kind == "rule":
        test.assertIn(name, schema.classes, address)
        test.assertTrue(schema.classes[name].rules, address)
    else:
        owner, slot = name.split(".", 1)
        test.assertIn(owner, schema.classes, address)
        cls = schema.classes[owner]
        if kind == "attribute":
            test.assertIn(slot, cls.attributes, address)
        elif kind == "refinement":
            test.assertIn(slot, cls.slot_usage, address)
        test.assertIn(slot, view.class_slots(owner), address)
        test.assertEqual(view.induced_slot(slot, owner).name, slot, address)


def assert_mapping(test, rows, obligations, view):
    test.assertEqual(set(rows), obligations, "Source obligations and completion map differ")
    modules = {Path(s.source_file).name: s for s in view.all_schema() if s.source_file}
    for source, (addresses, selectors) in rows.items():
        for address in addresses:
            assert_element(test, view, modules, address)
        for selector in selectors:
            module = selector.split(".", 1)[0]
            test.assertIn(selector, test_selectors(module), source)


def branches(expression):
    return expression.any_of + expression.exactly_one_of + expression.all_of + expression.none_of


def assert_slot_expression(test, view, slot, known, enclosing=None):
    effective = slot.range or (enclosing.range if enclosing else None)
    if effective or enclosing is None:
        assert_ranges(test, slot, known, effective)
    else:
        # A condition can constrain a union-typed slot without choosing a union arm.
        test.assertIsNotNone(enclosing)
        assert_ranges(test, enclosing, known)
    if slot.range_expression:
        owner = slot.range_expression.is_a or effective
        test.assertIn(owner, view.all_classes())
        assert_class_expression(test, view, slot.range_expression, owner, known)
    context = slot if slot.range or enclosing is None else enclosing
    for member in (slot.has_member, slot.all_members):
        if member:
            assert_slot_expression(test, view, member, known, context)
    for branch in branches(slot):
        assert_slot_expression(test, view, branch, known, context)


def assert_class_expression(test, view, expression, owner, known):
    if expression.is_a:
        test.assertIn(expression.is_a, view.all_classes())
        # Named classes keep their owner; anonymous is_a narrows the target.
        if not isinstance(expression, ClassDefinition):
            owner = expression.is_a
    slots = view.class_induced_slots(owner)
    by_name = {slot.name: slot for slot in slots}
    by_name.update({slot.alias: slot for slot in slots if slot.alias})
    for name, condition in expression.slot_conditions.items():
        test.assertIn(name, by_name, (owner, name))
        assert_slot_expression(test, view, condition, known, by_name[name])
    for branch in branches(expression):
        assert_class_expression(test, view, branch, owner, known)


def assert_range_closure(test, view):
    classes = view.all_classes()
    known = classes | view.all_types() | view.all_enums()
    for slot in view.all_slots(attributes=False).values():
        assert_slot_expression(test, view, slot, known)
        if slot.domain:
            test.assertIn(slot.domain, classes)
    for cls in classes.values():
        assert_class_ranges(test, view, cls, known)


def assert_class_ranges(test, view, cls, known):
    for target in ([cls.is_a] if cls.is_a else []) + cls.mixins + cls.union_of:
        test.assertIn(target, view.all_classes())
    induced = {slot.name: slot for slot in view.class_induced_slots(cls.name)}
    declared = set(view.all_slots(attributes=False))
    for ancestor in view.class_ancestors(cls.name):
        declared.update(view.get_class(ancestor).attributes)
    for attached in cls.slots:
        test.assertIn(attached, declared, (cls.name, attached))
    for slot in induced.values():
        assert_slot_expression(test, view, slot, known)
    for slot in list(cls.attributes.values()) + list(cls.slot_usage.values()):
        test.assertIn(slot.name, induced)
        assert_slot_expression(test, view, slot, known, induced[slot.name])
    if cls.extra_slots and cls.extra_slots.range_expression:
        assert_slot_expression(test, view, cls.extra_slots.range_expression, known)
    assert_class_expression(test, view, cls, cls.name, known)
    for rule in cls.rules:
        for expression in (rule.preconditions, rule.postconditions, rule.elseconditions):
            if expression:
                assert_class_expression(test, view, expression, cls.name, known)


def predicate_schema(operator, union=False):
    value = {"any_of": [{"range": "number"}, {"range": "text"}]} if union else {"range": "number"}
    return SchemaDefinition(
        id="https://example.org/predicates", name="predicates",
        types={"number": {"base": "float", "uri": "xsd:double"}, "text": {"base": "str", "uri": "xsd:string"}},
        classes={"owner": {"attributes": {"value": value}, "rules": [{"postconditions": {
            "slot_conditions": {"value": {operator: [{"none_of": [{"equals_number": 0}]}]}}}}]}})


class SchemaCompletionContracts(unittest.TestCase):
    def test_boolean_predicates_preserve_scalar_and_union_context(self):
        for union in (False, True):
            for operator in ("any_of", "exactly_one_of", "all_of", "none_of"):
                schema = predicate_schema(operator, union)
                with self.subTest(union=union, operator=operator):
                    assert_range_closure(self, SchemaView(schema))
                    bad = deepcopy(schema)
                    condition = bad.classes["owner"].rules[0].postconditions.slot_conditions["value"]
                    getattr(condition, operator)[0].none_of[0].range = "missing"
                    with self.assertRaises(AssertionError):
                        assert_range_closure(self, SchemaView(bad))
        for value in ({}, {"any_of": [{"range": "number"}, {}]}):
            schema = SchemaDefinition(id="https://example.org/untyped", name="untyped",
                                      slots={"value": value}, types={"number": {"base": "float", "uri": "xsd:double"}})
            with self.subTest(untyped=value), self.assertRaises(AssertionError):
                assert_range_closure(self, SchemaView(schema))

    def test_member_range_expressions_preserve_predicate_context(self):
        for member in ("has_member", "all_members"):
            schema = SchemaDefinition(
                id="https://example.org/members", name="members",
                types={"number": {"base": "float", "uri": "xsd:double"}},
                classes={"row": {"attributes": {"value": {"range": "number"}}},
                         "owner": {"attributes": {"rows": {"range": "row", "multivalued": True}},
                                   "rules": [{"postconditions": {"slot_conditions": {"rows": {
                                       member: {"range_expression": {"slot_conditions": {"value": {
                                           "none_of": [{"equals_number": 0}]}}}}}}}}]}})
            with self.subTest(member=member):
                assert_range_closure(self, SchemaView(schema))
                bad = deepcopy(schema)
                condition = bad.classes["owner"].rules[0].postconditions.slot_conditions["rows"]
                getattr(condition, member).range_expression.slot_conditions["value"].none_of[0].range = "missing"
                with self.assertRaises(AssertionError):
                    assert_range_closure(self, SchemaView(bad))

    def test_attachments_require_an_applicable_declaration(self):
        attribute = {"value": {"range": "text"}}
        positives = [
            {"owner": {"attributes": attribute}},
            {"owner": {"slots": ["value"], "attributes": attribute}},
            {"parent": {"attributes": attribute}, "owner": {"is_a": "parent", "slots": ["value"]}},
            {"parent": {"mixin": True, "attributes": attribute}, "owner": {"mixins": ["parent"], "slots": ["value"]}},
        ]
        negatives = [
            {"owner": {"slots": ["value"]}},
            {"owner": {"slots": ["value"]}, "other": {"attributes": attribute}},
            {"owner": {"slots": ["value"], "slot_usage": attribute}},
        ]
        for classes in positives:
            with self.subTest(positive=classes):
                schema = SchemaDefinition(id="https://example.org/attachments", name="attachments", classes=deepcopy(classes),
                                          types={"text": {"base": "str", "uri": "xsd:string"}})
                assert_range_closure(self, SchemaView(schema))
        for classes in negatives:
            with self.subTest(negative=classes), self.assertRaises((AssertionError, ValueError)):
                schema = SchemaDefinition(id="https://example.org/attachments", name="attachments", classes=deepcopy(classes),
                                          types={"text": {"base": "str", "uri": "xsd:string"}})
                assert_range_closure(self, SchemaView(schema))
        schema = SchemaDefinition(id="https://example.org/domain", name="domain",
                                  types={"text": {"base": "str", "uri": "xsd:string"}},
                                  slots={"value": {"range": "text", "domain": "missing"}})
        with self.assertRaises(AssertionError):
            assert_range_closure(self, SchemaView(schema))

    def test_actual_predicates_and_artifact_declarations_remain_typed(self):
        view = source_view()
        restore = view.induced_slot("saved-rubble-restore-at", "saved-rubble")
        self.assertEqual((restore.range, restore.minimum_value), ("double", 0))
        condition = view.get_class("saved-rubble").rules[0].postconditions.any_of[1].slot_conditions["saved-rubble-restore-at"]
        self.assertEqual((condition.minimum_value, condition.none_of[0].equals_number), (0, 0))
        self.assertEqual(view.induced_slot("item-upgrade-material", "item-upgrade").range, "material")
        for branch, material in zip(view.get_class("item").all_of[1:], ("wood", "iron"), strict=True):
            condition = branch.any_of[0].slot_conditions["item-upgrades"].all_members.range_expression.slot_conditions["item-upgrade-material"]
            self.assertEqual(condition.none_of[0].equals_string, material)
        artifact = view.get_class("artifact")
        self.assertIn("traversal-kind", artifact.slots)
        selector = artifact.attributes["traversal-kind"]
        self.assertEqual((selector.range, selector.slot_uri, selector.required),
                         ("ArtifactTraversalKind", "pixlnd:artifact/traversal-kind", True))
        self.assertEqual(set(view.get_enum("ArtifactTraversalKind").permissible_values),
                         {"climb_speed", "swim_speed", "diving_skill", "ride_speed", "glide_speed", "sail_speed", "light_radius"})

    def test_runtime_cost_declaring_root_imports_exact_enum_owner(self):
        path = ROOT / "ontology/schema/design-combat-runtime-cost-strike.yaml"
        raw = yaml.safe_load(path.read_text())
        self.assertIn("associations-crafting-costs", raw["imports"])
        view = SchemaView(str(path))
        for resource in ("mp", "stamina"):
            slot = view.induced_slot("runtime-cost-" + resource, "runtime-cost")
            self.assertEqual([arm.range for arm in slot.any_of], ["double", "all-resource"])
            self.assertEqual(slot.any_of[0].minimum_value, 0)
        self.assertEqual(view.induced_slot("runtime-cost-mp", "runtime-cost").any_of[0].maximum_value, 100)
        enum = view.get_enum("all-resource")
        self.assertEqual((enum.from_schema, enum.enum_uri, set(enum.permissible_values)),
                         ("https://w3id.org/pixlnd/associations/crafting-costs", "pixlnd:all-resource", {"all"}))
        assert_range_closure(self, view)

    def test_alpha_block_declaring_root_imports_exact_reference_owner(self):
        path = ROOT / "ontology/schema/structured-world-block-sources.yaml"
        raw = yaml.safe_load(path.read_text())
        self.assertIn("world-catalog-block-terrain", raw["imports"])
        view = SchemaView(str(path))
        slot = view.induced_slot("id", "alpha-block-source-row")
        self.assertEqual((slot.range, slot.alias, slot.required), ("block-type", "id", True))
        block = view.get_class("block-type")
        self.assertEqual((block.from_schema, block.class_uri),
                         ("https://w3id.org/pixlnd/world-catalog/block-terrain", "pixlnd:block-type"))
        self.assertEqual(view.induced_slot("id", "block-type").range, "string")
        self.assertEqual(view.get_class("alpha-block-source-entry").attributes["key"].pattern, "^[0-9]+$")
        assert_range_closure(self, view)

    def test_pet_cage_target_condition_preserves_item_reference(self):
        raw = yaml.safe_load((ROOT / "ontology/schema/entities-pet.yaml").read_text())
        schema = SchemaDefinition(**raw)  # Declaring module only; no imported graph or induction.
        self.assertEqual(set(schema.classes), {"pet"})
        self.assertIn("pet-cage", raw["classes"]["pet"]["slots"])
        self.assertIn("pet-cage", schema.classes["pet"].slots)
        self.assertNotIn("pet-cage", schema.classes["pet"].slot_usage)
        declared = raw["slots"]["pet-cage"]
        cage = schema.slots["pet-cage"]
        self.assertEqual(declared.get("range_expression"), {
            "slot_conditions": {"item-type": {"alias": "type", "equals_string": "pet"}}})
        self.assertEqual(set(cage.range_expression.slot_conditions), {"item-type"})
        condition = cage.range_expression.slot_conditions["item-type"]
        self.assertEqual((condition.name, condition.alias, condition.equals_string), ("item-type", "type", "pet"))
        self.assertEqual(cage.name, "pet-cage")
        for key, value in {"range": "item", "alias": "cage", "required": True,
                           "slot_uri": "pixlnd:pet/cage", "see_also": ["../domain/3_Classes.md#pet"]}.items():
            self.assertEqual(declared[key], value)
            self.assertEqual(getattr(cage, key), value)
        for key in ("inlined", "inlined_as_list", "multivalued"):
            self.assertNotIn(key, declared)
            self.assertIsNone(getattr(cage, key))

    def test_every_mapped_class_slot_and_enum_resolves(self):
        rows = completion_rows(COVERAGE.read_text())
        assert_mapping(self, rows, source_obligations(), source_view())

    def test_imported_range_closure(self):
        assert_range_closure(self, source_view())

    def test_mapping_rejects_missing_obligations_and_elements(self):
        schema = SchemaDefinition(id="https://example.org/probe", name="probe", source_file="probe.yaml",
                                  classes={"owner": {"attributes": {"field": {"range": "owner"}}}},
                                  slots={"detached": {"range": "owner"}}, enums={"Choice": {"permissible_values": {"one": {}}}})
        view = SchemaView(schema)
        selector = "test_ontology_schema_completion.SchemaCompletionContracts.test_imported_range_closure"
        rows = {"source": (["probe.yaml:class:owner", "probe.yaml:attribute:owner.field",
                            "probe.yaml:enum:Choice"], [selector])}
        assert_mapping(self, rows, {"source"}, view)
        for address in ("probe.yaml:class:missing", "probe.yaml:slot:Choice",
                        "probe.yaml:enum:owner", "probe.yaml:attribute:owner.missing",
                        "probe.yaml:induced:owner.detached", "absent.yaml:class:owner", "generic file link"):
            bad = {"source": ([address], [selector])}
            with self.subTest(address=address), self.assertRaises(AssertionError):
                assert_mapping(self, bad, {"source"}, view)
        with self.assertRaises(AssertionError):
            assert_mapping(self, rows, {"source", "omitted"}, view)
        table = START + "\n| Source obligation | YAML elements | Tests | Classification / retained prose |\n|---|---|---|---|\n| `source` | - | test | 1: retained prose |\n" + END
        with self.assertRaisesRegex(AssertionError, "Convertible mapping"):
            completion_rows(table)

    def test_range_closure_rejects_unknown_nested_ranges(self):
        baseline = SchemaDefinition(
            id="https://example.org/ranges", name="ranges",
            types={"text": {"base": "str", "uri": "xsd:string"}},
            slots={"shared": {"range": "text"}},
            classes={"parent": {"slots": ["shared"]},
                     "owner": {"is_a": "parent", "slot_conditions": {"value": {"range": "text"}},
                               "attributes": {"value": {"range": "text", "any_of": [{"range": "text"}, {"range": "text"}]}},
                               "extra_slots": {"range_expression": {"range": "text"}},
                               "rules": [{"preconditions": {"slot_conditions": {"value": {"equals_string": "x"}}},
                                          "postconditions": {"slot_conditions": {"value": {"range": "text"}}},
                                          "elseconditions": {"slot_conditions": {"shared": {"range": "text"}}}}]}})
        assert_range_closure(self, SchemaView(baseline))
        union = deepcopy(baseline.classes["owner"].attributes["value"])
        union.range = None
        condition = baseline.classes["owner"].rules[0].preconditions.slot_conditions["value"]
        assert_slot_expression(self, SchemaView(baseline), condition, {"text"}, union)
        for location in ("global", "attribute", "branch", "dynamic", "rule", "else", "class-expression", "direct-class"):
            bad = deepcopy(baseline)
            owner = bad.classes["owner"]
            if location == "global":
                bad.slots["shared"].range = "missing"
            elif location == "attribute":
                owner.attributes["value"].range = "missing"
            elif location == "branch":
                owner.attributes["value"].any_of[1].range = "missing"
            elif location == "dynamic":
                owner.extra_slots.range_expression.range = "missing"
            elif location == "rule":
                owner.rules[0].postconditions.slot_conditions["value"].range = "missing"
            elif location == "else":
                owner.rules[0].elseconditions.slot_conditions["shared"].range = "missing"
            elif location == "direct-class":
                owner.slot_conditions["value"].range = "missing"
            else:
                owner.rules[0].preconditions.is_a = "missing"
            with self.subTest(location=location), self.assertRaises((AssertionError, ValueError)):
                assert_range_closure(self, SchemaView(bad))


if __name__ == "__main__":
    unittest.main()
