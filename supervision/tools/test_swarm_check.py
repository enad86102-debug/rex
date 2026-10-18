#!/usr/bin/env python3
"""Small isolated negative and positive unit tests for the policy validator."""
from __future__ import annotations
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).with_name("swarm_check.py")
spec = importlib.util.spec_from_file_location("swarm_check", MODULE)
assert spec and spec.loader
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)


def fixture(root: Path) -> None:
    for path in mod.ROOT_DOCS:
        p = root / path
        p.parent.mkdir(parents=True, exist_ok=True)
        if p.suffix == ".json":
            continue
        p.write_text("# Valid review document\n", encoding="utf-8")
    skill = root / ".agents/skills/rex-qa/SKILL.md"
    skill.parent.mkdir(parents=True, exist_ok=True)
    skill.write_text(
        "---\nname: rex-qa\ndescription: A specific focused skill for reviewing real production quality.\n"
        "---\n\n# Test\n1. Read code.\n2. Inspect tests.\n3. Report results.\n",
        encoding="utf-8",
    )
    (root / "supervision/SWARM_TASK_BOARD.json").write_text(
        json.dumps({"schema": "rex.swarm.taskboard.v1", "wip_limit": 3,
                    "tasks": [{"id": "S-1", "class": "D0", "status": "ready_for_review",
                               "owner": "rex-qa", "exit": "test passes"}]}),
        encoding="utf-8",
    )
    (root / "supervision/SWARM_AGENT_ROUTING.json").write_text(
        json.dumps({"reviewers": [{"id": "SW-01", "skills": ["rex-qa"]}]}),
        encoding="utf-8",
    )


class TestSwarmCheck(unittest.TestCase):
    def test_valid_minimal_fixture(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root)
            errors, stats = mod.validate(root)
            self.assertEqual(errors, [])
            self.assertEqual(stats["skills"], 1)
            self.assertEqual(stats["reviewers"], 1)

    def test_unknown_task_owner_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root)
            path = root / "supervision/SWARM_TASK_BOARD.json"
            data = json.loads(path.read_text(encoding="utf-8"))
            data["tasks"][0]["owner"] = "not-a-skill"
            path.write_text(json.dumps(data), encoding="utf-8")
            errors, _ = mod.validate(root)
            self.assertTrue(any("Unknown skill owner" in e for e in errors))

    def test_malformed_manifest_is_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root)
            path = root / ".agents/skills/rex-qa/SKILL.md"
            path.write_text("# Missing metadata", encoding="utf-8")
            errors, _ = mod.validate(root)
            self.assertTrue(any("frontmatter" in e for e in errors))

    def test_duplicate_task_ids_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            fixture(root)
            path = root / "supervision/SWARM_TASK_BOARD.json"
            data = json.loads(path.read_text(encoding="utf-8"))
            data["tasks"].append(dict(data["tasks"][0]))
            path.write_text(json.dumps(data), encoding="utf-8")
            errors, _ = mod.validate(root)
            self.assertTrue(any("Duplicate task" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
