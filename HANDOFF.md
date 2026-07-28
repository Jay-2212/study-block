# Study Block Handoff

## Current state

Study Block 1.0.4 is implemented, installed in `/Applications`, and published
from [`Jay-2212/study-block`](https://github.com/Jay-2212/study-block).
The static site is live at
[`studyblock.jaybharti.me`](https://studyblock.jaybharti.me) with the v1.0.4
download and SHA-256 checksum.

## Last session

- Replaced Chrome enforcement's quit-time `queue.sync` restoration with an
  asynchronous serial-worker operation, a same-worker fast path, and a bounded
  five-second wait.
- Audited the termination path and confirmed it contains no
  `DispatchQueue.main.sync` calls.
- Set the marketing version, build number, and bundle metadata to `1.0.4`.
- Published the v1.0.4 GitHub release with the DMG and checksum asset.
- Updated the website's immutable download URL, version, and checksum.
- Replaced `/Applications/Study Block.app`; the v1.0.3 bundle is recoverable
  from Trash.

## Verification

- All focused smoke checks passed, and Debug and Release builds launched.
- Five Debug and three Release cooperative Quit/relaunch cycles completed with
  new exact-path PIDs while Chrome was running; no crash report was generated.
- The installed app also quit and relaunched cleanly with no crash report.
- The Release app, DMG, and mounted DMG app passed integrity/signature checks
  and reported version/build `1.0.4`.
- A fresh GitHub release download matched SHA-256
  `45b7b7abfc61d62797543f5380760f391b45513a5480856d6184f2f156287cf7`.
- GitHub Pages build `1118819043` deployed release commit `2bf913e`; the live
  site returned HTTP 200 with the v1.0.4 links and checksum.
- `/Applications/Study Block.app` reports version/build `1.0.4` and launches
  from the exact installed path.

## Next steps

Trusted distribution still requires Developer ID signing, hardened runtime,
notarization, stapling, and a clean-machine Gatekeeper test.

## Open questions

None.
