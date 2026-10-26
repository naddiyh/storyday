import 'package:flutter/material.dart';

@immutable
class ScrapbookPalette extends ThemeExtension<ScrapbookPalette> {
  const ScrapbookPalette(this.colors);
  final List<Color> colors;
  static ScrapbookPalette from(ColorScheme scheme, {required bool pastel}) {
    const accents = [
      Color(0xFFECE3FA),
      Color(0xFFDDF3E6),
      Color(0xFFFFE7D5),
      Color(0xFFDCE7FF),
      Color(0xFFFBE0EA),
      Color(0xFFFFF2C2)
    ];
    return ScrapbookPalette([
      for (final color in accents)
        scheme.brightness == Brightness.dark
            ? Color.alphaBlend(color.withOpacity(.12), scheme.surfaceContainer)
            : pastel
                ? color
                : Color.alphaBlend(
                    color.withOpacity(.35), scheme.surfaceContainerLow)
    ]);
  }

  @override
  ScrapbookPalette copyWith({List<Color>? colors}) =>
      ScrapbookPalette(colors ?? this.colors);
  @override
  ScrapbookPalette lerp(covariant ScrapbookPalette? other, double t) => other ==
          null
      ? this
      : ScrapbookPalette(List.generate(
          colors.length, (i) => Color.lerp(colors[i], other.colors[i], t)!));
}
