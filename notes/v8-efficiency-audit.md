# v8 Efficiency Audit

Audit of unnecessary work in `scripts/generate_clip_chain/generate_clip_chain.sh`. FFmpeg filter chain parameters (eq, lutyuv, noise, tinterlace, codec flags, presets) are intentional design decisions and are out of scope. Each finding includes a severity and fix status.

---

## Finding 1 — Sequential mpv shader renders (medium) — fixed

`run_dev()` runs its two shader-baked renders back to back:

```bash
echo "[3/4] Rendering with Guest Advanced NTSC shader..."
mpv ... --o="$OUT_DIR/dev_guest_ntsc.mp4" "$OUT_DIR/dev.mpg"

echo "[4/4] Rendering with Royale Kurozumi shader..."
mpv ... --o="$OUT_DIR/dev_royale_kurozumi.mp4" "$OUT_DIR/dev.mpg"
```

Both steps read the same `dev.mpg` and write to separate output files with no dependency on each other. Running them sequentially doubles the shader render time when they could overlap.

**Fix sketch:** launch step 3 in the background, run step 4 in the foreground, then `wait`:

```bash
mpv ... --o="$OUT_DIR/dev_guest_ntsc.mp4" "$OUT_DIR/dev.mpg" &
mpv ... --o="$OUT_DIR/dev_royale_kurozumi.mp4" "$OUT_DIR/dev.mpg"
wait
```

**Caveat:** on GPU-bound rendering (hardware-accelerated GLSL) this is a clear win — roughly halves the combined render time. On CPU-bound systems both processes compete for the same cores; on low-core-count or already-saturated hardware the gain may be neutral or slightly negative.

**Affected modes:** dev

---

## Finding 2 — `mkdir -p` runs before input file validation (low) — fixed

```bash
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Input not found: $INPUT_FILE" >&2
  exit 1
fi
```

When `INPUT_FILE` is missing the script exits with an error, but the output directory has already been created as a side effect. On the default path this leaves a `./renders/` directory behind with no output in it.

**Fix sketch:** move the input file check above `mkdir -p`:

```bash
if [[ ! -f "$INPUT_FILE" ]]; then
  echo "Input not found: $INPUT_FILE" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
```

**Affected modes:** all

---

## Summary

| # | Location | Issue | Severity | Status |
|---|----------|-------|----------|--------|
| 1 | `run_dev()` lines 127–141 | Shader renders sequential despite being independent | medium | fixed |
| 2 | `generate_clip_chain.sh` lines 70–76 | `mkdir -p` runs before input validation | low | fixed |
