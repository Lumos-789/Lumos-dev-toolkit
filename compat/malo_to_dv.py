#!/usr/bin/env python3
"""Bind a malo-browser take to the delivery-video `demo-stage-recording` contract.

Both projects call the artifact `demo-stage-recording`, but they disagree on two
fields, so `delivery-video`'s preflight rejects malo evidence as-is:

  1. malo writes self-checks as a dict ``{"name": {"passed": bool, "detail": str}}``;
     delivery-video requires a list ``[{"id": str, "passed": bool}]``.
  2. malo records ``headless`` under ``run.headless``; delivery-video reads
     ``capture.headless`` and requires it to be ``true``.

The sha256 and duration are re-derived from the mp4 itself, so a stale evidence
file cannot silently bind to a different take.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

DEMO_STAGE_KIND = "demo-stage-recording"
DURATION_TOLERANCE_S = 0.2


class ConvertError(RuntimeError):
    pass


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def probe_duration(path: Path) -> float:
    try:
        result = subprocess.run(
            [
                "ffprobe", "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                str(path),
            ],
            capture_output=True,
            text=True,
            check=True,
        )
    except FileNotFoundError as exc:
        raise ConvertError("ffprobe not found on PATH; delivery-video requires it") from exc
    except subprocess.CalledProcessError as exc:
        raise ConvertError(f"ffprobe failed on {path}: {exc.stderr.strip()}") from exc
    raw = result.stdout.strip()
    if not raw or raw == "N/A":
        raise ConvertError(f"ffprobe returned no duration for {path}")
    return float(raw)


def checks_as_list(checks: object) -> list[dict]:
    if isinstance(checks, list):
        return checks
    if isinstance(checks, dict):
        return [
            {"id": str(name), "passed": bool(body.get("passed")), "detail": body.get("detail", "")}
            for name, body in checks.items()
            if isinstance(body, dict)
        ]
    raise ConvertError(f"unexpected checks block: {type(checks).__name__}")


def convert(evidence_path: Path, video_path: Path, out_path: Path | None) -> Path:
    if not evidence_path.is_file():
        raise ConvertError(f"evidence not found: {evidence_path}")
    if not video_path.is_file():
        raise ConvertError(f"video not found: {video_path}")

    evidence = json.loads(evidence_path.read_text(encoding="utf-8"))
    if not isinstance(evidence, dict):
        raise ConvertError("evidence must be a JSON object")
    if evidence.get("kind") != DEMO_STAGE_KIND:
        raise ConvertError(
            f"evidence kind {evidence.get('kind')!r} is not {DEMO_STAGE_KIND!r}"
        )
    if evidence.get("status") != "passed":
        raise ConvertError(
            f"evidence status {evidence.get('status')!r} != 'passed'; "
            "delivery-video only accepts a passed take"
        )

    video_block = evidence.get("video")
    if not isinstance(video_block, dict):
        raise ConvertError("evidence has no video block")

    capture = dict(evidence.get("capture") or {})
    run = evidence.get("run") or {}
    capture["headless"] = bool(run.get("headless"))
    if capture["headless"] is not True:
        raise ConvertError(
            "malo run.headless is not true; a visible-window take is not a demo-stage recording"
        )

    actual_sha = sha256_of(video_path)
    actual_duration = probe_duration(video_path)
    declared = video_block.get("duration_s")
    if declared is not None:
        try:
            drift = abs(float(declared) - actual_duration)
        except (TypeError, ValueError) as exc:
            raise ConvertError(f"video.duration_s is not numeric: {declared!r}") from exc
        if drift > DURATION_TOLERANCE_S:
            raise ConvertError(
                f"video.duration_s {declared} drifts {drift:.2f}s from the file "
                f"({actual_duration:.2f}s); evidence belongs to another take"
            )

    converted = dict(evidence)
    converted["capture"] = capture
    converted["checks"] = checks_as_list(evidence.get("checks"))
    converted["video"] = {
        **video_block,
        "file": video_path.name,
        "sha256": actual_sha,
        "duration_s": round(actual_duration, 3),
    }

    target = out_path or video_path.with_suffix(".evidence.json")
    target.write_text(json.dumps(converted, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return target


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("evidence", type=Path, help="malo evidence JSON")
    parser.add_argument("video", type=Path, help="the mp4 the evidence describes")
    parser.add_argument("--out", type=Path, default=None, help="output evidence path")
    args = parser.parse_args(argv)

    try:
        target = convert(args.evidence, args.video, args.out)
    except ConvertError as exc:
        print(f"malo_to_dv: {exc}", file=sys.stderr)
        return 1
    print(f"malo_to_dv: wrote {target}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
