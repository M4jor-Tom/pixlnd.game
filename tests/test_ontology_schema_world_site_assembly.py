"""Initial site assembly world schema tests."""
import json
import tempfile
import unittest
from copy import deepcopy
from pathlib import Path

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA, copy_schema, load_module
from test_ontology_schema_authoring import validator


def volume(width, depth, above=12):
    return {'width': width, 'depth': depth, 'below-floor': 1, 'above-floor': above}


class LogicalWorldTests(unittest.TestCase):
    def test_initial_site_assembly_contracts(self):
        def oracle(path):
            return assembly_oracle(self, path)

        schemas = oracle(SCHEMA)
        path = SCHEMA
        with tempfile.TemporaryDirectory(prefix="initial-site-assembly-") as directory:
            destination = Path(directory)
            original = load_module(path.with_name('world.yaml'))
            mutations = []
            for owner in ('initial-ruins-assembly', 'initial-camp-assembly', 'initial-rescue-assembly', 'initial-battlefield-exit'):
                mutations.append(('remove-' + owner, ('classes', owner), None))
            for owner in ('initial-ruins-assembly', 'initial-camp-assembly', 'initial-rescue-assembly'):
                mutations.append(('remove-attachment-' + owner, ('classes', owner, 'slots'), []))
            mutations += [
                ('rooms-three-to-two', ('classes', 'initial-ruins-assembly', 'attributes', 'rooms', 'minimum_cardinality'), 2),
                ('rooms-maximum-two', ('classes', 'initial-ruins-assembly', 'attributes', 'rooms', 'maximum_cardinality'), 2),
                ('corridor-nominal-passage', ('classes', 'initial-ruins-assembly', 'attributes', 'corridors', 'range'), 'ruins-passage-volume'),
                ('passage-nominal-corridor', ('classes', 'initial-ruins-assembly', 'attributes', 'entrance-passage', 'range'), 'ruins-corridor-volume'),
                ('camp-range-broaden', ('classes', 'initial-camp-assembly', 'slot_usage', 'initial-battlefield', 'range'), 'encounter-volume'),
                ('camp-range-swap', ('classes', 'initial-camp-assembly', 'slot_usage', 'initial-battlefield', 'range'), 'rescue-battlefield-volume'),
                ('rooms-required-loss', ('classes', 'initial-ruins-assembly', 'attributes', 'rooms', 'required'), False),
                ('rooms-inline-loss', ('classes', 'initial-ruins-assembly', 'attributes', 'rooms', 'inlined'), False),
                ('rooms-list-inline-loss', ('classes', 'initial-ruins-assembly', 'attributes', 'rooms', 'inlined_as_list'), False),
                ('rooms-alias-loss', ('classes', 'initial-ruins-assembly', 'attributes', 'rooms', 'alias'), 'wrong-rooms'),
                ('rooms-uri-loss', ('classes', 'initial-ruins-assembly', 'attributes', 'rooms', 'slot_uri'), 'pixlnd:wrong-rooms'),
                ('corridors-lower-loss', ('classes', 'initial-ruins-assembly', 'attributes', 'corridors', 'minimum_cardinality'), 0),
                ('corridors-guessed-upper', ('classes', 'initial-ruins-assembly', 'attributes', 'corridors', 'maximum_cardinality'), 2),
                ('exit-width-change', ('classes', 'initial-battlefield-exit', 'attributes', 'width-blocks', 'equals_number'), 9),
                ('shared-domain-loss', ('slots', 'initial-battlefield', 'domain'), 'initial-camp-assembly'),
                ('shared-alias-loss', ('slots', 'initial-battlefield', 'alias'), 'wrong-battlefield'),
                ('shared-uri-loss', ('slots', 'initial-opposite-exits', 'slot_uri'), 'pixlnd:wrong-exits'),
                ('shared-inline-loss', ('slots', 'initial-opposite-exits', 'inlined'), False),
                ('ruins-parent-loss', ('classes', 'initial-ruins-assembly', 'is_a'), 'poi'),
            ]
            for label, keys, replacement in mutations:
                target = destination / label
                copy_schema(target)
                mutant = deepcopy(original)
                cursor = mutant
                for key in keys[:-1]:
                    cursor = cursor[key]
                if replacement is None:
                    del cursor[keys[-1]]
                else:
                    cursor[keys[-1]] = replacement
                if label == 'rooms-three-to-two':
                    mutant['classes']['initial-ruins-assembly']['attributes']['rooms']['maximum_cardinality'] = 2
                changed = target / 'world.yaml'
                changed.write_text(yaml.safe_dump(mutant, sort_keys=False))
                mutant_path = target / path.name
                with self.subTest(mutation=label), self.assertRaises(AssertionError):
                    oracle(mutant_path)
                # These native effects are deliberately distinct from nominal declaration checks.
                if label in ('rooms-three-to-two', 'corridor-nominal-passage', 'camp-range-broaden', 'camp-range-swap'):
                    verify_native_effect(self, label, mutant_path, schemas)

    def test_initial_site_assembly_values(self):
        from ontology_source_contracts import assert_declared_root

        # Independent literal roots: no missing-top-class or emitted-field oracle.
        expected = {
            "initial-ruins-assembly": {"id", "located-in", "rooms", "corridors", "entrance-court",
                "entrance-passage", "reward-alcove", "horizontal-bounds-width-blocks",
                "horizontal-bounds-depth-blocks", "clear-ceiling-height-blocks", "door-width-blocks",
                "door-height-blocks", "corridor-trap-free-lane-width-blocks"},
            "initial-camp-assembly": {"id", "located-in", "battlefield", "opposite-exits"},
            "initial-rescue-assembly": {"id", "located-in", "battlefield", "opposite-exits"},
            "initial-battlefield-exit": {"width-blocks"},
        }
        view = SchemaView(str(SCHEMA))
        schemas = {}
        for owner, fields in expected.items():
            self.assertTrue(owner in view.all_classes(), "Missing declared source class: " + owner)
            schema = validator(owner).schema
            assert_declared_root(owner, fields, fields, schema=schema, view=view)
            schemas[owner] = schema

        ruins = {'id': 'ruins-example', 'located-in': 'unresolved-land',
                 'rooms': [volume(24, 24)] * 3, 'corridors': [volume(8, 8)],
                 'entrance-court': volume(24, 16), 'entrance-passage': volume(8, 8),
                 'reward-alcove': volume(12, 8), 'horizontal-bounds-width-blocks': 36,
                 'horizontal-bounds-depth-blocks': 112, 'clear-ceiling-height-blocks': 6,
                 'door-width-blocks': 4, 'door-height-blocks': 5,
                 'corridor-trap-free-lane-width-blocks': 4}
        rows = {'initial-ruins-assembly': ruins,
                'initial-camp-assembly': {'id': 'camp-example', 'located-in': 'unresolved-land',
                                         'battlefield': volume(64, 64, 16),
                                         'opposite-exits': [{'width-blocks': 8}] * 2},
                'initial-rescue-assembly': {'id': 'rescue-example', 'located-in': 'unresolved-land',
                                           'battlefield': volume(48, 48, 16),
                                           'opposite-exits': [{'width-blocks': 8}] * 2},
                'initial-battlefield-exit': {'width-blocks': 8}}
        for owner, row in rows.items():
            verify_owner_witnesses(self, owner, row, schemas)


def verify_assembly_counts(reject, native, owner, row):
    if owner == 'initial-ruins-assembly':
        for count in (0, 2, 4):
            reject('rooms-count-' + str(count), dict(row, rooms=[volume(24, 24)] * count))
        reject('empty-corridors', dict(row, corridors=[]))
        # Multiple counts are structural witnesses, not connected geometry claims.
        for count in (1, 2, 7):
            native.validate(dict(row, corridors=[volume(8, 8)] * count))
        reject('ceiling-not-occupancy-above', dict(row, **{'clear-ceiling-height-blocks': 12}))
    elif owner in ('initial-camp-assembly', 'initial-rescue-assembly'):
        for count in (0, 1, 3):
            reject('exits-count-' + str(count), dict(row, **{'opposite-exits': [{'width-blocks': 8}] * count}))
        other_width = 48 if owner == 'initial-camp-assembly' else 64
        reject('wrong-nominal-battlefield-dimensions', dict(row, battlefield=volume(other_width, other_width, 16)))
        # Two equal exit values are legal; no fabricated uniqueness or IDs.
        native.validate(row)


def reject_container_witnesses(reject, row, field, value):
    for malformed in ('component-ref', True, 1, {}, [None], ['component-ref']):
        reject(field + '-container-' + repr(malformed), dict(row, **{field: malformed}))
    if isinstance(value, dict):
        reject(field + '-list-instead-of-singleton', dict(row, **{field: [value]}))
    else:
        reject(field + '-null-member', dict(row, **{field: [None] * len(value)}))
        reject(field + '-ref-member', dict(row, **{field: ['component-ref'] * len(value)}))
    member = value[0] if isinstance(value, list) else value
    for dimension, literal in member.items():
        for malformed in (literal - 1, literal + 1, str(literal), True, False, None,
                          float('nan'), float('inf'), float('-inf')):
            bad = deepcopy(row)
            target = bad[field][0] if isinstance(value, list) else bad[field]
            target[dimension] = malformed
            reject(field + '.' + dimension + '-' + repr(malformed), bad)
        bad = deepcopy(row)
        target = bad[field][0] if isinstance(value, list) else bad[field]
        del target[dimension]
        reject(field + '.' + dimension + '-missing', bad)
    bad = deepcopy(row)
    target = bad[field][0] if isinstance(value, list) else bad[field]
    target['id'] = 'invented-component-id'
    reject(field + '-invented-component-id', bad)


def reject_field_witnesses(reject, row, field, value):
    reject('missing-' + field, {k: v for k, v in row.items() if k != field})
    reject('null-' + field, dict(row, **{field: None}))
    if isinstance(value, (dict, list)):
        reject_container_witnesses(reject, row, field, value)
    elif isinstance(value, (int, float)):
        for malformed in (value - 1, value + 1, str(value), True, False, [], {},
                          float('nan'), float('inf'), float('-inf')):
            reject(field + '-' + repr(malformed), dict(row, **{field: malformed}))
    else:
        for malformed in (True, 1, [], {}, {'id': value}):
            reject(field + '-' + repr(malformed), dict(row, **{field: malformed}))


def verify_owner_witnesses(self, owner, row, schemas):
    native = jsonschema.Draft201909Validator(schemas[owner])
    native.validate(row)

    def reject(label, bad):
        with self.subTest(owner=owner, witness=label), self.assertRaises(jsonschema.ValidationError):
            native.validate(bad)

    for bad in (None, [], [row], False, 0, 'reference'):
        reject('root-' + repr(bad), bad)
    for field, value in row.items():
        reject_field_witnesses(reject, row, field, value)
    for field in ('closed', 'reachable', 'opposite', 'orientation', 'position', 'state', 'policy'):
        reject('unknown-' + field, dict(row, **{field: True}))
    verify_assembly_counts(reject, native, owner, row)


def verify_native_camp(self, label, native, schemas, owner):
    row = {'id': 'camp-example', 'located-in': 'unresolved-land',
           'battlefield': {'width': 48, 'depth': 48, 'below-floor': 1, 'above-floor': 16},
           'opposite-exits': [{'width-blocks': 8}] * 2}
    with self.assertRaises(jsonschema.ValidationError):
        jsonschema.Draft201909Validator(schemas[owner]).validate(row)
    native.validate(row)
    row['battlefield'].update(width=64, depth=64)
    if label == 'camp-range-swap':
        with self.assertRaises(jsonschema.ValidationError):
            native.validate(row)
    else:
        native.validate(row)


def verify_native_ruins(self, label, native, schemas, owner, emitted):
    row = {'id': 'ruins-example', 'located-in': 'unresolved-land',
           'rooms': [{'width': 24, 'depth': 24, 'below-floor': 1, 'above-floor': 12}] * 3,
           'corridors': [{'width': 8, 'depth': 8, 'below-floor': 1, 'above-floor': 12}],
           'entrance-court': {'width': 24, 'depth': 16, 'below-floor': 1, 'above-floor': 12},
           'entrance-passage': {'width': 8, 'depth': 8, 'below-floor': 1, 'above-floor': 12},
           'reward-alcove': {'width': 12, 'depth': 8, 'below-floor': 1, 'above-floor': 12},
           'horizontal-bounds-width-blocks': 36, 'horizontal-bounds-depth-blocks': 112,
           'clear-ceiling-height-blocks': 6, 'door-width-blocks': 4, 'door-height-blocks': 5,
           'corridor-trap-free-lane-width-blocks': 4}
    if label == 'rooms-three-to-two':
        with self.assertRaises(jsonschema.ValidationError):
            native.validate(row)
        row['rooms'] = row['rooms'][:2]
        with self.assertRaises(jsonschema.ValidationError):
            jsonschema.Draft201909Validator(schemas[owner]).validate(row)
        native.validate(row)
    else:
        native.validate(row)
        self.assertNotEqual(emitted['$defs'][owner]['properties']['corridors'],
                            schemas[owner]['$defs'][owner]['properties']['corridors'])


def verify_native_effect(self, label, mutant_path, schemas):
    from ontology_source_contracts import assert_declared_root

    owner = 'initial-camp-assembly' if label.startswith('camp-') else 'initial-ruins-assembly'
    emitted = json.loads(JsonSchemaGenerator(str(mutant_path), top_class=owner,
                                             preserve_names=True, not_closed=False).serialize())
    fields = ({'id', 'located-in', 'battlefield', 'opposite-exits'} if owner == 'initial-camp-assembly' else
              {'id', 'located-in', 'rooms', 'corridors', 'entrance-court', 'entrance-passage', 'reward-alcove',
               'horizontal-bounds-width-blocks', 'horizontal-bounds-depth-blocks', 'clear-ceiling-height-blocks',
               'door-width-blocks', 'door-height-blocks', 'corridor-trap-free-lane-width-blocks'})
    assert_declared_root(owner, fields, fields, schema=emitted, view=SchemaView(str(mutant_path)))
    native = jsonschema.Draft201909Validator(emitted)
    if owner == 'initial-ruins-assembly':
        verify_native_ruins(self, label, native, schemas, owner, emitted)
    else:
        verify_native_camp(self, label, native, schemas, owner)


def verify_outdoor_schema(self, definition, outdoor, owner, exit_name):
    self.assertEqual(definition['properties']['battlefield']['$ref'], '#/$defs/' + outdoor[owner])
    exits = definition['properties']['opposite-exits']
    self.assertEqual((exits['type'], exits['minItems'], exits['maxItems']), ('array', 2, 2))
    self.assertEqual(exits['items']['$ref'], '#/$defs/' + exit_name)
    self.assertNotIn('uniqueItems', exits)


def verify_local_schema_prop(self, definition, name, range_, multiple, inline, minimum, maximum, value):
    prop = definition['properties'][name]
    if multiple:
        self.assertEqual(prop['type'], 'array')
        self.assertEqual((prop.get('minItems'), prop.get('maxItems')), (minimum, maximum))
        self.assertEqual(prop['items']['$ref'], '#/$defs/' + range_)
        self.assertNotIn('uniqueItems', prop)
    elif inline:
        self.assertEqual(prop['$ref'], '#/$defs/' + range_)
    else:
        self.assertEqual((prop['type'], prop['const']), ('number', value))
        self.assertNotIn('minimum', prop)
        self.assertNotIn('maximum', prop)


def verify_assembly_definition(self, schema, owner, fields, ruins, exit_name, local, outdoor):
    definition = schema['$defs'][owner]
    self.assertEqual(len(definition['required']), len(fields))
    for field, prop in definition['properties'].items():
        self.assertNotIn('default', prop)
        if field == 'located-in':
            self.assertEqual(prop['type'], 'string')
            self.assertNotIn('$ref', prop)  # Typed reference, not FK membership.
    if owner in (ruins, exit_name):
        for name, (range_, multiple, inline, minimum, maximum, value) in (
                local if owner == ruins else {'width-blocks': ('double', False, False, None, None, 8)}).items():
            verify_local_schema_prop(self, definition, name, range_, multiple, inline, minimum, maximum, value)
    if owner in outdoor:
        verify_outdoor_schema(self, definition, outdoor, owner, exit_name)


def verify_outdoor_slots(self, view, owner, outdoor, shared, anchor):
    for name, (alias, range_, multiple, minimum, maximum) in shared.items():
        slot = view.induced_slot(name, owner)
        self.assertEqual((slot.alias, slot.domain, slot.range, str(slot.slot_uri)),
                         (alias, 'poi', outdoor[owner] if name == 'initial-battlefield' else range_,
                          'pixlnd:poi/' + name))
        self.assertEqual((bool(slot.multivalued), bool(slot.inlined), bool(slot.inlined_as_list)),
                         (multiple, True, multiple))
        self.assertEqual((slot.minimum_cardinality, slot.maximum_cardinality), (minimum, maximum))
        self.assertIn(anchor, slot.see_also)


def verify_induced_slot_facets(self, slot):
    self.assertTrue(slot.required)
    self.assertFalse(slot.key or slot.list_elements_unique)
    self.assertIsNone(slot.ifabsent)
    self.assertIsNone(slot.exact_cardinality)
    self.assertIsNone(slot.minimum_value)
    self.assertIsNone(slot.maximum_value)


def verify_assembly_slots(self, view, raw, owner, expected, exit_name, outdoor, shared, anchor):
    slots = view.class_induced_slots(owner)
    self.assertEqual(len(slots), len(expected[owner]))
    self.assertEqual({s.alias or s.name for s in slots}, expected[owner])
    self.assertEqual([s.name for s in slots if s.identifier], [] if owner == exit_name else ['id'])
    for slot in slots:
        verify_induced_slot_facets(self, slot)
    if owner != exit_name:
        self.assertNotIn('id', raw['classes'][owner].get('slots', []))
        relation = view.induced_slot('located-in', owner)
        self.assertEqual((relation.alias, relation.domain, relation.range, str(relation.slot_uri)),
                         ('located-in', 'settlement-or-dungeon-or-poi', 'land', 'pixlnd:located-in'))
        self.assertFalse(relation.multivalued or relation.inlined or relation.inlined_as_list)
    if owner in outdoor:
        verify_outdoor_slots(self, view, owner, outdoor, shared, anchor)


def verify_assembly_attribute(self, raw, view, anchor, owner, name, range_, multiple, inline, minimum, maximum, value):
    authored = raw['classes'][owner]['attributes'][name]
    self.assertEqual((authored['alias'], authored['domain'], authored['range']), (name, owner, range_))
    self.assertEqual(authored['slot_uri'], 'pixlnd:' + owner + '/' + name)
    self.assertEqual(authored['see_also'], [anchor])
    self.assertTrue(authored['required'])
    self.assertEqual((bool(authored.get('multivalued')), bool(authored.get('inlined')),
                      bool(authored.get('inlined_as_list'))), (multiple, inline, multiple))
    self.assertEqual((authored.get('minimum_cardinality'), authored.get('maximum_cardinality'),
                      authored.get('equals_number')), (minimum, maximum, value))
    slot = view.induced_slot(name, owner)
    self.assertEqual((slot.alias, slot.domain, slot.range), (name, owner, range_))
    self.assertEqual(str(slot.slot_uri), 'pixlnd:' + owner + '/' + name)
    self.assertIn(anchor, slot.see_also)
    self.assertEqual((bool(slot.multivalued), bool(slot.inlined), bool(slot.inlined_as_list)),
                     (multiple, inline, multiple))
    self.assertEqual((slot.minimum_cardinality, slot.maximum_cardinality, slot.equals_number),
                     (minimum, maximum, value))
    self.assertTrue(slot.required)


def verify_shared_slot(self, raw, anchor, outdoor, name, alias, range_, multiple, minimum, maximum):
    authored = raw['slots'][name]
    self.assertEqual((authored['alias'], authored['domain'], authored['range']), (alias, 'poi', range_))
    self.assertEqual(authored['slot_uri'], 'pixlnd:poi/' + name)
    self.assertEqual(authored['see_also'], [anchor])
    self.assertTrue(authored['required'] and authored['inlined'])
    self.assertEqual(bool(authored.get('multivalued')), multiple)
    self.assertEqual(bool(authored.get('inlined_as_list')), multiple)
    self.assertEqual((authored.get('minimum_cardinality'), authored.get('maximum_cardinality')),
                     (minimum, maximum))
    self.assertEqual({c for c, d in raw['classes'].items() if name in d.get('slots', [])}, set(outdoor))


def verify_outdoor_declaration(self, raw, outdoor, owner):
    declaration = raw['classes'][owner]
    self.assertEqual(declaration['is_a'], 'poi')
    self.assertEqual(declaration['slots'], ['located-in', 'initial-battlefield', 'initial-opposite-exits'])
    self.assertFalse(declaration.get('attributes'))
    self.assertEqual(declaration['slot_usage'], {'initial-battlefield': {'range': outdoor[owner]}})


def verify_assembly_class_declaration(self, view, raw, owner, anchor):
    self.assertTrue(owner in view.all_classes(), 'Missing declared source class: ' + owner)
    declaration = raw['classes'][owner]
    self.assertEqual(declaration['class_uri'], 'pixlnd:' + owner)
    self.assertEqual(declaration['see_also'], [anchor])
    self.assertEqual(str(view.get_class(owner).class_uri), 'pixlnd:' + owner)
    self.assertIn(anchor, view.get_class(owner).see_also)
    self.assertFalse(declaration.get('mixins'))


def assembly_oracle(self, path):
    from ontology_source_contracts import assert_declared_root

    anchor = '../domain/encounter-contracts.md#geometry-and-occupancy'
    ruins = 'initial-ruins-assembly'
    outdoor = {'initial-camp-assembly': 'camp-battlefield-volume',
               'initial-rescue-assembly': 'rescue-battlefield-volume'}
    constants = {'horizontal-bounds-width-blocks': 36, 'horizontal-bounds-depth-blocks': 112,
                 'clear-ceiling-height-blocks': 6, 'door-width-blocks': 4,
                 'door-height-blocks': 5, 'corridor-trap-free-lane-width-blocks': 4}
    # Independent source-literal contract: not inferred from declarations or emitted data.
    local = {'rooms': ('ruins-room-volume', True, True, 3, 3, None),
             'corridors': ('ruins-corridor-volume', True, True, 1, None, None),
             'entrance-court': ('ruins-court-volume', False, True, None, None, None),
             'entrance-passage': ('ruins-passage-volume', False, True, None, None, None),
             'reward-alcove': ('ruins-alcove-volume', False, True, None, None, None)}
    local.update({name: ('double', False, False, None, None, value)
                  for name, value in constants.items()})
    exit_name = 'initial-battlefield-exit'
    expected = {ruins: {'id', 'located-in', 'rooms', 'corridors', 'entrance-court',
                       'entrance-passage', 'reward-alcove', 'horizontal-bounds-width-blocks',
                       'horizontal-bounds-depth-blocks', 'clear-ceiling-height-blocks',
                       'door-width-blocks', 'door-height-blocks',
                       'corridor-trap-free-lane-width-blocks'},
                'initial-camp-assembly': {'id', 'located-in', 'battlefield', 'opposite-exits'},
                'initial-rescue-assembly': {'id', 'located-in', 'battlefield', 'opposite-exits'},
                exit_name: {'width-blocks'}}
    raw = load_module(path.with_name('world.yaml'))
    view = SchemaView(str(path))
    for owner in expected:
        verify_assembly_class_declaration(self, view, raw, owner, anchor)
    self.assertIn('relations', raw['imports'])
    self.assertEqual(raw['classes'][ruins]['is_a'], 'dungeon')
    self.assertEqual(raw['classes'][ruins]['slots'], ['located-in'])
    self.assertEqual(set(raw['classes'][ruins]['attributes']), set(local))
    self.assertFalse(raw['classes'][ruins].get('slot_usage'))
    self.assertFalse(raw['classes'][exit_name].get('is_a') or raw['classes'][exit_name].get('slots'))
    self.assertEqual(set(raw['classes'][exit_name]['attributes']), {'width-blocks'})
    for owner in outdoor:
        verify_outdoor_declaration(self, raw, outdoor, owner)
    shared = {'initial-battlefield': ('battlefield', 'encounter-volume', False, None, None),
              'initial-opposite-exits': ('opposite-exits', exit_name, True, 2, 2)}
    for name, (alias, range_, multiple, minimum, maximum) in shared.items():
        verify_shared_slot(self, raw, anchor, outdoor, name, alias, range_, multiple, minimum, maximum)
    for owner, fields in [(ruins, local), (exit_name, {'width-blocks': ('double', False, False, None, None, 8)})]:
        for name, (range_, multiple, inline, minimum, maximum, value) in fields.items():
            verify_assembly_attribute(self, raw, view, anchor, owner, name, range_, multiple, inline, minimum, maximum, value)
    for owner in expected:
        verify_assembly_slots(self, view, raw, owner, expected, exit_name, outdoor, shared, anchor)
    schemas = {}
    for owner, fields in expected.items():
        schema = (validator(owner).schema if path == SCHEMA else
                      json.loads(JsonSchemaGenerator(str(path), top_class=owner, preserve_names=True,
                                                     not_closed=False).serialize()))
        assert_declared_root(owner, fields, fields, schema=schema, view=view)
        verify_assembly_definition(self, schema, owner, fields, ruins, exit_name, local, outdoor)
        schemas[owner] = schema
    for owner in ('dungeon', 'poi'):
        self.assertEqual(view.class_slots(owner), ['id'])
    for owner in ('ruins-room-volume', 'ruins-corridor-volume', 'ruins-court-volume',
                  'ruins-passage-volume', 'ruins-alcove-volume', 'camp-battlefield-volume',
                  'rescue-battlefield-volume', exit_name):
        self.assertFalse(any(s.identifier or s.key for s in view.class_induced_slots(owner)))
    return schemas


if __name__ == "__main__":
    unittest.main()
