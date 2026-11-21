"""Initial site local difficulty world schema tests."""
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
from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import catalog, validator


def verify_local_raw(self, raw, profile, hostile, boss, anchor, constants, power):
    # Check ALL raw owners before any SDK induction or schema emission.
    for owner in (profile, hostile, boss):
        self.assertIn(owner, raw['classes'], 'missing local-difficulty declaration: ' + owner)
        declaration = raw['classes'][owner]
        self.assertEqual(declaration['class_uri'], 'pixlnd:' + owner)
        self.assertIn(anchor, declaration['see_also'])
        self.assertFalse(declaration.get('slots') or declaration.get('mixins'))
    declarations = raw['classes']
    self.assertFalse(declarations[profile].get('is_a') or declarations[profile].get('slot_usage'))
    self.assertEqual(set(declarations[profile]['attributes']), set(constants))
    self.assertEqual(declarations[hostile]['is_a'], 'creature-spawn')
    self.assertEqual(declarations[boss]['is_a'], hostile)
    self.assertEqual(set(declarations[hostile]['attributes']), {'tier', 'parameters'})
    self.assertEqual(set(declarations[boss]['attributes']), {'height-blocks'})
    self.assertFalse(declarations[boss].get('slot_usage'))
    self.assertEqual(declarations[hostile]['slot_usage'], {
        'entity-species': {'alias': 'type', 'range': 'creature', 'equals_string': 'skeleton'},
        'entity-hostility': {'alias': 'hostility', 'equals_string': 'hostile'},
        'entity-power-base': {'alias': 'power-base', 'minimum_value': 2, 'maximum_value': 6,
                              'equals_expression': power},
    })
    return declarations


def verify_local_raw_slots(self, declarations, local, anchor):
    for (owner, name), (range_, lower, upper, equal, expression, inline) in local.items():
        slot = declarations[owner]['attributes'][name]
        self.assertEqual((slot['alias'], slot['slot_uri'], slot['range'], slot['required']),
                         (name, 'pixlnd:' + owner + '/' + name, range_, True))
        self.assertEqual((slot.get('minimum_value'), slot.get('maximum_value'), slot.get('equals_number'),
                          slot.get('equals_expression'), bool(slot.get('inlined'))),
                         (lower, upper, equal, expression, inline))
        if lower is not None:
            self.assertIs(type(slot['minimum_value']), type(lower))
            self.assertIs(type(slot['maximum_value']), type(upper))
        if equal is not None:
            self.assertIs(type(slot['equals_number']), int)
        else:
            self.assertNotIn('equals_number', slot)
        self.assertIn(anchor, slot['see_also'])
        self.assertFalse(slot.get('identifier') or slot.get('key') or slot.get('multivalued') or
                         slot.get('inlined_as_list') or slot.get('domain') or slot.get('ifabsent'))
        self.assertIsNone(slot.get('minimum_cardinality'))
        self.assertIsNone(slot.get('maximum_cardinality'))


def verify_local_induced_slots(self, view, local, anchor):
    for (owner, name), (range_, lower, upper, equal, expression, inline) in local.items():
        slot = view.induced_slot(name, owner)
        self.assertEqual((slot.alias, str(slot.slot_uri), slot.range, bool(slot.required)),
                         (name, 'pixlnd:' + owner + '/' + name, range_, True))
        self.assertEqual((slot.minimum_value, slot.maximum_value, slot.equals_expression, bool(slot.inlined)),
                         (lower, upper, expression, inline))
        if equal is None:
            self.assertIsNone(slot.equals_number)
        else:
            print('local numeric metadata:', name, equal, slot.equals_number,
                  type(slot.equals_number).__module__ + '.' + type(slot.equals_number).__qualname__,
                  slot.minimum_value, slot.maximum_value)
            self.assertTrue(isinstance(slot.equals_number, int) and not isinstance(slot.equals_number, bool)
                            and slot.equals_number == equal)
        self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined_as_list)
        self.assertIsNone(slot.minimum_cardinality)
        self.assertIsNone(slot.maximum_cardinality)
        self.assertIn(anchor, slot.see_also)


def verify_local_inherited(self, view, profile, hostile, boss, power):
    inherited = {
        'entity-hostility': ('hostility', 'hostility', True, False, None, None),
        'entity-species': ('type', 'creature', True, False, None, None),
        'entity-class': ('class', 'character-class', False, False, None, None),
        'entity-specialization': ('spec', 'specialization', False, False, None, None),
        'entity-level': ('level', 'integer', True, False, None, None),
        'entity-power-base': ('power-base', 'u8', True, False, None, None),
        'entity-appearance': ('appearance', 'appearance', True, False, None, None),
        'entity-equipment': ('equipment', 'item', False, True, 13, 13),
        'entity-name': ('name', 'string', False, False, None, None),
    }
    for owner in (hostile, boss):
        names = set(inherited) | {'tier', 'parameters'} | ({'height-blocks'} if owner == boss else set())
        slots = view.class_induced_slots(owner)
        self.assertEqual({s.name for s in slots}, names)
        self.assertEqual(len(slots), len(names))
        for name, (alias, range_, required, multiple, lower, upper) in inherited.items():
            slot = view.induced_slot(name, owner)
            self.assertEqual((slot.alias, slot.range, bool(slot.required), bool(slot.multivalued),
                              slot.minimum_cardinality, slot.maximum_cardinality),
                             (alias, range_, required, multiple, lower, upper))
            self.assertEqual(str(slot.slot_uri), 'pixlnd:entity/' + name.removeprefix('entity-'))
            self.assertIn('../domain/3_Classes.md#entity', slot.see_also)
            self.assertFalse(slot.identifier or slot.key or slot.inlined_as_list)
            self.assertEqual(bool(slot.inlined), name == 'entity-appearance')
        self.assertIsNone(view.induced_slot('entity-level', owner).minimum_value)
        self.assertEqual(view.induced_slot('entity-power-base', owner).equals_expression, power)
        self.assertEqual((view.induced_slot('entity-power-base', owner).minimum_value,
                          view.induced_slot('entity-power-base', owner).maximum_value), (2, 6))
        self.assertEqual(view.induced_slot('entity-species', owner).equals_string, 'skeleton')
        self.assertEqual(view.induced_slot('entity-hostility', owner).equals_string, 'hostile')
        parameters = view.induced_slot('parameters', owner)
        self.assertEqual((parameters.range, parameters.owner, bool(parameters.required), bool(parameters.inlined)),
                         (profile, owner, True, True))


def local_contract_cases(native, owner, row, parameters, profile):
    cases = [None, [], False, 1, 'root', dict(row, unknown=True)]
    for field in row:
        cases.append(dict(row, **{field: True}))
        if field not in ('class', 'spec', 'equipment', 'name'):
            cases += [{k: v for k, v in row.items() if k != field}, dict(row, **{field: None})]
        else:
            native.validate({k: v for k, v in row.items() if k != field})
            native.validate(dict(row, **{field: None}))
    for name, value in parameters.items():
        for bad in (value - 0.1, value + 0.1, str(value), [], {}):
            changed = deepcopy(row)
            target = changed if owner == profile else changed['parameters']
            target[name] = bad
            cases.append(changed)
    if owner != profile:
        cases += [dict(row, type='skeleton-knight'), dict(row, hostility='friendly'),
                  dict(row, tier=-1), dict(row, tier=5), dict(row, **{'power-base': 1}),
                  dict(row, **{'power-base': 7}), dict(row, parameters='profile-reference')]
    return cases


def verify_local_value_vector(self, owner, native, tier, level, golden, parameters, view, config):
    from jsonasobj2 import JsonObj, as_dict
    from linkml_runtime.utils.inference_utils import generate_slot_value

    calls = 0
    row = {'hostility': 'hostile', 'type': 'skeleton', 'level': level, 'power-base': 2 + tier,
           'appearance': {'id': 'local-appearance', 'head-model': 0, 'hair-rgb': [0, 0, 0], 'scale': [1, 1, 1]},
           'class': 'warrior', 'spec': 'berserker', 'equipment': ['local-item'] * 13, 'name': 'Skeleton', 'tier': tier, 'parameters': deepcopy(parameters)}
    if owner == 'initial-site-boss-spawn':
        row['height-blocks'] = float(golden)
    native.validate(row)
    # Wrong but IN-BOUNDS targets admit: inference does not compare or update them.
    row['power-base'] = 3
    if owner == 'initial-site-boss-spawn':
        row['height-blocks'] = 3.0
    native.validate(row)
    obj = JsonObj(deepcopy(row))
    before = deepcopy(as_dict(obj))
    power = generate_slot_value(obj, 'entity_power_base', view, class_name=owner, config=config)
    self.assertIs(type(power), int)
    self.assertEqual(power, 2 + tier)
    calls += 1
    if owner == 'initial-site-boss-spawn':
        height = generate_slot_value(obj, 'height_blocks', view, class_name=owner, config=config)
        self.assertIs(type(height), float)
        self.assertLessEqual(abs(height - float(golden)), 1e-12)
        calls += 1
    self.assertEqual(as_dict(obj), before)
    return calls


def verify_local_mutation(self, label, keys, replacement, baseline, module, path):
    changed = deepcopy(baseline)
    cursor = changed
    for key in keys[:-1]:
        cursor = cursor[key]
    if replacement is None:
        del cursor[keys[-1]]
    else:
        cursor[keys[-1]] = replacement
    module.write_text(yaml.safe_dump(changed, sort_keys=False))
    self.assertEqual(yaml.safe_load(module.read_text()), changed)
    with self.subTest(mutation=label), self.assertRaises(AssertionError):
        self._assert_initial_site_local_difficulty(path)
    print('local mutation detected:', label)


def verify_local_expression_deletion(self, label, path, hostile, boss, baseline_schemas):
    from jsonasobj2 import JsonObj, as_dict
    from linkml_runtime.utils.inference_utils import Config, generate_slot_value
    from ontology_source_contracts import assert_declared_root

    owner = hostile if label == 'power-expression' else boss
    view = SchemaView(str(path))
    schema = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                                           preserve_names=True, not_closed=False).serialize())
    fields = {'hostility', 'type', 'class', 'spec', 'level', 'power-base', 'appearance',
              'equipment', 'name', 'tier', 'parameters'}
    required = {'hostility', 'type', 'level', 'power-base', 'appearance', 'tier', 'parameters'}
    if owner == boss:
        fields.add('height-blocks')
        required.add('height-blocks')
    assert_declared_root(owner, fields, required, schema=schema, view=view)
    self.assertEqual(schema, baseline_schemas[owner])
    row = {'hostility': 'hostile', 'type': 'skeleton', 'level': 5, 'power-base': 3,
           'appearance': {'id': 'local-appearance', 'head-model': 0, 'hair-rgb': [0, 0, 0], 'scale': [1, 1, 1]},
           'class': 'warrior', 'spec': 'berserker', 'equipment': ['local-item'] * 13, 'name': 'Skeleton', 'tier': 0,
           'parameters': {'power-base-offset': 2, 'boss-hp-multiplier': 4,
               'boss-direct-damage-multiplier': 1.5, 'height-base-blocks': 1.7,
               'height-minimum-multiplier': 1.25, 'height-linear-growth': 0.75,
               'height-maximum-level': 10}}
    if owner == boss:
        row['height-blocks'] = 3.0
    jsonschema.Draft201909Validator(schema).validate(row)
    obj = JsonObj(deepcopy(row))
    before = deepcopy(as_dict(obj))
    slot = 'entity_power_base' if owner == hostile else 'height_blocks'
    self.assertIsNone(generate_slot_value(obj, slot, view, class_name=owner,
        config=Config(use_expressions=True, use_string_serialization=False)))
    self.assertEqual(as_dict(obj), before)
    print('local expression deletion:', label, 'SDK None; native byte-equivalent/no-effect')


class LogicalWorldTests(unittest.TestCase):
    def _assert_initial_site_local_difficulty(self, path):
        from ontology_source_contracts import assert_declared_root

        profile = 'initial-site-local-difficulty-profile'
        hostile = 'initial-site-hostile-spawn'
        boss = 'initial-site-boss-spawn'
        anchor = '../domain/encounter-contracts.md#local-difficulty-and-boss-size'
        constants = {
            'power-base-offset': ('integer', 2), 'boss-hp-multiplier': ('double', 4),
            'boss-direct-damage-multiplier': ('double', 1.5), 'height-base-blocks': ('double', 1.7),
            'height-minimum-multiplier': ('double', 1.25), 'height-linear-growth': ('double', 0.75),
            'height-maximum-level': ('integer', 10),
        }
        power = "parameters['power-base-offset'] + tier"
        height = "parameters['height-base-blocks'] * (parameters['height-minimum-multiplier'] + parameters['height-linear-growth'] * (max([1, min([level, parameters['height-maximum-level']])]) - 1) / (parameters['height-maximum-level'] - 1))"
        raw = yaml.safe_load(path.with_name('world.yaml').read_text())
        declarations = verify_local_raw(self, raw, profile, hostile, boss, anchor, constants, power)
        local = {(profile, name): (range_, value, value, value if name in
                 ('power-base-offset', 'boss-hp-multiplier', 'height-maximum-level') else None, None, False)
                 for name, (range_, value) in constants.items()}
        local.update({(hostile, 'tier'): ('integer', 0, 4, None, None, False),
                      (hostile, 'parameters'): (profile, None, None, None, None, True),
                      (boss, 'height-blocks'): ('double', 2.125, 3.4, None, height, False)})
        verify_local_raw_slots(self, declarations, local, anchor)
        view = SchemaView(str(path))
        verify_local_induced_slots(self, view, local, anchor)
        verify_local_inherited(self, view, profile, hostile, boss, power)
        fields = {
            profile: set(constants),
            hostile: {'hostility', 'type', 'class', 'spec', 'level', 'power-base', 'appearance',
                      'equipment', 'name', 'tier', 'parameters'},
            boss: {'hostility', 'type', 'class', 'spec', 'level', 'power-base', 'appearance',
                   'equipment', 'name', 'tier', 'parameters', 'height-blocks'},
        }
        required = {profile: set(constants), hostile: {'hostility', 'type', 'level', 'power-base',
                    'appearance', 'tier', 'parameters'}, boss: {'hostility', 'type', 'level', 'power-base',
                    'appearance', 'tier', 'parameters', 'height-blocks'}}
        schemas = {}
        for owner in (profile, hostile, boss):
            schema = (validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
                str(path), top_class=owner, preserve_names=True, not_closed=False).serialize()))
            assert_declared_root(owner, fields[owner], required[owner], schema=schema, view=view)
            if owner != profile:
                self.assertEqual(schema['$defs'][owner]['properties']['parameters']['$ref'], '#/$defs/' + profile)
            schemas[owner] = schema
        return view, schemas

    def test_initial_site_local_difficulty_contracts(self):
        _, schemas = self._assert_initial_site_local_difficulty(SCHEMA)
        profile = 'initial-site-local-difficulty-profile'
        parameters = {'power-base-offset': 2, 'boss-hp-multiplier': 4, 'boss-direct-damage-multiplier': 1.5,
                      'height-base-blocks': 1.7, 'height-minimum-multiplier': 1.25,
                      'height-linear-growth': 0.75, 'height-maximum-level': 10}
        source = catalog('generators')['design']['initial-encounters']
        self.assertEqual([source['power-base-offset'], source['boss-hp-mult'], source['boss-damage-mult'],
                          *[source['boss-height'][key] for key in ('base', 'min-mult', 'growth', 'max-level')]],
                         [2, 4, 1.5, 1.7, 1.25, 0.75, 10])
        hostile = {'hostility': 'hostile', 'type': 'skeleton', 'level': 1, 'power-base': 2,
                   'appearance': {'id': 'local-appearance', 'head-model': 0, 'hair-rgb': [0, 0, 0], 'scale': [1, 1, 1]},
                   'class': 'warrior', 'spec': 'berserker', 'equipment': ['local-item'] * 13, 'name': 'Skeleton', 'tier': 0, 'parameters': parameters}
        rows = {profile: parameters, 'initial-site-hostile-spawn': hostile,
                'initial-site-boss-spawn': dict(hostile, **{'height-blocks': 2.125})}
        count = 0
        for owner, row in rows.items():
            native = jsonschema.Draft201909Validator(schemas[owner])
            native.validate(row)
            cases = local_contract_cases(native, owner, row, parameters, profile)
            for index, bad in enumerate(cases):
                with self.subTest(owner=owner, case=index), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)
                count += 1
        print('local contracts: 3 complete positives;', count, 'negative controls')

    def test_initial_site_local_difficulty_values(self):
        from fractions import Fraction

        from linkml_runtime.utils.inference_utils import Config

        view, schemas = self._assert_initial_site_local_difficulty(SCHEMA)
        parameters = {'power-base-offset': 2, 'boss-hp-multiplier': 4, 'boss-direct-damage-multiplier': 1.5,
                      'height-base-blocks': 1.7, 'height-minimum-multiplier': 1.25,
                      'height-linear-growth': 0.75, 'height-maximum-level': 10}
        config = Config(use_expressions=True, use_string_serialization=False)
        self.assertEqual(view.slot_name_mappings()['entity_power_base'].name, 'entity-power-base')
        self.assertEqual(view.slot_name_mappings()['height_blocks'].name, 'height-blocks')
        calls = 0
        for owner in ('initial-site-hostile-spawn', 'initial-site-boss-spawn'):
            native = jsonschema.Draft201909Validator(schemas[owner])
            for tier in (0, 2, 4):
                for level, golden in [(1, Fraction(17, 8)), (5, Fraction(323, 120)),
                                      (10, Fraction(17, 5)), (20, Fraction(17, 5))]:
                    calls += verify_local_value_vector(self, owner, native, tier, level, golden, parameters, view, config)
        print('local values: 24 complete vectors; public calls', calls,
              '; wrong in-bounds targets admitted; SDK arithmetic-only tolerance 1e-12')

    def test_initial_site_local_difficulty_mutations(self):
        _, baseline_schemas = self._assert_initial_site_local_difficulty(SCHEMA)
        profile, hostile, boss = ('initial-site-local-difficulty-profile', 'initial-site-hostile-spawn',
                                  'initial-site-boss-spawn')
        mutations = [('missing-' + owner, ('classes', owner), None) for owner in (profile, hostile, boss)]
        mutations += [
            ('hostile-parent', ('classes', hostile, 'is_a'), 'entity'),
            ('boss-parent', ('classes', boss, 'is_a'), 'creature-spawn'),
            ('profile-range', ('classes', profile, 'attributes', 'height-linear-growth', 'range'), 'integer'),
            ('tier-alias', ('classes', hostile, 'attributes', 'tier', 'alias'), 'wrong-tier'),
            ('height-required', ('classes', boss, 'attributes', 'height-blocks', 'required'), False),
            ('fraction-bound', ('classes', profile, 'attributes', 'height-linear-growth', 'minimum_value'), 0.5),
            ('integer-equality', ('classes', profile, 'attributes', 'power-base-offset', 'equals_number'), None),
            ('parameters-range', ('classes', hostile, 'attributes', 'parameters', 'range'), 'initial-site-hostile-profile'),
            ('parameters-identity', ('classes', hostile, 'attributes', 'parameters', 'identifier'), True),
            ('power-expression', ('classes', hostile, 'slot_usage', 'entity-power-base', 'equals_expression'), None),
            ('height-expression', ('classes', boss, 'attributes', 'height-blocks', 'equals_expression'), None),
        ]
        self.assertEqual(len(mutations), 14)
        original = SCHEMA.with_name('world.yaml').read_bytes()
        baseline = yaml.safe_load(original)
        with tempfile.TemporaryDirectory(prefix='local-difficulty-mutations-') as directory:
            target = Path(directory) / 'schema'
            shutil.copytree(SCHEMA.parent, target)
            module = target / 'world.yaml'
            path = target / SCHEMA.name
            for label, keys, replacement in mutations:
                verify_local_mutation(self, label, keys, replacement, baseline, module, path)
                if label in ('power-expression', 'height-expression'):
                    verify_local_expression_deletion(self, label, path, hostile, boss, baseline_schemas)
                module.write_bytes(original)
        self.assertEqual(SCHEMA.with_name('world.yaml').read_bytes(), original)
        print('local mutations: all14 SAME raw-first oracle cases; 2 missing inference/native no-effect')


if __name__ == "__main__":
    unittest.main()
