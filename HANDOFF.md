# Study Block Handoff

## Current state

Study Block 1.1.1 is implemented and published from
[`Jay-2212/study-block`](https://github.com/Jay-2212/study-block).
The static site is at [`studyblock.jaybharti.me`](https://studyblock.jaybharti.me).
The site now reads the latest GitHub release for version, download URL, and
checksum, with v1.1.1 hardcoded as the no-JS fallback.

## Last session

1.1.1 native polish pass, taking only the useful principles from
`ceorkm/macos-design-skill` (quiet chrome, one job on screen, shared glass,
shortcuts in menus). Did not install the CSS skill, add a sidebar, or restyle
the marketing site.

- **Ready screen**: quieter title, duration picker is the content, Start is the
  only prominent button, Settings lives in the window toolbar.
- **Idle copy**: helper text only when a session just finished, notifications
  need enabling, or Do Not Disturb has a status.
- **Floating timer**: remaining/elapsed clock, no redundant icon, smaller panel,
  position still remembered.
- **Nudge**: shared `studySurface` glass, Quit Now as the primary action.
- **Consistency**: default surface radius 12, Settings tabs no longer extra
  padded, menu bar Stop uses ⌘.

## Verification

- `./script/run_smoke_tests.sh` passed.
- `./script/build_and_run.sh --verify` launched the Debug app.
- `./script/package_release.sh` produced `dist/StudyBlock.dmg`.
- SHA-256: `a449b2b1c9288bf8f8a6668c57f5c4438ad7bff41b80a7792a60f1146f122503`

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
- Manual check on a real `/Applications` install: quieter ready screen, toolbar
  Settings, drag the timer, confirm remaining/elapsed caption.

## Open questions

None.
