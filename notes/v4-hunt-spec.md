# v4 Hunt Spec

Specifies the behavior and test contract for the `hunt` primitive.

## What hunt does

Extracts a time window from a pre-cropped intermediate and produces a clean 960×720 H.264 preview. No pillarbox removal, no glitch chain applied. Used for scrubbing through cropped footage to find transitions before committing to a glitch render.

Hunt expects its input to already have the pillarbox removed (i.e. output of `crop`). Feeding it the raw source produces a preview with pillarbox intact.

## Parameterization

- `HUNT_START` (default: `00:00:00`) — seek position in the input file.
- `HUNT_LENGTH` (default: `00:12:00`) — duration of the output clip.

## Output contract

| Property | Required value |
|----------|---------------|
| File | `$OUT_DIR/hunt.mp4` |
| Resolution | 960×720 |
| Codec | h264 |
| Audio | copied from source |

## Test assertions for `test_run_hunt`

The `test_run_hunt` function in `run_tests.sh` asserts at three durations (2s, 5s, 8s):

1. Output file `hunt.mp4` exists
2. Codec is `h264`
3. Resolution is `960×720`
4. Duration is within ±1s of requested length
5. Audio stream is present

## Invocation

```bash
# Default: hunt from 00:00:00 for 12 minutes
./scripts/generate_clip_chain/generate_clip_chain.sh hunt renders/cropped.mp4

# Custom time window
HUNT_START=00:10:00 HUNT_LENGTH=30 ./scripts/generate_clip_chain/generate_clip_chain.sh hunt renders/cropped.mp4

# Custom output directory
./scripts/generate_clip_chain/generate_clip_chain.sh hunt renders/cropped.mp4 ./renders
```
