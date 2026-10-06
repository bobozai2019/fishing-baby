"""Generate the runtime CJK font subset used by the game."""

from __future__ import annotations

from argparse import ArgumentParser
from pathlib import Path
import os

from fontTools import subset


SOURCE_FONT = Path("resources/fonts/NotoSansCJKsc-Regular.otf")
OUTPUT_FONT = Path("resources/fonts/NotoSansCJKsc-Subset.otf")
TEXT_FILES = (
    Path("project.godot"),
    Path("scenes"),
    Path("scripts"),
    Path("resources/game_data"),
    Path("resources/ui"),
)
TEXT_SUFFIXES = {".cfg", ".gd", ".godot", ".json", ".tres", ".tscn"}


def collect_characters(project_root: Path) -> set[int]:
    codepoints = set(range(0x20, 0x7F))
    codepoints.add(0x00A0)

    for entry in TEXT_FILES:
        path = project_root / entry
        candidates = [path] if path.is_file() else path.rglob("*")
        for candidate in candidates:
            if not candidate.is_file() or candidate.suffix.lower() not in TEXT_SUFFIXES:
                continue
            text = candidate.read_text(encoding="utf-8-sig")
            codepoints.update(ord(character) for character in text if character.isprintable())

    return codepoints


def build_subset(project_root: Path) -> tuple[int, int, int]:
    source_path = project_root / SOURCE_FONT
    output_path = project_root / OUTPUT_FONT
    temporary_path = output_path.with_suffix(".tmp.otf")

    if not source_path.is_file():
        raise FileNotFoundError(f"Source font not found: {source_path}")

    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = [0, 1, 2, 3, 4, 5, 6]
    options.name_legacy = True
    options.notdef_glyph = True
    options.notdef_outline = True
    options.recommended_glyphs = True
    options.glyph_names = True

    font = subset.load_font(str(source_path), options)
    requested = collect_characters(project_root)
    available = set().union(*(table.cmap.keys() for table in font["cmap"].tables))
    included = requested & available
    missing = requested - available

    subsetter = subset.Subsetter(options=options)
    subsetter.populate(unicodes=included)
    subsetter.subset(font)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    subset.save_font(font, str(temporary_path), options)
    os.replace(temporary_path, output_path)

    return len(included), len(missing), output_path.stat().st_size


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument("--project-root", type=Path, default=Path.cwd())
    args = parser.parse_args()

    project_root = args.project_root.resolve()
    included, missing, size = build_subset(project_root)
    print(
        f"[font] Generated {OUTPUT_FONT.as_posix()}: "
        f"{included} characters, {size / 1024:.1f} KiB"
    )
    if missing:
        print(f"[font] Ignored {missing} characters not present in the source font.")


if __name__ == "__main__":
    main()
