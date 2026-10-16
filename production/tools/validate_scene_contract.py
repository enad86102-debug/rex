#!/usr/bin/env python3
"""Validate scene assembly metadata; it cannot approve visual art or rights."""
import json
import math
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "assets" / "scene-contract.json"
SEATS = {"NORTH", "EAST", "SOUTH", "WEST"}
THEMES = {"emerald", "royal_black", "sapphire", "ruby", "ivory", "purple"}
ENVIRONMENTS = {"royal_hall", "wadi_rum", "petra", "aqaba"}
DYNAMIC = {"cards", "player_names", "turn_indicators", "controls", "invitation_codes"}


def _vector(value):
    return (isinstance(value, list) and len(value) == 3 and
            all(isinstance(n, (int, float)) and not isinstance(n, bool) and math.isfinite(n)
                for n in value))


def validate(data: dict) -> None:
    if data.get("version") != 1 or data.get("status") != "candidate_for_art_and_renderer_review":
        raise ValueError("unexpected scene contract version or approval status")
    if data.get("units") != "metres" or data.get("up_axis") != "+Y":
        raise ValueError("inconsistent coordinate system")
    camera = data.get("camera", {})
    if not _vector(camera.get("position")) or not _vector(camera.get("target")):
        raise ValueError("invalid camera")
    table = data.get("table", {})
    if not _vector(table.get("centre")) or not (0.5 < table.get("playing_surface_height", 0) < 1.1):
        raise ValueError("invalid table origin or height")
    if table.get("playing_surface_min_width", 0) < 1 or table.get("playing_surface_min_depth", 0) < 0.7:
        raise ValueError("unreadable card surface")
    if set(table.get("dynamic_content_excluded_from_textures", [])) != DYNAMIC:
        raise ValueError("dynamic content must remain independent")
    seats = data.get("seats", {})
    if set(seats) != SEATS:
        raise ValueError("expected four camera-relative seats")
    for name, item in seats.items():
        if not _vector(item.get("position")) or item.get("inward_yaw_degrees") not in (0, 90, 180, 270):
            raise ValueError("invalid seat anchor: " + name)
    if not (seats["NORTH"]["position"][2] > 0 > seats["SOUTH"]["position"][2] and
            seats["EAST"]["position"][0] > 0 > seats["WEST"]["position"][0]):
        raise ValueError("seat positions contradict local camera")
    for key, required in (("themes", THEMES), ("environments", ENVIRONMENTS)):
        entries = data.get(key, [])
        if not isinstance(entries, list) or len(entries) != len(required) or {x.get("id") for x in entries} != required:
            raise ValueError("missing or duplicate " + key)
        for item in entries:
            if item.get("release_approved") is not False:
                raise ValueError("approval requires independent human review")
            if item.get("model") is not None:
                raise ValueError("unreviewed model cannot enter scene contract")
            if key == "themes" and any(not re.fullmatch(r"#[0-9A-Fa-f]{6}", item.get(color, ""))
                                       for color in ("felt_srgb", "wood_srgb", "metal_srgb")):
                raise ValueError("invalid material colour")


def main() -> None:
    validate(json.loads(MANIFEST.read_text(encoding="utf-8")))
    print("scene assembly contract valid; all production models remain blocked")


if __name__ == "__main__":
    main()
