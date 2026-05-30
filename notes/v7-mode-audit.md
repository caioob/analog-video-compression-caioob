# v7 Mode Inconsistency Audit

Audit of mode references across all scripts, READMEs, and CLAUDE.md. Each finding includes its fix status.

---

## Finding 1 — `scripts/README.md` missing `dev` (medium) — fixed

```
generate_clip_chain/ - Runs the three pipeline primitives: hunt, crop, and glitch.
```

`dev` was added after this line was written and never included. Fixed by updating the description to include the dev composition mode.

---

## Finding 2 — CLAUDE.md Inspection Commands reference a non-existent file (medium) — fixed

All three `mpv` commands and `ffprobe` in the Inspection Commands section pointed to `renders/transition_hunt_glitch.mpg`. That filename is not produced by any current mode:

| Mode | Output |
|------|--------|
| hunt | `hunt.mp4` |
| crop | `cropped.mp4` |
| glitch | `$GLITCH_OUT` (default: `glitch.mpg`) |
| dev | `dev.mpg`, `dev_guest_ntsc.mp4`, `dev_royale_kurozumi.mp4` |

Fixed by updating Inspection Commands to use `dev.mpg`, which is the natural DEV-stage inspection target.

---

## Finding 3 — `CROP_FILTER` not attributed to `dev` in generate_clip_chain README (low) — fixed

The env var table listed `CROP_FILTER` as applying only to `crop`. `dev` uses it internally for its crop step — the same way `GLITCH_NOISE` is correctly listed as "glitch, dev". Fixed by updating the Applies to column to "crop, dev".

---

## Finding 4 — Implicit `hunt` invocation removed (medium) — fixed

The script previously accepted `./generate_clip_chain.sh source.mp4` with no MODE arg, silently defaulting to hunt. This was invisible — no example or help text showed this form — and inconsistent with the explicit-argument design enforced for INPUT_FILE.

Fixed by removing the fallback `else` branch. MODE is now required; omitting it prints a clear error and the help text.

---

## Summary

| # | Location | Issue | Severity | Status |
|---|----------|-------|----------|--------|
| 1 | `scripts/README.md` | `dev` omitted from description | medium | fixed |
| 2 | `CLAUDE.md` Inspection Commands | Referenced `transition_hunt_glitch.mpg` (non-existent) | medium | fixed |
| 3 | `scripts/generate_clip_chain/README.md` env table | `CROP_FILTER` not attributed to `dev` | low | fixed |
| 4 | `generate_clip_chain.sh` | Implicit `hunt` invocation removed | medium | fixed |
