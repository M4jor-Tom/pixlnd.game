# Android touch profile

Status: accepted owner documentation choices; runtime implementation unauthorized and unimplemented.
Recorded: 2026-10-18. Authority date and decision ID were not supplied; no D-number is assigned.

## Context and authority

The [device-independent direction](device-independent-controls.md) separates player intentions
from physical mappings. The [native stack choice](android-native-touch-controls.md) selected
only tools; this later policy extends that scope, not the historical approval itself.
The owner requested Android design reconciliation and selected all ten recommended options
without amendments, first answering exactly:

> 1: Approved; 2: Approved; 3: Approved; 4: Approved; 5: Approved; If there's currently other points to clarify on this very topic, bring them up now. Otherwise, I'll send an implementer to run them

Then answering exactly:

> 6: Approved; 7: Approved; 8: Approved; 9: Approved; 10: Approved;

This is one significant physical-profile decision bundle. Effective rules live only in the
[existing Android profile](../domain/controller-profiles.md#android); gameplay effects, costs,
class slots and eligibility keep their existing owners. No gameplay, behavior-changing JSON,
loader, checker or test implementation follows from these approvals. Separate bounded runtime
authority and actual Android acceptance are still required. No prior tool selection or
canonical action meaning is superseded; earlier unselected physical boundaries are resolved
only within the selected scope below. Owner motivation beyond the proposals is unavailable;
tradeoffs below describe the selected options, not invented owner reasoning.

## Accepted choices and tradeoffs

### 1 — Landscape layout and fixed joystick

Selected recommended option, exact item answer: `1: Approved`. Effective choice:
[landscape layout and fixed joystick](../domain/controller-profiles.md#android-layout).
Fixed controls and separate buttons favor stable placement and distinct intentions over floating controls or merged buttons.

### 2 — Movement response and camera sensitivity

Selected recommended option, exact item answer: `2: Approved`. Effective choice:
[movement response and camera sensitivity](../domain/controller-profiles.md#android-response).
A neutral zone followed by full speed retains existing movement rather than adding analog slow walking; width-based look gives a fixed scale without acceleration.

### 3 — Finger ownership and simultaneous controls

Selected recommended option, exact item answer: `3: Approved`. Effective choice:
[finger ownership and simultaneous controls](../domain/controller-profiles.md#android-finger-ownership).
Stable finger ownership supports concurrent input while preventing crossing or extra fingers from activating other controls.

### 4 — Intentional release versus interruption

Selected recommended option, exact item answer: `4: Approved`. Effective choice:
[intentional release versus interruption](../domain/controller-profiles.md#android-interruption).
Fresh-touch rearming and release-inside completion favor intentional actions over automatic resumption; committed effects keep their existing lifecycles.

### 5 — Inventory, skills and shop touch interaction

Selected recommended option, exact item answer: `5: Approved`. Effective choice:
[inventory, skills and shop touch interaction](../domain/controller-profiles.md#android-panels).
Explicit selection and confirmation separate browsing from committing operations; live-time vulnerability remains unchanged.
