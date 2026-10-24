# Bounded native physics frame

Keep authoritative horizontal positions in scalar logical coordinates and project active views
into a main/world-owned local frame aligned to the existing terrain zone. Vertical coordinates
and units are unchanged. The stock editor and export toolchain remain selected.

A live translation completes synchronously before actor physics callbacks. Existing kinematic
bodies reenter KINEMATIC through RIGID without an intervening physics step, commit the translated
native pose, then restage any genuine pending scene target. Restore generated velocities and
sleep through direct state; preserve constant velocities, RIDs, shapes and script state.
Static bodies use their normal transform path. Cold creation and explicit discontinuous relocation
have separate ownership and must not be mistaken for pending physical movement.

Logical anchors retain measured native displacement against a local sample; frame translations
change the sample, not durable position. Saved data never contains the transient origin.
This avoids far-coordinate native-contact instability without a custom precision build or an
oppositely translated enormous parent/child hierarchy. It requires complete spatial/cache ownership
and actual contact, lifecycle, Area, action and persistence verification; mechanism feasibility
alone does not establish integrated correctness or bitwise translation invariance.

Canonical meanings remain in [world](../domain/3_Classes.md#world),
[save-data](../domain/3_Classes.md#save-data), [AI](../domain/3_Classes.md#ai-behavior),
[controls](../domain/controls.md) and the [encounter contract](../domain/encounter-contracts.md).
No gameplay values, membership policy, remote simulation or backend/export change follows.
