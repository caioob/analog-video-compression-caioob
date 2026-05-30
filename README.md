# analog-video-compression

A 1-hour looping glitch-video art installation targeting:

**Linux PC (DEV)** → **Nintendo Wii + WiiMC-SS (CERT)** → **480i composite → CRT TV (PROD)**

## Pipeline

| Stage | Environment | Purpose |
|-------|-------------|---------|
| DEV | Linux + FFmpeg + mpv | Render and inspect test clips |
| CERT | WiiMC-SS via USB (exFAT/NTFS) | Validate on actual Wii hardware |
| PROD | Wii → 480i composite → CRT | Final all-night loop |

Always execute stages sequentially: DEV → CERT → PROD.

## Modes

| Mode | What it does | Output |
|------|-------------|--------|
| `hunt` | Clean 960×720 scrub preview from a pre-cropped file | `hunt.mp4` |
| `crop` | Removes 1080p pillarbox, scales to 960×720 intermediate | `cropped.mp4` |
| `glitch` | Full artifact+safety chain → CRT-ready MPEG2 | `*.mpg` |
| `dev` | 3-minute crop → glitch → clean MPEG2 + 2 shader-baked previews | `dev.mpg`, `dev_guest_ntsc.mp4`, `dev_royale_kurozumi.mp4` |

## Quick start

```bash
# DEV review render — crop 3 minutes, glitch, preview with and without CRT shaders
./scripts/generate_clip_chain/generate_clip_chain.sh dev source.mp4

# Custom start time
DEV_START=00:22:00 ./scripts/generate_clip_chain/generate_clip_chain.sh dev source.mp4

# Inspect output — always clean pass first
mpv --no-deinterlace renders/dev.mpg
mpv --no-deinterlace --glsl-shader="./mpv-retro-shaders-master/crt-guest-advanced-ntsc.glsl" renders/dev.mpg
```

## Source material

`theThirdTransmission.mp4` — ~9GB, 1-hour 1080p H.264. Contains a mix of native 1080p and legacy 2000s upscaled clips. Crop filter `crop=1440:1072:240:4` removes the pillarbox from the 4:3 content inside the 1080p wrapper.

## Tests

```bash
./scripts/tests/run_tests.sh --no-visual   # headless
./scripts/tests/run_tests.sh               # with mpv visual inspection
```

Covers all three primitives and the `dev` composition mode.

## Repository structure

```
scripts/
  generate_clip_chain/   # main pipeline script
  tests/                 # test suite
notes/                   # versioned specs and operational runbooks
mpv-retro-shaders-master/ # CRT preview shaders (monitor-only)
renders/                 # script output (gitignored)
```

See `scripts/README.md` for the scripts index and `notes/README.md` for the notes index.
