#!/usr/bin/env python3
from __future__ import annotations

import argparse
import subprocess
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run the Godot capture_scene.gd helper using a real display driver."
    )
    parser.add_argument("--project-root", required=True, help="Path to the Godot project root.")
    parser.add_argument("--scene", required=True, help="res:// scene path to capture.")
    parser.add_argument("--output", required=True, help="res:// or absolute path for the PNG.")
    parser.add_argument("--width", type=int, default=1280, help="Output width.")
    parser.add_argument("--height", type=int, default=720, help="Output height.")
    parser.add_argument("--godot", default="godot", help="Godot executable.")
    parser.add_argument(
        "--offscreen-position",
        default="32000,32000",
        help="Window position used to keep the capture window off-screen when possible.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    project_root = Path(args.project_root).resolve()
    command = [
        args.godot,
        "--path",
        str(project_root),
        "--quiet",
        "--no-header",
        "--single-window",
        "--windowed",
        "--position",
        args.offscreen_position,
        "--resolution",
        f"{args.width}x{args.height}",
        "-s",
        "res://scripts/tools/capture_scene.gd",
        "--",
        args.scene,
        args.output,
        str(args.width),
        str(args.height),
    ]
    print("[RUN] " + " ".join(command))
    return subprocess.call(command)


if __name__ == "__main__":
    raise SystemExit(main())
