#!/usr/bin/env bash
# Regenerate the committed Mermaid views of the LinkML schema with LinkML's own generators.
set -euo pipefail
cd "$(dirname "$0")/.."
out=docs/ontology/mermaid
gen() { uv run --locked --project tools/ontology "$@" ontology/schema/pixlnd.yaml; }
# ponytail: LinkML 1.12.1 leaves names like Class-reference or Character-class unquoted, and
# Mermaid parses their `class` as a keyword. Both generators emit class names as capitalized
# space-separated tokens (slots stay lowercase), so quote each: "…" for ER, `…` for classDiagram.
# Drop this once LinkML quotes them; it breaks if their output format changes.
quote() { sed -E "s/(^| )([A-Z][A-Za-z0-9-]*)/\1$1\2$1/g" "${@:2}"; }
rm -rf "$out" # also drops diagrams of classes removed from the schema
mkdir -p "$out"
# Keep the overview within Mermaid's 50,000-char budget: core roots and one-hop references.
# Complete attributes and every class remain in the separate, unfiltered classes/ views.
gen gen-erdiagram --exclude-attributes -f mermaid \
  --classes world --classes entity --classes item --classes ability --classes generators-source \
  --follow-references --max-hops 1 | quote '"' >"$out/overview.mmd" &
er=$!
gen gen-mermaid-class-diagram -d "$out/classes"
# It only writes fenced Markdown: drop the ``` fences and blank lines into plain .mmd files.
for f in "$out"/classes/*.md; do sed -E '/^```|^\s*$/d' "$f" | quote '`' >"${f%.md}.mmd"; done
rm "$out"/classes/*.md
wait "$er"
python3 tests/test_ontology_mermaid.py
