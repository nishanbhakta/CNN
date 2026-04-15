#!/usr/bin/env python3
"""Compare a golden feature-map CSV against a hardware-generated feature-map CSV."""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Compare a golden output CSV and a hardware output CSV, then write a "
            "cell-by-cell comparison report."
        )
    )
    parser.add_argument("golden_csv", type=Path, help="Path to the golden output CSV")
    parser.add_argument("actual_csv", type=Path, help="Path to the hardware output CSV")
    parser.add_argument(
        "--comparison-csv",
        type=Path,
        help=(
            "Optional destination for the detailed comparison CSV "
            "(default: alongside the hardware output as output_comparison.csv)"
        ),
    )
    return parser.parse_args()


def load_feature_map_csv(path: Path) -> list[list[int | None]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.reader(handle)
        return [
            [None if cell == "" else int(cell) for cell in row]
            for row in reader
        ]


def compare_feature_maps(
    golden_csv: Path,
    actual_csv: Path,
    comparison_csv: Path,
) -> dict[str, int]:
    golden_rows = load_feature_map_csv(golden_csv)
    actual_rows = load_feature_map_csv(actual_csv)

    if len(golden_rows) != len(actual_rows):
        raise ValueError(
            "Golden and hardware output CSVs have different row counts: "
            f"{len(golden_rows)} vs {len(actual_rows)}"
        )

    total_cells = 0
    matching_cells = 0
    mismatched_cells = 0

    comparison_csv.parent.mkdir(parents=True, exist_ok=True)

    with comparison_csv.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["row", "col", "golden", "actual", "status"])

        for row_index, (golden_row, actual_row) in enumerate(
            zip(golden_rows, actual_rows, strict=True)
        ):
            if len(golden_row) != len(actual_row):
                raise ValueError(
                    "Golden and hardware output CSVs have different column counts "
                    f"at row {row_index}: {len(golden_row)} vs {len(actual_row)}"
                )

            for col_index, (golden_value, actual_value) in enumerate(
                zip(golden_row, actual_row, strict=True)
            ):
                total_cells += 1
                status = "MATCH" if golden_value == actual_value else "MISMATCH"
                if status == "MATCH":
                    matching_cells += 1
                else:
                    mismatched_cells += 1

                writer.writerow(
                    [
                        row_index,
                        col_index,
                        "" if golden_value is None else golden_value,
                        "" if actual_value is None else actual_value,
                        status,
                    ]
                )

    return {
        "total_cells": total_cells,
        "matching_cells": matching_cells,
        "mismatched_cells": mismatched_cells,
    }


def main() -> int:
    args = parse_args()
    comparison_csv = (
        args.comparison_csv
        if args.comparison_csv is not None
        else args.actual_csv.with_name("output_comparison.csv")
    )

    try:
        summary = compare_feature_maps(
            golden_csv=args.golden_csv.resolve(),
            actual_csv=args.actual_csv.resolve(),
            comparison_csv=comparison_csv.resolve(),
        )
    except (FileNotFoundError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1

    print(f"Golden CSV     : {args.golden_csv.resolve()}")
    print(f"Hardware CSV   : {args.actual_csv.resolve()}")
    print(f"Comparison CSV : {comparison_csv.resolve()}")
    print(
        "Summary        : "
        f"{summary['matching_cells']}/{summary['total_cells']} cells match, "
        f"{summary['mismatched_cells']} mismatches"
    )
    status = "PASS" if summary["mismatched_cells"] == 0 else "FAIL"
    print(f"Status         : {status}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
