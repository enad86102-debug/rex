#!/usr/bin/env python3
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path

MODULE = Path(__file__).with_name("audit_router.py")
s = importlib.util.spec_from_file_location("audit_router", MODULE)
assert s and s.loader
m = importlib.util.module_from_spec(s)
s.loader.exec_module(m)


class AuditRouterTests(unittest.TestCase):
    def test_committed_registry_is_exactly_one_thousand(self):
        entries = m.load_catalog(m.DEFAULT_PATH)
        self.assertEqual(len(entries), 1000)
        self.assertEqual(len({x["domain"] for x in entries}), 25)

    def test_trix_path_gets_game_assurance(self):
        entries = m.load_catalog(m.DEFAULT_PATH)
        packet = m.route(entries, ["production/server/internal/games/trixcomplex/engine.go"], 10)
        self.assertEqual(len(packet), 10)
        self.assertTrue(any(x["domain"] == "trix_complex" for x in packet))
        self.assertTrue(any(x["category"] == "game" for x in packet))
        self.assertTrue(all(x["status"] == "NOT_RUN" for x in packet))

    def test_private_hand_paths_get_security_lens(self):
        entries = m.load_catalog(m.DEFAULT_PATH)
        packet = m.route(entries, ["production/server/internal/matchcore/deal.go"], 16)
        self.assertTrue(any(x["category"] == "security" for x in packet))

    def test_always_bounded_and_not_executed(self):
        entries = m.load_catalog(m.DEFAULT_PATH)
        packet = m.route(entries, ["production/mobile/lib/main.dart", "production/server/internal/api/api.go"], 12)
        self.assertLessEqual(len(packet), 12)
        self.assertEqual(len({x["id"] for x in packet}), len(packet))

    def test_unrelated_file_has_no_matching_audit(self):
        entries = m.load_catalog(m.DEFAULT_PATH)
        self.assertEqual(m.route(entries, ["supervision/REX_SWARM_CHARTER.md"]), [])

    def test_invalid_limit_is_rejected(self):
        with self.assertRaises(ValueError):
            m.route([], ["production/server/internal/api/api.go"], 1000)

    def test_fake_pass_in_registry_is_rejected(self):
        entries = m.load_catalog(m.DEFAULT_PATH)
        with tempfile.TemporaryDirectory() as tmp:
            file = Path(tmp) / "catalog.json"
            entries[0] = dict(entries[0], status="PASS")
            file.write_text(json.dumps({"schema": "rex.audit.assignments.v1", "count": 1000, "audits": entries}), encoding="utf-8")
            with self.assertRaises(ValueError):
                m.load_catalog(file)


if __name__ == "__main__":
    unittest.main()
