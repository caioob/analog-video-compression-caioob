# v3 Glitch Spec

Specifies the behavior and test contract for the `glitch` primitive.

## What glitch does

Applies the full artifact+safety filter chain to a 960×720 intermediate (crop output) and encodes it as an interlaced MPEG2 stream suitable for Wii playback via composite to CRT.

Every filter step serves a CRT safety or aesthetic purpose — none are optional.

## Filter chain

```
scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=<NOISE>:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff
```

| Filter | Purpose |
|--------|---------|
| `scale=720:480:flags=neighbor` | Downscale to 480i target; nearest-neighbor preserves compression artifacts |
| `eq=contrast=0.85:brightness=-0.05` | Attenuates signal to prevent tube blooming |
| `lutyuv=y='clip(val,16,235)'` | Clamps luma to legal broadcast range — no 100% IRE peaks |
| `noise=alls=<N>:allf=t+u` | Dynamic grain prevents phosphor burn-in on static elements |
| `tinterlace=mode=interleave_top,fieldorder=bff` | Mismatched field order creates the intentional horizontal combing artifact |

## Parameterization

- `GLITCH_NOISE` (default: `15`) — noise intensity. `10` produces a softer variant.
- `GLITCH_OUT` (default: `glitch.mpg`) — output filename inside `$OUT_DIR`.

## Output contract

| Property | Required value |
|----------|---------------|
| File | `$OUT_DIR/$GLITCH_OUT` |
| Resolution | 720×480 |
| Codec | mpeg2video |
| Field order | bb (bottom-bottom — proves tinterlace fired) |
| Audio | none (always stripped) |

## Test assertions for `test_glitch`

The `test_glitch` function in `run_tests.sh` must assert:

1. Output file exists
2. Codec is `mpeg2video`
3. Resolution is `720×480`
4. `field_order` is `bb` (proves tinterlace fired)
5. No audio stream

The field order check is the critical assertion — it proves the full tinterlace+fieldorder filter chain executed correctly.

## Invocation

```bash
# Default: glitch renders/cropped.mp4 → renders/glitch.mpg
INPUT_FILE=renders/cropped.mp4 ./scripts/generate_clip_chain/generate_clip_chain.sh glitch

# Or via positional arg
./scripts/generate_clip_chain/generate_clip_chain.sh glitch renders/cropped.mp4

# Softer noise variant
GLITCH_NOISE=10 GLITCH_OUT=soft.mpg ./scripts/generate_clip_chain/generate_clip_chain.sh glitch renders/cropped.mp4
```
