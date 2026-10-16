import json
import unittest
from pathlib import Path


PROFILE = (Path(__file__).resolve().parents[1] / "rules" / "trix_complex" /
           "profile-0.9.0-draft.json")


class TrixDraftProfileTest(unittest.TestCase):
    def test_draft_profile_keeps_release_choices_unapproved(self):
        data = json.loads(PROFILE.read_text(encoding="utf-8"))
        self.assertEqual(data["game_id"], "trix_complex")
        self.assertEqual(data["rules_version"], "REX-GAME-TRIX-COMPLEX/0.9.0-draft")
        self.assertEqual(data["contract_status"], "PROPOSED")
        self.assertIsNone(data["human_approval_reference"])
        self.assertFalse(data["commercial_match_activation"])
        self.assertEqual(data["players"], 4)
        self.assertEqual(data["kingdom_count"], 4)
        self.assertEqual(set(data["contracts_per_kingdom"]), {"complex", "trix"})
        self.assertEqual(sum(data["trix_placement_scores"]), 500)
        self.assertEqual(
            13 * data["complex_penalties"]["trick"] +
            13 * data["complex_penalties"]["diamond"] +
            4 * data["complex_penalties"]["queen"] +
            data["complex_penalties"]["king_of_hearts"], -500)
        for unresolved in ("seat_order", "opening_leader_policy", "doubling_policy",
                           "redeal_policy", "timeout_policy", "resignation_policy",
                           "tie_policy", "complex_hearts_lead_policy",
                           "complex_penalty_discard_policy"):
            self.assertIsNone(data[unresolved], unresolved)


if __name__ == "__main__":
    unittest.main()
