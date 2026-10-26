# Daystick visual refinement and regression ? 26 October 2026

The currently supplied PDF has **36 pages**, replacing the earlier eight-page reference. Reference metadata/checksum is saved in `output/playwright/daystick36/reference.json`. Pages were rendered at 390 ? 844 for comparison.

## Changes

- Home: month dropdown opens a real month/year selector; previous/next month and return to today work. Filters follow the PDF placement and use compact pills. Calendar cells and month buttons were refined. Selecting a day's header opens its detail page.
- Memories: a real date-range sheet replaces the calendar shortcut. Presets, custom inclusive dates, counts and Clear apply to the archive without changing saved data. Saved notes open a read view, with Edit, Share preview and confirmed Delete.
- Journal: white writing surface, compact header and five-action toolbar; text style sheet (bold, italic, underline, text size, mixed content) and sticker picker. Selected formatting/stickers persist with the note. Existing note records remain readable. Checklist toggles preserve the added fields.
- Checklist: category pills, progress, separated task rows, Add/remove item and Home Top 3 explanation. Categories persist.
- Schedule: optional cost now persists; date/time alignment and notes spacing adjusted. Existing save, recurrence, icon choice and edit/delete behavior retained.
- Focus: completed-session presentation uses actual recorded elapsed duration and daily totals; next-session and done actions work. It does not claim the target duration when a session was ended early.
- Profile settings now open dedicated Reminders, Privacy & security, and Help & about pages. Reminder switches/quiet hours persist locally; help search/FAQ and a copyable feedback draft work.
- Story: dedicated day/week/month preview with watermark switch and themed portrait card. Size and action spacing refined from the first browser pass.
- Optional welcome/onboarding/account visual flows are accessible from Help. Onboarding saves the chosen name and theme; Home remains the default route. Account controls clearly state that authentication is not connected and never collect/store passwords.

## PDF coverage and intentional differences

| PDF pages | Application UI | Status / limits |
| --- | --- | --- |
| 1, 19 | Home calendar and empty day | Implemented; actual/local sample entries differ from the reference content. |
| 2 | Create | Four formats and manual step planning. AI-generated breakdown remains excluded. |
| 3, 14, 21 | Focus setup, active and completed | Implemented; audio, DND and automatic multi-step progression are not connected. |
| 4 | Recap | Actual deterministic statistics and story entry. Mood/AI blocks remain excluded. |
| 5 | Themes & buddy | Exactly three identities, independent appearance modes, preview/apply/persistence; original character names retained. |
| 6, 34 | Memories and date filter | Implemented with real search/filtering and date-range counts. |
| 7, 8 | Profile and editor | Implemented locally; avatar uses initials or supplied buddy. Device gallery import not connected. |
| 9?11, 30 | Journal, format and stickers | Implemented text/mixed editor and sheets; freehand canvas, arbitrary photo import and generated stickers remain unavailable. |
| 12 | Checklist | Implemented local categories/items/progress. AI suggestion and device alerts excluded/unavailable. |
| 13, 32, 33 | Schedule and date/time selection | Implemented with Flutter date/time pickers; these picker overlays are not identical to the PDF's custom time sheet. |
| 15, 17, 18 | Welcome/onboarding | Optional local flow; no forced onboarding. Goal/check-in chips disclose preview status; name/theme save. |
| 16, 25?27 | Account/password/reset | Visual pages with unavailable controls. No fake login, account creation, password reset or security claims. |
| 20 | Day detail | Implemented with saved notes, schedules and completed focus sessions. |
| 22 | Share to status | Local preview implemented. Media export/social sharing not connected. No fabricated mood label. |
| 23 | Reminders | Preferences persist; native notifications are not delivered yet. |
| 24 | Privacy | Local data disclosure; app lock disabled, no AI switches. |
| 28 | Month jump | Implemented; logging bars not fabricated for unsaved history. |
| 29 | Journal read view | Implemented with real data; uses an icon when there is no imported photo. |
| 31 | Voice recording | Not connected; no fake recording/transcription UI or invented duration. |
| 35 | Help & about | Searchable FAQ, feedback draft, licenses. Answers describe actual behavior. |
| 36 | Logout confirmation | Not shown because there is no authenticated session. |

Secret Note, Quick Mood, mood charts, week calendar and visible Create navbar label remain removed as explicitly requested. Plus continues to open a page. No Supabase, AI service or remote media was added. Existing supplied character and jasmine sticker are reused.

**The result is not a claim of exact pixel identity across all 36 reference states.** Unavailable integrations and the deliberate exclusions above remain visible differences. The PDF includes states that require future functionality. Numbers/content come from actual local data rather than copied reference statistics.

## Regression

- `dart format .`: 62 files, final run with no changes.
- `flutter --no-version-check analyze`: no issues (42.6 seconds).
- `flutter --no-version-check test --reporter expanded`: **60 passed** (80 seconds).
- Eight new tests cover inclusive range bounds, reminder restore, backward-compatible note metadata, 320px routes at 100%/200% text, style/sticker saving, month jump (including its accessible button role) and archive date filtering.
- Reproduced and fixed: month title overflow with 200% text; date/time trailing labels consuming narrow ListTile width; story portrait overflowing at large text; welcome page overflowing at large text; indicators clipping after calendar row reduction; missing accessible month-selection button role.
- Intermediate browser capture: 20 routes, zero page errors. Final responsive pass: 20 routes ? 3 viewport widths (320, 390, 768), **60 screenshots, zero page errors**. Editor, text-style and sticker sheets were also captured through actual browser interactions. A missing accessible button role on month selection was discovered in Playwright, fixed, and added to the month regression test.

Changed files include calendar toolbar/day grid/detail widgets, journal model/editor/read view, archive/range sheet, schedule model/form, focus completion, story page, reminder store/preferences pages, introduction pages, router/bootstrap, and regression tests. Local evidence is under `output/playwright/daystick36/`; command logs use `output/playwright/daystick36-*`.


## Browser evidence

`output/playwright/daystick36/comparison.html` pairs reference pages with application captures. Final images are in `output/playwright/daystick36/final/`. `output/playwright/daystick36-browser-verified.log` records the 60-route responsive pass. `editor-snapshot.log`, `format-snapshot.log`, `sticker-snapshot.log` and `create-saved.log` record journal entry, formatting/sticker interactions and successful saving. A sample note was created only in the isolated automation browser context.

A reused browser context again emitted a service-worker preparation timeout warning and recovered. This warning is not claimed fixed. The successful screenshot pass reported zero page errors. No browser console or backend error is being presented as a passed feature.

The review build uses `UI_REFERENCE_REVIEW=true` for the reference date (22 October 2026) and initial profile name. The production default still uses the device date and local profile. Data counts are not copied from the PDF.


The final accessibility refinement gives month selection its own semantics container rather than merging its label with the calendar. The eight targeted tests passed again after this change, including an exact label assertion. Responsive coverage is in Flutter widget tests and desktop-browser viewports; physical Android/iOS device testing was not performed.


Final release web build passed (255.1 seconds). Playwright on that build identified **?Jump to a month? as a separate button**, opened the month sheet, returned to today, navigated to Memories and opened its date-range sheet. Additional modal images: `month-jump-390.png` and `date-filter-390.png`. Final build log: `output/playwright/daystick36-release-final.log`; final analyzer log: `output/playwright/daystick36-analyze-final.log`.

Preview: http://127.0.0.1:5175. The local preview server remains running.
