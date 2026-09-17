# TODO — decisions to take before the affected implementation slice

Priority zero. Resume here with any agent. Context: `ontology/domain.md` (§1 scope, §7 open
points), `ontology/instances/*.json`, `docs/ROADMAP/README.md`. Already decided on 2026-09-07:
D1 hybrid ruleset, D2 Godot 4.7 + GDScript, D3/D4 cut + Omega content → roadmap, region lock /
`+` items / worn degradation dropped.

**Status 2026-09-13:** D1–D26 and the original fact conflicts below remain decided. The ontology
reconciliation in §E records approved corrections and additional open questions. Resolve an open
question before its affected slice; do not reopen settled choices. Designed numbers live in
`ontology/instances/generators.json#design`.

## A. Design decisions (owner)

- [x] **D5 Multiplayer target** — dedicated server (alpha style, IP/DNS join, seed in server
  config). Recorded: `rulesets.json#ruleset-hybrid.flags.multiplayer`, `domain.md §3 multiplayer-mode`.
- [x] **D6 Undocumented numbers** — all designed, recorded in `generators.json#design` + the
  file each row names:
  - [x] alpha per-point skill: flat +5 % effect / −5 % cooldown per point, floor 25 %, uncapped
  - [x] crit: ×2.0, chance above 100 % adds to the multiplier → `stats.json#stats.crit`
  - [x] item stat curve: alpha curve only, no 1.0 tier curve → `stats.json`
  - [x] prices: buy = base × level × rarity mult (1/2/4/8/16), sell 25 % → `economy.json#prices`
  - [x] artifacts: +5 % first, ×0.9 each next, floor 1 %; one traversal stat **and** attack + max HP
    with the same rule → `key-items.json#artifact`
  - [x] inventory stack cap: none → `domain.md §3 inventory`
  - [x] enemy HP/damage: cuwo npc-hp formula × per-family multiplier, white lvl-1 mob = 150–250 HP
  - [x] Circle of Power: +10 % attack, +10 % max HP in the land → `status-effects.json`
  - [x] recipes: cubes = 5 × size class (1/2/4), +1 gem per rarity tier above common → `recipes.json`
- [x] **D7 Alpha player cap** — configurable, default 4. Recorded: `generators.json#network-alpha`.
- [x] **D8 Skin colour at creation** — real option, per-race palette ours. Recorded: `races.json#_creation`.
- [x] **D9 First-person zoom** — kept. Recorded: `ui.json#camera`.
- [x] **D10 Ability merge in hybrid** — 3 alpha class columns (removed skills back at rank 3) +
  1 `ultimate` column holding the steam R skill, unlocked by 5 points in the spec's rank-3 skill.
  Recorded: `abilities.json` `alpha-tree` on every R skill, `domain.md §3 skill-tree`.
- [x] **D11 Hybrid gaps (2026-09-08)** — block gives MP (the bar specials spend); Regeneration =
  stamina only; artifacts 1–3 per land, seeded; `/pvp` dropped, PvP = `server.cfg` flag default off.
  Recorded: `generators.json#design` (`block-reward`, `regeneration`, `artifacts-per-land`, `pvp`).
- [x] **D12 World numbers (2026-09-08)** — zone 64², land 256² zones, 1 block = 1 m, sea level 96, fBm
  heightfield, climate rules, land names. Recorded: `generators.json#design.terrain|climate|names`,
  `landscapes.json#*.gen`.
- [x] **D13 Player movement, camera, keys (2026-09-08)** — walk/sprint/swim/jump/gravity/step-up/hitbox/stamina,
  orbit camera zoom range, hybrid key column. Recorded: `generators.json#design.movement|camera`, `keybinds.json#hybrid`.
- [x] **D14 Open-world spawns (2026-09-08)** — groups per zone, roster, hostility roll, NPC HP multiplier,
  wander/chase numbers. Recorded: `generators.json#design.spawns|enemy-hp`; wetlands roster fixed (`slimes` → ids).
- [x] **D15 Combat multipliers (2026-09-08)** — attack-power ×10, NPC damage ×12, armor floor 10 %, combo bonus,
  swing/windup/cooldown, respawn. Recorded: `generators.json#design.combat`, `classes.json#*.hp-mult`.
- [x] **D16 Simulation radius (2026-09-08)** — creatures beyond 80 blocks are frozen (fixes the physics catch-up
  spiral, 4 FPS). Recorded: `generators.json#design.spawns.ai.sim-radius`, `c-sim-radius`.
- [x] **D17 Runtime profiling and frame budget (2026-09-08)** — Godot Debug Menu add-on on F3 for players, physics
  catch-up cap. Recorded: `keybinds.json#hybrid.debug-menu`, `ui.json#hud.debug-menu`, `generators.json#design.frame-budget`, `c-frame-budget`.
- [x] **D18 Items, loot, inventory (2026-09-09)** — drop chances, rarity weights, level spread, ground-item lifetime,
  stack rule, starting inventory. Recorded: `generators.json#design.loot|stack-cap|starting-inventory`, `c-loot-config`,
  `c-stack-rule`, `c-slot-accepts`; `domain.md §3.4 inventory` props, relations `holds` / `equips`.
- [x] **D19 XP and level-up (2026-09-09)** — XP per kill (fraction of the creature's xp-to-next, level-gap multiplier),
  overflow carry, heal on level-up, skill points banked. Recorded: `generators.json#design.progression`, `c-xp-config`, `c-level-up`.
- [x] **D20 Skill tree (2026-09-09)** — spend/unlock rules, X screen, keys 1-4 placeholder strike, per-point multipliers (swim speed first).
  Recorded: `generators.json#design.abilities`, `keybinds.json#hybrid.skills-window`, `ui.json#screens.skills`, `abilities.json` rank-1 `needs` 0,
  `c-tree-shape`, `c-skill-spend`.
- [x] **D21 Class abilities (2026-09-10)** — a runtime (dash / channel / burst / buff / heal) with numbers, cost and cooldown for
  every class node and ultimate; MP gain and the M2 special attack; stun / knockdown / knockback / burning / slow numbers.
  Recorded: `generators.json#design.abilities|resources|special-attack|status-effects`, `c-ability-runtime`.
- [x] **D22 Settlements and spawn rule (2026-09-10)** — one village per land, placement / flattening / ring layout numbers, one NPC per
  service building, shop stock + prices in play, trainer respec fee, inn heal + respawn point, spawn on the (0,0) village square.
  Recorded: `generators.json#design.settlement`, `ui.json#screens.npc-service`, `c-settlement-config`.
- [x] **D23 Defence (2026-09-11)** — dodge roll numbers + per-passive rewards, block (shield / guardian / cyclone) with block-power,
  the stealth bar's sources, decay and bonuses, creature hits rolling stun / knockback on the player.
  Recorded: `generators.json#design.defence`, `design.abilities.<id>.stealth-per-s|stealth-full`, `c-defence-config`.
- [x] **D24 Weapon movesets and projectiles (2026-09-11)** — an M1 / M2 runtime per class weapon-type (melee variants, arrows with gravity,
  bolts, returning boomerangs, staff bursts at the cursor, wand beams, bracelet bolts / splash balls), the projectile ultimates, poison ticks.
  Recorded: `generators.json#design.movesets`, `design.abilities` runtime `projectile` + dash `throw`, `design.status-effects.poison`, `c-moveset-config`.
- [x] **D25 Game feel (2026-09-11)** — feedback bundles per combat event: hit-stop, camera trauma / shake, floating damage numbers,
  stun stars, buff icons, level-up toast pop, projectile trails / impact flashes, and sounds synthesised from alpha sound ids.
  Recorded: `generators.json#design.feel`, `audio.json#sfx-alpha-ids`, `c-feel-config`.
- [x] **D26 Creature ranged / mage roles (2026-09-11)** — a `combat-role` (melee, ranged, mage, any-class) parsed from
  `creatures.json` role text; ranged / mage chase to range, back off below keep-away, need line of sight, wind up and fire a
  shot through the target's normal dodge / block / i-frames, applying statuses on a landed hit (poison through dodge);
  any-class humanoids roll a weighted role per spawned group; species overrides (spitter, snout-beetle) per creature id.
  Recorded: `generators.json#design.creature-roles`, `design.feel.sfx.fireball`, `c-creature-roles`.

## B. Conflicting facts (pick a side)

- [x] **F1 Steam ability numbers** — recorded in `abilities.json`, `?` stripped:
  - [x] Heroic Shout: taunt 5 m + 50 % HP over 10 s
  - [x] Guardian Toughness: +25 % max HP
  - [x] Battle Fury trigger: 13 % per hit
  - [x] Shadow Shooter duration: 30 s
  - [x] Bubbles count: **6** (owner pick, guide value)
  - [x] Shuriken Toss cost: 25 stamina
  - [x] R-ultimate cooldowns: per-skill (20/30/40/60 s)
- [x] **F2 Rideable flags** — per-page (no). `pet-food.json` `rideable: false` on all 13.
- [x] **F4 Land difficulty — owner override, not the default.** Enemy level = band from lowest
  party level − X to highest + Y (solo: own level), X/Y in solo settings or `server.cfg`; each land
  rolls a danger tier (safe/normal/dangerous) at generation that fixes where in the band it sits.
  Recorded: `generators.json#design.enemy-level`, `landscapes.json#_shared`, `domain.md §3 land`.
- [x] **F6 Land geometry** — one land = one region cell; our own noise/water/heightmap.
  Recorded: `domain.md §3 land`.
- [x] **F8 Spirit Bell duration** — 30 s. `key-items.json#spirit-bell`.
- [x] **F9 Life Potion station** — anywhere. `consumables.json#life-potion`.
- [x] **F10 Alpha-id creatures "not in alpha"** — tagged `S`, alpha id reserved. `creatures.json`.
- [x] **F11 Warthog food** (banana mash) — obtainable. `pet-food.json`.

## C. Process gaps (do, no decision needed)

- [x] Godot 4.7.2 via `nix develop` (flake.nix); `godot --headless -s ontology/validate.gd` passes
- [x] `git init` the repo — done, first commit b9e0bfd.
- [x] Raw research corpus (740 wiki pages, cuwo clone) — not kept; `ontology/research/*.md` is
  what remains.

## D. Not decisions (info)

- F3 (`+` items / lore) is moot: region lock dropped.
- F5 split into D7/D8/D9 above, all decided.
- F7 Omega status (Vulkan vs UE5, silence since 2024) is roadmap-only.

## E. Ontology reconciliation (2026-09-13)

Derive straightforward corrections from `ontology/`. If it does not determine the answer
unambiguously, record the decision here for later instead of inventing a rule. The approved/open
subsections track decisions; the reconciliation checklist tracks application. Approval alone does
not mean a correction is applied; land it in `ontology/` before changing consumers.
Present each proposal to the owner as the finished player experience, not as a schema edit;
ask one question at a time. For every item, explain the player-visible result of approval AND
of not approving/leaving it unresolved. Distinguish current-build effects from future risks;
a declined documentation correction does not itself break the game or approve the opposite rule.
Approval of an ontology decision is not approval to implement additional gameplay.
The full walkthrough/resumption protocol is in `tasks/lessons.md`; the prompt
**"resume walking through items"** means follow it and this checkpoint, not implement a slice.
Never propose or implement regional gear power loss in pixlnd, even for Cube World cloning
fidelity: permanently excluded, not a deferral or alternate mode (owner, 2026-09-15).

**Resume checkpoint (2026-09-17):** items 1–2 are applied, validated and committed in `c675f85`.
Items 3–8 are approved for ontology and their semantic corrections are committed in `f1ec112`;
their walkthrough handoff is recorded in `d856897`. The owner resumed and approved item 9's
validation-contract direction for **ontology documentation only** on 2026-09-17. Its policy is
recorded in `domain.md §5`; validator, loader, generator and gameplay implementation remain
deferred and unauthorized. Exact required paths and unresolved provenance/boundary mappings
still need documentation before enforcement.
Inspect actual Git state on `fix/ontology-reconciliation`.
Item 3's live slot/validator/consumer changes remain deferred, and item 7's
spirit-cube drops remain unimplemented. No live flags, balance or unresolved gameplay choices changed.
Next unpresented item: **10 — Runtime contract violations**, starting with the open panel-time
policy before choosing a timer-freezing fix; combo-boundary policy is a separate question.
Follow `tasks/lessons.md`: present one gamer-facing recommendation with both outcomes, ask
one approval question, then wait. Do not jump to the gameplay handoff's aggro slice or the
deferred equipment/validator implementation. Preserve D1–D26 and all walkthrough approvals;
all remaining open questions stay open.

### Approved in the item-by-item walkthrough

- [x] **Cookie remains deferred (item 1, owner approved A).** Preserve its A/X reference row
  and roadmap entry; remove it from `generators.json#design.loot.consumable-pool` (also used by
  shops). This reconciles D18 content selection with D3, not a new cut-content exception.
- [x] **Relation cardinalities (item 2, owner approved).** `raises-stat` permits multiple stat
  targets; each artifact still raises exactly one traversal stat plus attack and max HP (D6,
  `c-artifact-stat`). `costs` permits zero or multiple resources with amounts scoped by ruleset
  (Steam Intercept uses stamina and MP). Correct `domain.md §4`; preserve existing effects,
  costs and hybrid balance. This approval does not settle family membership or artifact stacking.
- [x] **Equipment model (item 3, owner approved for ontology, 2026-09-15).** Gear has dedicated
  matching positions; the Q consumable is selected independently and never displaces gear.
  Lamps occupy the light slot, a glider or boat the special slot, and taming food the pet slot
  rather than the player's quick-use slot. Keep existing class/hand restrictions and all 13
  stored indices (12 usable positions plus reserved `unknown-0`); no extra slot or stat bonus.
  Record canonical item-type/subtype distinctions. Gameplay implementation is a separate step;
  wand handedness and traversal unlocks are not settled by this approval.
- [x] **World blocks versus combat blocking (item 4, owner approved, 2026-09-15).** Model the
  terrain voxel as `block` and the defensive action as `combat-block`. Reconcile ontology
  references only; preserve terrain behavior, controls, block-power costs, MP rewards, damage
  reduction and existing runtime config/event identifiers. This adds no gameplay mechanic.
- [x] **Boomerang recipe (item 5, owner approved for ontology, 2026-09-15).** A common boomerang
  costs 20 wood cubes at the workbench, following D6's two-handed size class. Preserve rarity
  gem requirements and combat behavior; wand handedness/cost remain separate. Without this
  correction, using the old recipe in a finished crafting system would charge only 10 wood
  cubes (half the intended amount); leaving it unresolved would not override D6.
- [x] **Creature source identities (item 6, owner approved for ontology, 2026-09-15).** Numeric
  source IDs include post-alpha additions; retain stable creature IDs, numeric IDs, version
  tags and existing food pairings (192: Radishling Sprout / Mineral Water; 293: Caterpillar /
  Mixed Salad). Preserve legacy `aid` / `alpha_entity_id` names and null/-1 for unrecorded IDs;
  version provenance is not inferred from a number alone. No taming or loader behavior change.
  Without clarification, existing rows still load, but a future alpha-only range check could
  wrongly exclude these creatures or their bait; that is a risk, not a reproduced gameplay bug.
- [x] **Mission-boss spirit-cube exception (item 7, owner approved for ontology, 2026-09-15).**
  Eligible non-mission bosses drop one spirit cube per kill, with a fixed type/level per boss.
  Mission bosses, including Saurians, do not drop spirit cubes; their normal mission rewards
  remain unchanged. The hybrid retains the recorded alpha exception. Without reconciliation,
  implementing the universal wording could give mission bosses extra weapon-upgrade drops;
  declining the correction would not approve that alternative. No drop runtime is implemented.
- [x] **Reference versus hybrid scope (item 8, owner approved for ontology, 2026-09-15).**
  Hybrid v1 retains alpha progression + approved Steam content; A/S comparisons are historical
  reference, X/cut and Omega-only content remain roadmap material, and current-slice approximations
  are not final rules. No new content inclusion/exclusion or unresolved merge is authorized.
  Non-approval would not change the already-decided game; it would leave ambiguous scope text.
  Owner reaffirmed: **never propose or implement regional gear power loss in pixlnd**, even
  for cloning fidelity. Permanently excluded, not deferred or an alternative mode.
  The requested stop before item 9 was honored; the owner resumed on 2026-09-17.
- [x] **Validation-contract direction (item 9, owner approved for ontology documentation only,
  2026-09-17).** Require data for active hybrid systems, reject missing whole tables/config blocks
  and malformed shapes, and check existing class/spec, skill-tree and upgrade-capacity rules
  without changing balance. Permit source-version inheritance only where explicitly documented,
  never guessed. Validate definitions/config at load time and generated artifacts separately;
  report failure for any accumulated loading/validation error. Recorded in `domain.md §5`.
  Exact path/inheritance/boundary mapping remains preparatory work below, not invented by this
  approval. Once implemented, these checks should catch data regressions before players encounter
  missing choices, broken progression or invalid upgrades. Leaving the contract open
  would not change today's gameplay or approve different rules; it would retain blind spots.
  Validator, loader, generator and gameplay changes require separate authorization.

### Open — decide before the named slice

- [ ] **Aggro / group aggro:** define threat amount, tie-breaking, decay/reset, taunt priority
  and duration, full-stealth interaction and group membership before the next aggro slice.
  Sources: `domain.md#ai-behavior`, `generators.json#design.status-effects` (current taunt approximation).
- [ ] **Combo attack boundary:** whole cast, channel tick or completed channel? How do
  zero-damage taunts count? Before class-strike bookkeeping changes; sources:
  `domain.md#combo-system`, `c-combo-reset`, `generators.json#design.movesets` (D24).
- [ ] **Panel time policy:** live combat or whole-world single-player pause while panels are
  open? Before fixing player-only timer freezing; sources: `ui.json#screens`, `domain.md#multiplayer-mode`.
- [ ] **Creature family membership:** one primary scaling family plus descriptive groups, or
  multiple families with a defined scaling rule? Skeleton Dog appears in dogs and skeletons
  but its singular family is skeletons. Before family-based scaling; sources:
  `domain.md#member-of-family` (relation row), `creature-families.json`, `creatures.json#skeleton-dog`.
- [ ] **Hybrid settlements / inn services:** are multiple settlements and inn cost 10 future
  targets, or stale flags? Is paid timed sleep distinct from D22's free heal/respawn service?
  Before changing settlement count or adding sleep; sources: `rulesets.json#ruleset-hybrid.flags`,
  `generators.json#design.settlement`, D22. Keep current D22 behavior until clarified.
- [ ] **Traversal prerequisites:** skill, global key item, or both for riding/gliding/sailing;
  how do climbing spikes interact with climbing points? Before traversal/pets; sources:
  `abilities.json` shared trees, `key-items.json`, `rulesets.json#ruleset-hybrid.flags`.
- [ ] **Books and formulas:** are hybrid book recipes permanent/global, and how do duplicate
  unlocks interact with formulas? Before crafting/save-data; sources: `domain.md#book-of-crafting`,
  `recipes.json#recipe-sources`, `rulesets.json#ruleset-hybrid.flags`.
- [ ] **Artifact accumulation:** diminishing returns counted globally or per traversal stat;
  percentages additive or compounded? Before artifacts; sources: `generators.json#design.artifact`,
  `key-items.json#artifact`. D6 constants and traversal + attack + HP bonuses remain settled.
- [ ] **Assassin ultimate:** is Camouflage's `also-ultimate` an alias of rank 3 or a separately
  unlocked fourth node? Before changing its tree; sources: `abilities.json#camouflage`, D10/D20.
- [ ] **Wand handedness:** mechanically two-handed despite a one-hand pose, or actually
  one-handed? Before wand equipment/crafting rules; sources: `weapon-types.json#wand`,
  `c-hands`, `generators.json#design.recipes`.
- [ ] **Hybrid persistence / authority:** character portability across worlds, ownership of
  discoveries/unlocks, and authoritative validation of state. Before save-data/networking;
  sources: `domain.md#player-character`, `#save-data`, `#multiplayer-mode`,
  `generators.json#network-alpha`. D5's dedicated server does not alone choose authority.
- [ ] **World bounds / resets:** does hybrid retain the finite 1024²-region bound despite
  “infinite” wording, and do cleared dungeon/quest mobs reset at midnight? Before boundary/clock
  logic; sources: `domain.md#gen-world` (generator row), `#game-clock`, `c-midnight-reset`.
- [ ] **Validation-contract mapping (policy approved in item 9):** document exact required
  table/config paths, permitted per-family provenance inheritance and remaining constraint
  boundaries from `domain.md §2/§5` before filling validator gaps. Ask the owner only where
  approved definitions do not determine a unique answer; current loader defaults are not
  authority. Artifact definition versus generated-instance checks are separated in §5.
  No new inheritance rule or unresolved gameplay choice was approved; implementation is deferred.
- [ ] **Remaining uncertain facts:** verify or choose explicit hybrid defaults for swamp-lands
  identity, Lion tameability (`null` currently means untameable), resistance meaning and the
  gear-HP roll formula before their respective slices. Sources: `landscapes.json#swamp-lands`,
  `creatures.json#lion`, `stats.json`. D13 hitboxes and D15 armor are already designed, not open.

### Reconciliation work — application checklist

These are the other findings from the 2026-09-13 audit, alongside the open questions above.
Keep references/indices and settled D decisions intact; defer any dependent work whose answer
is still open. Do not mistake a listed proposed correction for an approved new gameplay rule.

- [x] **Apply approved items 1–2 (2026-09-15):** removed Cookie from the active pool and corrected
  `raises-stat` / `costs` cardinalities as recorded above. Historical data, effects, costs and
  balance numbers preserved. Cookie loot/shop regressions failed before the pool correction and
  passed after it (`game/items/test_items.gd`, `game/world/test_settlement.gd`).
- [x] **Equipment model — ontology (item 3, 2026-09-15):** recorded the approved semantics in
  `domain.md §3.4/§4/§5`: 13 stored positions / 12 usable, independent Q selection, matching
  item types and subtype restrictions, pet food in the pet slot during taming. Relation
  cardinalities now count equipped items rather than storage positions and allow an item type
  multiple eligible slots (rings, weapons). Existing indices, stats and gameplay are unchanged.
- [ ] **Equipment implementation — deferred (item 3):** after explicit implementation approval,
  normalize live `equipment-slots.json#accepts` to item-type IDs (`light`, `special`, `weapon`),
  express subtype restrictions and pet-food placement, and align the validator/consumers with
  the approved model. Live slot JSON is deliberately unchanged: current `items.gd#slot_id`
  consumes it directly. Wand handedness and traversal prerequisites remain open above.
- [x] **Duplicate `block` identity (item 4, 2026-09-15):** kept the voxel `block` in `domain.md
  §3.1`, renamed only the defensive class to `combat-block` in §3.3, and corrected the heading
  reference in `generators.json#design.defence._doc`. Runtime config/event keys and all terrain,
  block-power, MP and damage-reduction behavior are unchanged.
- [x] **Recipe quantities (item 5, 2026-09-15):** split `recipes.json#gear-weapons.boomerang|wand`
  into a 20-wood-cube `boomerang` recipe and the unchanged provisional 10-cube `wand` recipe.
  Both remain at the workbench. All other recipe data, gem requirements and weapon behavior
  are unchanged. This reconciles the recipe with `generators.json#design.recipes` (D6).
- [x] **Creature source IDs (item 6, 2026-09-15):** clarified `entity.species`, the legacy
  `creature.alpha-entity-id`, `pet-food`, `tamed-by` and `c-food-id` in `domain.md`; aligned
  `Creature` / `PetFood` comments and the creature/food JSON `_doc` fields. Stable and numeric
  IDs, version tags, taming pairs, legacy property names and executable loader/validator logic
  are unchanged. F10's reserved-alpha-ID distinction and unrecorded IDs are preserved.
- [x] **Boss spirit-cube exception (item 7, 2026-09-15):** aligned `domain.md#spirit-cube`,
  `#loot-rule`, `gen-boss`, `generators.json#boss.alpha-spirit-drop` and `economy.json#loot.A-boss`
  with the approved hybrid mission-boss exception. Preserved the source notes on Saurians and
  alpha boss-kill missions, existing mission reward data, spirit effects and level restrictions.
  No executable drop logic, numeric balance or ruleset flags changed.
- [x] **Reference versus hybrid scope (item 8, 2026-09-15):** clarified `domain.md §0/§1/§7`,
  the reference-only `region-lock` entry, `rulesets.json` annotations, `generators.json` annotations
  and `ontology/README.md`. Recorded permanent exclusion of regional gear power loss, not a
  roadmap option. Historical data and all live flags/balance values preserved. Settlement/inn
  targets, traversal, artifacts and other unresolved merges remain open. Walkthrough protocol
  and the explicit stop/resume route are recorded in `tasks/lessons.md` and `docs/HANDOFF.md`.
- [x] **Validation contract — ontology (item 9, 2026-09-17):** recorded the approved direction
  in `domain.md §5`, clarified `c-versions-nonempty` and split `c-artifact-stat` between
  definition and generated-instance checks. The roadmap and handoff distinguish applied
  documentation from deferred enforcement.
- [ ] **Validator gaps — implementation deferred (item 9):** after separate authorization and
  the mapping above, add negative checks for missing races and whole moveset blocks, wrong
  root/row shapes, both directions of class/spec references, spec cardinality/start index,
  rootless shared skill columns and handedness-specific cube capacities. Enforce documented
  provenance, separate artifact-definition/generated-instance checks and failure on accumulated
  errors. Currently `Ontology.validate()` checks only whether its pass adds errors; the runner
  separately checks accumulated errors. The approved boolean contract is not implemented.
  `model.gd#Ontology` and `validate.gd` are unchanged; no new checks are implemented.
- [ ] **Runtime contract violations (walkthrough item 10; not yet presented or approved):** reproduce and fix inventory freezing dodge timers
  (`player.gd#_physics_process`), poison ticks rejected by dodge (`player.gd#take_damage`,
  `entity.gd#tick_statuses`), exhausted block protecting against same-interval hits
  (`player.gd#blocks_from`), and greatsword + shield accepted in either equip order
  (`inventory.gd#equip`, `c-hands`). Non-projectile class strikes also omit combo result handling
  (`abilities.gd`). Settle panel-time / combo-boundary questions above before choosing behavior.
- [ ] **Artifact/document cleanup:** replace the missing `instances/shops.json` reference with
  `economy.json#shops`; remove the duplicate `economy.json#prices.formula` key; reconcile stale
  “all settled” summaries and claims that dodge, stealth bar or poison are absent in
  `ontology/README.md`, `docs/ROADMAP/README.md`, `todo_implement.md`, `docs/HANDOFF.md`.
  Make `domain.md §7` enumerate actual remaining uncertainties rather than treating optional
  fields or already-designed hitboxes/armor as open facts. Keep research dumps unchanged.

**Items 1–2 verification (2026-09-15):** `timeout 90 nix develop -c godot --headless -s <script>`
passed for `ontology/validate.gd`, `game/items/test_items.gd` and
`game/world/test_settlement.gd`; all `ontology/instances/*.json` parse as objects with `jq`;
`git diff --check` passed. Before the pool correction, the added regressions failed only for
Cookie (142 drops in the seeded 4,000-kill test; present in shop stock). Relation rows were
reviewed against existing D6 / `c-artifact-stat` and Steam Intercept data; the headless validator
does not validate Markdown cardinalities. These checks do not close the other audit findings.

**Item 3 verification (2026-09-15):** `timeout 90 nix develop -c godot --headless -s
ontology/validate.gd` passed. `jq` confirmed 13 slot entries with indices 0..12, an empty
reserved `unknown-0`, and the separate Q field. Semantic review matched the approved equipment
model to existing item-type definitions; the validator does not check Markdown semantics.
`git diff --check` passed; `game/`, instance JSON and validator code are unchanged. No claim
that the deferred equipment behavior is implemented or tested at runtime.

**Item 4 verification (2026-09-15):** the headless ontology validator and `git diff --check`
passed. Heading inspection confirmed one `block` and one `combat-block`; ontology reference
review found and corrected the generator's §3.3 heading reference. A `jq` comparison against
`HEAD` confirmed the generator change is exclusively that `_doc` wording. Gameplay, validator
code, equipment data, weapon definitions and the still-pending recipe data are unchanged.

**Item 5 verification (2026-09-15):** a targeted `jq` check failed before the correction and
passed after: separate boomerang/wand rows, 20/10 wood cubes respectively, boomerang station
`workbench`, no shared row. A full JSON comparison against `HEAD` confirmed that only this
split and the boomerang quantity changed. The headless ontology validator and
`git diff --check` passed. Gameplay, validator code, weapon definitions, creature/food pairs
and live equipment data are unchanged. No finished crafting UI/runtime is claimed.

**Item 6 verification (2026-09-15):** the headless ontology validator and
`game/entities/test_creature_roles.gd` passed. `jq` checked the two named post-alpha IDs,
version tags and bidirectional food pairings; full JSON comparisons against `HEAD` confirmed
both creature and pet-food files differ only in `_doc`. Diff review confirmed `model.gd`
changes are comments only; `game/` and validator runner are unchanged. `git diff --check`
passed. Source namespace clarification was reviewed against research §2.5 and F10; no
claim that the future taming system is implemented.

**Item 7 verification (2026-09-15):** the headless ontology validator,
`game/items/test_items.gd` and `git diff --check` passed. Semantic review confirmed the
mission-boss exception across the domain's three descriptions and both JSON loot descriptions.
JSON comparisons confirmed all other economy data and generator values unchanged (apart from
the previously approved item 4 `_doc` correction). `game/`, the validator runner, mission
reward data and ruleset flags are unchanged. These checks do not test a spirit-cube drop
runtime; that remains unimplemented.

**Item 8 verification (2026-09-15):** the headless ontology validator,
`game/items/test_items.gd`, `game/world/test_settlement.gd` and `git diff --check` passed.
All instance JSON files parse as objects. Comparisons against the pre-item-8 working files
confirmed only `rulesets.json` annotations (`_doc`, hybrid `_rule`, Omega `_note`) and
`generators.json` root/design `_doc` changed; every other value, including prior approvals,
is unchanged. Hybrid remains default with region-lock, plus-items, worn-rarity and per-land
inventory disabled, and global key items enabled. `game/` and the validator runner are unchanged.
Semantic/simplification review checked the scope distinctions, permanent exclusion and explicit
walkthrough stop/resume route. This is not proof that the validator covers every semantic rule.

**Item 9 verification (2026-09-17):** `timeout 90 nix develop -c godot --headless -s
ontology/validate.gd` and `git diff --check` passed. Scope/checkpoint checks confirmed
documentation-only changes, documentation approved/applied versus enforcement deferred,
and matching next-item pointers in the roadmap/handoff. Semantic and simplification review
preserved the approved policy and left unresolved mappings open. `game/`, instance
JSON, `model.gd` and `validate.gd` are unchanged. The existing validator does not validate this
Markdown or prove the proposed negative checks work; no enforcement fix is claimed.

**Audit verification baseline (not proof of consistency):** `ontology/validate.gd`,
`game/items/test_items.gd`, `game/combat/test_defence.gd` and
`game/entities/test_creature_roles.gd` passed at `e4f87f5`. Memory-only negative probes still
accepted missing races/movesets, 32-cube one-handed swords, missing pet-food versions, duplicate
spec indices, reversed starting-spec order, rootless shared columns and empty artifact stat kinds.
Runtime probes reproduced the four violations above. Add regressions for these cases; do not
rely on the old green tests or temporary probe files surviving the session.

## Initial scaffold — DONE 2026-09-08 (`project.godot`, `game/`)
The router-derived scaffold loads `instances/` through `ontology/model.gd`. For subsequent
slices, resolve relevant §E questions, sync `ontology/`, then route implementation.
