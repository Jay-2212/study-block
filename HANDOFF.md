# Study Block Handoff

## Current state

Study Block 1.0.2 is implemented, installed, and published from the public
[`Jay-2212/study-block`](https://github.com/Jay-2212/study-block) repository.
The release now exposes one stable asset, `StudyBlock.dmg`, so the permanent
latest-release URL remains valid across future versions.

The static product site is live at
[`studyblock.jaybharti.me`](https://studyblock.jaybharti.me). GitHub Pages
publishes `docs/` from `main`; Cloudflare has an unproxied CNAME from
`studyblock.jaybharti.me` to `jay-2212.github.io`, and GitHub Pages enforces
HTTPS.

## Last session

- Fixed the Nudge Ladder feature card collision by moving all feature-card
  diagrams from absolute positioning into normal flex flow.
- Verified Chrome Blocking, Nudge Ladder, Floating Timer, and Private Streaks
  at desktop and mobile widths, including reduced-motion mode.

## Verification

- Local geometry checks at 1280, 720, and 390 px found zero feature-card
  overlap and zero horizontal overflow.
- Reduced-motion emulation left all cards fully visible, untransformed, and
  collision-free.
- HTML validation and JavaScript syntax checks passed.
- All smoke checks passed, and `./script/build_and_run.sh --verify` built and
  launched the app through the Command Line Tools fallback.

## Next steps

Trusted app distribution still requires Developer ID signing, hardened-runtime
validation, notarization, stapling, and a clean-machine Gatekeeper test.

## Open questions

None.
