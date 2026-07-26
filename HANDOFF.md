# Study Block Handoff

## Current state

Phases 1 and 2 are complete. During an active session, Study Block now redirects explicitly blacklisted Chrome tabs through AppleScript to a calm local countdown page and monitors blacklisted native apps with the full escalation ladder. Google, ChatGPT, and Claude are permanently allowed. The app is built and open at the idle session screen.

## Last session summary

Shipped Phase 2 with a provider boundary for optional strict mode, AppleScript Chrome polling, blacklist-only redirects, the Application Support `block.html` countdown page, `NSWorkspace` app activation monitoring, a per-app escalation state machine, a SwiftUI nudge panel, hidden 15-minute timer validation, warned cooperative termination, and focused policy/state-machine tests.

Live verification used the persisted onboarding policy (`youtube.com` and TextEdit). During a real 25-minute session, YouTube redirected to the local block page within two seconds while Google, ChatGPT, and Claude URLs stayed unchanged. TextEdit exercised gentle nudge → five-minute snooze → returning nudge → rejected 16-minute timer → accepted one-minute timer → visible 30-second warning → cooperative quit. TextEdit closed; Study Block and Chrome remained running. Stopping the session disabled redirects immediately.

`./script/run_smoke_tests.sh` and `./script/build_and_run.sh --verify` pass through the Command Line Tools fallback.

## Next steps

Review Phase 2. After approval, begin Phase 3 only: Home, persisted session/block events, and local statistics. The Chrome extension and native messaging host remain an optional later strict-mode upgrade if AppleScript enforcement proves insufficient.

## Open questions

None. Xcode is still not installed; continue using the existing Command Line Tools fallback and do not download Xcode.
