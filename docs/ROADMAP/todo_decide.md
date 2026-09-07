# TODO — decisions to take BEFORE any engine work

Priority zero. Resume here with any agent. Context: `ontology/domain.md` (§1 scope, §7 open
points), `ontology/instances/*.json`, `docs/ROADMAP/README.md`. Already decided on 2026-09-07:
D1 hybrid ruleset, D2 Godot 4.7 + GDScript, D3/D4 cut + Omega content → roadmap, region lock /
`+` items / worn degradation dropped.

For each item: pick the default or write the override, then apply the "where to record" edit.
Mark done with `[x]`.

## A. Design decisions (owner)

- [ ] **D5 Multiplayer target** — dedicated server (alpha style, IP/DNS join, seed in server
  config) | Steam-friends P2P | both.
  Default: dedicated server (hybrid ruleset assumes it; top fan request).
  Record: `instances/rulesets.json#ruleset-hybrid.flags.multiplayer`, `domain.md §3.7 multiplayer-mode`.
- [ ] **D6 Undocumented numbers** — sources never contained these; we design them:
  - [ ] alpha per-point skill percentages (wiki uses "X%") → `abilities.json` `alpha-tree.per-point`
  - [ ] crit damage multiplier → `stats.json#stats.crit`
  - [ ] 1.0-style stat curve vs alpha curve (only alpha is reverse-engineered) → `stats.json`
  - [ ] vendor buy/sell price formula per rarity/level → `economy.json#prices`
  - [ ] artifact bonus % per pickup and diminishing rule → `key-items.json#artifact`
  - [ ] inventory stack cap → `domain.md §3.4 inventory`
  - [ ] per-species enemy HP/damage (only "white mobs 150–250 HP" known) → `creatures.json`
  - [ ] Circle of Power buff magnitude → `status-effects.json#circle-of-power`
  - [ ] per-weapon recipe quantities (only "5 iron cubes" + cotton armour table known) → `recipes.json#gear-weapons`
  Default for all: derive from the alpha curves in `stats.json#alpha-item-stat-formulas`,
  tune in play, keep as `generators.json` knobs.
- [ ] **D7 Alpha player cap** — 4 (vanilla, cuwo default) | 10 (alpha-era wiki) | configurable.
  Default: configurable, 4. Record: `generators.json#network-alpha.max-players`.
- [ ] **D8 Skin colour at creation** — existence unverified in original data (hair RGB only).
  Default: add it as a real option. Record: `races.json#_creation`.
- [ ] **D9 First-person zoom** — 2011 devlog feature; 1.0 unverified. Default: keep.
  Record: `ui.json#camera`.
- [ ] **D10 Ability merge in hybrid** — alpha-removed skills (war frenzy, bulwark, aim,
  scout's swiftness, mana shield, shuriken attack) return as skill-tree nodes next to the steam
  R-ultimates; exact tree layout (columns, unlock costs) is ours to draw.
  Default: 3 class columns as alpha + 1 "ultimate" column holding the steam R skill.
  Record: `abilities.json` `alpha-tree` on every S-only skill, `domain.md §3.5 skill-tree`.

## B. Conflicting facts (pick a side)

- [ ] **F1 Steam ability numbers** (default = wiki / patch-note value, listed first):
  - [ ] Heroic Shout: taunt 5 m + 50 % HP over 10 s **vs** short "take more damage" debuff
  - [ ] Guardian Toughness: +25 % max HP **vs** +25 flat HP (likely bug)
  - [ ] Battle Fury trigger: ~12–14 % per hit **vs** on critical hit
  - [ ] Shadow Shooter duration: 30 s **vs** ~20 s
  - [ ] Bubbles count: 8 **vs** 6
  - [ ] Shuriken Toss cost: 25 stamina (patch 0.9.2-0) **vs** 50
  - [ ] R-ultimate cooldowns: per-skill (20/30/40/60 s) **vs** blanket 40 s / 30 s
  Record: `abilities.json` (strip the `?` from the chosen value).
- [ ] **F2 Rideable flags** for beaver, chicken, crow, koala, monkey, parrot, penguin, seagull,
  squirrel, crab, hornet, fly, bumblebee, warthog — wiki table says yes (1.0.0-1 all-rideable
  bug), creature pages say no. Default: per-page (no), already applied.
  Record: `pet-food.json` `rideable: "table"` → true/false.
- [ ] **F4 Alpha land difficulty** — land level rises with distance from spawn (devlog, wiki)
  **vs** "creatures of all power ranges (1–100) in every land" (Picroma 2013). Press saw mixed
  levels per land. Default: level-by-distance base + per-land spread.
  Record: `generators.json#land.alpha-level`, `landscapes.json#_shared`.
- [ ] **F6 Land geometry** — is one gameplay land one internal 64×64-zone region cell?
  Water level, heightmap and noise parameters unknown (alpha generator only exists as x86 code
  wrapped by cuwo). Default: one land = one region cell; our own noise.
  Record: `generators.json#world-scales`, `domain.md §3.1 land`.
- [ ] **F8 Spirit Bell duration** — 30 s (wiki) **vs** ~45 s (guide). Default 30.
  Record: `key-items.json#spirit-bell`.
- [ ] **F9 Life Potion station** — anywhere **vs** campfire. Default anywhere.
  Record: `consumables.json#life-potion`.
- [ ] **F10 Alpha-id creatures the wiki calls "not in alpha"** — panther 29, spectrino 80,
  rune giant 118, duckbill 74, ancient guardians 77/78. Default: treat as S creatures with
  reserved alpha ids. Record: `creatures.json` `v`.
- [ ] **F11 Warthog food** (banana-mash 170) — obtainable (1.0 guides) **vs** cut (wiki).
  Default obtainable. Record: `pet-food.json`.

## C. Process gaps (do, no decision needed)

- [ ] Install Godot 4.7.x; run `godot --headless -s ontology/validate.gd` — `model.gd` has never
  been parsed by the engine (only the node cross-ref check passed).
- [ ] `git init` the repo; nothing is committed yet.
- [ ] Optional: keep the raw research corpus (740 wiki pages, cuwo clone) — it lived in the
  session scratchpad and is gone; only `ontology/research/*.md` remains.

## D. Not decisions (info)

- F3 (`+` items / lore) is moot: region lock dropped.
- F5 partially split into D7/D8/D9 above.
- F7 Omega status (Vulkan vs UE5, silence since 2024) is roadmap-only.

## After all boxes are ticked
Run the `router` skill: scaffold the Godot project, derive architecture from `domain.md §3`
classes, load `instances/` through `ontology/model.gd`.
