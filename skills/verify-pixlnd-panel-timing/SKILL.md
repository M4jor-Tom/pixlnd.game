---
name: "verify-pixlnd-panel-timing"
description: "Use when changing pixlnd player timers or gameplay input handling while native inventory, skill-tree or shop panels are open."
version: 1
created: "2026-09-17"
updated: "2026-09-17"
---

**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

## When to Use
Use for authorized panel-time or input-gating changes in pixlnd. This is verification guidance, not permission to change gameplay or unrelated menu policies.

## Procedure
1. Read ontology/domain/3_Classes.md#hud-element and the current implementation authorization/decision record; consult todo_decide.md only if present. Trace every writer of player.ui_open and every Input read in player.gd.
2. Use game/entities/test_panel_time.gd as the real-panel fixture. Drive existing panel hooks and player physics with controlled dt; initialize effects through real gameplay methods. Observe a failing assertion before changing runtime code.
3. Assert both sides of the contract: existing DOT/cooldown/buff/dodge state progresses once per tick, while movement, jump/swim-up, dodge, held block, combat and interaction input stays unavailable. Check that closing restores input and lethal DOT stops the frame.
4. Run the focused test under timeout 90 nix develop -c godot --headless -s game/entities/test_panel_time.gd; then every game/**/test_*.gd, ontology/validate.gd and headless boot. Capture exit codes and inspect logs for script errors.
5. For native visual inspection, use a temporary copy of the fixture outside the repo. After opening each panel, await process_frame and RenderingServer.frame_post_draw, then save root.get_texture().get_image(). Run without --headless and inspect the PNGs; remove no production gates for the capture.

## Pitfalls
- A swimming fixture on the floor can have its negative velocity zeroed by collision. Put it above the floor before asserting sink versus swim-up.
- Returning early for ui_open freezes the simulation; simply removing the return admits gameplay input. Prefer the existing shared update flow with explicit input gates over duplicate timer machinery.
- Manual physics steps and batched key presses do not independently prove event dispatch or every input branch. Shop._open does not test vendor interaction or E/Escape closing.
- A rendered success log is not visual evidence. Narrow-window panel clipping may predate the change and must not be silently fixed outside authorization.
- No multiplayer, active-ability or forced-movement guarantee is proven unless the test actually covers it; distinguish source tracing from runtime assertions.

## Verification
1. Focused regression fails for the intended timing/input defect before the repair and passes afterwards.
2. Full headless suite, validator and boot exit successfully with no script errors.
3. Windowed fixture passes and captured panels are inspected; note coverage limits in the handoff.
4. Independent correctness and ponytail reviews examine the diff and evidence; scope preserves unrelated ontology data, balance and deferred work.