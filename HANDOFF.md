# Study Block Handoff

## Current state

Study Block 1.0.3 is implemented, installed in `/Applications`, and published
from [`Jay-2212/study-block`](https://github.com/Jay-2212/study-block).
The static site is live at
[`studyblock.jaybharti.me`](https://studyblock.jaybharti.me) with the v1.0.3
download and SHA-256 checksum.

## Last session

- Replaced the name-wide dev-launch `pkill` with bundle-path targeting and
  cooperative AppKit termination; removed `open -n` and made verification
  require the exact repo-built app.
- Added installed-only refresh of enabled `SMAppService.mainApp` registration
  after a bundle/build replacement. A stored bundle identity prevents repeated
  refreshes, and development builds cannot auto-take over the registration.
- Released v1.0.3 with marketing and build versions both set to `1.0.3`.
- Updated the website to the immutable v1.0.3 asset URL and published checksum
  `b8651333208eb3e45d2fa40df668e07444bb0c1fcb7b119cbaddcec6ad8fab52`.

## Verification

- All focused smoke checks passed.
- Consecutive dev runs exited cooperatively and relaunched with a new exact-path
  PID; a simultaneously running `/Applications` copy kept its original PID.
- The warning-free Release app passed strict code-signature checks, the DMG
  verified, and the app mounted from the DMG reported version/build `1.0.3`.
- The GitHub release asset was downloaded again and matched the published
  checksum. GitHub Pages built the release commit, and the live download
  returned the v1.0.3 DMG with HTTP 200.
- The installed `/Applications` copy launched to its ready window, remained
  running, and showed no crash dialog. The replaced v1.0.2 bundle is recoverable
  from Trash.
- The stale background-item record was real but disabled and pointed at an old
  repo `.build` bundle. The nudge ladder already used cooperative termination
  and excluded both the production and current app bundle identifiers.

## Next steps

Trusted distribution still requires Developer ID signing, hardened runtime,
notarization, stapling, and a clean-machine Gatekeeper test.

## Open questions

None.
