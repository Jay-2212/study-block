# Study Block Handoff

## Current state

Study Block development is complete through Phase 4. The app has editable
post-onboarding settings, configurable presets, local completed-session history
and stats, launch at login, interrupted-session recovery, session-only Chrome
and music polling, sleep/wake handling, and deterministic stop/Quit teardown.

The working defaults remain 60/90/120 minutes, strict mode on, session DND on,
`youtube.com` blocked, and the user’s original allow/block selections intact.
Phase 4 QA added two short open-ended entries to local session history.

## Phase 4 verification

- `./script/run_smoke_tests.sh`: passed domain, policy, escalation, settings
  persistence, and session-history checks.
- `./script/build_and_run.sh --verify`: passed through the Command Line Tools
  fallback and launched the fresh app.
- Settings: temporarily added `reddit.com`, edited the first preset from 60 to
  65 minutes during a session, confirmed the main UI updated live, then restored
  60 minutes and removed the temporary domain.
- Policy: Reddit and YouTube redirected to the local block page; stopping the
  session restored the original URL. Google/ChatGPT/Claude precedence is covered
  by policy and settings smoke checks.
- Clock: hide/show worked; the live panel was `178 × 78` at `x=1268, y=57`,
  floating layer 3 at the active display’s top-right.
- Strict/nudges: strict mode remained visible and the full escalation state
  machine smoke test passed. The external foreground-app focus bridge was
  unavailable during the final live trigger, so no new destructive app-quit
  cycle was forced; Phase 2/3 live verification remains valid.
- DND: the recovered live session reported “Do Not Disturb is on for this
  session”; stop and Quit exercised the restoration path. Existing Focus
  preservation remains unchanged from the Phase 3 assertion-level verification.
- Recovery: a `SIGKILL` session resumed at the original absolute deadline
  (`59:43` remaining), kept blocking fail-safe, then restored the Chrome tab on
  stop.
- Quit: an initial test found teardown was too late in
  `applicationWillTerminate`; moving it to `applicationShouldTerminate` fixed
  the issue. The retest restored YouTube before the process exited.
- Launch at login: enabled successfully, displayed the registered state, then
  disabled successfully to restore the user’s original preference.
- Performance: cold process launch measured 76 ms, 53 ms, and 57 ms. Idle CPU
  sampled at `0.0%`. Warmed footprint was `52 MB` before and after a full
  start/stop cycle.
- Leaks: `leaks` reported 19,936 bytes in system framework allocations and no
  Study Block-owned symbols in leak paths. Timer and observer callbacks use weak
  ownership; session timers and observers have explicit invalidation/removal.
- Edge paths: Chrome-absent polling backs off to 10 seconds; sleep suspends
  enforcement/DND/panels and wake recomputes from absolute dates; corrupt or
  missing JSON recovers to safe defaults; back-to-back starts end the first
  session before starting the second.

## Release prerequisite

The local bundle is correctly ad-hoc signed with the Apple Events entitlement,
but `spctl` rejects it for distribution because this machine has zero valid
code-signing identities. Public shipping requires a Developer ID Application
certificate plus hardened-runtime signing, notarization, stapling, and a
clean-machine Gatekeeper test. Xcode is still not installed and was not
downloaded.

## Next steps

No feature work remains. When Apple distribution credentials and release tooling
are available, perform the credentialed signing/notarization pass described
above. The optional Chrome extension/native messaging provider remains a
separate future product decision.

## Open questions

None.
