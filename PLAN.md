# Study Block Build Plan

> Status: **Complete.** Phases 1–4 were implemented and verified on 2026-07-26.

## Product

Study Block is a native SwiftUI macOS 15+ focus companion with a regular app
window and a menu bar presence. It stores settings, active-session recovery, and
completed-session history as atomic JSON in Application Support.

Core guarantees:

- Study-site allowlist entries always beat the blocklist.
- Google, ChatGPT, and Claude are permanently unblockable.
- Enforcement runs only during a session and fails open when Chrome is absent.
- Study Block never force-quits an app and never targets itself or Chrome.
- Do Not Disturb preserves an existing Focus and restores only the state Study
  Block changed.
- Stopping, sleeping, waking, or quitting tears down session-owned timers,
  polling, panels, nudges, music control, and DND state.
- Full Chrome URLs are never persisted by Study Block.

## Completed phases

### Phase 1 — Foundation and onboarding

- Xcode project with Command Line Tools fallback.
- Three-step onboarding for study sites, allowed apps/sites, and distractions.
- Registrable-domain normalization and focused tests.
- Main window, menu bar, settings entry point, timer, and floating panel.
- Atomic local settings persistence.

### Phase 2 — Enforcement and app nudges

- Session-only AppleScript Chrome inspection and local blocked page.
- Permanent allow rules and allowlist precedence.
- Per-app nudge, allowance, warning, and cooperative-quit state machine.
- No force quit, Accessibility escalation, or privileged helper.

### Phase 3 — Full session experience

- 60, 90, and 120-minute presets plus open-ended timing.
- Top-right, draggable, nonactivating floating clock.
- Strict mode, music pausing, and session-scoped Do Not Disturb.
- Preserved app-target and policy invariants.

### Phase 4 — Final polish and hardening

- Native tabbed Settings for site/app policy, editable presets, defaults,
  launch at login, and stats.
- Completed-session history with today, this-week, and streak summaries.
- Missing/corrupt settings recovery and atomic history/checkpoint storage.
- Recoverable active sessions after abnormal termination.
- Chrome polling moved off the main thread, limited to active sessions, and
  backed off to ten seconds while Chrome is absent.
- Chrome tabs redirected by Study Block restore on stop and before normal Quit,
  including block pages left by an interrupted process.
- AppleScript and persistence work moved to dedicated queues.
- Explicit sleep/wake, clock-change, normal-Quit, and app-lifetime teardown.
- Timer/observer closure audit and focused settings/history/timer tests.

## Verification

- `./script/run_smoke_tests.sh`
- `./script/build_and_run.sh --verify`
- Real Chrome redirect and restoration.
- Live settings mutation during an active session.
- Floating clock visibility and top-right panel bounds.
- Strict-mode session behavior and automated escalation coverage.
- DND session activation/restoration path.
- Launch-at-login enable/disable.
- Abnormal termination and active-session recovery.
- Normal Quit teardown before process termination.
- Idle CPU, footprint, `leaks`, code signing, and Gatekeeper inspection.

Measured Phase 4 results and environment-specific caveats are recorded in
`HANDOFF.md`.

## Distribution

Development is complete. The current Command Line Tools artifact is ad-hoc
signed for local use. A public release still requires a Developer ID Application
certificate, hardened-runtime release signing, notarization, stapling, and a
clean-machine Gatekeeper check. This machine currently has no valid code-signing
identity, so those credentialed release operations were not fabricated.

The optional Chrome extension/native-messaging upgrade remains intentionally out
of scope; AppleScript enforcement is the shipped core implementation.

## Approved website release

> Status: **Approved on 2026-07-26.** The implementation brief was supplied
> directly by the product owner.

- Publish a static product site from `docs/` through GitHub Pages.
- Use an intentional dark, focus-oriented visual system derived from the app
  icon and native macOS interface.
- Cover the shipped blocking, nudge ladder, floating timer, and local streak
  features with accurate product copy.
- Link the primary download to a stable `StudyBlock.dmg` latest-release asset
  and display the current GitHub release version client-side.
- Configure `studyblock.jaybharti.me`, DNS-only Cloudflare CNAME, and GitHub
  Pages HTTPS.
- Verify the site, stable download, rendered version, and GitHub link live.
