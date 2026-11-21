"""Initial populated land world schema tests."""
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
from test_ontology_schema_world_ruins_population import RuinsPopulationMixin


def verify_land_raw(self, raw, owner, roles, ranges, expression, description, anchors):
    self.assertIn(owner, raw['classes'], 'missing whole-land declaration: initial-populated-land')
    cls = raw['classes'][owner]
    self.assertEqual(set(cls), {'class_uri', 'is_a', 'description', 'see_also', 'attributes', 'slot_usage'})
    self.assertEqual((cls['class_uri'], cls['is_a'], cls['description'], cls['see_also']),
                     ('pixlnd:' + owner, 'land', description, anchors))
    self.assertEqual(cls['slot_usage'], {'id': {'equals_expression': expression}})
    self.assertEqual(set(cls['attributes']), set(roles))
    for index, (role, range_) in enumerate(zip(roles, ranges)):
        expected = {'alias': role, 'slot_uri': 'pixlnd:' + owner + '/' + role, 'range': range_,
                    'required': True, 'inlined': False, 'see_also': anchors,
                    'description': 'The ' + role + ' site relationship for this initial hybrid land; not a captive or a duplicated site body.'}
        if index >= 2:
            expected['range_expression'] = {'slot_conditions': {'tier': {'equals_number': index - 2}}}
            self.assertIs(type(cls['attributes'][role]['range_expression']['slot_conditions']['tier']['equals_number']), int)
        self.assertEqual(cls['attributes'][role], expected)


def verify_land_declared(self, view, path, owner, roles, ranges, expression, description, anchors):
    from jsonasobj2 import as_dict

    declared = view.get_class(owner)
    self.assertEqual((declared.class_uri, declared.is_a, declared.description, declared.see_also),
                     ('pixlnd:' + owner, 'land', description, anchors))
    self.assertEqual(set(declared.attributes), set(roles))
    self.assertEqual(set(declared.slot_usage), {'id'})
    self.assertEqual(declared.slot_usage['id'].equals_expression, expression)
    local = view.induced_slot('id', owner)
    self.assertEqual((local.alias, str(local.slot_uri), local.range, local.required, local.identifier,
                      local.pattern, local.equals_expression),
                     ('id', 'pixlnd:id', 'string', True, True, '^[a-z0-9]+(?:-[a-z0-9]+)*$', expression))
    self.assertIsNone(view.induced_slot('id', 'land').equals_expression)
    self.assertIsNone(view.get_slot('id').equals_expression)
    # Match induction histories; compare complete SDK metadata, including domain_of.
    reference = SchemaView(str(path))
    reference.induced_slot('id', 'land')
    self.assertEqual(as_dict(view.get_slot('id')), as_dict(reference.get_slot('id')))
    self.assertEqual(as_dict(view.get_slot('located-in')), as_dict(reference.get_slot('located-in')))
    return declared


def verify_land_slots(self, view, declared, owner, roles, ranges, anchors):
    for index, (role, range_) in enumerate(zip(roles, ranges)):
        for slot in (declared.attributes[role], view.induced_slot(role, owner)):
            self.assertEqual((slot.alias, str(slot.slot_uri), slot.range, slot.required, slot.inlined,
                              slot.see_also, slot.domain), (role, 'pixlnd:' + owner + '/' + role,
                              range_, True, False, anchors, None))
            self.assertFalse(slot.multivalued or slot.inlined_as_list or slot.identifier or slot.key
                             or slot.list_elements_ordered or slot.list_elements_unique)
            self.assertEqual((slot.minimum_cardinality, slot.maximum_cardinality,
                              slot.exact_cardinality, slot.ifabsent), (None, None, None, None))
            if index >= 2:
                tier = slot.range_expression.slot_conditions['tier'].equals_number
                self.assertTrue(isinstance(tier, int) and not isinstance(tier, bool) and tier == index - 2)
            else:
                self.assertIsNone(slot.range_expression)
        self.assertFalse(view.is_inlined(view.induced_slot(role, owner)))


def build_land_schemas(self, view, path, owner, roles, ranges):
    from ontology_source_contracts import assert_declared_root

    base_fields = {'id', 'name', 'landscape', 'level', 'danger-tier', 'coords', 'settlements',
                   'tier-range', 'rarity', 'realm', 'key-items', 'gnome-suppliers',
                   'books-of-crafting', 'circles-of-power', 'artifacts', 'wizard-towers', 'border'}
    base_required = {'id', 'name', 'landscape', 'level', 'danger-tier', 'coords', 'settlements'}
    outdoor = {'id', 'located-in', 'battlefield', 'opposite-exits', 'tier', 'population',
               'pack-assignments', 'boss-assignment'}
    ruins = {'id', 'located-in', 'rooms', 'corridors', 'entrance-court', 'entrance-passage',
             'reward-alcove', 'horizontal-bounds-width-blocks', 'horizontal-bounds-depth-blocks',
             'clear-ceiling-height-blocks', 'door-width-blocks', 'door-height-blocks',
             'corridor-trap-free-lane-width-blocks', 'population'}
    contracts = {'land': (base_fields, base_required), owner: (base_fields | set(roles), base_required | set(roles)),
                 ranges[0]: (ruins, ruins), ranges[1]: (outdoor, outdoor), ranges[2]: (outdoor, outdoor)}
    schemas = {}
    for root, (fields, required) in contracts.items():
        slots = view.class_induced_slots(root)
        self.assertEqual(len(slots), len(fields))
        self.assertEqual({s.alias or s.name for s in slots}, fields)
        self.assertEqual({s.alias or s.name for s in slots if s.required}, required)
        self.assertEqual([s.name for s in slots if s.identifier], ['id'])
        schema = (validator(root).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
            str(path), top_class=root, preserve_names=True, not_closed=False).serialize()))
        assert_declared_root(root, fields, required, schema=schema, view=view)
        self.assertEqual(len(schema['$defs'][root]['required']), len(required))
        schemas[root] = schema
    return schemas


def verify_land_inherited(self, view, owner, schemas, roles):
    for name in view.class_slots('land'):
        inherited, base = view.induced_slot(name, owner), view.induced_slot(name, 'land')
        for facet in ('alias', 'range', 'slot_uri', 'domain', 'required', 'multivalued', 'inlined',
                      'inlined_as_list', 'identifier', 'key', 'minimum_cardinality', 'maximum_cardinality',
                      'exact_cardinality', 'minimum_value', 'maximum_value', 'equals_number',
                      'see_also', 'ifabsent', 'list_elements_ordered', 'list_elements_unique'):
            self.assertEqual(getattr(inherited, facet), getattr(base, facet), (name, facet))
        if name != 'id':
            self.assertEqual(inherited.equals_expression, base.equals_expression)
    for role in roles:
        prop = schemas[owner]['$defs'][owner]['properties'][role]
        self.assertEqual(prop['type'], 'string')
        self.assertNotIn('$ref', prop)
    self.assertEqual(view.class_slots('dungeon'), ['id'])
    self.assertEqual(view.class_slots('poi'), ['id'])


def land_outdoor_body(index):
    tier = 1 if index == 1 else index - 2
    body = {'battlefield': {'width': 64 if index == 1 else 48, 'depth': 64 if index == 1 else 48,
                           'below-floor': 1, 'above-floor': 16},
            'opposite-exits': [{'width-blocks': 8}, {'width-blocks': 8}], 'tier': tier,
            'population': {'packs': 2, 'pack-size': 3, 'bosses': 1, 'hostiles': 7,
                           'captives': 0 if index == 1 else 1},
            'pack-assignments': [{'role': 'melee', 'tier': tier, 'boss': False},
                                 {'role': 'mage', 'tier': tier, 'boss': False}],
            'boss-assignment': {'role': 'ranged', 'tier': tier, 'boss': True, 'special': 'stomp'}}
    return body


def build_land_sites(self, roles, ranges):
    land = {'id': 'land-example', 'name': 'Synthetic Plain', 'landscape': 'greenlands', 'level': 1,
            'danger-tier': 'normal', 'coords': [-512, 511], 'settlements': ['village-example']}
    sites = {}
    for index, (role, range_) in enumerate(zip(roles, ranges)):
        land[role] = role + '-example'
        if index == 0:
            body = self._initial_ruins_population_witness()
        else:
            body = land_outdoor_body(index)
        body.update(id=land[role], **{'located-in': land['id']})
        sites[role] = {'root': range_, 'body': body}
    return land, sites


def verify_land_safe_names(self, view, owner, ranges, safe):
    from linkml_runtime.utils.formatutils import underscore

    for wire, name in safe.items():
        slot = view.induced_slot(wire, owner if wire != 'located-in' else ranges[1])
        self.assertEqual(underscore(slot.alias or slot.name), name)
        self.assertEqual(view.slot_name_mappings()[name].name, wire)


def verify_land_compute(self, v, record, endpoints, owners, schemas, owner, roles, ranges, safe):
    from jsonasobj2 import JsonObj, as_dict, items
    from linkml_runtime.utils.formatutils import underscore
    from linkml_runtime.utils.inference_utils import (
        Config,
        generate_slot_value,
        obj_as_dict_nonrecursive,
    )

    # Explicit supplied typed JsonObj views, NOT emitted classes or automatic resolution.
    original = deepcopy((record, endpoints, owners))
    jsonschema.Draft201909Validator(schemas[owner]).validate(record)
    self.assertEqual(len({r['id'] for r in owners}), len(owners))
    self.assertIn(record['id'], {r['id'] for r in owners})
    for row in owners:
        jsonschema.Draft201909Validator(schemas['land']).validate(row)
    obj = JsonObj(**{underscore(k): deepcopy(value) for k, value in record.items()})
    supplied = {}
    for index, role in enumerate(roles):
        endpoint = endpoints[role]
        self.assertEqual(endpoint['root'], ranges[index])
        self.assertEqual(endpoint['body']['id'], record[role])
        self.assertIn(endpoint['body']['located-in'], {r['id'] for r in owners})
        if index >= 2:
            self.assertEqual(endpoint['body']['tier'], index - 2)
        jsonschema.Draft201909Validator(schemas[endpoint['root']]).validate(endpoint['body'])
        supplied[safe[role]] = JsonObj(**{underscore(k): deepcopy(value) for k, value in endpoint['body'].items()})
    self.assertEqual(len({e['body']['id'] for e in endpoints.values()}), 6)
    before = deepcopy((as_dict(obj), {k: as_dict(e) for k, e in supplied.items()}))
    identities = {k: id(e) for k, e in supplied.items()}
    # The hook ONLY supplies provided endpoints: equality resides in the YAML expression.
    config = Config(use_expressions=True, use_string_serialization=False,
                    parse_string_serialization=False, use_rules=False,
                    resolve_function=lambda value, key: supplied[key] if key in supplied else value)
    bindings = obj_as_dict_nonrecursive(obj, config.resolve_function)
    for key, value in items(obj):
        if key in supplied:
            self.assertIs(bindings[key], supplied[key])
        else:
            self.assertEqual(bindings[key], value)
    binding_before = deepcopy({k: as_dict(value) if isinstance(value, JsonObj) else value for k, value in bindings.items()})
    result = generate_slot_value(obj, 'id', v, class_name=owner, config=config)
    self.assertEqual((record, endpoints, owners), original)
    self.assertEqual((as_dict(obj), {k: as_dict(e) for k, e in supplied.items()}), before)
    self.assertEqual({k: id(e) for k, e in supplied.items()}, identities)
    self.assertEqual({k: as_dict(value) if isinstance(value, JsonObj) else value for k, value in bindings.items()}, binding_before)
    return result


def land_contract_bads(native, record, root, owner, sites, required):
    bads = [None, False, 1, 'root', [], dict(record, unknown=True)]
    for field in required:
        bads.append({k: v for k, v in record.items() if k != field})
        bads.append(dict(record, **{field: None}))
    for field in record:
        bads.append(dict(record, **{field: True}))
    for field in ('id',) + (tuple(sites) if root == owner else ('located-in',)):
        for value in (0, [], {}, '', 'Bad ID', '-bad', 'bad-'):
            # Native scalar references do not carry the target identifier pattern.
            if field != 'id' and isinstance(value, str):
                native.validate(dict(record, **{field: value}))
            else:
                bads.append(dict(record, **{field: value}))
    return bads


def build_land_mutations(owner, roles):
    mutations = [('missing-class', ('classes', owner), None, None),
                 ('owner-facet-loss', ('classes', owner, 'slot_usage', 'id', 'equals_expression'), None, 'all')]
    left = ['ruins.located_in', 'daily_camp.located_in', 'white_rescue.located_in',
            'green_rescue.located_in', 'blue_rescue.located_in', 'purple_rescue.located_in']
    for index, role in enumerate(roles):
        remaining = left[:index] + left[index + 1:]
        changed = 'id if [' + ', '.join(remaining) + "] == [id, id, id, id, id] else id + '-'"
        mutations.append(('owner-' + role + '-comparison-loss',
                          ('classes', owner, 'slot_usage', 'id', 'equals_expression'), changed, role))
    mutations += [('role-alias', ('classes', owner, 'attributes', 'ruins', 'alias'), 'wrong-ruins', None),
                  ('role-type', ('classes', owner, 'attributes', 'daily-camp', 'range'), 'integer', None),
                  ('role-required', ('classes', owner, 'attributes', 'green-rescue', 'required'), False, None),
                  ('role-target', ('classes', owner, 'attributes', 'ruins', 'range'), 'initial-populated-camp-assembly', None)]
    for index, role in enumerate(roles[2:]):
        mutations.append(('target-tier-' + role, ('classes', owner, 'attributes', role,
            'range_expression', 'slot_conditions', 'tier', 'equals_number'), (index + 1) % 4, None))
    return mutations


def verify_land_mutation_write(self, raw, keys, replacement, module):
    changed = deepcopy(raw)
    cursor = changed
    for key in keys[:-1]:
        cursor = cursor[key]
    if replacement is None:
        del cursor[keys[-1]]
    else:
        cursor[keys[-1]] = replacement
    module.write_text(yaml.safe_dump(changed, sort_keys=False))
    self.assertEqual(yaml.safe_load(module.read_text()), changed)


def verify_land_mutation_effects(
    self, path, owner, expression, land, sites, owners, lost, schemas, roles, calls, compute
):
    from ontology_source_contracts import assert_declared_root

    mv = SchemaView(str(path))
    self.assertNotEqual(mv.induced_slot('id', owner).equals_expression, expression)
    self.assertEqual(compute(mv, land, sites, owners), None if lost == 'all' else 'land-example')
    calls += 1
    for role in roles:
        endpoints = deepcopy(sites)
        endpoints[role]['body']['located-in'] = 'land-alternate'
        expected = None if lost == 'all' else 'land-example' if lost == role else 'land-example-'
        self.assertEqual(compute(mv, land, endpoints, owners), expected)
        calls += 1
    if lost == 'all':
        schema = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                           preserve_names=True, not_closed=False).serialize())
        fields = {'id', 'name', 'landscape', 'level', 'danger-tier', 'coords', 'settlements',
                  'tier-range', 'rarity', 'realm', 'key-items', 'gnome-suppliers',
                  'books-of-crafting', 'circles-of-power', 'artifacts', 'wizard-towers', 'border',
                  'ruins', 'daily-camp', 'white-rescue', 'green-rescue', 'blue-rescue', 'purple-rescue'}
        required = {'id', 'name', 'landscape', 'level', 'danger-tier', 'coords', 'settlements',
                    'ruins', 'daily-camp', 'white-rescue', 'green-rescue', 'blue-rescue', 'purple-rescue'}
        assert_declared_root(owner, fields, required, schema=schema, view=mv)
        self.assertEqual(schema, schemas[owner])
        jsonschema.Draft201909Validator(schema).validate(land)
        print('whole-land owner-facet loss: public None; native whole-schema no-effect')
    return calls


class LogicalWorldTests(RuinsPopulationMixin, unittest.TestCase):
    def _assert_initial_populated_land(self, path):
        owner = 'initial-populated-land'
        roles = ('ruins', 'daily-camp', 'white-rescue', 'green-rescue', 'blue-rescue', 'purple-rescue')
        ranges = ('initial-populated-ruins-assembly', 'initial-populated-camp-assembly',
                  *('initial-populated-rescue-assembly',) * 4)
        expression = "id if [ruins.located_in, daily_camp.located_in, white_rescue.located_in, green_rescue.located_in, blue_rescue.located_in, purple_rescue.located_in] == [id, id, id, id, id, id] else id + '-'"
        description = ('Initial hybrid land and its designated ruins, daily camp and four supplier-rescue sites. '
                       'Every selected site belongs to this land; rescue roles have no presentation order.')
        anchors = ['../domain/encounter-contracts.md#placement-and-access',
                   '../domain/encounter-contracts.md#populations-tiers-and-clear-conditions']
        raw = load_module(path.with_name('world.yaml'))
        verify_land_raw(self, raw, owner, roles, ranges, expression, description, anchors)
        # Every mutant meets this complete RAW oracle before any SDK induction/emission.
        view = SchemaView(str(path))
        declared = verify_land_declared(
            self, view, path, owner, roles, ranges, expression, description, anchors)
        verify_land_slots(self, view, declared, owner, roles, ranges, anchors)
        schemas = build_land_schemas(self, view, path, owner, roles, ranges)
        verify_land_inherited(self, view, owner, schemas, roles)
        # Complete synthetic logical fixture, never a production instance or save envelope.
        land, sites = build_land_sites(self, roles, ranges)
        safe = {'id': 'id', 'located-in': 'located_in', 'ruins': 'ruins', 'daily-camp': 'daily_camp',
                'white-rescue': 'white_rescue', 'green-rescue': 'green_rescue',
                'blue-rescue': 'blue_rescue', 'purple-rescue': 'purple_rescue'}
        verify_land_safe_names(self, view, owner, ranges, safe)

        def compute(v, record, endpoints, owners):
            return verify_land_compute(
                self, v, record, endpoints, owners, schemas, owner, roles, ranges, safe)

        return view, schemas, land, sites, compute

    def test_initial_populated_land_contracts(self):
        _, schemas, land, sites, _ = self._assert_initial_populated_land(SCHEMA)
        owner = 'initial-populated-land'
        records = [(owner, land)] + [(e['root'], e['body']) for e in sites.values()]
        negatives = 0
        for root, record in records:
            native = jsonschema.Draft201909Validator(schemas[root])
            native.validate(record)
            required = schemas[root]['$defs'][root]['required']
            bads = land_contract_bads(native, record, root, owner, sites, required)
            for bad in bads:
                with self.subTest(root=root, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)
                negatives += 1
            self.assertEqual({e.validator for e in native.iter_errors(dict(record, unknown=True))}, {'additionalProperties'})
        generic = {k: v for k, v in land.items() if k not in sites}
        jsonschema.Draft201909Validator(schemas['land']).validate(generic)
        for role in sites:
            jsonschema.Draft201909Validator(schemas[owner]).validate(dict(land, **{role: 'missing-but-valid-id'}))
        self.assertEqual({k: sum(e['body']['population'][k] for e in sites.values())
                          for k in ('hostiles', 'bosses', 'captives')}, {'hostiles': 46, 'bosses': 7, 'captives': 4})
        print('whole-land contracts: 7 complete synthetic records;', negatives, 'negative controls; native references unresolved')

    def test_initial_populated_land_owner_binding(self):
        view, schemas, land, sites, compute = self._assert_initial_populated_land(SCHEMA)
        roles = tuple(sites)
        generic = {k: v for k, v in land.items() if k not in sites}
        alternate = dict(generic, id='land-alternate')
        owners = [generic, alternate]
        self.assertEqual(compute(view, land, sites, owners), 'land-example')
        for role in roles:
            changed = deepcopy(sites)
            changed[role]['body']['located-in'] = 'land-alternate'
            self.assertEqual(compute(view, land, changed, owners), 'land-example-')
        for supplied_id in ('0', 'a', 'a-b', '0-0', 'land-other'):
            record = dict(land, id=supplied_id)
            endpoints = deepcopy(sites)
            for endpoint in endpoints.values():
                endpoint['body']['located-in'] = supplied_id
            owner_rows = [dict(generic, id=supplied_id), alternate]
            self.assertEqual(compute(view, record, endpoints, owner_rows), supplied_id)
            endpoints['ruins']['body']['located-in'] = 'land-alternate'
            self.assertEqual(compute(view, record, endpoints, owner_rows), supplied_id + '-')
        # No evaluation on incomplete/ambiguous resolution: these are NOT native FK rejections.
        for candidates in ([], [sites['ruins'], deepcopy(sites['ruins'])]):
            self.assertNotEqual(len(candidates), 1)
        native = jsonschema.Draft201909Validator(schemas['initial-populated-land'])
        for changed in (dict(land, ruins='absent-site'), dict(land, ruins=land['daily-camp']),
                        dict(land, **{'white-rescue': land['purple-rescue']})):
            native.validate(changed)  # Existence, nominal class, target tier and uniqueness are not dereferenced.
        print('whole-land owner binding: 17 nonmutating public computations; missing/ambiguous supplied endpoints incomplete')

    def test_initial_populated_land_mutations(self):
        _, schemas, land, sites, compute = self._assert_initial_populated_land(SCHEMA)
        owner = 'initial-populated-land'
        original = SCHEMA.with_name('world.yaml').read_bytes()
        raw = load_module(SCHEMA.with_name('world.yaml'))
        expression = raw['classes'][owner]['slot_usage']['id']['equals_expression']
        roles = tuple(sites)
        mutations = build_land_mutations(owner, roles)
        self.assertEqual(len(mutations), 16)
        generic = {k: v for k, v in land.items() if k not in sites}
        owners = [generic, dict(generic, id='land-alternate')]
        calls = 0
        with tempfile.TemporaryDirectory(prefix='whole-land-mutations-') as directory:
            target = Path(directory) / 'schema'
            copy_schema(target)
            module, path = target / 'world.yaml', target / SCHEMA.name
            for label, keys, replacement, lost in mutations:
                verify_land_mutation_write(self, raw, keys, replacement, module)
                with self.subTest(mutation=label), self.assertRaises(AssertionError):
                    self._assert_initial_populated_land(path)
                print('whole-land actual YAML loss detected:', label)
                if lost is not None:
                    calls = verify_land_mutation_effects(
                        self, path, owner, expression, land, sites, owners, lost, schemas, roles, calls, compute)
                module.write_bytes(original)
        self.assertEqual(calls, 49)
        self.assertEqual(SCHEMA.with_name('world.yaml').read_bytes(), original)
        print('whole-land mutations: 16 SAME raw-first controls; 49 YAML-dependent public computations')


if __name__ == "__main__":
    unittest.main()
