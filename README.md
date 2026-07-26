# Study Block

![Study Block app icon](Design/AppIconMaster.png)

Study Block is a native macOS focus app for keeping a study session visible and
reducing distractions while it runs. It has a regular app window, a menu bar
control, and a small floating timer.

## Features

- Timed presets and an open-ended session option
- A draggable, always-on-top floating timer
- Chrome tab enforcement that redirects blocked sites during a session
- An app nudge ladder: reminder, short allowance, warning, then a cooperative
  quit request
- Strict mode with shorter escalation timing and no snoozing
- Optional session-scoped Do Not Disturb and music pausing
- Editable study sites, blocked sites and apps, presets, and defaults
- Local session history, weekly focus time, and streaks
- Launch at login and interrupted-session recovery

Study sites take precedence over the blocklist. Google, ChatGPT, and Claude are
always available. Settings, session checkpoints, and history stay on your Mac,
and Study Block never force-quits another app.

## Download

Download the current DMG from the
[latest GitHub release](https://github.com/Jay-2212/study-block/releases/latest).

1. Open `Study-Block.dmg`.
2. Drag **Study Block** to **Applications**.
3. Because this build is unsigned and not notarized, Control-click or
   right-click the app in Applications, choose **Open**, then confirm **Open**.
   This is normally required only the first time.

The release is built for Apple silicon.

## Requirements

- macOS 15 or later
- Google Chrome for tab enforcement
- Apple silicon for the downloadable build

Do Not Disturb control and Chrome tab enforcement may prompt for macOS
permissions when first used.

## Build from source

You need macOS 15 or later and either Xcode or the Apple Command Line Tools.
Clone the repository, then run from the project root:

```sh
git clone https://github.com/Jay-2212/study-block.git
cd study-block
./script/build_and_run.sh --verify
```

The script uses Xcode when available. Otherwise, it compiles with the Apple
Command Line Tools, creates an ad-hoc signed app bundle, launches it, and checks
that the process is running.

For an optimized Release build:

```sh
./script/build_and_run.sh --release --verify
```

Run the focused smoke tests with:

```sh
./script/run_smoke_tests.sh
```

With Command Line Tools, the built app is written to
`.build/Release/Study Block.app`. Xcode builds use `.build/DerivedData`.

## Privacy and behavior

Chrome inspection runs only during onboarding and active sessions. Study Block
stores normalized domains rather than full browsing URLs. It suspends
session-owned enforcement across sleep and restores Chrome tabs it redirected
when a session stops or the app quits normally.

## Project layout

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

## License

Study Block is available under the [MIT License](LICENSE).
