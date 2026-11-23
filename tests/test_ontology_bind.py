"""scripts/ontology_bind.py rejects malformed rows and dangling catalog references."""

import copy
import json
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
import jsonschema  # noqa: E402
import ontology_bind as bind  # noqa: E402


def bound(name):
    raw = json.loads((bind.SOURCE / f"{name}.json").read_text(encoding="utf-8"))
    return bind.contracts.bind_source(name, raw)


class OntologyBindTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.enterClassContext(patch.object(bind.contracts, "CHECK_CONTRACTS", False))
        cls.defs = bind.whole_schema()["$defs"]
        names = {name for name, _ in bind.CATALOGS.values()}
        cls.catalogs = {name: bound(name) for name in sorted(names)}

    def test_shape_errors_are_rejected(self):
        creatures = copy.deepcopy(self.catalogs["creatures"])
        creatures["entries"][0]["value"]["bogus"] = 1
        schema = {"$defs": self.defs, "$ref": "#/$defs/creatures-source"}
        self.assertTrue(list(jsonschema.Draft201909Validator(schema).iter_errors(creatures)))

    def test_current_references_resolve(self):
        self.assertEqual(bind.reference_errors(self.catalogs), [])

    def test_dangling_references_are_reported(self):
        catalogs = copy.deepcopy(self.catalogs)
        catalogs["specializations"]["entries"][0]["value"]["class"] = "bard"
        catalogs["creatures"]["entries"][0]["value"]["tame"] = "no-such-food"
        errors = bind.reference_errors(catalogs)
        self.assertTrue(any("unknown character-class 'bard'" in e for e in errors), errors)
        self.assertTrue(any("unknown pet-food 'no-such-food'" in e for e in errors), errors)


class BinderIsolationTests(unittest.TestCase):
    def test_bound_files_restores_guard_on_failure(self):
        with patch.object(bind.contracts, "CHECK_CONTRACTS", True):
            with patch.object(bind, "whole_schema", side_effect=RuntimeError("probe")):
                with self.assertRaisesRegex(RuntimeError, "probe"):
                    bind.bound_files()
            self.assertIs(bind.contracts.CHECK_CONTRACTS, True)

    def test_set_up_class_restores_guard_on_failure(self):
        class IsolatedOntologyBindTest(OntologyBindTest):
            pass

        with patch.object(bind.contracts, "CHECK_CONTRACTS", True):
            try:
                with patch.object(bind, "whole_schema", side_effect=RuntimeError("probe")):
                    with self.assertRaisesRegex(RuntimeError, "probe"):
                        IsolatedOntologyBindTest.setUpClass()
            finally:
                IsolatedOntologyBindTest.doClassCleanups()
            self.assertIs(bind.contracts.CHECK_CONTRACTS, True)


if __name__ == "__main__":
    unittest.main()
