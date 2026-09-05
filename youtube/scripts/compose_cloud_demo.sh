#!/usr/bin/env bash
# Build branded intro/outro around recorded Cloud footage and export YouTube files.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/out"
RAW_CANDIDATES=(
  "$OUT/raw/cloud_app_raw.webm"
  "$OUT/raw/cloud_app_raw.mp4"
)
FONT_BOLD="/usr/share/fonts/truetype/macos/Inter-Bold.ttf"
FONT_REG="/usr/share/fonts/truetype/macos/Inter-Regular.ttf"

mkdir -p "$OUT/cards" "$OUT/exports"

RAW=""
for candidate in "${RAW_CANDIDATES[@]}"; do
  if [[ -f "$candidate" ]]; then
    RAW=$candidate
    break
  fi
done

if [[ -z "$RAW" ]]; then
  echo "No raw footage in $OUT/raw. Run: npm run record --prefix youtube" >&2
  exit 1
fi

INTRO="$OUT/cards/intro.mp4"
OUTRO="$OUT/cards/outro.mp4"
BED="$OUT/cards/bed.wav"
FOOTAGE="$OUT/cards/footage.mp4"
CONCAT="$OUT/cards/concat.txt"
MASTER="$OUT/cards/master.mp4"

draw_card() {
  local dest=$1 title=$2 subtitle=$3 eyebrow=$4 duration=$5
  ffmpeg -y -f lavfi -i "color=c=0b1220:s=1920x1080:d=${duration}:r=30" \
    -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
    -filter_complex \
    "[0:v]drawbox=x=0:y=520:w=1920:h=4:color=6ea8fe@0.85:t=fill,\
drawtext=fontfile=${FONT_REG}:text='${eyebrow}':fontsize=28:fontcolor=9fb0d0:x=(w-text_w)/2:y=330,\
drawtext=fontfile=${FONT_BOLD}:text='${title}':fontsize=88:fontcolor=e8eefc:x=(w-text_w)/2:y=390,\
drawtext=fontfile=${FONT_REG}:text='${subtitle}':fontsize=32:fontcolor=6ea8fe:x=(w-text_w)/2:y=555,\
fade=t=in:st=0:d=0.4,fade=t=out:st=$(awk "BEGIN{print ${duration}-0.4}"):d=0.4,format=yuv420p[v]" \
    -map "[v]" -map 1:a -shortest \
    -c:v libx264 -profile:v high -pix_fmt yuv420p -r 30 \
    -c:a aac -ar 48000 -ac 2 -b:a 192k \
    "$dest"
}

draw_card "$INTRO" "CLOUD" "Starter app  ·  live API demo" "XENO S.GAMES" 3.5
draw_card "$OUTRO" "THANKS FOR WATCHING" "github.com/Xenoframes008/Cloud" "LIKE  ·  SUBSCRIBE  ·  COMMENT" 4.5

RAW_DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$RAW")
FADE_OUT_START=$(python3 -c "print(max(0.0, float('$RAW_DUR')-0.35))")

ffmpeg -y -i "$RAW" \
  -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
  -filter_complex "[0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2:color=0b1220,fps=30,format=yuv420p,fade=t=in:st=0:d=0.3,fade=t=out:st=${FADE_OUT_START}:d=0.3[v]" \
  -map "[v]" -map 1:a -shortest \
  -c:v libx264 -profile:v high -pix_fmt yuv420p -r 30 \
  -c:a aac -ar 48000 -ac 2 -b:a 192k \
  "$FOOTAGE"

{
  echo "file '$INTRO'"
  echo "file '$FOOTAGE'"
  echo "file '$OUTRO'"
} > "$CONCAT"

ffmpeg -y -f concat -safe 0 -i "$CONCAT" -c copy "$MASTER"

TOTAL=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$MASTER")
python3 "$ROOT/scripts/make_audio_bed.py" "$TOTAL" "$BED"

# Mix the original (silent) master with the generated bed, then final-encode.
MIXED="$OUT/cards/mixed.mp4"
ffmpeg -y -i "$MASTER" -i "$BED" \
  -filter_complex "[1:a]volume=0.55,afade=t=in:st=0:d=0.6,afade=t=out:st=$(python3 -c "print(max(0.0, float('$TOTAL')-0.8))"):d=0.8[a]" \
  -map 0:v -map "[a]" -shortest \
  -c:v copy -c:a aac -b:a 384k -ar 48000 -ac 2 \
  "$MIXED"

bash "$ROOT/scripts/encode_youtube.sh" "$MIXED" "$OUT/exports/cloud_starter_demo_youtube_1080p.mp4" --landscape

# Shorts: blur-fill 9:16 with captions.
SHORTS_SRC="$OUT/cards/shorts_src.mp4"
ffmpeg -y -i "$MIXED" \
  -filter_complex "\
[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=24:8[bg];\
[0:v]scale=1080:1920:force_original_aspect_ratio=decrease[fg];\
[bg][fg]overlay=(W-w)/2:(H-h)/2,\
drawbox=x=0:y=120:w=1080:h=110:color=0b1220@0.45:t=fill,\
drawtext=fontfile=${FONT_BOLD}:text='CLOUD  ·  LIVE DEMO':fontsize=42:fontcolor=e8eefc:x=(w-text_w)/2:y=150,\
drawtext=fontfile=${FONT_REG}:text='Xeno S.Games':fontsize=28:fontcolor=6ea8fe:x=(w-text_w)/2:y=200[v]" \
  -map "[v]" -map 0:a \
  -c:v libx264 -pix_fmt yuv420p -c:a copy \
  "$SHORTS_SRC"

bash "$ROOT/scripts/encode_youtube.sh" "$SHORTS_SRC" "$OUT/exports/cloud_starter_demo_youtube_shorts.mp4" --shorts

# Thumbnail from a mid-footage frame plus title treatment.
THUMB_FRAME="$OUT/cards/thumb_frame.png"
ffmpeg -y -ss 2.5 -i "$FOOTAGE" -frames:v 1 -update 1 "$THUMB_FRAME"
ffmpeg -y -i "$THUMB_FRAME" -frames:v 1 -update 1 \
  -vf "scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,\
drawbox=x=0:y=470:w=1280:h=250:color=0b1220@0.72:t=fill,\
drawtext=fontfile=${FONT_BOLD}:text='CLOUD':fontsize=92:fontcolor=e8eefc:x=48:y=500,\
drawtext=fontfile=${FONT_REG}:text='Starter app live demo':fontsize=36:fontcolor=6ea8fe:x=52:y=610" \
  "$OUT/exports/cloud_starter_demo_thumbnail.jpg"

echo "Exports ready in $OUT/exports"
ls -lh "$OUT/exports"
