# Product Requirements Document (PRD)

## Personal Journal, Decorated Calendar & Mood Tracker

**Document status:** Draft v1.0\
**Purpose:** Product and implementation specification for Codex\
**Target platforms:** Android and iOS\
**Client:** Flutter\
**Backend / database:** Supabase\
**AI features:** Explicitly out of scope for this version

------------------------------------------------------------------------

## 1. Product Summary

Build a mobile-first personal journaling app that combines dated notes,
flexible checklists, mood tracking, a decorated calendar, secure Secret
Notes, reminders, home-screen widgets, and shareable monthly recap
stories.

The product should feel personal and delightful without forcing one
aesthetic. Its visual system should support both cute/soft themes and
cool/minimal themes while keeping navigation, readability, and core
interactions consistent.

### Product vision

A private, expressive space where people can record everyday life,
organize small tasks, reflect on how they feel, and turn their month
into a beautiful visual story.

### Product pillars

1.  **Remember:** journal entries, mixed-content notes, lists, and
    photos.
2.  **Feel:** daily mood logging and monthly reflection.
3.  **Express:** decorated calendar, themes, characters, and shareable
    stories.
4.  **Trust:** Secret Notes with a strict local-only content boundary.

### Product positioning

A personal life journal with a decorated calendar at its heart---not
merely a notes app or task manager.

------------------------------------------------------------------------

## 2. Goals and Success Criteria

### Goals

-   Make it fast and pleasant to create a dated note.
-   Make the calendar the primary daily destination and a visually
    distinctive feature.
-   Support free-text journaling, checklists, and mixed content in one
    note.
-   Allow users to record a mood for each day and reflect on mood
    history.
-   Protect Secret Notes from ordinary previews, search, sharing,
    widgets, analytics, and remote processing.
-   Make monthly recaps visually appealing and editable before sharing.
-   Offer theme customization that can appeal to users who prefer cute
    aesthetics and users who prefer cool, minimal aesthetics.
-   Provide a useful offline-friendly core experience.

### Non-goals for v1

-   AI summaries, AI writing assistance, AI mood interpretation, or any
    AI processing.
-   Social feeds, public profiles, followers, or public sharing of
    journals.
-   Collaborative/shared journals.
-   Web or desktop client.
-   Cloud-based content search or server-side processing of Secret
    Notes.
-   Paid subscriptions, in-app purchases, or marketplace features.
-   Medical or mental-health diagnosis and recommendations.

### Success metrics to consider

Track only privacy-safe, non-content product events and make analytics
opt-in or clearly disclosed where required.

-   Time to create the first note.
-   Percentage of new users who create a first note.
-   Weekly active users.
-   Percentage of active users who log at least one mood in a week.
-   Monthly recap generation and export rate.
-   Reminder opt-in rate and reminder disable rate.
-   Crash-free sessions and app launch reliability.
-   Widget engagement, where platform APIs permit measurement without
    collecting note content.

Do not collect note text, Secret Note metadata that could reveal
sensitive behavior, photos, mood text, checklist item text, or recap
contents for analytics.

------------------------------------------------------------------------

## 3. Target Users and Core Use Cases

### Primary user groups

-   People who enjoy journaling and personal reflection.
-   People who want a calendar-based memory log.
-   People who combine daily notes with practical checklists.
-   People who like aesthetic customization, stickers, and character
    mascots.
-   People who want a private journal and do not want their private
    writing processed by AI.

### Core use cases

1.  Open the calendar and understand which days have entries.
2.  Tap a date and create a journal note, checklist, or mixed note.
3.  Add a mood and optionally decorate the day.
4.  Find older notes using search and tags.
5.  Set a gentle reminder to write or complete a task.
6.  Create a Secret Note and unlock it with a PIN or device biometrics.
7.  Generate a monthly recap from selected non-secret content and edit
    it before exporting.
8.  Customize theme, calendar decoration, and character.
9.  See useful date or mood information from a home-screen widget
    without exposing private content.

------------------------------------------------------------------------

## 4. Platform and Technical Direction

### Client

-   Flutter for Android and iOS.
-   Use a feature-oriented, maintainable Flutter architecture.
-   Use a consistent design system with light/dark or user-selected
    themes.
-   Support accessibility: scalable text, adequate contrast,
    screen-reader labels, touch targets, and reduced-motion-friendly
    behavior.
-   Keep UI state, domain logic, and data access separated.
-   Use dependency injection and repository abstractions where
    practical.
-   Include unit tests for domain logic and widget tests for critical
    UI.

### Backend and database

-   Supabase provides PostgreSQL, authentication, and optional storage
    for non-secret media.
-   Use Supabase Auth for account identity if account-based sync is
    enabled.
-   Use Row Level Security (RLS) on all user-owned tables.
-   Use versioned SQL migrations and seed data for development.
-   Never rely on client-side filtering as the only authorization
    boundary.
-   Store Supabase project URL and anon/publishable key in
    environment-specific configuration. Never ship the service-role key
    in the client.
-   Secret Note content must not be stored in Supabase in v1. Secret
    content and associated secret media must remain on the device and be
    encrypted locally.
-   A user may use ordinary cloud-backed features only after the app
    clearly explains what is synced. Do not imply that all app content
    is local-only if ordinary notes or media are stored remotely.

### Offline and sync expectations

-   The app should allow reading and creating ordinary notes while
    offline, with local persistence and queued synchronization when
    online.
-   Define conflict handling for simultaneous changes, using an updated
    timestamp and a clear policy. Do not silently discard edits.
-   Secret Notes are local-only and must never enter the sync queue.
-   If offline support is implemented with a local database, document
    how local ordinary notes are reconciled with Supabase.
-   If full offline sync is too large for the first implementation,
    establish local repositories and clear interfaces so it can be added
    without rewriting UI and domain logic.

### Suggested implementation building blocks

Choose packages after checking current Flutter compatibility and
maintenance status. Likely areas include: - Supabase Flutter client. -
Local database (SQLite-based). - Secure key storage using platform
secure storage. - Local authentication / biometrics. - Local
notifications. - Calendar UI or a custom calendar grid. - Share/export
and image rendering. - Android home-screen widgets and iOS WidgetKit
integration.

Widgets require platform-specific implementation or a maintained Flutter
bridge. Treat widget development as a distinct workstream, not a
standard Flutter screen.

------------------------------------------------------------------------

## 5. Information Architecture and Navigation

### Primary navigation

Use a bottom navigation bar with five destinations:

1.  **Calendar** --- default landing screen and core experience.
2.  **Search** --- search and filter ordinary notes.
3.  **Create** --- central action for creating a note or list.
4.  **Recap** --- monthly recap and history.
5.  **Themes** --- appearance, decorations, and character customization.

Settings, reminder management, account/sync settings, export, and
privacy controls can be accessed from a profile/settings entry in the
app bar or Themes screen.

### Navigation principles

-   Calendar is the default screen.
-   Creating a note should take one or two taps from the main screen.
-   Secret Notes must be clearly separated from ordinary notes.
-   Do not show secret text, titles, tags, or images in ordinary
    navigation, notifications, search results, or calendar previews.
-   Use clear empty states and helpful onboarding.
-   Avoid excessive decoration that harms readability.

------------------------------------------------------------------------

## 6. Functional Requirements

Priority labels: - **P0:** Required for a usable first release. -
**P1:** Important; deliver in the first complete product milestone. -
**P2:** Enhancement that may follow after core workflows are stable.

### 6.1 Onboarding and Preferences

**Priority:** P0

Requirements: - Explain the app's main purpose and calendar-first
approach. - Let users choose an initial visual theme or accept a
default. - Let users choose a character or skip the choice. - Explain
the difference between ordinary notes and Secret Notes. - Explain which
ordinary content may sync to Supabase. - Explain that Secret Notes are
stored locally and excluded from remote processing. - Ask for
notification permission only when the user enables a reminder or
otherwise understands why it is needed. - Allow theme, privacy,
reminder, and sync preferences to be changed later.

Acceptance criteria: - A user can finish onboarding without enabling
notifications. - Theme and character selection can be skipped. - Privacy
wording does not claim all content is local-only if ordinary notes sync
remotely.

### 6.2 Calendar

**Priority:** P0

Requirements: - Monthly calendar is the default home screen. - Navigate
between months and return to today. - Select a date to view that day's
entries and mood. - Show a subtle indicator when a date has ordinary
notes. - Show a mood color/marker when a mood is recorded. - Show
decorations or stickers where the user has added them. - If a date has
Secret Notes, show only a small lock icon. Do not show secret title,
text, mood derived from secret content, photo, tag, or preview. -
Support a minimal/clean view and a decorated view. - Provide a date
detail view or bottom sheet with that day's ordinary notes and a clearly
separated Secret Notes entry point. - Handle dates with multiple
notes. - Respect locale, first day of week, and month/year changes. -
Calendar decorations must not prevent dates from being tapped or labels
from being read.

Acceptance criteria: - Calendar updates after note creation, deletion,
mood changes, or decoration changes. - A date containing only Secret
Notes displays no indication beyond the approved lock indicator. -
Calendar screenshots and ordinary previews never reveal Secret Note
content. - The calendar remains legible with all supported themes and
font scaling.

### 6.3 Notes and Journaling

**Priority:** P0

Requirements: - Create, read, edit, and delete a note. - Associate each
note with a date; time is optional. - Support multiple notes per date. -
Support a title and free-text body. - Support a mixed-content editor
containing text blocks and checklist blocks. - Support checklist items
with checked/unchecked states. - Provide useful starter templates such
as Journal, To-do, Shopping List, and Packing List. Templates are
starting content, not separate incompatible note types. - Allow optional
tags. - Allow optional photos or image attachments, subject to storage
permissions and limits. - Allow a note to be favorited or pinned. -
Autosave or clearly indicate save status; prevent accidental data
loss. - Provide confirmation or recovery for destructive actions. - Keep
secret and ordinary note models/data paths separated. - Support a useful
empty state for a date with no entries.

Acceptance criteria: - A user can create a mixed note with prose and
checklist items in one note. - A user can create more than one note on a
date. - Edits persist after navigating away and reopening the note. -
Checklist completion state persists. - Secret Notes cannot be created by
merely toggling a flag on an already-synced remote record unless the
content is securely migrated and remote copies are removed; the safer v1
behavior is to create a new local-only Secret Note.

### 6.4 Search and Tags

**Priority:** P1

Requirements: - Search ordinary note titles and body content. - Filter
by one or more tags. - Filter by date range and favorite status. -
Provide recent searches only if they do not expose secret terms. -
Provide an empty state and a clear way to reset filters. - Exclude
Secret Notes entirely from results and search indexing. - Do not send
note content to a remote search service. - Search locally over synced
ordinary notes and any local cache available to the user. - Clearly
handle offline search behavior.

Acceptance criteria: - Secret Note text and titles never appear in
search results, suggestions, indexing, or search history. - Search
filters can be combined and cleared. - Search results link to the
correct note and date.

### 6.5 Gentle Reminders

**Priority:** P1

Requirements: - Users can schedule a reminder for a date/time, for
writing or a chosen ordinary note/task. - Reminder message is
configurable and can use a generic, privacy-safe default. - Provide
recurring reminders only if supported reliably by the selected
notification implementation. - Allow snooze, reschedule, and disable. -
Respect system notification permissions and quiet preferences. - Avoid
shame, streak pressure, or guilt-based copy. - Never put Secret Note
content or title into a notification. - If a reminder relates to a
Secret Note, the notification must be generic and must not reveal that
it is secret unless the user explicitly opts into such wording.

Acceptance criteria: - A user can create, edit, and delete a reminder. -
Permission denial is handled gracefully. - Notifications do not expose
note content on a locked screen by default. - Time zone changes and
daylight-saving behavior are handled as appropriate for the device
locale.

### 6.6 Secret Notes and Privacy

**Priority:** P0; security-critical

Requirements: - Create and edit a Secret Note in a separate protected
flow. - Unlock with a user-defined PIN and/or device biometrics where
supported. - Offer a secure fallback when biometrics are unavailable or
fail. - Auto-lock when the app backgrounds or after a configurable
timeout. - Use local encryption for secret content and secret media. -
Store encryption keys using platform secure storage/key management. - Do
not store Secret Note content, titles, media, tags, or body-derived data
in Supabase. - Do not include Secret Notes in sync, cloud storage,
remote logs, analytics, crash-report breadcrumbs, search, widgets, recap
generation, sharing, or export. - Do not include secret content in
clipboard or OS share sheet unless an explicit, separately designed user
action is introduced in a future version. For v1, Secret Notes are
excluded from sharing. - Calendar shows only a lock icon for dates
containing Secret Notes. - Avoid leaking secret existence through
unnecessary APIs or metadata. Some local UI indication is allowed only
as specified for the calendar. - Protect against accidental screenshots
where platform capabilities allow, but do not claim screenshot blocking
is universally enforceable. - Provide clear recovery behavior if the PIN
is forgotten. Do not promise recovery if the encryption key cannot be
recovered securely. - Avoid logging sensitive values during debugging. -
Test data deletion and app uninstall behavior. Explain that uninstalling
or losing the device may permanently remove local-only Secret Notes
unless a secure local recovery method is deliberately designed later.

Security implementation notes: - A PIN should unlock access to a
protected encryption key or key-encryption key; it must not be treated
as encryption by itself. - Use a reviewed cryptographic library and
platform key storage. Do not invent a custom cipher. - Apply rate
limiting/backoff to PIN attempts where technically feasible. -
Re-authenticate after the app has been backgrounded according to the
lock policy. - Avoid writing decrypted secret content to temporary files
or logs. - Do not send Secret Note data to Supabase Edge Functions or
any external API. - Add automated tests for every known secret-content
egress path.

Acceptance criteria: - Secret content is absent from Supabase tables,
Storage buckets, sync queues, remote telemetry, search, and share
exports. - A locked Secret Note cannot be read from the normal note list
or calendar preview. - Backgrounding the app triggers the configured
lock behavior. - The privacy statement accurately describes local-only
storage and recovery limitations.

### 6.7 Mood Tracking

**Priority:** P0

Requirements: - Let a user record one primary mood per date. - Initial
mood set: Amazing, Good, Okay, Low, Difficult. Labels should be
localizable and may be refined in design. - Give each mood a distinct
but accessible color and optional icon/emoji. - Allow a short optional
reflection, subject to privacy settings. - Allow a user to change or
remove a mood. - Display mood markers on the calendar. - Include mood
distribution in the monthly recap. - Mood data must not be described as
diagnosis or used to make health claims. - Secret Note content must not
be mined to infer mood. Only explicit mood data recorded through the
mood feature may be used in recap.

Acceptance criteria: - A mood can be added, edited, and removed for a
date. - Calendar and recap update consistently. - Mood colors have
sufficient contrast and are not the only means of conveying meaning.

### 6.8 Decorations, Themes, and Characters

**Priority:** P1

Requirements: - Provide a default clean theme and at least a small set
of polished themes at launch. - Support both soft/cute and cool/minimal
aesthetics. - Allow selection of accent colors and calendar decoration
styles. - Support date decorations/stickers without harming
legibility. - Provide five original characters as the initial character
set: 1. **Lumi --- The Dreamer:** lavender/cream; thoughtful and
imaginative; bunny concept. 2. **Miso --- The Cool One:** charcoal/sage;
calm and confident; cat concept. 3. **Pip --- The Optimist:** butter
yellow/orange; cheerful and energetic; chick concept. 4. **Bumi --- The
Comforter:** cocoa/muted blue; warm and reassuring; bear concept. 5.
**Nori --- The Explorer:** mint/deep teal; curious and adventurous; frog
concept. - Character concepts are provisional; final artwork and names
require design review and trademark/name checks. - Characters may appear
on onboarding, empty states, widgets, recap covers, and theme
previews. - Avoid forcing character art into the note editor when it
competes with writing. - Support a reduced-decoration or no-character
option.

Acceptance criteria: - User preferences persist after app restart. -
Changing theme does not alter note content. - Calendar remains legible
in all themes. - Users can disable character illustrations.

### 6.9 Monthly Recap and Story Export

**Priority:** P1

Requirements: - Generate a recap for a selected month using explicit,
eligible user data only. - No AI in v1. Recap content is created from
deterministic counts and user-selected entries/photos, plus editable
text written by the user. - Include a cover, mood overview, selected
memories, and a reflection page. - Allow users to choose story style,
colors, character, photos, and included content. - Allow every text
field to be edited before export. - Offer multiple visual templates: -
Cute scrapbook. - Minimal editorial. - Film diary. - Pastel memory
board. - Dark/cinematic. - Export shareable images in a story-friendly
vertical format and/or save them to the device. - Share only content
explicitly included by the user. - Never include Secret Notes, secret
photos, secret titles, or secret-derived summaries. - If no notes/moods
exist for a month, show a useful empty state rather than inventing a
recap. - Provide preview before saving or sharing.

Suggested story sequence: 1. **Month cover:** "October, a little piece
of my life." 2. **Mood page:** count/distribution of explicitly recorded
moods. 3. **Little moments:** user-selected non-secret entries and
photos. 4. **Note to myself:** a user-written reflection, such as "I'm
still growing, and that is enough."

Example story copy is illustrative and must be editable. Do not
fabricate user memories or emotions.

Acceptance criteria: - Recap totals match the source records. - Users
can preview and edit each slide. - Secret content is excluded by
construction, not just hidden in the UI. - Export includes only selected
eligible content. - The generated image is legible at common phone story
dimensions.

### 6.10 Home-Screen Widgets

**Priority:** P1; platform-specific

Requirements: - Android and iOS support should be implemented and tested
separately. - Provide widget sizes appropriate to each platform. -
Possible widget types: - Today's date and a shortcut to write. - Mini
calendar with mood markers. - Daily prompt or gentle reminder. -
Character/theme decoration. - Widget content must not display note
bodies, titles, photos, or Secret Note content. - Default to
privacy-safe display on the lock screen and in widget previews. - Widget
taps should open the correct app destination/date. - Respect widget
refresh limitations imposed by the OS. - Avoid promises of real-time
refresh where the OS does not guarantee it.

Acceptance criteria: - Widget can be added and removed using standard OS
flows. - Tapping a widget opens the intended screen. - Secret content is
never rendered by the widget provider. - Theme/character changes
propagate when the platform permits refresh.

### 6.11 Settings, Export, and Data Management

**Priority:** P1

Requirements: - Theme and character preferences. - Reminder
preferences. - Privacy and Secret Note lock settings. - Account and sync
status if Supabase Auth/sync is enabled. - Export ordinary notes and
data in a clearly documented format, if included in v1. - Delete
ordinary account/cloud data through a deliberate confirmation flow. -
Delete local Secret Notes with a clear warning that deletion may be
irreversible. - Explain which data is local-only and which is
cloud-synced. - Provide a privacy policy and account deletion path if
accounts are required.

Acceptance criteria: - User can find privacy and notification settings
easily. - Account deletion removes associated remote data according to
the product's retention policy. - Local Secret Notes are not silently
uploaded as part of export or backup.

------------------------------------------------------------------------

## 7. Data Model and Supabase Design

Use UUID primary keys, timestamps, explicit ownership, and versioned
migrations. The schema below is a starting point and should be reviewed
before implementation.

### 7.1 `profiles`

Purpose: User preferences and profile-level settings.

Suggested fields: - `id uuid primary key references auth.users(id)` -
`display_name text null` - `theme_id text not null` -
`character_id text null` - `calendar_style text not null` -
`created_at timestamptz` - `updated_at timestamptz`

Do not store Secret Note content or PINs here.

### 7.2 `notes`

Purpose: Ordinary cloud-synced notes only.

Suggested fields: - `id uuid primary key` -
`user_id uuid not null references auth.users(id)` -
`entry_date date not null` - `title text null` -
`content jsonb not null` - `tags text[] or normalized relation` -
`is_favorite boolean not null default false` -
`created_at timestamptz not null` - `updated_at timestamptz not null` -
`deleted_at timestamptz null` if using soft deletes

`content` should represent an ordered list of typed blocks, for
example: - paragraph/text block - checklist block with checklist items -
image reference block for eligible non-secret media

Validate content shape in the application and consider database
constraints where practical. Avoid mixing remote ordinary-note models
with local Secret Note models.

### 7.3 `note_tags` (optional normalized design)

Suggested fields: - `id uuid primary key` - `user_id uuid not null` -
`name text not null` - `normalized_name text not null` -
`created_at timestamptz not null` - unique constraint on
`(user_id, normalized_name)`

If using normalized tags, add a `note_tag_assignments` join table with
`note_id`, `tag_id`, and `user_id`, all protected by RLS. Choose either
normalized tags or a simple array based on search/filter requirements;
do not implement both without a clear need.

### 7.4 `moods`

Purpose: Explicit daily mood records.

Suggested fields: - `id uuid primary key` - `user_id uuid not null` -
`mood_date date not null` - `mood_key text not null` (e.g. `amazing`,
`good`, `okay`, `low`, `difficult`) - `reflection text null` -
`created_at timestamptz not null` - `updated_at timestamptz not null` -
unique constraint on `(user_id, mood_date)`

If mood reflection is sensitive, consider storing it locally or giving
users a clear sync setting. Do not infer it from note content.

### 7.5 `reminders`

Purpose: Reminder metadata for ordinary notes and journaling prompts.

Suggested fields: - `id uuid primary key` - `user_id uuid not null` -
`note_id uuid null` - `scheduled_at timestamptz not null` -
`timezone text not null` - `reminder_kind text not null` -
`enabled boolean not null default true` -
`created_at timestamptz not null` - `updated_at timestamptz not null`

The client schedules local notifications. If reminders sync between
devices, define rescheduling and duplicate-notification behavior. Do not
store Secret Note titles or content in reminder rows.

### 7.6 `calendar_decorations`

Purpose: User-applied decorations to calendar dates.

Suggested fields: - `id uuid primary key` - `user_id uuid not null` -
`decoration_date date not null` - `decoration_key text not null` -
`created_at timestamptz not null`

Define whether multiple decorations per date are supported and enforce
limits.

### 7.7 `media` or Supabase Storage

Purpose: Optional ordinary-note photos and recap assets.

Requirements: - Use a private bucket, not a public bucket, for user
media. - Use user-scoped object paths and Storage policies. - Generate
signed URLs only when required. - Do not store Secret Note media in
Supabase Storage. - Avoid leaking private media URLs into analytics or
logs. - Set file size/type limits and handle failed uploads. - Define
deletion behavior when an attached note is deleted.

### 7.8 Local-only Secret Note model

Secret Notes must live in a local encrypted database or encrypted local
storage design. Suggested logical fields: - local UUID - entry date -
encrypted title - encrypted content blocks - encrypted media references
or encrypted media files - local creation/update timestamps - encryption
metadata/version

Do not create a Supabase `secret_notes` table for v1. Even a table
containing secret text encrypted client-side adds avoidable metadata and
operational risk; keep secret content and its associated records
local-only.

### 7.9 Security policies

-   Enable RLS on every user-owned table.
-   Policies must restrict select/insert/update/delete to the
    authenticated owner.
-   Storage policies must enforce the same ownership boundaries.
-   Do not use service-role credentials in the Flutter client.
-   Add migration tests or policy tests for cross-user access denial.
-   Avoid storing note bodies or sensitive identifiers in server logs.
-   Do not use database triggers or Edge Functions that forward note
    content to external services.

------------------------------------------------------------------------

## 8. Privacy and Security Requirements

Privacy is a product feature, not merely a settings page.

### Secret Note data boundary

The following must remain local-only in v1: - Secret Note text and
title. - Secret Note checklist items and tags. - Secret Note photos and
attachments. - Secret Note content-derived metadata. - Secret Note
content in backups, search indexes, analytics, logs, widgets, and
exports.

The calendar may show only a lock indicator on dates with Secret Notes.
No additional detail should leak into the ordinary UI.

### Ordinary note data

Ordinary notes may sync through Supabase if account sync is enabled and
explained to the user. Do not describe ordinary cloud-synced notes as
never leaving the device.

### Threat model and limitations

-   Protect against casual access to the app and accidental UI
    disclosure.
-   Use OS-backed secure storage and vetted encryption.
-   Recognize that rooted/jailbroken devices, OS compromise, malicious
    accessibility services, or someone who already has an unlocked
    device may weaken protections.
-   Do not promise absolute security or universally block screenshots.
-   Make recovery limitations clear before a user depends on local-only
    encrypted content.

### Privacy acceptance tests

-   Verify Secret Notes never appear in network requests.
-   Verify Secret Notes never enter Supabase, Storage, analytics, crash
    logs, search, notifications, or recap exports.
-   Verify widgets use only approved, non-sensitive fields.
-   Verify a lock timeout returns the app to a protected state.
-   Verify deletion removes local encrypted content and associated media
    as intended.

------------------------------------------------------------------------

## 9. Design System and UX Requirements

### Visual principles

-   Modern, clean, neat, warm, and personal.
-   Cute enough for users who love playful aesthetics, but not
    gender-exclusive.
-   Cool and minimal options for users who prefer restrained design.
-   Calendar remains the visual hero.
-   Characters and stickers add personality without clutter.
-   Use generous spacing, consistent typography, clear hierarchy, and
    accessible contrast.
-   Do not rely on color alone to communicate mood.
-   Use motion sparingly and respect reduced-motion preferences.

### Suggested theme families

1.  **Lavender Cream:** soft lavender, cream, subtle purple accents.
2.  **Sage Ivory:** sage green, ivory, warm neutrals.
3.  **Midnight:** navy, charcoal, restrained cool accents.
4.  **Peach Butter:** peach, butter yellow, warm cream.
5.  **Monochrome:** black, white, and grayscale.

Theme names/colors are provisional and should be validated with actual
design work.

### Story styles

-   Cute scrapbook: paper textures, stickers, washi tape, playful
    headings.
-   Minimal editorial: whitespace, typography-led layouts, restrained
    accents.
-   Film diary: photo frames and film-inspired details.
-   Pastel memory board: soft colors and collage layouts.
-   Dark cinematic: dark background and high-contrast typography.

### Five character concepts

1.  **Lumi --- The Dreamer:** bunny; lavender and cream; thoughtful and
    imaginative.
2.  **Miso --- The Cool One:** cat; charcoal and sage; calm and
    confident.
3.  **Pip --- The Optimist:** chick; butter yellow and orange; cheerful
    and energetic.
4.  **Bumi --- The Comforter:** bear; cocoa and muted blue; warm and
    reassuring.
5.  **Nori --- The Explorer:** frog; mint and deep teal; curious and
    adventurous.

These are concept names and art directions, not final licensed assets.
Create original artwork and check naming conflicts before release.

### Accessibility

-   Support system text scaling.
-   Ensure interactive targets are comfortable to tap.
-   Provide semantics labels for icons and calendar dates.
-   Use contrast-safe mood colors.
-   Support dark mode or a dedicated dark theme.
-   Avoid animation as the only source of information.
-   Ensure story text remains legible when exported.

------------------------------------------------------------------------

## 10. Home-Screen Widget Requirements

Widgets are a cross-platform feature with native constraints.

### Initial widget variants

1.  **Quick Write:** date, character, and shortcut to create today's
    entry.
2.  **Mini Calendar:** compact month/date overview with non-sensitive
    mood markers.
3.  **Daily Mood:** selected mood or a shortcut to record one.
4.  **Gentle Reminder:** generic prompt with a direct app link.

### Privacy rules

-   Never display note bodies, titles, Secret Note details, or private
    photos.
-   Prefer generic text such as "A moment for yourself."
-   Consider OS lock-screen/widget privacy behavior and explain
    limitations.
-   Do not depend on instant refresh; respect Android and iOS widget
    scheduling limits.

### Implementation note

Create a platform-specific technical spike for Android widgets and iOS
WidgetKit before committing to detailed widget behavior. The Flutter app
remains the source of truth, while the platform widget reads only
approved, minimal display data.

------------------------------------------------------------------------

## 11. Monthly Recap Rules

The v1 recap must be deterministic and non-AI.

Allowed: - Counts of explicitly recorded moods. - Counts of days with
ordinary entries. - User-selected ordinary notes or excerpts. -
User-selected ordinary photos. - User-written reflection text. -
User-selected theme, character, and decorations.

Not allowed: - Secret Notes or secret-derived content. - Invented
memories, feelings, milestones, or summaries. - AI-generated writing or
analysis. - Automatically sharing without preview and consent.

Suggested export: - Vertical story images suitable for common social
story formats. - Local save and OS share sheet for explicitly selected,
non-secret content. - Preview/edit step before sharing.

------------------------------------------------------------------------

## 12. Error Handling and Edge Cases

Handle at minimum: - No notes or moods for a selected date. - No data
for a selected month. - Supabase unavailable or user offline. - Sync
conflict or failed upload. - Permission denied for notifications,
photos, or biometrics. - Device does not support biometrics. - User
forgets the Secret Note PIN. - Encryption key unavailable or
corrupted. - App is backgrounded while a Secret Note is open. - User
deletes a note with attached media. - Widget data is stale because the
OS has not refreshed it. - User changes time zone or locale. - A recap
contains no photos or no mood data. - User tries to share a recap
containing a selected item that has since been deleted. - User changes
theme while a recap draft is open. - User signs out while ordinary local
data and local-only Secret Notes exist.

Never silently delete user content after an ordinary network error. For
irrecoverable local Secret Note key loss, clearly communicate that
encrypted content may not be recoverable.

------------------------------------------------------------------------

## 13. Testing and Definition of Done

### Unit tests

-   Note block serialization/deserialization.
-   Checklist state updates.
-   Tag normalization and filtering.
-   Calendar date grouping.
-   Mood aggregation and recap counts.
-   Theme preference persistence.
-   Reminder scheduling calculations.
-   Secret-content filtering and export eligibility.
-   Sync conflict resolution.

### Widget tests

-   Calendar month navigation and date selection.
-   Note editor with mixed text and checklist blocks.
-   Search and combined filters.
-   Mood selection.
-   Secret Note lock and unlock screens.
-   Recap preview/edit/export flow.
-   Empty, loading, offline, and error states.
-   Accessibility semantics and scalable text.

### Integration and security tests

-   Supabase authentication and RLS isolation.
-   Ordinary note create/update/delete and sync.
-   Offline edits and retry behavior.
-   Secret Note network-egress tests.
-   Secret Note auto-lock and re-authentication.
-   Widget privacy tests on both platforms.
-   Reminder permission and notification behavior.
-   Story export excludes Secret Notes.
-   Storage policy and media deletion behavior.
-   Account deletion and local data handling.

### Release definition of done

A feature is complete when: - Requirements and acceptance criteria
pass. - Loading, empty, success, and error states are implemented. -
Accessibility and responsive layouts are checked. - Sensitive data is
not logged. - Tests are added for domain logic and critical user
flows. - Database changes are represented by migrations. - RLS and
Storage policies are tested. - No AI feature or external AI processing
is present. - Documentation describes any known limitation honestly.

------------------------------------------------------------------------

## 14. Suggested Delivery Plan

### Phase 0 --- Foundation

-   Set up Flutter project structure and design tokens.
-   Set up Supabase development project and migrations.
-   Establish local persistence and repository interfaces.
-   Define ordinary-note sync and Secret Note local-only boundaries.
-   Create privacy threat model and test plan.

### Phase 1 --- Core journal

-   Onboarding and preferences.
-   Calendar and date detail.
-   Ordinary notes with mixed content and checklists.
-   Mood tracking.
-   Local persistence and basic Supabase sync.
-   Theme foundation.

### Phase 2 --- Find and protect

-   Tags and search.
-   Secret Notes with encryption, PIN/biometric unlock, and auto-lock.
-   Gentle reminders.
-   Privacy regression tests.

### Phase 3 --- Express and share

-   Calendar decorations and five character concepts.
-   Monthly recap and story templates.
-   Editing and export/share.
-   Additional themes and accessibility polish.

### Phase 4 --- Platform extras

-   Android home-screen widgets.
-   iOS home-screen widgets.
-   Widget refresh and privacy verification.
-   Final performance, security, and store-readiness checks.

This plan is a suggested order, not a fixed timeline. Secret Note
security should be prototyped early enough to validate feasibility
before the rest of the app depends on its architecture.

------------------------------------------------------------------------

## 15. Open Decisions

Resolve these during implementation planning; do not block early UI
prototyping unless a decision changes architecture.

1.  **Account model:** Is Supabase Auth required, or should basic local
    journaling work without an account?
2.  **Ordinary note sync:** Sync ordinary notes by default after
    sign-in, or require explicit opt-in?
3.  **Offline-first scope:** Which ordinary content must be fully
    editable offline in the first release?
4.  **Media storage:** What file size/type limits and upload policy
    should apply to ordinary photos?
5.  **Secret Note recovery:** Accept permanent loss if the device/key is
    lost, or design a carefully scoped recovery method later?
6.  **PIN policy:** Minimum length, retry backoff, and whether device
    passcode fallback is supported.
7.  **Reminder model:** Local-only reminders or cross-device reminder
    sync?
8.  **Recap export:** PNG only at first, or multiple export
    sizes/formats?
9.  **Widget scope:** Which widget variants are required at launch for
    each platform?
10. **Localization:** English only initially, or English and Indonesian?
11. **Final brand:** App name, final character names, and approved
    original artwork.
12. **Deletion and backup policy:** Define user-facing retention and
    recovery explanations for ordinary cloud data and local-only Secret
    Notes.

------------------------------------------------------------------------

## 16. Instructions for Codex

Use this PRD as the source of truth for product scope. Do not attempt to
implement every feature in one large change.

Before coding: 1. Inspect the existing repository and report its current
structure and state. 2. Identify whether a Flutter project already
exists; do not overwrite working files blindly. 3. Propose a concise
implementation plan and list architecture decisions that need approval.
4. Establish design tokens, navigation, domain models, repositories, and
migrations before building feature screens. 5. Keep Secret Notes
local-only from the first implementation. Never create a Supabase table
or Storage path for Secret Note content. 6. Implement one vertical slice
at a time, with tests. 7. Use Supabase migrations and RLS policies for
every cloud-owned table. 8. Never put Supabase service-role credentials
in the app. 9. Do not add AI features, AI SDKs, AI API calls, or
AI-generated recap content. 10. Do not claim the privacy promise is
satisfied until network-egress and storage tests verify it.

### Suggested first Codex milestone

Deliver a reviewed architecture proposal and a working foundation
containing: - Flutter app shell and navigation. - Design tokens and
theme switching. - Supabase client configuration through safe
environment configuration. - SQL migrations for profiles and ordinary
notes, with RLS. - Local persistence/repository interfaces. - Calendar
UI with mocked/sample data. - Unit/widget tests for core models and
calendar behavior. - A short `README.md` explaining setup and
environment variables.

Do not implement Secret Note encryption as an improvised placeholder.
First choose a maintained cryptographic approach, define key lifecycle
and recovery behavior, then implement and test it as a dedicated
security-critical milestone.

------------------------------------------------------------------------

## 17. Glossary

-   **Ordinary note:** A normal journal entry or list that may be synced
    according to the user's account/sync settings.
-   **Secret Note:** A separate, encrypted, local-only entry excluded
    from Supabase, remote processing, search, widgets, analytics,
    sharing, and recap.
-   **Mood:** A user-selected daily feeling label; not a diagnosis.
-   **Decoration:** A sticker, icon, or visual accent applied to a
    calendar date or story.
-   **Recap:** A deterministic, editable monthly visual summary
    assembled from explicitly selected eligible content.
-   **Widget:** An Android home-screen widget or iOS WidgetKit extension
    that displays only approved, non-sensitive information.

------------------------------------------------------------------------

**End of PRD --- v1.0**
