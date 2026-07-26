# Study Block Handoff

## Current state

Study Block 1.0.2 is implemented, installed, and published from the public
[`Jay-2212/study-block`](https://github.com/Jay-2212/study-block) repository.
The release now exposes one stable asset, `StudyBlock.dmg`, so the permanent
latest-release URL remains valid across future versions.

The static product site is live at
[`studyblock.jaybharti.me`](https://studyblock.jaybharti.me). GitHub Pages
publishes `docs/` from `main`; Cloudflare has an unproxied CNAME from
`studyblock.jaybharti.me` to `jay-2212.github.io`, and GitHub Pages enforces
HTTPS.

## Last session

- Installed and applied the `frontend-design` skill.
- Built the responsive product site with accessible semantic HTML, a deliberate
  type and color system, native-style product mockups, reduced-motion support,
  metadata, favicons, and hand-rolled reveal animations.
- Added the permanent latest-release download URL and client-side GitHub release
  version display with a graceful fallback.
- Changed release packaging to produce `dist/StudyBlock.dmg`, uploaded the
  stable 1.0.2 asset, verified it, and removed the obsolete versioned asset.
- Made the repository public, enabled GitHub Pages, configured the custom domain,
  created and verified the DNS-only Cloudflare CNAME, and enabled HTTPS.

## Verification

- HTML validation and JavaScript syntax checks passed.
- Desktop and 390 px responsive checks found no horizontal overflow.
- Live HTTPS rendered `v1.0.2` from the unauthenticated GitHub API with no
  browser console warnings.
- The GitHub repository returned HTTP 200 without authentication.
- The permanent latest-release URL downloaded `StudyBlock.dmg`; its SHA-256 is
  `1b1590b6ede9a5a12883876a585961750d76ac62335445dcd3dd4ee8ab102b7e`,
  matching the uploaded file, and `hdiutil verify` passed.
- GitHub Pages reports the site built, its certificate approved, and HTTPS
  enforcement enabled. HTTP redirects to HTTPS and the live HTTPS page returns
  200.
- All smoke checks passed, and `./script/build_and_run.sh --verify` built and
  launched the app through the Command Line Tools fallback.

## Next steps

Trusted app distribution still requires Developer ID signing, hardened-runtime
validation, notarization, stapling, and a clean-machine Gatekeeper test.

## Open questions

None.
