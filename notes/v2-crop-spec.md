# v2 Crop Spec

Specifies the behavior and test contract for the `crop` primitive.

## What crop does

Removes the pillarbox wrapper from a 4:3 source that has been letterboxed or pillarboxed into a larger container (e.g. 4:3 content inside a 1080p wrapper), then downscales to the 960×720 intermediate format expected by `glitch`.

The content is always assumed to be 4:3. The wrapper resolution varies by source and is controlled via `CROP_FILTER`.

## Parameterization

`CROP_FILTER` (default: `crop=1440:1072:240:4`) encodes both the wrapper geometry and the crop geometry in one FFmpeg crop expression:

```
crop=W:H:X:Y
```

- `W:H` — width and height of the 4:3 content region to keep
- `X:Y` — offset from the top-left of the wrapper frame

The default targets `theThirdTransmission.mp4`: a 1920×1080 container with 4:3 content centered at 240px from left, 4px from top, spanning 1440×1072.

To adapt to a different wrapper resolution, override `CROP_FILTER` — the 4:3 assumption stays, only the geometry changes.

After cropping, the filter chain always appends `,scale=960:720:flags=neighbor` regardless of `CROP_FILTER`, so the output resolution is fixed at 960×720.

## Output contract

| Property | Required value |
|----------|---------------|
| File | `$OUT_DIR/cropped.mp4` |
| Resolution | 960×720 |
| Codec | h264 |
| Audio | copied from source by default; stripped when `CROP_NO_AUDIO=1` |

## Test assertions for `test_crop`

The `test_crop` function in `run_tests.sh` must assert:

1. Output file `$tmp_dir/cropped.mp4` exists
2. Codec is `h264`
3. Resolution is `960×720` (not 720×480 — that is glitch's output, not crop's)
4. Audio stream is present (default behavior)
5. With `CROP_NO_AUDIO=1`: no audio stream

Duration assertion is optional; crop clips are long enough that short timing drift is irrelevant.

**Note:** The planned coverage table in CLAUDE.md lists `720×480` as the expected resolution for `test_crop`. That is wrong — 720×480 is the glitch output. The correct assertion is `960×720`.

## Invocation

```bash
# Default: crops theThirdTransmission.mp4 starting at 00:00:00 for 12 minutes, audio kept
./scripts/generate_clip_chain/generate_clip_chain.sh crop

# Custom window
CROP_START=00:10:00 CROP_LENGTH=60 ./scripts/generate_clip_chain/generate_clip_chain.sh crop

# Strip audio
CROP_NO_AUDIO=1 ./scripts/generate_clip_chain/generate_clip_chain.sh crop

# Different wrapper geometry
CROP_FILTER="crop=1280:960:0:60" ./scripts/generate_clip_chain/generate_clip_chain.sh crop
```
