# D17 — Runtime profiling and frame budget

Players profile in-game with the **Godot Debug Menu** add-on (Asset Library “Debug Menu”,
MIT, usable in release exports), on **F3** like Minecraft. Developer-only `monitors/` remain for CI.
Cap physics catch-up via [generators.json](../instances/generators.json) `design.frame-budget`
and `c-frame-budget`; UI binding is `hud-element` debug-menu / `keybinds.json` hybrid debug-menu.
