"""Cognitive-complexity and length rules of scripts/check_python_bash.py."""

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "scripts"))
import check_python_bash as cpb  # noqa: E402

PY = [
    ("if", "def f():\n    if a:\n        pass\n", {"f": 1}),
    ("nested_if", "def f():\n    for x in y:\n        if a:\n            pass\n", {"f": 3}),
    ("elif_else", "def f():\n    if a:\n        pass\n    elif b:\n        pass\n    else:\n        pass\n", {"f": 3}),
    ("else_nested_if", "def f():\n    if a:\n        pass\n    else:\n        if b:\n            pass\n", {"f": 4}),
    ("bool_runs", "def f():\n    x = a and b and c\n    y = a and b or c\n", {"f": 3}),
    ("ternary_nested", "def f():\n    for x in y:\n        z = 1 if a else 2\n", {"f": 3}),
    ("except_with", "def f():\n    with m:\n        try:\n            pass\n        except A:\n            pass\n        except B:\n            pass\n", {"f": 2}),
    ("match_in_if", "def f():\n    if a:\n        match x:\n            case 1:\n                pass\n", {"f": 3}),
    ("comprehension", "def f():\n    return [x for x in y if x and z]\n", {"f": 1}),
    ("lambda", "def f():\n    g = lambda: 1 if a else 2\n", {"f": 2}),
    ("nested_def", "def f():\n    def g():\n        if a:\n            pass\n    if b:\n        pass\n", {"f": 1, "g": 1}),
    ("loop_header_ternary", "def f():\n    for x in (a if b else c):\n        pass\n", {"f": 2}),
    ("ternary_header_ternary", "def f():\n    z = 1 if (a if b else c) else 2\n", {"f": 2}),
    ("method", "class C:\n    def m(self):\n        while a:\n            pass\n", {"m": 1}),
]
SH = [
    ("bash_if_chain", "f() {\n  if a; then :; elif b; then :; else :; fi\n}\n", {"f": 3}),
    ("bash_nested", "f() {\n  for i in 1; do\n    if a; then :; fi\n  done\n}\n", {"f": 3}),
    ("bash_case_until", "f() {\n  case $1 in a) ;; esac\n  until a; do :; done\n}\n", {"f": 2}),
    ("bash_bool_cmd", "f() {\n  a && b && c\n  a && b || c\n  a | b\n}\n", {"f": 3}),
    ("bash_bool_test", "f() {\n  [[ a && b || c ]]\n}\n", {"f": 2}),
    ("bash_while_header", "f() {\n  while if a; then :; fi; do :; done\n}\n", {"f": 2}),
    ("bash_nested_func", "f() {\n  g() {\n    if a; then :; fi\n  }\n}\n", {"f": 0, "g": 1}),
]


class CheckPythonBash(unittest.TestCase):
    def test_cognitive(self):
        for parse, table in ((cpb.python_functions, PY), (cpb.bash_functions, SH)):
            for name, source, expected in table:
                with self.subTest(name):
                    self.assertEqual({f.name: f.cognitive for f in parse(source)}, expected)

    def test_lengths(self):
        (f,) = cpb.python_functions("def f():\n" + "    x = 1\n" * 99)
        self.assertEqual(f.length, 100)
        (f,) = cpb.python_functions("def f():\n    x = 1\n    # trailing\n")
        self.assertEqual(f.length, 2)
        (f,) = cpb.python_functions('def f():\n    x = """a\nb\nc"""\n')
        self.assertEqual(f.length, 4)
        (f,) = cpb.bash_functions("f() {\n" + "  :\n" * 98 + "}\n")
        self.assertEqual(f.length, 100)

    def test_bash_parse_error(self):
        with self.assertRaises(ValueError):
            cpb.bash_functions("f() {\n")

    def test_main(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "big.py"
            path.write_text("x = 1\n" * 601)
            out = io.StringIO()
            with contextlib.redirect_stdout(out):
                self.assertEqual(cpb.main([str(path)]), 1)
            self.assertIn("file length 601 exceeds 600", out.getvalue())


if __name__ == "__main__":
    unittest.main()
