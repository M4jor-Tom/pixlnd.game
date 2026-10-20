# NVIDIA userspace libraries for the Nix launcher

## Context

Non-NixOS Linux does not provide Nix applications with a compatible graphics-library
closure automatically. NVIDIA userspace libraries must match the loaded kernel driver's
version; bundling an arbitrary driver or replacing Vulkan with OpenGL does not solve that.

## Decision

Use nixGL's NVIDIA Vulkan wrapper for the optional x86-64 Linux `nvidia` app. It also
sets up OpenGL/EGL libraries. Import it with the game's pinned nixpkgs to avoid mixing
libc versions, allow proprietary packages only in that import, and omit 32-bit wrappers.
The existing default app and development shell remain independent of host-driver detection.

Pin the reviewed source of [nix-community/nixGL#221](https://github.com/nix-community/nixGL/pull/221)
at `51471fb4760efda2defba73bc1c264b7ba5364c2`. The upstream default lacks fixes for the
removed nixpkgs `kernel` argument, newer open-kernel-module version strings and renamed
Vulkan ICD manifests. Do not replace this pin with upstream default until those fixes are present.

## Consequences

`--impure` and a loaded host NVIDIA kernel module are required. Matching installers must
be available from NVIDIA, so not every distribution-specific driver build is supported.
Initial evaluation/build can download driver libraries; the app installs no kernel module.
Full app evaluation, including `nix flake check`, is host-dependent and requires `--impure`;
the default app remains pure. This launcher is not a renderer fallback or a guarantee for
unsupported hardware, broken host drivers or hybrid-GPU device selection.

Usage and bounded checks live in [game/README.md](../../game/README.md#nix-launchers).
