#!/usr/bin/env python3
"""Offline Codex Cloud toolchain audit. Never prints secret values or calls the internet.
No repository mutations, tool installs, GitHub actions, or production assertions.
"""
from __future__ import annotations
import argparse
import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path

REQUIRED_CORE = ("git", "go", "python3")
REQUIRED_ANDROID = ("flutter", "dart", "java", "sdkmanager", "adb")
ART_OPTIONAL = ("blender", "node", "npm")
VERSIONS = {
    "go": ("go", "version"),
    "flutter": ("flutter", "--version", "--machine"),
    "dart": ("dart", "--version"),
    "java": ("java", "-version"),
    "git": ("git", "--version"),
    "python3": ("python3", "--version"),
    "adb": ("adb", "version"),
    "blender": ("blender", "-b", "--factory-startup", "--version"),
    "node": ("node", "--version"),
    "npm": ("npm", "--version"),
}
PIN_GO = "1.27.2"
PIN_FLUTTER = "3.35.7"


def tool_status(name: str) -> dict:
    path = shutil.which(name)
    if not path:
        return {"present": False}
    info = {"present": True, "path": path}
    if name in VERSIONS:
        try:
            cp = subprocess.run(VERSIONS[name], capture_output=True, text=True,
                                check=False, timeout=12)
            if name == "flutter" and cp.stdout.lstrip().startswith("{"):
                meta = json.loads(cp.stdout)
                version = meta.get("frameworkVersion")
                info["version"] = version if isinstance(version, str) else "unknown"
            else:
                line = (cp.stdout or cp.stderr).splitlines()
                info["version"] = line[0][:180] if line else "unknown"
            info["version_command_ok"] = (cp.returncode == 0)
        except (OSError, ValueError, subprocess.TimeoutExpired):
            info["version"] = "unavailable"
            info["version_command_ok"] = False
    return info


def inspect(root: Path, profile: str) -> dict:
    if profile not in ("core", "android", "art"):
        raise ValueError("profile must be core, android, or art")
    mandatory = list(REQUIRED_CORE)
    if profile in ("android", "art"):
        mandatory += list(REQUIRED_ANDROID)
    tools = sorted(set(mandatory) | set(ART_OPTIONAL) | {"curl"})
    result = {name: tool_status(name) for name in tools}
    missing = [name for name in mandatory if not result[name]["present"]]
    warnings = []
    if result["go"]["present"] and PIN_GO not in result["go"].get("version", ""):
        warnings.append(f"Go differs from verified production CI {PIN_GO}; compare compatibility.")
    if result.get("flutter", {}).get("present") and result["flutter"].get("version") != PIN_FLUTTER:
        warnings.append(f"Flutter differs from verified production CI {PIN_FLUTTER}; do not copy legacy 3.47.3 blindly.")
    prod = (root / "production/server/go.mod").is_file() and (root / "production/mobile/pubspec.yaml").is_file()
    skill_dir = root / ".agents/skills"
    count = len(list(skill_dir.glob("*/SKILL.md"))) if skill_dir.is_dir() else 0
    if not prod:
        warnings.append("production/server + production/mobile not found on checked-out branch; this may be a supervision-only checkout.")
    if (root / "supervision").is_dir() and count == 0:
        warnings.append("Swarm skill manifests not present in current workspace.")
    sdk_root = os.environ.get("ANDROID_SDK_ROOT") or os.environ.get("ANDROID_HOME")
    sdk_36 = bool(sdk_root and (Path(sdk_root) / "platforms/android-36").is_dir())
    if profile in ("android", "art") and not sdk_36:
        warnings.append("Android SDK platform 36 unavailable/unverified; configure Android SDK without automatic license acceptance.")
    if profile == "art" and not result["blender"]["present"]:
        warnings.append("Blender unavailable; source modeling/rigging cannot be asserted.")
    if result.get("go", {}).get("present") and not prod:
        warnings.append("Go available but REX production source not available for tests in this checkout.")
    verdict = "READY_TOOLING_BASELINE" if not missing and (profile == "core" or sdk_36) else "MISSING_PREREQUISITES"
    return {
        "schema": "rex.cloud.doctor.v1", "profile": profile,
        "verdict": verdict,
        "meaning": "Environment capability inventory ONLY; not real multiplayer or release readiness.",
        "runtime": {"system": platform.system(), "arch": platform.machine()},
        "tools": result, "required_missing": missing,
        "production_source_present": prod, "repo_skill_count": count,
        "android_sdk_36_present": sdk_36, "warnings": warnings,
        "secrets_inspected": False, "network_access_tested": False,
        "physical_android_device_verified": False
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    ap.add_argument("--profile", choices=("core", "android", "art"), default="core")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--strict", action="store_true")
    args = ap.parse_args()
    report = inspect(args.root.resolve(), args.profile)
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"REX Cloud {args.profile}: {report['verdict']}")
        for name, value in report["tools"].items():
            print(f"  {name}: " + (value.get("version") or "present" if value["present"] else "MISSING"))
        for warning in report["warnings"]:
            print("  WARN: " + warning)
    return (1 if report["verdict"] != "READY_TOOLING_BASELINE" else 0) if args.strict else 0


if __name__ == "__main__":
    raise SystemExit(main())
