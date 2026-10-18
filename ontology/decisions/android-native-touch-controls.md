# Android native touch controls

Selected tool stack: native Godot `VirtualJoystick`, `TouchScreenButton` and a dedicated
touch-look region. Unimplemented; separate bounded implementation authority and Android
device validation are required.

Native controls require no third-party addon dependency. Game-specific adapter and lifecycle
integration remain necessary; API availability does not verify Android behavior.

[Canonical controls](../domain/controls.md) own meanings;
[the Android profile](../domain/controller-profiles.md#android) owns physical policy and scope.
See the [implementation backlog](../../docs/ROADMAP/todo_implement.md#device-independent-controls-documentation-only).

## Tool references

- [VirtualJoystick (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_virtualjoystick.html)
- [TouchScreenButton (Godot 4.7)](https://docs.godotengine.org/en/4.7/classes/class_touchscreenbutton.html)
