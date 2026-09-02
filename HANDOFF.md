# Study Block Handoff

## Current state

Study Block 1.2.0 is implemented, packaged, and verified from
[`Jay-2212/study-block`](https://github.com/Jay-2212/study-block).
The static site at [`studyblock.jaybharti.me`](https://studyblock.jaybharti.me) has
been updated with v1.2.0 fallback links and checksum.

## Last session

1.2.0 modernization, notch session contour, and performance health pass.

- **HUD perimeter progress**: Animated perimeter progress bar (`PerimeterRoundedRectangle`)
  tracing clockwise from top-center to reflect session progress.
- **MacBook notch contour**: Ambient glowing session contour hugging the MacBook camera
  notch (`NotchShape`, `NotchOutlineView`, `NotchOverlayController`), with automatic
  fallback to a sleek compact pill on external/notchless screens.
- **Indicator settings**: Floating HUD and Notch contour are independently togglable in
  Settings and in the Menu Bar dropdown (Notch on by default, Floating HUD on by default).
- **Menu bar glitch fix**: Replaced mutating 1-second label rebuilds with a stable status
  display and native checkmark toggles, eliminating tracking misclicks.
- **Memory & caching**: Replaced unbounded favicon dictionary with bounded `NSCache`
  (200 items, 10 MB limit).
- **Performance & threads**: Adaptive Chrome tab scanning (immediate inspection on app switch,
  2s when Chrome is frontmost, 8s in background), and on-demand escalation ticker (paused when idle).
- **Do Not Disturb**: Improved menu bar accessibility search and fixed verification timeout
  loop in macOS 15.
- **Glass settings**: Added `.scrollContentBackground(.hidden)` to settings forms for
  clean system material pass-through.

## Verification

- `./script/run_smoke_tests.sh` passed (all 5 smoke suites).
- `./script/build_and_run.sh --verify` built and launched the Debug app.
- `./script/package_release.sh` produced `dist/StudyBlock.dmg`.
- SHA-256: `53a4a8b9e1d3ebf9102786dd50a3c907d7f85010b52bdd6985cb5ec125a8b1c8`

## Limitations / unresolved

- Still ad-hoc signed, not notarized. First launch requires Control-click Open.
- Visual QA used launch verification and smoke tests.

## Next steps

- Commit and push to GitHub repository `Jay-2212/study-block`.
- Publish GitHub Release `v1.2.0` with `dist/StudyBlock.dmg` and `dist/StudyBlock.dmg.sha256`.

## Open questions

None.
