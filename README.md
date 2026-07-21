# Ghostty Warp Stars

A bright, point-only radial starfield shader for [Ghostty](https://ghostty.org/). Stars spawn throughout a circular zone, accelerate toward the viewer, and respawn at randomized positions.

The effect is intentionally restrained:

- crisp star points
- no trails or streaks
- no glow
- no twinkling
- randomized respawns instead of a single center point
- dark-pixel masking to keep terminal text readable

It works in any Ghostty terminal and includes an optional configuration adjustment for [Herdr](https://herdr.dev/).

![Warp Stars running in Ghostty](docs/demo.gif)

## Requirements

- Ghostty with custom-shader support
- A dark terminal theme is strongly recommended
- macOS or Linux

This shader uses Ghostty's `iTime`, `iResolution`, and `iChannel0` shader inputs. Animation must remain enabled for continuous motion.

## Quick install

Clone or copy this folder onto the target machine, then run:

```sh
./install.sh
```

The installer:

1. copies `shaders/warp-stars.glsl` into your Ghostty shader directory;
2. backs up your Ghostty configuration before changing it;
3. adds the shader and enables continuous shader animation;
4. runs `ghostty +validate-config` when Ghostty is available in `PATH`.

Reload Ghostty afterward:

- **macOS:** `Cmd+Shift+,`
- **Linux:** `Ctrl+Shift+,`

To remove the installed shader and the configuration block added by the installer:

```sh
./install.sh --uninstall
```

## Manual installation

Copy the shader:

```sh
mkdir -p ~/.config/ghostty/shaders
cp shaders/warp-stars.glsl ~/.config/ghostty/shaders/warp-stars.glsl
```

Add these lines to `~/.config/ghostty/config`:

```ini
custom-shader = /absolute/path/to/.config/ghostty/shaders/warp-stars.glsl
custom-shader-animation = always
```

Use the real absolute path for your machine. Validate the result:

```sh
ghostty +validate-config
```

### Combining it with another shader

Ghostty accepts multiple `custom-shader` entries. They form an ordered shader pipeline. For example, the setup this project came from applies a cursor effect first and Warp Stars second:

```ini
custom-shader = /absolute/path/to/cursor_warp.glsl
custom-shader = /absolute/path/to/warp-stars.glsl
custom-shader-animation = always
```

The cursor shader is not included here. The original setup uses [ghostty-cursor-shaders](https://github.com/sahaj-b/ghostty-cursor-shaders).

## Herdr integration

Warp Stars does not require Herdr. To make Herdr panels use the terminal background, merge the following into `~/.config/herdr/config.toml`:

```toml
[theme.custom]
panel_bg = "reset"
```

If `[theme.custom]` already exists, add only the `panel_bg` entry rather than creating the table twice. Reload Herdr after editing:

```sh
herdr config check
herdr server reload-config
```

## Customization

The main controls are at the top of `shaders/warp-stars.glsl`:

| Constant | Default | Purpose |
| --- | ---: | --- |
| `WARP_SPEED` | `0.060` | Lifecycle and movement speed |
| `SPAWN_RADIUS` | `0.22` | Size of the randomized circular spawn zone |
| `STAR_BRIGHTNESS` | `1.38` | Overall additive brightness |
| `STAR_COUNT` | `44` | Number of simulated stars |
| `STAR_COLOR` | `(0.96, 0.98, 1.00)` | Blue-white point color |
| `BACKGROUND_LUMA_START` | `0.11` | Luminance where background masking starts |
| `BACKGROUND_LUMA_END` | `0.25` | Luminance above which pixels are protected |

After changing the shader, reload Ghostty. Recent Ghostty versions can hot-reload custom shader changes.

### Performance

With `custom-shader-animation = always`, Ghostty continuously renders animated frames, normally synchronized to the active display. Movement is based on `iTime`, so animation speed does not depend on display refresh rate.

An isolated Apple M4 benchmark measured approximately 5.17% of one CPU core and 306.9 MiB physical memory for a 2496×1283 Warp Stars terminal, compared with 1.12% CPU and 207.4 MiB for an unshaded baseline. Per-process GPU attribution was unavailable on the test system, so no system-wide GPU number is presented as a substitute.

See [the full methodology and results](docs/performance.md).

## How the effect works

Each star has a deterministic pseudo-random lifecycle:

1. A generation key chooses a fresh point inside the spawn circle.
2. A perspective depth value (`z`) decreases over time.
3. The projected travel distance uses `1 / z`, producing radial acceleration.
4. Point size and brightness increase slightly as the star approaches.
5. The star fades near its lifecycle boundaries and respawns with a new generation key.
6. The final star layer is added only to dark terminal pixels, preserving most text and UI elements.

No previous star position is sampled, which is why the effect produces no tail.

## Project layout

```text
ghostty-warp-stars/
├── docs/
│   ├── demo.gif
│   └── performance.md
├── examples/
│   ├── ghostty.conf
│   └── herdr.toml
├── shaders/
│   └── warp-stars.glsl
├── CONTRIBUTING.md
├── install.sh
├── LICENSE
└── README.md
```

## Publishing

This folder is ready to become a Git repository:

```sh
git init -b main
git add .
git commit -m "Initial release"
```

Create an empty repository on your preferred host, add it as `origin`, and push `main`.

## License

MIT. See [`LICENSE`](LICENSE).
