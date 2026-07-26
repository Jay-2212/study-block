# Study Block Handoff

## Current state

Study Block 1.0 is complete and published as GitHub release
[`v1.0.0`](https://github.com/Jay-2212/study-block/releases/tag/v1.0.0).
The repository now has release-oriented documentation, an MIT license,
contribution guidance, a description, and focused topics.

The canonical build script supports optimized Release builds:

```sh
./script/build_and_run.sh --release --verify
```

## Release verification

- All smoke checks passed.
- The Command Line Tools fallback built and launched the arm64 Release app.
- The app bundle passed strict `codesign` verification with its Apple Events
  entitlement.
- `Study-Block-1.0.0.dmg` contains the app and an Applications symlink.
- The local DMG passed `hdiutil verify`, mounted, and launched successfully.
- The published DMG was downloaded again from GitHub, matched SHA-256
  `6153ffffd3a10763cd4de649f8e290901651d639f078e9491475aff591eda0cb`,
  mounted, and launched without crashing.

## Distribution caveat

The release is ad-hoc signed, unsigned for public trust purposes, and not
notarized because this Mac has no Developer ID Application identity or Xcode.
The README documents the right-click **Open** first-launch workaround. A future
trusted distribution still requires Developer ID signing, hardened-runtime
validation, notarization, stapling, and a clean-machine Gatekeeper test.

## Next steps

No product work is pending. The next optional release task is a signed and
notarized build when Apple distribution credentials and full Xcode tooling are
available.

## Open questions

None.
