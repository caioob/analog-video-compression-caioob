# v6 Path Audit

Audit of all path references in `scripts/generate_clip_chain/generate_clip_chain.sh` and `scripts/tests/run_tests.sh`. Each finding is rated by severity: **low** (cosmetic / unlikely to cause real problems), **medium** (will break under realistic conditions).

---

## generate_clip_chain.sh

### 1. `OUT_DIR` defaults to `./renders` — CWD-relative (medium)

```bash
OUT_DIR="${3:-./renders}"
```

If the script is called from any directory other than the repo root, renders land in that directory's `renders/` subfolder, not the repo's. No error is shown — it silently creates the wrong directory.

**Affected modes:** all  
**Fix:** resolve to absolute on assignment, or document that callers must pass an explicit `OUT_DIR`.

---

### 2. Shader path uses unresolved `../../` segments (low)

```bash
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
local shader_dir="$script_dir/../../mpv-retro-shaders-master"
```

`script_dir` is correctly canonicalized, but `shader_dir` is not — it retains `../../` in the string. This works in practice because the OS resolves it at access time, but tools that inspect the path string (logging, error messages) will show the unresolved form. It also breaks silently if the script is ever moved to a different depth within the repo.

**Fix:** wrap in `$(cd "$script_dir/../../mpv-retro-shaders-master" && pwd)` to canonicalize.

---

### 3. `tmp_crop` hardcoded to `/tmp` (low)

```bash
tmp_crop=$(mktemp /tmp/dev_crop_XXXXXX.mp4)
```

`/tmp` is hardcoded. On macOS, `/tmp` is a symlink to `/private/tmp`, which can cause path mismatches in some tools. On Linux this is fine. The project targets Linux only, so this is low risk — but `mktemp` without a path prefix would use `$TMPDIR` automatically and be more portable.

**Fix:** `mktemp --suffix=.mp4` (no explicit `/tmp` prefix).

---

### 4. `INPUT_FILE` and `OUT_DIR` are CWD-relative when not absolute (low, by design)

Both are accepted as-is from the caller. If a user passes a relative path, it resolves from wherever the script was invoked. This is standard shell behavior and is expected — the mandatory `INPUT_FILE` check at line 72 catches missing files but not path confusion.

**No fix needed** — document in help text that absolute paths are recommended for non-interactive use.

---

## run_tests.sh

### 5. All paths correctly anchored (no issues)

| Variable | How resolved | Status |
|----------|-------------|--------|
| `REPO_ROOT` | `cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd` | absolute, correct |
| `SCRIPT` | `$REPO_ROOT/...` | absolute |
| `SOURCE` | `$REPO_ROOT/...` | absolute |
| `tmp_dir` | `mktemp -d` | absolute (system temp) |
| Output paths | `$tmp_dir/filename` | absolute |
| mpv playback | `$out` / `$mpg` — both `$tmp_dir/...` | absolute |

No path issues found in the test runner.

---

## Summary

| # | Location | Issue | Severity |
|---|----------|-------|----------|
| 1 | `generate_clip_chain.sh:48,51` | `OUT_DIR` defaults to CWD-relative `./renders` | medium |
| 2 | `generate_clip_chain.sh:96` | Shader path not canonicalized (`../../` retained) | low |
| 3 | `generate_clip_chain.sh:108` | `tmp_crop` hardcoded to `/tmp` | low |
| 4 | `generate_clip_chain.sh` | Relative `INPUT_FILE`/`OUT_DIR` silently resolve from CWD | low (by design) |
| 5 | `run_tests.sh` | No issues | — |
