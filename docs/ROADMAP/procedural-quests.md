# Procedural quests & the Old Man (X → follow-up)

**Status:** built Dec 2011 – 2012, **cut Jan 2013** before alpha ("quests could remove a lot of the
freedom… too repetitive"). Redesigned "several times" 2013–2015 (Kotaku interview), shipped in 1.0
only as typed *missions*. The `old-man` NPC (alpha entity id 18) and item type 21 "special
accessories" (amulet1/2, jewel case, key, medicine, antivenom, band-aid, crutch, bandage, salve)
are the data remnants.

## What existed
- **Kill quests** with randomly generated text in EN + DE from phrase sets; quest region
  highlighted on the minimap; progress shown under the minimap; XP reward (2011-12-30).
- **"Find someone" quests** (2012-07); quest lines planned.
- Pre-2019 concept (wiki:Quests, wiki:Old_Man): quest log; quests carry a **rarity colour**;
  example chain: kill boss → note → find Amulet → return to NPC; Deadlands "Drolu Herbs into a
  cauldron"; Old Man as giver/vendor.
- 2015 faction tweets implied quest hooks: find a paladin's horse, examine a Monstrosity animated
  by Necromancers, save an NPC being cooked by Skeleton Knights.
- Picroma 2013 "Planned: procedural quests with varying story, creatures and places" + lore.

## Ontology hooks to add when picked up
- `quest` class: id, template (kill / find-npc / fetch-item / escort / deliver / investigate),
  rarity tier, giver `npc-role`, target refs (creature / poi / item), text seed, reward table,
  state machine (offered → active → objective-done → turned-in / failed / expired).
- `quest-template` instances with EN phrase sets; DE optional.
- Re-enable `item-types.json#special-accessory` subtypes as quest items.
- `npc-role: old-man` (quest giver + vendor of quest consumables).
- HUD: quest log screen, minimap region highlight, progress widget.
- Generator `gen-quests` per land per day; invariant: never require an unreachable target;
  targets must exist within N lands; daily expiry aligned with `game-clock` midnight reset.
- Relation `quest → mission-type` so 1.0 missions become quest templates instead of a parallel
  system.

## Design notes
- Wollay's stated risk: repetition and loss of freedom. Mitigate by keeping quests optional,
  short, tied to existing mission sites, and rewarding exploration stats/lore rather than gating.
- Faction quests (`factions.json`) are the natural first templates.

## Online documentation
- Devlog Dec 2011 (quest system): http://web.archive.org/web/2014/http://wollay.blogspot.com/2011_12_01_archive.html
- Devlog Jul 2012 ("find someone"): http://web.archive.org/web/2014/http://wollay.blogspot.com/2012_07_01_archive.html
- Devlog Jan 2013 (quests dropped): http://web.archive.org/web/2014/http://wollay.blogspot.com/2013_01_01_archive.html
- Wiki: https://cubeworld.fandom.com/wiki/Quests , https://cubeworld.fandom.com/wiki/Old_Man , https://cubeworld.fandom.com/wiki/Missions
- Kotaku 2015 status interview: https://kotaku.com/over-a-year-later-cube-world-finally-has-a-few-new-thi-1736067016
- Faction tweets 2015: https://www.siliconera.com/cube-world-is-still-alive-gets-demons-ghosts-and-necromancers/
- Picroma 2013 feature page (Wayback): http://web.archive.org/web/2013/http://picroma.com/cubeworld
