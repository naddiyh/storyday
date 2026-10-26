import 'package:flutter/material.dart';
import '../../../core/design/app_theme.dart';

/// Presentation preferences only. Never store journal or vault data here.
class Appearance {
  const Appearance(
      {this.theme = JournalTheme.lavender,
      this.decorated = true,
      this.mode = ThemeMode.system});
  final JournalTheme theme;
  final bool decorated;
  final ThemeMode mode;
  Appearance copyWith(
          {JournalTheme? theme, bool? decorated, ThemeMode? mode}) =>
      Appearance(
        theme: theme ?? this.theme,
        mode: mode ?? this.mode,
        decorated: decorated ?? this.decorated,
      );
}
