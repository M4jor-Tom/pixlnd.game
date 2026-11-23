"""Bind ontology/instances/*.json to their LinkML source shapes, validate, write game data.

Every instances file `<name>.json` is bound with the YAML-declared reversible source maps,
checked to unbind losslessly, validated against `<name>-source` in one whole-schema JSON
Schema, then written to game/generated/instances/. Files without a declared source class
(not yet modeled) are copied verbatim. Identifier references between catalogs must resolve.
`--check` compares instead of writing.
Run: uv run --locked --project tools/ontology python scripts/ontology_bind.py [--check]
"""

import json
import sys
from pathlib import Path

import jsonschema
from linkml.generators.jsonschemagen import JsonSchemaGenerator

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tests"))
import ontology_source_contracts as contracts  # noqa: E402  (shared binder, single implementation)

SOURCE = ROOT / "ontology" / "instances"
TARGET = ROOT / "game" / "generated" / "instances"
# Referenced class → bound catalog (file, entries path) holding its ids. The schema declares the
# reference ranges but not which instances file owns each class's ids.
# ponytail: hand table; a schema annotation (e.g. `instances-catalog`) could replace it.
CATALOGS = {
    "ability": ("abilities", ["entries"]),
    "character-class": ("classes", ["entries"]),
    "creature": ("creatures", ["entries"]),
    "creature-family": ("creature-families", ["entries"]),
    "crafting-station": ("crafting-stations", ["entries"]),
    "faction": ("factions", ["entries"]),
    "ingredient": ("ingredients", ["entries"]),
    "landscape": ("landscapes", ["entries"]),
    "material": ("materials", ["entries"]),
    "npc-role": ("npc-roles", ["entries"]),
    "pet-food": ("pet-food", ["foods", "entries"]),
    "race": ("races", ["entries"]),
    "rarity": ("rarities", ["entries"]),
    "specialization": ("specializations", ["entries"]),
    "status-effect": ("status-effects", ["entries"]),
    "weapon-type": ("weapon-types", ["entries"]),
}
# Literal non-id owners accepted by the former GDScript validator (model_equipment.gd: owner "any").
SENTINELS = {("weapon-source-row", "class"): {"any"}}
# Recorded in docs/HANDOFF.md ("Deposit yield outside its declared reference range"); remove once decided.
KNOWN_FINDINGS = {"deposits.entries[3].value.yields: unknown ingredient 'sandstone'"}


def whole_schema() -> dict:
    return json.loads(
        JsonSchemaGenerator(
            str(contracts.SCHEMA), preserve_names=True, not_closed=False
        ).serialize()
    )


def bound_files() -> dict[str, str]:
    previous = contracts.CHECK_CONTRACTS
    try:
        contracts.CHECK_CONTRACTS = False
        return _bound_files()
    finally:
        contracts.CHECK_CONTRACTS = previous


def _bound_files() -> dict[str, str]:
    defs = whole_schema()["$defs"]
    out, errors, bound_by_name = {}, [], {}
    for path in sorted(SOURCE.glob("*.json")):
        raw = json.loads(path.read_text(encoding="utf-8"))
        if f"{path.stem}-source" not in defs:
            print(f"unmodeled, copied verbatim: {path.name}")
            out[path.name] = path.read_text(encoding="utf-8")
            continue
        try:
            bound = contracts.bind_source(path.stem, raw)
            if contracts.unbind_source(path.stem, bound) != raw:
                raise jsonschema.ValidationError("source binding is not lossless")
            schema = {"$defs": defs, "$ref": f"#/$defs/{path.stem}-source"}
            for error in jsonschema.Draft201909Validator(schema).iter_errors(bound):
                errors.append(f"{path.stem}: {error.json_path}: {error.message[:200]}")
        except (jsonschema.ValidationError, AssertionError, KeyError) as error:
            errors.append(f"{path.stem}: {error}")
            continue
        bound_by_name[path.stem] = bound
        out[path.name] = json.dumps(bound, ensure_ascii=False, indent=1, sort_keys=True) + "\n"
    errors += reference_errors(bound_by_name)
    if errors:
        sys.exit("ontology instances INVALID:\n  " + "\n  ".join(errors))
    return out


def catalog_ids(bound_by_name: dict) -> dict[str, set]:
    ids = {}
    for cls, (name, path) in CATALOGS.items():
        node = bound_by_name.get(name, {})
        for part in path:
            node = node.get(part, []) if isinstance(node, dict) else []
        ids[cls] = {entry["key"] for entry in node}
    return ids


def _items(value, inlined: bool) -> list[tuple]:
    """(index or None, item) pairs of a slot value; a keyed map of references holds no ids."""
    if isinstance(value, list):
        return list(enumerate(value))
    return [] if isinstance(value, dict) and not inlined else [(None, value)]


def reference_errors(bound_by_name: dict) -> list[str]:
    """Every value of a non-inlined identifier-range slot must name a known catalog entry."""
    view, ids, errors = contracts.source_view(), catalog_ids(bound_by_name), []
    classes = view.all_classes()

    def check(owner: str, key: str, targets: set, item, at: str) -> None:
        if not targets or not isinstance(item, str) or item in SENTINELS.get((owner, key), ()):
            return
        if not any(item in ids[t] for t in targets):
            errors.append(f"{at}: unknown {'/'.join(sorted(targets))} {item!r}")

    def walk_slot(owner: str, slot, value, path: str) -> None:
        key, inlined = slot.alias or slot.name, view.is_inlined(slot)
        branches = [slot, *slot.any_of, *slot.exactly_one_of]
        targets = set() if inlined else {b.range for b in branches if b.range in ids}
        inline = next((b.range for b in branches if b.range in classes), None) if inlined else None
        for i, item in _items(value, inlined):
            at = path if i is None else f"{path}[{i}]"
            check(owner, key, targets, item, at)
            if inline:
                walk(inline, item, at)

    def walk(owner: str, value, path: str) -> None:
        if isinstance(value, dict):
            for slot in contracts.inline_slots(owner):
                if (slot.alias or slot.name) in value:
                    walk_slot(owner, slot, value[slot.alias or slot.name], f"{path}.{slot.alias or slot.name}")

    for name, bound in bound_by_name.items():
        walk(f"{name}-source", bound, name)
    return [e for e in errors if e not in KNOWN_FINDINGS]


def main(check: bool) -> None:
    files = bound_files()
    current = {p.name: p.read_text(encoding="utf-8") for p in TARGET.glob("*.json")}
    if check:
        if current != files:
            stale = sorted(set(current) ^ set(files) | {n for n in files if current.get(n) != files[n]})
            sys.exit("stale game/generated/instances: " + " ".join(stale))
        return
    TARGET.mkdir(parents=True, exist_ok=True)
    for name in set(current) - set(files):
        (TARGET / name).unlink()
    for name, text in files.items():
        (TARGET / name).write_text(text, encoding="utf-8")
    print(f"bound {len(files)} instances files")


if __name__ == "__main__":
    main("--check" in sys.argv[1:])
