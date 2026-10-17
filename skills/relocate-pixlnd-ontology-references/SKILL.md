---
name: "relocate-pixlnd-ontology-references"
description: "Use when pixlnd ontology Markdown files move and old links, inline references or index-relative targets need mechanical updates."
version: 2
created: "2026-10-15"
updated: "2026-10-17"
---
**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path
before combining relative references; never normalize an alias-plus-`..` path first.
Retain that canonical skill-directory base when reading companions.

## When to Use
Mechanical path maintenance after moving or splitting pixlnd ontology documents; does not authorize semantic review or domain changes.

## Procedure
1. Respect hand.lock: acquire exclusively with an owner/token, snapshot current HEAD/index and candidate bytes outside the repository, and release only the verified owned lock.
2. Derive destination anchors from actual section headings. Preserve version-tagged heading anchors; map historical D/F references to their existing decision snapshot when appropriate.
3. Update plain live references to ontology/domain/index.md or matching section files. Preserve correct relative paths for Markdown links and make moved index links relative to its new directory.
4. Preserve historical '## Snapshot: ontology/domain.md, … source/original lines …' captions: they describe original provenance, not current navigable paths. Edit only path spans elsewhere.
5. Keep all section-body hashes unchanged and preserve inherited staging state. Follow symlinks through their real target rather than editing CLAUDE.md separately.
6. Verify link targets and anchors, allow only historical captions as old-path remnants, parse affected JSON, confirm GDScript changes are comments only, and release the owned lock.

## Pitfalls
- An index does not contain every section anchor; blindly replacing domain.md with domain/index.md breaks anchored links.
- Index links such as domain/0_Conventions.md become wrong after moving the index into domain/.
- Owner history rewrites invalidate earlier HEAD checks; refresh evidence and reacquire a missing lock rather than relying on old ownership.
- Harness discovery can retain a symlink's lexical path. Test alias-first relative reads against canonical target identity, not mere existence: a wrongly resolved AGENTS.md may exist in the profile instead of the repository. Resolve the existing skill file physically before joining relative references.

## Verification
1. Every changed Markdown link resolves to an existing file and heading.
2. All section bodies remain byte-identical; only approved path spans and index link prefixes change.
3. Only preserved historical snapshot captions retain domain.md; staging and executable code remain unchanged.