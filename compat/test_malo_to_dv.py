#!/usr/bin/env python3
"""Tests for the malo-browser -> delivery-video evidence adapter."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import malo_to_dv  # noqa: E402

FIXTURE = HERE / "fixtures" / "malo-evidence.json"
FPS = 30
DURATION_S = 10


def ffmpeg_available() -> bool:
    return shutil.which("ffmpeg") is not None and shutil.which("ffprobe") is not None


@unittest.skipUnless(ffmpeg_available(), "ffmpeg and ffprobe are required")
class ConvertTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.tmp = Path(tempfile.mkdtemp(prefix="malo-to-dv-"))
        cls.video = cls.tmp / "take-01.mp4"
        subprocess.run(
            [
                "ffmpeg", "-y", "-v", "error",
                "-f", "lavfi", "-i",
                f"color=c=black:s=1920x1080:r={FPS}",
                "-t", str(DURATION_S),
                "-c:v", "libx264", "-pix_fmt", "yuv420p",
                str(cls.video),
            ],
            check=True,
        )
        cls.raw = json.loads(FIXTURE.read_text(encoding="utf-8"))

    @classmethod
    def tearDownClass(cls) -> None:
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def write_evidence(self, mutate=None) -> Path:
        data = json.loads(json.dumps(self.raw))
        if mutate:
            mutate(data)
        path = self.tmp / "malo.evidence.json"
        path.write_text(json.dumps(data), encoding="utf-8")
        return path

    def convert(self, mutate=None) -> dict:
        evidence = self.write_evidence(mutate)
        out = malo_to_dv.convert(evidence, self.video, None)
        return json.loads(out.read_text(encoding="utf-8"))

    def test_checks_dict_becomes_list(self) -> None:
        converted = self.convert()
        self.assertIsInstance(converted["checks"], list)
        self.assertEqual(len(converted["checks"]), 7)
        for item in converted["checks"]:
            self.assertIsInstance(item, dict)
            self.assertIs(item["passed"], True)
            self.assertIn("id", item)

    def test_headless_moves_into_capture(self) -> None:
        converted = self.convert()
        self.assertIs(converted["capture"]["headless"], True)
        self.assertIs(converted["capture"]["window_visible"], False)

    def test_sha256_and_duration_are_recomputed(self) -> None:
        converted = self.convert()
        actual = malo_to_dv.sha256_of(self.video)
        self.assertEqual(converted["video"]["sha256"], actual)
        self.assertEqual(converted["video"]["file"], "take-01.mp4")
        self.assertAlmostEqual(converted["video"]["duration_s"], DURATION_S, delta=0.2)

    def test_default_output_sits_next_to_video(self) -> None:
        evidence = self.write_evidence()
        out = malo_to_dv.convert(evidence, self.video, None)
        self.assertEqual(out, self.video.with_suffix(".evidence.json"))

    def test_explicit_output_path(self) -> None:
        evidence = self.write_evidence()
        target = self.tmp / "explicit.evidence.json"
        out = malo_to_dv.convert(evidence, self.video, target)
        self.assertEqual(out, target)
        self.assertTrue(target.is_file())

    def test_rejects_failed_status(self) -> None:
        with self.assertRaises(malo_to_dv.ConvertError):
            self.convert(lambda d: d.__setitem__("status", "failed"))

    def test_rejects_wrong_kind(self) -> None:
        with self.assertRaises(malo_to_dv.ConvertError):
            self.convert(lambda d: d.__setitem__("kind", "cdp-screencast"))

    def test_rejects_visible_window(self) -> None:
        def mutate(d):
            d["run"]["headless"] = False

        with self.assertRaises(malo_to_dv.ConvertError):
            self.convert(mutate)

    def test_rejects_duration_drift(self) -> None:
        def mutate(d):
            d["video"]["duration_s"] = 99

        with self.assertRaises(malo_to_dv.ConvertError):
            self.convert(mutate)

    def test_rejects_missing_video_block(self) -> None:
        def mutate(d):
            d.pop("video", None)

        with self.assertRaises(malo_to_dv.ConvertError):
            self.convert(mutate)

    @unittest.skipUnless(
        os.environ.get("DELIVERY_VIDEO_SCRIPTS"),
        "set DELIVERY_VIDEO_SCRIPTS to the delivery-video scripts dir to run",
    )
    def test_output_passes_delivery_video_preflight(self) -> None:
        scripts = Path(os.environ["DELIVERY_VIDEO_SCRIPTS"])
        sys.path.insert(0, str(scripts))
        import preflight  # noqa: E402

        evidence = self.write_evidence()
        out = malo_to_dv.convert(evidence, self.video, None)
        errors: list[str] = []
        preflight.check_demo_stage_evidence("take-01", self.video, errors)
        self.assertEqual(errors, [], f"delivery-video rejected {out.name}: {errors}")


if __name__ == "__main__":
    unittest.main()
