# Daystick responsive UI and regression report

Reference: `Daystick — Scrapbook Journal App-selection (1).pdf`, particularly PDF pages 2 (monthly calendar) and 3 (Create). The user's explicit changes take precedence over the PDF: no Week mode, no visible Create label in the bottom navigation, and a full-page Create route instead of a bottom sheet. The PDF is a visual reference, not permission to introduce its AI features or expose private notes.

## Changes

- Removed Week state, controls, and the alternate seven-day calendar rendering. Month navigation, Today, selected dates, decorations, and activity indicators remain functional.
- Moved calendar filters into a dedicated, left-aligned row directly below the month controls and above weekday headings. Filters wrap on narrow screens or with enlarged text; they no longer depend on a horizontal scroller.
- Kept five navigation controls, with an accessible Create label for assistive technology but no visible text beneath the central plus. Centered and constrained the navigation bar on wider screens.
- Both creation entry points open the shared `/create` page above the tab shell. It has a close button, no bottom navigation, retains the selected date, and returns to the originating screen. Direct links have a safe Home fallback. Rapid repeat activation is guarded.
- Constrained Create to the shared content width. Format cards use equal-height pairs, with natural content height rather than a fixed aspect ratio. Larger text switches to a single column. Functional UI uses Flutter widgets rather than PDF screenshots.
- Replaced the character throughout shared headers and the buddy section with the user's original transparent PNG. The full artwork is contained without stretching or cropping, with bounded image decoding.
- Used the imagegen skill and built-in image generation tool to create a transparent jasmine sticker, integrated into the Flower decoration and selector. Existing Material interface icons remain vector icons. Source and final prompt: [asset-provenance.md](asset-provenance.md).
- Added the missing `cupertino_icons` 1.0.8 font dependency to resolve the build's missing Cupertino font warning.

## Bugs reproduced and fixed

- Create previously opened a bottom sheet from both Home and the central plus. It now opens one full page and preserves date/navigation state.
- Create cards had uneven heights when descriptions wrapped. Equal-height rows now accommodate content and enlarged text.
- Playwright exposed theme preview cards without explicit accessible button roles. They now expose a named button, selected state, and activation action.
- Browser activation reproduced stacked theme previews: applying a theme left another preview visible. A per-screen in-flight guard prevents repeated activation from opening multiple dialogs. A regression invokes duplicate activation and verifies one dialog, then no dialog after Apply.
- Theme navigation/highlighting was adjusted for Create being a page above the four persistent tab branches, while retaining five visible navigation controls on primary screens.

## Changed files

Navigation: `lib/app/shell.dart`, `router.dart`, new `create_navigation.dart`.

Reusable UI: `lib/core/widgets/scrapbook.dart`, new `journal_character.dart` and `responsive_card_grid.dart`.

Calendar: `calendar_screen.dart`, `calendar_grid.dart`, `calendar_day.dart`, `calendar_icons.dart`, new `calendar_toolbar.dart` under `lib/features/calendar/presentation/`.

Feature screens: `lib/features/notes/presentation/create_screen.dart`, `lib/features/themes/presentation/themes_screen.dart`.

Assets/configuration: `assets/characters/companion.png`, `assets/stickers/jasmine.png`, `pubspec.yaml`, `pubspec.lock`.

Tests/tools: `test/calendar_test.dart`, `foundation_test.dart`, `replacement_regression_test.dart`, new `responsive_navigation_test.dart`, new `tool/responsive-check.ps1`.

## Coverage and practical limits

The widget layout matrix covers all five destinations plus Themes at 320×568, 390×844, 844×390, 768×1024, and 1440×900, each at normal and 200% text. Existing tests cover all three theme identities, appearance persistence, ordinary-note search/filtering, checklist editing/deletion, failed-save draft retention, and Secret Notes privacy boundaries.

This is responsive behavior across representative phone, landscape, tablet, and desktop sizes, not certification of every physical device or pixel identity at every size. Narrow or enlarged-text layouts intentionally wrap and scroll. The app continues to use fixture calendar activity and existing local ordinary-note storage. Schedule, focus, secure vault, mood recording, and rich-media tools retain their existing placeholder status; this update does not implement backend or AI features.

## Actual final validation

| Check | Result |
| --- | --- |
| `flutter --no-version-check pub get` | Passed; the subsequent Cupertino font addition also resolved dependencies successfully. |
| `dart format .` | Passed; 39 Dart files, no remaining formatting changes. |
| `flutter --no-version-check analyze` | Passed, no issues found. |
| `flutter --no-version-check test` | Passed, all 38 tests. |
| Release web build, HTML renderer, PWA strategy none | Passed; the missing Cupertino font warning is resolved. |
| Playwright screenshot matrix | 30 captures: six screens at five viewport sizes. Each batch reported zero JavaScript page errors. |
| Fresh matrix browser console | Zero errors, zero warnings. |
| Reused interaction browser console | Zero errors; one existing Flutter service-worker startup timeout warning on reload. The loader continued and the app rendered. |
| PowerShell capture tool | Syntax validation passed; final desktop capture and console check also completed after log-persistence adjustment. |

The web build uses `UI_REFERENCE_REVIEW=true` to hold the reference date at October 22, 2026 and use the PDF's demonstration name. Normal builds use the real date. This flag does not introduce secret data.

### Browser checks and evidence

Used the installed [Playwright skill](C:/Users/ASUS/.codex/skills/playwright/SKILL.md) through `npx --yes --package @playwright/cli playwright-cli`. Fresh snapshots were used for element references. The off-screen Flutter Enable accessibility control required its documented element-evaluation workaround. Batches used CLI `run-code --filename` only for known-route navigation, viewport changes and screenshot capture. The capture script stores CLI output explicitly because Windows PowerShell transcripts did not retain native command output reliably.

- Advanced to November, returned with Today, selected October 16, and verified the secret-only day exposed only a lock indicator.
- Opened Create through the central plus, verified it had no bottom sheet or bottom navigation, then opened Journal and observed `Fri, Oct 16, 2026` in the editor header. Cancel returned to Create; Close returned to Home with the selected date preserved.
- Opened appearance from Profile, applied Midnight, and verified no second preview remained. Theme cards now appear as named buttons in the browser accessibility snapshot. Changed to Dark mode and checked the character, text and surfaces visually.
- Opened the new Create page from Profile in Midnight/Dark and closed it back to Profile successfully.
- Repeated the responsive screenshot matrix after refining card heights and fixing preview activation. Final evidence is under `output/playwright/responsive/`, with `capture-manifest.json` listing 30 viewport captures. `responsive-tests.log` records the final Flutter test run. `cli-results.log` preserves the final desktop batch and zero-error/zero-warning matrix console check.

Screenshots: [Home, 390×844](../output/playwright/responsive/390x844-calendar.png), [Create, 390×844](../output/playwright/responsive/390x844-create.png), [Home, desktop](../output/playwright/responsive/1440x900-calendar.png), [Midnight Dark](../output/playwright/responsive/themes-midnight-dark.png).

Preview: http://127.0.0.1:5175/ . Browser viewport coverage does not replace physical Android/iOS device testing. This Windows environment's existing mobile toolchain limitations remain as documented in README. Exact pixel identity across all PDF pages is not claimed; fixture content, unavailable features, accessibility text scaling, and the requested control changes intentionally differ.
