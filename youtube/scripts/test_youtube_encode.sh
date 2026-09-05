#!/usr/bin/env bash
# Smoke-test the YouTube encoder against a 1-second generated clip.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$ROOT/out/test"
mkdir -p "$TMP"

SRC="$TMP/source.mp4"
LAND="$TMP/land.mp4"
SHORT="$TMP/short.mp4"

ffmpeg -y -f lavfi -i "color=c=0b1220:s=1280x720:d=1:r=24" \
  -f lavfi -i "sine=frequency=440:duration=1" \
  -shortest -c:v libx264 -pix_fmt yuv420p -c:a aac "$SRC"

bash "$ROOT/scripts/encode_youtube.sh" "$SRC" "$LAND" --landscape
bash "$ROOT/scripts/encode_youtube.sh" "$SRC" "$SHORT" --shorts

python3 - "$LAND" "$SHORT" <<'PY'
import json, subprocess, sys

def probe(path):
    out = subprocess.check_output([
        "ffprobe", "-v", "error", "-print_format", "json",
        "-show_streams", "-show_format", path,
    ])
    return json.loads(out)

def check(path, width, height):
    info = probe(path)
    video = next(s for s in info["streams"] if s["codec_type"] == "video")
    audio = next(s for s in info["streams"] if s["codec_type"] == "audio")
    assert video["codec_name"] == "h264", video["codec_name"]
    assert video["width"] == width, video["width"]
    assert video["height"] == height, video["height"]
    assert video["pix_fmt"] == "yuv420p", video["pix_fmt"]
    assert audio["codec_name"] == "aac", audio["codec_name"]
    assert audio["sample_rate"] == "48000", audio["sample_rate"]
    assert int(audio["channels"]) == 2, audio["channels"]
    assert "mp4" in info["format"]["format_name"]
    print(f"ok {path} {width}x{height}")

check(sys.argv[1], 1920, 1080)
check(sys.argv[2], 1080, 1920)
PY

echo "YouTube encode smoke test passed"
