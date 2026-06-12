#!/usr/bin/env python3
"""Render a geometry3d .tui3d ASCII sequence to MP4 or MOV with ffmpeg."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import shutil
import subprocess
import sys
import time
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


MAGIC = "GEOMETRY3D_TUI_SEQUENCE v1"
FRAME_MARKER = "---frame---"
FONT_CANDIDATES = (
    Path("/System/Library/Fonts/Menlo.ttc"),
    Path("/System/Library/Fonts/Monaco.dfont"),
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"),
    Path("/usr/share/fonts/truetype/liberation/LiberationMono-Regular.ttf"),
    Path("C:/Windows/Fonts/consola.ttf"),
    Path("C:/Windows/Fonts/cour.ttf"),
)
LUMA = {
    " ": 0,
    ".": 34,
    ":": 62,
    "-": 86,
    "=": 112,
    "+": 142,
    "*": 174,
    "#": 212,
    "%": 235,
    "@": 255,
}


def format_duration(seconds: float) -> str:
    seconds = max(0, round(seconds))
    minutes, seconds = divmod(seconds, 60)
    hours, minutes = divmod(minutes, 60)
    if hours:
        return f"{hours:d}:{minutes:02d}:{seconds:02d}"
    return f"{minutes:02d}:{seconds:02d}"


class ProgressBar:
    def __init__(self, total: int, enabled: bool) -> None:
        self.total = max(1, total)
        self.enabled = enabled
        self.interactive = sys.stderr.isatty()
        self.started_at = time.monotonic()
        self.last_rendered = 0
        self.last_log_percent = -10

    def update(self, completed: int) -> None:
        if not self.enabled:
            return
        now = time.monotonic()
        percent = min(100, completed * 100 // self.total)
        if self.interactive:
            if completed < self.total and now - self.last_rendered < 0.1:
                return
            width = 30
            filled = min(width, completed * width // self.total)
            bar = "#" * filled + "-" * (width - filled)
            elapsed = now - self.started_at
            eta = elapsed * (self.total - completed) / completed if completed else 0
            sys.stderr.write(
                f"\rEncoding [{bar}] {percent:3d}% "
                f"{completed}/{self.total} elapsed {format_duration(elapsed)} "
                f"eta {format_duration(eta)}"
            )
            sys.stderr.flush()
            self.last_rendered = now
            if completed >= self.total:
                sys.stderr.write("\n")
        elif percent >= self.last_log_percent + 10 or completed >= self.total:
            elapsed = now - self.started_at
            print(
                f"Encoding {percent:3d}% ({completed}/{self.total}) "
                f"elapsed {format_duration(elapsed)}",
                file=sys.stderr,
            )
            self.last_log_percent = percent


@dataclass(frozen=True)
class SequenceInfo:
    width: int
    height: int
    fps: int
    frame_count: int


def read_sequence_info(path: Path) -> SequenceInfo:
    with path.open(encoding="utf-8") as source:
        if source.readline().rstrip("\r\n") != MAGIC:
            raise ValueError(f"not a geometry3d TUI sequence: {path}")
        metadata = {}
        for _ in range(4):
            line = source.readline().rstrip("\r\n")
            key, value = line.split("=", 1)
            metadata[key] = int(value)
    info = SequenceInfo(
        width=metadata["width"],
        height=metadata["height"],
        fps=metadata["fps"],
        frame_count=metadata["frames"],
    )
    if min(info.width, info.height, info.fps, info.frame_count) < 1:
        raise ValueError(f"invalid sequence metadata: {path}")
    return info


def iter_frames(path: Path, info: SequenceInfo):
    with path.open(encoding="utf-8") as source:
        for _ in range(5):
            source.readline()
        emitted = 0
        for line in source:
            if line.rstrip("\r\n") != FRAME_MARKER:
                continue
            frame = []
            for _ in range(info.height):
                row = source.readline()
                if row == "":
                    row = ""
                frame.append(row.rstrip("\r\n")[: info.width].ljust(info.width))
            emitted += 1
            yield frame
    if emitted != info.frame_count:
        raise ValueError(
            f"expected {info.frame_count} frames in {path}, found {emitted}"
        )


def default_font() -> Path:
    for path in FONT_CANDIDATES:
        if path.exists():
            return path
    raise FileNotFoundError("no supported monospace font found; pass --font")


def load_font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    if not path.exists():
        raise FileNotFoundError(f"monospace font not found: {path}")
    return ImageFont.truetype(str(path), size=size)


def choose_layout(
    font_path: Path,
    requested_size: int,
    columns: int,
    rows: int,
    margin: int,
    line_gap: int,
    cell_aspect: float,
    max_width: int,
    max_height: int,
) -> tuple[ImageFont.FreeTypeFont, int, int, int, int, tuple[int, int, int, int]]:
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for size in range(requested_size, 0, -1):
        font = load_font(font_path, size)
        bbox = probe.textbbox((0, 0), "Mg", font=font)
        cell_width = max(1, round(probe.textlength("M", font=font)))
        cell_height = max(
            bbox[3] - bbox[1] + line_gap,
            round(cell_width * cell_aspect),
        )
        video_width = columns * cell_width + margin * 2
        video_height = rows * cell_height + margin * 2
        if video_width <= max_width and video_height <= max_height:
            video_width += video_width % 2
            video_height += video_height % 2
            return font, cell_width, cell_height, video_width, video_height, bbox
    raise ValueError(
        f"{columns}x{rows} characters cannot fit within "
        f"{max_width}x{max_height}; increase --max-width/--max-height"
    )


def ffmpeg_command(ffmpeg: str, output: Path, width: int, height: int, fps: int) -> list[str]:
    common = [
        ffmpeg,
        "-y",
        "-hide_banner",
        "-loglevel",
        "warning",
        "-f",
        "rawvideo",
        "-pixel_format",
        "rgb24",
        "-video_size",
        f"{width}x{height}",
        "-framerate",
        str(fps),
        "-i",
        "-",
        "-an",
    ]
    if output.suffix.lower() == ".mov":
        return common + ["-c:v", "prores_ks", "-profile:v", "3", "-pix_fmt", "yuv422p10le", str(output)]
    return common + [
        "-c:v",
        "libx264",
        "-preset",
        "medium",
        "-crf",
        "18",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        str(output),
    ]


def render(args: argparse.Namespace) -> None:
    info = read_sequence_info(args.input)
    font_path = args.font if args.font is not None else default_font()
    font, cell_width, cell_height, video_width, video_height, bbox = choose_layout(
        font_path,
        args.font_size,
        info.width,
        info.height,
        args.margin,
        args.line_gap,
        args.cell_aspect,
        args.max_width,
        args.max_height,
    )
    print(
        f"TUI grid {info.width}x{info.height}, cell {cell_width}x{cell_height}px, "
        f"video {video_width}x{video_height}px",
        file=sys.stderr,
    )
    print(
        "TUI Y correction is already baked into the sequence; "
        "the tall cell restores its physical aspect ratio.",
        file=sys.stderr,
    )

    ffmpeg = shutil.which("ffmpeg")
    if ffmpeg is None:
        raise FileNotFoundError("ffmpeg was not found in PATH")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    process = subprocess.Popen(
        ffmpeg_command(ffmpeg, args.output, video_width, video_height, info.fps),
        stdin=subprocess.PIPE,
    )
    assert process.stdin is not None
    progress = ProgressBar(info.frame_count, not args.no_progress)
    try:
        for frame_index, frame in enumerate(iter_frames(args.input, info), start=1):
            image = Image.new("RGB", (video_width, video_height), (5, 7, 9))
            draw = ImageDraw.Draw(image)
            for row_index, row in enumerate(frame):
                y = args.margin + row_index * cell_height - bbox[1]
                for column_index, char in enumerate(row):
                    value = LUMA.get(char, 220)
                    if value == 0:
                        continue
                    draw.text(
                        (args.margin + column_index * cell_width, y),
                        char,
                        font=font,
                        fill=(value, value, value),
                    )
            process.stdin.write(image.tobytes())
            progress.update(frame_index)
    finally:
        process.stdin.close()
    if process.wait() != 0:
        raise RuntimeError("ffmpeg failed to encode the video")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="input .tui3d sequence")
    parser.add_argument("output", type=Path, help="output .mp4 or .mov file")
    parser.add_argument("--font", type=Path)
    parser.add_argument("--font-size", type=int, default=18)
    parser.add_argument("--line-gap", type=int, default=0)
    parser.add_argument("--cell-aspect", type=float, default=2.0)
    parser.add_argument("--margin", type=int, default=24)
    parser.add_argument("--max-width", type=int, default=3840)
    parser.add_argument("--max-height", type=int, default=2160)
    parser.add_argument("--no-progress", action="store_true")
    args = parser.parse_args()
    if args.output.suffix.lower() not in {".mp4", ".mov"}:
        parser.error("output must end in .mp4 or .mov")
    try:
        render(args)
    except (FileNotFoundError, RuntimeError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
