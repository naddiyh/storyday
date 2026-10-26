# Daystick reference UI redesign and regression report

## Reference and scope

Reviewed all 18 pages of the supplied Daystick Scrapbook Journal PDF, including
weekly/monthly Home, Create, Recap, themes, archive, Profile, journal/checklist
editors, secret flow, and mood sheet. The PDF is visual reference, not authority
to introduce AI or expose secret content. The app retains its three theme
identities, local preferences, ordinary-note repository, and five destinations.

## Implemented

- Lavender canvas, white paper panels, strong compact headings, pill controls,
  rounded pastel activity cells, and prominent circular central Create action.
- Shared ScrapbookHeader, ScrapbookPanel, and ActivityTile Flutter components.
  A neutral bird icon stands in for final original mascot artwork.
- Home Week/Month switching and All/Journal/Lists/Mood/Secret indicator filters.
  Full-date fixtures, date selection, Today, month clamping, decoration choices,
  and selected-day summaries remain intact. Filtering hides indicator metadata;
  it never loads secret content or titles.
- Memories uses paper cards and preserves local ordinary-note search.
- Create uses format cards while preserving journal/checklist/mixed-note editing.
- Profile uses grouped panels and the existing Themes & Appearance entry point.
- Recap uses compact statistic tiles calculated from actual saved notes and
  checklist tasks, with honest empty/mood states rather than invented activity.
- Light, Dark, and System appearances remain supported in all three themes.

## Bugs reproduced and fixed

### Checklist completion lost on edit

Reproduction: seed a checklist with a completed Passport task; open it, save
without changing the task, and inspect persisted state. The historical save
mapping created every ChecklistItem with its default done=false. Running the
new regression test with that historical mapping fails: expected true, actual
false. Evidence: build/checklist-regression-before.txt (local generated output).
The editor now initializes and maintains completion state alongside its text
controllers, including add/remove operations, exposes checkboxes, and writes the
saved done flags. The regression test passes with the fix restored.

### Unconfirmed deletion

Deleting a saved memory previously removed it immediately. A confirmation now
provides Keep and Delete; the new widget test verifies Keep retains the note
and Delete removes it.

### Misleading recap counts and corrupted separators

The old recap called checklist-note counts checklist items and labelled entry
counts as a mood overview. The redesigned summary counts completed tasks,
body-bearing journal entries, lists, and distinct date-only recorded days.
Moods are not inferred. Visible corrupted text separators were replaced with
readable separators, including the Privacy and Security settings label.

## Validation

- Baseline before changes: 20 existing tests passed.
- Final regression suite: 21 tests passed.
- Added a widget regression for completion preservation and deletion confirmation.
- Extended deterministic calendar tests to switch Week (7 cells) and Month
  (31 cells for the October fixture).
- Existing tests cover date boundaries, ordinary-only data, secret lock privacy,
  theme preview/apply/cancel, preference restoration, all five destinations,
  reduced motion, and 320px layouts at 200% text across six theme/mode pairs.
- dart format . completed. Flutter analysis is clean.
- Web release build completed successfully; Edge rendered the updated app with zero startup JavaScript errors. The compiler emitted a non-fatal Cupertino font warning from the existing adaptive controls; Material icons rendered successfully.
- Actual Flutter screen rendering is captured by tool/preview_test.dart.
  Generated screenshots live under build/previews/ and are not source assets.

## Principal changed files

lib/core/design/app_theme.dart; lib/core/widgets/page_content.dart;
lib/core/widgets/scrapbook.dart; lib/app/shell.dart;
lib/features/calendar/presentation/calendar_screen.dart, calendar_grid.dart,
calendar_day.dart; lib/features/search/presentation/search_screen.dart;
lib/features/notes/presentation/create_screen.dart;
lib/features/recap/presentation/recap_screen.dart;
lib/features/settings/presentation/settings_screen.dart;
test/calendar_test.dart; test/scrapbook_test.dart; tool/preview_test.dart.

## Remaining limitations

This is an adaptation of the reference, not every feature pictured in its PDF.
Schedules, focus timers, voice/photos/freehand canvas, production mascot assets,
secret encryption, notifications, and story export remain unimplemented.
AI suggestions are excluded by the approved PRD. The calendar activity is still
labeled fixtures; decorations remain session-only. No account or logout is
simulated. Android/iOS device validation still requires the previously documented
toolchain setup. Browser preview is a development aid. Local ordinary-note
storage remains the existing prototype; this change does not introduce cloud sync.
