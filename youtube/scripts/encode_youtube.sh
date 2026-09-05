#!/usr/bin/env bash
# Encode any video to YouTube-recommended MP4 (H.264 + AAC, faststart).
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  encode_youtube.sh <input> <output.mp4> [--shorts|--landscape] [--fps 30]

YouTube export defaults:
  - landscape: 1920x1080, 30 fps
  - shorts:    1080x1920, 30 fps
  - H.264 High, yuv420p, +faststart
  - AAC-LC 48 kHz stereo
  - loudness target -14 LUFS (YouTube)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

INPUT=$1
OUTPUT=$2
shift 2

MODE=landscape
FPS=30

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shorts) MODE=shorts ;;
    --landscape) MODE=landscape ;;
    --fps)
      FPS=$2
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

if [[ ! -f "$INPUT" ]]; then
  echo "Input not found: $INPUT" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

if [[ "$MODE" == "shorts" ]]; then
  W=1080
  H=1920
else
  W=1920
  H=1080
fi

VF="scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=0b1220,fps=${FPS},format=yuv420p,setsar=1"

HAS_AUDIO=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$INPUT" || true)

FFMPEG_ARGS=(
  -y
  -i "$INPUT"
)

if [[ -z "$HAS_AUDIO" ]]; then
  FFMPEG_ARGS+=(
    -f lavfi
    -i anullsrc=channel_layout=stereo:sample_rate=48000
    -filter_complex "[0:v]${VF}[v];[1:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,loudnorm=I=-14:TP=-1.5:LRA=11[a]"
    -map "[v]"
    -map "[a]"
    -shortest
  )
else
  FFMPEG_ARGS+=(
    -filter_complex "[0:v]${VF}[v];[0:a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,loudnorm=I=-14:TP=-1.5:LRA=11[a]"
    -map "[v]"
    -map "[a]"
  )
fi

FFMPEG_ARGS+=(
  -c:v libx264 -profile:v high -level 4.1 -preset medium -crf 18
  -pix_fmt yuv420p -r "$FPS" -g $((FPS * 2)) -bf 2
  -c:a aac -b:a 384k -ar 48000 -ac 2
  -movflags +faststart
  -color_primaries bt709 -color_trc bt709 -colorspace bt709
  "$OUTPUT"
)

ffmpeg "${FFMPEG_ARGS[@]}"

echo "Wrote $OUTPUT"
ffprobe -v error \
  -show_entries format=duration,size,format_name \
  -show_entries stream=codec_name,width,height,pix_fmt,avg_frame_rate,sample_rate,channels \
  -of default=nw=1 \
  "$OUTPUT"
