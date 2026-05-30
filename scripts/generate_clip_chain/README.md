# generate_clip_chain.sh

Runs the three CRT pipeline primitives and the `dev` composition mode.

## Modes

| Mode | Input | Output | Purpose |
|------|-------|--------|---------|
| `hunt` | pre-cropped file | `hunt.mp4` (960×720 H.264) | Clean scrub preview for scouting transitions |
| `crop` | raw pillarboxed source | `cropped.mp4` (960×720 H.264) | Remove pillarbox, produce intermediate for glitch |
| `glitch` | cropped intermediate | `*.mpg` (720×480 MPEG2) | Full artifact+safety chain → CRT-ready encode |
| `dev` | raw pillarboxed source | `dev.mpg` + 2 shader mp4s | 3-minute crop → glitch → clean + shader-baked preview renders |

All files are written to `./renders` by default.

## Usage

```bash
./scripts/generate_clip_chain/generate_clip_chain.sh [MODE] [INPUT_FILE] [OUTPUT_DIR]
```

## Examples

```bash
# Hunt — scrub preview from a pre-cropped file
./scripts/generate_clip_chain/generate_clip_chain.sh hunt cropped.mp4

# Crop — remove pillarbox from raw source
./scripts/generate_clip_chain/generate_clip_chain.sh crop source.mp4

# Glitch — apply full artifact+safety chain
./scripts/generate_clip_chain/generate_clip_chain.sh glitch cropped.mp4

# Dev — 3-minute crop → glitch → clean + shader renders
./scripts/generate_clip_chain/generate_clip_chain.sh dev source.mp4

# Override timing
HUNT_START=00:10:00 HUNT_LENGTH=30 ./scripts/generate_clip_chain/generate_clip_chain.sh hunt cropped.mp4
CROP_START=00:10:00 CROP_LENGTH=60 ./scripts/generate_clip_chain/generate_clip_chain.sh crop source.mp4
DEV_START=00:22:00 ./scripts/generate_clip_chain/generate_clip_chain.sh dev source.mp4

# Softer noise
GLITCH_NOISE=10 GLITCH_OUT=soft.mpg ./scripts/generate_clip_chain/generate_clip_chain.sh glitch cropped.mp4
GLITCH_NOISE=10 ./scripts/generate_clip_chain/generate_clip_chain.sh dev source.mp4
```

## Help

```bash
./scripts/generate_clip_chain/generate_clip_chain.sh --help
```

## Environment overrides

| Variable | Default | Applies to |
|----------|---------|------------|
| `HUNT_START` | `00:00:00` | hunt |
| `HUNT_LENGTH` | `00:12:00` | hunt |
| `CROP_START` | `00:00:00` | crop |
| `CROP_LENGTH` | `00:12:00` | crop |
| `CROP_FILTER` | `crop=1440:1072:240:4` | crop, dev |
| `GLITCH_OUT` | `glitch.mpg` | glitch |
| `GLITCH_NOISE` | `15` | glitch, dev |
| `DEV_START` | `00:00:00` | dev |
| `DEV_LENGTH` | `180` | dev |
