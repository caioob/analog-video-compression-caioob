#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
Usage:
  ./generate_clip_chain.sh [MODE] [INPUT_FILE] [OUTPUT_DIR]

Arguments:
  MODE         Mode to run: hunt | crop | glitch | dev (default: hunt)
               hunt  — expects a pre-cropped file as INPUT_FILE
               crop  — removes pillarbox and scales to 960x720 intermediate
               glitch — applies artifact+safety chain, encodes MPEG2
               dev   — crop 3m → glitch → dev.mpg + 2 shader-baked mp4s
  INPUT_FILE   Source video file (default: theThirdTransmission.mp4)
  OUTPUT_DIR   Output directory (default: ./renders)

Environment overrides:
  HUNT_START    Start time for hunt clip       (default: 00:00:00)
  HUNT_LENGTH   Duration for hunt clip         (default: 00:12:00)
  CROP_START    Start time for crop            (default: 00:00:00)
  CROP_LENGTH   Duration for crop              (default: 00:12:00)
  CROP_FILTER   Crop expression                (default: crop=1440:1072:240:4)
  GLITCH_OUT    Output filename for glitch     (default: glitch.mpg)
  GLITCH_NOISE  Noise level for glitch chain   (default: 15)
  DEV_START     Start time for dev clip        (default: 00:00:00)
  DEV_LENGTH    Duration for dev clip          (default: 180)

Examples:
  ./generate_clip_chain.sh hunt cropped.mp4
  HUNT_START=00:10:00 HUNT_LENGTH=30 ./generate_clip_chain.sh hunt cropped.mp4
  CROP_START=00:10:00 CROP_LENGTH=60 ./generate_clip_chain.sh crop
  INPUT_FILE=renders/cropped.mp4 GLITCH_OUT=out.mpg ./generate_clip_chain.sh glitch
  ./generate_clip_chain.sh dev
  DEV_START=00:22:00 ./generate_clip_chain.sh dev
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

MODE="hunt"
if [[ "${1:-}" == "hunt" || "${1:-}" == "crop" || "${1:-}" == "glitch" || "${1:-}" == "dev" ]]; then
  MODE="$1"
  INPUT_FILE="${2:-theThirdTransmission.mp4}"
  OUT_DIR="${3:-./renders}"
else
  INPUT_FILE="${1:-theThirdTransmission.mp4}"
  OUT_DIR="${2:-./renders}"
fi

HUNT_START="${HUNT_START:-00:00:00}"
HUNT_LENGTH="${HUNT_LENGTH:-00:12:00}"
CROP_START="${CROP_START:-00:00:00}"
CROP_LENGTH="${CROP_LENGTH:-00:12:00}"
CROP_FILTER="${CROP_FILTER:-crop=1440:1072:240:4}"
GLITCH_OUT="${GLITCH_OUT:-glitch.mpg}"
GLITCH_NOISE="${GLITCH_NOISE:-15}"
DEV_START="${DEV_START:-00:00:00}"
DEV_LENGTH="${DEV_LENGTH:-180}"

mkdir -p "$OUT_DIR"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Input not found: $INPUT_FILE" >&2
  exit 1
fi

run_hunt() {
  echo "Building hunt preview clip..."
  ffmpeg -y -ss "$HUNT_START" -i "$INPUT_FILE" -t "$HUNT_LENGTH" \
    -vf "scale=960:720:flags=neighbor" \
    -c:v libx264 -preset veryfast -crf 18 \
    "$OUT_DIR/hunt.mp4"
}

run_crop() {
  echo "Building cropped intermediate..."
  ffmpeg -y -ss "$CROP_START" -i "$INPUT_FILE" -t "$CROP_LENGTH" \
    -vf "$CROP_FILTER,scale=960:720:flags=neighbor" \
    -c:v libx264 -preset veryfast -crf 18 \
    "$OUT_DIR/cropped.mp4"
}

run_dev() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local shader_dir="$script_dir/../../mpv-retro-shaders-master"
  local guest_shader="$shader_dir/crt-guest-advanced-ntsc.glsl"
  local royale_shader="$shader_dir/crt-royale-kurozumi-intel.glsl"

  if [[ ! -f "$guest_shader" ]]; then
    echo "Missing shader: $guest_shader" >&2; exit 1
  fi
  if [[ ! -f "$royale_shader" ]]; then
    echo "Missing shader: $royale_shader" >&2; exit 1
  fi

  local tmp_crop
  tmp_crop=$(mktemp /tmp/dev_crop_XXXXXX.mp4)

  echo "[1/4] Cropping ${DEV_LENGTH}s from ${DEV_START}..."
  ffmpeg -y -ss "$DEV_START" -i "$INPUT_FILE" -t "$DEV_LENGTH" \
    -vf "$CROP_FILTER,scale=960:720:flags=neighbor" \
    -c:v libx264 -preset veryfast -crf 18 \
    "$tmp_crop"

  echo "[2/4] Applying glitch chain..."
  ffmpeg -y -i "$tmp_crop" \
    -vf "scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=${GLITCH_NOISE}:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff" \
    -c:v mpeg2video -flags +ildct+ilme -top 0 -b:v 8000k -maxrate 9000k -minrate 2000k -bufsize 1835k \
    -an \
    "$OUT_DIR/dev.mpg"

  rm -f "$tmp_crop"

  echo "[3/4] Rendering with Guest Advanced NTSC shader..."
  mpv --no-config --no-audio --no-deinterlace \
    --glsl-shader="$guest_shader" \
    --o="$OUT_DIR/dev_guest_ntsc.mp4" \
    --ovc=libx264 \
    --ovcopts=crf=18,preset=medium \
    "$OUT_DIR/dev.mpg"

  echo "[4/4] Rendering with Royale Kurozumi shader..."
  mpv --no-config --no-audio --no-deinterlace \
    --glsl-shader="$royale_shader" \
    --o="$OUT_DIR/dev_royale_kurozumi.mp4" \
    --ovc=libx264 \
    --ovcopts=crf=18,preset=medium \
    "$OUT_DIR/dev.mpg"
}

run_glitch() {
  echo "Applying glitch chain..."
  ffmpeg -y -i "$INPUT_FILE" \
    -vf "scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=${GLITCH_NOISE}:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff" \
    -c:v mpeg2video -flags +ildct+ilme -top 0 -b:v 8000k -maxrate 9000k -minrate 2000k -bufsize 1835k \
    -an \
    "$OUT_DIR/$GLITCH_OUT"
}

case "$MODE" in
  hunt)
    run_hunt
    echo
    echo "Done. Output files in: $OUT_DIR"
    echo "- hunt.mp4"
    ;;
  crop)
    run_crop
    echo
    echo "Done. Output files in: $OUT_DIR"
    echo "- cropped.mp4"
    ;;
  glitch)
    run_glitch
    echo
    echo "Done. Output files in: $OUT_DIR"
    echo "- $GLITCH_OUT"
    ;;
  dev)
    run_dev
    echo
    echo "Done. Output files in: $OUT_DIR"
    echo "- dev.mpg"
    echo "- dev_guest_ntsc.mp4"
    echo "- dev_royale_kurozumi.mp4"
    ;;
  *)
    echo "Invalid mode: $MODE" >&2
    print_help
    exit 1
    ;;
esac
