# game/ — engine layer

Consumes `ontology/`; never redefines it. New gameplay = ontology first (sync rule), then code here.

## Data flow
- `OntologyDB` (autoload) loads `ontology/instances/*.json` through `ontology/model.gd` at start,
  runs the §5 constraints, aborts the process on any error. Read-only for the whole run.
- `OntologyDB.ruleset` = the default ruleset (hybrid). Gate features with `OntologyDB.flag("…")`.
- `OntologyDB.design` = `generators.json#design`, the owner-designed numbers (D6/D11).
- Mutable state (world, characters, inventory) belongs to `save-data` (§3.7), not to the autoload.

## Folders follow domain.md §3 (create a folder when its first scene lands)
| §3 section | folder | first pieces |
|---|---|---|
| 3.1 World | `world/` | zone streaming, land/landscape generation (`generators.json#terrain`) |
| 3.2 Entities | `entities/` | player-character, creature, npc, pet |
| 3.3 Combat | `combat/` | ability runtime, weapon movesets, status effects |
| 3.4 Items | `items/` | item instance, inventory, crafting, shop |
| 3.5 Progression | `progression/` | level formula, skill tree, artifacts |
| 3.6 Missions | `missions/` | mission-type runtime, arena |
| 3.7 Meta | `meta/` | server/client (`godot-multiplayer`), input map, HUD, save-data |

## Checks
```
nix develop -c godot --headless -s ontology/validate.gd   # ontology constraints
nix develop -c godot --headless --quit                    # autoload + main scene boot
```
