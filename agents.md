# Context: Retro Digital-to-Analog Distortion Video Installation (Optimized for CRT Longevity)

I am building a 1-hour looping video installation for a party. The target hardware platform is a softmodded Nintendo Wii outputting a native analog 480i interlaced signal via Composite/RCA cables to a physical CRT monitor. 

CRT preservation is the top priority. All glitch or aesthetic decisions are valid only when they remain within hardware-safe limits for burn-in risk, flyback stress, and legal signal range.

The goal is to achieve an intentional, aggressive horizontal "combing" and motion ghosting aesthetic using a "Mismatched Field Order" compression exploit, while simultaneously injecting protective signal constraints to prevent CRT burn-in and flyback stress during a whole-night loop. Gemini is serving as the information/strategy architect, and you are the execution/coding agent.

## ⚠️ Current Environment State (IMPORTANT)
We are starting completely from scratch. No environments or tools are ready yet:
- The Linux PC is a clean system (no specific video tools, libraries, or extra filesystems are installed yet).
- The Nintendo Wii is completely stock/factory settings (unmodded, no Homebrew Channel, no media players installed).
- The external storage media is currently unformatted/blank.

## System Infrastructure
- **DEV (Development):** Linux PC running FFmpeg and `mpv` for local preview/emulation.
- **CERT (Certification):** Nintendo Wii running WiiMC-SS (Media Centre) loading files from an exFAT or NTFS formatted USB drive to bypass the 4GB file limit.
- **PROD (Production):** The final installation setup (Wii -> 480i Composite -> CRT TV).

## Repository Script Documentation Rule (Mandatory)
- All executable scripts must live under `scripts/`.
- Each script must have its own directory under `scripts/`.
- Each script directory must include a `README.md` that documents usage, examples, and outputs.
- `scripts/README.md` is the index and must be updated whenever a script is added or removed.

## Source Material Constraints
- **File Size:** ~9GB raw file containing a 1-hour playback loop.
- **Video Profile:** 1080p H.264 wrapper.
- **Content:** A compilation of multiple video clips. Some are native 1080p, while many are legacy 2000s video clips with low-res digital compression blocks already "baked" into the 1080p upscale. 

## The Glitch & Protection Strategy (Insights from Architecture Review)
1. **Downscale:** Scale the 1080p wrapper to standard definition (720x480 or 640x480) using the sharp **Nearest Neighbor** algorithm (`sws_flags=neighbor`) so the original 2000s artifacts don't get blurred or anti-aliased.
2. **CRT Protection & Signal Legalization:** Because this loop will run all night, we must clamp the video signal to broadcast-safe levels to prevent tube blooming and high-voltage circuit stress. We must lower contrast/brightness and clamp luma values to legal ranges.
3. **Anti-Burn-In Measure:** To protect the phosphor from static elements (like vintage logos or letterbox bars), we must inject a continuous, subtle digital noise grain (`noise` filter) to keep the electron beam dynamically shifting position on every frame.
4. **The Interlace Glitch:** Apply an interlacing filter chain that intentionally tricks the container structure by interleaving fields but forcing a reversed field order flag (`fieldorder=bff`). When decoded by the Wii and drawn by the CRT, this creates violent horizontal tearing on movement without destroying the hardware.

## Your Task Right Now: Kick off Tier 1 (DEV) Setup & Test
Since our environment is completely empty, please act as the OpenCode engine and execute/provide:

1. **Environment Preparation:** Provide the Linux commands to install all necessary video tools (`ffmpeg`, `mpv`) and the system libraries required to format and mount exFAT/NTFS external drives on a clean Linux system.
2. **FFmpeg Extraction & Glitch Pipe Script:** Write a bash script or an efficient one-liner pipeline that takes a 9GB `input.mp4`, extracts a 60-second snippet from a specific timestamp (e.g., `-ss 00:10:00`), and outputs a `dev_test.mpg` or `dev_test.mp4` implementing the exact filter chain:
   - Nearest Neighbor downscale.
   - Contrast attenuation (e.g., `contrast=0.85:brightness=-0.05`).
   - Luma range clamping (limiting Y to 16-235 to avoid dangerous 100% IRE peaks).
   - Dynamic noise injection (`noise=alls=15:allf=t+u`) to prevent burn-in.
   - Field inversion (`tinterlace` / `fieldorder=bff` with top field interleaving).
3. **Mpv Preview Commands:** Provide the exact `mpv` terminal flags to locally emulate and analyze this interlaced output on our progressive DEV monitor, showing the raw combing lines and simulating the 480i motion jitter.
