# Repository-owned skills

Each skill has one canonical real directory here. `.pi/skills -> ../skills` and
`.claude/skills -> ../skills` expose the same files to both harnesses in every checkout.
The old local project-memory skill directory and installed resume-skill path are compatibility
symlinks, not active copies. Edit this repository, never maintain parallel skill copies.

Discovery can retain a lexical alias as the loaded file/base directory. Before combining any
relative skill reference, resolve the existing loaded `SKILL.md` to its physical canonical path
(e.g. `realpath` on that file), then use its parent directory. Retain this canonical base for
companions. Never normalize alias-plus-`..` first: it can find a missing file or unrelated profile
instructions instead of repository instructions. Explicitly repo-root-relative paths still use
the repository root; this changes link resolution, not workflow authority or semantics.

- **Pi:** project discovery uses `.pi/skills`; invoke `/skill:<name>` (for example,
  `/skill:ontology-resume-router-slice`) or let a matching request select the skill.
- **Claude Code:** project discovery uses `.claude/skills/<name>/SKILL.md`; invoke `/<name>`
  or let a matching request select the skill.
- **Verify:** run `python3 skills/check.py` from the repository root. It checks the preserved
  twelve-skill inventory, frontmatter, local Markdown links and alias-origin target identity
  through both discovery links and a temporary legacy-style link.

A new `<name>/SKILL.md` becomes visible through both directory links without another copy or
registration file. Update the smoke check's expected inventory when intentionally adding/removing
a skill. Supporting references stay beside their skill; canonical project rules remain in their
existing repository homes and are linked, not duplicated here.
