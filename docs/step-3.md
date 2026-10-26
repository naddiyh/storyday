# Step 3: interactive calendar

## Delivered

Home reuses the existing theme, routes, preferences, and date arithmetic. The
calendar is split into a screen, grid, day cell, and icon presentation mappings.
Date selection is shared with Create through the existing Riverpod provider.
`CalendarMonth.shift` constructs the destination month and clamps the selected
day to its last valid day, with no UTC conversions or fixed-duration date math.
Today reads an injectable clock; weekday columns use Material localizations.

Calendar fixtures are keyed by full local dates in the current month, so they do
not repeat when navigating. Eight explicit moods use stable enum identifiers.
Ordinary journal/checklist previews are separate from the secret-existence
boolean. Secret activity has no title/body/media fields and yields only a lock.
At most two activity icons plus an overflow marker occupy a day; accessible
labels provide the activity summary. Today has an underline; selection has a
border and semantic selected state as well as a background.

Flower, star, and leaf decorations can be selected or cleared per date. Session
state is intentionally not persisted. The existing appearance toggle controls
visibility; Cute and Cool provide the same controls with different corner radii
and accent opacity through CalendarStyle, a ThemeExtension. Material ColorScheme
continues to supply all colors. Theme and light/dark/system choices still persist.

## Files

- core/design/calendar_style.dart: calendar component tokens.
- core/design/app_theme.dart: central icon and personality styling.
- features/calendar/domain/calendar_month.dart: clamped month shifts.
- features/calendar/domain/day_activity.dart: mood, decoration, activity models.
- features/calendar/data/demo_calendar.dart: fixtures, clock, decoration state.
- features/calendar/presentation/: screen, grid, day cell, icon mappings.
- features/themes/presentation/themes_screen.dart: decoration toggle explanation.
- test/calendar_test.dart: deterministic date/privacy/interaction/responsive tests.
- tool/preview_test.dart: four personality/appearance screenshots.

## Validation

Existing baseline: 10 passing tests. Updated suite: 16 passing tests, including
clamping/leap years, full-date fixture isolation, lock-only privacy, decoration
selection, Create date propagation, and 320px/200% text in four theme combinations.
Native Android/iOS build limitations remain unchanged. Browser previews are a
local development aid, not a supported production web client.

## Limitations and next step

Activity is labeled sample data. Decorations reset at restart. The avatar is a
neutral placeholder. No full journal CRUD, encryption, sync, reminders, native
widgets, or complete recap has been added. Step 4 should introduce the ordinary
note model, local repository, and mixed text/checklist editor as a tested vertical
slice before cloud sync or vault implementation.
