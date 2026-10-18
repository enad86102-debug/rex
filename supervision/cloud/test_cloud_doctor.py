#!/usr/bin/env python3
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

PATH = Path(__file__).with_name("cloud_doctor.py")
spec = importlib.util.spec_from_file_location("cloud_doctor", PATH)
assert spec and spec.loader
doctor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(doctor)


class DoctorTests(unittest.TestCase):
    def test_rejects_unknown_profile(self):
        with self.assertRaises(ValueError):
            doctor.inspect(Path("."), "release-root")

    @patch.object(doctor.shutil, "which", return_value=None)
    def test_missing_tools_is_reported_and_not_passed(self, _which):
        with tempfile.TemporaryDirectory() as tmp:
            report = doctor.inspect(Path(tmp), "core")
            self.assertEqual(report["verdict"], "MISSING_PREREQUISITES")
            self.assertIn("go", report["required_missing"])
            self.assertFalse(report["secrets_inspected"])
            self.assertFalse(report["physical_android_device_verified"])

    @patch.object(doctor, "tool_status")
    def test_android_sdk_36_is_required_for_android_ready(self, fake):
        fake.side_effect = lambda name: {"present": True, "version": "go1.27.2" if name == "go" else "3.35.7" if name == "flutter" else "v"}
        with tempfile.TemporaryDirectory() as tmp:
            with patch.dict(doctor.os.environ, {"ANDROID_HOME": str(Path(tmp) / "missing"), "ANDROID_SDK_ROOT": str(Path(tmp) / "missing")}):
                report = doctor.inspect(Path(tmp), "android")
            self.assertEqual(report["verdict"], "MISSING_PREREQUISITES")
            self.assertFalse(report["android_sdk_36_present"])

    @patch.object(doctor, "tool_status")
    def test_core_can_report_tooling_ready_not_game_ready(self, fake):
        fake.side_effect = lambda name: {"present": True, "version": "go1.27.2" if name == "go" else "v"}
        with tempfile.TemporaryDirectory() as tmp:
            report = doctor.inspect(Path(tmp), "core")
            self.assertEqual(report["verdict"], "READY_TOOLING_BASELINE")
            self.assertIn("Environment capability inventory", report["meaning"])
            self.assertFalse(report["network_access_tested"])


if __name__ == "__main__":
    unittest.main()
