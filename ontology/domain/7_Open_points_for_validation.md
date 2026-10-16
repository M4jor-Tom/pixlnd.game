## 7. Open points for validation

### Current hybrid decision status (2026-10-16)

The four selected gameplay choices are resolved in canonical definitions:
[landscape availability](3_Classes.md#landscape), [ordinary Lion tameability](3_Classes.md#creature),
[Resistance meaning](3_Classes.md#stat) and [fixed gear HP](3_Classes.md#item).
No unresolved entry remains in the game-choice backlog. Further work requires owner direction;
see [the handoff](../../docs/HANDOFF.md).

Implementation remains separately unauthorized; see
[deferred work](../../docs/ROADMAP/todo_implement.md). Resistance's numerical mitigation formula
is **not approved**: obtain owner approval before implementation, never infer a coefficient,
DOT/damage-type classification or stacking rule from its settled meaning.

### Reference uncertainties, not new hybrid defaults

Historical Swamp Lands identity, disputed Lion tameability, conflicting Resistance descriptions
and the disputed historical gear-HP roll expression remain research uncertainties, not alternate
hybrid rules. Rare-zone rarity, the alpha `mana-cubes` field, species-specific chase observations,
source stat-display comparisons and Omega engine/status reports also remain uncertain.
They neither override designed hybrid rules nor enable cut/Omega content. Other `?` annotations
stay attached to their source records; any unresolved implication for active hybrid behavior
must be decided before implementation, not inferred from a historical flag or loader fallback.
Research is not exhausted by resolving the selected gameplay choices.
