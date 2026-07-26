# Study Block Handoff

## Current state

Study Block 1.0.2 is implemented, installed, and published as GitHub release
[`v1.0.2`](https://github.com/Jay-2212/study-block/releases/tag/v1.0.2).
The installed copy at `/Applications/Study Block.app` is the same release
binary packaged in `dist/Study-Block-1.0.2.dmg`.

The release adds cached website favicons with globe fallbacks, native app icons
throughout onboarding and settings, a visible ready-screen Settings button,
the standard Command-Comma Settings command, and deterministic ownership of
session-created Do Not Disturb across live settings reconfiguration.

## Verification

- All domain, policy, escalation, settings, and history smoke checks passed.
- `./script/build_and_run.sh --release --verify` built and launched version
  1.0.2 through the Command Line Tools fallback.
- The release bundle passed strict `codesign` verification.
- Live UI checks confirmed resolved favicons, an unavailable-site globe
  fallback, native icons for blocked and allowed apps, both Settings entry
  points, persistent edits, and live mid-session reapplication.
- The installed candidate successfully enabled session-owned Do Not Disturb.
  Stop, expiry, normal quit, and sleep all converge on the same idempotent
  release path; Focus-state verification now reports the resulting state.
- The DMG passed `hdiutil verify`, contains the matching 1.0.2 app and an
  Applications symlink, and has SHA-256
  `bff5a0509ba2b0c6e77e8651f8857d3cc7bac7322bc51854b1b45b5022f5bd43`.
- The published asset was downloaded again, matched the local DMG byte for
  byte, passed `hdiutil verify`, and the `v1.0.2` tag resolves to release commit
  `c407b31`.

## Distribution caveat

The app remains ad-hoc signed and is not notarized because this Mac has no
Developer ID Application identity or full Xcode installation. Replacing an
ad-hoc build can require refreshing its Accessibility entry because macOS ties
the permission to the binary hash.

## Next steps

No product work is pending. A future trusted distribution still requires
Developer ID signing, hardened-runtime validation, notarization, stapling, and
a clean-machine Gatekeeper test.

## Open questions

None.
