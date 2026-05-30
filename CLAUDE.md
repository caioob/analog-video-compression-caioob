# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A 1-hour looping glitch-video art installation targeting: **Linux PC (DEV)** → **Nintendo Wii + WiiMC-SS (CERT)** → **480i composite → CRT TV (PROD)**.

**Top priority: CRT preservation above all aesthetic decisions.** Any glitch choice that conflicts with burn-in risk, flyback stress, or legal luma range must be dropped in favor of safety.

## Pipeline Stages

| Stage | Environment | Purpose |
|-------|-------------|---------|
| DEV | Linux + FFmpeg + mpv | Render and inspect test clips |
| CERT | WiiMC-SS via USB (exFAT/NTFS) | Validate on actual Wii hardware |
| PROD | Wii → 480i composite → CRT | Final all-night loop |

Always execute phases sequentially: DEV → CERT → PROD. Do not tweak multiple variables at once between stages.

## Core FFmpeg Filter Chain

The canonical glitch+protection chain applied to every `.mpg` render:

```
scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=15:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff
```

- `flags=neighbor` — Nearest Neighbor downscale preserves legacy compression artifacts.
- `eq=contrast=0.85:brightness=-0.05` — Attenuates signal to prevent tube blooming.
- `lutyuv=y='clip(val,16,235)'` — Clamps luma to legal broadcast range (no 100% IRE peaks).
- `noise=alls=15:allf=t+u` — Dynamic grain prevents phosphor burn-in on static elements.
- `tinterlace=mode=interleave_top,fieldorder=bff` — Mismatched field order creates the intentional horizontal combing artifact.

Output codec flags: `-c:v mpeg2video -flags +ildct+ilme -top 0 -b:v 8000k -maxrate 9000k -minrate 2000k -bufsize 1835k`

Softer noise variant: set `GLITCH_NOISE=10` (default is 15).

## Main Script

```bash
# Hunt reel — clean 960×720 preview from a pre-cropped file
./scripts/generate_clip_chain/generate_clip_chain.sh hunt cropped.mp4

# Crop — remove 1080p pillarbox and produce 960×720 intermediate
./scripts/generate_clip_chain/generate_clip_chain.sh crop

# Glitch — full artifact+safety chain → MPEG2
INPUT_FILE=renders/cropped.mp4 ./scripts/generate_clip_chain/generate_clip_chain.sh glitch

# Dev — 3-minute crop → glitch → dev.mpg + 2 shader-baked mp4s
./scripts/generate_clip_chain/generate_clip_chain.sh dev

# Override timing / noise
HUNT_START=00:10:00 HUNT_LENGTH=30 ./scripts/generate_clip_chain/generate_clip_chain.sh hunt cropped.mp4
CROP_START=00:10:00 CROP_LENGTH=60 ./scripts/generate_clip_chain/generate_clip_chain.sh crop
GLITCH_NOISE=10 GLITCH_OUT=soft.mpg ./scripts/generate_clip_chain/generate_clip_chain.sh glitch
DEV_START=00:22:00 GLITCH_NOISE=10 ./scripts/generate_clip_chain/generate_clip_chain.sh dev
```

Default input: `theThirdTransmission.mp4`. Default output: `./renders/`.

Environment overrides: `HUNT_START`, `HUNT_LENGTH`, `CROP_START`, `CROP_LENGTH`, `CROP_FILTER`, `GLITCH_OUT`, `GLITCH_NOISE`, `DEV_START`, `DEV_LENGTH`.

## Inspection Commands

Always run the **clean truth check first** before enabling any shader:

```bash
# 1. Raw field behavior check (required first)
mpv --no-deinterlace "renders/transition_hunt_glitch.mpg"

# 2. Composite-like CRT preview on modern monitor
mpv --no-deinterlace --glsl-shader="./mpv-retro-shaders-master/crt-guest-advanced-ntsc.glsl" "renders/transition_hunt_glitch.mpg"

# 3. Second aesthetic reference
mpv --no-deinterlace --glsl-shader="./mpv-retro-shaders-master/crt-royale-kurozumi-intel.glsl" "renders/transition_hunt_glitch.mpg"

# Stream/field metadata
ffprobe -hide_banner -select_streams v:0 -show_streams renders/transition_hunt_glitch.mpg
```

Shaders are preview-only for modern monitor review. Technical decisions (field order, combing) must be made from the clean pass.

## Source Material

- `theThirdTransmission.mp4` — ~9GB, 1-hour 1080p H.264 source. Contains a mix of native 1080p and legacy 2000s upscaled clips.
- Crop filter `crop=1440:1072:240:4` removes pillarbox from the 4:3 content inside the 1080p wrapper before downscaling.

## Pipeline Primitives

Three primitives and one composition mode:

| Mode | What it does | Output |
|------|-------------|--------|
| **hunt** | Time extraction + scale + H.264 encode. Clean scrub preview — no crop, no glitch. Expects pre-cropped input. | `hunt.mp4` |
| **crop** | Removes 1080p pillarbox from 4:3 content, scales to 960×720 intermediate. | `cropped.mp4` |
| **glitch** | Full artifact+safety chain (eq, lutyuv, noise, tinterlace) → MPEG2 encode. | `*.mpg` |
| **dev** | Composition: 3-minute crop → glitch → clean MPEG2 + 2 shader-baked H.264 previews. | `dev.mpg`, `dev_guest_ntsc.mp4`, `dev_royale_kurozumi.mp4` |

## Test Suite

```bash
# Run all tests with visual mpv inspection
./scripts/tests/run_tests.sh

# Skip visual inspection (headless / CI)
./scripts/tests/run_tests.sh --no-visual
```

Exits non-zero if any assertion fails.

### Current coverage

| Test | Primitive | Asserts |
|------|-----------|---------|
| `test_run_hunt` | hunt | codec h264, resolution 960×720, duration ±1s, audio stream present (tested at 2s, 5s, 8s) |
| `test_crop` | crop | output resolution 960×720, audio stream present |
| `test_glitch` | glitch | codec mpeg2video, resolution 720×480, field_order bb, no audio |
| `test_dev` | dev | dev.mpg: mpeg2video, 720×480, field_order bb, no audio; shader mp4s: h264, file exists |

### Adding a test

Add a `test_<name>()` function in `run_tests.sh`: `mktemp -d` for output, invoke the script with controlled env vars, assert with `pass`/`fail` helpers, visual-inspect with `mpv --no-deinterlace` if `VISUAL=1`, then `rm -rf "$tmp_dir"`. Call the function at the bottom of the file.

## Repository Conventions

- All scripts live under `scripts/`, one subdirectory per script.
- Each script subdirectory requires a `README.md` with usage, examples, and outputs.
- `scripts/README.md` is the index — update it when adding or removing scripts.
- Notes in `notes/` follow the versioning convention `vX-topic.md`; never overwrite old versions, add new ones.
