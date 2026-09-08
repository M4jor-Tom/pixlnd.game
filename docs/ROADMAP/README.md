# Roadmap — follow-ups outside v1

**Start with [todo_decide.md](todo_decide.md)** (decisions, all taken) and
[todo_implement.md](todo_implement.md) (work the shipped slices postponed) — open decisions and fact conflicts to settle
before any engine work.

Decisions D3/D4 (2026-09-07): every feature tagged `X` (cut / data-only) or `Ω` (Omega, announced
but unreleased) in `ontology/domain.md` is **not in v1**. Each theme below is a self-contained
follow-up spec (<100 lines) with the online documentation it was reconstructed from. When a theme
is picked up, land it in `ontology/` first (sync rule), then implement.

| file | theme | origin |
|---|---|---|
| [house-building.md](house-building.md) | blueprints, construction pieces, architect NPC, teleport home | devlog 2012-01 |
| [procedural-quests.md](procedural-quests.md) | generated kill/find/fetch quests, quest log, Old Man giver | devlog 2011-12 → cut 2013-01 |
| [cut-creatures.md](cut-creatures.md) | dragon, egg, unused variants, cut pet foods, rare pets, pet evolution | alpha data + wiki |
| [cut-items-gear.md](cut-items-gear.md) | bone/saurian/mammoth/parrot/obsidian armour, mana potion, potion rarities, quest accessories, mythical tier | alpha data + wiki |
| [cut-world-mechanics.md](cut-world-mechanics.md) | mushroom lands, kingdom frontier walls, rune stones, fire/stomp traps, injured debuff, pet quarter, paladin class | devlog + data |
| [omega-weather-ambient.md](omega-weather-ambient.md) | rain, snow, moving clouds, waves, freezing water, ambient life | wollay.com 2023 |
| [omega-procedural-models.md](omega-procedural-models.md) | fully procedural bodies, faces, expressions, procedural weapons/armour | wollay.com 2023 |
| [omega-signature-abilities.md](omega-signature-abilities.md) | per-species signature moves (eat, belly slide, divide, claw boomerang…) | wollay.com 2023 |
| [omega-world-generation.md](omega-world-generation.md) | coarse region map first, logical road/river/building networks, NPC travel | wollay.com 2023-07-30 |
| [omega-ui-progression.md](omega-ui-progression.md) | new GUI, cast bars, returning skill trees, new class skills | wollay.com 2023 + 2026 tweet |

Explicitly **dropped, not roadmapped**: region lock / `+` items / worn degradation (D4).
