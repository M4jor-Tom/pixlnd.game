# Controller profiles

Profiles bind only the [canonical controls](controls.md). Physical choices, aliases, context
multiplexing and adapter names belong here, never in action meanings. Status distinguishes a
binding in data from a working feature. No new controller resolver or schema is implemented.

## Keyboard and mouse

Stable profile ID: `keyboard-mouse`. Current executable defaults are
[`keybinds.json#hybrid`](../instances/keybinds.json), consumed by `game/meta/input_map.gd`.
All 27 non-metadata rows are retained, including unused ones. The action references below
interpret the adapter; they do not rename or change its executable entries.

| Adapter row | Canonical action(s) and shape | Current mapping status |
|---|---|---|
| `move` | [move](controls.md#move), held directions | Implemented; expands to `move_forward/back/left/right`; direction normalized, not approved analog speed scaling |
| `jump` | [jump](controls.md#jump) start/hold/release; [swim-ascent](controls.md#swim-ascent) hold in water | Implemented shared input; distinct intentions |
| `sprint` | [sprint](controls.md#sprint) hold | Implemented; not source class utilities |
| `dodge` | [dodge](controls.md#dodge) press while moving | Implemented; no standing class-skill alias |
| `basic-attack` | [basic-attack](controls.md#basic-attack) press | Implemented; not held auto-repeat |
| `special-attack` | [special-attack](controls.md#special-attack) charged start/hold/release or instant press; [block](controls.md#block) eligible hold | Implemented coupling: same hold blocks and charges; release executes special, ends block request. Canonical actions remain separate |
| `class-skill-1` | [class-skill-1](controls.md#class-skill-1) press | Implemented |
| `class-skill-2` | [class-skill-2](controls.md#class-skill-2) press | Implemented; no activation hold required for resulting channel |
| `class-skill-3` | [class-skill-3](controls.md#class-skill-3) press | Implemented; Assassin Camouflage only here |
| `class-skill-4` | [class-skill-4](controls.md#class-skill-4) press | Implemented when tree has ultimate; no Assassin action |
| `ultimate` | Alias of [class-skill-4](controls.md#class-skill-4) press | Implemented alias, not a fifth skill or alternate Assassin Camouflage |
| `climb` | [climb](controls.md#climb) grab request | Registered only; release/detach and conflict handling not selected |
| `interact` | [interact](controls.md#interact) press; current adapter also dispatches [pick-up](controls.md#pick-up) and shop [ui-cancel](controls.md#ui-cancel) | Implemented NPC/pickup dispatch and shop close; not a merged semantic action |
| `pick-up` | [pick-up](controls.md#pick-up) press | Registered row unused directly; pickup currently uses `interact` fallback |
| `quick-item` | [quick-item](controls.md#quick-item) press | Implemented first consumable stack approximation; selector not implemented |
| `quick-select` | [quick-select](controls.md#quick-select) | Registered only; cycle/commit mapping not selected |
| `lamp` | [lamp](controls.md#lamp) | Registered only |
| `pet-call` | [pet-call](controls.md#pet-call) | Registered only; **no mount binding selected** |
| `crafting` | [crafting](controls.md#crafting) | Registered only |
| `inventory` | [inventory](controls.md#inventory) press toggles | Implemented |
| `skills-window` | [skills-window](controls.md#skills-window) press toggles | Implemented |
| `world-map` | [world-map](controls.md#world-map) | Registered only |
| `chat` | [chat](controls.md#chat) | Registered only |
| `menu` | [menu](controls.md#menu) request; shop [ui-cancel](controls.md#ui-cancel) press | Camera currently toggles cursor capture, not a system menu; shop closes. Routing/consumption for other contexts not selected |
| `help` | [help](controls.md#help) | Registered only |
| `debug-menu` | [debug-menu](controls.md#debug-menu) cycle request | Registered only; D17 overlay implementation deferred |
| `zoom` | [zoom](controls.md#zoom) adjustment | Implemented `zoom_in/out`; not map zoom |

Additional current paths bypass this binding table: captured mouse motion supplies
[look](controls.md#look) through `orbit_camera.gd`; native panel ItemLists supply
[ui-navigate](controls.md#ui-navigate), [ui-select](controls.md#ui-select) and
[ui-activate](controls.md#ui-activate), including pointer double-activation. Their precise native
physical event defaults are not a selected portable profile. Activation dispatches
[equip-item](controls.md#equip-item), [use-inventory-item](controls.md#use-inventory-item),
[spend-skill-point](controls.md#spend-skill-point), [buy-item](controls.md#buy-item) or
[sell-item](controls.md#sell-item) by list context. Inventory consumable activation uses the
selected bag item, unlike `quick-item`'s current first-consumable-stack target.

**Shared-input boundaries:** current NPC dispatch checks an NPC before a ground item; this is
an implementation observation, not a new general priority rule for pickup/climb/objects/pets.
Multiple panels independently own cursor state; no exclusive context stack or global priority
is selected here. Inventory/skills/shop retain current input restrictions and
[live time](3_Classes.md#hud-element). `menu`/shop cancellation must not be mistaken for one
canonical meaning or a decision to pause. The alias `ultimate` cannot create another skill.

No executable mappings exist for separate block, swimming ascent, mount/dismount, glider/boat,
object activation, formula learning, quick cycling or bench/map manipulation.
[Map operations](controls.md#screens-and-contextual-ui) have unselected physical gestures;
obsolete source maps are not defaults. No extra inventory alias, standing dodge alias, class chord or
UI-scale binding is inherited. Rebinding UI/persistence and device-resolved prompts are deferred.

## Gamepad

Stable profile ID: `gamepad`. **Unselected / unimplemented.** Refers to every applicable
[canonical action](controls.md), including separate movement/look, block/special, jump/ascent,
interaction/pickup/climb, recall/mount, slots and contextual UI/map operations. Buttons, axes,
triggers, layout, focus navigation, sensitivity/deadzones and shared-input shapes have not been
chosen. Native UI support alone is not a gameplay profile; do not inherit keyboard coupling.

## Android

Stable profile ID: `android`. **SELECTED POLICY / UNIMPLEMENTED.** The
[selected native Godot stack](../decisions/android-native-touch-controls.md) is `VirtualJoystick`,
`TouchScreenButton` and a dedicated touch-look region. The [touch-profile decision](../decisions/android-touch-profile.md)
records the later owner-approved physical policy below. It serves the same [54-action catalog](controls.md),
not a reduced or reinterpreted scheme. Widgets do not implement the catalog or decouple consumers.
Tool and policy approval grant no runtime authority; Android behavior and device acceptance
remain unverified. Unmapped deferred features gain no physical defaults.

<a id="android-layout"></a>
### Landscape layout and fixed joystick

Landscape in either direction; a fixed movement joystick at bottom-left, a right-side drag
region for look, and separate action buttons. Keep controls within the screen safe area and
each touch target at least 48 dp wide and high. Block and special have separate buttons;
NPC Talk and Pick Up remain separate. No automatic targeting or lock-on is introduced.

<a id="android-response"></a>
### Movement response and camera sensitivity

For joystick radius R, displacement of magnitude <= 0.15 R requests neutral. Beyond that,
normalize the direction and request the existing full walking/swimming speed; retain existing
movement eligibility, multipliers and costs from `generators.json#design.movement`.
Sprint is a separate hold: no automatic sprint or new slow-walk curve.

Dragging right looks right; dragging up looks up. Let W be the usable safe-area screen width
and dx/dy the right/down-positive screen deltas in the same units. Apply yaw adjustment
`-180 degrees * dx / W` and pitch adjustment `-180 degrees * dy / W`: a full-width drag turns
180 degrees, with the same degrees-per-distance vertically. Preserve existing
`generators.json#design.camera.pitch-deg` bounds; add no acceleration. This is Android-only
response, not a change to mouse sensitivity or a selection of saved settings.

<a id="android-finger-ownership"></a>
### Finger ownership and simultaneous controls

Each physical touch owns the control where it starts until release/cancellation. Movement
and look each accept one owner; action buttons accept independent fingers. Crossing another
control never activates it. Extra fingers on an occupied control do nothing and cannot take
over when its owner leaves. No captured or ignored touch transfers to another control;
activation requires a fresh touch.

Movement, look and an action must work simultaneously, without overriding gameplay eligibility
or costs. A touch must never also generate a duplicate mouse-driven action.
