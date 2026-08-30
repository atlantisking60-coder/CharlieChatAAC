#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(r"C:\Users\Craig\Downloads\Charlie Chat")
BOARDS_DIR = ROOT / "lib" / "data" / "boards"

def load(p):
    with open(p, "r", encoding="utf-8-sig") as f:
        return json.load(f)

issues = []
ids = {}
for p in BOARDS_DIR.rglob("*.json"):
    try:
        d = load(p)
    except Exception as e:
        issues.append(f"{p}: JSON error {e}")
        continue
    ids[d.get("id")] = d.get("name")

for p in BOARDS_DIR.rglob("*.json"):
    try:
        d = load(p)
    except Exception:
        continue
    rel = p.relative_to(BOARDS_DIR)
    parts = rel.parts
    area = parts[0]
    depth = len(parts) - 2
    bid = d.get("id")
    pid = d.get("parentBoardId")
    if d.get("area") != area:
        issues.append(f"{rel}: area mismatch ({d.get('area')} != {area})")
    if d.get("tier") != depth:
        issues.append(f"{rel}: tier {d.get('tier')} != depth {depth}")
    exp_sub = depth >= 2
    if bool(d.get("isSubBoard")) != exp_sub:
        issues.append(f"{rel}: isSubBoard {d.get('isSubBoard')} != expected {exp_sub}")
    exp_ter = depth >= 3
    if bool(d.get("isTertiaryBoard")) != exp_ter:
        issues.append(f"{rel}: isTertiaryBoard {d.get('isTertiaryBoard')} != expected {exp_ter}")
    exp_quad = depth >= 4
    if bool(d.get("isQuaternaryBoard")) != exp_quad:
        issues.append(f"{rel}: isQuaternaryBoard {d.get('isQuaternaryBoard')} != expected {exp_quad}")
    exp_quin = depth >= 5
    if bool(d.get("isQuinaryBoard")) != exp_quin:
        issues.append(f"{rel}: isQuinaryBoard {d.get('isQuinaryBoard')} != expected {exp_quin}")
    if depth <= 1 and pid:
        issues.append(f"{rel}: top-level but has parentBoardId {pid}")
    if depth > 1 and not pid:
        issues.append(f"{rel}: sub-board missing parentBoardId")
    if pid and pid == bid:
        issues.append(f"{rel}: self parentBoardId {pid}")
    if pid and pid not in ids:
        issues.append(f"{rel}: parentBoardId {pid} not found")

print(f"Total files: {len(ids)}")
print(f"Issues: {len(issues)}")
for i in issues[:50]:
    print(i)

out = ROOT / "audit_issues.txt"
with open(out, "w", encoding="utf-8") as f:
    f.write(f"Total files: {len(ids)}\nIssues: {len(issues)}\n\n")
    for i in issues:
        f.write(i + "\n")
print(f"\nFull report: {out}")
