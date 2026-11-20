"""Initial site placement world schema tests."""
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


class LogicalWorldTests(unittest.TestCase):
    def _assert_initial_site_placement(self, path):
        from ontology_source_contracts import assert_declared_root

        owner = 'initial-site-placement-profile'
        raw = yaml.safe_load(path.with_name('world.yaml').read_text())
        self.assertTrue(owner in raw['classes'], 'missing placement declaration: initial-site-placement-profile')
        cls = raw['classes'][owner]
        anchors = ['../domain/encounter-contracts.md#placement-and-access']
        description = ('Initial hybrid site placement parameters, not positions or saved state. '
                       'Land-seeded locations remain fixed across visits and daily renewal. '
                       'Floors follow H=max(natural ground height, sea level+4 blocks); ocean lands retain dry site islands. '
                       'The dry village hub applies only where ordinary ocean village generation fails. '
                       'Protected village area, finite-world bounds and joint village/all-six-site geography validation remain required; '
                       'failure is diagnostic, never fewer suppliers or partial encounters. '
                       'Optional terrain-following guidance never reshapes terrain or guarantees walkability; '
                       'its failure only omits guidance.')
        facts = {
            'minimum-village-distance-blocks': (192, 'Inclusive lower distance of a site centre from the village square, not the land centre.'),
            'maximum-village-distance-blocks': (215, 'Inclusive upper distance of a site centre from the village square, not the land centre.'),
            'minimum-site-separation-blocks': (192, 'Minimum distance between site centres, distinct from village distance.'),
            'sea-level-floor-clearance-blocks': (4, 'Relative sea-level clearance in H=max(natural ground height, sea level+4 blocks), not absolute floor altitude.'),
            'terrain-apron-blocks': (8, 'Site terrain apron, not a connecting-route width or walkability guarantee.'),
            'fallback-village-hub-width-blocks': (64, 'Dry village hub width only on ocean lands where ordinary village generation otherwise fails; not every site or battlefield.'),
            'fallback-village-hub-depth-blocks': (64, 'Dry village hub depth only on ocean lands where ordinary village generation otherwise fails; not every site or battlefield.'),
        }
        self.assertEqual(set(cls), {'class_uri', 'description', 'see_also', 'attributes'})
        self.assertEqual((cls['class_uri'], cls['description'], cls['see_also']),
                         ('pixlnd:' + owner, description, anchors))
        self.assertEqual(set(cls['attributes']), set(facts))
        for name, (number, meaning) in facts.items():
            slot = cls['attributes'][name]
            self.assertEqual(slot, {'alias': name, 'slot_uri': 'pixlnd:' + owner + '/' + name,
                                   'range': 'integer', 'required': True, 'equals_number': number,
                                   'description': meaning, 'see_also': anchors})
            self.assertIs(type(slot['equals_number']), int)
        # SAME raw-first oracle rejects all declaration mutants before SDK work.
        view = SchemaView(str(path))
        declared = view.get_class(owner)
        self.assertEqual((str(declared.class_uri), declared.description, declared.see_also),
                         ('pixlnd:' + owner, description, anchors))
        self.assertIsNone(declared.is_a)
        self.assertFalse(declared.slots or declared.slot_usage or declared.mixins)
        self.assertEqual(set(declared.attributes), set(facts))
        self.assertEqual(set(view.class_slots(owner)), set(facts))
        for name, (number, meaning) in facts.items():
            for slot in (declared.attributes[name], view.induced_slot(name, owner)):
                self.assertEqual((slot.alias, str(slot.slot_uri), slot.range, slot.required,
                                  slot.description, slot.see_also),
                                 (name, 'pixlnd:' + owner + '/' + name, 'integer', True, meaning, anchors))
                self.assertTrue(isinstance(slot.equals_number, int) and not isinstance(slot.equals_number, bool))
                self.assertEqual(slot.equals_number, number)
                self.assertFalse(slot.identifier or slot.key or slot.multivalued or slot.inlined or slot.inlined_as_list)
                self.assertEqual((slot.minimum_cardinality, slot.maximum_cardinality, slot.exact_cardinality,
                                  slot.minimum_value, slot.maximum_value, slot.ifabsent), (None,) * 6)
        # Independent literal 7/7 native guard; never copy expectations from emitted output.
        fields = {'minimum-village-distance-blocks', 'maximum-village-distance-blocks',
                  'minimum-site-separation-blocks', 'sea-level-floor-clearance-blocks',
                  'terrain-apron-blocks', 'fallback-village-hub-width-blocks', 'fallback-village-hub-depth-blocks'}
        required = {'minimum-village-distance-blocks', 'maximum-village-distance-blocks',
                    'minimum-site-separation-blocks', 'sea-level-floor-clearance-blocks',
                    'terrain-apron-blocks', 'fallback-village-hub-width-blocks', 'fallback-village-hub-depth-blocks'}
        schema = (validator(owner).schema if path == SCHEMA else json.loads(JsonSchemaGenerator(
            str(path), top_class=owner, preserve_names=True, not_closed=False).serialize()))
        assert_declared_root(owner, fields, required, schema=schema, view=view)
        self.assertEqual(len(schema['$defs'][owner]['required']), 7)
        self.assertEqual(len(view.class_induced_slots(owner)), 7)
        return schema, {name: number for name, (number, _) in facts.items()}

    def test_initial_site_placement_contracts(self):
        schema, values = self._assert_initial_site_placement(SCHEMA)
        native = jsonschema.Draft201909Validator(schema)
        native.validate(values)
        props = schema['$defs']['initial-site-placement-profile']['properties']
        for name, number in values.items():
            self.assertEqual(props[name]['type'], 'integer')
            self.assertEqual(props[name]['const'], number)
        # Admission describes parameters, not actual geography or runtime H evaluation.
        for name in ('id', 'position', 'floor', 'ocean-fallback', 'reachable', 'connecting-width', 'state'):
            with self.subTest(unknown=name):
                errors = list(native.iter_errors(dict(values, **{name: True})))
                self.assertEqual({error.validator for error in errors}, {'additionalProperties'})

    def test_initial_site_placement_values(self):
        schema, values = self._assert_initial_site_placement(SCHEMA)
        native = jsonschema.Draft201909Validator(schema)
        native.validate(values)
        for name, number in values.items():
            bads = [{key: value for key, value in values.items() if key != name}]
            bads += [dict(values, **{name: value}) for value in
                     (number - 1, number + 1, None, True, False, str(number), number + 0.5, [], {})]
            for bad in bads:
                with self.subTest(field=name, bad=bad), self.assertRaises(jsonschema.ValidationError):
                    native.validate(bad)
        for bad in (None, True, False, 0, 192, 'root', [], [values], {}):
            with self.subTest(root=bad), self.assertRaises(jsonschema.ValidationError):
                native.validate(bad)

    def test_initial_site_placement_mutations(self):
        schema, values = self._assert_initial_site_placement(SCHEMA)
        from ontology_source_contracts import assert_declared_root

        owner = 'initial-site-placement-profile'
        original = SCHEMA.with_name('world.yaml').read_bytes()
        raw = yaml.safe_load(original)
        mutations = [('missing-class', ('classes', owner), None),
                     ('class-uri', ('classes', owner, 'class_uri'), 'pixlnd:wrong-placement'),
                     ('class-anchor', ('classes', owner, 'see_also'), []),
                     ('class-description', ('classes', owner, 'description'), 'wrong scope')]
        for name, number in values.items():
            base = ('classes', owner, 'attributes', name)
            mutations += [(name + '-' + facet, base + (facet,), replacement) for facet, replacement in
                          (('required', None), ('range', 'string'), ('equals_number', None),
                           ('alias', 'wrong-alias'), ('slot_uri', 'pixlnd:wrong-owner/' + name), ('see_also', []))]
            mutations.append((name + '-equals_number-changed', base + ('equals_number',), number + 1))
        with tempfile.TemporaryDirectory(prefix='placement-mutations-') as directory:
            target = Path(directory) / 'schema'
            shutil.copytree(SCHEMA.parent, target)
            module, path = target / 'world.yaml', target / SCHEMA.name
            for label, keys, replacement in mutations:
                changed = deepcopy(raw)
                cursor = changed
                for key in keys[:-1]:
                    cursor = cursor[key]
                key = keys[-1]
                if replacement is None:
                    del cursor[key]
                else:
                    cursor[key] = replacement
                module.write_text(yaml.safe_dump(changed, sort_keys=False))
                self.assertEqual(yaml.safe_load(module.read_text()), changed)
                with self.subTest(mutation=label), self.assertRaises(AssertionError):
                    self._assert_initial_site_placement(path)
                if label == 'minimum-village-distance-blocks-equals_number':
                    # Own copied entry/view/emission, not cached live schema or a rewritten schema.
                    mv = SchemaView(str(path))
                    self.assertIsNone(mv.induced_slot('minimum-village-distance-blocks', owner).equals_number)
                    emitted = json.loads(JsonSchemaGenerator(str(path), top_class=owner,
                                        preserve_names=True, not_closed=False).serialize())
                    fields = {'minimum-village-distance-blocks', 'maximum-village-distance-blocks',
                              'minimum-site-separation-blocks', 'sea-level-floor-clearance-blocks',
                              'terrain-apron-blocks', 'fallback-village-hub-width-blocks', 'fallback-village-hub-depth-blocks'}
                    required = {'minimum-village-distance-blocks', 'maximum-village-distance-blocks',
                                'minimum-site-separation-blocks', 'sea-level-floor-clearance-blocks',
                                'terrain-apron-blocks', 'fallback-village-hub-width-blocks', 'fallback-village-hub-depth-blocks'}
                    assert_declared_root(owner, fields, required, schema=emitted, view=mv)
                    bad = dict(values, **{'minimum-village-distance-blocks': 193})
                    with self.assertRaises(jsonschema.ValidationError):
                        jsonschema.Draft201909Validator(schema).validate(bad)
                    jsonschema.Draft201909Validator(emitted).validate(bad)
                    print('placement equality deletion: native broadening with unchanged guarded 7/7 closed root')
                module.write_bytes(original)
        self.assertEqual(len(mutations), 53)
        self.assertEqual(SCHEMA.with_name('world.yaml').read_bytes(), original)
        print('placement mutations: 53 SAME raw-first actual-YAML controls; one native equality broadening')


if __name__ == "__main__":
    unittest.main()
