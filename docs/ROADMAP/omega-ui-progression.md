# Omega: GUI overhaul, cast bars, returning skill trees & new skills (Ω → follow-up)

**Status:** announced 2023-05-25; 2026 tweet: "All classes are fully functional now, including
some new skills! Next working on skill trees." Secondary reports (May 2026) mention a UI overhaul
and crafting stations. Nothing concrete (skill lists, tree layouts, numbers) is public.

## What v1 already covers
The hybrid ruleset (D1) brings back alpha XP, levels, 2 skill points/level and the skill tree,
and merges the 1.0 spec kits (R-ultimates, Shift utilities) with the alpha tree skills
(`rulesets.json#ruleset-hybrid.flags._ability-merge`). So "skill trees return" is v1, not Ω.

## Announced Ω items not in v1
- **New GUI** (Plasma-based UI in alpha/1.0; Omega redraws it). Screenshots show reworked HUD.
- **Cast bars** showing ability names and durations for players and enemies (ties to
  omega-signature-abilities.md telegraphs).
- **New class skills** (unnamed) on top of the existing kits; per-species abilities for enemies.
- Music: new Omega tracks on SoundCloud (wol_lay).

## Ontology hooks when picked up
- `ability.cast-time` and `ability.telegraph` fields (already implied by charge mechanics for
  M2); HUD element `cast-bar` in `ui.json#hud` (currently tagged Ω).
- Skill-tree layout: when Wollay publishes it, add `alpha-tree` equivalents (`omega-tree`) to
  `abilities.json`; keep stable ability ids so both layouts can coexist behind ruleset flags.
- New skills: add as `ability` entries with `versions: ["Ω"]` as they are revealed; do not invent.
- GUI: no ontology change; `ui.json` screens list is the contract for whatever skin is used.

## Open facts to watch
- Engine: 2023 posts say Vulkan; Feb–Jun 2024 tweets say Unreal Engine 5 experiments. Unresolved.
- Release model (free update vs new game), price, date: unknown as of 2025-01 (MassivelyOP).
- Whether region lock returns (Omega is "in the spirit of the alpha", so likely not).

## Online documentation
- Announcement: https://wollay.com/2023/05/25/new-blog-and-new-project-cube-world-omega/
- Feed: https://wollay.com/feed/
- 2024 UE5 tweets: https://x.com/wol_lay/status/1753019613753852220 , https://x.com/wol_lay/status/1781000511635722461
- 2026 classes/skill-trees tweet: https://x.com/wol_lay/status/2073003858264002920
- MassivelyOP 2025 status: https://massivelyop.com/2025/01/06/whatever-happened-to-multiplayer-voxel-rpg-cube-world-and-its-successor-cube-world-omega/
- Steam discussions on Omega: https://steamcommunity.com/app/1128000/discussions/0/3843304884851807866/
- Alpha skill tree reference: https://cubeworld.fandom.com/wiki/Skills , https://cubeworld.fandom.com/wiki/Skill_Points
- Plasma GUI write-up (prior art): https://github.com/coremaze/Plasma-Writeup
