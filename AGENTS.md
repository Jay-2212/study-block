# Study Block Project Guidance

## Session workflow

1. At the start of every session, read `HANDOFF.md` first.
2. Read only the files relevant to the current task. Never re-scan the whole codebase.
3. Build one feature per session.
4. Do not write application code until `PLAN.md` has been reviewed and approved.
5. At the end of every implementation session, build and run the app to verify that it launches.
6. After verification, update `HANDOFF.md` with the current state, the last session's work, next steps, and open questions. Keep it short and overwrite stale information instead of appending an endless history.

The planning-only bootstrap session is the sole pre-project exception to the build-and-run requirement because no Xcode project exists yet.

## Product and stack

- Build a native macOS app in Swift using SwiftUI.
- Use an Xcode project, not Swift Package Manager, as the application project format.
- Provide both a regular app window and a menu bar presence.
- Use native macOS structure and controls first. Use Liquid Glass where the deployment OS supports it and system-adaptive materials as the fallback.
- Use AppKit only behind small, explicit bridges when SwiftUI cannot provide the required menu bar, floating panel, workspace, or window behavior.
- Control Chrome through a companion Chrome extension and native messaging bridge. Register and verify the native host during onboarding once the Phase 3 host exists; retain AppleScript domain discovery as a fallback.
- Persist settings and local statistics as atomic JSON files in Application Support.

## Architecture and coding standards

- Keep source files small, single-purpose, and roughly under 300 lines.
- Organize code by responsibility: app entry point, feature views, models, stores, services, and narrowly scoped platform bridges.
- Keep SwiftUI as the source of truth; do not duplicate state in AppKit coordinators or bridge objects.
- Separate app-wide session state, durable preferences, window state, and view-local state deliberately.
- Prefer semantic colors, system materials, standard controls, keyboard access, and accessible labels.
- Keep menu bar labels short and action-oriented; open the main window for deeper workflows.
- Keep security- and permission-sensitive behavior explicit. Never silently broaden permissions or enforcement.
- Add focused tests for domain normalization, whitelist/blacklist rules, timer limits, escalation state transitions, and persistence.

## Build and run

- The canonical build/run entry point is `./script/build_and_run.sh`.
- Run `./script/run_smoke_tests.sh` for the lightweight domain-normalization checks.
- Run `./script/build_and_run.sh --verify` to stop the existing process, build the `StudyBlock` scheme in Debug for macOS, launch the fresh `.app`, and verify its process.
- The script prefers `xcodebuild`. When Xcode is unavailable, it uses the installed Command Line Tools to compile, ad-hoc sign, and launch the same app sources as a local development fallback.
- The Codex Run action is wired to `./script/build_and_run.sh`.

## Scope discipline

- Follow the approved phase and current session scope.
- Do not begin a later phase opportunistically.
- Do not commit, push, publish, or change signing/distribution settings unless the user explicitly requests it.
