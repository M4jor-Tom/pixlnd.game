---
name: "split-linkml-declarations-without-wire-changes"
description: "Split pixlnd LinkML YAML modules that exceed ontology-schema-size (150 lines), especially when a single class has too many inline attributes; preserve native JSON Schema, binding and GDScript generation."
version: 1
created: "2026-11-21"
updated: "2026-11-21"
---
## When to Use
Use for authoring-only schema reorganizations, not changes to gameplay, saves, validation semantics, or source instance shapes.

## Procedure
1. Record the baseline and run the actual ontology-schema-size hook predicate. Snapshot each class and enum; compare complete field facet dictionaries in attachment order, keyed by wire alias, using duplicate-aware YAML parsing.
2. Keep public module filenames and import topic parts directly using child schema IDs. Move small classes intact; attach large classes' factored slots in the old order using globally unique internal names and the original aliases and URIs. Retain family-root references in the root when moving them would create an import cycle.
3. Pilot one owner. Compare the native JSON Schema from separate baseline/candidate processes, preserving required and other array order; render GDScript with the established local linkml-gdscript tool and compare actual files. Use the instance hook to validate lossless bind/unbind and verify byte equality of its output.
4. Update authored test lookups to resolve actual attached declarations before constructing alias maps and reject duplicate attachments/aliases. Exercise the same oracle on an unmodified flattened copy_schema tree, then edit real authored slot dictionaries for mutations and retain their separate native admissions or no-effects.
5. Update Markdown links to the declaring module and element, regenerate diagrams, and run the short hooks. An alternate temporary Git index can make new YAML visible to --all-files without changing the owner's staged work.

## Pitfalls
- Moving declarations is not permission to change data or weaken the hook. Mermaid shows authoring slot names rather than JSON aliases; review these differences separately from GDScript and binding.
- The LinkML view may deduplicate repeated attachments before induction; reject duplicates at the authored layer.
- Full LinkML and Godot runs can outlast short focused budgets. Keep exit receipts distinct for in-scope tests, short hooks and the full gate; never claim a timeout or pre-existing failure as a pass.

## Verification
1. Every module is <=150 physical lines and the physical declarations have no duplicate keys or owners.
2. Before/after authored facets and native schemas are equal; generated GDScript and bound inputs are byte-identical.
3. Both public families resolve standalone, from pixlnd.yaml, and through the existing flattened mutation fixture. Same-oracle mutations still hit their original semantic targets.