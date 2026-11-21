"""Initial ruins population value and mutation world schema tests."""
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
from test_ontology_schema_world_ruins_population import RuinsPopulationMixin


def ruins_value_case_builders(row):
    cases = []
    def case(label, root, value, intended, reason):
        cases.append(dict(label=label, root=root, value=deepcopy(value), source_intended_admission=intended, reason=reason))
    def change(label, path, value=None, remove=False, intended=False, reason='typed structural boundary', root='assembly'):
        w = deepcopy(row if root == 'assembly' else row['rooms'][1])
        cur = w
        for key in path[:-1]:
            cur = cur[key]
        if remove:
            del cur[path[-1]]
        else:
            cur[path[-1]] = value
        case(label, root, w, intended, reason)
    return cases, case, change


def add_ruins_semantic_cases(case, row):
    from itertools import permutations

    semantic = []
    for order in permutations((1, 2, 3)):
        value = deepcopy(row)
        value['rooms'] = [deepcopy(row['rooms'][t - 1]) for t in order]
        semantic.append({'label': 'permutation-' + ''.join(map(str, order)), 'value': value,
                         'expected_same_whole_list': order == (1, 2, 3)})
    for order in ((1, 1, 3), (1, 2, 2), (2, 2, 3), (1, 1, 1), (2, 2, 2), (3, 3, 3), (1, 3), (1, 2)):
        value = deepcopy(row)
        value['rooms'] = [deepcopy(row['rooms'][t - 1]) for t in order]
        semantic.append({'label': 'duplicate-or-missing-' + ''.join(map(str, order)),
                         'value': value, 'expected_same_whole_list': False})
    for s in semantic:
        case(s['label'], 'assembly', s['value'], s['expected_same_whole_list'], 'exact whole-slot order plus cardinality; SDK is not native admission')


def add_ruins_root_cases(case, change, row):
    for value in (None, [], [row], False, True, 0, 'reference', {}):
        case('assembly-root-' + repr(value)[:25], 'assembly', value, False, 'closed typed complete root')
        case('room-root-' + repr(value)[:25], 'room', value, False, 'closed identity-free typed room root')
    for key in row:
        change('assembly-missing-' + key, [key], remove=True)
        change('assembly-null-' + key, [key], None)
        change('assembly-wrong-' + key, [key], False)


def add_ruins_room_key_cases(change, row):
    for key in ('width', 'depth', 'below-floor', 'above-floor', 'tier', 'pack-assignment'):
        change('room-missing-' + key, [key], remove=True, root='room')
        change('room-null-' + key, [key], None, root='room')
        change('room-wrong-' + key, [key], False, root='room')
    for key in ('extra','id','room_levels','hp','survivors','policy','position','receipt','room-list'):
        change('room-unknown-' + key, [key], True, root='room')
        if key != 'id':
            change('assembly-unknown-' + key, [key], True)
    for count in (0,1,2,4):
        change('room-count-' + str(count), ['rooms'], [deepcopy(row['rooms'][i % 3]) for i in range(count)], reason='inherited exact3 rooms')


def add_ruins_room_member_cases(change, row, i):
    for value in (None, 'reference', False, [], {}):
        change('room-member-' + str(i) + '-' + repr(value), ['rooms',i], value)
    for f in ('width','depth','below-floor','above-floor'):
        change('geometry-room-' + str(i) + '-' + f, ['rooms',i,f], row['rooms'][i][f] + 1)
    for value in (False,True,'1',1.5,0,4):
        change('room-tier-' + str(i) + '-' + repr(value), ['rooms',i,'tier'], value)
        change('pack-tier-type-' + str(i) + '-' + repr(value), ['rooms',i,'pack-assignment','tier'], value,
               reason='integer typing or room/pack tier agreement')
    change('pack-mismatch-' + str(i), ['rooms',i,'pack-assignment','tier'], 1 if i else 2, reason='singleton room/pack tier agreement')
    for value in ([], 'reference', None, {}, False):
        change('pack-shape-' + str(i) + '-' + repr(value), ['rooms',i,'pack-assignment'], value)


def add_ruins_room_pack_cases(change, i):
    for f in ('role','tier','boss'):
        change('pack-missing-' + str(i) + '-' + f, ['rooms',i,'pack-assignment',f], remove=True)
    for f in ('special','spirit'):
        for value in (None, 'stomp' if f == 'special' else 'spirit-fire'):
            change('nonboss-' + str(i) + '-' + f + '-' + repr(value), ['rooms',i,'pack-assignment',f], value, reason='nonboss presence forbidden including null')
    change('pack-extra-' + str(i), ['rooms',i,'pack-assignment','id'], 'invented')
    change('pack-boolean-flip-' + str(i), ['rooms',i,'pack-assignment','boss'], True, reason='inherited known equals_expression Boolean native limit')
    for role in ('melee','ranged','mage'):
        change('pack-role-positive-' + str(i) + '-' + role, ['rooms',i,'pack-assignment','role'], role, intended=True)


def add_ruins_boss_cases(change, i):
    change('boss-mismatch-' + str(i), ['rooms',i,'boss-assignment','tier'], 1, reason='room/boss singleton tier agreement')
    change('boss-missing-' + str(i), ['rooms',i,'boss-assignment'], remove=True, reason='t2/3 boss present and nonnull')
    for value in (None, [], 'reference', False, {}):
        change('boss-shape-' + str(i) + '-' + repr(value), ['rooms',i,'boss-assignment'], value)
    for f in ('role','tier','boss','special','spirit'):
        change('boss-field-missing-' + str(i) + '-' + f, ['rooms',i,'boss-assignment',f], remove=True)
        change('boss-field-null-' + str(i) + '-' + f, ['rooms',i,'boss-assignment',f], None)
    for f in ('special','spirit'):
        change('boss-invalid-' + str(i) + '-' + f, ['rooms',i,'boss-assignment',f], 'invalid')
    for value in (False, True, '2', 2.5):
        change('boss-tier-type-' + str(i) + '-' + repr(value), ['rooms',i,'boss-assignment','tier'], value)
    change('boss-extra-' + str(i), ['rooms',i,'boss-assignment','id'], 'invented')
    change('boss-boolean-flip-' + str(i), ['rooms',i,'boss-assignment','boss'], False, reason='inherited known equals_expression Boolean native limit')
    for role in ('melee','ranged','mage'):
        change('boss-role-positive-' + str(i) + '-' + role, ['rooms',i,'boss-assignment','role'], role, intended=True)
    for value in ('stomp','charge'):
        change('boss-special-positive-' + str(i) + '-' + value, ['rooms',i,'boss-assignment','special'], value, intended=True)
    for value in ('spirit-fire','spirit-unholy','spirit-ice','spirit-wind'):
        change('boss-spirit-positive-' + str(i) + '-' + value, ['rooms',i,'boss-assignment','spirit'], value, intended=True)


def add_ruins_population_cases(change, row):
    for value in (None, dict(row['rooms'][1]['boss-assignment'],tier=1)):
        change('t1-boss-supplied-' + repr(value), ['rooms',0,'boss-assignment'], value, reason='tier1 boss must be absent, not null')
    for f,v in row['population'].items():
        change('population-count-' + f, ['population',f], v+1)
        change('population-missing-' + f, ['population',f], remove=True)
        for value in (False,True):
            change('population-bool-' + f + '-' + str(value), ['population',f], value)


def add_ruins_geometry_cases(case, change, row):
    for f in ('horizontal-bounds-width-blocks','horizontal-bounds-depth-blocks','clear-ceiling-height-blocks','door-width-blocks','door-height-blocks','corridor-trap-free-lane-width-blocks'):
        change('assembly-geometry-' + f, [f], row[f]+1)
    for f in ('corridors','entrance-court','entrance-passage','reward-alcove'):
        for k in ('width','depth','below-floor','above-floor'):
            path = [f,0,k] if f == 'corridors' else [f,k]
            value = row[f][0][k] if f == 'corridors' else row[f][k]
            change('component-geometry-' + f + '-' + k, path, value+1)
    for i in range(3):
        case('complete-room-positive-' + str(i+1), 'room', row['rooms'][i], True, 'tier-specific complete room')


def ruins_mutation_adder():
    mutations = []
    def add(label, keys, value=None, module='world.yaml'):
        mutations.append({'label':label, 'module':module, 'keys':list(keys), 'replacement':value})
    return mutations, add


def add_ruins_owner_mutations(add, room, assembly):
    for owner, fields in [(room, ('tier','pack-assignment','boss-assignment')), (assembly, ('population',))]:
        root=('classes',owner)
        for facet, value in [('class',None),('is_a','poi'),('class_uri','pixlnd:wrong'),('see_also',[]),('description','changed'),('slots',['id']),('mixins',['poi'])]:
            add(owner+'-'+facet, root if facet=='class' else root+(facet,), value)
        for field in fields:
            keys=root+('attributes',field)
            add(owner+'-'+field+'-removed', keys)
            for facet,value in [('alias','wrong'),('domain','poi'),('slot_uri','pixlnd:wrong'),('range','string'),('see_also',[]),('description','changed'),('identifier',True),('key',True),('multivalued',True),('inlined_as_list',True),('minimum_cardinality',1),('maximum_cardinality',2)]:
                add(owner+'-'+field+'-'+facet,keys+(facet,),value)
            add(owner+'-'+field+'-required',keys+('required',),field=='boss-assignment')
            add(owner+'-'+field+'-inlined',keys+('inlined',),field=='tier')


def add_ruins_tier_mutations(add, room, assembly):
    for facet,value in [('minimum_value',0),('maximum_value',4)]:
        add('room-tier-'+facet,('classes',room,'attributes','tier',facet),value)
    root=('classes',assembly,'slot_usage','rooms')
    for facet,value in [('range','ruins-room-volume'),('list_elements_ordered',False),('equals_expression',None),('equals_expression','rooms')]:
        add('contextual-rooms-'+facet+('-loss' if value is None else '-changed'),root+(facet,),value)
    add('room-rules-loss',('classes',room,'rules'))


def add_ruins_rule_mutations(add, room):
    for i,tier in enumerate((1,2,3)):
        root=('classes',room,'rules',i)
        add('rule-'+str(tier)+'-precondition',root+('preconditions','slot_conditions','tier','equals_number'),0)
        add('rule-'+str(tier)+'-pack-tier',root+('postconditions','slot_conditions','pack-assignment','range_expression','slot_conditions','tier','equals_number'),0)
        add('rule-'+str(tier)+'-presence',root+('postconditions','slot_conditions','boss-assignment','value_presence'),'PRESENT' if tier==1 else 'ABSENT')
        if tier != 1:
            for facet,value in [('range','initial-mission-boss-assignment'),('inlined',False),('range_expression',None)]:
                add('rule-'+str(tier)+'-boss-'+facet,root+('postconditions','slot_conditions','boss-assignment',facet),value)


def add_ruins_parent_mutations(add):
    for facet,value in [('range','encounter-volume'),('required',False),('inlined',False),('inlined_as_list',False),('multivalued',False),('minimum_cardinality',2),('maximum_cardinality',4),('alias','wrong'),('domain','poi'),('slot_uri','pixlnd:wrong')]:
        add('parent-rooms-'+facet,('classes','initial-ruins-assembly','attributes','rooms',facet),value)
    add('geometry-room-width',('classes','ruins-room-volume','slot_usage','width','equals_number'),25)
    add('geometry-bounds',('classes','initial-ruins-assembly','attributes','horizontal-bounds-width-blocks','equals_number'),37)
    add('identity-loss',('slots','id','identifier'),False,'identity.yaml')
    add('land-range',('slots','located-in','range'),'string','relations.yaml')


def verify_ruins_mutation_case(self, case, baseline, target, path):
    original = baseline[case['module']]
    changed = deepcopy(original)
    cursor = changed
    for key in case['keys'][:-1]:
        cursor = cursor[key]
    if case['replacement'] is None:
        del cursor[case['keys'][-1]]
    else:
        cursor[case['keys'][-1]] = case['replacement']
    module = target / case['module']
    module.write_text(yaml.safe_dump(changed, sort_keys=False))
    self.assertEqual(yaml.safe_load(module.read_text()), changed)
    with self.subTest(mutation=case['label']), self.assertRaises(AssertionError):
        self._assert_initial_ruins_population_contract(path)
    shutil.copyfile(SCHEMA.parent / case['module'], module)


def verify_ruins_order_none(self, orders, row, mutant_view, assembly, config):
    from jsonasobj2 import JsonObj, as_dict
    from linkml_runtime.utils.inference_utils import generate_slot_value

    for order in orders:
        value = deepcopy(row)
        value['rooms'] = [deepcopy(row['rooms'][t - 1]) for t in order]
        before = deepcopy(value)
        obj = JsonObj(value)
        object_before = deepcopy(as_dict(obj))
        self.assertIsNone(generate_slot_value(obj, 'rooms', mutant_view, class_name=assembly, config=config))
        self.assertEqual(value, before)
        self.assertEqual(as_dict(obj), object_before)


def verify_ruins_order_loss_schema(self, path, assembly, room, fields, mutant_view, schemas, orders, row):
    from ontology_source_contracts import assert_declared_root

    emitted = json.loads(JsonSchemaGenerator(str(path), top_class=assembly,
                                            preserve_names=True, not_closed=False).serialize())
    assert_declared_root(assembly, fields, fields, schema=emitted, view=mutant_view)
    self.assertEqual(len(emitted['$defs'][assembly]['required']), 14)
    for owner in (assembly, room, 'initial-ruins-assembly', 'ruins-room-volume'):
        self.assertEqual(emitted['$defs'][owner], schemas[assembly]['$defs'][owner])
    native = jsonschema.Draft201909Validator(emitted)
    baseline_native = jsonschema.Draft201909Validator(schemas[assembly])
    for order in orders[:6]:
        value = deepcopy(row)
        value['rooms'] = [deepcopy(row['rooms'][t - 1]) for t in order]
        self.assertTrue(baseline_native.is_valid(value))
        self.assertTrue(native.is_valid(value))


def verify_ruins_tier_zero(self, baseline, room, module, path, room_fields, required, schemas, view, row):
    from ontology_source_contracts import assert_declared_root

    # Only room tier minimum1→0; a concrete native broadening, independent of order.
    changed = deepcopy(baseline['world.yaml'])
    changed['classes'][room]['attributes']['tier']['minimum_value'] = 0
    module.write_text(yaml.safe_dump(changed, sort_keys=False))
    self.assertEqual(yaml.safe_load(module.read_text()), changed)
    with self.assertRaises(AssertionError):
        self._assert_initial_ruins_population_contract(path)
    mutant_view = SchemaView(str(path))
    emitted = json.loads(JsonSchemaGenerator(str(path), top_class=room,
                                            preserve_names=True, not_closed=False).serialize())
    assert_declared_root(room, room_fields, required, schema=emitted, view=mutant_view)
    assert_declared_root(room, room_fields, required, schema=schemas[room], view=view)
    self.assertEqual(len(emitted['$defs'][room]['required']), 6)
    self.assertEqual(emitted['$defs'][room]['properties']['tier']['minimum'], 0)
    zero = deepcopy(row['rooms'][0])
    zero['tier'] = 0
    self.assertIs(type(zero['tier']), int)
    baseline_room = jsonschema.Draft201909Validator(schemas[room])
    native = jsonschema.Draft201909Validator(emitted)
    self.assertEqual([e.validator for e in baseline_room.iter_errors(zero)], ['minimum'])
    self.assertTrue(native.is_valid(zero))
    self.assertTrue(baseline_room.is_valid(row['rooms'][0]))
    self.assertTrue(native.is_valid(row['rooms'][0]))


class LogicalWorldTests(RuinsPopulationMixin, unittest.TestCase):
    def test_initial_ruins_population_values(self):
        _, schemas = self._assert_initial_ruins_population_contract(SCHEMA)
        row = self._initial_ruins_population_witness()
        for room in row['rooms']:
            self.assertIs(type(room['tier']), int)
            self.assertIs(type(room['pack-assignment']['boss']), bool)
            self.assertIs(room['pack-assignment']['boss'], False)
            if 'boss-assignment' in room:
                self.assertIs(type(room['boss-assignment']['boss']), bool)
                self.assertIs(room['boss-assignment']['boss'], True)
        cases, case, change = ruins_value_case_builders(row)
        add_ruins_semantic_cases(case, row)
        add_ruins_root_cases(case, change, row)
        add_ruins_room_key_cases(change, row)
        for i in range(3):
            add_ruins_room_member_cases(change, row, i)
            add_ruins_room_pack_cases(change, i)
        for i in (1, 2):
            add_ruins_boss_cases(change, i)
        add_ruins_population_cases(change, row)
        add_ruins_geometry_cases(case, change, row)
        self.assertEqual((len(cases), len({c['label'] for c in cases})), (343, 343))
        # Exactly the measured source-intended negatives admitted by this backend.
        gaps = {'permutation-132', 'permutation-213', 'permutation-231', 'permutation-312', 'permutation-321',
                'duplicate-or-missing-113', 'duplicate-or-missing-122', 'duplicate-or-missing-223',
                'duplicate-or-missing-111', 'duplicate-or-missing-222', 'duplicate-or-missing-333',
                'pack-boolean-flip-0', 'pack-boolean-flip-1', 'pack-boolean-flip-2',
                'boss-shape-1-None', 'boss-shape-2-None', 'boss-boolean-flip-1', 'boss-boolean-flip-2'}
        self.assertEqual(len(gaps), 18)
        self.assertEqual(sum(c['source_intended_admission'] for c in cases), 31)
        natives = {'assembly': jsonschema.Draft201909Validator(schemas['initial-populated-ruins-assembly']),
                   'room': jsonschema.Draft201909Validator(schemas['initial-populated-ruins-room'])}
        admitted, disagreements = [], []
        for c in cases:
            before = deepcopy(c['value'])
            observed = natives[c['root']].is_valid(c['value'])
            with self.subTest(witness=c['label'], source_intended=c['source_intended_admission']):
                self.assertIs(type(c['source_intended_admission']), bool)
                self.assertEqual(observed, c['source_intended_admission'] or c['label'] in gaps)
                self.assertEqual(c['value'], before)
            if observed:
                admitted.append(c['label'])
            if observed != c['source_intended_admission']:
                disagreements.append(c['label'])
        self.assertEqual((len(admitted), len(cases) - len(admitted)), (49, 294))
        self.assertEqual(set(disagreements), gaps)
        print('ruins native: 343 cases, 31 intended positives, 49 admissions, 294 rejections; 18 negative admissions')

    def test_initial_ruins_population_native_mutations(self):
        from itertools import permutations

        from linkml_runtime.utils.inference_utils import Config

        view, schemas = self._assert_initial_ruins_population_contract(SCHEMA)
        room, assembly = 'initial-populated-ruins-room', 'initial-populated-ruins-assembly'
        mutations, add = ruins_mutation_adder()
        add_ruins_owner_mutations(add, room, assembly)
        add_ruins_tier_mutations(add, room, assembly)
        add_ruins_rule_mutations(add, room)
        add_ruins_parent_mutations(add)
        assert len({m['label'] for m in mutations}) == len(mutations)
        self.assertEqual(len(mutations), 110)
        baseline = {name: yaml.safe_load((SCHEMA.parent / name).read_text())
                    for name in ('world.yaml', 'identity.yaml', 'relations.yaml')}
        # Copy the ACTUAL repository import graph; never edit generated definitions.
        with tempfile.TemporaryDirectory(prefix='ruins-population-mutations-') as directory:
            target = Path(directory) / 'schema'
            shutil.copytree(SCHEMA.parent, target)
            path = target / SCHEMA.name
            for case in mutations:
                verify_ruins_mutation_case(self, case, baseline, target, path)
            fields = {'id', 'located-in', 'rooms', 'corridors', 'entrance-court', 'entrance-passage',
                      'reward-alcove', 'horizontal-bounds-width-blocks', 'horizontal-bounds-depth-blocks',
                      'clear-ceiling-height-blocks', 'door-width-blocks', 'door-height-blocks',
                      'corridor-trap-free-lane-width-blocks', 'population'}
            room_fields = {'width', 'depth', 'below-floor', 'above-floor', 'tier', 'pack-assignment', 'boss-assignment'}
            required = {'width', 'depth', 'below-floor', 'above-floor', 'tier', 'pack-assignment'}
            row = self._initial_ruins_population_witness()
            orders = [*permutations((1, 2, 3)), (1, 1, 3), (1, 2, 2), (2, 2, 3),
                      (1, 1, 1), (2, 2, 2), (3, 3, 3), (1, 3), (1, 2)]
            self.assertEqual(len(orders), 14)
            changed = deepcopy(baseline['world.yaml'])
            del changed['classes'][assembly]['slot_usage']['rooms']['equals_expression']
            module = target / 'world.yaml'
            module.write_text(yaml.safe_dump(changed, sort_keys=False))
            self.assertEqual(yaml.safe_load(module.read_text()), changed)
            with self.assertRaises(AssertionError):
                self._assert_initial_ruins_population_contract(path)
            mutant_view = SchemaView(str(path))
            self.assertIsNone(mutant_view.induced_slot('rooms', assembly).equals_expression)
            config = Config(use_expressions=True, use_string_serialization=False, use_rules=False)
            verify_ruins_order_none(self, orders, row, mutant_view, assembly, config)
            verify_ruins_order_loss_schema(
                self, path, assembly, room, fields, mutant_view, schemas, orders, row)
            verify_ruins_tier_zero(
                self, baseline, room, module, path, room_fields, required, schemas, view, row)
        print('ruins mutations: all110 SAME-oracle metadata cases; order loss SDK14 None/native6 no-effect; tier0 broadening')


if __name__ == "__main__":
    unittest.main()
