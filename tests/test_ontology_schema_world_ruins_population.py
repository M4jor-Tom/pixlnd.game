"""Initial ruins population contracts; hosts the shared RuinsPopulationMixin."""
from copy import deepcopy
import json
import unittest

import yaml
from linkml.generators.jsonschemagen import JsonSchemaGenerator
from linkml_runtime.utils.schemaview import SchemaView

from test_ontology_schema import SCHEMA
from test_ontology_schema_authoring import validator


def ruins_expected():
    expected = yaml.safe_load("""
  initial-populated-ruins-room:
    class_uri: pixlnd:initial-populated-ruins-room
    description: "The same contained ruins room volume with its designated tier, one shared three-guard pack assignment and a separate boss only in rooms two and three; not mutable survivors or saved room levels."
    see_also: ["../domain/encounter-contracts.md#geometry-and-occupancy", "../domain/encounter-contracts.md#populations-tiers-and-clear-conditions"]
    is_a: ruins-room-volume
    attributes:
      tier: {alias: tier, domain: initial-populated-ruins-room, slot_uri: "pixlnd:initial-populated-ruins-room/tier", range: integer, required: true, minimum_value: 1, maximum_value: 3, description: "Designated room tier green, blue or purple, not an occurrence identifier.", see_also: ["../domain/encounter-contracts.md#populations-tiers-and-clear-conditions"]}
      pack-assignment: {alias: pack-assignment, domain: initial-populated-ruins-room, slot_uri: "pixlnd:initial-populated-ruins-room/pack-assignment", range: initial-nonboss-assignment, required: true, inlined: true, description: "One permanent singleton assignment shared by the designated three-guard pack of this room; not three independent member assignments.", see_also: ["../domain/encounter-contracts.md#populations-tiers-and-clear-conditions"]}
      boss-assignment: {alias: boss-assignment, domain: initial-populated-ruins-room, slot_uri: "pixlnd:initial-populated-ruins-room/boss-assignment", range: initial-ruins-boss-assignment, inlined: true, description: "Separate permanent non-mission boss assignment, absent in room one and present in rooms two and three at their room tier; existing special and spirit scope is retained.", see_also: ["../domain/encounter-contracts.md#populations-tiers-and-clear-conditions"]}
    rules:
    - preconditions:
        slot_conditions:
          tier: {equals_number: 1}
      postconditions:
        slot_conditions:
          pack-assignment: {range_expression: {slot_conditions: {tier: {equals_number: 1}}}}
          boss-assignment: {value_presence: ABSENT}
    - preconditions:
        slot_conditions:
          tier: {equals_number: 2}
      postconditions:
        slot_conditions:
          pack-assignment: {range_expression: {slot_conditions: {tier: {equals_number: 2}}}}
          boss-assignment: {value_presence: PRESENT, range: initial-ruins-boss-assignment, inlined: true, range_expression: {slot_conditions: {tier: {equals_number: 2}}}}
    - preconditions:
        slot_conditions:
          tier: {equals_number: 3}
      postconditions:
        slot_conditions:
          pack-assignment: {range_expression: {slot_conditions: {tier: {equals_number: 3}}}}
          boss-assignment: {value_presence: PRESENT, range: initial-ruins-boss-assignment, inlined: true, range_expression: {slot_conditions: {tier: {equals_number: 3}}}}
  initial-populated-ruins-assembly:
    class_uri: pixlnd:initial-populated-ruins-assembly
    description: "Initial ruins geometry refined on the same three contained room occurrences with ordered green, blue, purple allocations and its complete designated population; not a configuration or saved payload."
    see_also: ["../domain/encounter-contracts.md#geometry-and-occupancy", "../domain/encounter-contracts.md#populations-tiers-and-clear-conditions"]
    is_a: initial-ruins-assembly
    slot_usage:
      rooms:
        range: initial-populated-ruins-room
        list_elements_ordered: true
        equals_expression: "rooms if rooms.tier == [1, 2, 3] else []"
    attributes:
      population: {alias: population, domain: initial-populated-ruins-assembly, slot_uri: "pixlnd:initial-populated-ruins-assembly/population", range: ruins-population, required: true, inlined: true, description: "Complete designated three packs of three and two separate bosses, not surviving or spawned state.", see_also: ["../domain/encounter-contracts.md#populations-tiers-and-clear-conditions"]}
""")
    return expected


def verify_ruins_parent(self, parent, assembly_fields, geo):
    self.assertEqual((parent['is_a'], parent['slots']), ('dungeon', ['located-in']))
    self.assertEqual(set(parent['attributes']), assembly_fields - {'id', 'located-in', 'population'})
    geometry = {'horizontal-bounds-width-blocks': 36, 'horizontal-bounds-depth-blocks': 112,
                'clear-ceiling-height-blocks': 6, 'door-width-blocks': 4,
                'door-height-blocks': 5, 'corridor-trap-free-lane-width-blocks': 4}
    parent_local = {'rooms': ('ruins-room-volume', True, True, 3, 3),
                    'corridors': ('ruins-corridor-volume', True, True, 1, None),
                    'entrance-court': ('ruins-court-volume', False, True, None, None),
                    'entrance-passage': ('ruins-passage-volume', False, True, None, None),
                    'reward-alcove': ('ruins-alcove-volume', False, True, None, None)}
    parent_local.update({f: ('double', False, False, None, None) for f in geometry})
    for name, (range_, multi, inline, lo, hi) in parent_local.items():
        a = parent['attributes'][name]
        self.assertEqual((a['alias'], a['domain'], a['slot_uri'], a['range']),
                         (name, 'initial-ruins-assembly', 'pixlnd:initial-ruins-assembly/' + name, range_))
        self.assertEqual(a['see_also'], [geo])
        self.assertIs(a['required'], True)
        self.assertEqual((bool(a.get('multivalued')), bool(a.get('inlined')), bool(a.get('inlined_as_list'))),
                         (multi, inline, multi))
        self.assertEqual((a.get('minimum_cardinality'), a.get('maximum_cardinality')), (lo, hi))
        self.assertEqual(a.get('equals_number'), geometry.get(name))


def verify_ruins_volume(self, classes, volume_fields, geo):
    self.assertEqual(set(classes['encounter-volume']['attributes']), volume_fields)
    self.assertEqual(classes['ruins-room-volume']['is_a'], 'encounter-volume')
    self.assertEqual(classes['ruins-room-volume']['slot_usage'], {
        'width': {'equals_number': 24}, 'depth': {'equals_number': 24},
        'below-floor': {'equals_number': 1}, 'above-floor': {'equals_number': 12}})
    self.assertEqual(classes['encounter-volume']['see_also'], [geo])
    for name in volume_fields:
        a = classes['encounter-volume']['attributes'][name]
        self.assertEqual((a['alias'], a['range'], a['slot_uri'], a['minimum_value']),
                         (name, 'double', 'pixlnd:encounter-volume/' + name, 0))
        self.assertIs(a['required'], True)


def verify_ruins_identity(self, path):
    identity = yaml.safe_load(path.with_name('identity.yaml').read_text())['slots']['id']
    location = yaml.safe_load(path.with_name('relations.yaml').read_text())['slots']['located-in']
    nominal = yaml.safe_load(path.with_name('relation-types.yaml').read_text())['classes']
    self.assertIs(identity['identifier'], True)
    self.assertIs(identity['required'], True)
    self.assertEqual((identity['alias'], identity['range']), ('id', 'string'))
    self.assertEqual(nominal['dungeon']['slots'], ['id'])
    self.assertEqual(nominal['poi']['slots'], ['id'])
    self.assertEqual((location['alias'], location['domain'], location['slot_uri'], location['range']),
                     ('located-in', 'settlement-or-dungeon-or-poi', 'pixlnd:located-in', 'land'))
    self.assertIs(location['required'], True)


def verify_ruins_assignments(self, classes):
    for owner, expression, required, absent in (
            ('initial-nonboss-assignment', 'False', (), ('special', 'spirit')),
            ('initial-ruins-boss-assignment', 'True', ('special', 'spirit'), ()),
            ('initial-mission-boss-assignment', 'True', ('special',), ('spirit',))):
        a = classes[owner]
        self.assertEqual(a['is_a'], 'encounter-assignment')
        self.assertEqual(a['slot_usage'], {'boss': {'equals_expression': expression},
                                         **{f: {'required': True} for f in required}})
        self.assertEqual(a.get('none_of', []), [
            {'slot_conditions': {f: {'value_presence': 'PRESENT'}}} for f in absent])
    self.assertEqual(classes['encounter-assignment']['attributes']['spirit']['exactly_one_of'], [
        {'range': 'material', 'equals_string_in': ['spirit-fire', 'spirit-unholy', 'spirit-ice', 'spirit-wind']}])


def verify_ruins_class_rules(self, view, owner, base, geo, pop, expected, room):
    for cls in (view.get_class(owner), view.induced_class(owner)):
        self.assertEqual((cls.class_uri, cls.is_a, cls.see_also, cls.description),
                         ('pixlnd:' + owner, base, [geo, pop], expected[owner]['description']))
        self.assertEqual(len(cls.rules), 3 if owner == room else 0)
        for tier, rule in zip((1, 2, 3), cls.rules):
            self.assertEqual(set(rule.preconditions.slot_conditions), {'tier'})
            self.assertEqual(rule.preconditions.slot_conditions['tier'].equals_number, tier)
            post = rule.postconditions.slot_conditions
            self.assertEqual(set(post), {'pack-assignment', 'boss-assignment'})
            self.assertEqual(post['pack-assignment'].range_expression.slot_conditions['tier'].equals_number, tier)
            boss = post['boss-assignment']
            self.assertEqual(str(boss.value_presence), 'ABSENT' if tier == 1 else 'PRESENT')
            if tier != 1:
                self.assertEqual(boss.range, 'initial-ruins-boss-assignment')
                self.assertIs(boss.inlined, True)
                self.assertEqual(boss.range_expression.slot_conditions['tier'].equals_number, tier)


def verify_ruins_slot_sets(self, view, owner, fields, assembly):
    slots = view.class_induced_slots(owner)
    names, aliases = [s.name for s in slots], [s.alias or s.name for s in slots]
    self.assertEqual((len(names), len(set(names)), len(aliases), len(set(aliases))),
                     (len(fields[owner][0]),) * 4)
    self.assertEqual(set(aliases), fields[owner][0])
    self.assertEqual({s.alias or s.name for s in slots if s.required}, fields[owner][1])
    self.assertEqual([s.name for s in slots if s.identifier], ['id'] if owner == assembly else [])
    self.assertFalse(any(s.key for s in slots))


def verify_ruins_expected_slots(self, view, owner, expected):
    for name, a in expected[owner]['attributes'].items():
        for slot in (view.get_class(owner).attributes[name], view.induced_slot(name, owner)):
            for facet in ('alias', 'domain', 'slot_uri', 'range', 'description', 'see_also'):
                self.assertEqual(getattr(slot, facet), a[facet])
            self.assertEqual((bool(slot.required), bool(slot.inlined)),
                             (a.get('required', False), a.get('inlined', False)))
            self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined_as_list)
            for facet in ('ifabsent', 'minimum_cardinality', 'maximum_cardinality', 'exact_cardinality'):
                self.assertIsNone(getattr(slot, facet))


def verify_ruins_inherited(self, view, owner, base, room):
    # Same underlying facts and inherited metadata, not parallel geometry or identity.
    for inherited in view.class_induced_slots(base):
        slot = view.induced_slot(inherited.name, owner)
        for facet in ('alias', 'domain', 'slot_uri', 'see_also', 'required', 'multivalued',
                      'inlined', 'inlined_as_list', 'minimum_cardinality', 'maximum_cardinality',
                      'identifier', 'key', 'equals_number', 'minimum_value', 'maximum_value'):
            self.assertEqual(getattr(slot, facet), getattr(inherited, facet))
        self.assertEqual(slot.range, room if inherited.name == 'rooms' else inherited.range)


def verify_ruins_rooms_slot(self, view, room, assembly):
    tier = view.induced_slot('tier', room)
    self.assertEqual((tier.range, tier.minimum_value, tier.maximum_value), ('integer', 1, 3))
    rooms = view.induced_slot('rooms', assembly)
    self.assertEqual((rooms.name, rooms.alias, rooms.domain, rooms.slot_uri, rooms.range),
                     ('rooms', 'rooms', 'initial-ruins-assembly', 'pixlnd:initial-ruins-assembly/rooms', room))
    self.assertEqual((rooms.required, rooms.multivalued, rooms.inlined, rooms.inlined_as_list,
                      rooms.list_elements_ordered), (True, True, True, True, True))
    self.assertEqual((rooms.minimum_cardinality, rooms.maximum_cardinality), (3, 3))
    self.assertEqual(rooms.equals_expression, 'rooms if rooms.tier == [1, 2, 3] else []')
    self.assertEqual(view.induced_slot('located-in', assembly).range, 'land')


def verify_ruins_schemas(self, path, fields, view):
    from ontology_source_contracts import assert_declared_root

    schemas = {}
    for owner, (properties, required) in fields.items():
        schema = validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
            str(path), top_class=owner, preserve_names=True, not_closed=False).serialize())
        assert_declared_root(owner, properties, required, schema=schema, view=view)
        definition = schema['$defs'][owner]
        self.assertEqual(len(definition['required']), len(required))
        self.assertFalse(any('default' in prop for prop in definition['properties'].values()))
        schemas[owner] = schema
    return schemas


def verify_ruins_schema_props(self, schemas, assembly, room):
    ad = schemas[assembly]['$defs'][assembly]['properties']
    self.assertEqual(ad['population']['$ref'], '#/$defs/ruins-population')
    self.assertEqual(ad['located-in']['type'], 'string')
    self.assertEqual((ad['rooms']['type'], ad['rooms']['minItems'], ad['rooms']['maxItems']), ('array', 3, 3))
    self.assertEqual(ad['rooms']['items']['$ref'], '#/$defs/' + room)
    self.assertNotIn('uniqueItems', ad['rooms'])
    rp = schemas[room]['$defs'][room]['properties']
    self.assertEqual(rp['pack-assignment']['$ref'], '#/$defs/initial-nonboss-assignment')
    self.assertEqual((rp['tier']['type'], rp['tier']['minimum'], rp['tier']['maximum']), ('integer', 1, 3))
    self.assertEqual(rp['boss-assignment']['anyOf'], [
        {'$ref': '#/$defs/initial-ruins-boss-assignment'}, {'type': 'null'}])


def verify_ruins_shared_defs(self, path, view, schemas, assembly_fields, volume_fields):
    from ontology_source_contracts import assert_declared_root

    for owner, properties in (('initial-ruins-assembly', assembly_fields - {'population'}),
                              ('ruins-room-volume', volume_fields)):
        old = validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
            str(path), top_class=owner, preserve_names=True, not_closed=False).serialize())
        assert_declared_root(owner, properties, properties, schema=old, view=view)
        self.assertEqual(len(old['$defs'][owner]['required']), len(properties))
        for schema in schemas.values():
            self.assertEqual(schema['$defs'][owner], old['$defs'][owner])


def verify_ruins_camp_rescue(self, view):
    for owner in ('dungeon', 'poi'):
        self.assertEqual(view.class_slots(owner), ['id'])
    for owner, range_ in (('initial-populated-camp-assembly', 'camp-battlefield-volume'),
                          ('initial-populated-rescue-assembly', 'rescue-battlefield-volume')):
        slots = view.class_induced_slots(owner)
        self.assertEqual((len(slots), len({s.name for s in slots}), len({s.alias for s in slots})), (8, 8, 8))
        self.assertEqual([s.name for s in slots if s.identifier], ['id'])
        self.assertEqual(view.induced_slot('initial-battlefield', owner).range, range_)


class RuinsPopulationMixin:
    def _assert_initial_ruins_population_contract(self, path):
        room, assembly = 'initial-populated-ruins-room', 'initial-populated-ruins-assembly'
        geo = '../domain/encounter-contracts.md#geometry-and-occupancy'
        pop = '../domain/encounter-contracts.md#populations-tiers-and-clear-conditions'
        expected = ruins_expected()
        raw = yaml.safe_load(path.with_name('world.yaml').read_text())
        classes = raw['classes']
        # All owners' complete RAW goldens precede ANY SchemaView/induction/emission.
        for owner in (room, assembly):
            assert owner in classes, 'Missing declared source class: ' + owner
            self.assertEqual(classes[owner], expected[owner], owner)
        assembly_fields = {'id', 'located-in', 'rooms', 'corridors', 'entrance-court',
            'entrance-passage', 'reward-alcove', 'horizontal-bounds-width-blocks',
            'horizontal-bounds-depth-blocks', 'clear-ceiling-height-blocks', 'door-width-blocks',
            'door-height-blocks', 'corridor-trap-free-lane-width-blocks', 'population'}
        volume_fields = {'width', 'depth', 'below-floor', 'above-floor'}
        room_fields = {'width', 'depth', 'below-floor', 'above-floor', 'tier',
                       'pack-assignment', 'boss-assignment'}
        room_required = {'width', 'depth', 'below-floor', 'above-floor', 'tier', 'pack-assignment'}
        parent = classes['initial-ruins-assembly']
        verify_ruins_parent(self, parent, assembly_fields, geo)
        verify_ruins_volume(self, classes, volume_fields, geo)
        verify_ruins_identity(self, path)
        verify_ruins_assignments(self, classes)
        view = SchemaView(str(path))
        fields = {room: (room_fields, room_required), assembly: (assembly_fields, assembly_fields)}
        for owner, base in ((room, 'ruins-room-volume'), (assembly, 'initial-ruins-assembly')):
            verify_ruins_class_rules(self, view, owner, base, geo, pop, expected, room)
            verify_ruins_slot_sets(self, view, owner, fields, assembly)
            verify_ruins_expected_slots(self, view, owner, expected)
            verify_ruins_inherited(self, view, owner, base, room)
        verify_ruins_rooms_slot(self, view, room, assembly)
        schemas = verify_ruins_schemas(self, path, fields, view)
        verify_ruins_schema_props(self, schemas, assembly, room)
        verify_ruins_shared_defs(self, path, view, schemas, assembly_fields, volume_fields)
        verify_ruins_camp_rescue(self, view)
        return view, schemas

    def _initial_ruins_population_witness(self):
        row = {
         'id': 'ruins-example', 'located-in': 'unresolved-land',
         'rooms': [
          {'width':24, 'depth':24, 'below-floor':1, 'above-floor':12, 'tier':1,
           'pack-assignment': {'role':'melee', 'tier':1, 'boss':False}},
          {'width':24, 'depth':24, 'below-floor':1, 'above-floor':12, 'tier':2,
           'pack-assignment': {'role':'ranged', 'tier':2, 'boss':False},
           'boss-assignment': {'role':'mage', 'tier':2, 'boss':True, 'special':'stomp', 'spirit':'spirit-fire'}},
          {'width':24, 'depth':24, 'below-floor':1, 'above-floor':12, 'tier':3,
           'pack-assignment': {'role':'mage', 'tier':3, 'boss':False},
           'boss-assignment': {'role':'melee', 'tier':3, 'boss':True, 'special':'charge', 'spirit':'spirit-ice'}}],
         'corridors':[{'width':8, 'depth':8, 'below-floor':1, 'above-floor':12}],
         'entrance-court': {'width':24, 'depth':16, 'below-floor':1, 'above-floor':12},
         'entrance-passage': {'width':8, 'depth':8, 'below-floor':1, 'above-floor':12},
         'reward-alcove': {'width':12, 'depth':8, 'below-floor':1, 'above-floor':12},
         'horizontal-bounds-width-blocks':36, 'horizontal-bounds-depth-blocks':112,
         'clear-ceiling-height-blocks':6, 'door-width-blocks':4, 'door-height-blocks':5,
         'corridor-trap-free-lane-width-blocks':4,
         'population': {'packs':3, 'pack-size':3, 'bosses':2, 'hostiles':11, 'captives':0}}
        return row


class LogicalWorldTests(RuinsPopulationMixin, unittest.TestCase):
    def test_initial_ruins_population_contracts(self):
        self._assert_initial_ruins_population_contract(SCHEMA)

    def test_initial_ruins_population_order_binding(self):
        from itertools import permutations
        from jsonasobj2 import JsonObj, as_dict
        from linkml_runtime.utils.inference_utils import Config, generate_slot_value

        view, _ = self._assert_initial_ruins_population_contract(SCHEMA)
        owner = 'initial-populated-ruins-assembly'
        slot = view.induced_slot('rooms', owner)
        self.assertEqual((slot.range, slot.minimum_cardinality, slot.maximum_cardinality),
                         ('initial-populated-ruins-room', 3, 3))
        self.assertIs(slot.required, True)
        self.assertEqual(slot.equals_expression, 'rooms if rooms.tier == [1, 2, 3] else []')
        config = Config(use_expressions=True, use_string_serialization=False, use_rules=False)
        self.assertEqual(vars(config), {'use_expressions': True, 'use_string_serialization': False,
            'parse_string_serialization': False, 'use_rules': False, 'resolve_function': None})
        row = self._initial_ruins_population_witness()
        orders = [*permutations((1, 2, 3)), (1, 1, 3), (1, 2, 2), (2, 2, 3),
                  (1, 1, 1), (2, 2, 2), (3, 3, 3), (1, 3), (1, 2)]
        self.assertEqual(len(orders), 14)
        for order in orders:
            value = deepcopy(row)
            value['rooms'] = [deepcopy(row['rooms'][t - 1]) for t in order]
            before = deepcopy(value)
            obj = JsonObj(value)
            object_before = deepcopy(as_dict(obj))
            actual = obj.rooms
            self.assertTrue(all(type(r['tier']) is int for r in actual))
            self.assertEqual([r['tier'] for r in actual], list(order))
            expected = generate_slot_value(obj, 'rooms', view, class_name=owner, config=config)
            with self.subTest(room_tiers=order):
                self.assertIs(type(expected), list)
                if order == (1, 2, 3):
                    self.assertIs(expected, actual)
                    self.assertEqual(as_dict(expected), value['rooms'])
                else:
                    self.assertEqual(expected, [])
                    self.assertNotEqual(expected, actual)
                self.assertEqual(value, before)
                self.assertEqual(as_dict(obj), object_before)
        # Public expected-value binding, NOT input validation or STRICT inference.
        # Required typed exact3 supplies the nonempty premise; native bool typing is separate.
        print('ruins SDK: 14 complete contextual whole-slot bindings; inputs unchanged')


if __name__ == "__main__":
    unittest.main()
