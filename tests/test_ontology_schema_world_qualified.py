"""Qualified world components schema tests."""
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


def qualified_component_facts(group):
    pair = {a: ('integer', False, False, None, None, None, None) for a in ('x', 'y')}
    drop = {'item': ('item', False, False, None, None, None, None),
            'pos': ('int64', True, False, 3, 3, None, None),
            'rotation': ('float', False, False, None, None, None, None),
            'scale': ('float', False, False, None, None, None, None),
            'drop-time': ('integer', False, False, None, None, None, None)}
    cuwo = {'entity-type': ('uint32', False, False, None, None, None, None),
            'pos': ('int64', True, False, 3, 3, None, None),
            'orientation': ('uint32', False, False, None, None, None, None),
            'size': ('float', True, False, 3, 3, None, None),
            'closed': ('u8', False, False, None, None, None, None),
            'time-offset': ('uint32', False, False, None, None, None, None),
            'something8': ('uint32', False, False, None, None, None, None),
            'user-id': ('integer', False, False, None, None, 0, 18446744073709551615)}
    berld = {'kind': ('int32', False, False, None, None, None, None),
             'position': ('int64', True, False, 3, 3, None, None),
             'orientation': ('i8', False, False, None, None, None, None),
             'size': ('berld-static-size-components', False, True, None, None, None, None),
             'is-closed': ('boolean', False, False, None, None, None, None),
             'transform-time': ('int32', False, False, None, None, None, None),
             'unknown-b': ('int32', False, False, None, None, None, None),
             'interactor': ('int64', False, False, None, None, None, None)}
    return {
        'discovery': {'zone-coordinate': (None, pair),
                      'cuwo-discovery-coordinate-components': ('zone-coordinate',
                          {a: ('uint32', *v[1:]) for a, v in pair.items()}),
                      'cwsdk-zone-coordinate-components': ('zone-coordinate', pair)},
        'drop': {'dropped-item': (None, drop),
                 'cuwo-dropped-item-components': ('dropped-item',
                     dict(drop, **{'drop-time': ('uint32', *drop['drop-time'][1:])})),
                 'berld-dropped-item-components': ('dropped-item',
                     dict(drop, **{'drop-time': ('int32', *drop['drop-time'][1:])}))},
        'static': {'cuwo-static-header-components': (None, cuwo),
                   'berld-static-header-components': (None, berld),
                   'berld-static-size-components': (None,
                       {a: ('float', False, False, None, None, None, None)
                        for a in ('width', 'depth', 'height')})},
    }[group]


def qualified_component_refs():
    cu = 'https://github.com/matpow2/cuwo/blob/240bb61ec42abb10a73d750ce72f243e04e55509/'
    be = 'https://github.com/LastExceed/berld/blob/f5d3886ce06cde28cc66932f23eea85a05149bc7/'
    sdk = 'https://api.github.com/repos/coremaze/CWSDK/git/blobs/'
    zone_anchor = '../domain/3_Classes.md#zone'
    static_anchors = ['../domain/3_Classes.md#static-entity', '../instances/static-entities.json']
    return {
        'zone-coordinate': ['../domain/3_Classes.md#world', zone_anchor],
        'cuwo-discovery-coordinate-components': [cu + 'cuwo/packet.py#L652-L659', cu + 'cuwo/world.py'],
        'cwsdk-zone-coordinate-components': [sdk + value for value in (
            'be8891283cfa0d7676146f19d8e713f5a9650107', '420c24ff97a594f1e8f8f60aa7baf7929b0161d6',
            'a16689bfc90217d4059247de313c17b52b0d7591', '0b067c6515df7fe38b8ad24993933509cf9a3cfc',
            '97fc2a0ac21c0585186805fd7a1227cd827124d8')],
        'dropped-item': [zone_anchor, cu + 'cuwo/tgen_wrap.pxd#L441-L450', be + 'protocol/src/packet/world_update/loot.rs'],
        'cuwo-dropped-item-components': [zone_anchor, cu + 'cuwo/tgen_wrap.pxd#L441-L450'],
        'berld-dropped-item-components': [zone_anchor, be + 'protocol/src/packet/world_update/loot.rs'],
        'cuwo-static-header-components': static_anchors + [cu + 'cuwo/tgen_wrap.pxd#L260-L271', cu + 'cuwo/static.py', cu + 'cuwo/world.py#L135-L182'],
        'berld-static-header-components': static_anchors + [be + 'protocol/src/packet/world_update.rs#L119-L135', be + 'protocol/src/packet/world_update/world_object.rs', be + 'protocol/src/packet/common.rs#L10'],
        'berld-static-size-components': [be + 'protocol/src/packet/common.rs#L190-L197'],
    }


def verify_qualified_raw_owner(self, group, raw, owner, parent, fields, refs):
    declaration = raw['classes'].get(owner)
    self.assertIsNotNone(declaration, 'Missing declared source class: ' + owner)
    self.assertEqual(declaration['class_uri'], 'pixlnd:' + owner)
    self.assertTrue(declaration['description'])
    self.assertEqual(declaration['see_also'], refs[owner])
    self.assertEqual(declaration.get('is_a'), parent)
    self.assertFalse(declaration.get('slots') or declaration.get('mixins'))
    authored = raw['classes'][parent]['attributes'] if parent else declaration['attributes']
    self.assertEqual(set(authored), {'coordinate-x', 'coordinate-y'} if group == 'discovery' else set(fields))
    if parent:
        self.assertFalse(declaration.get('attributes'))
        refinements = ({'coordinate-' + a: {'range': 'uint32'} for a in ('x', 'y')}
                       if owner == 'cuwo-discovery-coordinate-components' else
                       {'drop-time': {'range': 'uint32' if owner.startswith('cuwo') else 'int32'}}
                       if group == 'drop' else {})
        self.assertEqual(declaration.get('slot_usage', {}), refinements)
    verify_qualified_raw_fields(self, group, fields, authored, declaration, parent, owner)


def verify_qualified_raw_fields(self, group, fields, authored, declaration, parent, owner):
    for alias, (range_, multiple, inline, minimum, maximum, low, high) in fields.items():
        authored_name = 'coordinate-' + alias if group == 'discovery' else alias
        slot = dict(authored[authored_name], **declaration.get('slot_usage', {}).get(authored_name, {}))
        self.assertEqual((slot['alias'], slot['domain'], slot['slot_uri']),
                         (alias, parent or owner, 'pixlnd:' + (parent or owner) + '/' + alias))
        self.assertEqual(slot['range'], range_)
        self.assertIs(slot['required'], True)
        self.assertEqual((bool(slot.get('multivalued')), bool(slot.get('inlined'))), (multiple, inline))
        self.assertFalse(slot.get('inlined_as_list') or slot.get('identifier') or slot.get('key'))
        self.assertEqual((slot.get('minimum_cardinality'), slot.get('maximum_cardinality'),
                          slot.get('minimum_value'), slot.get('maximum_value')),
                         (minimum, maximum, low, high))


def verify_qualified_induced_fields(self, group, view, owner, fields):
    for alias, (range_, multiple, inline, minimum, maximum, low, high) in fields.items():
        slot = view.induced_slot('coordinate-' + alias if group == 'discovery' else alias, owner)
        self.assertEqual((slot.alias, slot.range, bool(slot.required), bool(slot.multivalued),
                          bool(slot.inlined), slot.minimum_cardinality, slot.maximum_cardinality),
                         (alias, range_, True, multiple, inline, minimum, maximum))
        self.assertFalse(slot.key or slot.identifier or slot.ifabsent)


def verify_qualified_drop_owner(self, owner, schema, row):
    native = jsonschema.Draft201909Validator(schema)
    native.validate(row)
    # No invented positive/uniform scale or yaw-degree limits.
    native.validate(dict(row, rotation=1000.5, scale=0))
    for field in row:
        with self.subTest(owner=owner, missing=field), self.assertRaises(jsonschema.ValidationError):
            native.validate({k: v for k, v in row.items() if k != field})
    for field, bads in (('item', [{}, [], True, 1]),
                        ('rotation', [True, None, '0', [], {}]),
                        ('scale', [True, None, '1', [], {}]),
                        ('drop-time', [True, None, '0', 0.5, [], {}]),
                        ('pos', [[0], [0, 1], [0, 1, 2, 3], [0, False, 0], [0, '1', 0],
                                 [0, 9223372036854775808, 0], None])):
        for bad in bads:
            with self.subTest(owner=owner, field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                native.validate(dict(row, **{field: bad}))
    for bad in (None, True, 0, [], 'drop', dict(row, unknown=0)):
        with self.assertRaises(jsonschema.ValidationError):
            native.validate(bad)
    bounds = {'cuwo-dropped-item-components': (0, 4294967295),
              'berld-dropped-item-components': (-2147483648, 2147483647)}
    if owner in bounds:
        low, high = bounds[owner]
        for value in (low, high):
            native.validate(dict(row, **{'drop-time': value}))
        for value in (low - 1, high + 1):
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(dict(row, **{'drop-time': value}))
    else:
        native.validate(dict(row, **{'drop-time': -1}))


def verify_qualified_static_row(self, schemas, owner, row):
    native = jsonschema.Draft201909Validator(schemas[owner])
    native.validate(row)
    for field in row:
        with self.subTest(owner=owner, missing=field), self.assertRaises(jsonschema.ValidationError):
            native.validate({k: v for k, v in row.items() if k != field})
        for bad in (None, 'value', []):
            with self.subTest(owner=owner, field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                native.validate(dict(row, **{field: bad}))
    for bad in (None, True, 0, 'header', [], dict(row, unknown=True)):
        with self.assertRaises(jsonschema.ValidationError):
            native.validate(bad)


def qualified_mutations(original, group, owners):
    mutations = [(owner, None, None) for owner in owners]
    if group != 'attachments':
        mutations += [(owner, None, facet) for owner in owners for facet in ('class_uri', 'see_also', 'description')]
    for owner in owners:
        declaration = original['classes'][owner]
        for alias in declaration.get('attributes', {}):
            if group == 'attachments' and alias not in ('discovered-zones', 'chunk-items', 'closed', 'occupant'):
                continue
            append_qualified_alias_mutations(mutations, owner, alias, declaration)
        if declaration.get('slot_usage'):
            mutations.append((owner, None, 'slot_usage'))
    return mutations


def append_qualified_alias_mutations(mutations, owner, alias, declaration):
    mutations.extend((owner, alias, facet) for facet in ('remove', 'range', 'required', 'alias', 'slot_uri'))
    slot = declaration['attributes'][alias]
    for facet in ('minimum_cardinality', 'maximum_cardinality', 'minimum_value', 'maximum_value',
                  'multivalued', 'inlined', 'inlined_as_list', 'list_elements_unique'):
        if facet in slot:
            mutations.append((owner, alias, facet))


def mutate_qualified_slot(declaration, alias, facet):
    slot = declaration['attributes'][alias]
    if facet == 'range':
        slot[facet] = 'string'
    elif facet in ('alias', 'slot_uri'):
        slot[facet] += '-mutated'
    elif isinstance(slot[facet], bool):
        slot[facet] = not slot[facet]
    else:
        slot[facet] += 1


def verify_qualified_mutant(self, oracle, original, owner, alias, facet, directory):
    target = Path(directory) / 'schema'
    copy_schema(target)
    raw = deepcopy(original)
    declaration = raw['classes'][owner]
    if facet is None:
        del raw['classes'][owner]
    elif facet in ('class_uri', 'see_also', 'description'):
        declaration[facet] = [] if facet == 'see_also' else ''
    elif facet == 'slot_usage':
        declaration['slot_usage'] = {}
    elif facet == 'remove':
        del declaration['attributes'][alias]
    else:
        mutate_qualified_slot(declaration, alias, facet)
    (target / 'world.yaml').write_text(yaml.safe_dump(raw, sort_keys=False))
    with self.assertRaises((AssertionError, KeyError)):
        oracle(target / SCHEMA.name)


class QualifiedWorldComponentsTests(unittest.TestCase):
    def _assert_qualified_components(self, group, path):
        from ontology_source_contracts import assert_declared_root

        # Independent literal source component oracles, NOT full packet/save roots.
        # Tuple = range, multiple, inline, minimum/maximum cardinality, value bounds.
        facts = qualified_component_facts(group)
        refs = qualified_component_refs()
        raw = load_module(path.with_name('world.yaml'))
        # Raw first keeps SAME actual-YAML mutations cheap and deterministic.
        for owner, (parent, fields) in facts.items():
            verify_qualified_raw_owner(self, group, raw, owner, parent, fields, refs)
        view = SchemaView(str(path))
        schemas = {}
        for owner, (_, fields) in facts.items():
            verify_qualified_induced_fields(self, group, view, owner, fields)
            schema = (validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
                str(path), top_class=owner, preserve_names=True, not_closed=False).serialize()))
            assert_declared_root(owner, set(fields), set(fields), schema=schema, view=view)
            schemas[owner] = schema
        return schemas

    def test_qualified_discovery_components(self):
        schemas = self._assert_qualified_components('discovery', SCHEMA)
        for owner, schema in schemas.items():
            native = jsonschema.Draft201909Validator(schema)
            native.validate({'x': 0, 'y': 1})
            native.validate({'x': 4294967295, 'y': 0})
            if owner != 'cuwo-discovery-coordinate-components':
                # Abstract integer projection, not portable C++ int width or hybrid bounds.
                native.validate({'x': -1, 'y': 0})
            else:
                for bad in (-1, 4294967296):
                    with self.assertRaises(jsonschema.ValidationError):
                        native.validate({'x': bad, 'y': 0})
            for bad in ({}, {'x': 0}, {'y': 0}, [0, 1], [0], [0, 1, 2], None,
                        {'x': True, 'y': 0}, {'x': '0', 'y': 0}, {'x': 0.5, 'y': 0},
                        {'x': 0, 'y': []}, {'x': 0, 'y': None}, {'x': 0, 'y': 0, 'z': 0}):
                with self.subTest(owner=owner, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)

    def test_qualified_drop_components(self):
        schemas = self._assert_qualified_components('drop', SCHEMA)
        row = {'item': 'nominal-item', 'pos': [-1, 0, 1], 'rotation': -1.5, 'scale': -0.5, 'drop-time': 0}
        for owner, schema in schemas.items():
            verify_qualified_drop_owner(self, owner, schema, row)

    def test_qualified_static_components(self):
        schemas = self._assert_qualified_components('static', SCHEMA)
        rows = {'cuwo-static-header-components': {'entity-type': 1, 'pos': [-1, 0, 1], 'orientation': 3,
                    'size': [1.0, 2.0, 3.0], 'closed': 1, 'time-offset': 0, 'something8': 0, 'user-id': 0},
                'berld-static-header-components': {'kind': 1, 'position': [-1, 0, 1], 'orientation': 3,
                    'size': {'width': 1.0, 'depth': 2.0, 'height': 3.0}, 'is-closed': True,
                    'transform-time': 0, 'unknown-b': 0, 'interactor': 0},
                'berld-static-size-components': {'width': 1.0, 'depth': 2.0, 'height': 3.0}}
        for owner, row in rows.items():
            verify_qualified_static_row(self, schemas, owner, row)
        for owner, field, low, high in (
            ('cuwo-static-header-components', 'entity-type', 0, 4294967295),
            ('cuwo-static-header-components', 'orientation', 0, 4294967295),
            ('cuwo-static-header-components', 'closed', 0, 255),
            ('cuwo-static-header-components', 'time-offset', 0, 4294967295),
            ('cuwo-static-header-components', 'something8', 0, 4294967295),
            ('cuwo-static-header-components', 'user-id', 0, 18446744073709551615),
            ('berld-static-header-components', 'kind', -2147483648, 2147483647),
            ('berld-static-header-components', 'orientation', -128, 127),
            ('berld-static-header-components', 'transform-time', -2147483648, 2147483647),
            ('berld-static-header-components', 'unknown-b', -2147483648, 2147483647),
            ('berld-static-header-components', 'interactor', -9223372036854775808, 9223372036854775807)):
            native = jsonschema.Draft201909Validator(schemas[owner])
            # Storage bounds only; these positives do NOT authenticate enum/code/sentinel legality.
            for value in (low, high):
                native.validate(dict(rows[owner], **{field: value}))
            for value in (low - 1, high + 1, True, 0.5):
                with self.subTest(owner=owner, field=field, value=value), self.assertRaises(jsonschema.ValidationError):
                    native.validate(dict(rows[owner], **{field: value}))
        for owner, field in (('cuwo-static-header-components', 'pos'),
                             ('cuwo-static-header-components', 'size'),
                             ('berld-static-header-components', 'position')):
            native = jsonschema.Draft201909Validator(schemas[owner])
            for bad in ([0], [0, 1], [0, 1, 2, 3], [0, True, 0], [0, '1', 0]):
                with self.assertRaises(jsonschema.ValidationError):
                    native.validate(dict(rows[owner], **{field: bad}))
        native = jsonschema.Draft201909Validator(schemas['berld-static-header-components'])
        for bad in (0, 'true', None):
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(dict(rows['berld-static-header-components'], **{'is-closed': bad}))
        for bad in ([1, 2, 3], {'width': 1, 'depth': 2}, {'width': 1, 'depth': 2, 'height': True}):
            with self.assertRaises(jsonschema.ValidationError):
                native.validate(dict(rows['berld-static-header-components'], size=bad))

    def _assert_qualified_attachments(self, path):
        from ontology_source_contracts import assert_declared_root

        raw = load_module(path.with_name('world.yaml'))
        view = SchemaView(str(path))
        facts = {'world': ({'id', 'seed', 'day', 'time-ms', 'spawn-rule', 'name', 'origin-poi', 'discovered-zones'},
                           {'id', 'seed', 'day', 'time-ms', 'spawn-rule', 'discovered-zones'}),
                 'zone': ({'id', 'size-blocks', 'columns', 'spawns', 'static-entities', 'chunk-items'},
                          {'id', 'size-blocks', 'columns', 'spawns', 'static-entities', 'chunk-items'}),
                 'static-entity': ({'id', 'orientation', 'closed', 'occupant'}, {'id'})}
        for owner, alias, range_, required, multiple, inline in (
            ('world', 'discovered-zones', 'zone-coordinate', True, True, True),
            ('zone', 'chunk-items', 'dropped-item', True, True, True),
            ('static-entity', 'closed', 'boolean', False, False, False),
            ('static-entity', 'occupant', 'entity', False, False, False)):
            slot = raw['classes'][owner]['attributes'][alias]
            self.assertEqual((slot['alias'], slot['domain'], slot['slot_uri'], slot['range'], slot['required']),
                             (alias, owner, 'pixlnd:' + owner + '/' + alias, range_, required))
            self.assertEqual((bool(slot.get('multivalued')), bool(slot.get('inlined')),
                              bool(slot.get('inlined_as_list')), bool(slot.get('list_elements_unique'))),
                             (multiple, inline, inline and multiple, owner == 'world'))
            induced = view.induced_slot(alias, owner)
            self.assertEqual((induced.range, bool(induced.required), bool(induced.inlined),
                              bool(induced.multivalued), bool(induced.list_elements_unique)),
                             (range_, required, inline, multiple, owner == 'world'))
        schemas = {}
        for owner, (fields, required) in facts.items():
            schema = (validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
                str(path), top_class=owner, preserve_names=True, not_closed=False).serialize()))
            assert_declared_root(owner, fields, required, schema=schema, view=view)
            schemas[owner] = schema
        return schemas

    def test_qualified_world_attachments_and_state(self):
        # Guard every child root BEFORE admitting a nonempty collection.
        self._assert_qualified_components('discovery', SCHEMA)
        self._assert_qualified_components('drop', SCHEMA)
        schemas = self._assert_qualified_attachments(SCHEMA)
        world = {'id': 'world', 'seed': 0, 'day': 0, 'time-ms': 0,
                 'spawn-rule': 'near-village', 'discovered-zones': [{'x': -1, 'y': 0}]}
        zone = {'id': 'zone', 'size-blocks': 64, 'columns': [], 'spawns': [], 'static-entities': [],
                'chunk-items': [{'item': 'nominal-item', 'pos': [-1, 0, 1],
                                 'rotation': 0.5, 'scale': 1.5, 'drop-time': 0}]}
        for owner, row, field, bads in (
            ('world', world, 'discovered-zones', [None, {}, [None], [[0, 1]], [{'x': 0}],
                                                 [{'x': 0, 'y': True}], [{'x': 0, 'y': 0, 'z': 0}]]),
            ('zone', zone, 'chunk-items', [None, {}, [None], [{}], [{'item': {}}]])):
            native = jsonschema.Draft201909Validator(schemas[owner])
            native.validate(row)
            native.validate(dict(row, **{field: []}))
            for bad in bads:
                with self.subTest(owner=owner, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(dict(row, **{field: bad}))
            with self.assertRaises(jsonschema.ValidationError):
                native.validate({k: v for k, v in row.items() if k != field})
        # Set uniqueness is declared/induced above; native enforcement is a future probe,
        # not an excuse to replace it with a custom equality checker.
        native = jsonschema.Draft201909Validator(schemas['static-entity'])
        for row in ({'id': 'seat'}, {'id': 'door', 'orientation': 0, 'closed': False},
                    {'id': 'seat', 'occupant': 'nominal-entity'},
                    {'id': 'seat', 'closed': None, 'occupant': None}):
            native.validate(row)  # Optional native null is not historical wire null.
        for field, bads in (('orientation', [-1, 4, True, '0']),
                            ('closed', [0, 'false', [], {}]), ('occupant', [0, True, [], {}])):
            for bad in bads:
                with self.assertRaises(jsonschema.ValidationError):
                    native.validate({'id': 'object', field: bad})
        with self.assertRaises(jsonschema.ValidationError):
            native.validate({'id': 'seat', 'sat': True})

    def _qualified_same_yaml_mutations(self, group):
        oracle = self._assert_qualified_attachments if group == 'attachments' else lambda path: self._assert_qualified_components(group, path)
        oracle(SCHEMA)
        original = load_module(SCHEMA.with_name('world.yaml'))
        owners = {'discovery': ['zone-coordinate', 'cuwo-discovery-coordinate-components', 'cwsdk-zone-coordinate-components'],
                  'drop': ['dropped-item', 'cuwo-dropped-item-components', 'berld-dropped-item-components'],
                  'static': ['cuwo-static-header-components', 'berld-static-header-components', 'berld-static-size-components'],
                  'attachments': ['world', 'zone', 'static-entity']}[group]
        mutations = qualified_mutations(original, group, owners)
        for owner, alias, facet in mutations:
            with self.subTest(group=group, owner=owner, alias=alias, facet=facet), tempfile.TemporaryDirectory() as directory:
                verify_qualified_mutant(self, oracle, original, owner, alias, facet, directory)
        # Exact production oracle on the unchanged original, after every mutant.
        oracle(SCHEMA)

    def test_qualified_discovery_same_yaml_mutations(self):
        self._qualified_same_yaml_mutations('discovery')

    def test_qualified_drop_same_yaml_mutations(self):
        self._qualified_same_yaml_mutations('drop')

    def test_qualified_static_same_yaml_mutations(self):
        self._qualified_same_yaml_mutations('static')

    def test_qualified_attachments_same_yaml_mutations(self):
        self._qualified_same_yaml_mutations('attachments')


if __name__ == "__main__":
    unittest.main()
