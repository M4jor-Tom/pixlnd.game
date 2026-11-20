"""Hard Python/Bash limits: file lines, function lines, cognitive complexity."""

import ast
import json
import subprocess
import sys
from collections import namedtuple
from pathlib import Path

Function = namedtuple("Function", "name line length cognitive")
LOOPS = (ast.For, ast.AsyncFor, ast.While)
DEFS = (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)
BASH_LOOPS = {"ForClause", "WhileClause", "CaseClause"}
MAX_FILE_LINES, MAX_FUNCTION_LINES, MAX_COGNITIVE = 600, 100, 15


def py_if(node, nesting):
    total, cur = 0, node
    while cur:  # elif chain: +1 each, without nesting
        total += (1 + nesting if cur is node else 1) + py_score(cur.test, nesting, cur)
        total += sum(py_score(s, nesting + 1, cur) for s in cur.body)
        orelse, nxt = cur.orelse, None
        if len(orelse) == 1 and isinstance(orelse[0], ast.If) and orelse[0].col_offset == cur.col_offset:
            nxt = orelse[0]
        elif orelse:
            total += 1 + sum(py_score(s, nesting + 1, cur) for s in orelse)
        cur = nxt
    return total


def py_score(node, nesting, parent=None):
    """Cognitive score of node's subtree, not entering nested defs/classes."""
    if isinstance(node, DEFS):
        return 0
    if isinstance(node, ast.If):
        return py_if(node, nesting)
    total, step = 0, 0  # step: extra depth for body/orelse/cases only, never headers
    if isinstance(node, LOOPS + (ast.Match, ast.ExceptHandler, ast.IfExp)):
        total, step = 1 + nesting, 1
    elif isinstance(node, ast.Lambda):
        step = 1
    elif isinstance(node, ast.BoolOp) and not (
        isinstance(parent, ast.BoolOp) and type(parent.op) is type(node.op)
    ):
        total = 1
    for name, value in ast.iter_fields(node):
        depth = nesting + (step if name in {"body", "orelse", "cases"} else 0)
        total += sum(py_score(c, depth, node) for c in (value if isinstance(value, list) else [value]) if isinstance(c, ast.AST))
    return total


def python_functions(source):
    tree = ast.parse(source)
    return [
        Function(n.name, n.lineno, n.end_lineno - n.lineno + 1, sum(py_score(s, 0) for s in n.body))
        for n in ast.walk(tree)
        if isinstance(n, (ast.FunctionDef, ast.AsyncFunctionDef))
    ]


def sh_score(node, nesting, op=None):
    """Cognitive score of a shfmt JSON subtree; op is the enclosing && / || (if any)."""
    if isinstance(node, list):
        return sum(sh_score(c, nesting, op) for c in node)
    if not isinstance(node, dict):
        return 0
    kind = node.get("Type")
    if kind == "FuncDecl":
        return 0
    if kind == "IfClause":
        total = 1 + nesting + sh_score(node.get("Cond"), nesting) + sh_score(node.get("Then"), nesting + 1)
        clause = node.get("Else")
        while clause:  # elif has a non-empty Cond; plain else is just +1
            total += 1 + sh_score(clause.get("Cond"), nesting) + sh_score(clause.get("Then"), nesting + 1)
            clause = clause.get("Else")
        return total
    if kind in BASH_LOOPS:
        return 1 + nesting + sum(sh_score(v, nesting + (k in {"Do", "Items"})) for k, v in node.items())
    if kind in {"BinaryCmd", "BinaryTest"} and node["Op"] in {"&&", "||"}:
        own = 0 if op == node["Op"] else 1
        return own + sum(sh_score(v, nesting, node["Op"]) for v in node.values())
    return sum(sh_score(v, nesting, None if kind else op) for v in node.values())


def sh_functions(node):
    """Yield every FuncDecl in a shfmt JSON tree, outer before nested."""
    if isinstance(node, dict):
        if node.get("Type") == "FuncDecl":
            start, end = node["Pos"]["Line"], node["End"]["Line"]
            yield Function(node["Name"]["Value"], start, end - start + 1, sh_score(node["Body"], 0))
        node = list(node.values())
    if isinstance(node, list):
        for child in node:
            yield from sh_functions(child)


def bash_functions(source):
    run = subprocess.run(
        ["shfmt", "-ln", "bash", "--to-json"], input=source, capture_output=True, text=True, check=False
    )
    if run.returncode:
        raise ValueError(run.stderr.strip())
    return list(sh_functions(json.loads(run.stdout)))


def check_file(path):
    source = Path(path).read_text(encoding="utf-8")
    lines = source.count("\n") + bool(source and not source.endswith("\n"))
    errors = [f"{path}: file length {lines} exceeds {MAX_FILE_LINES}"] if lines > MAX_FILE_LINES else []
    try:
        functions = (python_functions if path.endswith(".py") else bash_functions)(source)
    except (SyntaxError, ValueError) as error:
        return errors + [f"{path}: parse error: {error}"]
    for fn in functions:
        where = f"{path}:{fn.line}: {fn.name}"
        if fn.length > MAX_FUNCTION_LINES:
            errors.append(f"{where}: function length {fn.length} exceeds {MAX_FUNCTION_LINES}")
        if fn.cognitive > MAX_COGNITIVE:
            errors.append(f"{where}: cognitive complexity {fn.cognitive} exceeds {MAX_COGNITIVE}")
    return errors


def main(paths):
    errors = [error for path in paths for error in check_file(path)]
    if errors:
        print("\n".join(errors))
        return 1
    print(
        f"Python/Bash limits passed ({MAX_FILE_LINES} lines/file; {MAX_FUNCTION_LINES} lines/function; "
        f"cognitive complexity {MAX_COGNITIVE})."
    )
    return 0


if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.exit("No Python or Bash sources to check")
    sys.exit(main(sys.argv[1:]))
