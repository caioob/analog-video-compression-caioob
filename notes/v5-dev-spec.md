# v5 Dev Spec

Specifies the behavior and output contract for the `dev` mode.

## What dev does

Composes the three primitives into a single DEV-stage review render:

1. **crop** — extract 3 minutes from the raw source, remove pillarbox → 960×720 H.264 intermediate
2. **glitch** — apply the full artifact+safety chain → 720×480 MPEG2
3. **render ×3** — produce one clean output and two shader-baked mp4 previews for monitor review

The clean output is the ground truth for technical decisions (field order, combing). The shader outputs are aesthetic references only.

## Outputs

All written to `$OUT_DIR` (default: `./renders`):

| File | Description |
|------|-------------|
| `dev.mpg` | Raw glitch output — no shader, ground truth |
| `dev_guest_ntsc.mp4` | Baked with `crt-guest-advanced-ntsc.glsl` |
| `dev_royale_kurozumi.mp4` | Baked with `crt-royale-kurozumi-intel.glsl` |

The intermediate crop file is not kept.

## Parameterization

- `DEV_START` (default: `00:00:00`) — seek position in the raw source.
- `DEV_LENGTH` (default: `180`) — duration in seconds (3 minutes).
- `CROP_FILTER` (default: `crop=1440:1072:240:4`) — pillarbox removal geometry.
- `GLITCH_NOISE` (default: `15`) — noise intensity passed to the glitch chain.

## Shader paths

Shaders are resolved from `./mpv-retro-shaders-master/`:
- `crt-guest-advanced-ntsc.glsl`
- `crt-royale-kurozumi-intel.glsl`

The script must verify both shader files exist before starting and exit with an error if either is missing.

## Invocation

```bash
# Default: 3 minutes from 00:00:00
./scripts/generate_clip_chain/generate_clip_chain.sh dev

# Custom window
DEV_START=00:22:00 ./scripts/generate_clip_chain/generate_clip_chain.sh dev

# Softer noise
GLITCH_NOISE=10 ./scripts/generate_clip_chain/generate_clip_chain.sh dev
```

## Inspection order

Always inspect in this order — same rule as the core pipeline:

1. `dev.mpg` — clean truth check (`mpv --no-deinterlace`)
2. `dev_guest_ntsc.mp4` — composite-like CRT feel
3. `dev_royale_kurozumi.mp4` — second aesthetic reference

## Relation to primitives

`dev` is a composition, not a primitive. It is not independently testable without the full source file and shaders. Primitive-level correctness is verified by `test_crop` and `test_glitch`.
