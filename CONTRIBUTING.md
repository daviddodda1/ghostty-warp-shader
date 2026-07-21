# Contributing

Small, focused improvements are welcome.

Before opening a change:

1. Keep the default effect readable over a dark terminal background.
2. Avoid introducing trails or glow into the default preset.
3. Run `ghostty +validate-config` with the shader enabled.
4. Document any new top-level tuning constant in `README.md`.
5. Mention material GPU-cost changes, especially increases to loop counts.

For visual changes, include a short screen recording and the display refresh rate used for testing.
