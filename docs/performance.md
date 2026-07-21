# Performance notes

These measurements compare isolated Ghostty processes with identical static terminal content and window dimensions.

## Test environment

- MacBook Air (`Mac16,13`)
- Apple M4, 24 GB unified memory
- macOS build `25F80`
- Ghostty 1.3.1
- 2496×1283 window on a 60 Hz display
- Three sequential processes, each running only `tail -f /dev/null`
- Three-second warm-up followed by ten one-second samples
- The user's primary Ghostty shader pipeline was suspended during each run

## Configurations

1. **Baseline:** no custom shaders
2. **Warp Stars:** `warp-stars.glsl` only, with continuous animation
3. **Full pipeline:** cursor shader followed by Warp Stars, with continuous animation

## Results

CPU is the median normalized CPU time from `powermetrics`, expressed as a percentage of one CPU core. The median avoids process-launch and window-resize spikes. Physical footprint comes from Apple's `footprint` tool.

| Configuration | CPU, median | Physical footprint | Difference from baseline |
| --- | ---: | ---: | ---: |
| Baseline | 1.12% | 207.4 MiB | — |
| Warp Stars | 5.17% | 306.9 MiB | +4.05% CPU, +99.5 MiB |
| Full pipeline | 5.18% | 312.9 MiB | +4.06% CPU, +105.5 MiB |

A separate `ps` sample agreed with the CPU result: median CPU was 1.15% for baseline, 4.90% for Warp Stars, and 4.75% for the full pipeline.

## GPU measurement limitation

The benchmark invoked Apple's privileged per-process counter directly:

```sh
powermetrics --show-process-gpu
```

On this Apple M4/macOS combination, the `GPU ms/s` field returned `0.00` for every process in every sample, including the animated shader processes. The lower-level `TASK_POWER_INFO_V2` GPU field also returned zero. This means the operating system did not expose usable per-process GPU attribution through these interfaces.

No system-wide GPU number is substituted here because unrelated applications would contaminate it. A reliable GPU comparison therefore requires a per-process Metal trace, such as Xcode Instruments' Metal System Trace, or future macOS tooling that exposes per-process GPU time on this hardware.

## Interpretation

On this machine, the measured CPU overhead is modest and the shader adds roughly 100 MiB of physical memory for the large terminal surface and rendering resources. These measurements alone do not establish the GPU cost.

`custom-shader-animation = always` keeps rendering even while Ghostty is unfocused. Users who only need animation in the foreground can try `custom-shader-animation = true`, which Ghostty also accepts.

Performance scales with terminal surface size, display refresh rate, shader count, and hardware. Results on other machines may differ substantially.
