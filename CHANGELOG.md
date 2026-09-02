# Changelog

## 1.1.1 — 2026-09-02

- Quieted the ready screen so choosing a duration and starting is the only job.
- Moved Settings into the window toolbar and kept Command-Comma.
- Made the floating timer a smaller remaining/elapsed clock.
- Gave the app nudge the same glass surface as the timer, with Quit Now as the
  primary action.

## 1.1.0 — 2026-09-01

- Made the floating focus timer draggable and remembered where you left it.
- Stopped asking for Accessibility on every session start. Do Not Disturb now
  checks silently and explains in Settings when access is missing.
- Fixed adding websites in Settings and listed open Chrome tabs so you can
  allow or block them directly.
- Google, ChatGPT, and Claude are suggested work sites, not permanently
  unblockable.
- Stats now shows focus time by day, most blocked sites and apps, and what
  was blocked in each session.

## 1.0.4 — 2026-07-28

- Fixed a shutdown deadlock by restoring redirected Chrome tabs on the
  enforcement worker with a bounded quit-time wait.

## 1.0.3 — 2026-07-28

- Fixed the development build launcher so it only quits Study Block copies
  launched from this repository and never terminates the installed login item.
- Removed forced duplicate-instance launches and made launch verification check
  the exact development app bundle.
- Refreshes an enabled launch-at-login registration from the current installed
  app bundle after an app replacement, while preventing development builds from
  taking over the registration.

## 1.0.2 — 2026-07-26

- Added asynchronously fetched, disk-cached website favicons with a globe
  fallback when an icon is unavailable.
- Added native application icons to onboarding and editable app lists.
- Added a visible Settings button to the ready screen and the standard
  Command-Comma app-menu shortcut.
- Fixed session-owned Do Not Disturb restoration after live settings changes
  and across stop, timer expiry, normal quit, and system sleep.

## 1.0.0 — 2026-07-26

- Initial public release with focus timers, Chrome and app enforcement,
  session-scoped Do Not Disturb, editable settings, local stats, and
  interrupted-session recovery.
