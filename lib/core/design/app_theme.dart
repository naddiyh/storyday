import 'scrapbook_palette.dart';
import 'calendar_style.dart';
import 'tokens.dart';
import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double section = 32;
  static const double pageWidth = 720;
}

enum JournalTheme {
  lavender(
      'sweet_pastel',
      'Sweet Pastel',
      'Playful pastels, soft shapes, little moments of joy.',
      Color(0xFF795495),
      Color(0xFFFFF9F5)),
  sage(
      'calm_natural',
      'Calm & Natural',
      'Warm neutrals, sage accents, and room to breathe.',
      Color(0xFF52664B),
      Color(0xFFFAF8F1)),
  midnight(
      'midnight',
      'Midnight',
      'Navy, slate, and muted violet. Quietly refined.',
      Color(0xFF69648B),
      Color(0xFFEDEFF5));

  const JournalTheme(
      this.id, this.label, this.description, this.seed, this.paper);
  final String id;
  final String label;
  final String description;
  final Color seed;
  final Color paper;

  static JournalTheme fromId(String? id) => switch (id) {
        'sweet_pastel' || 'lavender' || 'peach' => lavender,
        'calm_natural' || 'sage' || 'monochrome' => sage,
        'midnight' => midnight,
        _ => lavender,
      };

  List<Color> get palette => switch (this) {
        lavender => [
            seed,
            const Color(0xFFEAC3D5),
            paper,
            const Color(0xFFDED2EF)
          ],
        sage => [seed, const Color(0xFFB5C4A9), paper, const Color(0xFFDCD2BD)],
        midnight => [
            const Color(0xFF171B29),
            const Color(0xFF303B52),
            const Color(0xFF929CB1),
            seed
          ],
      };

  ThemeData build({Brightness? brightness}) {
    final resolved =
        brightness ?? (this == midnight ? Brightness.dark : Brightness.light);
    final radius = this == lavender
        ? DesignTokens.panelRadius
        : this == sage
            ? 12.0
            : 8.0;
    final darkPaper = switch (this) {
      lavender => const Color(0xFF231D29),
      sage => const Color(0xFF1D231E),
      midnight => const Color(0xFF121725)
    };
    var scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: resolved,
      surface: resolved == Brightness.dark ? darkPaper : paper,
    );
    if (this == lavender && resolved == Brightness.light) {
      scheme = scheme.copyWith(
          primary: const Color(0xFF7955D9),
          onPrimary: Colors.white,
          surface: const Color(0xFFF5F1FF),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF5F1FF),
          surfaceContainerHighest: const Color(0xFFF5F1FF),
          onSurface: const Color(0xFF302743),
          onSurfaceVariant: const Color(0xFF6E657F),
          primaryContainer: const Color(0xFFECE3FC),
          onPrimaryContainer: const Color(0xFF302743));
    }
    final base = ThemeData(
        useMaterial3: true, colorScheme: scheme, fontFamily: 'PlusJakartaSans');
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final taskAccent = this == lavender
        ? resolved == Brightness.light
            ? const Color(0xFF2B9D76)
            : const Color(0xFF90D8B5)
        : scheme.primary;
    return base.copyWith(
      checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          fillColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? taskAccent : null),
          checkColor: WidgetStatePropertyAll(scheme.onPrimary)),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: taskAccent, linearTrackColor: taskAccent.withOpacity(.12)),
      dialogTheme: DialogTheme(
          backgroundColor: scheme.surfaceContainerLow, shape: shape),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: scheme.surfaceContainerLow,
          modalBackgroundColor: scheme.surfaceContainerLow,
          showDragHandle: true,
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(radius)))),
      chipTheme: base.chipTheme.copyWith(
          showCheckmark: false,
          side: BorderSide.none,
          labelStyle: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius / 2))),
      listTileTheme: ListTileThemeData(
          iconColor: scheme.primary,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.pagePadding,
              vertical: DesignTokens.space)),
      extensions: [
        ScrapbookPalette.from(scheme, pastel: this == lavender),
        CalendarStyle(
            radius: this == lavender ? 10 : 6,
            decorationOpacity: this == lavender ? 0.85 : 0.55)
      ],
      iconTheme: IconThemeData(
          size: DesignTokens.icon, color: scheme.onSurfaceVariant),
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.copyWith(
        bodyLarge: DesignTokens.body.copyWith(color: scheme.onSurface),
        headlineLarge: base.textTheme.headlineLarge
            ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -1.1),
        headlineSmall: base.textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.5),
        titleMedium:
            base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: DesignTokens.elevation,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: DesignTokens.elevation,
        shadowColor: scheme.shadow.withOpacity(0.12),
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        elevation: DesignTokens.elevation,
        indicatorColor: scheme.secondaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.buttonRadius)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant.withOpacity(.35)),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}
