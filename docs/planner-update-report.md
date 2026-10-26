# Schedule / Focus and feature-removal update

Date: 2026-10-24.

The latest user instruction removes Secret Note and Quick Mood from the product. This overrides those portions of the original PRD and PDF. The source PRD itself remains unchanged as historical reference.

## What changed

- Removed Secret Note and Quick Mood cards, all secret/mood calendar fields and icons, the corresponding filters, mood recap UI, and the Secret Notes settings entry. There is no new secret storage, encryption or biometric implementation.
- Create now contains four formats: Journal / Note, Checklist / To-do, Schedule, Focus session. Its central navigation action remains a full page; the visible Create label and calendar Week mode remain removed.
- Added the PDF's Schedule form: title, deterministic keyword-based icon suggestion and icon picker, selected date, start/end time, location, reminder preference, repeat controls, notes, and calendar preview.
- Schedules save locally, restore after restart, support editing and confirmed deletion, appear in calendar cells and selected-day details, and have a searchable Schedule archive filter. Once, daily, weekends and weekly recurrence respect the first date. Calendar filters now filter selected-day entries as well as indicators.
- Added the Focus setup page and Focus timer page, following the PDF's task selection, duration choices, character, progress ring, countdown, pause/resume and Step done structure. Tasks can come from unfinished checklist items or a custom task. Duration supports 15, 25, 45 and custom 1–180 minutes.
- Focus uses elapsed wall time rather than counting timer callbacks, catches up after background throttling, excludes paused time, saves actual elapsed seconds once, and adds completed-session totals to Recap. An active session can be reopened from Home.
- Archive note cards now open the existing editor; schedule cards open their edit form.

## Storage and interfaces

`PlannerData` holds `Schedule` and `FocusRecord` models. `PlannerStore` has shared-preferences and in-memory implementations. Planner mutations serialize writes and publish state only after successful persistence. Main loads planner data at startup. No backend, credentials or new package dependency were introduced.

New implementation: `lib/features/planner/domain/planner.dart`, `focus_controller.dart`; `data/planner_store.dart`; `presentation/schedule_page.dart`, `schedule_symbols.dart`, `focus_pages.dart`.

Integrated with app routing/bootstrap, Create, calendar models/data/grid indicators/filters, Memories, Recap and Profile. Updated existing regressions plus `test/planner_test.dart`; browser capture tool: `tool/planner-check.ps1`.

## Bugs fixed during regression

- Focus originally created a periodic timer when merely reading its provider, even with no active session. Tests reproduced leaked timers throughout the app. Tickers now start only for an active running session and stop on pause, completion or disposal.
- Concurrent planner writes retain both schedule and focus records instead of overwriting one another. Failed writes do not publish phantom schedules.
- Focus completion is guarded against repeated activation and records actual elapsed time rather than the planned duration when Step done is pressed early.
- Discontinued secret/mood indicators and settings were removed throughout the active UI, rather than leaving stale entry points.

## Limits

Reminder timing is stored but native notification delivery is not implemented. The PDF's ambient-audio and OS Do Not Disturb controls remain visible but disabled, with an explicit explanation; the app does not pretend to change device settings or play sound. Active focus state lasts for the current app run; completed records persist. No AI breakdown controls or AI-generated tasks were added. This update does not claim production Supabase integration or complete rich-media/story export functionality.

## Final validation and browser evidence

- `flutter --no-version-check pub get`: passed; no new dependencies.
- `dart format .`: passed (46 Dart files).
- `flutter --no-version-check analyze`: passed, no issues found.
- `flutter --no-version-check test`: all 48 tests passed after the final Schedule styling change. Log: `output/playwright/planner-tests.log`.
- A targeted rerun of the 10 planner regressions also passed. Covered recurrence, persistence/restart, concurrent writes, failed saves, clock/pause correctness, background catch-up, schedule create/edit/delete via UI, focus creation/completion and 320px/200% text layouts.
- Release HTML web build with `UI_REFERENCE_REVIEW=true`: passed. This preview uses the PDF's October 22, 2026 reference date; normal builds use the current date.
- Playwright CLI captured eight screens at 320×568, 390×844 and 768×1024 (24 viewport screenshots). Each capture batch returned zero JavaScript page errors. Three Schedule screenshots were refreshed after the final white-paper input refinement; that batch also returned no errors.
- Browser interaction checks opened Schedule from Create, entered `Watch a series`, location and notes, saved it, and observed the event in Home with its time and location. Then opened Focus Session from Create, started the timer, paused, resumed, pressed Step done, and observed an actual elapsed-time record of `1m 11s` in Recap. Reloading the compiled app restored both the schedule and completed focus record.
- No application JavaScript errors occurred. Fresh captures had no console warnings; reused sessions after reload logged one Flutter bootstrap service-worker timeout (`prepareServiceWorker took more than 4000ms`). The loader continued and the app rendered. This browser-startup warning remains; it is not reported as fixed.

Evidence: `output/playwright/planner/cli-results.log`, `refine-schedule.log`, `console-final.log`, and the screenshots in that directory. The capture tools now initialize native-command logs with the correct PowerShell encoding and wait for the Flutter page title before capture.

Preview: http://127.0.0.1:5175/

Screenshots: [Create](../output/playwright/planner/390x844-create.png), [Schedule](../output/playwright/planner/390x844-schedule.png), [Focus setup](../output/playwright/planner/390x844-focus-setup.png), [Paused timer](../output/playwright/planner/focus-timer-paused.png), [Restored Recap](../output/playwright/planner/recap-restored.png).

These are browser viewport checks and widget tests, not physical Android/iOS device certification or a claim that every PDF page is pixel-identical. No ordinary note data was deleted as part of removing the discontinued features.
