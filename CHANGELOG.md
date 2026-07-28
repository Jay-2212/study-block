# Changelog

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
