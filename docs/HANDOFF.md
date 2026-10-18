# Handoff — pending continuation

## Android touch implementation — separate owner authorization required

Next action: obtain separate bounded implementation authority for the
[selected native stack](../ontology/decisions/android-native-touch-controls.md) and settled
[physical policy](../ontology/domain/controller-profiles.md#android), limited to the
[selected first-slice scope](../ontology/domain/controller-profiles.md#android-first-slice), then follow the
[resume → router workflow and authority/precision gate](../skills/ontology-resume-router-slice/SKILL.md).
Tool selection is not runtime permission. Consume the [controls contract](../ontology/domain/controls.md),
[Android profile](../ontology/domain/controller-profiles.md#android) and
[controls backlog](ROADMAP/todo_implement.md#device-independent-controls-documentation-only);
resolve unknown material gameplay edges with the owner, not guessed defaults.

Current entrypoints: [main](../game/main.gd) `_ready()` wires
[input_map.gd](../game/meta/input_map.gd) `build()` and panels;
[player.gd](../game/entities/player.gd) `_physics_process()`, `_defence_tick()`, `_combat_tick()`,
`_special_tick()` and `interact_nearest()` still consume coupled keyboard actions;
[orbit_camera.gd](../game/entities/orbit_camera.gd) `_unhandled_input()` consumes raw mouse look.
[inventory_panel.gd](../game/items/inventory_panel.gd) and
[skill_panel.gd](../game/progression/skill_panel.gd) use `_unhandled_input()` / `_on_activated()`;
[shop_panel.gd](../game/items/shop_panel.gd) uses `_process()` / `_on_buy()` / `_on_sell()`.
These native ItemList paths and independent cursor/UI ownership are not a portable touch adapter.

Pending validation includes three independent movement/look/action touch streams,
release/cancel/focus/background handling, live-time UI restrictions, no duplicate emulated
events, safe-area/size/orientation mapping and actual Android device checks. Physical policy
is selected in the linked profile, not verified by documentation validation. Consume it rather
than treating widget defaults as policy; report genuine material gaps instead of guessing.

## Dormant source continuation — separate owner request required

The earlier finite 108–111 source-pass audit, parent native acceptance/acknowledgment and
publication outcome remain unestablished by this gameplay checkpoint. Inspect existing native
evidence and the prior checkpoint at
`9b63e6e11c8c52b38183624c4fd1c43e9f09a870:docs/HANDOFF.md` before any separately authorized
continuation. Source-status maintenance already exists in `f801166`; do not recreate it or
restore the old §E history. Publishing gameplay documentation renews no earlier conditional
source-pass grant and does not establish its acceptance/publication outcome.

No selected source item is pending; research is not exhausted. Existing remaining evidence gaps
stay at [§7](../ontology/domain/7_Open_points_for_validation.md#7-open-points-for-validation) and
the [validation-contract backlog](ROADMAP/todo_implement.md#validation-contract-documentation-approved-implementation-unauthorized).
Silk/Spinning Wheel quantities remain **HOLD**. Retained/withdrawn source leads stay **UNAPPROVED**;
do not reopen handled class/weapon/lore attributions. Any future sourcing must follow
[lessons](lessons.md) and the current reconciliation contract: only inspected public article
extracts are public-safe; private authenticated DOM/account/token material is prohibited.
This continuation note authorizes no source research, inventory, selection or publication.
