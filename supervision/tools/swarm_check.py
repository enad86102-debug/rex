#!/usr/bin/env python3
"""Offline validator of REX repository-local skills, agent routing and task board.

This checks the supervision configuration only. It does NOT test game logic,
activate subagents, query GitHub, assess release readiness, or run Flutter/Go.
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT_DOCS = (
    "supervision/REX_SWARM_CHARTER.md",
    "supervision/REX_SWARM_WORKBENCH.md",
    "supervision/REX_SWARM_TOOL_REGISTRY.md",
    "supervision/REX_SWARM_PRODUCTION_MISSION.md",
    "supervision/REX_SWARM_REPORT_TEMPLATE.md",
    "supervision/SWARM_TASK_BOARD.json",
    "supervision/SWARM_AGENT_ROUTING.json",
)
CLASSES = {"D0", "D1", "D2", "D3"}
STATUSES = {
    "blocked_human", "blocked_dependency", "needs_technical_review",
    "needs_art_and_technical_review", "ready_for_safe_code", "ready_for_review",
    "in_progress", "tested", "reviewed", "completed",
}
NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


def validate(root: Path) -> tuple[list[str], dict]:
    errors: list[str] = []
    stats = {"skills": 0, "tasks": 0, "reviewers": 0, "checked_documents": len(ROOT_DOCS)}
    for item in ROOT_DOCS:
        p = root / item
        if not p.is_file() or not p.read_text(encoding="utf-8").strip():
            errors.append(f"Missing or empty required document: {item}")

    skills_dir = root / ".agents" / "skills"
    manifests = sorted(skills_dir.glob("*/SKILL.md"))
    stats["skills"] = len(manifests)
    if not manifests:
        errors.append("No repo-local SKILL.md manifests discovered")
    names: set[str] = set()
    for p in manifests:
        text = p.read_text(encoding="utf-8")
        relative = str(p.relative_to(root))
        if not text.startswith("---\n") or "\n---\n" not in text[4:]:
            errors.append(f"Malformed YAML-style frontmatter: {relative}")
            continue
        metadata, rest = text[4:].split("\n---\n", 1)
        match_name = re.search(r"^name:\s*([^\n]+)$", metadata, re.M)
        match_desc = re.search(r"^description:\s*(.+)$", metadata, re.M)
        if not match_name or not match_desc:
            errors.append(f"Name/description missing: {relative}")
            continue
        name = match_name.group(1).strip().strip('"')
        description = match_desc.group(1).strip().strip('"')
        if not NAME_RE.fullmatch(name) or name != p.parent.name:
            errors.append(f"Invalid skill name or folder mismatch: {relative}")
        if name in names:
            errors.append(f"Duplicate skill name: {name}")
        names.add(name)
        if len(description) < 25:
            errors.append(f"Description too short: {relative}")
        if len(re.findall(r"^\d+\. ", rest, re.M)) < 3:
            errors.append(f"Skill missing actionable numbered procedure: {relative}")
        if len(text) > 25000:
            errors.append(f"Skill instructions too long for focused discovery: {relative}")

    board_path = root / "supervision" / "SWARM_TASK_BOARD.json"
    if board_path.is_file():
        try:
            board = json.loads(board_path.read_text(encoding="utf-8"))
            tasks = board.get("tasks")
            if board.get("schema") != "rex.swarm.taskboard.v1" or not isinstance(tasks, list):
                errors.append("Task board schema or tasks array invalid")
            else:
                stats["tasks"] = len(tasks)
                ids: set[str] = set()
                for task in tasks:
                    ident = task.get("id", "")
                    if ident in ids:
                        errors.append(f"Duplicate task id: {ident}")
                    ids.add(ident)
                    if task.get("class") not in CLASSES:
                        errors.append(f"Invalid approval class: {ident}")
                    if task.get("status") not in STATUSES:
                        errors.append(f"Unknown status: {ident}")
                    if task.get("owner") not in names:
                        errors.append(f"Unknown skill owner: {ident} -> {task.get('owner')}")
                    if not task.get("exit"):
                        errors.append(f"Missing measurable exit condition: {ident}")
                if len(tasks) == 0:
                    errors.append("Task queue must not be empty")
            wip = board.get("wip_limit")
            if not isinstance(wip, int) or not 1 <= wip <= 3:
                errors.append("wip_limit must be integer 1..3")
        except (json.JSONDecodeError, UnicodeError) as exc:
            errors.append(f"Invalid SWARM_TASK_BOARD.json: {exc}")

    routing_path = root / "supervision" / "SWARM_AGENT_ROUTING.json"
    if routing_path.is_file():
        try:
            routing = json.loads(routing_path.read_text(encoding="utf-8"))
            reviewers = routing.get("reviewers")
            if not isinstance(reviewers, list) or not reviewers:
                errors.append("Agent routing must have a nonempty reviewers array")
            else:
                stats["reviewers"] = len(reviewers)
                ids: set[str] = set()
                for reviewer in reviewers:
                    ident = reviewer.get("id", "")
                    if ident in ids:
                        errors.append(f"Duplicate reviewer: {ident}")
                    ids.add(ident)
                    chosen = reviewer.get("skills")
                    if not isinstance(chosen, list) or not chosen:
                        errors.append(f"No skill mapped to reviewer: {ident}")
                        continue
                    for skill in chosen:
                        if skill not in names:
                            errors.append(f"Unknown reviewer skill: {ident} -> {skill}")
        except (json.JSONDecodeError, UnicodeError) as exc:
            errors.append(f"Invalid SWARM_AGENT_ROUTING.json: {exc}")
    return errors, stats


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    ap.add_argument("--json", action="store_true", help="Print structured result")
    args = ap.parse_args()
    errors, stats = validate(args.root.resolve())
    report = {"result": "PASS" if not errors else "FAIL", "scope": "supervision_metadata_only", "counts": stats, "errors": errors}
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"REX SWARM CONFIG {report['result']}: {stats['skills']} skills, {stats['tasks']} tasks, {stats['reviewers']} reviewer mappings")
        for e in errors:
            print("ERROR:", e)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
