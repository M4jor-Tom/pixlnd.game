## 2. Competency Questions

Each must be answerable from the model + instances. Data requirement in the right column.

| # | Question | Answered by |
|---|---|---|
| CQ1 | What can the player be? (race, gender, class, spec, appearance) | `race`, `character-class`, `specialization`, `appearance` |
| CQ2 | What can the player *do* in combat, through which semantic action, at what cost/cooldown, in which ruleset? | `ability`, `weapon-type` (moveset), `resource`, [controls](controls.md), `control-action` |
| CQ3 | How much damage / HP / armor does an item or character have? | `stat`, `item` + `item-stat-formula` generator, `level-formula` |
| CQ4 | What exists in the world and where? (biomes → flora, fauna, structures) | `landscape`, `terrain-feature`, `creature`, `flora`, `deposit`, `dungeon-type`, `poi-type`, relations `spawns-in`, `placed-in` |
| CQ5 | How is the world laid out numerically? (block, zone, region, mission grid, seed) | `world`, `zone`, `land`, `generators.json` scales |
| CQ6 | Which creature drops / is tamed by / can be ridden / can become a boss? | `creature`, `pet-food`, relations `tamed-by`, `drops`, `boss-ification` generator |
| CQ7 | What is an item? (type, subtype, material, rarity, level, cubes, name) | `item`, `item-type`, `material`, `rarity`, `affix`, `item-name` generator |
| CQ8 | How is gear obtained, crafted, upgraded, identified, sold? | `recipe`, `crafting-station`, `shop`, `formula`, `book-of-crafting`, `leftovers`, `spirit-cube`, `adaptation` |
| CQ9 | How does the player progress, in each ruleset? | `ruleset`, `skill-tree`, `power-level`, `artifact`, `region-lock`, `lore`, `gnome-supplier` |
| CQ10 | What tasks does the world offer and what do they reward? | `mission-type`, `arena`, relations `rewards` |
| CQ11 | Who lives in settlements and what services do they give? | `settlement`, `district`, `building`, `npc-role`, `shop` |
| CQ12 | How do NPCs / enemies behave, how many aggro points does each mob hold against each player, and whom does it target? (hostility, groups, patrols, schedules, potions) | `hostility`, `ai-behavior`, `creature` fields; relations `threat`, `current-target` and relation property `aggro-points` |
| CQ13 | What status effects exist and what applies them? | `status-effect`, relation `applies` |
| CQ14 | What is the day/night cycle, what resets, how does sleep work? | `game-clock` |
| CQ15 | What persists between sessions and across worlds? | `save-data`, `world`, `player-character` |
| CQ16 | How does multiplayer work in each version? | `multiplayer-mode`, `slash-command` |
| CQ17 | What is on screen, what does each control mean and how does each controller bind it? | `hud-element`, [controls](controls.md), [controller profiles](controller-profiles.md), `input-binding`, `option` |
| CQ18 | What was in which version, and what did fans ask to fix? | `ruleset` feature flags, `instances/versions.json` |
| CQ19 | What did Omega announce, retained as roadmap/reference rather than v1 content? | `Ω`-tagged classes/fields |

---

