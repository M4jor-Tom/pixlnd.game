#!/usr/bin/env python3
"""Portable smoke check for repository skill discovery and local Markdown links."""
from pathlib import Path
from tempfile import TemporaryDirectory
import os
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
EXPECTED = set("""
audit-pixlnd-ontology-consistency
ontology-auto-approve-data-source-precision-increase
ontology-reconcile-topic
ontology-resume-router-slice
record-finding
record-impactful-decision
record-pixlnd-reconciliation-batch
relocate-pixlnd-ontology-references
reorganize-pixlnd-decision-records
verify-pixlnd-combo-boundaries
verify-pixlnd-panel-timing
verify-pixlnd-semantic-rebase
""".split())
PATH_GUIDANCE = (
    "**Path base:** Resolve the existing loaded `SKILL.md` to its physical canonical path\n"
    "before combining relative references; never normalize an alias-plus-`..` path first.\n"
    "Retain that canonical skill-directory base when reading companions."
)


def check_aliases():
    with TemporaryDirectory() as temporary:
        profile = Path(temporary) / "profile"
        (profile / "skills").mkdir(parents=True)
        (profile / "AGENTS.md").write_text("Unrelated profile instructions.\n")
        legacy = profile / "skills/ontology-resume-router-slice"
        legacy.symlink_to(SKILLS / legacy.name, target_is_directory=True)
        aliases = [ROOT / harness / "skills" / name / "SKILL.md"
                   for harness in (".pi", ".claude") for name in sorted(EXPECTED)]
        aliases.append(legacy / "SKILL.md")
        for alias in aliases:
            if alias.parent.name == legacy.name:
                wrong = Path(os.path.abspath(alias.parent / "../../AGENTS.md"))
                assert wrong.resolve() != ROOT / "AGENTS.md", wrong
                print(f"Regression witness: alias-first target {'exists but is wrong' if wrong.exists() else 'is missing'}: {wrong}")
        for alias in aliases:
            skill = alias.resolve(strict=True)  # Resolve existing entrypoint BEFORE joining links.
            assert skill == SKILLS / alias.parent.name / "SKILL.md", alias
            base = skill.parent
            assert (base / "../../AGENTS.md").resolve(strict=True) == ROOT / "AGENTS.md"
            assert (base / "../record-impactful-decision/SKILL.md").resolve(strict=True) == SKILLS / "record-impactful-decision/SKILL.md"
            if base.name == "record-impactful-decision":
                companion = (base / "recording-guidance.md").resolve(strict=True)
                assert (companion.parent / "../../ontology/domain/index.md").resolve(strict=True) == ROOT / "ontology/domain/index.md"
            assert PATH_GUIDANCE in skill.read_text(), f"missing canonical-base instruction: {alias}"
        print("PASS: 25 alias-origin entrypoints, repository/sibling/companion target identity")


def check():
    for harness in (".pi", ".claude"):
        link = ROOT / harness / "skills"
        assert link.is_symlink(), f"missing discovery symlink: {link}"
        assert not link.readlink().is_absolute(), f"nonportable symlink: {link}"
        assert link.resolve() == SKILLS, f"wrong discovery target: {link}"
    found = {p.parent.name for p in SKILLS.glob("*/SKILL.md")}
    assert found == EXPECTED, f"skill inventory mismatch: {found ^ EXPECTED}"
    for name in sorted(EXPECTED):
        directory = SKILLS / name
        assert directory.is_dir() and not directory.is_symlink(), directory
        skill = directory / "SKILL.md"
        assert not skill.is_symlink(), skill
        text = skill.read_text()
        assert text.startswith("---\n"), f"missing frontmatter: {skill}"
        frontmatter = text.split("---\n", 2)[1]
        fields = dict(re.findall(r"^(name|description):\s*(.+)$", frontmatter, re.M))
        assert fields.get("name", "").strip('\"\'') == name, skill
        description = fields.get("description", "").strip('\"\'')
        assert description and len(description) <= 1024, skill
    entrypoints = [ROOT / p for p in (
        "AGENTS.md", "docs/lessons.md", "docs/ROADMAP/README.md",
        "ontology/AGENTS.md", "ontology/decisions/AGENTS.md",
    )]
    documents = sorted(SKILLS.rglob("*.md")) + entrypoints
    for document in documents:
        for target in re.findall(r"\[[^\]]*\]\(([^\s)]+)\)", document.read_text()):
            url = urlsplit(target)
            if url.scheme or url.netloc:
                continue
            path = document.parent / unquote(url.path) if url.path else document
            assert path.exists(), f"broken link: {document}: {target}"
            if url.fragment and path.suffix == ".md":
                headings = re.findall(r"^#+\s+(.+)$", path.read_text(), re.M)
                anchors = {re.sub(r"[^\w\- ]", "", h.lower()).replace(" ", "-") for h in headings}
                assert unquote(url.fragment) in anchors, f"missing anchor: {document}: {target}"
    check_aliases()
    print(f"PASS: {len(EXPECTED)} canonical skills, two relative discovery links, {len(documents)} Markdown files")


if __name__ == "__main__":
    check()
