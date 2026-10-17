---
name: "verify-pixlnd-combo-boundaries"
description: "Use when modifying pixlnd class-skill, projectile or multi-hit combo bookkeeping and its regressions."
version: 1
created: "2026-09-17"
updated: "2026-09-17"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

## When to Use
Use for authorized combat changes that affect hit counting, misses, channels, caps or inactivity. Read ontology/domain/3_Classes.dsl (locator=combo-system) and the current authorization first.

## Procedure
1. Trace result ownership before editing: player._strike applies damage/statuses and returns target count; _landed applies combo/cap/timer and optionally M1 rewards. Weapon attacks, projectile volleys and abilities own their respective hit/miss boundaries. Putting gains into player._strike would double-count existing callers.
2. Use game/combat/test_class_combos.gd for real-player/creature fixtures and controlled ability ticks. Observe the intended failures before editing. Distinguish one multi-target strike, repeated channel ticks and a multi-shot volley.
3. Check channels with no hits, a late hit and repeated hits; cover duration expiry, stamina exhaustion and reset. Check normal inactivity during a previously successful channel so accumulated hits cannot revive an expired combo.
4. Assert zero-damage taunts with and without targets leave count/timer untouched while still provoking/healing. Cover heals, buffs, movement-only dashes and projectile side heals against accidental miss settlement.
5. Run the focused combo test, all game tests, ontology validation and headless boot with timeout 90 nix develop -c godot. If an existing buff/damage fixture fails, inspect its prior combo state before changing the runtime or expected damage.
6. For native HUD evidence, bind game/meta/hud.gd in a temporary fixture copy, await rendering, assert the combo label after hit/miss and capture root.get_texture().get_image(). Inspect captures; keep instrumentation outside production.

## Pitfalls
- Calling _landed(true) for a class skill adds basic-hit MP/finisher rewards; existing non-basic bookkeeping uses false.
- Resetting on each empty channel tick violates the whole-channel miss policy; clearing channel state without settlement misses early endings.
- A zero-damage taunt can return affected targets: target count alone does not authorize combo gains.
- Previously discarded skill hits can legitimately raise a subsequent M1's damage. Isolate buff-only test fixtures rather than undoing correct gains.
- Manual dash completion tests do not prove wall collision or full death-to-reset wiring; label source-traced coverage separately.

## Verification
1. Focused red-to-green evidence exercises the intended bug, not parse/setup errors.
2. Full suite passes; unrelated data/runtime files and any earlier pending repairs remain intact.
3. HUD assertions and inspected captures agree with hit/miss state.
4. Fresh correctness and ponytail reviews examine the diff and logs; record coverage limits without claiming multiplayer verification.