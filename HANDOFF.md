# Study Block Handoff

## Current state

Study Block 1.1.0 is implemented and published from
[`Jay-2212/study-block`](https://github.com/Jay-2212/study-block).
The static site is at [`studyblock.jaybharti.me`](https://studyblock.jaybharti.me).
The site now reads the latest GitHub release for version, download URL, and
checksum, with v1.1.0 hardcoded as the no-JS fallback.

## Last session

1.1.0 product pass:

- **Floating timer**: SwiftUI hosting view now drags the panel, and the last
  position is saved. It no longer snaps back to the top-right on every show.
- **Accessibility nag**: session start no longer calls
  `AXIsProcessTrustedWithOptions(prompt: true)`. Do Not Disturb checks
  silently; Settings → Sessions explains missing access and can open
  Accessibility settings. Enabling DND can prompt once per launch.
- **Sites settings**: Add works (editors live on `AppModel`, not throwaway
  view `let`s). Open Chrome tabs are scanned on the Sites tab. Allowlist still
  beats the blocklist.
- **Permanent allow removed**: Google, ChatGPT, and Claude are suggestions
  only. They block if listed.
- **Stats**: sessions record blocked sites/apps. Stats shows a 14-day focus
  chart, most-blocked lists, and per-session chips. Redirects count on first
  tab redirect, not every 2s poll.

## Verification

- `./script/run_smoke_tests.sh` passed.
- `./script/build_and_run.sh --verify` launched the Debug app.
- `./script/package_release.sh` produced `dist/StudyBlock.dmg`.
- SHA-256: `7acb93371c1804cbacde200f309f3b397efa080965ee8b20fd2cd91f4b704475`

## Limitations / unresolved

- Still ad-hoc signed, not notarized. First launch still needs Control-click
  Open. Replacing the app can drop TCC grants for Accessibility and Chrome
  automation.
- `StudyBlockTests` still cannot run here (no Xcode; only smoke binaries).
- Do Not Disturb still uses the Control Center clock click when Accessibility
  is already trusted. That path is fragile across macOS UI changes.
- Visual QA used launch verification, not screenshots.

## Next steps

- Trusted distribution (Developer ID, notarization, stapling) still outstanding.
- Manual check on a real `/Applications` install: drag the timer, add a site,
  block ChatGPT, confirm no Accessibility dialog with DND off.

## Open questions

None.
