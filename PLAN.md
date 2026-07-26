# Study Block Build Plan

> Status: approved on 2026-07-26. Phases 1 and 2 are complete.

## 1. Agreed product boundaries

- Native Swift/SwiftUI macOS app, built as an Xcode project.
- Minimum deployment target: macOS 15.
- Use Liquid Glass APIs only behind `if #available(macOS 26, *)`; use native, system-adaptive materials and controls on macOS 15–25.
- Provide a regular main window, Dock presence, and a concise `MenuBarExtra`.
- Keep all data local. Do not persist Chrome tab titles, paths, queries, or full URLs.
- Phase 1 uses AppleScript to discover open Chrome tabs.
- Phase 2 uses AppleScript through the existing Apple Events entitlement to enforce Chrome tabs. Enforcement is firm but bypassable and is not tamper-resistant.
- A Chrome extension and native messaging bridge are deferred to an optional strict-mode upgrade if AppleScript enforcement proves insufficient.
- The final escalation attempts to quit only the distracting app or game, never Study Block.
- Session web enforcement is allowlist-first. The blacklist supplements the allowlist with explicit classification and messaging.
- Distribution will be direct, Developer ID–signed and notarized, with App Sandbox disabled.

## 2. Proposed user experience

### Onboarding

The onboarding window contains three ordered steps and can be revisited from Settings.

1. **Study/work domains**
   - Welcome the user, then ask: “Where do you study or work?”
   - Read the URLs of currently open Google Chrome tabs.
   - Immediately reduce each URL to its normalized registrable domain, deduplicate it, and discard the raw URL.
   - Example: `docs.google.com/document/...` becomes `google.com`.
   - Show common study/work domain suggestions and a manual paste field.
   - Pasted values may be domains or full URLs; both use the same normalization path.

2. **Whitelist**
   - Review the domains selected in step 1.
   - Add productive apps by installed-app identity and bundle identifier, not display name alone.
   - Add productive websites from presets such as Google Search, ChatGPT, Claude, and Notion.
   - Allow custom app and domain entries.

3. **Blacklist**
   - Select distracting domains from presets such as YouTube, Reddit, and X.
   - Select installed games and distracting apps by bundle identifier.
   - Explain that Phase 1 saves these preferences but Phase 3 adds active enforcement.
   - Reject whitelist/blacklist conflicts and ask the user to choose one classification.

Domain extraction must use a registrable-domain/public-suffix-aware resolver rather than blindly taking the last two labels; otherwise domains such as `example.co.uk` are handled incorrectly. `localhost`, IP addresses, invalid text, unsupported schemes, and browser-internal URLs need explicit validation behavior and unit tests.

### Study session

- The menu bar shows whether a session is active and exposes short actions: open Study Block, start/stop the session when appropriate, show/hide the timer, and quit Study Block.
- A small floating timer appears near the trailing side of the active display during a session.
- The simplest timer model is a 25-minute countdown by default, adjustable from 5 to 120 minutes in Settings.
- The timer is movable, stays above ordinary windows, avoids stealing keyboard focus, and remains usable across Spaces. SwiftUI owns timer state; a narrow AppKit panel bridge owns only panel behavior.
- The main window shows onboarding until completion, then shows Home.

### Phase 2 app escalation

Track escalation separately for each blocked bundle identifier during an active session:

1. Detect the distracting app launch or activation and show a gentle nudge.
2. Offer **Quit now**, **Give me 5 min**, or a user timer.
3. A five-minute snooze suppresses that app’s nudge; the nudge returns when it expires if the app is still running or is reopened.
4. A user timer accepts a positive duration up to 15 minutes. The cap is not advertised, values above it are rejected rather than silently clamped, and invalid input does not start a timer.
5. When the allowance expires, show an approximately 30-second visible warning.
6. After the warning, call the normal macOS termination request for that distracting app.
7. Observe whether it actually terminates. If the request fails or the app remains open, notify the user and record the failure; do not force-quit, request Accessibility access, or terminate Study Block.

Stopping the study session clears all active escalation states and pending quit countdowns.

## 3. Proposed architecture

### macOS app target

- `WindowGroup("Study Block", id: "main")` for onboarding and Home so the primary window can appear normally at launch.
- `MenuBarExtra` for session status and quick actions; keep the app’s activation policy regular.
- Separate scenes for Settings and any auxiliary UI.
- App-wide session coordinator as the single source of truth for session state, active policy, timer state, and escalation events.
- Small, explicit platform services:
  - Chrome discovery service: AppleScript adapter in Phase 1, bridge adapter in Phase 3.
  - Workspace monitor: observes foreground app launches/activations through `NSWorkspace`.
  - App termination service: wraps the cooperative `NSRunningApplication.terminate()` request and observes the result.
  - Floating timer panel controller: the smallest AppKit boundary needed for side placement and non-activating, always-on-top behavior.

### Chrome extension

The extension is not part of Phase 2. It is a later optional strict-mode upgrade:

- Manifest V3 extension.
- Reads open Chrome tabs for onboarding only when Study Block asks for them.
- Uses dynamic `declarativeNetRequest` rules to redirect main-frame navigation outside the allowlist while a study session is active.
- Uses the blacklist as a supplemental explicit-distraction classification for blocked-page copy, events, and future escalation behavior.
- Stores only the latest normalized policy, session status/expiry, and minimal bridge metadata in `chrome.storage.local`.
- Reports block events to the app for statistics without sending page paths, query strings, titles, or content.
- Does not rely on AppleScript after Phase 3.

### Native messaging bridge

- A small signed native-host executable communicates with the extension through Chrome’s length-prefixed JSON standard input/output protocol.
- The host manifest uses an absolute executable path and restricts `allowed_origins` to the exact Study Block extension ID.
- The bridge validates every message with a versioned schema. Initial message types:
  - `hello` / compatibility response
  - `getPolicy`
  - `policyChanged`
  - `getOpenDomains`
  - `sessionChanged`
  - `blockEvent`
  - `heartbeat`
- The native host is only a transport adapter. It forwards messages to the running Study Block app over a local, authenticated IPC boundary; it does not become a second source of truth.
- The extension caches the last policy but fails open after a short missed-heartbeat window or the known session expiry. This avoids leaving Chrome blocked after Study Block crashes or is removed.
- During onboarding, installation places the native-host manifest in Chrome’s supported per-user location and verifies the exact extension origin and absolute executable path. If registration or connection fails, onboarding offers repair and AppleScript domain discovery remains available.

### Persistence

Use versioned, atomic JSON files in Application Support as the app’s authoritative local store. This is the simplest persistence option and remains easy to inspect, migrate, and share selectively with the later bridge.

- `StudySettings`
  - onboarding completion
  - normalized whitelisted domains
  - normalized blacklisted domains
  - whitelisted app bundle identifiers
  - blacklisted app bundle identifiers
  - timer preferences
- `StudySession`
  - start/end timestamps
  - planned and actual active duration
  - completion/stop reason
- `BlockEvent`
  - timestamp
  - website domain or app bundle identifier
  - event kind and escalation stage
  - requested action and result

The extension keeps only a disposable policy cache. The app’s JSON store remains authoritative. Active escalation deadlines should be recoverable after an app relaunch so Study Block does not accidentally reset an allowance, but no enforcement survives after the study session ends.

### State and data flow

1. Onboarding and Settings write normalized policy to the atomic JSON store.
2. Starting a session publishes the active policy to the menu bar, floating timer, AppleScript Chrome enforcer, and workspace monitor.
3. The AppleScript Chrome enforcer periodically inspects normalized tab domains and redirects explicitly blacklisted tabs to the app's calm local block page. Google, ChatGPT, and Claude are permanently allowed.
4. The workspace monitor emits app launch/activation events to the escalation state machine.
5. Ending a session stops Chrome enforcement, cancels app escalation and pending quit warnings, and closes the floating timer.

## 4. Phase plan

### Phase 1 — Onboarding, menu bar, and basic timer

**Scope**

- Create the macOS 15 Xcode project and focused folder structure.
- Add a canonical `script/build_and_run.sh` that stops, builds, launches, and verifies Study Block, then wire the Codex Run action to it.
- Establish the regular main window, menu bar extra, Settings entry point, and system-adaptive visual foundation.
- Implement all three onboarding pages and preset/custom selection UI.
- Implement domain parsing, registrable-domain normalization, deduplication, conflict validation, and unit tests.
- Add Chrome-only open-tab discovery through the temporary AppleScript adapter.
- Persist onboarding and policy settings in an atomic JSON file.
- Add the basic study-session timer and floating side panel.
- Gate macOS 26 Liquid Glass enhancements and verify the macOS 15 material fallback.
- Do not implement browser blocking, app monitoring, nudges, or quitting.

**Verifiable exit criteria**

- A clean checkout builds through the canonical script and launches a foreground `.app`.
- The main window and menu bar presence both appear and can reopen each other.
- A fresh install completes all three onboarding steps; relaunch restores the saved choices.
- Real open Chrome tabs appear as deduplicated domains only; full URLs are not stored or shown.
- Manual domain parsing and public-suffix edge cases pass unit tests.
- Starting/stopping the basic timer shows/hides the floating panel and survives ordinary window changes without stealing focus.
- UI is usable on macOS 15 fallback styling; macOS 26 glass code is availability-gated.

### Phase 2 — AppleScript Chrome enforcement and app nudges

**Scope**

- During an active session, periodically inspect open Chrome tabs through AppleScript using the existing Apple Events entitlement.
- Redirect tabs whose normalized domains match the onboarding blacklist to a calm local dark block page that shows the session time remaining.
- Permanently allow Google, ChatGPT, and Claude domains even if settings contain a conflicting blacklist entry.
- Leave explicit hooks for an optional Chrome extension strict-mode provider, but do not build the extension or native messaging host.
- Observe selected distracting native apps through `NSWorkspace`.
- Implement the per-app escalation ladder: gentle nudge, five-minute snooze, returning nudge, user timer with a hidden 15-minute rejection cap, approximately 30-second visible warning, and cooperative quit request.
- Never target Study Block for termination. Observe and report cooperative termination failure; never force-quit.
- Stopping the session clears enforcement timers, snoozes, warnings, and pending quit attempts.
- Add focused tests for permanent-domain allowances, blacklist matching, timer validation, and escalation transitions.

**Verifiable exit criteria**

- With an active session and `youtube.com` open in a real Chrome window, the tab redirects to the local block page within a few seconds.
- Google, ChatGPT, and Claude tabs remain untouched.
- The block page is calm, dark, local, and displays the current session time remaining.
- A selected harmless distracting app exercises the nudge, snooze, returning nudge, user timer, warned quit, and successful/failed cooperative-quit paths in order.
- Durations above 15 minutes are rejected rather than clamped.
- The warned quit targets only the selected distracting app and never Study Block.
- The Command Line Tools fallback build succeeds, launches the fresh app, and verifies its process.

### Phase 3 — Home and local statistics

**Scope**

- Add Home after onboarding.
- Add start/stop session controls to Home and keep them synchronized with the menu bar.
- Show hours studied, apps blocked, and productive hours.
- Define hours studied as all elapsed session time. Define productive hours as time in sessions that reach their planned countdown rather than being stopped early.
- Finalize `StudySession` and `BlockEvent` persistence and aggregation rules.
- Add empty, active-session, and historical states.
- Add focused tests for session timing, stop/relaunch recovery, midnight boundaries, stat aggregation, and duplicate block events.

**Verifiable exit criteria**

- Home replaces onboarding after completion and Settings can reopen onboarding choices.
- Start/stop from either Home or the menu bar updates every surface consistently.
- Session duration persists across relaunch and is counted exactly once.
- Real Phase 2 enforcement events feed the app-blocked statistic without retry inflation.
- Seeded fixtures produce known values for all three stats.
- Empty and zero states are clear and do not fabricate activity.

### Optional later phase — Chrome extension strict mode

**Scope**

- Build the Manifest V3 Chrome extension.
- Build and sign the native messaging host, host manifest, versioned protocol, local IPC boundary, heartbeat, and policy cache.
- Register and verify the native host during onboarding, with a repair action and AppleScript fallback.
- Replace Phase 1 AppleScript tab discovery with the extension-provided domain list.
- Apply/remove allowlist-first main-frame redirect rules only while a session is active; use the blacklist as supplemental classification.
- Add the extension-owned blocked page and minimal website block-event reporting.
- Add permission education, extension/bridge health status, and recovery UI.
- Do not add force quit, Accessibility-driven control, privileged helpers, or tamper resistance.

**Verifiable exit criteria**

- With the extension connected, starting a session redirects a domain that is not allowlisted; stopping immediately restores access.
- An allowlisted domain remains available, while a blacklisted domain is explicitly classified and redirected.
- The app receives block events containing only normalized domains and updates stats once per defined event.
- Chrome tab discovery works without AppleScript permission and exposes domains only.
- Native messaging rejects unapproved extension origins and malformed or incompatible messages.
- If the app or bridge disappears, extension blocking fails open within the specified heartbeat/expiry window.
- The app, helper, and extension pass a real clean-profile integration test after build/install.

## 5. Verification strategy

- Unit tests:
  - domain and public-suffix normalization
  - whitelist/blacklist conflict rules
  - session/timer calculations
  - 15-minute validation boundary
  - escalation state transitions using an injectable clock
  - stats aggregation and duplicate-event handling
  - bridge schema validation
- UI tests:
  - three-step onboarding
  - Settings revisit
  - Home start/stop synchronization
  - permission-denied and extension-disconnected states
- Integration tests:
  - AppleScript Chrome discovery in Phase 1
  - AppleScript tab redirect and `NSWorkspace` escalation in Phase 2
  - extension/native-host handshake and policy updates in the optional strict-mode phase
  - dynamic redirects against a disposable Chrome profile
  - cooperative termination against a harmless test app
- End every implementation session by running the canonical build/run script and confirming the actual app process and visible launch before updating `HANDOFF.md`.

## 6. Permissions and distribution

| Capability | Phase | Permission or packaging impact |
| --- | --- | --- |
| Read Chrome tabs through AppleScript | 1 only | Requires an Apple Events usage description, hardened-runtime Apple Events entitlement, and user approval to automate Chrome. Denial must fall back to manual entry. |
| Redirect Chrome tabs through AppleScript | 2 | Reuses the Apple Events entitlement and automation approval. Enforcement is polling-based and intentionally bypassable. |
| Observe ordinary app launches/activation | 2 | Use `NSWorkspace`; do not request Accessibility permission by default. Background/agent-only apps are outside the product scope. |
| Quit distracting apps | 2 | `NSRunningApplication.terminate()` is cooperative and can fail. A sandboxed app cannot terminate other apps. |
| Chrome extension tab discovery | Optional strict mode | Requires narrowly explained Chrome extension permissions such as `tabs`, plus `nativeMessaging`, `storage`, and declarative network request/host access appropriate to the final rule design. |
| Chrome extension redirects | Optional strict mode | Broad host access may create a prominent install warning and Chrome Web Store review/privacy obligations. Request only what blocking requires. |
| Native messaging | Optional strict mode | Requires installing a per-user host manifest with an absolute host path and fixed allowed extension origin; app/helper upgrade paths must preserve registration. |
| Direct distribution | Release | The core quit behavior points to Developer ID signing, hardened runtime, and notarized distribution outside the Mac App Store, with App Sandbox disabled. |

No Screen Recording, Full Disk Access, Accessibility, administrator privileges, kernel/system extension, or privileged helper is planned.

## 7. Main risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| App Sandbox conflicts with quitting other apps | High | Use the confirmed direct Developer ID–signed/notarized distribution path with App Sandbox disabled; never imply Mac App Store compatibility while this feature remains. |
| Native-host installation breaks after move/update | High | Use a stable installed binary location, explicit health check, repair flow, and clean-machine upgrade test. |
| Chrome extension permissions feel invasive | High | Keep processing local, discard full URLs immediately, request minimal permissions, explain each permission, and publish a precise privacy statement before distribution. |
| Domain normalization misclassifies multi-label suffixes | Medium | Use a public-suffix-aware resolver, version its data/dependency, and test international and multi-label domains. |
| Cooperative app quit fails or triggers unsaved-work prompts | Medium | Warn clearly, request normal termination only, observe the result, never force-quit, and report failure without looping aggressively. |
| Timer/escalation drift across sleep, relaunch, or clock changes | Medium | Store absolute deadlines, inject a clock in tests, recompute from wall-clock state on wake/relaunch, and cancel everything when the session ends. |
| Extension and app policy diverge | Medium | App is authoritative; use versioned snapshots, acknowledgements, heartbeat/expiry, idempotent updates, and visible connection health. |
| Floating timer annoys or steals focus | Medium | Use a narrow non-activating panel, allow move/hide, remember placement safely per display, and test multiple Spaces/displays. |
| “Blocked” statistics inflate through retries/redirect loops | Medium | Define a deduplication window and event identity before Phase 2 aggregation; test repeated navigations and app activations. |
| macOS 26 visual APIs leak into the macOS 15 path | Low | Centralize availability-gated styling, use system controls first, and build/test against the macOS 15 deployment target. |

## 8. Review gates

- **Completed:** Phase 2 AppleScript enforcement behavior, permanent allowed domains, and app escalation behavior were approved and verified.
- **Before Phase 3:** apply the approved metric definitions above and validate them with fixtures.
- **Before optional strict mode:** review the onboarding registration/repair experience and allowlist-first redirect rule design.
- **Before release:** review extension permissions, privacy copy, signing, native-host installation/repair, and clean-machine behavior.

## 9. Primary technical references

- [Chrome native messaging](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging)
- [Chrome Extensions API and permissions reference](https://developer.chrome.com/docs/extensions/reference/)
- [Apple: App Sandbox limitations](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox)
- [Apple: `NSRunningApplication.terminate()`](https://developer.apple.com/documentation/appkit/nsrunningapplication/terminate())
- [Apple: Apple Events usage description](https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription)
- [Apple: Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Apple: SwiftUI Liquid Glass](https://developer.apple.com/documentation/swiftui/glass)
