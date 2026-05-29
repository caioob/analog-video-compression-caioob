#!/usr/bin/env bash
set -euo pipefail

# Full clip chain generator for CRT testing workflow.
# Outputs:
# 1) transition_hunt_12m.mp4       (cropped 4:3 hunt reel)
# 2) transition_hunt_glitch.mpg    (full glitch chain)
# 3) cert_test_60s_glitch.mpg      (cert validation clip)
# 4) cert_test_60s_glitch_soft.mpg (optional softer-noise variant)

print_help() {
  cat <<'EOF'
Usage:
  ./generate_clip_chain.sh [MODE] [INPUT_FILE] [OUTPUT_DIR]

Description:
  Generates the full CRT test chain:
  1) transition_hunt_12m.mp4
  2) transition_hunt_glitch.mpg
  3) cert_test_60s_glitch.mpg
  4) cert_test_60s_glitch_soft.mpg

Arguments:
  MODE         Chain to run: all | hunt | cert | client (default: all)
  INPUT_FILE   Source video file (default: theThirdTransmission.mp4)
  OUTPUT_DIR   Output directory (default: ./renders)

Environment overrides:
  HUNT_START   Start time for hunt clip      (default: 00:00:00)
  HUNT_LENGTH  Duration for hunt clip        (default: 00:12:00)
  CERT_START   Start time for cert test clip (default: 00:10:00)
  CERT_LENGTH  Duration for cert test clip   (default: 60)
  CERT_RENDER_MP4 Render cert mp4 outputs    (default: 0)
  CROP_FILTER  Crop expression               (default: crop=1440:1072:240:4)
  SHADER_DIR   mpv shader directory          (default: ./mpv-retro-shaders-master/crt/shaders)
  CLIENT_CRF   CRF for client mp4 outputs    (default: 18)
  CLIENT_PRESET Preset for client outputs    (default: medium)

Examples:
  ./generate_clip_chain.sh
  ./generate_clip_chain.sh hunt
  CERT_RENDER_MP4=1 ./generate_clip_chain.sh cert
  ./generate_clip_chain.sh client
  ./generate_clip_chain.sh theThirdTransmission.mp4 ./renders
  CERT_START=00:22:00 CERT_LENGTH=75 ./generate_clip_chain.sh cert
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_help
  exit 0
fi

MODE="all"
if [[ "${1:-}" == "all" || "${1:-}" == "hunt" || "${1:-}" == "cert" || "${1:-}" == "client" ]]; then
  MODE="$1"
  INPUT_FILE="${2:-theThirdTransmission.mp4}"
  OUT_DIR="${3:-./renders}"
else
  INPUT_FILE="${1:-theThirdTransmission.mp4}"
  OUT_DIR="${2:-./renders}"
fi

# Tunables
HUNT_START="${HUNT_START:-00:00:00}"
HUNT_LENGTH="${HUNT_LENGTH:-00:12:00}"
CERT_START="${CERT_START:-00:10:00}"
CERT_LENGTH="${CERT_LENGTH:-60}"
CERT_RENDER_MP4="${CERT_RENDER_MP4:-0}"

# Crop values detected from source: pillarboxed 4:3 inside 1080p
CROP_FILTER="${CROP_FILTER:-crop=1440:1072:240:4}"
SHADER_DIR="${SHADER_DIR:-./mpv-retro-shaders-master/crt/shaders}"
CLIENT_CRF="${CLIENT_CRF:-18}"
CLIENT_PRESET="${CLIENT_PRESET:-medium}"

mkdir -p "$OUT_DIR"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Input not found: $INPUT_FILE" >&2
  exit 1
fi

run_hunt_chain() {
  echo "[1/2] Building transition hunt clip..."
  ffmpeg -y -ss "$HUNT_START" -i "$INPUT_FILE" -t "$HUNT_LENGTH" \
    -vf "$CROP_FILTER,scale=960:720:flags=neighbor" \
    -c:v libx264 -preset veryfast -crf 18 -an \
    "$OUT_DIR/transition_hunt_12m.mp4"

  echo "[2/2] Applying full glitch chain to hunt clip..."
  ffmpeg -y -i "$OUT_DIR/transition_hunt_12m.mp4" \
    -vf "scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=15:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff" \
    -c:v mpeg2video -flags +ildct+ilme -top 0 -b:v 8000k -maxrate 9000k -minrate 2000k -bufsize 1835k \
    -an \
    "$OUT_DIR/transition_hunt_glitch.mpg"
}

run_cert_chain() {
  echo "[1/2] Building 60s validation clip (standard noise)..."
  ffmpeg -y -ss "$CERT_START" -i "$INPUT_FILE" -t "$CERT_LENGTH" \
    -vf "$CROP_FILTER,scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=15:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff" \
    -c:v mpeg2video -flags +ildct+ilme -top 0 -b:v 8000k -maxrate 9000k -minrate 2000k -bufsize 1835k \
    -an \
    "$OUT_DIR/cert_test_60s_glitch.mpg"

  echo "[2/2] Building 60s validation clip (softer noise)..."
  ffmpeg -y -ss "$CERT_START" -i "$INPUT_FILE" -t "$CERT_LENGTH" \
    -vf "$CROP_FILTER,scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=10:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff" \
    -c:v mpeg2video -flags +ildct+ilme -top 0 -b:v 8000k -maxrate 9000k -minrate 2000k -bufsize 1835k \
    -an \
    "$OUT_DIR/cert_test_60s_glitch_soft.mpg"

  if [[ "$CERT_RENDER_MP4" == "1" ]]; then
    echo "[cert] Rendering mp4 review outputs..."
    ffmpeg -y -i "$OUT_DIR/cert_test_60s_glitch.mpg" \
      -c:v libx264 -preset "$CLIENT_PRESET" -crf "$CLIENT_CRF" -an \
      "$OUT_DIR/cert_test_60s_glitch.mp4"
    ffmpeg -y -i "$OUT_DIR/cert_test_60s_glitch_soft.mpg" \
      -c:v libx264 -preset "$CLIENT_PRESET" -crf "$CLIENT_CRF" -an \
      "$OUT_DIR/cert_test_60s_glitch_soft.mp4"
  fi
}

run_client_chain() {
  local guest_shader royale_shader

  guest_shader="$SHADER_DIR/crt-guest-advanced-ntsc.glsl"
  royale_shader="$SHADER_DIR/crt-royale-kurozumi-intel.glsl"

  run_hunt_chain

  if [[ ! -f "$guest_shader" ]]; then
    echo "Missing shader: $guest_shader" >&2
    exit 1
  fi

  if [[ ! -f "$royale_shader" ]]; then
    echo "Missing shader: $royale_shader" >&2
    exit 1
  fi

  echo "[1/2] Rendering client artifact with Guest Advanced NTSC shader..."
  mpv --no-config --no-audio --no-deinterlace \
    --glsl-shader="$guest_shader" \
    --o="$OUT_DIR/transition_hunt_glitch_guest_ntsc.mp4" \
    --ovc=libx264 \
    --ovcopts=crf="$CLIENT_CRF",preset="$CLIENT_PRESET" \
    "$OUT_DIR/transition_hunt_glitch.mpg"

  echo "[2/2] Rendering client artifact with Royale Kurozumi shader..."
  mpv --no-config --no-audio --no-deinterlace \
    --glsl-shader="$royale_shader" \
    --o="$OUT_DIR/transition_hunt_glitch_royale_kurozumi.mp4" \
    --ovc=libx264 \
    --ovcopts=crf="$CLIENT_CRF",preset="$CLIENT_PRESET" \
    "$OUT_DIR/transition_hunt_glitch.mpg"
}

case "$MODE" in
  all)
    run_hunt_chain
    run_cert_chain
    ;;
  hunt)
    run_hunt_chain
    ;;
  cert)
    run_cert_chain
    ;;
  client)
    run_client_chain
    ;;
  *)
    echo "Invalid mode: $MODE" >&2
    print_help
    exit 1
    ;;
esac

echo
echo "Done. Output files in: $OUT_DIR"
if [[ "$MODE" == "all" || "$MODE" == "hunt" ]]; then
  echo "- transition_hunt_12m.mp4"
  echo "- transition_hunt_glitch.mpg"
fi
if [[ "$MODE" == "all" || "$MODE" == "cert" ]]; then
  echo "- cert_test_60s_glitch.mpg"
  echo "- cert_test_60s_glitch_soft.mpg"
  if [[ "$CERT_RENDER_MP4" == "1" ]]; then
    echo "- cert_test_60s_glitch.mp4"
    echo "- cert_test_60s_glitch_soft.mp4"
  fi
fi
if [[ "$MODE" == "client" ]]; then
  echo "- transition_hunt_12m.mp4"
  echo "- transition_hunt_glitch.mpg"
  echo "- transition_hunt_glitch_guest_ntsc.mp4"
  echo "- transition_hunt_glitch_royale_kurozumi.mp4"
fi
