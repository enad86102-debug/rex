import json
from pathlib import Path
import struct
import tempfile
import unittest

from inspect_glb import inspect


class IntakeTest(unittest.TestCase):
    def test_truncated_and_forged_headers_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "bad.glb"
            for data in (b"", b"not gltf" * 5, struct.pack("<4sII", b"glTF", 2, 999) + b"12345678"):
                path.write_bytes(data)
                with self.assertRaises(ValueError):
                    inspect(path)

    def test_structural_pass_never_grants_production_approval(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "human_GUIDE_ONLY.glb"
            payload = json.dumps({"asset": {"version": "2.0"}}).encode()
            payload += b" " * (-len(payload) % 4)
            path.write_bytes(struct.pack("<4sIII4s", b"glTF", 2, 20 + len(payload), len(payload), b"JSON") + payload)
            report = inspect(path)
            self.assertFalse(report["release_approved"])
            self.assertTrue(report["guide_only"])
            self.assertEqual(report["skins"], 0)
            self.assertFalse(report["all_primitives_have_uv"])


if __name__ == "__main__":
    unittest.main()
