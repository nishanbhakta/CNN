#!/usr/bin/env python3
"""Render before/after CNN CSV grids as PNG images.

The script reads one or two CSV feature maps, converts their numeric values
into grayscale images, and writes a PNG for each CSV. When two CSVs are given,
it also writes a side-by-side comparison image.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path
from typing import Callable

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError as exc:  # pragma: no cover - dependency failure path
    raise SystemExit(
        "Pillow is required for CSV-to-image rendering. Install it with: pip install pillow"
    ) from exc


PaletteFn = Callable[[int | None], tuple[int, int, int]]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Render a CSV grid as an image and optionally place a second CSV next to it "
            "for before/after CNN comparison."
        )
    )
    parser.add_argument("before_csv", type=Path, help="CSV for the pre-CNN grid")
    parser.add_argument(
        "after_csv",
        type=Path,
        nargs="?",
        help="CSV for the post-CNN grid (optional)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Path for the output PNG",
    )
    parser.add_argument(
        "--cell-size",
        type=int,
        default=16,
        help="Pixel size used for each CSV cell in the output image",
    )
    parser.add_argument(
        "--gap",
        type=int,
        default=24,
        help="Gap in pixels between the before and after panels",
    )
    parser.add_argument(
        "--title-before",
        default="Before CNN",
        help="Title shown above the first CSV panel",
    )
    parser.add_argument(
        "--title-after",
        default="After CNN",
        help="Title shown above the second CSV panel",
    )
    return parser.parse_args()


def read_csv_grid(path: Path) -> list[list[int | None]]:
    if not path.exists():
        raise FileNotFoundError(f"CSV not found: {path}")

    rows: list[list[int | None]] = []
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        for raw_row in reader:
            if not raw_row:
                continue

            row: list[int | None] = []
            for cell in raw_row:
                stripped = cell.strip()
                row.append(None if stripped == "" else int(stripped))
            rows.append(row)

    if not rows:
        raise ValueError(f"CSV contains no data: {path}")

    width = max(len(row) for row in rows)
    for row in rows:
        if len(row) < width:
            row.extend([None] * (width - len(row)))

    return rows


def build_palette(grid: list[list[int | None]]) -> PaletteFn:
    values = [value for row in grid for value in row if value is not None]
    if not values:
        raise ValueError("CSV contains only blank cells")

    minimum = min(values)
    maximum = max(values)

    if 0 <= minimum and maximum <= 255:

        def raw_scale(value: int | None) -> tuple[int, int, int]:
            if value is None:
                return (245, 245, 245)
            return (value, value, value)

        return raw_scale

    if minimum < 0 and maximum > 0:
        bound = max(abs(minimum), abs(maximum))
        if bound == 0:
            bound = 1

        def signed_scale(value: int | None) -> tuple[int, int, int]:
            if value is None:
                return (245, 245, 245)
            normalized = (value + bound) / (2 * bound)
            shade = max(0, min(255, int(round(normalized * 255))))
            return (shade, shade, shade)

        return signed_scale

    if minimum == maximum:
        shade = 128

        def constant_scale(value: int | None) -> tuple[int, int, int]:
            if value is None:
                return (245, 245, 245)
            return (shade, shade, shade)

        return constant_scale

    span = maximum - minimum

    def minmax_scale(value: int | None) -> tuple[int, int, int]:
        if value is None:
            return (245, 245, 245)
        normalized = (value - minimum) / span
        shade = max(0, min(255, int(round(normalized * 255))))
        return (shade, shade, shade)

    return minmax_scale


def render_grid(grid: list[list[int | None]], title: str, cell_size: int) -> Image.Image:
    palette = build_palette(grid)
    rows = len(grid)
    cols = len(grid[0])
    padding = 12
    title_height = 28
    width = padding * 2 + cols * cell_size
    height = padding * 2 + title_height + rows * cell_size

    image = Image.new("RGB", (width, height), color=(255, 255, 255))
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default()

    draw.text((padding, padding), title, fill=(0, 0, 0), font=font)

    top = padding + title_height
    for row_index, row in enumerate(grid):
        for col_index, value in enumerate(row):
            x0 = padding + col_index * cell_size
            y0 = top + row_index * cell_size
            x1 = x0 + cell_size
            y1 = y0 + cell_size
            fill = palette(value)
            draw.rectangle((x0, y0, x1, y1), fill=fill, outline=(210, 210, 210))

    return image


def combine_side_by_side(left: Image.Image, right: Image.Image, gap: int) -> Image.Image:
    width = left.width + gap + right.width
    height = max(left.height, right.height)
    combined = Image.new("RGB", (width, height), color=(255, 255, 255))
    combined.paste(left, (0, 0))
    combined.paste(right, (left.width + gap, 0))
    return combined


def save_single_image(csv_path: Path, output_path: Path, title: str, cell_size: int) -> Path:
    grid = read_csv_grid(csv_path)
    image = render_grid(grid, title=title, cell_size=cell_size)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)
    return output_path


def main() -> int:
    args = parse_args()

    before_output = args.output.with_name(f"{args.before_csv.stem}_image.png")
    before_image_path = save_single_image(
        args.before_csv,
        before_output,
        title=args.title_before,
        cell_size=args.cell_size,
    )

    if args.after_csv is None:
        before_output.replace(args.output)
        print(f"Wrote: {args.output}")
        return 0

    after_output = args.output.with_name(f"{args.after_csv.stem}_image.png")
    after_image_path = save_single_image(
        args.after_csv,
        after_output,
        title=args.title_after,
        cell_size=args.cell_size,
    )

    with Image.open(before_image_path) as left, Image.open(after_image_path) as right:
        comparison = combine_side_by_side(left, right, gap=args.gap)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        comparison.save(args.output)

    print(f"Wrote: {before_image_path}")
    print(f"Wrote: {after_image_path}")
    print(f"Wrote: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())