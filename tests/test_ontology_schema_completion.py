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
        with test.subTest(source=source):
            for address in addresses:
                assert_element(test, view, modules, address)
            for selector in selectors:
                module = selector.split(".", 1)[0]
                test.assertIn(selector, test_selectors(module), source)


def branches(expression):
    return expression.any_of + expression.exactly_one_of + expression.all_of + expression.none_of


def assert_slot_expression(test, view, slot, known, enclosing=None):
    effective = slot.range or (enclosing.range if enclosing else None)
    if effective or branches(slot):
        assert_ranges(test, slot, known, effective)
    else:
        # A condition can constrain a union-typed slot without choosing a union arm.
        test.assertIsNotNone(enclosing)
        assert_ranges(test, enclosing, known)
    if slot.range_expression:
        owner = slot.range_expression.is_a or effective
        test.assertIn(owner, view.all_classes())
        assert_class_expression(test, view, slot.range_expression, owner, known)
    context = slot if slot.range or branches(slot) else enclosing
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
    for name, cls in classes.items():
        with test.subTest(owner=name):
            assert_class_ranges(test, view, cls, known)


def assert_class_ranges(test, view, cls, known):
    for target in ([cls.is_a] if cls.is_a else []) + cls.mixins + cls.union_of:
        test.assertIn(target, view.all_classes())
    induced = {slot.name: slot for slot in view.class_induced_slots(cls.name)}
    for attached in cls.slots:
        test.assertIn(attached, view.all_slots(attributes=False))
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


class SchemaCompletionContracts(unittest.TestCase):
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
