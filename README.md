# Study Block

![Study Block app icon](Design/AppIconMaster.png)

A native macOS focus companion that keeps study sessions visible and distractions out of the way.

## Features

- **Session presets** — start a focused 60, 90, or 120-minute session, or use an open-ended timer.
- **Floating clock** — keep a small, always-on-top countdown or elapsed-time clock within sight while you work.
- **AppleScript enforcement** — redirect explicitly blocked Chrome sites to a calm local session page while productive and study domains remain available.
- **Nudge ladder** — respond to distracting apps with a gentle reminder, a limited allowance, a visible warning, and finally a cooperative quit request.
- **Strict mode** — disable snoozing and shorten escalation timing when you want a firmer session.
- **Session environment** — pause distracting music apps and optionally enable Do Not Disturb for the duration of a session.

Study Block keeps its settings and local session state on your Mac. It never force-quits apps, and its final enforcement step targets only the distracting app.

## Requirements

- macOS 15 or later
- Apple Command Line Tools

Xcode is supported but not required.

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

Run the lightweight policy and domain checks with:

```sh
./script/run_smoke_tests.sh
```

## Project structure

```text
StudyBlock/
├── App/          App entry point and scene composition
├── Models/       Settings, policy, and escalation state
├── Services/     Chrome, workspace, panel, and termination adapters
├── Stores/       App-wide session and enforcement coordinators
├── Views/        Onboarding, settings, timer, menu bar, and nudges
├── Resources/    App metadata, entitlements, and bundled icon
└── Assets.xcassets/
StudyBlockTests/  Focused policy, persistence, and state-machine tests
script/           Canonical build, launch, and smoke-test commands
Design/           Source artwork, including the 1024 px icon master
```
