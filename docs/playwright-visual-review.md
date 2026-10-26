# Playwright visual refinement

## Tooling and reproduction

Installed the curated Playwright skill at ~/.codex/skills/playwright using the
skill-installer helper. Used Playwright CLI through npx with the local Edge
channel, snapshots before interacting with references, and real browser PNGs.
The installed skill becomes discoverable automatically on the next turn.
Artifacts are stored in output/playwright/ and ignored by Git.

Reference: page 2 of the supplied Daystick PDF, 292.5 x 633 PDF points,
compared with a 390 x 844 CSS-pixel browser viewport (same aspect ratio).
The reference PNG is rendered at 2x; the app is always live Flutter widgets.
The bird illustration is an isolated crop from the user-supplied reference,
not a flattened application screen. Font: bundled Plus Jakarta Sans, OFL license
in assets/fonts/OFL.txt. No external font request is needed at runtime.

Build for deterministic reference review:

    flutter --no-version-check build web --release --web-renderer html --pwa-strategy none --dart2js-optimization=O1 --dart-define=UI_REFERENCE_REVIEW=true
    python -m http.server 5175 --bind 127.0.0.1 --directory build/web
    powershell -File tool/visual-check.ps1

The reference-review define fixes the calendar date to 22 October 2026 and
uses the reference's sample greeting name. Normal builds keep the real device
date and generic profile identity. It does not modify persisted private notes.

## Iterations actually reviewed

1. Captured home-before.png. The calendar dominated the viewport; selected-day
   details were mostly below the fold. Header used an icon instead of the bird.
2. home-pass-1.png: bundled typography and reference mascot, compact calendar,
   pill filters and a white bottom bar with raised central plus. Calendar bottom
   moved to roughly y=468; the extra Today/navigation row still pushed details
   down to about y=550.
3. home-pass-2.png: consolidated navigation and selected-day paper panel.
   Details began around y=500; compact controls needed better large-text sizing.
4. home-pass-3.png: adjusted top inset and row density. At 390x844, calendar
   panel is approximately y=141..468; normalized reference is y=141..467.
   Selected-day panel starts around y=480 versus reference y=477. These are
   visual layout observations, not a claim of zero pixel difference.
5. Examining Create/Recap screenshots revealed oversized format cards and a missing mood-bar layout. Reduced card padding, badge and text dimensions, hid review-only date/form headings, and added honest empty mood bars.
6. Final capture set checks Home, Memories, Create, Recap, Profile, and Themes
   against the final build. Create now uses a two-column pastel format grid;
   Profile uses the reference's compact profile/statistics/four-settings layout.

## Bugs caught during refinement

- Compact dates overflowed vertically with 200% text: added scale-aware row
  growth while preserving compact geometry at default scale.
- Header controls overflowed at 320px/200%: constrained arrow geometry and
  allowed the header groups to wrap.
- Today moved off the horizontally scrollable filter list: returned it to the
  visible month header; scroll-aware tests bring controls into view before taps.
- Rapid/duplicated Create activation could stack dialogs: a per-card pending
  guard now waits for the current dialog to close. The regression test invokes
  the handler twice, expects one dialog, closes it, and verifies no secret data.
- The browser accessibility enable control is outside its own viewport: normal
  Playwright click timed out. Used the fresh snapshot reference with a DOM click
  to activate Flutter semantics, then interacted using new snapshot references.

## Scope and fidelity limitations

The result is not a pixel-identical implementation of every one of the PDF's
18 screens. Actual saved entries/counts and recorded dates differ from the PDF's
illustrative data. Focus, schedules, advanced drawing, encrypted vault, AI,
streak/focus statistics and account/logout are not implemented by this styling
change; their controls remain explicit placeholders where shown. Secret content
is excluded from archive/recap and never fabricated to mimic the PDF. No AI
features are introduced. Three theme identities and appearance persistence remain.
Browser rendering/rasterization and font metrics also differ from the raster PDF.

## Regression validation

The existing 21 Flutter tests cover date navigation, week/month, selected-day
creation, checklist completion, deletion confirmation, theme persistence and
preview/apply, secret privacy, and large-text layouts across all six theme/mode
pairs. The re-entry guard regression is included in scrapbook_test.dart.
See final command output for the actual latest run; no pixel-perfect or 100%
visual-match assertion is made. Screenshots are evidence for review, not a
substitute for functional tests.

Final validation: dart format . completed; all 21 Flutter regression tests pass. flutter analyze is clean after removing a redundant const. Web build and Playwright captures are recorded in output/playwright/final-run.log.

## Final browser result

Playwright final screenshot run completed for all six routes at 390x844. The
console query reported Errors: 0, Warnings: 0. The full CLI transcript is
output/playwright/final-run.log. This was checked on the compiled browser build,
not only a widget-test renderer. The web compiler still prints its existing
non-fatal Cupertino font tree-shaking warning; runtime screenshots render icons.

Raw Home/reference RGB mean absolute error (0..255, lower is closer) was 20.513
before the refinement and 17.517 in the final capture. Intermediate passes were
16.806, 17.198 and 17.495. This metric includes text/content, date indicators,
font rasterization and all pixel positions. It is not a match percentage and it
is not zero. In particular, the lowest raw pixel score does not automatically
mean the best calendar structure. These measurements explicitly demonstrate
that the complete image is still not pixel-identical to the PDF.

The final images and transcript are review evidence. Do not describe this as
100% identical, or describe unimplemented PDF screens as implemented.
