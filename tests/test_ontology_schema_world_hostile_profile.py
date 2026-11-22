"""Initial site hostile profile world schema tests."""
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
from test_ontology_schema import SCHEMA, load_module
from test_ontology_schema_authoring import catalog


def verify_hostile_profile_slots(self, expected, cls, view, owner):
    for field, facets in expected['attributes'].items():
        for kind, slot in [('attribute', cls.attributes[field]),
                           ('lookup', view.get_slot(field, strict=True)),
                           ('induced', view.induced_slot(field, owner))]:
            with self.subTest(field=field, kind=kind):
                for facet in ('alias', 'slot_uri', 'range', 'required', 'description', 'inlined',
                              'equals_string', 'minimum_value', 'maximum_value'):
                    self.assertEqual(getattr(slot, facet), facets.get(facet))
                self.assertEqual(list(slot.see_also), facets['see_also'])
                self.assertIsNone(slot.domain)  # Contextual ownership is not explicit domain.
                self.assertEqual(slot.owner, None if kind == 'attribute' else owner)
                self.assertIn(owner, slot.domain_of)
                self.assertFalse(slot.multivalued or slot.identifier or slot.key or slot.inlined_as_list)
                self.assertIsNone(slot.ifabsent)
                self.assertIsNone(slot.minimum_cardinality)
                self.assertIsNone(slot.maximum_cardinality)


def verify_hostile_profile_emitted(self, expected, schema, owner):
    for field, facets in expected['attributes'].items():
        emitted = schema['$defs'][owner]['properties'][field]
        self.assertEqual(emitted['description'], facets['description'])
        self.assertNotIn('default', emitted)
        if field == 'hostile-species':
            self.assertEqual((emitted['type'], emitted['const']), ('string', 'skeleton'))
        else:
            self.assertEqual((emitted['type'], emitted['minimum'], emitted['maximum']),
                             ('number', facets['minimum_value'], facets['maximum_value']))


def hostile_profile_mutations(owner, root):
    mutations = []
    for facet, value in [('class', None), ('class_uri', 'pixlnd:wrong'), ('see_also', []),
                         ('description', 'changed'), ('is_a', 'poi'), ('mixins', ['poi']), ('slots', ['id'])]:
        mutations.append((facet, root if facet == 'class' else root + (facet,), value))
    for field in ('hostile-species', 'melee-probability', 'ranged-probability', 'mage-probability'):
        keys = root + ('attributes', field)
        mutations.append((field + '-removed', keys, None))
        for facet, value in [('alias', 'wrong'), ('slot_uri', 'pixlnd:wrong'), ('range', 'string'),
                             ('required', False), ('multivalued', True), ('see_also', []),
                             ('description', 'changed'), ('domain', owner), ('identifier', True),
                             ('key', True), ('ifabsent', 'string(wrong)'), ('inlined_as_list', True),
                             ('minimum_cardinality', 1), ('maximum_cardinality', 2)]:
            mutations.append((field + '-' + facet, keys + (facet,), value))
        if field == 'hostile-species':
            for facet, value in [('inlined', True), ('equals_string', 'skeletons')]:
                mutations.append((field + '-' + facet, keys + (facet,), value))
        else:
            for facet, value in [('minimum_value', 0), ('maximum_value', 1)]:
                mutations.append((field + '-' + facet, keys + (facet,), value))
    return mutations


def verify_hostile_profile_mutation(self, label, keys, value, baseline, module, original, path):
    changed = deepcopy(baseline)
    cursor = changed
    for key in keys[:-1]:
        cursor = cursor[key]
    if value is None:
        del cursor[keys[-1]]
    else:
        cursor[keys[-1]] = value
    try:
        module.write_text(yaml.safe_dump(changed, sort_keys=False))
        self.assertEqual(yaml.safe_load(module.read_text()), changed)
        with self.subTest(mutation=label), self.assertRaises(AssertionError):
            self._assert_initial_site_hostile_profile(path)
        print('hostile mutation detected:', label)
    finally:
        module.write_bytes(original)
    self.assertEqual(module.read_bytes(), original)


def verify_hostile_profile_broadened(self, owner, baseline, module, original, path, schema):
    from ontology_source_contracts import assert_declared_root

    changed = deepcopy(baseline)
    changed['classes'][owner]['attributes']['melee-probability']['minimum_value'] = 0.4
    try:
        module.write_text(yaml.safe_dump(changed, sort_keys=False))
        self.assertEqual(yaml.safe_load(module.read_text()), changed)
        with self.assertRaises(AssertionError):
            self._assert_initial_site_hostile_profile(path)
        view = SchemaView(str(path))
        emitted = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                                                preserve_names=True, not_closed=False).serialize())
        fields = {'hostile-species', 'melee-probability', 'ranged-probability', 'mage-probability'}
        assert_declared_root(owner, fields, fields, schema=emitted, view=view)
        if '$ref' not in emitted:
            self.assertEqual(emitted['type'], 'object')
        self.assertEqual(emitted['$defs'][owner]['properties']['melee-probability']['minimum'], 0.4)
        positive = {'hostile-species': 'skeleton', 'melee-probability': 0.5,
                    'ranged-probability': 0.3, 'mage-probability': 0.2}
        witness = dict(positive, **{'melee-probability': 0.45})
        native = jsonschema.Draft201909Validator(emitted)
        baseline_native = jsonschema.Draft201909Validator(schema)
        self.assertEqual([e.validator for e in baseline_native.iter_errors(witness)], ['minimum'])
        self.assertTrue(native.is_valid(witness))
        self.assertTrue(baseline_native.is_valid(positive))
        self.assertTrue(native.is_valid(positive))
    finally:
        module.write_bytes(original)
    self.assertEqual(module.read_bytes(), original)


class LogicalWorldTests(unittest.TestCase):
    def _assert_initial_site_hostile_profile(self, path):
        from ontology_source_contracts import assert_declared_root

        owner = 'initial-site-hostile-profile'
        anchor = '../domain/encounter-contracts.md#populations-tiers-and-clear-conditions'
        source = '../instances/generators.json#design.initial-encounters'
        expected = {
            'class_uri': 'pixlnd:' + owner,
            'description': 'Fixed logical parameters for the designated initial-site hostiles: existing skeleton species and the basic-role choice probabilities. Friendly captives remain separate and ambient rosters are unchanged. Each pack and singleton boss makes its independent once-only role choice, retained across unload, restart and daily renewal, under the linked encounter rule. This is not a generated entity identity or assignment record.',
            'see_also': [anchor, source],
            'attributes': {
                'hostile-species': {
                    'alias': 'hostile-species', 'slot_uri': 'pixlnd:' + owner + '/hostile-species',
                    'range': 'creature', 'required': True, 'inlined': False, 'equals_string': 'skeleton',
                    'description': 'Existing creature species for the designated initial hostiles, not a family, generated entity identity, captive or ambient roster extension.',
                    'see_also': [anchor, source + '.species', '../instances/creatures.json#skeleton'],
                },
            },
        }
        for role, value in [('melee', 0.5), ('ranged', 0.3), ('mage', 0.2)]:
            field = role + '-probability'
            expected['attributes'][field] = {
                'alias': field, 'slot_uri': 'pixlnd:' + owner + '/' + field,
                'range': 'double', 'required': True, 'minimum_value': value, 'maximum_value': value,
                'description': 'Dimensionless independent probability for choosing the existing ' + role + ' role once per pack or singleton boss, not a per-hostile roll or relative loot weight.',
                'see_also': [anchor, source + '.role-weights'],
            }
        raw = load_module(path.parent / 'world.yaml')
        self.assertTrue(owner in raw.get('classes', {}), 'missing raw world declaration: ' + owner)
        # ALL raw metadata, attachments and fields precede SDK induction/generation.
        self.assertEqual(raw['classes'][owner], expected)
        fields = {'hostile-species', 'melee-probability', 'ranged-probability', 'mage-probability'}
        self.assertTrue(fields.isdisjoint(raw.get('slots', {})))
        view = SchemaView(str(path))
        self.assertIn(owner, view.all_classes())
        cls = view.get_class(owner)
        self.assertEqual(str(cls.class_uri), 'pixlnd:' + owner)
        self.assertEqual(cls.description, expected['description'])
        self.assertEqual(list(cls.see_also), [anchor, source])
        self.assertEqual(set(cls.attributes), fields)
        self.assertFalse(cls.slots or cls.is_a or cls.mixins)
        verify_hostile_profile_slots(self, expected, cls, view, owner)
        self.assertEqual(str(view.get_class('creature').class_uri), 'pixlnd:creature')
        creature_id = view.induced_slot('id', 'creature')
        self.assertTrue(creature_id.identifier)
        self.assertEqual(creature_id.range, 'string')
        schema = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                                               preserve_names=True, not_closed=False).serialize())
        assert_declared_root(owner, fields, fields, schema=schema, view=view)
        if '$ref' not in schema:
            self.assertEqual(schema['type'], 'object')
        verify_hostile_profile_emitted(self, expected, schema, owner)
        return view, schema

    def test_initial_site_hostile_profile_contracts(self):
        _, schema = self._assert_initial_site_hostile_profile(SCHEMA)
        config = catalog('generators')['design']['initial-encounters']
        self.assertEqual(config['species'], 'skeleton')
        self.assertEqual(config['role-weights'], {'melee': 0.5, 'ranged': 0.3, 'mage': 0.2})
        self.assertEqual(catalog('creatures')['skeleton']['family'], 'skeletons')
        positive = {'hostile-species': 'skeleton', 'mage-probability': 0.2,
                    'melee-probability': 0.5, 'ranged-probability': 0.3}
        cases = [('positive-full-profile', positive, True)]
        for field in sorted(positive):
            cases.append(('missing-' + field, {k: v for k, v in positive.items() if k != field}, False))
        species = [('actual-family-skeletons', 'skeletons'),
                   ('known-species-skeleton-knight', 'skeleton-knight'),
                   ('known-species-skeleton-horse', 'skeleton-horse'),
                   ('known-species-skeleton-dog', 'skeleton-dog'),
                   ('known-species-monstrosity', 'monstrosity'),
                   ('known-alternative-collie', 'collie')]
        for label, value in species:
            if label.startswith('known-'):
                self.assertIn(value, catalog('creatures'))
            cases.append(('wrong-species-' + label, dict(positive, **{'hostile-species': value}), False))
        for label, value in [('null', None), ('boolean', True), ('integer', 1), ('array', []), ('object', {})]:
            cases.append(('wrong-species-shape-' + label, dict(positive, **{'hostile-species': value}), False))
        for field, value in [('melee-probability', 0.5), ('ranged-probability', 0.3), ('mage-probability', 0.2)]:
            for label, bad in [('lower-finite', value - 0.01), ('upper-finite', value + 0.01),
                               ('null', None), ('boolean', True), ('integer', 1),
                               ('string', '0.5'), ('array', []), ('object', {})]:
                cases.append(('wrong-' + field + '-' + label, dict(positive, **{field: bad}), False))
        for label, value in [('null', None), ('array', []), ('string', 'root'), ('number', 1)]:
            cases.append(('wrong-root-shape-' + label, value, False))
        cases.append(('unknown-root-field', dict(positive, **{'unselected-field': 1}), False))
        self.assertEqual((len(cases), len({c[0] for c in cases})), (45, 45))
        native = jsonschema.Draft201909Validator(schema)
        for label, payload, expected in cases:
            with self.subTest(case=label):
                before = deepcopy(payload)
                errors = list(native.iter_errors(payload))
                self.assertEqual(not errors, expected)
                self.assertEqual(payload, before)
                if label == 'unknown-root-field':
                    self.assertEqual([e.validator for e in errors], ['additionalProperties'])
                print('hostile corpus:', label, 'admitted=' + str(not errors))
        print('hostile native: 45 cases, 1 admission, 44 rejections')

    def test_initial_site_hostile_profile_mutations(self):
        self._assert_initial_site_hostile_profile(SCHEMA)
        owner = 'initial-site-hostile-profile'
        root = ('classes', owner)
        mutations = hostile_profile_mutations(owner, root)
        self.assertEqual(len(mutations), len({m[0] for m in mutations}))
        original = (SCHEMA.parent / 'world.yaml').read_bytes()
        baseline = load_module(SCHEMA.parent / 'world.yaml')
        with tempfile.TemporaryDirectory(prefix='hostile-profile-mutations-') as directory:
            target = Path(directory) / 'schema'
            shutil.copytree(SCHEMA.parent, target)
            path = target / SCHEMA.name
            module = target / 'world.yaml'
            _, schema = self._assert_initial_site_hostile_profile(path)
            for label, keys, value in mutations:
                verify_hostile_profile_mutation(self, label, keys, value, baseline, module, original, path)
            # ONLY melee minimum .5 -> .4: actual YAML broadening, not output editing.
            verify_hostile_profile_broadened(self, owner, baseline, module, original, path, schema)
        self.assertEqual((SCHEMA.parent / 'world.yaml').read_bytes(), original)
        print('hostile mutations:', len(mutations), 'SAME-oracle cases; minimum .5->.4 admits .45, baseline rejects minimum')


if __name__ == "__main__":
    unittest.main()
