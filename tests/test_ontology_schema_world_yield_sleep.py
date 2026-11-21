"""Deposit yield interval and hybrid inn sleep world schema tests."""
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
from test_ontology_schema_authoring import catalog, validate, validator


class LogicalWorldTests(unittest.TestCase):
    def _assert_deposit_yield_interval(self, path):
        from ontology_source_contracts import assert_declared_root

        owner = 'deposit-ingredient-yield'
        raw = load_module(path.with_name('world.yaml'))
        self.assertTrue(owner in raw['classes'], 'missing scalar declaration: deposit-ingredient-yield')
        anchors = ['../domain/3_Classes.md#deposit', '../schema/associations.yaml#ingredient-yield',
                   '../schema/world-catalog.yaml#deposit-yields']
        description = ('Deposit-scoped logical ingredient yield interval, not an emitted quantity or distribution. '
                       'The inherited ingredient reference and required minimum/maximum describe the fixed 1–3 interval. '
                       'Raw deposit catalog yields remain ingredient strings; reference existence and midnight renewal remain separate.')
        cls = raw['classes'][owner]
        self.assertEqual(cls, {'class_uri': 'pixlnd:' + owner, 'description': description,
                              'see_also': anchors, 'is_a': 'ingredient-yield',
                              'slot_usage': {'ingredient-yield-minimum': {'equals_number': 1},
                                             'ingredient-yield-maximum': {'equals_number': 3}}})
        for name in ('ingredient-yield-minimum', 'ingredient-yield-maximum'):
            self.assertIs(type(cls['slot_usage'][name]['equals_number']), int)
        # The reusable association is not narrowed for flora or other yield contexts.
        generic = load_module(path.with_name('associations.yaml'))
        self.assertEqual(generic['classes']['ingredient-yield'], {
            'class_uri': 'pixlnd:ingredient-yield', 'see_also': ['../domain/4_Relations.md'],
            'slots': ['ingredient-yield-ingredient', 'ingredient-yield-minimum', 'ingredient-yield-maximum'],
            'description': 'Logical count interval; minimum <= maximum is a coupled rule, not enforced by native JSON Schema.'})
        for field, range_, meaning in (
                ('ingredient', 'ingredient', 'Ingredient yield ingredient property; interpreted under its owning definition.'),
                ('minimum', 'integer', 'Ingredient yield minimum property; interpreted under its owning definition.'),
                ('maximum', 'integer', 'Ingredient yield maximum property; interpreted under its owning definition.')):
            expected = {'description': meaning, 'slot_uri': 'pixlnd:ingredient-yield/' + field,
                        'alias': field, 'domain': 'ingredient-yield', 'range': range_,
                        'required': True, 'see_also': ['../domain/4_Relations.md']}
            if field != 'ingredient':
                expected['minimum_value'] = 0
            self.assertEqual(generic['slots']['ingredient-yield-' + field], expected)
        view = SchemaView(str(path))
        declared = view.get_class(owner)
        self.assertEqual((str(declared.class_uri), declared.description, declared.see_also, declared.is_a),
                         ('pixlnd:' + owner, description, anchors, 'ingredient-yield'))
        self.assertFalse(declared.attributes or declared.slots or declared.mixins)
        self.assertEqual(set(declared.slot_usage), {'ingredient-yield-minimum', 'ingredient-yield-maximum'})
        self.assertEqual(set(view.class_slots(owner)),
                         {'ingredient-yield-ingredient', 'ingredient-yield-minimum', 'ingredient-yield-maximum'})
        for field, range_, number in (('ingredient', 'ingredient', None), ('minimum', 'integer', 1), ('maximum', 'integer', 3)):
            name = 'ingredient-yield-' + field
            slot = view.induced_slot(name, owner)
            self.assertEqual((slot.alias, str(slot.slot_uri), slot.domain, slot.range, slot.required),
                             (field, 'pixlnd:ingredient-yield/' + field, 'ingredient-yield', range_, True))
            self.assertEqual(slot.equals_number, number)
            if number is not None:
                self.assertTrue(isinstance(slot.equals_number, int) and not isinstance(slot.equals_number, bool))
                self.assertEqual(declared.slot_usage[name].equals_number, number)
            self.assertEqual(slot.minimum_value, None if field == 'ingredient' else 0)
            self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined or slot.inlined_as_list)
            self.assertEqual((slot.maximum_value, slot.minimum_cardinality, slot.maximum_cardinality,
                              slot.exact_cardinality, slot.ifabsent), (None,) * 5)
            parent = view.induced_slot(name, 'ingredient-yield')
            self.assertIsNone(parent.equals_number)
            self.assertEqual((parent.range, parent.required), (range_, True))
        fields = {'ingredient', 'minimum', 'maximum'}
        required = {'ingredient', 'minimum', 'maximum'}
        schema = (validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
            str(path), top_class=owner, preserve_names=True, not_closed=False).serialize()))
        assert_declared_root(owner, fields, required, schema=schema, view=view)
        self.assertEqual(len(view.class_induced_slots(owner)), 3)
        self.assertEqual(len(schema['$defs'][owner]['required']), 3)
        return schema

    def test_deposit_yield_interval_contracts(self):
        from ontology_source_contracts import assert_declared_root, validate_source

        schema = self._assert_deposit_yield_interval(SCHEMA)
        native = jsonschema.Draft201909Validator(schema)
        native.validate({'ingredient': 'iron-nugget', 'minimum': 1, 'maximum': 3})
        props = schema['$defs']['deposit-ingredient-yield']['properties']
        for field, number in (('minimum', 1), ('maximum', 3)):
            self.assertEqual((props[field]['type'], props[field]['const'], props[field]['minimum']), ('integer', number, 0))
        view = SchemaView(str(SCHEMA))
        self.assertEqual(view.get_slot('deposit-yields').range, 'ingredient')
        targets = {row['yields'] for row in catalog('deposits').values()
                   if isinstance(row, dict) and 'yields' in row}
        self.assertEqual(targets - catalog('ingredients').keys(), {'sandstone'})
        self.assertEqual(len(targets & catalog('ingredients').keys()), 8)
        self.assertEqual(catalog('deposits')['sandstone-deposit']['yields'], 'sandstone')
        # Nominal ingredient references, not FK existence or raw quantity payloads.
        for ingredient in ('sandstone', 'not-an-ingredient'):
            native.validate({'ingredient': ingredient, 'minimum': 1, 'maximum': 3})
        validate_source('deposits', catalog('deposits'))
        generic_schema = validator('ingredient-yield').schema
        assert_declared_root('ingredient-yield', {'ingredient', 'minimum', 'maximum'},
                             {'ingredient', 'minimum', 'maximum'}, schema=generic_schema, view=view)
        validate('ingredient-yield', {'ingredient': 'iron-nugget', 'minimum': 0, 'maximum': 9})
        # The generic coupled interval remains an explicitly unenforced boundary.
        validate('ingredient-yield', {'ingredient': 'iron-nugget', 'minimum': 9, 'maximum': 0})

    def test_deposit_yield_interval_values(self):
        schema = self._assert_deposit_yield_interval(SCHEMA)
        native = jsonschema.Draft201909Validator(schema)
        row = {'ingredient': 'iron-nugget', 'minimum': 1, 'maximum': 3}
        native.validate(row)
        for field, bads in (
                ('ingredient', [None, True, False, 1, 0.5, [], {}, {'id': 'iron-nugget'}]),
                ('minimum', [None, True, False, 0, 2, 3, '1', 1.5, [], {}]),
                ('maximum', [None, True, False, 0, 1, 2, 4, '3', 3.5, [], {}])):
            for bad in [{key: value for key, value in row.items() if key != field}] + [dict(row, **{field: v}) for v in bads]:
                with self.subTest(field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)
        for bad in (None, True, False, 0, 'root', [], [row], {},
                    dict(row, id='deposit-a'), dict(row, quantity=2), dict(row, unknown=True)):
            with self.subTest(root=bad), self.assertRaises(jsonschema.ValidationError):
                native.validate(bad)

    def test_deposit_yield_interval_mutations(self):
        schema = self._assert_deposit_yield_interval(SCHEMA)
        from ontology_source_contracts import assert_declared_root

        owner = 'deposit-ingredient-yield'
        original = SCHEMA.with_name('world.yaml').read_bytes()
        raw = load_module(SCHEMA.with_name('world.yaml'))
        base = ('classes', owner)
        mutations = [('missing-class', base, None), ('class-uri', base + ('class_uri',), 'pixlnd:wrong'),
                     ('class-anchor', base + ('see_also',), []), ('class-description', base + ('description',), 'wrong scope'),
                     ('parent', base + ('is_a',), 'recipe-consumption'), ('extra-attribute', base + ('attributes',), {'quantity': {'range': 'integer'}})]
        for field, number in (('minimum', 1), ('maximum', 3)):
            keys = base + ('slot_usage', 'ingredient-yield-' + field)
            mutations += [(field + '-' + label, keys + ('equals_number',), value) for label, value in
                          (('equality-loss', None), ('equality-change', number + 1), ('equality-bool', True))]
            mutations += [(field + '-refinement-loss', keys, None),
                          (field + '-optional', keys + ('required',), False),
                          (field + '-alias', keys + ('alias',), 'wrong')]
        with tempfile.TemporaryDirectory(prefix='deposit-interval-mutations-') as directory:
            target = Path(directory) / 'schema'
            copy_schema(target)
            module, path = target / 'world.yaml', target / SCHEMA.name
            for label, keys, replacement in mutations:
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
                with self.subTest(mutation=label), self.assertRaises(AssertionError):
                    self._assert_deposit_yield_interval(path)
                if label == 'minimum-equality-loss':
                    view = SchemaView(str(path))
                    self.assertIsNone(view.induced_slot('ingredient-yield-minimum', owner).equals_number)
                    emitted = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                                        preserve_names=True, not_closed=False).serialize())
                    assert_declared_root(owner, {'ingredient', 'minimum', 'maximum'},
                                         {'ingredient', 'minimum', 'maximum'}, schema=emitted, view=view)
                    bad = {'ingredient': 'iron-nugget', 'minimum': 2, 'maximum': 3}
                    with self.assertRaises(jsonschema.ValidationError):
                        jsonschema.Draft201909Validator(schema).validate(bad)
                    jsonschema.Draft201909Validator(emitted).validate(bad)
                    print('deposit minimum equality loss: actual native broadening, guarded 3/3 root')
                module.write_bytes(original)
            self.assertEqual(module.read_bytes(), original)
        self.assertEqual(len(mutations), 18)
        self.assertEqual(SCHEMA.with_name('world.yaml').read_bytes(), original)

    def _assert_hybrid_inn_sleep(self, path):
        from ontology_source_contracts import assert_declared_root

        owner = 'hybrid-inn-sleep-service-parameters'
        raw = load_module(path.with_name('world.yaml'))
        self.assertTrue(owner in raw['classes'], 'missing scalar declaration: hybrid-inn-sleep-service-parameters')
        anchors = ['../domain/3_Classes.md#game-clock', '../domain/5_Constraints.md#c-inn-hours']
        description = ('Hybrid inn paid sleep parameters from settlements/inn items 2–4, distinct from free anytime healing and respawn. '
                       'The 18:00–06:00 availability wraps midnight; next 07:00 is a clock skip, not accelerated combat, statuses or cooldowns. '
                       'All connected players explicitly agree; the initiator pays the single fee only on success, with refusal blocking the skip without charge. '
                       'Ordinary midnight resets apply once only when crossed; sleeping grants no extra shop refresh or mission reroll. '
                       'The historical reference sleep multiplier and fresh-world clock remain separate.')
        facts = {'fee-copper': (10, 'Single initiating-player fee on a successful agreed sleep skip.'),
                 'available-from-hour': (18, 'Start hour of the overnight paid sleep window, not a free recovery restriction.'),
                 'available-until-hour': (6, 'End hour of the overnight paid sleep window; wraps midnight from 18.'),
                 'next-morning-hour': (7, 'Next 07:00 target: 22:00 reaches tomorrow morning; 02:00 reaches that morning.')}
        cls = raw['classes'][owner]
        self.assertEqual(set(cls), {'class_uri', 'description', 'see_also', 'attributes'})
        self.assertEqual((cls['class_uri'], cls['description'], cls['see_also']), ('pixlnd:' + owner, description, anchors))
        self.assertEqual(set(cls['attributes']), set(facts))
        for name, (number, meaning) in facts.items():
            self.assertEqual(cls['attributes'][name], {'alias': name, 'slot_uri': 'pixlnd:' + owner + '/' + name,
                             'range': 'integer', 'required': True, 'equals_number': number,
                             'description': meaning, 'see_also': anchors})
            self.assertIs(type(cls['attributes'][name]['equals_number']), int)
        view = SchemaView(str(path))
        declared = view.get_class(owner)
        self.assertEqual((str(declared.class_uri), declared.description, declared.see_also), ('pixlnd:' + owner, description, anchors))
        self.assertIsNone(declared.is_a)
        self.assertFalse(declared.slots or declared.slot_usage or declared.mixins)
        self.assertEqual(set(declared.attributes), set(facts))
        self.assertEqual(set(view.class_slots(owner)), set(facts))
        for name, (number, meaning) in facts.items():
            for slot in (declared.attributes[name], view.induced_slot(name, owner)):
                self.assertEqual((slot.alias, str(slot.slot_uri), slot.range, slot.required, slot.description, slot.see_also),
                                 (name, 'pixlnd:' + owner + '/' + name, 'integer', True, meaning, anchors))
                self.assertTrue(isinstance(slot.equals_number, int) and not isinstance(slot.equals_number, bool))
                self.assertEqual(slot.equals_number, number)
                self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined or slot.inlined_as_list)
                self.assertEqual((slot.minimum_cardinality, slot.maximum_cardinality, slot.exact_cardinality,
                                  slot.minimum_value, slot.maximum_value, slot.ifabsent), (None,) * 6)
        fields = {'fee-copper', 'available-from-hour', 'available-until-hour', 'next-morning-hour'}
        required = {'fee-copper', 'available-from-hour', 'available-until-hour', 'next-morning-hour'}
        schema = (validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
            str(path), top_class=owner, preserve_names=True, not_closed=False).serialize()))
        assert_declared_root(owner, fields, required, schema=schema, view=view)
        self.assertEqual(len(view.class_induced_slots(owner)), 4)
        self.assertEqual(len(schema['$defs'][owner]['required']), 4)
        return schema

    def test_hybrid_inn_sleep_contracts(self):
        schema = self._assert_hybrid_inn_sleep(SCHEMA)
        native = jsonschema.Draft201909Validator(schema)
        native.validate({'fee-copper': 10, 'available-from-hour': 18, 'available-until-hour': 6, 'next-morning-hour': 7})
        props = schema['$defs']['hybrid-inn-sleep-service-parameters']['properties']
        for name, number in (('fee-copper', 10), ('available-from-hour', 18), ('available-until-hour', 6), ('next-morning-hour', 7)):
            self.assertEqual((props[name]['type'], props[name]['const']), ('integer', number))
        clock = SchemaView(str(SCHEMA)).get_class('game-clock')
        self.assertEqual(set(clock.attributes), {'speed', 'initial-time-ms', 'reference-sleep-speed'})
        self.assertEqual(clock.attributes['initial-time-ms'].equals_number, 25200000)
        self.assertEqual(clock.attributes['reference-sleep-speed'].equals_number, 100)

    def test_hybrid_inn_sleep_values(self):
        schema = self._assert_hybrid_inn_sleep(SCHEMA)
        native = jsonschema.Draft201909Validator(schema)
        row = {'fee-copper': 10, 'available-from-hour': 18, 'available-until-hour': 6, 'next-morning-hour': 7}
        native.validate(row)
        for field, number in row.items():
            bads = [{key: value for key, value in row.items() if key != field}]
            bads += [dict(row, **{field: value}) for value in (None, True, False, number - 1, number + 1, str(number), number + 0.5, [], {})]
            for bad in bads:
                with self.subTest(field=field, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)
        for bad in (None, True, False, 0, 'root', [], [row], {}, dict(row, id='inn'),
                    dict(row, agreement=True), dict(row, healing=True), dict(row, unknown=0)):
            with self.subTest(root=bad), self.assertRaises(jsonschema.ValidationError):
                native.validate(bad)

    def test_hybrid_inn_sleep_mutations(self):
        schema = self._assert_hybrid_inn_sleep(SCHEMA)
        from ontology_source_contracts import assert_declared_root

        owner = 'hybrid-inn-sleep-service-parameters'
        original = SCHEMA.with_name('world.yaml').read_bytes()
        raw = load_module(SCHEMA.with_name('world.yaml'))
        base = ('classes', owner)
        mutations = [('missing-class', base, None), ('class-uri', base + ('class_uri',), 'pixlnd:wrong'),
                     ('class-anchor', base + ('see_also',), []), ('class-description', base + ('description',), 'wrong scope')]
        for name, number in (('fee-copper', 10), ('available-from-hour', 18), ('available-until-hour', 6), ('next-morning-hour', 7)):
            keys = base + ('attributes', name)
            mutations += [(name + '-' + facet, keys + (facet,), replacement) for facet, replacement in
                          (('required', None), ('range', 'string'), ('equals_number', None),
                           ('alias', 'wrong'), ('slot_uri', 'pixlnd:wrong/' + name), ('see_also', []))]
            mutations += [(name + '-constant-changed', keys + ('equals_number',), number + 1),
                          (name + '-constant-bool', keys + ('equals_number',), True),
                          (name + '-attachment', keys, None)]
        with tempfile.TemporaryDirectory(prefix='inn-sleep-mutations-') as directory:
            target = Path(directory) / 'schema'
            copy_schema(target)
            module, path = target / 'world.yaml', target / SCHEMA.name
            for label, keys, replacement in mutations:
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
                with self.subTest(mutation=label), self.assertRaises(AssertionError):
                    self._assert_hybrid_inn_sleep(path)
                if label == 'fee-copper-equals_number':
                    view = SchemaView(str(path))
                    self.assertIsNone(view.induced_slot('fee-copper', owner).equals_number)
                    emitted = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                                        preserve_names=True, not_closed=False).serialize())
                    assert_declared_root(owner, {'fee-copper', 'available-from-hour', 'available-until-hour', 'next-morning-hour'},
                                         {'fee-copper', 'available-from-hour', 'available-until-hour', 'next-morning-hour'}, schema=emitted, view=view)
                    bad = {'fee-copper': 11, 'available-from-hour': 18, 'available-until-hour': 6, 'next-morning-hour': 7}
                    with self.assertRaises(jsonschema.ValidationError):
                        jsonschema.Draft201909Validator(schema).validate(bad)
                    jsonschema.Draft201909Validator(emitted).validate(bad)
                    print('inn fee equality loss: actual native broadening, guarded 4/4 root')
                module.write_bytes(original)
            self.assertEqual(module.read_bytes(), original)
        self.assertEqual(len(mutations), 40)
        self.assertEqual(SCHEMA.with_name('world.yaml').read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
