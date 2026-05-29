# generate_clip_chain.sh

Quick helper script to build the CRT testing clip chain from a single source file.

## What it generates
- `transition_hunt_12m.mp4` (4:3 hunt reel for finding transitions)
- `transition_hunt_glitch.mpg` (hunt reel with full glitch/safety chain)
- `cert_test_60s_glitch.mpg` (60s cert clip, standard noise)
- `cert_test_60s_glitch_soft.mpg` (60s cert clip, softer noise)

All files are written to `./renders` by default.

## Usage
```bash
./scripts/generate_clip_chain/generate_clip_chain.sh [MODE] [INPUT_FILE] [OUTPUT_DIR]
```

`MODE` options:
- `all` (default): run hunt + cert chains
- `hunt`: run transition hunt outputs only
- `cert`: run 60s cert outputs only
- `client`: run hunt chain, then render two shader-baked mp4 artifacts for client review

## Examples
```bash
# Default input/output
./scripts/generate_clip_chain/generate_clip_chain.sh

# Hunt chain only
./scripts/generate_clip_chain/generate_clip_chain.sh hunt

# Cert chain only
./scripts/generate_clip_chain/generate_clip_chain.sh cert

# Cert chain + mp4 review outputs
CERT_RENDER_MP4=1 ./scripts/generate_clip_chain/generate_clip_chain.sh cert

# Client artifact chain (hunt + shader baked mp4 outputs)
./scripts/generate_clip_chain/generate_clip_chain.sh client

# Custom input and output directory
./scripts/generate_clip_chain/generate_clip_chain.sh all theThirdTransmission.mp4 ./renders

# Override cert clip timing
CERT_START=00:22:00 CERT_LENGTH=75 ./scripts/generate_clip_chain/generate_clip_chain.sh cert
```

## Help
```bash
./scripts/generate_clip_chain/generate_clip_chain.sh --help
```

## Environment overrides
- `HUNT_START` (default: `00:00:00`)
- `HUNT_LENGTH` (default: `00:12:00`)
- `CERT_START` (default: `00:10:00`)
- `CERT_LENGTH` (default: `60`)
- `CERT_RENDER_MP4` (default: `0`)
- `CROP_FILTER` (default: `crop=1440:1072:240:4`)
- `SHADER_DIR` (default: `./mpv-retro-shaders-master/crt/shaders`)
- `CLIENT_CRF` (default: `18`)
- `CLIENT_PRESET` (default: `medium`)

## Client mode outputs
When `MODE=client`, the script generates:
- `transition_hunt_12m.mp4`
- `transition_hunt_glitch.mpg`
- `transition_hunt_glitch_guest_ntsc.mp4`
- `transition_hunt_glitch_royale_kurozumi.mp4`
