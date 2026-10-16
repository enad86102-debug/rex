import copy
import json
import unittest

from validate_scene_contract import MANIFEST, validate


class SceneContractTest(unittest.TestCase):
    def setUp(self):
        self.data = json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_current_contract(self):
        validate(self.data)

    def test_rejects_missing_seat_or_mislabeled_approval(self):
        broken = copy.deepcopy(self.data)
        del broken["seats"]["WEST"]
        with self.assertRaises(ValueError):
            validate(broken)
        broken = copy.deepcopy(self.data)
        broken["themes"][0]["release_approved"] = True
        with self.assertRaises(ValueError):
            validate(broken)

    def test_rejects_baked_cards_and_unreviewed_models(self):
        broken = copy.deepcopy(self.data)
        broken["table"]["dynamic_content_excluded_from_textures"].remove("cards")
        with self.assertRaises(ValueError):
            validate(broken)
        broken = copy.deepcopy(self.data)
        broken["environments"][0]["model"] = "screenshot.glb"
        with self.assertRaises(ValueError):
            validate(broken)


if __name__ == "__main__":
    unittest.main()
