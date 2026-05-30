# tests

Test suite for the CRT pipeline scripts.

## Usage

```bash
# From repo root — runs all tests and opens each render in mpv
./scripts/tests/run_tests.sh

# Skip visual mpv inspection
./scripts/tests/run_tests.sh --no-visual
```

Exits non-zero if any assertion fails.

## Tests

- `test_run_hunt` — runs `hunt` mode with lengths 2s, 5s, and 8s; asserts codec, resolution, duration, and no audio on each output.

## Adding tests

Add a `test_<name>()` function following the same pattern:
1. `mktemp -d` for a temp output dir
2. Invoke the script under test with controlled env vars and `OUT_DIR`
3. Assert with `pass`/`fail` helpers
4. Visual inspect with `mpv --no-deinterlace` if `VISUAL=1`
5. `rm -rf "$tmp_dir"`

Then call your function in the runner section at the bottom of `run_tests.sh`.
