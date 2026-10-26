# Three-theme system

JournalTheme in core/design/app_theme.dart is the single palette and component
configuration source. Exactly three enum values are exposed. Existing internal
lavender/sage enum names remain to avoid unnecessary changes to callers, while
persisted stable IDs are sweet_pastel, calm_natural, and midnight. Legacy IDs
migrate on load and are written with new IDs on the next preference save.

MaterialApp receives light and dark ThemeData for the selected identity and
uses the separately persisted ThemeMode. Midnight honors Light through a slate
surface and muted violet/navy accents, Dark through deep charcoal/navy surfaces,
and System through platform brightness. It never silently overrides ThemeMode.

ThemesScreen is available from Profile > Themes & Appearance. Each card uses
its own ThemeData to render a miniature calendar, journal row, and palette.
Preview opens a local themed dialog; Cancel leaves preferences unchanged. Apply
updates the shared Riverpod appearance state and serializes the local preference
write. The actual five destinations inherit MaterialApp's selected scheme.

Common configuration includes card radius/elevation, typography, icon sizing,
buttons, inputs, chips, dialogs, bottom sheets, navigation and calendar tokens.
Sweet Pastel uses soft cream/lavender surfaces and gentle shadows; Calm & Natural
uses warm white/sage and quieter borders; Midnight uses slate/violet and crisp
corners. Activity and vault privacy logic are unaffected.

Regression tests cover three identities, legacy migration, restart restoration,
all appearance choices, preview cancellation, applied themes across five routes,
contrast, and 320px calendar rendering at 200% text for all six theme/mode pairs.
The supplied reference is visual direction only; no static mockup is embedded.
Mascot illustrations remain placeholders; native-device validation remains
subject to the existing Android/iOS toolchain limitations.
