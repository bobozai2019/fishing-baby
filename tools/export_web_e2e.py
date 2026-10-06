"""Create the generated E2E Web directory and export the current Godot project."""

from pathlib import Path
from os import environ
from export_godot_web import export_web


def main() -> None:
    output = Path("tmp/build/web_e2e/index.html")
    output.parent.mkdir(parents=True, exist_ok=True)
    godot = environ.get(
        "GODOT_EXE",
        r"D:\godot\Godot_v4.7.1-stable\Godot_v4.7.1-stable_win64_console.exe",
    )
    export_web(
        project_root=Path("."),
        godot=Path(godot),
        preset="Web E2E",
        output=output,
        template=Path("tools/web_templates/godot-4.7.1-2d-release.zip"),
    )


if __name__ == "__main__":
    main()
