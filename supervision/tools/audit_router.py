#!/usr/bin/env python3
"""Route 1000 REX audit assignments to a bounded review packet.

Offline registry selection only: DOES NOT perform audits, create agents,
change production files, access credentials, or establish approvals.
"""
from __future__ import annotations
import argparse
import json
import sys
from pathlib import Path

DEFAULT_PATH = Path(__file__).resolve().parents[1] / "SWARM_AUDITS_1000.json"
CATEGORIES = {"game", "security", "persistence", "mobile", "visual"}
SEVERITY = {"CRITICAL": 3, "HIGH": 2, "NORMAL": 1}


def load_catalog(path: Path) -> list[dict]:
    data = json.loads(path.read_text(encoding="utf-8"))
    items = data.get("audits")
    if data.get("schema") != "rex.audit.assignments.v1" or not isinstance(items, list):
        raise ValueError("Unsupported audit registry schema")
    if data.get("count") != 1000 or len(items) != 1000:
        raise ValueError(f"Expected 1000 audit assignments, received {len(items)}")
    ids = [x["id"] for x in items]
    if len(set(ids)) != 1000 or ids != [f"REX-AUD-{i:04d}" for i in range(1, 1001)]:
        raise ValueError("IDs must be unique and sequential REX-AUD-0001..1000")
    if len({x["domain"] for x in items}) != 25:
        raise ValueError("Must cover 25 distinct target domains")
    for x in items:
        if x.get("category") not in CATEGORIES or x.get("severity") not in SEVERITY:
            raise ValueError(f"Invalid category or severity: {x.get('id')}")
        if x.get("status") != "NOT_RUN":
            raise ValueError(f"Registry is configuration, not executed evidence: {x['id']}")
        if (not x.get("audit") or not x.get("owner_skill")
                or not x.get("required_evidence") or not x.get("trigger_paths")):
            raise ValueError(f"Missing operational audit metadata: {x['id']}")
        if any(not isinstance(path, str) or not path for path in x["trigger_paths"]):
            raise ValueError(f"Invalid path rule: {x['id']}")
    return items


def _normalize(p: str) -> str:
    return p.replace("\\", "/").removeprefix("./").strip()


def route(items: list[dict], changed_files: list[str], limit: int = 12) -> list[dict]:
    if limit < 1 or limit > 32:
        raise ValueError("Review packet size must be between 1 and 32")
    paths = sorted({_normalize(p) for p in changed_files if _normalize(p)})
    if not paths:
        return []
    candidates = []
    for item in items:
        longest = max((len(prefix) for file in paths for prefix in item["trigger_paths"]
                       if file.startswith(prefix)), default=0)
        if longest == 0:
            continue
        # Prefer precise component path matches; severity breaks ties.
        candidates.append((longest, SEVERITY[item["severity"]], item["id"], item))
    candidates.sort(key=lambda entry: (-entry[0], -entry[1], entry[2]))
    # Spread available review attention across applicable components.
    selected = []
    counts: dict[str, int] = {}
    while candidates and len(selected) < limit:
        choice = min(candidates, key=lambda e: (counts.get(e[3]["domain"], 0), -e[0], -e[1], e[2]))
        candidates.remove(choice)
        selected.append(choice[3])
        counts[choice[3]["domain"]] = counts.get(choice[3]["domain"], 0) + 1
    return selected


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--catalog", type=Path, default=DEFAULT_PATH)
    parser.add_argument("--validate", action="store_true")
    parser.add_argument("--paths", nargs="*", default=[])
    parser.add_argument("--limit", type=int, default=12)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    try:
        items = load_catalog(args.catalog)
        if args.validate:
            result = {"status": "PASS", "registered": len(items), "executed": 0, "meaning": "registry metadata validated; no audit has run"}
            print(json.dumps(result, indent=2) if args.json else "PASS: 1000 review assignments registered; 0 executed")
            return 0
        chosen = route(items, args.paths, args.limit)
    except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
        print(f"REX AUDIT ROUTER ERROR: {exc}", file=sys.stderr)
        return 1
    if args.json:
        print(json.dumps({"selected": chosen, "selected_count": len(chosen), "executed": 0, "state": "ASSIGNED_NOT_RUN"}, ensure_ascii=False, indent=2))
    else:
        print(f"REX: selected {len(chosen)} audit assignments. Actual executions: 0")
        for audit in chosen:
            print(f"{audit['id']} [{audit['severity']}] {audit['domain']}: {audit['audit']}")
        if not chosen:
            print("No matching code paths; review changes manually rather than claiming PASS.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
