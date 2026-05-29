# v1 Artifact Testing

Use these commands to inspect the glitch output while `hunt` renders are being produced.

Target file:
- `renders/transition_hunt_glitch.mpg`

## 1) Clean truth check (no shader)
Use this first to validate raw field behavior and combing.

```bash
mpv --no-deinterlace "renders/transition_hunt_glitch.mpg"
```

## 2) Shader preview - Guest Advanced NTSC
Use this to preview a composite-like CRT feel on a modern monitor.

```bash
mpv --no-deinterlace --glsl-shader="./mpv-retro-shaders-master/crt/shaders/crt-guest-advanced-ntsc.glsl" "renders/transition_hunt_glitch.mpg"
```

## 3) Shader preview - Royale Kurozumi Intel
Use this as a second aesthetic reference pass.

```bash
mpv --no-deinterlace --glsl-shader="./mpv-retro-shaders-master/crt/shaders/crt-royale-kurozumi-intel.glsl" "renders/transition_hunt_glitch.mpg"
```

## Recommended review order
1. Clean truth check
2. Guest Advanced NTSC
3. Royale Kurozumi Intel

If visuals disagree between passes, prioritize the clean truth check for technical decisions.
