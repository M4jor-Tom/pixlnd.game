# Device-independent controls and controller profiles

Status: owner-approved documentation direction. Gameplay and controller-tool implementation
are not authorized. Recorded: 2026-10-18; no D-number is assigned. Authority: the owner's
controls-design request followed by the amendment below.

## Context and choice

Android players need an input contract independent of existing keyboard coupling. The owner
selected one canonical catalog of distinct player intentions, with controller profiles referring
to it. Effective definitions: [controls](../domain/controls.md) and
[controller profiles](../domain/controller-profiles.md). Effects and gates retain their existing
owners; this is not a balance rewrite, new gameplay or an engine schema selection.

Original owner request:

> I need controls for the android players of this game. Ensure a clear and proper definition of controls, agnostic to keyboards/gamepads/anything, and that the controllers (keyboard, etc) refer to the said definition of controls. Dispatch subagents to fetch every doclink defining controls in @ontology/, then centralize them, and refer them for each controller. Once done, dispatch subagents to find online tools allowing to implement controls for games on android devices, propose them for me to pick one, then, record its picking as a decision. Next session, I'll send an implementer to add it to the game, following the definition we will have made

Owner amendment, after the proposed catalog/profile separation:

> For the boundaries: Even if keyboard implemented shared controls, split and define them distinctly in the canonical definition of controls; Afterwards, if for technical reasons, we must take the decision to bind several distinct keyboard keys to the same control, or several controls to the same key with different input shapes, that's the keyboard's matter only. If you run in historical facts which do not longer belong to the present, drop them to save context for future implementers, which only require present-time documentation

## Rationale, alternatives and scope

The owner explicitly requires distinct meanings even when keyboard inputs overlap and wants
future implementers to consume present-time definitions without obsolete control history.
Treating shared inputs as one semantic action is rejected by that amendment. No other rationale
or evaluated tool alternatives were supplied. Existing keyboard coupling is described only in
its profile; it is not prescribed for gamepad or Android.

This supersedes scattered physical control definitions/version tables as current control
navigation, not existing gameplay effects, slot identities, balance decisions or source archives.
[D17](runtime-profiling.md) still owns profiling-overlay behavior; its physical default belongs
to the keyboard profile. Unknown interaction details stay bounded, not guessed. The writer
scope is documentation and verified inert metadata; executable hybrid bindings remain intact.
Android tool research and owner selection are later work: **no tool or layout is selected**.
