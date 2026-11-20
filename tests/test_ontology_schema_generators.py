"""Complete unchanged generator configuration, not generator execution."""

from copy import deepcopy
import unittest

import jsonschema

from ontology_source_contracts import validate_source
from test_ontology_schema_authoring import catalog


class GeneratorSourceTests(unittest.TestCase):
    def test_climate_collection_tuple_binding(self):
        from ontology_source_contracts import _walk

        climate = catalog("generators")["design"]["climate"]
        bound = _walk("generator-design-climate", climate, False)
        self.assertEqual(bound["rules"][0], {"first": "oceans", "second": "continent < 0.3"})
        self.assertEqual(_walk("generator-design-climate", bound, True), climate)

    def test_complete_generators_source(self):
        row = catalog("generators")
        validate_source("generators", row)
        self.assertIsInstance(row["design"]["item-stat-curve"], str)

    def test_required_generator_design_groups(self):
        row = catalog("generators")
        for key in ("movesets", "terrain", "initial-encounters", "artifact"):
            bad = deepcopy(row)
            del bad["design"][key]
            with self.subTest(key=key), self.assertRaises(jsonschema.ValidationError):
                validate_source("generators", bad)


if __name__ == "__main__":
    unittest.main()
