# Lenote

A Flutter foundation for a personal, calendar-first journal on Android and iOS.

## Available now

- Home, Memories, Create, Recap, and Profile navigation.
- Decorated monthly calendar with labeled fixture activity.
- Local ordinary journal/checklist/mixed-note saving and editing.
- Full-page paper editor with checklist completion, retry-safe save, and confirmed deletion.
- Date-grouped archive with text search and All/Journal/Lists/Schedule filters.
- Local schedules with repeat rules, calendar indicators, editing and deletion.
- Focus setup, start/pause/resume timer and actual elapsed-time recap totals.
- Exactly three themes: Sweet Pastel, Calm & Natural, and Midnight.
- Locally persisted themes and independent Light/Dark/System modes.
- Deterministic recap statistics from saved ordinary notes.
- Regression tests and Playwright CLI visual checks.

Home combines sample journal entries with saved notes and schedules; decoration edits remain session-only.
Secret Note and Quick Mood were removed at the user's request on October 24, 2026,
including their calendar indicators, filters, recap and settings UI.
Supabase, authentication, device notifications, ambient audio/system DND,
rich media/drawing, and story export remain unavailable. Active focus sessions
continue while the app is open; completed records and schedules restore after restart.
See [the planner update report](docs/planner-update-report.md).

## Setup

This foundation targets Flutter **3.24.0** / Dart **3.5.0**.
Dependency versions and CI are pinned for that baseline. Upgrade the SDK and
dependencies together in a separate change after testing both mobile platforms.

```sh
flutter --no-version-check pub get --enforce-lockfile
flutter --no-version-check run -d <device-id>
```

The optional `--no-version-check` flag avoids a slow SDK Git tag fetch observed
on the development machine. It does not change the installed SDK.

Android requires a working Android SDK, command-line tools, accepted licenses,
and compatible Java installation. On the assessed Windows machine, command-line
tools are missing and Android Studio's bundled JBR is incomplete. Repair those
before attempting a mobile build. Run `flutter --no-version-check doctor -v` to
check readiness. iOS requires macOS, Xcode, CocoaPods, and signing setup.

The scaffold uses provisional ID `com.example.lenote` and development signing.
Set the final application ID and release signing before distribution.

## Checks

```sh
dart format --output=none --set-exit-if-changed lib test tool
flutter --no-version-check analyze
flutter --no-version-check test
```

To render emulator-free previews of the actual Flutter screens:

```sh
flutter --no-version-check test tool/preview_test.dart
```

PNG images are written to `build/previews/` (ignored by Git).

## Structure

```text
lib/app/                    app entry, routes, navigation shell
lib/core/design/            shared design tokens and themes
lib/core/widgets/           reusable page components
lib/features/calendar/     date arithmetic and calendar preview
lib/features/themes/       appearance model, store, controller, screen
lib/features/*/presentation/ future-feature preview screens
test/                       foundation regression tests
docs/                       PRD and architecture notes
android/ and ios/            native Flutter runners
```

See [architecture](docs/architecture.md) and the unchanged
[product requirements](docs/product-requirements.md). The prototype stores ordinary notes and planner data locally in shared preferences.
Cloud sync is not connected. Secret Note and mood features are no longer part of the current UI.

## Updated UI scope

Navigation now uses Home, Memories, Create, Recap, and Profile. Appearance lives
under Profile, with three visual themes and light/dark/system modes saved locally.
Home includes saved notes and schedules alongside sample entries. Memories and Recap use locally saved data.
The central plus has no visible label and opens the full Create page with a close
action. Supabase is not connected. Responsive behavior and
regression results are recorded in [the responsive UI report](docs/responsive-ui-report.md).
Run `tool/responsive-check.ps1` against the compiled web preview for browser captures.

## Interactive calendar

Home now supports clamped month navigation, activity indicators, selected-day
previews, and session-only flower/star/leaf decorations. See [Step 3](docs/step-3.md).

## Themes & Appearance

Open Profile > Themes & Appearance. All three identities have palette swatches
and live widget miniatures. Tap a card to preview, then Apply theme or Cancel.
Light/Dark/System is independent of theme identity: Midnight uses light slate
in Light mode and deep navy in Dark mode. Preferences restore on restart.
Legacy lavender/peach IDs migrate to Sweet Pastel; sage/monochrome migrate to
Calm & Natural. No external art or downloaded themes are required.

