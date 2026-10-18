# Controls

The single present-time catalog of **player intentions**, independent of any device.
[Controller profiles](controller-profiles.md) refer to these stable action IDs; they alone
own physical bindings, aliases and shared-input phases. An action is not an ability, a key,
an engine InputMap name or proof of implementation. Effects, costs, eligibility and balance
remain in the linked gameplay definitions; later owner approvals override stale instance prose.

## Contract

- Each row has a stable ID/anchor, meaning, value/lifecycle and context. Distinct intentions
  stay distinct even when a profile currently drives them from the same input.
- **Trigger** means one request on activation, not automatic repetition. **Held** means
  active/inactive with start/end. **Direction** and **adjustment** describe semantic values,
  not a device axis, sensitivity, deadzone or analog speed-scaling policy.
- Special-attack release is an intentional completion for charged classes, not a universal
  cancellation rule. Device interruption, focus loss, interrupted holds, UI consumption and
  conflicting simultaneous requests need explicit adapter treatment; this catalog does not
  choose their gameplay outcome or arbitration priority.
- Context limits meaning; it does not add eligibility or new input availability. In particular,
  inventory/skills/shop retain their [live-time and input restrictions](3_Classes.md#hud-element).
  Time/input behavior for other menus is not selected. Enemy [current-target](4_Relations.md#threat-and-current-target-hybrid)
  is not a player lock-on control; no new targeting is introduced here.

## Locomotion and view

| ID | Intention | Value / lifecycle | Context and effect owner |
|---|---|---|---|
| <a id="move"></a>`move` | Move horizontally | 2-D direction; neutral stops requesting movement | Camera-relative [player movement](3_Classes.md#player-character); applies to existing walking/swimming contexts, no analog speed rule selected |
| <a id="look"></a>`look` | Change view / aim direction | 2-D directional adjustment | [Camera](../instances/ui.json) `camera` and [weapon aiming](3_Classes.md#weapon-type); profile chooses physical representation, not new targeting |
| <a id="zoom"></a>`zoom` | Adjust gameplay camera distance | Signed distance adjustment | [Camera](../instances/ui.json) `camera`, `generators.json#design.camera`; retained third/first-person transition |
| <a id="sprint"></a>`sprint` | Sprint | Held | [Movement](3_Classes.md#player-character), not a class-utility alias |
| <a id="jump"></a>`jump` | Jump from ground | Start, held sustain, release | [Movement](3_Classes.md#player-character); tap/hold height, no new airborne jump |
| <a id="swim-ascent"></a>`swim-ascent` | Swim upward | Held; end stops ascent request | [Swimming movement](3_Classes.md#player-character); separate from jump |
| <a id="climb"></a>`climb` | Grab / climb a surface | Grab request; ongoing direction via `move`; release/detach shape unselected | Existing [climbing](3_Classes.md#skill-tree-a) and [c-climbing](5_Constraints.md#constraint-catalog); runtime deferred, no new gate |
| <a id="pet-call"></a>`pet-call` | Recall active pet | Trigger | [Pet](3_Classes.md#pet); not mounting |
| <a id="pet-mount"></a>`pet-mount` | Mount eligible pet | Trigger | [Pet](3_Classes.md#pet) / `c-riding`; does not recall or bypass training/Reins |
| <a id="pet-dismount"></a>`pet-dismount` | Request dismount | Trigger; physical mapping unselected | [Pet](3_Classes.md#pet); automatic dismount causes remain gameplay rules |
| <a id="deploy-glider"></a>`deploy-glider` | Deploy equipped glider | Trigger; stow/toggle shape unselected | [Traversal](3_Classes.md#skill-tree-a), `c-gliding`; not boat deployment |
| <a id="deploy-boat"></a>`deploy-boat` | Deploy equipped boat | Trigger; stow/toggle shape unselected | [Traversal](3_Classes.md#skill-tree-a), `c-sailing` |
| <a id="glider-level"></a>`glider-level` | Level glider flight | Active request; hold/repeat shape unselected | [Glider effect](../instances/abilities.json) `deploy-special-item`; runtime deferred, no binding or gate inferred |

## Combat and class skills

| ID | Intention | Value / lifecycle | Context and effect owner |
|---|---|---|---|
| <a id="basic-attack"></a>`basic-attack` | Use weapon's basic attack | Trigger | [Weapon moveset](3_Classes.md#weapon-type) |
| <a id="special-attack"></a>`special-attack` | Use weapon's special attack | Charged classes: start, hold to reserve, release to execute/spend; instant class: trigger | [Special attack](3_Classes.md#special-attack), `generators.json#design.special-attack`; not a block request |
| <a id="block"></a>`block` | Defend with eligible equipment/stance | Held; end stops request | [Combat block](3_Classes.md#combat-block); Cyclone-derived automatic blocking remains an effect, not another activation |
| <a id="dodge"></a>`dodge` | Dodge in movement direction | Trigger, uses current `move` direction | [Dodge](3_Classes.md#dodge); existing movement/eligibility restrictions |
| <a id="class-skill-1"></a>`class-skill-1` | Activate first class skill | Trigger | [Skill tree](3_Classes.md#skill-tree-a) class rank 1; linked ability owns effect |
| <a id="class-skill-2"></a>`class-skill-2` | Activate second class skill | Trigger | Class rank 2; a resulting channel/buff is not an activation hold |
| <a id="class-skill-3"></a>`class-skill-3` | Activate third class skill | Trigger | Class rank 3; Assassin Camouflage exists only here |
| <a id="class-skill-4"></a>`class-skill-4` | Activate separate ultimate slot, when present | Trigger | [Skill tree](3_Classes.md#skill-tree-a) ultimate column; absent for Assassin, no fifth skill/duplicate Camouflage |

## World and item interaction

| ID | Intention | Value / lifecycle | Context and effect owner |
|---|---|---|---|
| <a id="interact"></a>`interact` | Talk to / request service from NPC | Trigger | [NPC](3_Classes.md#npc-role), [services](../instances/ui.json) `screens.npc-service`; not pickup or climb |
| <a id="pick-up"></a>`pick-up` | Collect nearby ground item | Trigger | [Inventory](3_Classes.md#inventory), `generators.json#design.loot.ground`; automatic currency pickup remains automatic |
| <a id="object-interact"></a>`object-interact` | Activate world object | Trigger with object context | [Static entity](3_Classes.md#static-entity) / [key item](3_Classes.md#key-item); object-specific effect, no universal new activation permission |
| <a id="lamp"></a>`lamp` | Toggle light | Trigger | [Key item](3_Classes.md#key-item), ability `lantern` |
| <a id="quick-item"></a>`quick-item` | Use quick-selected consumable | Trigger | [Consumable](3_Classes.md#consumable); current adapter uses the first consumable stack; food/potion channel rules are effects, not new control holds |
| <a id="use-inventory-item"></a>`use-inventory-item` | Use selected bag consumable | Trigger with selected bag item | Same [consumable effects](3_Classes.md#consumable), but the inventory selection determines the item, not quick selection or its first-stack approximation |
| <a id="quick-select"></a>`quick-select` | Open consumable selection | Trigger; close/commit shape unselected | [Inventory](3_Classes.md#inventory); current first-stack approximation does not define the final selector |
| <a id="quick-cycle"></a>`quick-cycle` | Change consumable selection | Signed selection step | [Quick selector](../instances/ui.json) `screens.quick-select`; no physical mapping selected |
| <a id="equip-item"></a>`equip-item` | Equip selected item / pet food | Trigger with selected item | [Equipment slot](3_Classes.md#equipment-slot) / [pet food](3_Classes.md#pet-food); existing class/slot/hand rules |
| <a id="learn-formula"></a>`learn-formula` | Learn selected recipe formula | Trigger with selected formula | [Formula](3_Classes.md#formula); sufficient-power and duplicate rules unchanged |
| <a id="spend-skill-point"></a>`spend-skill-point` | Invest one banked point in selected skill | Trigger with selected node | [Skill tree](3_Classes.md#skill-tree-a); not skill activation |
| <a id="buy-item"></a>`buy-item` | Buy selected stock entry | Trigger with selected entry | [Shop](3_Classes.md#shop), `generators.json#design.settlement.shop` |
| <a id="sell-item"></a>`sell-item` | Sell selected bag entry | Trigger with selected entry | Same shop rules; distinct from buying |

## Screens and contextual UI

UI selection/activation below describes routing, not a new gameplay effect. Activating a selected
entry dispatches its distinct intention above (equip, use selected bag consumable, learn, spend,
buy, sell), where applicable.
Text entry/commands remain [chat rules](../instances/slash-commands.json), not one new control per
historical command. Unapproved source-only commands/skills gain no hybrid activation here.

| ID | Intention | Value / lifecycle | Context and effect owner |
|---|---|---|---|
| <a id="inventory"></a>`inventory` | Open/close inventory | Trigger | [Inventory](3_Classes.md#inventory) |
| <a id="skills-window"></a>`skills-window` | Open/close skill tree | Trigger | [Skill tree](3_Classes.md#skill-tree-a) |
| <a id="crafting"></a>`crafting` | Open crafting screen | Trigger | [Recipe](3_Classes.md#recipe) / `ui.json#screens.crafting`; not crafting an entry |
| <a id="world-map"></a>`world-map` | Open/close world map | Trigger | [HUD](3_Classes.md#hud-element); not map manipulation |
| <a id="chat"></a>`chat` | Open chat entry | Trigger | [Slash command](3_Classes.md#slash-command) / chat rules |
| <a id="menu"></a>`menu` | Open system menu | Trigger | [HUD](3_Classes.md#hud-element); runtime only changes cursor capture today, no pause policy inferred |
| <a id="help"></a>`help` | Open help / move list | Trigger | [UI](../instances/ui.json) `screens.move-list`; data-only binding |
| <a id="debug-menu"></a>`debug-menu` | Cycle profiling overlay | Trigger: hidden/compact/full | [D17](../decisions/runtime-profiling.md), not UI scaling |
| <a id="ui-navigate"></a>`ui-navigate` | Move UI focus/selection | Direction or selection step | Existing panel/list selection; repeat/focus topology unselected |
| <a id="ui-select"></a>`ui-select` | Select a UI entry or location | Selection value | Existing screen context; pointer/focus representation is profile-owned |
| <a id="ui-activate"></a>`ui-activate` | Activate focused/selected UI entry | Trigger | Routes to entry's effect, including [use-inventory-item](#use-inventory-item) for a selected bag consumable; no new default operation |
| <a id="ui-cancel"></a>`ui-cancel` | Cancel/close current UI interaction | Trigger | Shop close exists; other contexts' close/consumption behavior unselected; not system-menu opening |
| <a id="map-rotate"></a>`map-rotate` | Rotate map view | Directional adjustment | [Map presentation](../instances/ui.json) `screens.world-map`; not camera look |
| <a id="map-pan"></a>`map-pan` | Pan map view | 2-D adjustment | Same map context; not player movement |
| <a id="map-zoom"></a>`map-zoom` | Change map scale | Signed scale adjustment | Same map context; not gameplay camera distance |
| <a id="map-marker"></a>`map-marker` | Place map marker | Trigger with map location | Same map context; persistence/visibility details not selected here |
| <a id="map-center"></a>`map-center` | Center map on selected visited area | Trigger with area | Same map context; does not move the player |
| <a id="bench-rotate"></a>`bench-rotate` | Rotate customization model | Directional adjustment | [Customization bench](3_Classes.md#customization-bench); not dodge or map rotation |
| <a id="bench-place"></a>`bench-place` | Place customization cube | Placement value and commit | Same bench effect; gesture shape unselected |
| <a id="bench-remove"></a>`bench-remove` | Remove customization cube | Trigger with cube | Same bench effect; removal destroys cube, not a generic UI cancel |

## Unselected boundaries

This is a documentation contract, not runtime authorization or a new engine schema. Profiles
must expose the same distinct meanings without inventing layouts. Android's
[native tool stack is selected](../decisions/android-native-touch-controls.md), not implemented.
Gamepad remains unselected; Android layout/mode, remapping/persistence, device switching,
prompts, axis conventions and input interruption policy remain unselected. Deferred
traversal/bench/map UI shapes and shared-request arbitration remain bounded above. Wall-flip/detach lifecycle, map travel, sleep-consent UI and source-only class-utility/chord activation have
no newly selected controls; their existing gameplay rules remain authoritative. No historical
binding is a fallback for an unspecified present mapping. Pet unsummoning and player item-drop /
trading activation are not selected by the current catalog; old source gestures confer no
activation permission.
