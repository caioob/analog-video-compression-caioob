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
    [[ -n "$audio_streams" ]] \
      && pass "$prefix audio stream present" \
      || fail "$prefix no audio stream"

    if [[ "$VISUAL" -eq 1 ]]; then
      echo "  Opening $prefix render in mpv..."
      mpv --no-deinterlace "$out"
    fi

    rm -rf "$tmp_dir"
  done
}

test_crop() {
  echo "test_crop"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  # Case 1: default — audio should be present
  CROP_START=00:10:00 CROP_LENGTH=5 \
    "$SCRIPT" crop "$SOURCE" "$tmp_dir"

  local out="$tmp_dir/cropped.mp4"

  if [[ ! -f "$out" ]]; then
    fail "output file missing"
    rm -rf "$tmp_dir"
    return
  fi
  pass "output file exists"

  local codec
  codec=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  [[ "$codec" == "h264" ]] \
    && pass "codec is h264" \
    || fail "codec is '$codec' (expected h264)"

  local width height
  width=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  height=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=height \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  [[ "$width" == "960" && "$height" == "720" ]] \
    && pass "resolution is 960x720" \
    || fail "resolution is ${width}x${height} (expected 960x720)"

  local audio_streams
  audio_streams=$(ffprobe -v error -select_streams a \
    -show_entries stream=codec_type \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  [[ -n "$audio_streams" ]] \
    && pass "audio stream present" \
    || fail "no audio stream"

  if [[ "$VISUAL" -eq 1 ]]; then
    echo "  Opening crop render in mpv..."
    mpv --no-deinterlace "$out"
  fi

  rm -rf "$tmp_dir"
}

test_glitch() {
  echo "test_glitch"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  local synth="$tmp_dir/synth.mp4"
  ffmpeg -y -f lavfi -i "color=c=blue:size=960x720:rate=25:duration=3" \
    -c:v libx264 -preset veryfast "$synth" 2>/dev/null

  "$SCRIPT" glitch "$synth" "$tmp_dir"

  local out="$tmp_dir/glitch.mpg"

  if [[ ! -f "$out" ]]; then
    fail "output file missing"
    rm -rf "$tmp_dir"
    return
  fi
  pass "output file exists"

  local codec
  codec=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  [[ "$codec" == "mpeg2video" ]] \
    && pass "codec is mpeg2video" \
    || fail "codec is '$codec' (expected mpeg2video)"

  local width height
  width=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  height=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=height \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  [[ "$width" == "720" && "$height" == "480" ]] \
    && pass "resolution is 720x480" \
    || fail "resolution is ${width}x${height} (expected 720x480)"

  local field_order
  field_order=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=field_order \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  [[ "$field_order" == "bb" ]] \
    && pass "field_order is bb" \
    || fail "field_order is '$field_order' (expected bb)"

  local audio_streams
  audio_streams=$(ffprobe -v error -select_streams a \
    -show_entries stream=codec_type \
    -of default=noprint_wrappers=1:nokey=1 "$out")
  [[ -z "$audio_streams" ]] \
    && pass "no audio stream" \
    || fail "unexpected audio stream found"

  if [[ "$VISUAL" -eq 1 ]]; then
    echo "  Opening glitch render in mpv..."
    mpv --no-deinterlace "$out"
  fi

  rm -rf "$tmp_dir"
}

test_dev() {
  echo "test_dev"
  local tmp_dir
  tmp_dir=$(mktemp -d)

  DEV_START=00:10:00 DEV_LENGTH=5 \
    "$SCRIPT" dev "$SOURCE" "$tmp_dir"

  # dev.mpg — full glitch assertions
  local mpg="$tmp_dir/dev.mpg"

  if [[ ! -f "$mpg" ]]; then
    fail "dev.mpg missing"
    rm -rf "$tmp_dir"
    return
  fi
  pass "dev.mpg exists"

  local codec
  codec=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=noprint_wrappers=1:nokey=1 "$mpg")
  [[ "$codec" == "mpeg2video" ]] \
    && pass "dev.mpg codec is mpeg2video" \
    || fail "dev.mpg codec is '$codec' (expected mpeg2video)"

  local width height
  width=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width \
    -of default=noprint_wrappers=1:nokey=1 "$mpg")
  height=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=height \
    -of default=noprint_wrappers=1:nokey=1 "$mpg")
  [[ "$width" == "720" && "$height" == "480" ]] \
    && pass "dev.mpg resolution is 720x480" \
    || fail "dev.mpg resolution is ${width}x${height} (expected 720x480)"

  local field_order
  field_order=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=field_order \
    -of default=noprint_wrappers=1:nokey=1 "$mpg")
  [[ "$field_order" == "bb" ]] \
    && pass "dev.mpg field_order is bb" \
    || fail "dev.mpg field_order is '$field_order' (expected bb)"

  local audio_streams
  audio_streams=$(ffprobe -v error -select_streams a \
    -show_entries stream=codec_type \
    -of default=noprint_wrappers=1:nokey=1 "$mpg")
  [[ -z "$audio_streams" ]] \
    && pass "dev.mpg no audio stream" \
    || fail "dev.mpg unexpected audio stream"

  # Shader-baked outputs — file exists + h264 codec
  for name in dev_guest_ntsc dev_royale_kurozumi; do
    local mp4="$tmp_dir/${name}.mp4"
    if [[ ! -f "$mp4" ]]; then
      fail "${name}.mp4 missing"
      continue
    fi
    pass "${name}.mp4 exists"

    local sh_codec
    sh_codec=$(ffprobe -v error -select_streams v:0 \
      -show_entries stream=codec_name \
      -of default=noprint_wrappers=1:nokey=1 "$mp4")
    [[ "$sh_codec" == "h264" ]] \
      && pass "${name}.mp4 codec is h264" \
      || fail "${name}.mp4 codec is '$sh_codec' (expected h264)"
  done

  if [[ "$VISUAL" -eq 1 ]]; then
    echo "  Opening dev.mpg in mpv..."
    mpv --no-deinterlace "$mpg"
  fi

  rm -rf "$tmp_dir"
}

test_run_hunt
test_crop
test_glitch
test_dev

echo
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
