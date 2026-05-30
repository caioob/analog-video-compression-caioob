#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/generate_clip_chain/generate_clip_chain.sh"
SOURCE="$REPO_ROOT/theThirdTransmission.mp4"
PASS=0
FAIL=0
VISUAL=1

[[ "${1:-}" == "--no-visual" ]] && VISUAL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

test_run_hunt() {
  echo "test_run_hunt"
  for len in 2 5 8; do
    local prefix="[len=${len}s]"
    local tmp_dir
    tmp_dir=$(mktemp -d)

    HUNT_START=00:10:00 HUNT_LENGTH=$len \
      "$SCRIPT" hunt "$SOURCE" "$tmp_dir"

    local out="$tmp_dir/hunt.mp4"

    if [[ ! -f "$out" ]]; then
      fail "$prefix output file missing"
      rm -rf "$tmp_dir"
      continue
    fi
    pass "$prefix output file exists"

    local codec
    codec=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=codec_name \
      -of default=noprint_wrappers=1:nokey=1 "$out")
    [[ "$codec" == "h264" ]] \
      && pass "$prefix codec is h264" \
      || fail "$prefix codec is '$codec' (expected h264)"

    local width height
    width=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=width \
      -of default=noprint_wrappers=1:nokey=1 "$out")
    height=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=height \
      -of default=noprint_wrappers=1:nokey=1 "$out")
    [[ "$width" == "960" && "$height" == "720" ]] \
      && pass "$prefix resolution is 960x720" \
      || fail "$prefix resolution is ${width}x${height} (expected 960x720)"

    local duration dur_rounded lo hi
    duration=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=duration \
      -of default=noprint_wrappers=1:nokey=1 "$out")
    dur_rounded="${duration%%.*}"
    lo=$(( len - 1 ))
    hi=$(( len + 1 ))
    [[ "$dur_rounded" -ge "$lo" && "$dur_rounded" -le "$hi" ]] \
      && pass "$prefix duration ~${len}s (got ${duration}s)" \
      || fail "$prefix duration ${duration}s out of range [${lo}s, ${hi}s]"

    local audio_streams
    audio_streams=$(ffprobe -v error -select_streams a \
      -show_entries stream=codec_type \
      -of default=noprint_wrappers=1:nokey=1 "$out")
    [[ -z "$audio_streams" ]] \
      && pass "$prefix no audio stream" \
      || fail "$prefix unexpected audio stream found"

    if [[ "$VISUAL" -eq 1 ]]; then
      echo "  Opening $prefix render in mpv..."
      mpv --no-deinterlace "$out"
    fi

    rm -rf "$tmp_dir"
  done
}

test_run_hunt

echo
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
