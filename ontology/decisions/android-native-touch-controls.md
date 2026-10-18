# Android native touch controls

Status: accepted owner tool choice; unimplemented. Recorded: 2026-10-18.
Authority: the owner's answer below; authority date and decision ID are not supplied.
Documentation approval is not runtime implementation permission.

## Context and choice

Android needs a touch adapter for the [canonical intentions](../domain/controls.md), with
physical mappings owned only by the [Android profile](../domain/controller-profiles.md#android).
The [device-independent controls direction](device-independent-controls.md) remains in force:
shared keyboard inputs do not merge meanings, and implementer docs retain only current rules.

The owner answered exactly:

> 1. Approved

This approves option 1 exactly:

> Native Godot controls — VirtualJoystick, TouchScreenButton, dedicated touch-look region

Only the tool stack is selected. No touch layout, joystick mode, targeting/lock-on, analog
speed policy or gameplay implementation is approved.

## Rationale, alternatives and tradeoffs

The presented benefits were no additional dependency, available fixed/floating/following
joystick modes, and native API availability confirmed in pinned Godot 4.7.2. The presented
caveat was remaining game-specific semantic adapter, layout and interruption work. No further
owner motivation was supplied. API availability does not verify widget or Android behavior.

Alternatives considered included [Wesley's joystick](https://github.com/Wesley-Source/versatile-mobile-joystick),
with extra integration/lifecycle work, and [Marco's joystick](https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot),
whose `VirtualJoystick` script class name collides with the native name in 4.7.2. The narrow
name collision does not establish a full addon import result. Neither addon is selected.

## Consequences and effective rules

The native widgets are building blocks, not an implementation of all 54 actions or a reason
to merge them. The [controls contract](../domain/controls.md#contract) and
[Android profile](../domain/controller-profiles.md#android) retain unresolved sensitivity/axes,
finger ownership/routing, intentional completion versus interruption outcomes, safe-area
mapping and UI integration. Existing effect, cost and eligibility rules are unchanged.
Separate implementation authority, precise material gameplay rules and device validation are
still required; see the [implementation backlog](../../docs/ROADMAP/todo_implement.md#device-independent-controls-documentation-only).
This resolves only the earlier direction's pending Android tool choice, not its layout or
other boundaries, and introduces no third-party addon dependency.

## Primary references

- [VirtualJoystick (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_virtualjoystick.html)
- [TouchScreenButton (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_touchscreenbutton.html)
- [InputEventScreenTouch (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_inputeventscreentouch.html)
- [InputEventScreenDrag (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_inputeventscreendrag.html)
- [Godot engine MIT license and notices](https://godotengine.org/license/)
