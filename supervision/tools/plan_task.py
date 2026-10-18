#!/usr/bin/env python3
"""Print a task packet from the review queue; no mutation or fake agent spawn."""
from __future__ import annotations
import argparse
import json
from pathlib import Path

def main():
    p=argparse.ArgumentParser()
    p.add_argument("task_id")
    p.add_argument("--root",type=Path,default=Path(__file__).resolve().parents[2])
    args=p.parse_args()
    root=args.root.resolve()
    board=json.loads((root/"supervision/SWARM_TASK_BOARD.json").read_text(encoding="utf-8"))
    routes=json.loads((root/"supervision/SWARM_AGENT_ROUTING.json").read_text(encoding="utf-8"))
    item=next((i for i in board["tasks"] if i["id"]==args.task_id),None)
    if item is None:
        print(f"Unknown task {args.task_id}")
        return 2
    experts=[r["id"]+" "+r["role"] for r in routes["reviewers"] if item["owner"] in r["skills"]]
    print(f"# {item['id']} — {item['title']}")
    print(f"Status: {item['status']} | Approval: {item['class']}")
    print(f"Owner skill: .agents/skills/{item['owner']}/SKILL.md")
    print("Suggested role: "+("; ".join(experts) if experts else "assign explicitly"))
    print(f"Exit test: {item['exit']}")
    print("No agent has been started by this command. Verify production branch and human gates before execution.")
    return 0

if __name__=="__main__":
    raise SystemExit(main())
