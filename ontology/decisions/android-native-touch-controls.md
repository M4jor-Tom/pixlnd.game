# Android native touch controls

Selected tool stack: native Godot `VirtualJoystick`, `TouchScreenButton` and a dedicated
touch-look region. The bounded first-slice adapter is implemented and owner hardware-tested on
Android. Detailed device/checklist coverage is unrecorded; broader controls work requires separate authority.

Native controls require no third-party addon dependency. A transparent UI-only SubViewport
receives only owned native widget events and an explicitly owned panel pointer; world/body
simulation remains in its original viewport. This avoids coupled root mouse emulation while
keeping native widgets functional, at the cost of an extra full-size UI composition whose
Android render cost still needs measurement. Game-specific adapter and lifecycle
integration remain necessary; API availability does not verify Android behavior.

[Canonical controls](../domain/controls.dsl) own meanings;
[the Android profile (locator=android)](../domain/controller-profiles.dsl) owns physical policy and scope.
See the [implementation backlog](../../docs/ROADMAP/todo_implement.md#device-independent-controls-documentation-only).

## Tool references

- [VirtualJoystick (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_virtualjoystick.html)
- [TouchScreenButton (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_touchscreenbutton.html)
