# Foundation architecture

The PRD in `docs/product-requirements.md` remains the product source of truth.
This slice implements appearance and navigation only. It does not establish
the security guarantees of the future Secret Notes vault.

## Boundaries

- `app/`: bootstrap, Riverpod dependency injection, GoRouter lifetime, navigation shell.
- `core/design/`: shared spacing and Material 3 color/typography/component themes.
- `core/widgets/`: responsive page layout, headings, and empty states.
- `features/calendar/`: date-only month arithmetic and an empty calendar preview.
- `features/themes/`: appearance model, persistence interface/adapter, controller, and UI.
- Other feature directories contain honest preview screens, not fake data or working editors.

The stateful route shell preserves each tab's state. Settings is a separate route.
Unknown routes offer recovery to the calendar. The central Create destination
will become the note creation flow once its repository exists.

Appearance uses a versioned SharedPreferencesAsync record. It stores only a
theme ID and decoration preference. Writes are serialized; failures surface in
the UI. Invalid saved data falls back to Lavender Cream. These preferences are
not appropriate storage for journal data, encryption keys, or authentication.

## Design

Five theme families use generated semantic color schemes: Lavender Cream,
Sage Ivory, Midnight (dark), Peach Butter, and Monochrome. Text, backgrounds,
controls, outlines, selection states, and surfaces use semantic colors.
The greeting can be disabled for a cleaner calendar. App typography uses the
platform font without runtime font downloads. Native Material icons are used;
final character artwork and sticker assets are deferred.

Content is scrollable and width-constrained. Calendar cells retain accessible
tap sizes; narrow displays can scroll the grid horizontally. Date cells have
full-date semantics, selected state, and a Today indicator. Theme animation
respects the platform reduced-motion setting. English is the initial locale;
calendar week starts use Material localizations rather than a hardcoded offset.

## Next boundaries

Ordinary notes will use local repositories and a transactional sync outbox.
Supabase will only receive consented ordinary data and use owner-enforced RLS.
Secret Notes require a separately reviewed local vault/key lifecycle; they must
never enter the ordinary database, sync queue, search, widgets, or export path.
Do not implement them as an `is_secret` flag on ordinary notes.

## Deferred decisions

The generated application ID `com.example.lenote` is provisional. Confirm brand,
organization ID, platform minimums, signing, and SDK upgrade before distribution.
No Supabase credentials, networking, telemetry, notification permissions, or
biometric permissions are configured in this foundation.

## Step 3 update

See [interactive calendar](step-3.md) for the current component boundaries and
validation. Profile is the settings destination. Cute/Cool and appearance mode
are locally persisted; legacy palette IDs remain compatible. The calendar uses
a shared grid and day cell, full-date sample activities, and session decorations.
