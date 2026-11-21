"""Basic world phase-2 roots and relations schema tests."""
import json
import shutil
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from ontology_source_contracts import assert_declared_root
from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import validator


def verify_world_relations_raw(self, facts, raw, unions):
    for name, domain, range_, required, multiple in facts:
        slot = raw['slots'][name]
        self.assertEqual((slot['domain'], slot['range']),
                         ('-or-'.join(domain.split()), '-or-'.join(range_.split())))
        self.assertEqual((bool(slot.get('required')), bool(slot.get('multivalued'))),
                         (required, multiple))
        self.assertEqual((slot.get('minimum_cardinality'), slot.get('maximum_cardinality'),
                          slot.get('exact_cardinality')), (1 if required and multiple else None, None, None))
        for endpoint in (domain, range_):
            if len(endpoint.split()) > 1:
                self.assertEqual(unions['-or-'.join(endpoint.split())]['union_of'], endpoint.split())


def verify_world_relations_view(self, facts, view):
    for name, domain, range_, required, multiple in facts:
        slot = view.get_slot(name)
        self.assertEqual((slot.domain, slot.range, bool(slot.required), bool(slot.multivalued),
                          slot.minimum_cardinality, slot.maximum_cardinality, slot.exact_cardinality),
                         ('-or-'.join(domain.split()), '-or-'.join(range_.split()), required, multiple,
                          1 if required and multiple else None, None, None))
        self.assertEqual(str(slot.slot_uri), 'pixlnd:' + name)
        self.assertIn('../domain/4_Relations.md', slot.see_also)
        for endpoint in (domain, range_):
            members = endpoint.split()
            for member in members:
                self.assertIn(member, view.all_classes())
            if len(members) > 1:
                self.assertEqual(view.get_class('-or-'.join(members)).union_of, members)


class BasicWorldP2Tests(unittest.TestCase):
    def _assert_basic_world_roots(self, path):
        from ontology_source_contracts import assert_declared_root

        raw = yaml.safe_load(path.with_name('world.yaml').read_text())
        # §3.1 climate, zone, settlement, realm. Requiredness is logical,
        # not a claim that optional native null equals historical source null.
        facts = {
            'climate': [('climate-temperature-c', 'temperature-c', 'float', True, False, False),
                        ('climate-humidity-pct', 'humidity-pct', 'float', True, False, False)],
            'zone': [('zone-size-blocks', 'size-blocks', 'integer', True, False, False),
                     ('zone-static-entities', 'static-entities', 'static-entity', True, True, True),
                     ('columns', 'columns', 'field', True, True, True),
                     ('spawns', 'spawns', 'creature-spawn', True, True, True),
                     ('chunk-items', 'chunk-items', 'dropped-item', True, True, True)],
            'settlement': [('settlement-districts', 'districts', 'district', True, True, False),
                           ('settlement-buildings', 'buildings', 'building', True, True, False),
                           ('settlement-petrified', 'petrified', 'boolean', False, False, False),
                           ('settlement-possessed', 'possessed', 'boolean', False, False, False),
                           ('style', 'style', 'settlement-style', False, False, False),
                           ('population-races', 'population-races', 'race', False, True, False),
                           ('population-animals', 'population-animals', 'creature', False, True, False),
                           ('count-per-land', 'count-per-land', 'integer', False, False, False)],
            'realm': [('realm-kind', 'kind', 'realm-kind', True, False, False),
                      ('realm-name', 'name', 'string', True, False, False),
                      ('realm-magic-or-technology', 'magic-or-technology', 'string', True, False, False),
                      ('realm-leader', 'leader', 'realm-leader', False, False, True),
                      ('realm-capital', 'capital', 'realm-capital', False, False, True)],
        }
        # Raw first: the SAME literals check a copied mutant before any emission.
        for owner, fields in facts.items():
            declaration = raw['classes'][owner]
            self.assertEqual(set(declaration.get('slots', [])) | set(declaration.get('attributes', {})),
                             {'id'} | {name for name, *_ in fields})
            for name, alias, range_, required, multiple, inline in fields:
                slot = declaration.get('attributes', {}).get(name, raw['slots'].get(name))
                self.assertIsNotNone(slot)
                self.assertEqual((slot['alias'], slot['range'], bool(slot.get('required')),
                                  bool(slot.get('multivalued')), bool(slot.get('inlined'))),
                                 (alias, range_, required, multiple, inline))
                self.assertEqual(bool(slot.get('inlined_as_list')), inline and multiple)
                if owner == 'climate':
                    self.assertIsNone(slot.get('minimum_value'))
                    self.assertIsNone(slot.get('maximum_value'))
            if owner == 'settlement':
                count = declaration['attributes']['count-per-land']
                self.assertEqual((count['minimum_value'], count['equals_number']), (1, 1))
        view = SchemaView(str(path))
        schemas = {}
        for owner, fields in facts.items():
            for name, alias, range_, required, multiple, inline in fields:
                slot = view.induced_slot(name, owner)
                self.assertEqual((slot.alias, slot.range, bool(slot.required), bool(slot.multivalued),
                                  bool(slot.inlined), bool(slot.inlined_as_list)),
                                 (alias, range_, required, multiple, inline, inline and multiple))
            properties = {'id'} | {alias for _, alias, *_ in fields}
            required = {'id'} | {alias for _, alias, _, needed, *_ in fields if needed}
            schema = (validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
                str(path), top_class=owner, preserve_names=True, not_closed=False).serialize()))
            assert_declared_root(owner, properties, required, schema=schema, view=view)
            schemas[owner] = schema
        self.assertEqual(set(view.get_enum('realm-kind').permissible_values),
                         {'kingdom', 'realm', 'cult', 'tribe'})
        return schemas

    def _assert_world_relations(self, path):
        # §4 rows 23–25,30–33,38–49,52,57–60. Global facts, NOT record fields.
        # Endpoint unions are literal source members; no generated expectations.
        facts = [
            ('yields', 'flora deposit creature', 'ingredient', True, True),
            ('spawns-in', 'creature flora deposit', 'landscape terrain-feature dungeon-type poi-type', False, True),
            ('placed-in', 'dungeon-type poi-type settlement', 'landscape', False, True),
            ('hosts', 'dungeon-type poi-type', 'mission-type', False, True),
            ('rewards', 'mission-type arena poi-type', 'item-type key-item artifact currency book-of-crafting', False, True),
            ('guards', 'creature', 'artifact key-item gnome-supplier magic-crystal', False, True),
            ('drops', 'creature', 'item spirit-cube leftovers currency', False, True),
            ('requires-key-item', 'poi-type dungeon-type ability', 'key-item', False, True),
            ('located-in', 'settlement dungeon poi', 'land', True, False),
            ('owned-by-realm', 'land', 'realm', True, False),
            ('reveals', 'realm', 'artifact', True, True),
            ('bound-to-land', 'item key-item leftovers', 'land', True, False),
            ('works-in-adjacent', 'item', 'land', False, True),
            ('raises-stock', 'gnome-supplier', 'shop', True, True),
            ('sells', 'shop', 'item-type pet-food formula key-item', False, True),
            ('offers-service', 'building', 'npc-role', True, True),
            ('contains-station', 'building', 'crafting-station', True, True),
            ('in-district', 'building', 'district', True, False),
            ('styled-by', 'settlement', 'landscape', True, False),
            ('has-hazard', 'landscape terrain-feature', 'status-effect', False, True),
            ('possesses', 'poi-type', 'npc-role creature', True, True),
            ('petrifies', 'creature', 'settlement', True, False),
            ('adjacent-to', 'land', 'land', False, True),
        ]
        raw = yaml.safe_load(path.with_name('relations.yaml').read_text())
        unions = yaml.safe_load(path.with_name('relation-types.yaml').read_text())['classes']
        verify_world_relations_raw(self, facts, raw, unions)
        view = SchemaView(str(path))
        verify_world_relations_view(self, facts, view)

    def test_basic_world_p2_roots_and_values(self):
        schemas = self._assert_basic_world_roots(SCHEMA)
        rows = {
            'climate': {'id': 'sample', 'temperature-c': 36.5, 'humidity-pct': 5.0},
            'zone': {'id': 'sample', 'size-blocks': 64, 'static-entities': [], 'columns': [], 'spawns': [], 'chunk-items': []},
            'settlement': {'id': 'sample', 'districts': ['trade'], 'buildings': ['inn'],
                           'petrified': False, 'possessed': True, 'count-per-land': 1},
            'realm': {'id': 'sample', 'kind': 'kingdom', 'name': 'Named realm', 'magic-or-technology': 'flavour'},
        }
        # Empty inline collections introduce no unguarded child-root admission.
        for owner, row in rows.items():
            native = jsonschema.Draft201909Validator(schemas[owner])
            native.validate(row)
            for field in schemas[owner]['$defs'][owner]['required']:
                with self.subTest(owner=owner, missing=field), self.assertRaises(jsonschema.ValidationError):
                    native.validate({key: value for key, value in row.items() if key != field})
            for bad in (None, True, 1, 'root', [], dict(row, unknown=True)):
                with self.subTest(owner=owner, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)
        for field in ('temperature-c', 'humidity-pct'):
            native = jsonschema.Draft201909Validator(schemas['climate'])
            # No inferred humidity/temperature bounds; readings differ from raw biome bands.
            for good in (-1000.5, 0, 1000.5):
                native.validate(dict(rows['climate'], **{field: good}))
            for bad in (None, True, '5', [], {}):
                with self.subTest(field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(dict(rows['climate'], **{field: bad}))
        for owner, field, bads in (
            ('zone', 'size-blocks', [True, '64', 1.5, None]),
            ('zone', 'columns', [True, {}, 'column']),
            ('zone', 'spawns', [True, {}, 'spawn']),
            ('zone', 'static-entities', [True, {}, 'object']),
            ('settlement', 'count-per-land', [0, 2, True, '1']),
            ('settlement', 'petrified', [0, 'false', [], {}]),
            ('settlement', 'possessed', [0, 'false', [], {}]),
            ('realm', 'kind', ['empire', 1, True, None]),
        ):
            native = jsonschema.Draft201909Validator(schemas[owner])
            for bad in bads:
                with self.subTest(owner=owner, field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(dict(rows[owner], **{field: bad}))

    def test_basic_world_p2_relation_contracts(self):
        self._assert_world_relations(SCHEMA)

    def test_basic_world_p2_root_mutations(self):
        self._assert_basic_world_roots(SCHEMA)
        cases = [
            (('slots', 'climate-temperature-c', 'range'), 'string'),
            (('slots', 'climate-humidity-pct', 'required'), False),
            (('classes', 'zone', 'attributes', 'columns', 'range'), 'block'),
            (('slots', 'zone-static-entities', 'multivalued'), False),
            (('classes', 'settlement', 'attributes', 'count-per-land', 'equals_number'), 2),
            (('slots', 'settlement-petrified', 'range'), 'integer'),
            (('slots', 'realm-kind', 'required'), False),
            (('slots', 'realm-leader', 'range'), 'realm-capital'),
        ]
        with tempfile.TemporaryDirectory(prefix='basic-world-p2-') as directory:
            target = Path(directory) / 'schema'
            shutil.copytree(SCHEMA.parent, target)
            original = yaml.safe_load((target / 'world.yaml').read_text())
            for keys, replacement in cases:
                mutant = deepcopy(original)
                cursor = mutant
                for key in keys[:-1]:
                    cursor = cursor[key]
                cursor[keys[-1]] = replacement
                (target / 'world.yaml').write_text(yaml.safe_dump(mutant, sort_keys=False))
                self.assertEqual(yaml.safe_load((target / 'world.yaml').read_text()), mutant)
                with self.subTest(keys=keys), self.assertRaises(AssertionError):
                    self._assert_basic_world_roots(target / SCHEMA.name)

    def test_landscape_fauna_logical_roster_contract(self):
        self._assert_landscape_fauna_contract(SCHEMA)
        mutations = [
            (('classes', 'landscape', 'slots'), ['id', 'landscape-flora', 'landscape-dungeons', 'landscape-pois', 'landscape-gen']),
            (('slots', 'landscape-fauna', 'range'), 'string'),
            (('slots', 'landscape-fauna', 'multivalued'), False),
        ]
        with tempfile.TemporaryDirectory(prefix='landscape-fauna-') as directory:
            target = Path(directory) / 'schema'
            for keys, replacement in mutations:
                shutil.copytree(SCHEMA.parent, target, dirs_exist_ok=True)
                path = target / 'world.yaml'
                mutant = yaml.safe_load(path.read_text())
                cursor = mutant
                for key in keys[:-1]:
                    cursor = cursor[key]
                cursor[keys[-1]] = replacement
                path.write_text(yaml.safe_dump(mutant, sort_keys=False))
                with self.subTest(keys=keys), self.assertRaises(AssertionError):
                    self._assert_landscape_fauna_contract(target / SCHEMA.name)
                shutil.rmtree(target)
        row = {'id': 'sample', 'flora': [], 'fauna': ['skeleton'], 'dungeons': [], 'pois': []}
        self.assertIsNone(jsonschema.Draft201909Validator(self._assert_landscape_fauna_contract(SCHEMA)).validate(row))
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.Draft201909Validator(self._assert_landscape_fauna_contract(SCHEMA)).validate(dict(row, fauna='skeleton'))

    def _assert_landscape_fauna_contract(self, path):
        raw = yaml.safe_load(path.with_name('world.yaml').read_text())
        declaration = raw['classes']['landscape']
        expected_slots = {'id', 'landscape-flora', 'landscape-fauna', 'landscape-dungeons', 'landscape-pois', 'landscape-gen'}
        self.assertEqual(set(declaration['slots']), expected_slots)
        fauna = raw['slots']['landscape-fauna']
        self.assertEqual((fauna['alias'], fauna['range'], bool(fauna.get('multivalued'))), ('fauna', 'creature', True))
        view = SchemaView(str(path))
        induced = view.induced_slot('landscape-fauna', 'landscape')
        self.assertEqual((induced.alias, induced.range, bool(induced.multivalued)), ('fauna', 'creature', True))
        schema = JsonSchemaGenerator(str(path), top_class='landscape', preserve_names=True, not_closed=False).serialize()
        return assert_declared_root('landscape', {'id', 'flora', 'fauna', 'dungeons', 'pois', 'gen'}, {'id'}, schema=json.loads(schema), view=view)

    def test_settlement_style_class_slot_contract(self):
        self._assert_settlement_style_contract(SCHEMA)
        mutations = [
            (('classes', 'settlement-style', 'slots'), ['id', 'settlement-style-lands']),
            (('slots', 'settlement-style-lands', 'range'), 'string'),
            (('slots', 'settlement-style-lands', 'required'), False),
            (('slots', 'settlement-style-lands', 'multivalued'), False),
            (('slots', 'settlement-style-desc', 'range'), 'landscape'),
        ]
        with tempfile.TemporaryDirectory(prefix='settlement-style-') as directory:
            target = Path(directory) / 'schema'
            for keys, replacement in mutations:
                shutil.copytree(SCHEMA.parent, target, dirs_exist_ok=True)
                path = target / 'catalog-properties.yaml'
                mutant = yaml.safe_load(path.read_text())
                cursor = mutant
                for key in keys[:-1]:
                    cursor = cursor[key]
                cursor[keys[-1]] = replacement
                path.write_text(yaml.safe_dump(mutant, sort_keys=False))
                with self.subTest(keys=keys), self.assertRaises(AssertionError):
                    self._assert_settlement_style_contract(target / SCHEMA.name)
                shutil.rmtree(target)
        row = {'id': 'style', 'lands': ['forest'], 'desc': 'Woodland'}
        schema = self._assert_settlement_style_contract(SCHEMA)
        native = jsonschema.Draft201909Validator(schema)
        native.validate(row)
        native.validate({'id': 'style', 'lands': ['forest']})
        for bad in ({'id': 'style', 'lands': 'forest'}, dict(row, desc=1)):
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(bad)

    def _assert_settlement_style_contract(self, path):
        raw = yaml.safe_load(path.with_name('catalog-properties.yaml').read_text())
        declaration = raw['classes']['settlement-style']
        expected_slots = {'id', 'settlement-style-lands', 'settlement-style-desc'}
        self.assertEqual(set(declaration['slots']), expected_slots)
        lands = raw['slots']['settlement-style-lands']
        desc = raw['slots']['settlement-style-desc']
        self.assertEqual((lands['alias'], lands['range'], bool(lands.get('required')), bool(lands.get('multivalued'))), ('lands', 'landscape', True, True))
        self.assertEqual((desc['alias'], desc['range'], bool(desc.get('required')), bool(desc.get('multivalued'))), ('desc', 'string', False, False))
        view = SchemaView(str(path))
        for name, expected in (('settlement-style-lands', ('lands', 'landscape', True, True)), ('settlement-style-desc', ('desc', 'string', False, False))):
            slot = view.induced_slot(name, 'settlement-style')
            self.assertEqual((slot.alias, slot.range, bool(slot.required), bool(slot.multivalued)), expected)
        schema = JsonSchemaGenerator(str(path), top_class='settlement-style', preserve_names=True, not_closed=False).serialize()
        return assert_declared_root('settlement-style', {'id', 'lands', 'desc'}, {'id', 'lands'}, schema=json.loads(schema), view=view)

    def test_world_root_generation_is_repeatable(self):
        expected = {
            'landscape': ({'id', 'flora', 'fauna', 'dungeons', 'pois', 'gen'}, {'id'}),
            'settlement-style': ({'id', 'lands', 'desc'}, {'id', 'lands'}),
            'settlement': ({'id', 'districts', 'buildings', 'petrified', 'possessed', 'style', 'population-races', 'population-animals', 'count-per-land'}, {'id', 'districts', 'buildings'}),
        }
        roots = []
        with tempfile.TemporaryDirectory(prefix='schema-generation-a-') as first, tempfile.TemporaryDirectory(prefix='schema-generation-b-') as second:
            for directory in (first, second):
                path = Path(directory) / 'schema'
                shutil.copytree(SCHEMA.parent, path)
                view = SchemaView(str(path / SCHEMA.name))
                schemas = {}
                for name, (properties, required) in expected.items():
                    serialized = JsonSchemaGenerator(str(path / SCHEMA.name), top_class=name, preserve_names=True, not_closed=False).serialize()
                    schema = json.loads(serialized)
                    schemas[name] = schema
                    assert_declared_root(name, properties, required, schema=schema, view=view)
                roots.append(schemas)
        self.assertEqual(roots[0], roots[1])

    def test_basic_world_p2_relation_mutations(self):
        self._assert_world_relations(SCHEMA)
        cases = [('owned-by-realm', 'range', 'settlement'),
                 ('located-in', 'required', False),
                 ('reveals', 'minimum_cardinality', 0),
                 ('contains-station', 'multivalued', False)]
        with tempfile.TemporaryDirectory(prefix='world-relations-p2-') as directory:
            target = Path(directory) / 'schema'
            shutil.copytree(SCHEMA.parent, target)
            original = yaml.safe_load((target / 'relations.yaml').read_text())
            for name, facet, replacement in cases:
                mutant = deepcopy(original)
                mutant['slots'][name][facet] = replacement
                (target / 'relations.yaml').write_text(yaml.safe_dump(mutant, sort_keys=False))
                self.assertEqual(yaml.safe_load((target / 'relations.yaml').read_text()), mutant)
                with self.subTest(name=name, facet=facet), self.assertRaises(AssertionError):
                    self._assert_world_relations(target / SCHEMA.name)


if __name__ == "__main__":
    unittest.main()
