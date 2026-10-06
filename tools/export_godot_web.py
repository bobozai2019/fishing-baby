"""Export the game from an isolated staging project without editor-only addons."""

from __future__ import annotations

import re
import shutil
import subprocess
import argparse
import time
from pathlib import Path


RUNTIME_DIRECTORIES = (".godot", "resources", "scenes", "scripts")
RUNTIME_FILES = ("icon.svg", "icon.svg.import")


def _remove_staging(staging: Path) -> None:
    for attempt in range(5):
        try:
            shutil.rmtree(staging)
            return
        except PermissionError:
            if attempt == 4:
                raise
            time.sleep(0.2 * (attempt + 1))


def _sanitize_project(text: str) -> str:
    text = re.sub(r"\n\[autoload\]\n.*?(?=\n\[|\Z)", "\n", text, flags=re.DOTALL)
    text = re.sub(r"\n\[editor_plugins\]\n.*?(?=\n\[|\Z)", "\n", text, flags=re.DOTALL)
    return text


def export_web(
    *, project_root: Path, godot: Path, preset: str, output: Path, template: Path
) -> None:
    project_root = project_root.resolve()
    output = output.resolve()
    template = template.resolve()
    tmp_root = (project_root / "tmp" / "web_export_staging").resolve()
    staging = tmp_root / "project"
    tmp_root.mkdir(parents=True, exist_ok=True)
    if staging.parent != tmp_root:
        raise RuntimeError(f"Unsafe staging path: {staging}")
    if staging.exists():
        _remove_staging(staging)

    try:
        staging.mkdir()
        for directory in RUNTIME_DIRECTORIES:
            source = project_root / directory
            if source.exists():
                shutil.copytree(source, staging / directory)
        for file_name in RUNTIME_FILES:
            source = project_root / file_name
            if source.exists():
                shutil.copy2(source, staging / file_name)

        project_text = (project_root / "project.godot").read_text(encoding="utf-8")
        (staging / "project.godot").write_text(
            _sanitize_project(project_text), encoding="utf-8"
        )
        presets = (project_root / "export_presets.cfg").read_text(encoding="utf-8")
        presets = presets.replace(
            "res://tools/web_templates/godot-4.7.1-2d-release.zip",
            template.as_posix(),
        )
        (staging / "export_presets.cfg").write_text(presets, encoding="utf-8")

        output.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(
            [
                str(godot),
                "--headless",
                "--path",
                str(staging),
                "--export-release",
                preset,
                str(output),
            ],
            check=True,
        )
    finally:
        if staging.exists():
            _remove_staging(staging)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path("."))
    parser.add_argument("--godot", type=Path, required=True)
    parser.add_argument("--preset", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--template", type=Path, required=True)
    args = parser.parse_args()
    export_web(
        project_root=args.project_root,
        godot=args.godot,
        preset=args.preset,
        output=args.output,
        template=args.template,
    )


if __name__ == "__main__":
    main()
