# Study Block Handoff

## Current state

Study Block 1.0.4 is implemented, installed in `/Applications`, and published
from [`Jay-2212/study-block`](https://github.com/Jay-2212/study-block).
The static site is live at
[`studyblock.jaybharti.me`](https://studyblock.jaybharti.me) with the v1.0.4
download and SHA-256 checksum. Version/build were left at 1.0.4 for this
session's changes; no release was cut.

## Last session

A portfolio-polish pass over five areas, keeping the existing
Models/Stores/Services/Views layering and the cooperative-only-quitting
ethic:

- **Notifications**: added `NotificationService` (Services), wired to
  `AppModel`'s session-ended lifecycle event so a completed session posts a
  system notification (banner + sound) regardless of whether the app is
  frontmost, via a `UNUserNotificationCenterDelegate` returning `.banner` in
  `willPresent`. Removed the old `NSSound.beep()` from `TimerCoordinator` so
  the notification is the single source of completion feedback. Denied/
  undetermined permission degrades gracefully: the app still records the
  session and shows an in-app "You focused for Xm. Nice work." message in the
  ready screen either way.
- **Permission priming**: onboarding gained a first step
  (`PermissionPrimingStepView`) explaining Chrome automation and
  notifications before either is requested. Notification authorization is
  requested when the user taps Continue on that step (not on `.onAppear`);
  Chrome automation is requested only when the user explicitly taps "Check
  Chrome Tabs" on the next step (the old auto-discovery `.onAppear` call was
  removed). Existing installs get an inline "Get notified…" + Enable row on
  the ready screen (visible only while `.notDetermined`) plus a durable
  status row in Settings → Sessions.
- **Menu commands**: added `CommandMenu("Session")` with Start/Stop Session
  items in a dedicated `SessionCommands` view, enablement driven by
  `AppModel`/`TimerCoordinator` state. Verified empirically via
  `System Events` UI scripting that enablement flips correctly on session
  start/stop.
- **Onboarding reshell**: `OnboardingModel.step` changed from a raw `Int` to
  an `OnboardingStep` enum (fixes a real off-by-one risk from inserting the
  priming step). Added `OnboardingStepIndicator` (segmented dots) replacing
  the old "Step X of 3" text, centered the step content to `maxWidth: 620`,
  and fixed a pre-existing bug where "Run Onboarding Again" reopened at the
  last-used step instead of the first (`OnboardingModel.restart()`).
- **Shared visual system**: `BigNumberDisplay` (two sizes only — `.large`
  64pt for the primary countdown, `.compact` 32pt for the floating timer and
  nudge countdown, with an `urgent` tint/weight for the nudge) now backs
  `TimerSetupView`, `FloatingTimerView`, and `AppNudgeView`. `StudyEmptyState`
  (a `ContentUnavailableView` wrapper with a `compact` inline variant)
  unifies empty states across onboarding, Settings, and site/app lists.
  `studySurface`'s default corner radius normalized to 16pt; StatsSettingsView
  cards switched from ad hoc `.background(.regularMaterial, …)` to
  `studySurface(cornerRadius: 12)`.
- **Nudge + Settings polish**: `AppNudgeView` got a tinted icon badge,
  `.accessibilityAddTraits(.isModal)`, an explicit accessibility label on the
  minutes field, and `.cancelAction` (not `.defaultAction`) bound only to the
  already-benign dismissals (Keep App Open, Give Me 5 Min, Close on quit-
  failed) — deliberately not binding Return to "Quit Now" since that's a
  cooperative-safety-relevant destructive action. `NudgePanelController.show()`
  now re-asserts `makeKeyAndOrderFront` on the next run-loop turn (not a
  second `NSApp.activate`) to win the key-window race against the just-
  activated blocked app, so its controls can reliably accept keyboard input.
  Settings window's hard `.frame(width: 720, height: 620)` replaced with
  `minWidth/idealWidth/minHeight/idealHeight` hints. `SettingsStore` gained a
  `pendingErrorAlert` (one-shot) alongside the existing persistent
  `errorMessage`, surfaced via a single `.alert` in `ContentView`; the
  passive inline error row in General settings stays as a supplement.

### Advisor consultations

Advisor was consulted at the start (plan critique — flagged the missing
notification delegate, the recovery-path false-notification risk, the
onboarding step-index fragility, the "Run Onboarding Again" bug, and the
beep/notification double-sound), for judgment calls during implementation
(menu command structure, empty-state component shape, nudge Escape/default-
action policy, error-alert placement/scope), and for a skeptical final review
of the diff. The final review caught two real issues that were fixed before
committing: a second `NSApp.activate` in the nudge-panel race-condition fix
(reverted — it would have fought the user's own app-switch, a cooperative-
ethic violation) and an invalid AX-based conclusion that the nudge TextField
was unfocusable (the test was confounded by Chrome holding frontmost status
in this environment; re-tested more carefully but still couldn't reach a
clean verification — see Limitations).

## Verification

- `./script/run_smoke_tests.sh` passes (domain normalization, enforcement
  policy, escalation, settings persistence, session history).
- `./script/build_and_run.sh --verify` succeeds after every slice (Command
  Line Tools fallback; this machine has no Xcode installed).
- **`StudyBlockTests` (XCTest) could not be run** — there is no Xcode on this
  machine, only Command Line Tools, and `xcodebuild test` requires Xcode.
  Only the smoke-test binaries and manual/UI-scripted checks below were run.
- Ruled out a suspected regression rigorously: when the main window
  stopped reopening after being closed mid-session, `git stash`'d all
  changes and reproduced the identical behavior on the unmodified 1.0.4
  code, confirming it's a pre-existing environment artifact from repeated
  ad-hoc rebuild/relaunch churn, not something this session's changes
  caused.
- Verified via `System Events` UI scripting (not screenshots — see below):
  menu Start/Stop Session enablement flips correctly on session start and
  stop; full onboarding flow (priming → domains → whitelist → blacklist →
  finish) advances/back-navigates correctly and completes without triggering
  the old auto-discovery permission prompt; a real 1-minute session (preset
  minutes temporarily edited to `1`) completed and was recorded in
  `sessions.json` with the correct fields, proving the `.ended(completed:
  true)` → `sessionHistory.record` → `lastCompletionMessage` /
  `notifications.notifySessionCompleted` code path executes (all three calls
  are unconditional and sequential, so the recorded session is proof the
  other two ran).
- One screenshot (of the onboarding priming step) was taken and reviewed
  before this policy changed — see Limitations for why screenshot-based
  visual QA was stopped for the rest of the session.

## Limitations / unresolved

- **Screenshot-based visual QA was abandoned mid-session.** Twice, a
  screenshot (once full-screen, once window/region-scoped) unexpectedly
  captured explicit adult video content open elsewhere on this Mac,
  unrelated to Study Block. Both images were deleted immediately. For the
  rest of the session, visual verification relied on `System Events`
  UI-scripting (reading control state/text) instead of screenshots. This
  means the onboarding reshell's final visual layout (spacing, the step
  indicator's appearance, and the two Settings-window layout claims) were
  **not** visually confirmed after the one deleted screenshot — they were
  verified structurally (correct view/text per step) but not visually.
- **Notification authorization status in this build is unknown.** The ready
  screen's "Get notified…" row not appearing after the priming step's
  Continue tap only proves the status isn't `.notDetermined` — it doesn't
  distinguish `.authorized` from `.denied` for this ad-hoc/unsigned dev
  build, and the OS notification banner itself was never visually confirmed.
  Worth a manual check on a real device/signed build.
- **Nudge dialog TextField keyboard focus was not conclusively verified.**
  Direct `AXFocused` checks read `false` after clicking the "Minutes" field,
  both before and after the `NudgePanelController` race-condition fix — but
  the test environment had Chrome repeatedly reclaiming frontmost status for
  reasons unrelated to Study Block (no `activate` calls exist anywhere in the
  Chrome enforcement code), which invalidates a same-session AX focus check
  (no Study Block window can be key while another app is frontmost). The fix
  applied (re-assert key-window status only, not a second app activation) is
  the standard, low-risk pattern for this class of bug and does not by
  itself risk any regression, but its effectiveness is unconfirmed. Worth a
  manual click-and-type check.
- **"Run Onboarding Again" fix (`OnboardingModel.restart()`) was not clicked
  end-to-end.** It was verified by code review plus independently confirming
  the underlying step-enum transitions work (via the priming→domains→
  whitelist→blacklist walkthrough above); the Settings button itself wasn't
  clicked because enumerating that Form section's children via `System
  Events` fails with a generic `-10000` error — reproduced on the
  pre-existing "Session presets" section too, so it's a tooling limitation,
  not evidence of a problem, but the button click itself remains unconfirmed.
- **Settings window sizing**: observed at 900×548 in this session, larger
  than the new `idealWidth`/`idealHeight` (640×560) hints, most likely
  because macOS restored an autosaved frame from a prior 720×620-era launch
  rather than sizing fresh from content. The hard fixed frame is gone and a
  fresh install should size to content, but this wasn't confirmed on a truly
  first-run window (would need `defaults delete com.jay.studyblock` plus a
  fresh launch to test cleanly).
- Trusted distribution still requires Developer ID signing, hardened
  runtime, notarization, stapling, and a clean-machine Gatekeeper test
  (unchanged from prior sessions).
- No deployment applies to this pass — `docs/` (the marketing site) was not
  touched.

## Next steps

- Manually verify: notification banner actually appears on a signed/
  notarized build; nudge TextField accepts typed input; Settings window
  sizes reasonably on a genuinely fresh install (no prior autosaved frame).
- Trusted distribution (Developer ID signing, notarization, stapling) still
  outstanding, as before.

## Open questions

None.
