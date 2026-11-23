"""Guarded native source admission; reversible source maps are declared in YAML."""

from copy import deepcopy
from functools import lru_cache

import jsonschema
from linkml_runtime.utils.schemaview import SchemaView
from test_ontology_schema import SCHEMA, generated
from test_ontology_schema_authoring import validate


@lru_cache(maxsize=1)
def source_view():
    return SchemaView(str(SCHEMA))


def assert_declared_root(name, properties, required, *, schema=None, view=None,
                         additional_properties=False):
    view = view or source_view()
    assert name in view.all_classes(), f"Missing declared source class: {name}"
    schema = generated(name) if schema is None else schema
    jsonschema.Draft201909Validator.check_schema(schema)
    definition = schema["$defs"][name]
    assert definition["type"] == "object"
    assert set(definition.get("properties", {})) == properties
    assert set(definition.get("required", [])) == required
    assert definition.get("additionalProperties", True) == additional_properties
    if "$ref" in schema:
        assert schema["$ref"] == "#/$defs/" + name
    for key, default in (("properties", {}), ("required", []), ("additionalProperties", True)):
        if "$ref" not in schema or key in schema:
            assert schema.get(key, default) == definition.get(key, default)
    return schema


@lru_cache(maxsize=None)
def class_contract(owner):
    view = source_view()
    assert owner in view.all_classes(), f"Missing declared source class: {owner}"
    slots = view.class_induced_slots(owner)
    fields = {slot.alias or slot.name for slot in slots}
    required = {slot.alias or slot.name for slot in slots
                if slot.required or slot.key or slot.identifier or str(slot.value_presence) == "PRESENT"}
    assert_declared_root(owner, fields, required, view=view)
    return view.get_class(owner), fields


def source_contract(name):
    return class_contract(name + "-source")


# Tests assert each walked class's generated contract; scripts/ontology_bind.py turns this off
# and validates once against the whole-schema JSON Schema instead.
CHECK_CONTRACTS = True


@lru_cache(maxsize=None)
def slot_fields(owner):
    return {slot.alias or slot.name for slot in inline_slots(owner)}


@lru_cache(maxsize=None)
def inline_slots(owner):
    return source_view().class_induced_slots(owner)


def _annotation(owner, name):
    annotation = owner.annotations[name] if name in owner.annotations else None
    return annotation.value if annotation else ""


def _entries(raw):
    if not isinstance(raw, dict):
        raise jsonschema.ValidationError("Source keyed collection must be an object")
    return [{"key": key, "value": deepcopy(value)} for key, value in raw.items()]


def _mapping(entries, fixed=()):
    if not isinstance(entries, list):
        raise jsonschema.ValidationError("Bound keyed collection must be a list")
    result = {}
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {"key", "value"}:
            raise jsonschema.ValidationError("Bound entry requires exactly key and value")
        key = entry["key"]
        if not isinstance(key, str) or key in result or key in fixed:
            raise jsonschema.ValidationError("Duplicate, non-string or fixed-section entry key")
        result[key] = deepcopy(entry["value"])
    return result


def _tuple_bound(value, positions):
    if isinstance(value, dict):
        if set(value) != set(positions):
            raise jsonschema.ValidationError("Bound tuple requires exactly its declared positions")
        return [_tuple(value[key], positions, True) for key in positions]
    if isinstance(value, list):
        raise jsonschema.ValidationError("Bound tuple must use positional objects")
    return value  # Native declared alternatives own scalar typing.


def _tuple_raw(value, positions):
    if isinstance(value, dict):
        raise jsonschema.ValidationError("Raw tuple must not be an object")
    if isinstance(value, list):
        if len(value) != len(positions):
            raise jsonschema.ValidationError("Raw tuple has wrong position count")
        return {key: _tuple(item, positions, False) for key, item in zip(positions, value)}
    return value  # Native declared alternatives own scalar typing.


def _tuple(value, positions, inverse):
    if inverse:
        return _tuple_bound(value, positions)
    return _tuple_raw(value, positions)


def _walk_entries(result, raw, fields, entries, inverse):
    fixed = fields - {entries}
    if inverse:
        if entries not in result:
            raise jsonschema.ValidationError("Missing bound entries")
        values = _mapping(result.pop(entries), fixed)
        if values.keys() & result.keys():
            raise jsonschema.ValidationError("Source reconstruction would overwrite a key")
        result.update(values)
    else:
        result = {key: value for key, value in result.items() if key in fixed}
        result[entries] = _entries({key: value for key, value in raw.items() if key not in fixed})
    return result


def _walk_path(result, path, inverse):
    parts = path.split(".")
    container = result
    for part in parts[:-1]:
        if not isinstance(container, dict) or part not in container:
            return
        container = container[part]
    if isinstance(container, dict) and parts[-1] in container:
        value = container[parts[-1]]
        container[parts[-1]] = _mapping(value) if inverse else _entries(value)


def _walk(owner_name, raw, inverse):
    if not isinstance(raw, dict):
        return deepcopy(raw)  # Native typing owns malformed containers.
    owner = source_view().get_class(owner_name)
    result = deepcopy(raw)
    if _annotation(owner, "source-map-entries") or _annotation(owner, "source-map-paths"):
        fields = class_contract(owner_name)[1] if CHECK_CONTRACTS else slot_fields(owner_name)
    else:
        fields = set()
    if inverse:
        result = _children(owner_name, result, True)
    entries = _annotation(owner, "source-map-entries")
    if entries:
        result = _walk_entries(result, raw, fields, entries, inverse)
    for path in _annotation(owner, "source-map-paths").split():
        _walk_path(result, path, inverse)
    return result if inverse else _children(owner_name, result, False)


def _source_reference(value, prefix, inverse):
    if isinstance(value, list):
        return [_source_reference(item, prefix, inverse) if isinstance(item, str) else deepcopy(item)
                for item in value]
    if not isinstance(value, str):
        return deepcopy(value)
    if inverse:
        return prefix + value
    if not value.startswith(prefix):
        raise jsonschema.ValidationError("Source reference lacks its declared literal prefix")
    return value[len(prefix):]


def _literal_null(slot, raw, inverse):
    if not _annotation(slot, "source-literal-null"):
        return False
    alias = slot.alias or slot.name
    value = raw[alias]
    if inverse and type(value) is dict and not value:
        raw[alias] = None
        return True
    if not inverse and value is None:
        raw[alias] = {}
        return True
    raise jsonschema.ValidationError("Only literal null maps to its source marker")


def _walk_inline(slot, value, inverse):
    if slot.multivalued and isinstance(value, list):
        return [_walk(slot.range, row, inverse) for row in value]
    if slot.multivalued and isinstance(value, dict):
        return {key: _walk(slot.range, row, inverse) for key, row in value.items()}
    if not slot.multivalued:
        return _walk(slot.range, value, inverse)
    return value


def _walk_map_union(slot, raw, alias, inverse):
    map_range = _annotation(slot, "source-map-union-range")
    if not map_range:
        return False
    if map_range not in source_view().all_classes():
        raise jsonschema.ValidationError("Source map union class is not declared")
    if isinstance(raw[alias], dict):
        raw[alias] = _walk(map_range, raw[alias], inverse)
    return True


def _tuple_slot(slot, value, positions, inverse):
    if slot.multivalued and isinstance(value, list):
        return [_tuple(member, positions, inverse) for member in value]
    return _tuple(value, positions, inverse)


def _children(owner, raw, inverse):
    for slot in inline_slots(owner):
        alias = slot.alias or slot.name
        if alias not in raw:
            continue
        if _literal_null(slot, raw, inverse):
            continue
        prefix = _annotation(slot, "source-reference-prefix")
        if prefix:
            raw[alias] = _source_reference(raw[alias], prefix, inverse)
            continue
        if _walk_map_union(slot, raw, alias, inverse):
            continue
        positions = _annotation(slot, "source-tuple-positions").split()
        if positions:
            raw[alias] = _tuple_slot(slot, raw[alias], positions, inverse)
        elif slot.inlined and slot.range in source_view().all_classes():
            raw[alias] = _walk_inline(slot, raw[alias], inverse)
    return raw


def _source_mapping(name, raw, inverse):
    if CHECK_CONTRACTS:
        source_contract(name)
    if not isinstance(raw, dict):
        raise jsonschema.ValidationError("Source root must be an object")
    return _walk(name + "-source", raw, inverse)


def bind_source(name: str, raw: dict) -> dict:
    return _source_mapping(name, raw, False)


def unbind_source(name: str, bound: dict) -> dict:
    return _source_mapping(name, bound, True)


def validate_source(name: str, raw: dict) -> None:
    bound = bind_source(name, raw)
    assert unbind_source(name, bound) == raw, "Source binding is not lossless"
    validate(name + "-source", bound)
