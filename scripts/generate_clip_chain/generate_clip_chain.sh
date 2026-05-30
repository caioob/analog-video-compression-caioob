#!/usr/bin/env bash
set -euo pipefail

print_help() {
  cat <<'EOF'
Usage:
  ./generate_clip_chain.sh [MODE] [INPUT_FILE] [OUTPUT_DIR]

Arguments:
  MODE         Primitive to run: hunt | crop | glitch (default: hunt)
               hunt  — expects a pre-cropped file as INPUT_FILE
               crop  — removes pillarbox and scales to 960x720 intermediate
               glitch — applies artifact+safety chain, encodes MPEG2
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

Examples:
  ./generate_clip_chain.sh hunt cropped.mp4
  HUNT_START=00:10:00 HUNT_LENGTH=30 ./generate_clip_chain.sh hunt cropped.mp4
  CROP_START=00:10:00 CROP_LENGTH=60 ./generate_clip_chain.sh crop
  INPUT_FILE=renders/cropped.mp4 GLITCH_OUT=out.mpg ./generate_clip_chain.sh glitch
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

MODE="hunt"
if [[ "${1:-}" == "hunt" || "${1:-}" == "crop" || "${1:-}" == "glitch" ]]; then
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
  *)
    echo "Invalid mode: $MODE" >&2
    print_help
    exit 1
    ;;
esac
