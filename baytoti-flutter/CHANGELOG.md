# Baytoti Flutter — Changelog

## Unreleased (2026-11-19)

### Added
- **HTTP backend**: Entire data layer now talks to `https://mazier.website/api/`
  (PHP + MariaDB on Oracle Cloud). Replaces Firebase/Firestore. See
  `backend/API.md` for the contract and `backend/DEPLOY.md` for the ops notes.
- **Multi-theme support** (like the Quran app): 5 color presets (teal, blue,
  purple, rose, green) picked via swatches on the settings screen, persisted in
  `SharedPreferences` (key `bayti_theme_preset`). `BaytiColors.applyPreset()`
  swaps the mutable palette, triggers a top-level `MaterialApp` rebuild, and
  recolors the frosted-glass background and hero cards.
- **Arabic-digit price parsing**: `parseFlexibleDouble()` /
  `toAsciiDigits()` in `lib/data/arabic_text.dart` accept Arabic-Indic
  (٠-٩), Persian (۰-۹), and the Arabic decimal separator (٫) alongside
  ASCII. Wired through purchase dialog, price prompt, and quick-add sheet.
- **Hosted product catalog**: Autocomplete JSON lives at
  `https://mazier.website/baytoti/products.json` (100 Jordanian items).
  Lets us refresh the catalog without shipping a new build.
- **Invite landing page** at `projects/baytoti/invite.html` — simple Arabic
  landing on GitHub Pages that reads `?code=XXXXXX`, shows the code, offers
  "copy" + "open app" buttons, and step-by-step join instructions.

### Changed
- `GlassBackground` and `GlassHero` now read colors from `BaytiColors` instead
  of hardcoding teal/amber, so theme switches are visible.
- Share links (`list_screen`, `members_screen`, `settings_screen`) point at the
  new `invite.html` instead of the Google-Sheets-backed `bayti.html`.
- Identity model: no Firebase Auth — users are identified by a local display
  name (`DisplayName`, key `bayti_displayName`, default `ضيف`). List access is
  gated by `listId` + 6-character `inviteCode` (alphabet excludes 0/O/1/I).

### Removed
- Firebase Dart packages, `firebase_options.dart`, `firebase.json`,
  `firestore.rules`.
- Android: Google Services Gradle plugin, `google-services.json`.
- iOS/macOS: `GoogleService-Info.plist` and its stale references in
  `Runner.xcodeproj/project.pbxproj`.

### Fixed
- Xcode build failure after Firebase removal (`Build input file cannot be
  found: GoogleService-Info.plist`) by pruning 4 references from
  `project.pbxproj`.
- Missing `ios/Flutter/Profile.xcconfig` created to silence a CocoaPods
  warning about a missing base configuration.
