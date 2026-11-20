"""Initial outdoor population world schema tests."""
from copy import deepcopy
import json
from pathlib import Path
import shutil
import tempfile
import unittest

import jsonschema
import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import validator


def verify_outdoor_raw_attribute(d, owner, kind, name, range_, inline, multi, lo, hi, A):
    a = d['attributes'][name]
    item = a
    assert (str(item['alias']), str(item['domain']), str(item['range']), str(item['slot_uri'])) == (name, owner, range_, 'pixlnd:' + owner + '/' + name)
    assert item['required'] and item['see_also'] == [A]
    assert (bool(item.get('inlined')), bool(item.get('multivalued')), bool(item.get('inlined_as_list'))) == (inline, multi, multi)
    assert (item.get('minimum_cardinality'), item.get('maximum_cardinality')) == (lo, hi)
    assert not any((item.get(f) for f in ('identifier', 'key', 'list_elements_unique', 'ifabsent', 'exact_cardinality')))
    if name == 'tier':
        assert (a.get('equals_number'), a.get('minimum_value'), a.get('maximum_value')) == ((1, None, None) if kind == 'camp' else (None, 0, 3))
    elif name in ('pack-assignments', 'boss-assignment'):
        assert a.get('range_expression') == ({'slot_conditions': {'tier': {'equals_number': 1}}} if kind == 'camp' else None)


def verify_outdoor_raw_owner(owner, kind, raw, A):
    assert owner in raw['classes'], 'Missing declared source class: ' + owner
    d = raw['classes'][owner]
    assert d['class_uri'] == 'pixlnd:' + owner and d['see_also'] == [A]
    assert d['is_a'] == 'initial-' + kind + '-assembly'
    assert not any((d.get(f) for f in ('slots', 'mixins', 'slot_usage')))
    assert set(d['attributes']) == {'tier', 'population', 'pack-assignments', 'boss-assignment'}
    expected_rules = [{'preconditions': {'slot_conditions': {'tier': {'equals_number': t}}}, 'postconditions': {'slot_conditions': {f: {'range_expression': {'slot_conditions': {'tier': {'equals_number': t}}}} for f in ('pack-assignments', 'boss-assignment')}}} for t in range(4)]
    assert d.get('rules', []) == (expected_rules if kind == 'rescue' else [])
    for name, range_, inline, multi, lo, hi in [('tier', 'integer', False, False, None, None), ('population', kind + '-population', True, False, None, None), ('pack-assignments', 'initial-nonboss-assignment', True, True, 2, 2), ('boss-assignment', 'initial-mission-boss-assignment', True, False, None, None)]:
        verify_outdoor_raw_attribute(d, owner, kind, name, range_, inline, multi, lo, hi, A)


def verify_outdoor_view_class(view, owner, kind, A):
    for cls in (view.get_class(owner), view.induced_class(owner)):
        assert str(cls.class_uri) == 'pixlnd:' + owner and cls.see_also == [A]
        assert cls.is_a == 'initial-' + kind + '-assembly'
        assert len(cls.rules) == (4 if kind == 'rescue' else 0)
        for t, rule in enumerate(cls.rules):
            assert set(rule.preconditions.slot_conditions) == {'tier'}
            assert rule.preconditions.slot_conditions['tier'].equals_number == t
            assert set(rule.postconditions.slot_conditions) == {'pack-assignments', 'boss-assignment'}
            for f in ('pack-assignments', 'boss-assignment'):
                assert rule.postconditions.slot_conditions[f].range_expression.slot_conditions['tier'].equals_number == t


def verify_outdoor_view_slot(view, owner, kind, name, range_, inline, multi, lo, hi, A):
    slot = view.induced_slot(name, owner)
    item = vars(slot)
    assert (str(item['alias']), str(item['domain']), str(item['range']), str(item['slot_uri'])) == (name, owner, range_, 'pixlnd:' + owner + '/' + name)
    assert item['required'] and item['see_also'] == [A]
    assert (bool(item.get('inlined')), bool(item.get('multivalued')), bool(item.get('inlined_as_list'))) == (inline, multi, multi)
    assert (item.get('minimum_cardinality'), item.get('maximum_cardinality')) == (lo, hi)
    assert not any((item.get(f) for f in ('identifier', 'key', 'list_elements_unique', 'ifabsent', 'exact_cardinality')))
    if name == 'tier':
        assert (slot.equals_number, slot.minimum_value, slot.maximum_value) == ((1, None, None) if kind == 'camp' else (None, 0, 3))
    elif name in ('pack-assignments', 'boss-assignment'):
        assert (slot.range_expression.slot_conditions['tier'].equals_number if slot.range_expression else None) == (1 if kind == 'camp' else None)


def verify_outdoor_view_owner(view, owner, kind, A, F):
    assert owner in view.all_classes(), 'Missing declared source class: ' + owner
    verify_outdoor_view_class(view, owner, kind, A)
    for name, range_, inline, multi, lo, hi in [('tier', 'integer', False, False, None, None), ('population', kind + '-population', True, False, None, None), ('pack-assignments', 'initial-nonboss-assignment', True, True, 2, 2), ('boss-assignment', 'initial-mission-boss-assignment', True, False, None, None)]:
        verify_outdoor_view_slot(view, owner, kind, name, range_, inline, multi, lo, hi, A)
    slots = view.class_induced_slots(owner)
    assert len(slots) == 8 and {s.alias or s.name for s in slots} == F
    assert [s.name for s in slots if s.identifier] == ['id']
    assert all((s.required for s in slots))
    assert view.induced_slot('initial-battlefield', owner).range == kind + '-battlefield-volume'


def verify_outdoor_schema_owner(path, view, owner, kind, F):
    from ontology_source_contracts import assert_declared_root

    schema = validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(str(path), top_class=owner, preserve_names=True, not_closed=False).serialize())
    assert_declared_root(owner, F, F, schema=schema, view=view)
    dfn = schema['$defs'][owner]
    assert len(dfn['required']) == 8
    props = dfn['properties']
    assert props['population']['$ref'] == '#/$defs/' + kind + '-population'
    assert props['boss-assignment']['$ref'] == '#/$defs/initial-mission-boss-assignment'
    packs = props['pack-assignments']
    assert (packs['type'], packs['minItems'], packs['maxItems']) == ('array', 2, 2)
    assert packs['items']['$ref'] == '#/$defs/initial-nonboss-assignment'
    assert 'uniqueItems' not in packs
    if kind == 'camp':
        for prop in (packs['items'], props['boss-assignment']):
            assert prop['allOf'] == [{'properties': {'tier': {'const': 1}}}]
    else:
        assert len(dfn['allOf']) == 4
        for t, rule in enumerate(dfn['allOf']):
            assert rule['if'] == {'properties': {'tier': {'const': t}}, 'required': ['tier']}
            for field in ('pack-assignments', 'boss-assignment'):
                assert rule['then']['properties'][field] == {'allOf': [{'properties': {'tier': {'const': t}}}]}
                assert 'items' not in rule['then']['properties'][field]


def build_outdoor_contract_mutations():
    mutations = []
    for kind in ('camp', 'rescue'):
        owner = 'initial-populated-' + kind + '-assembly'
        root = ('classes', owner)
        mutations += [('remove-' + kind, root, None),
                      ('parent-' + kind, root + ('is_a',), 'poi'),
                      ('class-uri-' + kind, root + ('class_uri',), 'pixlnd:wrong'),
                      ('class-source-' + kind, root + ('see_also',), []),
                      ('extra-attribute-' + kind, root + ('attributes', 'extra'), {'range': 'string'})]
        for field in ('tier', 'population', 'pack-assignments', 'boss-assignment'):
            keys = root + ('attributes', field)
            mutations += [(kind + '-' + field + '-' + facet, keys + (facet,), value)
                          for facet, value in [('alias', 'wrong'), ('domain', 'poi'),
                                               ('slot_uri', 'pixlnd:wrong'), ('required', False),
                                               ('see_also', []), ('range', 'string')]]
        for field in ('population', 'pack-assignments', 'boss-assignment'):
            mutations.append((kind + '-' + field + '-inline', root + ('attributes', field, 'inlined'), False))
        for facet, value in [('multivalued', False), ('inlined_as_list', False),
                             ('minimum_cardinality', 1), ('maximum_cardinality', 3)]:
            mutations.append((kind + '-packs-' + facet, root + ('attributes', 'pack-assignments', facet), value))
    camp = ('classes', 'initial-populated-camp-assembly', 'attributes')
    rescue = ('classes', 'initial-populated-rescue-assembly')
    mutations += [('camp-tier', camp + ('tier', 'equals_number'), 2),
                  ('rescue-min', rescue + ('attributes', 'tier', 'minimum_value'), -1),
                  ('rescue-max', rescue + ('attributes', 'tier', 'maximum_value'), 4),
                  ('population-swap', camp + ('population', 'range'), 'rescue-population')]
    for field in ('pack-assignments', 'boss-assignment'):
        mutations += [('camp-coupling-' + field, camp + (field, 'range_expression'), None)]
        for tier in range(4):
            mutations += [('rescue-coupling-' + str(tier) + '-' + field,
                           rescue + ('rules', tier, 'postconditions', 'slot_conditions', field,
                                     'range_expression', 'slot_conditions', 'tier', 'equals_number'), (tier + 1) % 4)]
    mutations.append(('rescue-tier3-postconditions', rescue + ('rules', 3, 'postconditions'), None))
    return mutations


def verify_outdoor_cross_tier(self, native, row, kind, tier):
    for targets in [(0,), (1,), ('boss',), (0, 1), (0, 'boss'), (1, 'boss'), (0, 1, 'boss')]:
        bad = deepcopy(row)
        for target in targets:
            assignment = bad['boss-assignment'] if target == 'boss' else bad['pack-assignments'][target]
            assignment['tier'] = (tier + 1) % 4
        with self.subTest(kind=kind, tier=tier, cross_tier=targets):
            # Domain requires agreement everywhere; rescue's conditional pack array is NOT enforced.
            self.assertEqual(native.is_valid(bad), kind == 'rescue' and 'boss' not in targets)


def outdoor_value_row(kind, tier):
    row = {'id': kind + '-example', 'located-in': 'unresolved-land',
           'battlefield': {'width': 64 if kind == 'camp' else 48,
                           'depth': 64 if kind == 'camp' else 48,
                           'below-floor': 1, 'above-floor': 16},
           'opposite-exits': [{'width-blocks': 8}, {'width-blocks': 8}], 'tier': tier,
           'population': {'packs': 2, 'pack-size': 3, 'bosses': 1, 'hostiles': 7,
                          'captives': 0 if kind == 'camp' else 1},
           'pack-assignments': [{'role': 'melee', 'tier': tier, 'boss': False},
                                {'role': 'mage', 'tier': tier, 'boss': False}],
           'boss-assignment': {'role': 'ranged', 'tier': tier, 'boss': True, 'special': 'stomp'}}
    return row


def add_outdoor_field_rows(bads, row, fields):
    for field in fields:
        bads.append(('missing-' + field, {k: v for k, v in row.items() if k != field}))
        types = ([None, False, True, 0, [], {}] if field in ('id', 'located-in') else
                 [None, False, True, 'wrong', [], {}] if field == 'tier' else
                 [None, False, 'wrong', 0, [], {}])
        for value in types:
            bad = deepcopy(row)
            bad[field] = value
            bads.append(('type-' + field, bad))


def add_outdoor_shape_rows(bads, row):
    for value in (None, [], [row], False, 0, 'reference'):
        bads.append(('root', value))
    for field in row['population']:
        bad = deepcopy(row)
        bad['population'][field] += 1
        bads.append(('population-' + field, bad))
    for field in row['battlefield']:
        bad = deepcopy(row)
        bad['battlefield'][field] += 1
        bads.append(('geometry-' + field, bad))
    for count in (0, 1, 3):
        bad = deepcopy(row)
        bad['pack-assignments'] = [deepcopy(row['pack-assignments'][0]) for _ in range(count)]
        bads.append(('pack-count', bad))
    for index in (0, 1):
        for value in (None, 'reference', False, [], {},
                      dict(row['pack-assignments'][index], special='stomp'),
                      dict(row['pack-assignments'][index], spirit='spirit-fire')):
            bad = deepcopy(row)
            bad['pack-assignments'][index] = value
            bads.append(('pack-member', bad))


def add_outdoor_misc_rows(bads, row, kind):
    for value in ((0, 2) if kind == 'camp' else (-1, 4)):
        bads.append(('tier-bound', dict(row, tier=value)))
    bads += [('id-pattern', dict(row, id='Bad Key!')), ('extra', dict(row, extra=True))]
    bad = deepcopy(row)
    bad['opposite-exits'][1]['width-blocks'] = 9
    bads.append(('exit-width', bad))
    for field in ('special', 'spirit'):
        bad = deepcopy(row)
        if field == 'special':
            del bad['boss-assignment']['special']
        else:
            bad['boss-assignment']['spirit'] = 'spirit-fire'
        bads.append(('boss-' + field, bad))


def verify_outdoor_boolean_flip(self, native, row):
    for target in (0, 1, 'boss'):
        bad = deepcopy(row)
        assignment = bad['boss-assignment'] if target == 'boss' else bad['pack-assignments'][target]
        assignment['boss'] = not assignment['boss']
        self.assertTrue(native.is_valid(bad))  # Existing equals_expression Boolean ceiling.


def build_outdoor_native_changed(original, label, camp, rescue):
    changed = deepcopy(original)
    if label == 'tier3-postconditions':
        del changed['classes'][rescue]['rules'][3]['postconditions']
    elif label == 'count-three':
        changed['classes'][camp]['attributes']['pack-assignments'].update(
            minimum_cardinality=3, maximum_cardinality=3)
    else:
        changed['classes'][camp]['attributes']['population']['range'] = 'rescue-population'
    return changed


def outdoor_native_row(owner, rescue):
    tier = 3 if owner == rescue else 1
    row = {'id': 'site-example', 'located-in': 'unresolved-land',
           'battlefield': {'width': 48 if owner == rescue else 64,
                           'depth': 48 if owner == rescue else 64,
                           'below-floor': 1, 'above-floor': 16},
           'opposite-exits': [{'width-blocks': 8}, {'width-blocks': 8}], 'tier': tier,
           'population': {'packs': 2, 'pack-size': 3, 'bosses': 1, 'hostiles': 7,
                          'captives': 1 if owner == rescue else 0},
           'pack-assignments': [{'role': 'melee', 'tier': tier, 'boss': False} for _ in range(2)],
           'boss-assignment': {'role': 'mage', 'tier': tier, 'boss': True, 'special': 'charge'}}
    return row


def verify_outdoor_native_mutation_rows(self, owner, rescue, row, baseline, mutant, label):
    if owner == rescue:
        for index in (0, 1):
            bad = deepcopy(row)
            bad['pack-assignments'][index]['tier'] = 0
            self.assertTrue(baseline.is_valid(bad) and mutant.is_valid(bad))
        bad = deepcopy(row)
        bad['boss-assignment']['tier'] = 0
        self.assertFalse(baseline.is_valid(bad))
        self.assertTrue(mutant.is_valid(bad))
    else:
        bad = deepcopy(row)
        if label == 'count-three':
            bad['pack-assignments'].append(deepcopy(bad['pack-assignments'][0]))
        else:
            bad['population']['captives'] = 1
        self.assertFalse(baseline.is_valid(bad))
        self.assertTrue(mutant.is_valid(bad))


class LogicalWorldTests(unittest.TestCase):
    def _assert_initial_outdoor_population_contract(self, path):
        C = 'initial-populated-camp-assembly'
        S = 'initial-populated-rescue-assembly'
        F = {'id', 'located-in', 'battlefield', 'opposite-exits', 'tier', 'population', 'pack-assignments', 'boss-assignment'}
        A = '../domain/encounter-contracts.md#populations-tiers-and-clear-conditions'
        raw = yaml.safe_load(path.with_name('world.yaml').read_text())
        for owner, kind in ((C, 'camp'), (S, 'rescue')):
            verify_outdoor_raw_owner(owner, kind, raw, A)
        view = SchemaView(str(path))
        for owner, kind in ((C, 'camp'), (S, 'rescue')):
            verify_outdoor_view_owner(view, owner, kind, A, F)
        for owner, kind in ((C, 'camp'), (S, 'rescue')):
            verify_outdoor_schema_owner(path, view, owner, kind, F)

    def test_initial_outdoor_population_contracts(self):
        self._assert_initial_outdoor_population_contract(SCHEMA)
        original = yaml.safe_load(SCHEMA.with_name('world.yaml').read_text())
        mutations = build_outdoor_contract_mutations()
        with tempfile.TemporaryDirectory(prefix='outdoor-population-contract-') as directory:
            target = Path(directory) / 'schema'
            shutil.copytree(SCHEMA.parent, target)
            for label, keys, value in mutations:
                changed = deepcopy(original)
                cursor = changed
                for key in keys[:-1]:
                    cursor = cursor[key]
                if value is None:
                    del cursor[keys[-1]]
                else:
                    cursor[keys[-1]] = value
                (target / 'world.yaml').write_text(yaml.safe_dump(changed, sort_keys=False))
                with self.subTest(mutation=label), self.assertRaises(AssertionError):
                    self._assert_initial_outdoor_population_contract(target / SCHEMA.name)

    def test_initial_outdoor_population_values(self):
        from ontology_source_contracts import assert_declared_root

        fields = {'id', 'located-in', 'battlefield', 'opposite-exits', 'tier', 'population',
                  'pack-assignments', 'boss-assignment'}
        view = SchemaView(str(SCHEMA))
        for owner in ('initial-populated-camp-assembly', 'initial-populated-rescue-assembly'):
            self.assertTrue(owner in view.all_classes(), 'Missing declared source class: ' + owner)
            assert_declared_root(owner, fields, fields, view=view, schema=validator(owner).schema)
        for kind, tier in [('camp', 1), ('rescue', 0), ('rescue', 1), ('rescue', 2), ('rescue', 3)]:
            owner = 'initial-populated-' + kind + '-assembly'
            native = validator(owner)
            row = outdoor_value_row(kind, tier)
            native.validate(row)
            repeated = deepcopy(row)
            repeated['pack-assignments'][1] = deepcopy(repeated['pack-assignments'][0])
            native.validate(repeated)  # Independent assignments may coincide, not unique IDs.
            alternative = deepcopy(row)
            alternative.update(id='wrong', **{'located-in': 'unresolved-land-alternative'})
            native.validate(alternative)  # Patterned ID, typed reference; no FK assertion.
            verify_outdoor_cross_tier(self, native, row, kind, tier)
            bads = []
            add_outdoor_field_rows(bads, row, fields)
            add_outdoor_shape_rows(bads, row)
            add_outdoor_misc_rows(bads, row, kind)
            for label, bad in bads:
                with self.subTest(kind=kind, tier=tier, malformed=label), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)
            verify_outdoor_boolean_flip(self, native, row)

    def test_initial_outdoor_population_native_mutations(self):
        from ontology_source_contracts import assert_declared_root

        self._assert_initial_outdoor_population_contract(SCHEMA)
        original = yaml.safe_load(SCHEMA.with_name('world.yaml').read_text())
        fields = {'id', 'located-in', 'battlefield', 'opposite-exits', 'tier', 'population',
                  'pack-assignments', 'boss-assignment'}
        camp, rescue = 'initial-populated-camp-assembly', 'initial-populated-rescue-assembly'
        with tempfile.TemporaryDirectory(prefix='outdoor-population-native-') as directory:
            for label, owner in [('tier3-postconditions', rescue), ('count-three', camp), ('population-swap', camp)]:
                target = Path(directory) / label
                shutil.copytree(SCHEMA.parent, target)
                changed = build_outdoor_native_changed(original, label, camp, rescue)
                (target / 'world.yaml').write_text(yaml.safe_dump(changed, sort_keys=False))
                self.assertEqual(yaml.safe_load((target / 'world.yaml').read_text()), changed)
                path = target / SCHEMA.name
                with self.subTest(mutation=label), self.assertRaises(AssertionError):
                    self._assert_initial_outdoor_population_contract(path)
                emitted = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                                                        preserve_names=True, not_closed=False).serialize())
                assert_declared_root(owner, fields, fields, schema=emitted, view=SchemaView(str(path)))
                baseline, mutant = validator(owner), jsonschema.Draft201909Validator(emitted)
                row = outdoor_native_row(owner, rescue)
                self.assertTrue(baseline.is_valid(row))
                self.assertEqual(mutant.is_valid(row), owner == rescue)
                verify_outdoor_native_mutation_rows(self, owner, rescue, row, baseline, mutant, label)
                # A tier-rule mutation does not fix the inherited Boolean-expression limitation.
                boolean = deepcopy(row)
                boolean['boss-assignment']['boss'] = False
                self.assertTrue(baseline.is_valid(boolean))


if __name__ == "__main__":
    unittest.main()
