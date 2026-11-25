# Controller profiles

Profiles bind only the [canonical controls](controls.md). Physical choices, aliases, context
multiplexing and binding names belong here, never in action meanings. The selected Android subset is
in [`controller-profiles.json#android`](../instances/controller-profiles.json).
Structural records are [`controller-profile`, `android-controller-profile` and
`android-profile-parameters`](../schema/meta-controller-profiles.yaml),
[`input-binding`](../schema/meta-input-binding.yaml), and literal
[`android-profile-source-row` / `keybinds-source`](../schema/catalog-meta-rulesets-controls.yaml).

## Keyboard and mouse

Stable profile ID: `keyboard-mouse`. [`keybinds.json#hybrid`](../instances/keybinds.json)
supplies the 27 physical defaults. The table distinguishes their meanings and coupling.

| Binding | Canonical action(s) and shape | Qualifications |
|---|---|---|
| `move` | [move](controls.md#move), held directions | Normalize the held keyboard direction; this default selects no analog speed-scaling policy. |
| `jump` | [jump](controls.md#jump) start/hold/release; [swim-ascent](controls.md#swim-ascent) hold in water | Shared input; distinct intentions |
| `sprint` | [sprint](controls.md#sprint) hold | Not source class utilities |
| `dodge` | [dodge](controls.md#dodge) press while moving | No standing class-skill alias |
| `basic-attack` | [basic-attack](controls.md#basic-attack) press | No held auto-repeat |
| `special-attack` | [special-attack](controls.md#special-attack) charged start/hold/release or instant press; [block](controls.md#block) eligible hold | Same hold blocks and charges; release executes special and ends the block request |
| `class-skill-1` | [class-skill-1](controls.md#class-skill-1) press | — |
| `class-skill-2` | [class-skill-2](controls.md#class-skill-2) press | No activation hold required for the resulting channel |
| `class-skill-3` | [class-skill-3](controls.md#class-skill-3) press | Assassin Camouflage only here |
| `class-skill-4` | [class-skill-4](controls.md#class-skill-4) press | Requires a tree ultimate; no Assassin action |
| `ultimate` | Alias of [class-skill-4](controls.md#class-skill-4) press | Neither a fifth skill nor alternate Assassin Camouflage |
| `climb` | [climb](controls.md#climb) grab request | Release/detach and conflict handling unselected |
| `interact` | [interact](controls.md#interact) press; shared input also requests [pick-up](controls.md#pick-up) and shop [ui-cancel](controls.md#ui-cancel) | Context-specific; not a merged action |
| `pick-up` | [pick-up](controls.md#pick-up) press | Shares the interact input in the pickup context |
| `quick-item` | [quick-item](controls.md#quick-item) press | Quick consumable use; selector distinct |
| `quick-select` | [quick-select](controls.md#quick-select) | Cycle/commit mapping unselected |
| `lamp` | [lamp](controls.md#lamp) | — |
| `pet-call` | [pet-call](controls.md#pet-call) | No mount binding selected |
| `crafting` | [crafting](controls.md#crafting) | — |
| `inventory` | [inventory](controls.md#inventory) press toggles | — |
| `skills-window` | [skills-window](controls.md#skills-window) press toggles | — |
| `world-map` | [world-map](controls.md#world-map) press | M toggles the fixed boundary/player overview |
| `chat` | [chat](controls.md#chat) | — |
| `menu` | [menu](controls.md#menu) request; shop [ui-cancel](controls.md#ui-cancel) press | Shop closes; other contexts have no general routing priority |
| `help` | [help](controls.md#help) | — |
| `debug-menu` | [debug-menu](controls.md#debug-menu) cycle request | D17 overlay cycle |
| `zoom` | [zoom](controls.md#zoom) adjustment | Camera zoom; not map zoom |

Captured mouse motion supplies [look](controls.md#look). Panel navigation, selection and activation
are distinct: selection alone does not equip, use, spend, buy or sell. The list context determines
the operation. No portable physical panel defaults or general priority among pickup, climb,
objects and pets follow. Inventory/skills/shop retain [live time](3_Classes.md#hud-element).
Menu and shop cancellation are distinct, and the ultimate alias cannot create another skill.

No separate physical defaults are selected for separate block, swimming ascent, mount/dismount, glider/boat,
object activation, formula learning, quick cycling or bench/map manipulation. The world map is
toggled by M; map manipulation remains unselected.
[Map operations](controls.md#screens-and-contextual-ui) have unselected physical gestures;
obsolete source maps are not defaults. No extra inventory alias, standing dodge alias, class chord or
UI-scale binding is inherited. No rebinding persistence or device-resolved prompts are selected here.

## Gamepad

Stable profile ID: `gamepad`. **Unselected.** Refers to every applicable
[canonical action](controls.md), including separate movement/look, block/special, jump/ascent,
interaction/pickup/climb, recall/mount, slots and contextual UI/map operations. Buttons, axes,
triggers, layout, focus navigation, sensitivity/deadzones and shared-input shapes have not been
chosen. Native UI support alone is not a gameplay profile; do not inherit keyboard coupling.

## Android

Stable profile ID: `android`. The physical policy serves the same [54-action catalog](controls.md);
unmapped intentions gain no physical defaults.

<a id="android-layout"></a>
### Landscape layout and fixed joystick

Landscape in either direction; a fixed movement joystick at bottom-left, a right-side drag
region for look, and separate action buttons. Keep controls within the screen safe area and
each touch target at least the [`android-profile-min-target-dp`](../schema/meta-controller-profiles.yaml)
minimum in both width and height; larger targets are allowed. Block and special have separate buttons;
NPC Talk and Pick Up remain separate. No automatic targeting or lock-on is introduced.

<a id="android-response"></a>
### Movement response and camera sensitivity

For joystick radius R and deadzone ratio D from
[`android-profile-deadzone-ratio`](../schema/meta-controller-profiles.yaml), displacement of
magnitude <= D R requests neutral. Beyond that,
normalize the direction and request the existing full walking/swimming speed; retain existing
movement eligibility, multipliers and costs from `generators.json#design.movement`.
Sprint is a separate hold: no automatic sprint or new slow-walk curve.

Dragging right looks right; dragging up looks up. Let W be the usable safe-area screen width
and dx/dy the right/down-positive screen deltas in the same units. Let K be
[`android-profile-look-deg-per-safe-width`](../schema/meta-controller-profiles.yaml), in degrees.
Apply yaw adjustment `-K * dx / W` and pitch adjustment `-K * dy / W`: a full-width drag turns
K degrees, with the same degrees-per-distance vertically. Preserve existing
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

<a id="android-interruption"></a>
### Intentional release versus interruption

For [charged specials](3_Classes.md#special-attack), only a normal release by the owning finger
inside the special button intentionally completes the charge under existing execution rules.
Sliding outside cancels without firing or spending reserved MP; interruption never becomes
release-to-fire. Cancellation adds no MP refund beyond not spending the reserved amount.
Instant specials retain their trigger shape.

For held buttons, sliding outside ends the request; sliding back does not restart it. The same
physical touch cannot rearm or transfer: a fresh touch is required. Focus loss, backgrounding,
panel opening, layout changes and death clear outstanding touch requests and cancel unfinished
charges. Returning never resumes them automatically. Already-fired attacks, running abilities
and cooldowns retain their existing rules; committed effects are not undone. This selects input
cleanup, not background simulation, pause or save policy.

<a id="android-panels"></a>
### Inventory, skills and shop touch interaction

One inventory, skills or shop panel owns the screen at a time; opening another replaces it
without leaking gameplay input. Gameplay touch controls, including look, are unavailable
while browsing. [Time still runs and players remain vulnerable](3_Classes.md#hud-element).
Panel transitions clear outstanding touches under the [interruption rule](#android-interruption).

Tap a row to select it, then use a clearly labeled **Equip / Use / Spend / Buy / Sell** button
for the corresponding existing operation. Scrolling or selecting alone never commits an
operation; confirmation commits only on release inside its button. Close or Android Back
closes the panel and consumes that input; gameplay requires fresh touches afterward.
This selects no other menu or keyboard behavior.

<a id="android-first-slice"></a>
### First implementation scope and button activation

The initial touch scheme covers movement
and look, sprint, separate Jump / Swim Up, basic/special attacks, block, dodge, available class
slots, separate Talk / Pick Up, Quick Item, inventory, skills, shops and camera zoom. These
map to the existing distinct [canonical actions](controls.md), not new gameplay permissions.
Gameplay trigger buttons fire once on touch-down, without repetition; held and charged actions
retain their own lifecycles. [Panel confirmations](#android-panels) commit on release inside.
Entering a new context never converts an existing hold into another action.

First-stack Quick Item is a bounded selection, not the final consumable-selection or channel
policy. Climbing, pets, gliding, crafting and full terrain-map controls are not removed from the
54-action target. The fixed boundary/player overview is the selected map exception.

<a id="android-request-order"></a>
### Requests arriving together

Interruptions and UI ownership first suppress uncommitted gameplay requests. Otherwise apply
current movement/look and held defence updates, then process action requests in arrival order.
After each request, check existing eligibility, resources and cooldowns for the next. This is
adapter ordering, not a new exclusive-one-action rule or additional attack permission.
No automatic retries or buffered attacks; already-committed effects are not undone.

<a id="android-camera-zoom"></a>
### Camera zoom mapping

Separate **Camera nearer / Camera farther** buttons map to [zoom](controls.md#zoom). Each tap
applies one existing `generators.json#design.camera.distance.step` toward nearer/farther within
the existing minimum/maximum bounds; no held repetition or pinch gesture. Distance zero
retains first-person view. Finger ownership, panel gating and trigger rules above apply;
map zoom is distinct and remains deferred.

<a id="android-device-scope"></a>
### Device switching and customization in this slice

Android gameplay initially uses the touch profile only; desktop keyboard/mouse is unchanged.
External keyboard/mouse gameplay on Android, gamepad switching, automatic device switching,
rebinding, layout editing and saved control preferences are deferred in this slice, not
permanently excluded or assigned future defaults. Android labels describe touch actions,
not keyboard instructions such as “B closes”.

<a id="android-world-map"></a>
### Android world map

The approved map exception to the first-slice map deferral is a fixed boundary-and-player
overview; it reveals no terrain and supports no map manipulation. A dedicated **Map** trigger
opens it. **Close** and Android **Back** close it and consume the input. While open, gameplay
touch requests are unavailable; transitions clear outstanding touches under the existing
interruption and ownership rules. Targets retain the existing safe-area, 48 dp minimum and
finger ownership requirements.

<a id="android-back"></a>
### Android Back when no panel is open

With a [supported panel](#android-panels) or the [world map](#android-world-map) open, Back closes it and consumes the input.
Otherwise consume Back without attacking, quitting or opening a new menu. Players can
background the app through Android system navigation; the [touch-cleanup rule](#android-interruption)
applies. This adds no pause, background simulation, save policy or system-menu implementation;
future menus retain their own design requirements.
