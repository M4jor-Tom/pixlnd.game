---
name: "verify-pixlnd-nvidia-launcher"
description: "Use when updating or verifying pixlnd's optional NVIDIA Nix launcher, especially across nixpkgs or nixGL changes."
version: 1
created: "2026-10-20"
updated: "2026-10-20"
---
## When to Use
Use for the optional x86-64 Linux #nvidia app, host-driver matching, or launcher regressions. This is packaging work, not authority to change gameplay or renderers.

## Procedure
1. Read flake.nix and ontology/decisions/nix-nvidia-launcher.md. Keep the ordinary default app and dev shell independent of host-driver detection; import nixGL with the same pinned nixpkgs as Godot.
2. Before changing the nixGL pin, inspect compatibility with current nixpkgs: NVIDIA override arguments, open/closed kernel-module version strings and Vulkan ICD filenames. Upstream default or a registry/package name alone is not compatibility proof.
3. Run `timeout 900 bash tests/test_flake.sh`. NVIDIA boot must be gated on x86-64 Linux plus a loaded module; a skipped boot is not runtime acceptance. Keep pure app metadata enumeration lazy enough not to force unsupported platform packages.
4. From a scratch working directory, run `timeout 180 nix run --impure /absolute/path/to/pixlnd#nvidia -- --quit-after 3`. Read the log for both a real NVIDIA Vulkan device and project-specific `pixlnd:` startup. Headless exit zero alone does not verify graphics.
5. If investigating OpenGL, compare forced `--rendering-method gl_compatibility` runs of both default and NVIDIA apps before calling a failure a regression. Do not change the production renderer merely to hide driver-loading errors.

## Pitfalls
- NVIDIA userspace libraries must match the loaded host kernel module; a matching installer must be available from NVIDIA. The flake installs no kernel module and does not guarantee hybrid-GPU selection.
- Full flake app checking forces the impure NVIDIA app; use scoped pure-default checks separately. Existing Intel-macOS support can already be absent in pinned nixpkgs.
- A shared launcher preserves --path and quoted argument forwarding. Checking project-specific startup with `-- --class=ranger` distinguishes actual game boot from Project Manager.
- Local NixOS NVIDIA success does not establish Ubuntu laptop acceptance; keep target-machine and forced-OpenGL limitations explicit.

## Verification
1. Focused launcher test passes, and unsupported architectures skip NVIDIA boot rather than invoking a missing app.
2. Default app remains purely evaluable on supported platforms and selects the game outside the checkout.
3. Windowed NVIDIA run reports Vulkan hardware and project startup without errors.
4. No unrelated nixpkgs, engine, renderer, gameplay, commit or publication changes are included.