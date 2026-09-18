# TODO — decisions to take before the affected implementation slice

Priority zero. Resume here with any agent. Context: `ontology/domain.md` (§1 scope, §7 open
points), `ontology/instances/*.json`, `docs/ROADMAP/README.md`. Already decided on 2026-09-07:
D1 hybrid ruleset, D2 Godot 4.7 + GDScript, D3/D4 cut + Omega content → roadmap, region lock /
`+` items / worn degradation dropped.

**Status 2026-09-18:** D1–D26 and the original fact conflicts below remain decided. The ontology
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

**Resume checkpoint (2026-09-18; commit references updated after rebase):** items 1–2 are applied,
validated and committed in `0a562fc`. Items 3–8 are approved for ontology and their semantic
corrections are committed in `e10836a`; their walkthrough handoff is recorded in `c005f55`. The owner resumed and approved item 9's
validation-contract direction for **ontology documentation only** on 2026-09-17. Its policy is
recorded in `domain.md §5`; validator, loader, generator and gameplay implementation remain
deferred and unauthorized. Exact required paths and unresolved provenance/boundary mappings
still need documentation before enforcement.
Inspect actual Git state on `fix/ontology-reconciliation`.
Item 3's live slot/validator/consumer changes remain deferred, and item 7's
spirit-cube drops remain unimplemented. No live flags, balance or unresolved gameplay choices changed.
Item **10 — Runtime contract violations** has its listed repairs applied: on 2026-09-17 the owner approved
live time for inventory, skill-tree and shop panels in solo and multiplayer, whole-channel combo
miss/reset for damaging channels (including early ends), and combo-neutral zero-damage taunts
(no increase, reset or inactivity-timer refresh). The rules are recorded in `domain.md §3.7/§3.3/§5`
for ontology documentation only. The owner separately authorized **only the poison-tick/dodge
runtime repair and its regression test** on 2026-09-17. Its existing rule and narrow scope are
recorded in `domain.md#status-effect`; the repair is applied with a red-to-green regression and
passing headless suite (evidence below). The owner subsequently authorized **only the
block-exhaustion/same-interval-hit repair and its regression** on 2026-09-17: the final valid
block retains damage/status protection and its MP reward; later hits at zero power receive none
of those block benefits. The repair is applied with red-to-green and full headless-suite evidence
below. The owner then separately authorized **only the two-handed-weapon/shield equip-conflict
repair and its regressions** on 2026-09-17: reject the attempted equip in either order without
changing the bag or worn gear. That repair is applied and tested; existing handedness data,
including the provisional wand classification, is unchanged. All other runtime fixes remain
unauthorized; the broader item-3 equipment-model implementation remains deferred.
The owner resumed on 2026-09-17 and explicitly authorized **only the panel-time runtime repair
and its regression tests**, preserving current gameplay input restrictions, balance and other
menus. Authorization is recorded in `domain.md#hud-element`; the repair is applied with
red-to-green regression, full headless-suite and windowed-check evidence below. Independent
correctness and ponytail reviews found no issues. The owner then separately authorized **only
the class-ability combo runtime repair and its regression tests** on 2026-09-17. Authorization
is recorded in `domain.md#combo-system`; the repair is applied with red-to-green, full-suite
and windowed HUD evidence below; independent correctness and ponytail reviews found no issues.
The completed panel-time changes, balance, inactivity expiry, caps and unrelated runtime
behavior are preserved.
The owner then requested committing the staged repairs before continuing: `44ab0a1` contains
the panel-time and class-combo repairs and their records. The owner approved **artifact/document
cleanup**, now applied, checked and reviewed: stale references/statuses, duplicate
price-description key and an index of remaining questions, with no gameplay or parsed-data-value
changes. At that checkpoint, cleanup approval did not authorize automatic commit or push.
The cleanup was subsequently committed before the authorized semantic rebase onto `20e35d8`;
that checkpoint authorized no push or additional implementation.
**Aggro / group aggro:** damage gain is now maximum-HP-percentage-based, not raw-HP-based
(owner correction, 2026-09-18; exact rule below). Targeting ties are unchanged. On 2026-09-18
the owner rejected no-decay-during-combat and directed continuous fixed-rate decay per mob/player,
with hits adding threat concurrently and target switches preserving remaining threat. These
ontology-only rules are applied in `domain.md#ai-behavior`; the requested relationship model
is explicit in §4/§5 (`threat`, `aggro-points`, `current-target`). The owner subsequently approved
**1 aggro point per second** and **zero-threat behavior** (2026-09-18), documentation only;
exact rules are below. Next question: **reset conditions — player death**. Other resets (including
engagement order), taunts, full-stealth interaction and group behavior remain open. Resume one
ontology decision at a time, not the implementation slice; deferred implementation is unauthorized.
**Publication authorization and stop point (2026-09-18):** the owner requested `commit+push`
of the current documentation on `fix/ontology-reconciliation`, then handoff. This authorizes
publication, not further decisions or gameplay. The next agent must start at `docs/HANDOFF.md`.
**Pending, presented but NOT approved:** death immediately clears every mob's aggro toward the
dead player, preserves surviving teammates' scores, and leaves the respawned player to rebuild
aggro from zero under normal hostile detection. Enemy healing, whole-fight resets and engagement
order are separate. Re-present this proposal for documentation-only approval; do not implement it.
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
- [x] **Panel-time policy (item 10, owner approved for ontology documentation only, 2026-09-17).**
  Time keeps running while inventory, skill-tree and shop panels are open, in both solo and
  multiplayer. Enemies, projectiles, damage-over-time effects, cooldowns, buffs and dodge timers
  follow their normal rules; browsing grants no immunity or extended protection. Browsing during
  combat remains risky. Recorded in `domain.md#hud-element`. Leaving this undecided would
  have retained the current partial player freeze, not approved a whole-world pause. This approval
  does not settle other panels/menus, input availability or combo boundaries; gameplay fixes still
  require separate authorization.
- [x] **Damaging-channel miss/reset boundary (item 10, owner approved for ontology documentation
  only, 2026-09-17).** Judge the whole channel, not individual ticks: empty ticks do not reset the
  combo; a channel that lands no hits resets it when it ends, including an early end. Normal
  inactivity expiry, successful-hit combo gains and per-weapon caps remain unchanged. Thus a
  Cyclone that hits and then spins through empty space is not treated as a miss. Leaving this
  undecided would keep the boundary open, not select per-tick resets. Recorded in
  `domain.md#combo-system` / `c-combo-reset`; runtime fixes require separate authorization.
- [x] **Zero-damage taunts and combos (item 10, owner approved for ontology documentation only,
  2026-09-17).** Zero-damage taunts neither increase nor reset combo and do not refresh its
  inactivity timer, whether or not any enemy is affected. Normal inactivity expiry and existing
  taunt/healing effects remain unchanged. Players can use a defensive taunt without a combo
  penalty, but cannot build or sustain a combo by taunting alone. Leaving this undecided would
  not approve rewarding or penalizing taunts. Recorded in `domain.md#combo-system` / `c-combo-reset`;
  threat amounts and targeting rules remain separate, and runtime changes require authorization.
- [x] **Poison ticks during dodge — runtime authorization (item 10, 2026-09-17).** Reproduce and
  fix poison ticks discarded during dodge, with a regression test. This enforces the existing
  D26 rule, not a new poison mechanic. Preserve poison damage/duration/cadence, ordinary dodge
  protection and existing burning behavior. That approval authorized no other deferred runtime
  work; the subsequent block authorization is separate. Application/verification are tracked below.
- [x] **Exhausted block and same-interval hits — runtime authorization (item 10, 2026-09-17).**
  Reproduce and repair blocking after power reaches zero, with a regression. Preserve the final
  valid hit's damage reduction, MP reward and attached-status protection; subsequent hits at zero
  power get no block benefits even before the next defence update. Positive power below one hit's
  cost still permits the existing full block. Preserve all balance, regeneration, Guardian,
  Cyclone and other defences. Deferral would leave the timing loophole, not approve free blocking.
  This enforces D23; that block approval authorized no other deferred runtime work.
- [x] **Two-handed weapon plus shield — runtime authorization (item 10, 2026-09-17).** Reject
  an equip attempt that would create this conflict in either equip order, leaving worn gear and
  the attempted bag item unchanged. Do not auto-unequip, delete or duplicate items. Valid 1H +
  shield, 2H alone and non-conflicting replacements remain available. Use current handedness
  data without settling the provisional wand classification. This authorizes only the conflict
  repair and regressions, not broader slot normalization, class restrictions, dual-wield routing
  or Guardian/Cyclone changes. Deferral would retain the loophole, not approve the invalid loadout.

- [x] **Panel-time — runtime authorization (item 10, 2026-09-17).** Repair the player-only
  timer freeze while inventory, skill-tree and shop panels are open, with regressions. Existing
  DOT ticks, cooldowns, buff and dodge expiry must continue; preserve gameplay input restrictions,
  balance and other menus. Deferral would retain the partial freeze, not authorize a world pause.
  This authorizes no other runtime fixes, commits or pushes. Application is tracked below.

- [x] **Class-ability combos — runtime authorization (item 10, 2026-09-17).** Repair missing
  non-projectile class-strike combo handling and add regressions, using the approved damaging-hit,
  whole-channel miss/reset and combo-neutral zero-damage-taunt rules. Preserve existing gain,
  inactivity and cap behavior, damage, costs, cooldowns and taunt/healing effects. Projectile
  and weapon attacks remain unchanged. This authorizes no other deferred work, commit or push.
  Application and verification are tracked below.

- [x] **Artifact/document cleanup — authorized (2026-09-17).** Correct stale references and
  current-status summaries, remove the duplicate price-description key with its effective value
  preserved, and distinguish implemented, approved/deferred and unresolved work. No gameplay,
  balance, loader/validator behavior or unresolved decision changes. Deferral would leave
  misleading documentation, not change the game. The preceding staged repairs were committed
  as requested; this approval does not automatically authorize a further commit or push.

- [x] **Aggro damage contribution (owner corrected 2026-09-18, ontology documentation only).**
  Gain 1 aggro point per 1% of the mob's maximum HP actually removed, including fractional
  points; reduction/absorption and zero-HP-loss handling are unchanged. This supersedes the
  earlier raw-HP conversion so equivalent percentage damage has equal threat-decay timing
  across progression. Recorded in `domain.md#ai-behavior`; the decay rate was approved separately
  below. Keeping raw-HP gain would make equivalent hits linger longer against higher-HP
  mobs at a fixed decay rate. Current last-attacker targeting is unchanged; no implementation,
  commit or push is authorized.

- [x] **Aggro current-target ties (owner approved 2026-09-18, ontology documentation only).**
  In ordinary threat-based targeting, keep the current target when tied for highest threat;
  another attacker must exceed it to displace it through threat alone. This avoids arbitrary
  switching on equal scores. Recorded in `domain.md#ai-behavior`; this approval does not settle
  other targeting ties or special rules. Deferral would have left this tie unresolved, not approved
  another rule. Current gameplay is unchanged; no implementation, commit or push is authorized.

- [x] **Aggro other-target ties (owner approved 2026-09-18, ontology documentation only).**
  When the current target is not among the highest-threat attackers, select the tied leader
  who engaged that enemy first. This gives a predictable fallback, not latest-hit or random
  selection; higher threat and current-target retention take precedence. Recorded in
  `domain.md#ai-behavior`. Deferral would have left this selection unresolved, not approved a
  different rule. Fight boundaries/reset and special rules are not settled by this approval;
  gameplay is unchanged and no implementation, commit or push is authorized.

- [x] **Aggro continuous decay and retained threat (owner direction/correction, 2026-09-18;
  ontology documentation only).** Each mob/player threat score decays at a constant points-per-second
  rate in and out of combat, while hits continue adding threat. Switching targets does not erase
  other scores: a player with positive remaining threat can become the target again if the
  higher-threat teammate dies, subject to normal targeting priority. This replaces the proposed
  no-decay rule; reduced priority is not being "forgiven". The initial 1-point-per-second example
  and zero-threat behavior were subsequently approved below; resets remain unresolved.
  Recorded in `domain.md#ai-behavior`. Deferral would not select no-decay or clearing on target
  switches. Gameplay is unchanged; no runtime, commit or push is authorized.

- [x] **Aggro decay rate (owner approved 2026-09-18, ontology documentation only).** Subtract
  1 aggro point per elapsed second from each mob/player score, continuously in and out of
  combat. With no further gains or resets, 10 points reach zero in 10 seconds at any progression
  level. Existing concurrent percentage-damage gains and targeting rules are unchanged.
  Deferral would have left the rate open, not selected no decay. Zero-threat behavior was
  subsequently approved below; resets and other open aggro decisions remain unresolved.
  No runtime, commit or push is authorized.

- [x] **Zero-threat behavior (owner approved after clarification, 2026-09-18; ontology only).**
  Aggro floors at zero. No separate memory of past damage sustains pursuit after those points
  expire: a mob stops pursuing that zero-threat player if it no longer detects them. A hostile
  mob that still detects them can keep attacking; zero is not immunity. Other players' scores
  are preserved. Deferral would have left this pursuit boundary open, not approved endless
  pursuit or safety beside a hostile mob. Reset conditions (including engagement order), taunts
  and full-stealth interactions remain separate; no runtime, commit or push is authorized.

- [x] **Aggro relationship model (owner requested 2026-09-18, ontology only).** Formalize
  `threat` as a directed mob/player entity relation carrying a numeric `aggro-points` amount;
  `current-target` is a separate, optional single-player relation per mob. Scores belong to
  individual entity pairs, not species or players globally. Recorded in `domain.md §4/§5`;
  existing gains, decay policy and targeting priorities stand. This clarification adds no
  balance choice, runtime implementation, commit or push authorization.

### Open — decide before the named slice

- [ ] **Aggro / group aggro:** damage conversion, targeting ties, continuous decay at
  1 aggro point/s and zero-threat behavior are approved above; define reset conditions, taunt
  priority/duration, full-stealth interaction and group membership before the next aggro slice.
  Sources: `domain.md#ai-behavior`, `generators.json#design.status-effects` (current taunt approximation).
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
- [x] **Panel-time policy — ontology (item 10, 2026-09-17):** documented live time for inventory,
  skill-tree and shop panels in solo and multiplayer in `domain.md §3.7`. Gameplay and live
  instance data are unchanged; runtime fixes were not authorized.
- [x] **Damaging-channel miss/reset boundary — ontology (item 10, 2026-09-17):** documented the
  whole-channel rule in `domain.md#combo-system` and `c-combo-reset`, including early ends and
  unchanged inactivity expiry / combo gains / caps. Runtime fixes stay deferred.
- [x] **Zero-damage taunts — ontology (item 10, 2026-09-17):** documented combo neutrality in
  `domain.md#combo-system` and `c-combo-reset`, including no inactivity-timer refresh and no-target
  casts. Taunt/healing effects and threat/targeting decisions are unchanged; runtime fixes stay deferred.
- [x] **Poison ticks during dodge — runtime repair (item 10, 2026-09-17):** retained the source
  status ID in the shared tick slot and passed it through `take_damage`; only poison ticks bypass
  dodge i-frames. Extended `test_creature_roles.gd` with tick damage/cadence/feedback and unchanged
  burning/direct-hit dodge checks. Poison balance, shared-slot replacement and all other runtime
  corrections are unchanged.
- [x] **Block exhaustion — runtime repair (item 10, 2026-09-17):** `blocks_from` now checks
  remaining power per hit. `take_damage` returns that hit's block result so melee, projectile and
  player-strike callers preserve attached-status protection even when the valid block empties
  the bar. No persistent hit cache or new balance/config is added. `test_defence.gd` checks
  consecutive melee/projectile hits without a defence update, with 25 or 1 power remaining:
  final valid block protected, next hit normal, no extra MP, and correct attached statuses.
- [x] **Hand conflict — runtime repair (item 10, 2026-09-17):** `Inventory.equip` checks the
  prospective hand pair before mutating the bag/equipment or emitting `changed`, rejecting a
  loaded two-handed main weapon plus occupied off-hand (currently shields). The regression
  checks greatsword and bow in both equip orders, unchanged bag order/worn gear/coins, no
  change signal and no item loss/duplication; valid swaps work after removing the conflict.
  No slot data, handedness classifications, class checks or other equipment-model work changed.
- [x] **Panel-time — runtime repair (item 10, 2026-09-17):** removed the shared panel early
  return in `player.gd`; existing simulation continues while movement, jump/swim-up, dodge,
  held block, combat and interaction input remain gated. Existing active effects and forced
  movement continue, with no new actions permitted. A lethal DOT stops the frame. Real-panel
  regressions cover inventory, skills and shop, timer expiry/cadence and unchanged input
  restrictions. No balance, instance data, other menus or class-ability combo handling changed.
- [x] **Class-ability combo runtime repair (item 10, 2026-09-17):** damaging class strikes
  reuse `_landed(false)` for combo gain/timer/cap without M1 rewards. Non-channel misses reset;
  channels accumulate hits and settle a miss only on normal or early end (stamina exhaustion
  or runtime reset). Zero-damage taunts/heals stay neutral. `test_class_combos.gd` covers the
  hit/miss/expiry/end cases, existing costs/damage and neutral support/movement skills. The
  old War Frenzy damage test now explicitly starts from zero combo, isolating its buff assertion
  from newly counted earlier class hits. No instance data or projectile/player runtime changed.
- [x] **Artifact/document cleanup (2026-09-17):** corrected the shop reference to
  `economy.json#shops` and the research path; removed the duplicate `prices.formula` description
  without changing its effective value. Reconciled current/open/historical summaries and stale
  dodge, stealth, poison, taunt and visual-check claims across the ontology README, roadmap,
  implementation backlog and handoff. `domain.md §7` now indexes the existing open hybrid
  questions separately from research uncertainties and optional fields; D13 hitboxes, D14
  current chase numbers and D15 armor stay decided. Research dumps, runtime and validator/loader
  code remain untouched. Parsed-data equivalence and targeted runtime checks pass; correctness
  review found no issues and both ponytail prose-reduction suggestions were applied.

- [x] **Aggro damage contribution — ontology (2026-09-18, subsequently corrected):** replaced
  raw-HP gain in `domain.md#ai-behavior` with maximum-HP-percentage gain, preserving fractional
  points. Updated the handoff and correction lesson; that checkpoint was the numeric decay
  rate, since approved below. Runtime, instance data and all other aggro decisions are unchanged.
- [x] **Aggro current-target ties — ontology (2026-09-18):** recorded the retention rule in
  `domain.md#ai-behavior` and narrowed the open list/checkpoint to other target-selection ties.
  Damage conversion, runtime, instance data and other unresolved decisions are unchanged.
- [x] **Aggro other-target ties — ontology (2026-09-18):** recorded the earliest-engagement
  fallback in `domain.md#ai-behavior`, preserved prior targeting priorities and advanced the
  checkpoint to passive threat decay. Runtime, instance data and other open decisions unchanged.
- [x] **Aggro decay policy — ontology (2026-09-18):** recorded constant per-mob/player decay,
  concurrent damage gains and retained threat across target changes; advanced the checkpoint
  to the numeric rate. Recorded the correction in `tasks/lessons.md`. Instance data, runtime
  (including D16 simulation), validator/loader and unresolved boundary rules remain unchanged.
- [x] **Aggro relationship model — ontology (2026-09-18):** added the two relation definitions,
  pair-scoped numeric amount/unit, runtime-layer constraints and illustrative facts; CQ12 now
  references them. The numeric rate was still open at that checkpoint; no executable or live data changes.
- [x] **Aggro decay rate — ontology (2026-09-18):** recorded continuous decay at 1 aggro point/s
  in `domain.md#ai-behavior`, removed the rate from open-question indices and advanced the
  handoff to zero-threat behavior. Runtime, live data and other aggro decisions are unchanged.
- [x] **Zero-threat behavior — ontology (2026-09-18):** recorded the zero floor and normal
  hostile-detection boundary in `domain.md#ai-behavior` and the relation constraints. Updated
  the open-question indices and handoff to reset conditions, starting with player death.
  Runtime, live data, existing targeting priorities and unresolved reset rules are unchanged.

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

**Item 10 policy verification (2026-09-17, before the runtime repair):** the headless ontology validator, `git diff --check`
and documentation-only scope checks passed. Semantic, `/simplify` and `ponytail-review` passes
preserved the panel-time and whole-channel rules, including early ends, normal inactivity expiry
and existing damaging-hit gains / caps. Zero-damage taunts are now combo-neutral, with no timer
refresh even when no enemy is affected; threat/targeting decisions remain separate. Next-topic
pointers matched. At that documentation-only stage, only `domain.md`, this roadmap and
`docs/HANDOFF.md` changed; gameplay, instance JSON and validator code were unchanged. The
validator does not check these Markdown policies or prove runtime compliance.

**Item 10 poison runtime verification (2026-09-17):** the new regression first failed with
0 HP lost instead of 10 during dodge, no DOT number and a second discarded poison tick. It
passed after the identity-preserving fix. All 13 `game/*/test_*.gd` scripts, `ontology/validate.gd`
and `godot --headless --quit` passed under `nix develop`, each bounded by `timeout 90`.
The regression also checks tick cadence, one DOT number without a hurt bundle, ordinary-hit
immunity after a poison tick, and burning replacing poison without inheriting its dodge exemption.
Live ontology instance data and balance were unchanged. At the poison-repair checkpoint,
panel-time, combo, block-exhaustion and hand-slot runtime fixes remained deferred; the later
block authorization/application is recorded separately above. `/simplify` retained the existing shared-slot runtime;
independent correctness and `ponytail-review` passes found no issues in the runtime/test diff.
The reviewer inspected the red/green/suite logs rather than rerunning tests.

**Item 10 block-exhaustion verification (2026-09-17):** `test_defence.gd` first failed 14
assertions: the second melee/projectile hit lost only 20 HP rather than 100, awarded a second
8 MP, and incorrectly suppressed statuses. It passed after the per-hit check/result propagation.
The regression preserves the exhausting hit's protection, tests positive power below one hit's
cost, and verifies stun/knockback plus a projectile's additional slow status. All 13 game tests,
`ontology/validate.gd` and headless boot passed under `timeout 90 nix develop -c godot …`.
Logs: `/tmp/pixlnd-block-exhaustion/{red,green,suite}.log` (session-local evidence). Live instance
JSON, balance and validator logic are unchanged. `/simplify` retained the per-hit return value
rather than a persistent hit cache; independent correctness and `ponytail-review` passes found
no issues. Reviewers read the source and red/green/suite logs, not rerun tests. The new projectile
regression invokes the impact callback; player-origin and Cyclone-specific exhaustion were
source-traced, not covered by dedicated new regressions. At that checkpoint, panel-time, combo
and hand-slot fixes remained deferred; the later hand-conflict approval/application is recorded
separately. No commit or push was authorized by the block repair approval.

**Item 10 equipment-conflict verification (2026-09-17):** `test_items.gd` first failed 12
assertions: greatsword/shield and bow/shield were accepted in both equip orders, changed bag/worn
state and emitted `changed`. The test passed after the pre-mutation hand-pair check. It also
checks no loss/duplication or coin changes and successful valid replacements after resolving
the conflict. All 13 game tests, `ontology/validate.gd` and headless boot passed under
`timeout 90 nix develop -c godot …`. Logs: `/tmp/pixlnd-equipment-conflict/{red,green,suite}.log`
(session-local evidence). SHA-256 checks confirmed the earlier uncommitted block runtime/test
files are untouched. Live instance JSON, balance, loader and validator remain unchanged.
`/simplify` retained the prospective-pair guard; independent correctness and `ponytail-review`
passes found no issues. Reviewers inspected source and red/green/suite logs without rerunning
tests. Other weapon classifications, shield-for-shield and non-hand swaps were source-traced,
not individually regression-tested. Panel-time, combo and the broader equipment-model
implementation are still deferred; no commit or push is authorized by this repair approval.

**Item 10 panel-time verification (2026-09-17):** `test_panel_time.gd` first failed 40
assertions, reproducing frozen poison, cooldowns, buffs and dodge expiry in all three real
panels (some failures were downstream of the freeze). It passes after the input/simulation
separation. Its swimming fixture was moved off the floor so collision does not zero sink
velocity. The regression checks poison cadence, ordinary-hit immunity before and vulnerability
after dodge expiry, single-step cooldown progression, normal combo inactivity, gameplay-input
suppression, movement after closing and lethal DOT. All 14 game tests, ontology validation and
headless boot passed under `timeout 90 nix develop -c godot …`. The same regression passed
windowed; a temporary copy captured each native panel for inspection (no browser UI). The
fixture's narrow window clips the wider panels; no UI layout fix is claimed or included.
Logs/captures: `/tmp/pixlnd-panel-time/{red,green,suite,visual}.log` and three panel PNGs
(session-local evidence). `/simplify` retained the existing single simulation flow rather than
adding separate timer machinery. Independent correctness and ponytail reviews found no issues;
reports are `correctness-review.md` and `ponytail-review.md` in the same log directory. Reviewers
inspected source and logs, not rerun tests. Active dash/channel/cast/heal continuation, knockback,
resource regeneration, ultimate input, the abilities-null branch and stored special charges
were source-traced, not individually regression-tested while browsing. The fixture manually
steps player physics, batches gameplay input and opens shops through `_open`, not vendor
interaction; no event-ordering or multiplayer/network claim is made. Live instance JSON,
balance and `abilities.gd` are unchanged. Combo repair, other deferred work, commit and push
remain unauthorized.

**Item 10 class-ability combo verification (2026-09-17):** `test_class_combos.gd` first failed
17 assertions for missing burst/dash hit/miss handling, channel completion and gains/caps.
It passes after the shared strike-result bookkeeping and channel end settlement. Regressions
cover multi-target bursts counting once, dash impact, empty/late/multiple channel hits, normal
duration and early stamina/reset endings, inactivity after a successful channel hit, sword/staff
caps, no M1 MP/finisher reward, unchanged strike damage/costs/cooldowns, Heroic Shout neutrality
with/without targets and unchanged taunt/healing effects, non-attacking buffs/movement/heals,
and a projectile's side heal versus whole-volley miss. The first full suite exposed the existing
War Frenzy fixture's zero-combo assumption; explicitly resetting that fixture's combo preserves
its intended buff-only assertion. All 15 game tests, ontology validation and headless boot then
passed under `timeout 90 nix develop -c godot …`. A temporary windowed copy binds the real HUD,
asserts `combo 5` on the burst hit and an empty combo label on its miss; both PNGs were inspected.
Logs/captures: `/tmp/pixlnd-class-combo/` (`red.log`, `green.log`, initial `suite.log`,
`abilities-green.log`, `suite-green.log`, `visual.log`, `combo-hit.png`, `combo-miss.png`).
The windowed run reported an ignored Nix evaluation-cache busy warning during concurrent Nix
startup; Godot and all assertions completed successfully. No browser or multiplayer test is
claimed. SHA-256 checks confirm the completed panel-time player/test files are unchanged;
live instance JSON, validator and projectile runtime are unchanged. `/simplify` retained one
shared strike path and one channel-end helper used by normal completion and reset. Independent
correctness and ponytail reviews found no issues (`correctness-review.md`, `ponytail-review.md`
in the same directory); reviewers inspected source/logs and HUD captures, not rerun tests.
The fixture manually settles dash impacts and steps ability timers: wall-triggered completion,
death calling reset, multi-target channel counting and successful class-projectile
non-double-counting were source-traced rather than individually asserted by the new regression.
No other deferred work, commit or push is authorized.

**Artifact/document cleanup verification (2026-09-17):** the staged repairs were first committed
as `44ab0a1` (rebased reference) after all 15 game tests, ontology validation and headless boot passed again. Cleanup
changes only six Markdown files and the removal of one duplicate economy description key.
Sorted `jq` output before/after is identical; `prices.formula` occurs once, all instance files
parse as objects, and runtime, validator/loader and research files have no diff. The ontology
validator, item and settlement tests, and headless boot passed again under `timeout 90 nix develop
-c godot …`; `git diff --check` passed. A source review reconciled the specific stale claims;
this does not prove every ontology semantic rule is enforced. The existing open-question list
is unchanged, with an index added to `domain.md §7`; no choice was silently resolved. No new
browser/windowed check is needed for this behavior-preserving documentation change. Evidence:
`/tmp/pixlnd-doc-cleanup/{precommit-suite,checks}.log` and sorted economy snapshots. `/simplify`
kept the open-question index concise and preserved historical D/F records rather than rewriting
them as current implementation. Independent correctness review found no issues; ponytail review
recommended removing duplicated cleanup authorization from §7 and repeated handoff scope/status.
Both suggestions were applied; approval remains in §E and verification links replace repeated
prose. Reviewers inspected source and supplied logs/captures, not rerun tests. Reports are
`correctness-review.md` / `ponytail-review.md` in the same evidence directory; post-adjustment
checks are recorded in `final-checks.log`.
At that verification checkpoint the cleanup diff remained uncommitted; it was subsequently
committed before the authorized rebase. No push or further gameplay implementation is authorized.

**Aggro ontology verification (2026-09-18):** the headless ontology validator
(`timeout 90 nix develop -c godot --headless -s ontology/validate.gd`), `git diff --check` and
scope checks passed after each approval/direction. Only `domain.md`, this roadmap,
`docs/HANDOFF.md` and `tasks/lessons.md` changed; runtime, live instance data and validator/loader
code are unchanged. Structural checks confirm unique relation/constraint IDs, entity-instance
endpoints, the `n→n` / `1→0..1` cardinalities and runtime-layer constraint labels. Semantic,
`/simplify` and ponytail review preserved the approved rules and separate pair-scoped amount /
target selection, while leaving the example decay rate and boundary decisions open. Redundant
explanatory prose was removed; examples remain illustrative, not static data or balance defaults.
The validator does not check these Markdown rules or prove runtime compliance; aggro
implementation remains unauthorized.

**Publication readiness (2026-09-18):** all 15 `game/*/test_*.gd` scripts, ontology validation
and headless boot passed again under `nix develop`, each Godot run bounded by `timeout 90`.
Scope/structural checks passed. Fresh read-only correctness and ponytail reviews found no issues;
they reviewed the patch and sources, not rerun tests. Ready to publish this documentation and
resume the walkthrough at the numeric decay rate, not to implement aggro. Evidence is session-local
in `/tmp/pixlnd-aggro-handoff.yS0KLL/` (`suite.log`, `correctness-review.md`, `ponytail-review.md`).
No visual test was needed for this documentation-only change.

**HP-normalized aggro correction verification (2026-09-18):** percentage-gain arithmetic
checks passed for 20/200 and 2000/20000 HP (10 points each), fractional gains and zero damage.
Stale-rule/scope checks, `git diff --check` and the headless ontology validator passed. Only
`domain.md`, this roadmap, the handoff and lessons changed; runtime/live data remain unchanged.
`/simplify` removed duplicate checkpoint rationale; ponytail review found no further cuts.
The validator does not check this Markdown formula; no runtime aggro test is claimed.

**Aggro decay-rate verification (2026-09-18):** arithmetic checks cover equal-percentage
hits at two HP scales, fractional elapsed time and concurrent gains; rate/checkpoint and
scope checks, `git diff --check` and the headless ontology validator passed. `/simplify` and
ponytail review retained the documentation-only scope; no runtime compliance is claimed.

**Zero-threat verification (2026-09-18):** documentation checks confirm the zero floor,
normal hostile-detection boundary, preserved gain/rate and next checkpoint. Scope checks,
`git diff --check` and headless ontology validation passed. `/simplify` shortened the checkpoint;
ponytail review found no further cuts. No runtime or live-data changes; Markdown checks do not
prove gameplay compliance.

**Normalized-aggro publication readiness (2026-09-18):** all 15 game tests, ontology validation
and headless boot passed, each Godot run bounded by `timeout 90`. Fresh read-only correctness
and ponytail review found no issues; the reviewer inspected documentation, not runtime tests.
The four-file Markdown scope preserves all runtime/live data. The player-death proposal remains
presented but unapproved, and the next agent must start at `docs/HANDOFF.md`. Session-local
suite/review evidence: `/tmp/pixlnd-aggro-publish.TliE3c/`. No visual test was needed; the green
suite does not prove runtime implementation of the new ontology rules.

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
