import 'package:flutter/material.dart';

@immutable
class CalendarStyle extends ThemeExtension<CalendarStyle> {
  const CalendarStyle({required this.radius, required this.decorationOpacity});
  final double radius;
  final double decorationOpacity;
  static const indicatorSize = 12.0;
  static const rowHeight = 36.0;
  @override
  CalendarStyle copyWith({double? radius, double? decorationOpacity}) =>
      CalendarStyle(
          radius: radius ?? this.radius,
          decorationOpacity: decorationOpacity ?? this.decorationOpacity);
  @override
  CalendarStyle lerp(covariant CalendarStyle? other, double t) => other == null
      ? this
      : CalendarStyle(
          radius: radius + (other.radius - radius) * t,
          decorationOpacity: decorationOpacity +
              (other.decorationOpacity - decorationOpacity) * t);
}
