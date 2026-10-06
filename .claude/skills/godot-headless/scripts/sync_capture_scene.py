#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync the bundled capture_scene.gd helper into a Godot project."
    )
    parser.add_argument(
        "--project-root",
        required=True,
        help="Path to the Godot project root.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Overwrite the destination file if it already exists.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    script_dir = Path(__file__).resolve().parent
    skill_dir = script_dir.parent
    source = skill_dir / "assets" / "godot" / "scripts" / "tools" / "capture_scene.gd"
    project_root = Path(args.project_root).resolve()
    destination = project_root / "scripts" / "tools" / "capture_scene.gd"

    if not source.exists():
        print(f"[ERROR] Missing bundled source: {source}")
        return 1

    if not project_root.exists():
        print(f"[ERROR] Project root does not exist: {project_root}")
        return 1

    if destination.exists() and not args.force:
        print(f"[SKIP] Destination already exists: {destination}")
        print("Use --force to overwrite.")
        return 0

    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    print(f"[OK] Synced {source} -> {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
