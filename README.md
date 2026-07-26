# Study Block

![Study Block app icon](Design/AppIconMaster.png)

A native macOS focus companion that keeps study sessions visible and distractions out of the way.

## Features

- **Editable session presets** — configure three timed presets or use an open-ended timer.
- **Floating clock** — keep a small, always-on-top countdown or elapsed-time clock within sight while you work.
- **AppleScript enforcement** — redirect explicitly blocked Chrome sites to a calm local session page while productive and study domains remain available.
- **Nudge ladder** — respond to distracting apps with a gentle reminder, a limited allowance, a visible warning, and finally a cooperative quit request.
- **Strict mode** — disable snoozing and shorten escalation timing when you want a firmer session.
- **Session environment** — pause distracting music apps and optionally enable Do Not Disturb for the duration of a session.
- **Live settings** — edit study sites, blocked sites and apps, session presets, and session defaults after onboarding.
- **Local history and stats** — review completed sessions, today and weekly focus time, and your current streak.
- **macOS integration** — launch at login, recover an interrupted session, and suspend enforcement cleanly across sleep and wake.

Study sites always beat the blocklist, and Google, ChatGPT, and Claude remain available. Study Block keeps settings, session checkpoints, and history on your Mac. It never force-quits apps, and its final enforcement step targets only the distracting app.

## Requirements

- macOS 15 or later
- Apple Command Line Tools

Xcode is supported but not required for local development. Developer ID signing
and notarization require Apple distribution credentials and the appropriate
Xcode tooling.

## Build and run

From the project root:

```sh
./script/build_and_run.sh
```

The script uses Xcode when it is installed. Otherwise, it compiles with the Apple Command Line Tools, creates and ad-hoc signs a local app bundle, and launches it.

To build, launch, and confirm that the app process is running:

```sh
./script/build_and_run.sh --verify
```

Run the lightweight domain, policy, escalation, settings, and session-history
checks with:

```sh
./script/run_smoke_tests.sh
```

## Project structure

```text
StudyBlock/
├── App/          App entry point and scene composition
├── Models/       Settings, sessions, policy, and escalation state
├── Services/     Chrome, workspace, panel, and termination adapters
├── Stores/       App-wide session, history, and enforcement coordinators
├── Views/        Onboarding, settings, timer, menu bar, and nudges
├── Resources/    App metadata, entitlements, and bundled icon
└── Assets.xcassets/
StudyBlockTests/  Focused policy, persistence, and state-machine tests
script/           Canonical build, launch, and smoke-test commands
Design/           Source artwork, including the 1024 px icon master
```
