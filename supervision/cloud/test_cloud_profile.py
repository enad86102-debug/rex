#!/usr/bin/env python3
"""Offline validity and privilege-regression checks for Cloud setup blueprints."""
import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent


class CloudPolicyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.profile = json.loads((ROOT / "REX_CLOUD_PROFILE.json").read_text(encoding="utf-8"))
        cls.access = json.loads((ROOT / "REX_ACCESS_MATRIX.json").read_text(encoding="utf-8"))

    def test_pinned_versions_match_production_ci(self):
        basis = self.profile["basis"]
        self.assertEqual(basis["go_version"], "1.27.2")
        self.assertEqual(basis["flutter_version"], "3.35.7")
        self.assertEqual(basis["jdk_major"], 17)
        self.assertEqual(basis["android_compile_sdk"], 36)

    def test_external_network_domains_are_host_only(self):
        hosts = self.profile["network"]["setup_domains"]
        self.assertEqual(len(hosts), len(set(hosts)))
        self.assertTrue(hosts)
        for host in hosts:
            with self.subTest(host=host):
                self.assertNotIn("://", host)
                self.assertNotIn("/", host)
                self.assertNotIn("*", host)
                self.assertNotIn(":", host)

    def test_no_development_grant_contains_destructive_access(self):
        risky = {"git-force-push", "repo-administration", "prod-deploy",
                 "play-publish", "release-signing", "secrets-administration"}
        for profile in self.access["profiles"]:
            with self.subTest(profile=profile["id"]):
                self.assertTrue(risky.isdisjoint(profile["permissions"]))

    def test_no_embedded_credentials_in_cloud_config(self):
        for file in (ROOT / "REX_ACCESS_MATRIX.json", ROOT / "REX_CLOUD_PROFILE.json"):
            content = file.read_text(encoding="utf-8")
            self.assertNotIn("-----BEGIN PRIVATE KEY-----", content)
            self.assertNotIn("ghp_", content)
            self.assertNotIn("github_pat_", content)
            self.assertNotIn("sk-proj-", content)

    def test_blueprints_do_not_pretend_to_be_live_platform_configuration(self):
        self.assertIn("not-platform-native", self.profile["profile_type"])
        self.assertTrue(self.access["principle"].startswith("least privilege"))


if __name__ == "__main__":
    unittest.main()
