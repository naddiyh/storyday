# PDF UI replacement and regression report

## Reference used

Daystick - Scrapbook Journal App-selection (1).pdf, especially page 6
(Themes & buddy), page 7 (Memories), and pages 10-13 (journal/checklist editors).
The existing calendar, pastel palette, mascot asset, three theme identities,
and five-destination shell were retained. This change replaces the remaining
generic layouts rather than embedding PDF screenshots into the application.

## Code replaced

- Removed the old private AlertDialog-based note editor from create_screen.dart.
  Added note_editor_page.dart as the reusable full-screen paper editor.
- Editors now use the root navigator above the tab shell, with a close action,
  date/header, top Save control, white paper surface, checklist progress and
  completion controls. Journal has the reference-style bottom toolbar; only
  the existing text/list mode is active, other future tools are disabled.
- Removed the duplicated theme heading found during Playwright review and added an explicit return-to-Profile control.
- Replaced oversized theme-preview cards with compact miniature palette cards
  like the PDF. Kept all three approved theme identities, independent appearance
  mode, preview/apply/cancel and persisted preferences. Added a buddy section
  while keeping future character selection clearly unavailable.
- Replaced the archive's ungrouped list and inert chips with date-grouped cards,
  descending date order, real All/Journal/Lists filters, ordinary-note search,
  pastel type badges, and actual checklist completion summaries.
- Reused existing Home, Create, Recap and Profile styling from the previous
  refinement. Their working behaviors and selected-date state are preserved.

## Bugs fixed and regression evidence

1. Full-page editors initially opened in a nested tab navigator and left the
   bottom bar visible. The new regression failed with a visible Home label.
   Both create and edit flows now push through the root navigator. The final
   regression asserts the editor covers the tabs and Cancel restores Create.
2. Save failure previously published a note into UI state before persistence
   succeeded. The controller now publishes after successful storage; failures
   retain the editor's draft and show a retry message. A failing repository
   test verifies no unsaved memory appears and the draft remains editable.
3. Editing an existing checklist allocated an unused text controller. It is
   disposed before replacement, while checked states remain preserved.
4. Save is guarded against rapid repeat submissions. The existing per-format
   modal guard and deletion-confirmation regressions remain in place.

## Changed files

- lib/core/design/app_theme.dart (central checklist/progress styling)
- lib/features/notes/presentation/create_screen.dart
- lib/features/notes/presentation/note_editor_page.dart (new)
- lib/features/notes/data/note_repository.dart
- lib/features/search/presentation/search_screen.dart
- lib/features/themes/presentation/themes_screen.dart
- lib/app/router.dart (explicit theme-page return navigation)
- test/replacement_regression_test.dart (new)
- docs/ui-replacement-report.md (this report)

## Automated checks

Baseline: 21 existing tests passed. Final suite: 25 tests passed. Four new regression tests cover root editor
navigation, archive ordering/filtering/search, storage failure retention, and
320px/200% text editor layout. Existing tests cover six theme/mode combinations,
calendar date calculations and interactions, ordinary/secret separation,
checklist completion, deletion confirmation, and theme persistence.

Formatting: dart format . executed. Static analysis: flutter analyze executed.
Final static analysis completed with no issues. The theme-page duplicate heading/back-navigation check is included in the new navigation regression.
The installed Flutter 3.24 SDK uses --no-version-check to avoid the previously
observed SDK Git tag fetch stall. Web preview uses the HTML renderer.

## Playwright verification

Used the installed Playwright skill with npx @playwright/cli, Edge channel,
390x844 viewport and snapshot references before interactions. The shell wrapper
is a .sh script; npx is its equivalent entry point in this PowerShell workspace.
Screenshots and snapshots are generated from the actual compiled Flutter app.

Browser flow: open Create, activate Flutter accessibility from its fresh
snapshot reference, open Journal, fill title and body, save, navigate to
Memories, verify the saved card under its date. Sample text from the supplied
PDF is entered in an isolated automation browser context; it is not user data
or a new production seed. Additional final screenshots cover all six routes.
Before images are preserved in output/playwright/replacement-before/.

Artifacts: output/playwright/journal-replacement.png,
memories-replacement.png, checklist-replacement.png, *-final.png and CLI logs.

## Remaining limitations

The UI is an implementation of the PDF's visual direction, not a pixel-perfect
copy of every one of its 18 screens. Saved data and statistics intentionally
reflect real local records rather than the PDF's invented counts. Schedule,
focus, rich drawing/photo/voice/story tools, protected secret vault, notifications,
and remote sync remain unavailable. AI controls are excluded by the approved PRD.
Secret content is never shown in ordinary archive or recap. Native Android/iOS
build validation remains subject to the existing toolchain limitations.

## Browser outcomes

Playwright created the reference sample journal in its isolated context, saved
it, reloaded the browser, and verified persistence. It then created Top 3 with
two tasks, marked one complete, saved, and verified `1 of 2 done` in Memories.
The checkbox `check` command initially returned before Flutter's semantics frame
updated; the next snapshot confirmed the checked state and 50% progress. This
was a browser-driver timing event, not counted as a passing immediate assertion.
Final screenshot checks also caught a white outer editor inset; it now uses the
theme surface. Title labels no longer float over filled titles, and checklist
checks/progress use the reference's green accent through centralized themes.

Six-route screenshot run: output/playwright/replacement-screen-run.log, no
runtime console errors. Reloading the isolated interaction session produced one
non-fatal Flutter service-worker timing warning. The compiler also retains the
previous non-fatal Cupertino font warning. Neither is reported as a clean warning
count across every run. Both are distinct from a failed regression test.

## Final result

- dart format .: completed; final formatting check reports no changed files.
- flutter analyze: no issues found.
- flutter test: 25 tests passed (21 baseline plus four new regressions).
- Final web build succeeded.
- Six-route Playwright capture completed with no runtime console errors.
- Filled journal draft screenshot confirms root editor covers bottom tabs and
  includes the new paper/toolbar layout. Filled checklist draft confirms the
  theme-colored outer inset, nonfloating title and green completion/progress.
- Sample drafts used for final visual captures were cancelled; the separately
  saved journal/checklist remained the persisted interaction fixtures.

The report does not assert zero pixel difference, complete PDF feature parity,
or native mobile validation. It records the implemented replacements and
actual regression/browser results.
