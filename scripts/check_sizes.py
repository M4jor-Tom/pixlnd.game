"""Hard GDScript physical-line limits; parse boundaries with the pinned gdtoolkit."""

import sys
from pathlib import Path

from gdtoolkit.parser import parser

FUNCTIONS = {
    "func_def", "abstract_func_def", "lambda",
    "property_custom_getter", "property_custom_setter",
}
BLOCKS = FUNCTIONS | {
    "if_stmt", "if_branch", "elif_branch", "else_branch", "while_stmt",
    "for_stmt", "for_stmt_typed", "match_stmt", "match_branch", "guarded_match_branch",
}


def last_line(node):
    # Suite metadata includes trailing comments/newlines and the next dedent.
    if node.data in BLOCKS:
        return last_line(node.children[-1])
    return node.meta.end_line


if len(sys.argv) == 1:
    sys.exit("No GDScript sources to check")

errors = []
for filename in sys.argv[1:]:
    source = Path(filename).read_text(encoding="utf-8")
    lines = source.count("\n") + bool(source and not source.endswith("\n"))
    if lines > 600:
        errors.append(f"{filename}: file length {lines} exceeds 600")
    tree = parser.parse(source, gather_metadata=True)
    for node in tree.iter_subtrees():
        if node.data not in FUNCTIONS:
            continue
        size = last_line(node) - node.meta.line + 1
        if size > 100:
            name = node.children[0].children[0] if node.data in {"func_def", "abstract_func_def"} else node.data
            errors.append(f"{filename}:{node.meta.line}: {name}: function length {size} exceeds 100")

if errors:
    print("\n".join(errors))
    sys.exit(1)
print("GDScript size limits passed (600 lines/file; 100 lines/function).")
