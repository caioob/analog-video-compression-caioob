# Director Cut Execution Plan (CRT Safety First)

This plan is for the CRT glitch-video pipeline and keeps one rule above all others: **protect the CRT first, aesthetics second**.

## Objective
- Build a 1-hour looping video for Wii -> 480i composite -> CRT.
- Preserve aggressive combing/glitch style while staying within hardware-safe signal behavior.

## Priority Rules
- CRT preservation is non-negotiable.
- Any glitch choice must stay inside safe limits for burn-in risk, flyback stress, and legal luma range.
- If a visual choice conflicts with safety, choose safety.

## Phase 1 - DEV (Linux)
1. Install tools (`ffmpeg`, `mpv`, exFAT/NTFS support).
2. Render a 60s test from `input.mp4`.
3. Verify metadata and field behavior.
4. Visually inspect combing/jitter and highlight safety.

### Install commands
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y ffmpeg mpv exfat-fuse exfatprogs ntfs-3g

# Fedora
sudo dnf install -y ffmpeg mpv exfatprogs fuse-exfat ntfs-3g

# Arch
sudo pacman -S --needed ffmpeg mpv exfatprogs ntfs-3g
```

### 60-second test render
```bash
ffmpeg -ss 00:10:00 -i input.mp4 -t 60 \
-vf "scale=720:480:flags=neighbor,eq=contrast=0.85:brightness=-0.05,lutyuv=y='clip(val,16,235)',noise=alls=15:allf=t+u,tinterlace=mode=interleave_top,fieldorder=bff" \
-c:v mpeg2video -flags +ildct+ilme -top 0 -b:v 8000k -maxrate 9000k -minrate 2000k -bufsize 1835k \
-c:a mp2 -b:a 192k -ar 48000 \
dev_test.mpg
```

### Verification commands
```bash
# Stream and field metadata
ffprobe -hide_banner -select_streams v:0 -show_streams dev_test.mpg

# Raw interlace/combing preview (no deinterlace)
mpv --no-deinterlace dev_test.mpg
```

## Phase 2 - CERT (WiiMC-SS)
1. Copy `dev_test.mpg` to USB (exFAT or NTFS).
2. Play on WiiMC-SS.
3. Confirm decode stability and intended motion artifacts.
4. Watch for unsafe behavior (extreme bloom, strong retention patterns, unstable output).

## Phase 3 - PROD (Final 1-hour loop)
1. Render full-length master with validated settings.
2. Run extended loop test on CRT.
3. If needed, reduce contrast/noise intensity before final deployment.

## Quick Go/No-Go Checklist
- Test file renders cleanly.
- Field/interlace behavior matches expectation.
- Combing appears on motion and noise is dynamic.
- No obvious unsafe signal behavior in highlights/static regions.
- WiiMC-SS playback is stable from USB.
- Full loop survives extended CRT playback.

## Focus protocol (anti-digression)
- Execute one phase at a time: DEV -> CERT -> PROD.
- Do not tweak multiple variables at once.
- After each phase, record pass/fail and the next concrete action.
