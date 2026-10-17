# Structurizr domain representation

The whole domain, including prose-only sections, is authoritative Structurizr DSL.
Definitions, properties, tables and competency-question references are structured records;
adjacent notes preserve prose, formulas, examples, uncertainty, permanent exclusions and
implementation deferrals. No Markdown authority remains in `ontology/domain/`.

Flat custom elements and explicit incidence edges describe the ontology, not C4 software
architecture or a reasoner. Reified relation definitions retain union endpoints, aggregate
cardinality, same-class roles and relation properties without false per-arm cardinalities or
self-edges. Undefined endpoint terms are labelled source terms, not new classes. Source family
membership is not inheritance. Formulas remain descriptive strings, never executable rules.
Explicit chapter-qualified anchors preserve action/profile references without conflating action
IDs with class IDs. Historical source coordinates are provenance, not live source links.

The consolidated Structurizr local viewer consumes staged DSL and clearly generated, read-only,
ignored documentation. It never writes back into authority. Runtime behavior, instance catalog
values, schemas and all gameplay implementation permissions are unchanged; this grants no
source-research or deferred-runtime work.

Effective authority: [workspace](../workspace.dsl), [chapter index](../domain/index.dsl).
Usage and representation conventions: [ontology guide](../README.md#structurizr-domain-tools).
